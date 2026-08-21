defmodule Exdashboard.Widgets.Store do
  use GenServer

  @table :exdashboard_widgets

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def put(id, widget) do
    :ets.insert(@table, {id, widget})
    :ok
  end

  def get(id) do
    case :ets.lookup(@table, id) do
      [{^id, widget}] ->  widget
      [] -> :not_found
    end
  end

  def update(id, fun) do
    case get(id) do
       widget ->
        new_widget = fun.(widget)
        put(id, new_widget)
        {:ok, new_widget}

      :not_found ->
        :not_found
    end
  end

  def delete(id) do
    :ets.delete(@table, id)
    :ok
  end

  def all do
    :ets.tab2list(@table)
  end

  def clear do
    :ets.delete_all_objects(@table)
    :ok
  end

  def refresh(id) do
    update(id, fn config ->
      {:ok, new_data} = config.refresh_f.(config.data)
      new_small = %{config.small | data: new_data}
      new_big = %{config.big | data: new_data}
      %{config | data: new_data, small: new_small, big: new_big}
    end)
  end

  def register_refreshes() do
    Enum.each(all(), fn {id, config} ->
      if config.refresh_ms > 0 do
        Process.send_after(self(), {:refresh, id}, config.refresh_ms)
      end
    end)
  end

  @impl true
  def handle_info({:refresh, id}, state) do
    {:ok, config} = refresh(id)
    Process.send_after(self(), {:refresh, id}, config.refresh_ms)

    callback_process = Map.get(state, :callback_process)
    if callback_process != nil do
      send(callback_process, {:refresh, id})
    end
    {:noreply, state}
  end

  @impl true
  def handle_call(:register_refreshes, {pid, _ref}, state) do
    register_refreshes()
    {:reply, :ok, %{callback_process: pid}}
  end

  # GenServer callbacks

  @impl true
  def init(_) do
    :ets.new(@table, [
      :named_table,
      :set,
      :public,
      read_concurrency: true
    ])

    {:ok, %{}}
  end
end
