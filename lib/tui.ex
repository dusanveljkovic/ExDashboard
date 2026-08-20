defmodule Exdashboard.TUI do
  @version "beta"
  use ExRatatui.App

  alias ExRatatui.Layout.Rect
  alias ExRatatui.{Layout, Event, Focus, Style}
  alias ExRatatui.Widgets.{Block, Paragraph, Table}
  alias ExRatatui.Text.{Line, Span}

  @impl true
  def mount(_opts) do
    layout = Exdashboard.Layouts.Sixteen
    state =
      layout.make_state()
      |> Map.put(:layout, layout)
      |> register_refreshes()

    {:ok, state}
  end

  defp register_refreshes(state) do
    Enum.each(state.widgets, fn {name, config} ->
      if config.refresh_ms > 0 do
        Process.send_after(self(), {:refresh, name}, config.refresh_ms)
      end
    end)
    state
  end

  @impl true
  def handle_info({:refresh, name}, state) do
    case Map.fetch(state.widgets, name) do
      {:ok, config} ->
        {:ok, new_data} = config.refresh_f.(config.data)
        new_small = %{config.small | data: new_data}
        new_big = %{config.big | data: new_data}
        new_config = %{config | data: new_data, small: new_small, big: new_big}

        Process.send_after(self(), {:refresh, name}, config.refresh_ms)
        new_state = %{state | widgets: Map.put(state.widgets, name, new_config)}
        {:noreply, new_state}

      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def render(%{layout: layout} = state, frame) do
    {header_rect, body_rect, footer_rect} = panels(frame)
    layout_render = layout.render(state, body_rect)

    [
      {make_header(layout.name()), header_rect},
      {make_footer(), footer_rect},
    ] ++ layout_render
  end

  def make_header(layout_name) do
    %Paragraph{
      text: [
        %Line{spans: [%Span{content: "ExDashboard - monitor everything"}], alignment: :center},
        %Line{spans: [%Span{content: "Version #{@version}"}], alignment: :center},
        %Line{spans: [%Span{content: "Layout: #{layout_name}"}], alignment: :center},
      ]
    }
  end

  def make_footer() do
    options = ["[Tab] cycle", "[f]ocus a widget", "[q]uit"]
    rows = options
    |> Enum.with_index()
    |> Enum.reduce(
        [[], [], []],
        fn {string, index}, rows ->
          row = rem(index, 3)
          List.update_at(rows, row, &(&1 ++ [Span.new(string)]))
        end)

    %Table{rows: rows}
  end

  defp panels(%{width: w, height: h}) do
    area = %Rect{x: 0, y: 0, width: w, height: h}

    [header, body, footer] =
      Layout.split(area, :vertical, [{:length, 3}, {:fill, 1}, {:length, 3}])

    {header, body, footer}
  end

  @impl true
  def handle_event(%Event.Key{code: "q", kind: "press"}, state), do: {:stop, state}

  @impl true
  def handle_event(%Event.Key{kind: "press"} = key, state) do
    {focus, key} = Focus.handle_key(state.widgets_focus, key)
    state = %{state | widgets_focus: focus}

    case key do
      nil ->
        {:noreply, state}

      %Event.Key{code: "f", kind: "press"} ->
        {:noreply, %{state | main_widget_name: Focus.current(focus)}}

      key ->
        {:noreply, state}
    end
  end

  def handle_event(_event, state), do: {:noreply, state}
end
