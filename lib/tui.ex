defmodule Exdashboard.TUI do
  use ExRatatui.App

  alias ExRatatui.Layout.Rect
  alias ExRatatui.{Layout, Event, Focus, Style}
  alias ExRatatui.Widgets.{Block, Paragraph, Table}
  alias ExRatatui.Text.{Line, Span}

  alias Exdashboard.Widgets

  @impl true
  def mount(_opts) do
    state = %{
      widgets_focus: Focus.new([:w1, :w2, :w3, :w4]),
      widgets: %{
        w1: Widgets.Factory.create_widget(:beszel, [system_name: "debian-server"]),
        w2: Widgets.Factory.create_widget(:adguardhome),
        w3: Widgets.Factory.create_widget(:qbittorrent),
        w4: Widgets.Factory.create_widget(:dummy),
      },
      main_widget_name: :w1,
      current_view: :four_small
    }

    register_refreshes(state)
    {w, h} = ExRatatui.terminal_size()
    {:ok, register_regions(state, w, h)}
  end

  defp register_refreshes(state) do
    Enum.each(state.widgets, fn {name, config} ->
      if config.refresh_ms > 0 do
        Process.send_after(self(), {:refresh, name}, config.refresh_ms)
      end
    end)
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
  def render(state, frame) do
    {header_rect, footer_rect, w1_rect, w2_rect, w3_rect, w4_rect, main_rect} = panels(frame)

    w1 = focus_wrapper(state, state.widgets.w1.small, :w1)
    w2 = focus_wrapper(state, state.widgets.w2.small, :w2)
    w3 = focus_wrapper(state, state.widgets.w3.small, :w3)
    w4 = focus_wrapper(state, state.widgets.w4.small, :w4)

    [
      {make_header(state.current_view), header_rect},
      {make_footer(), footer_rect},
      {w1, w1_rect},
      {w2, w2_rect},
      {w3, w3_rect},
      {w4, w4_rect},
      {Map.get(state.widgets, state.main_widget_name).big, main_rect}
    ]
  end

  def make_header(current_view) do
    view_str = case current_view do
      :four_small -> "4 small + 1 big"
      :sixteen_small -> "16 small"
    end
    %Paragraph{
      text: [
        %Line{spans: []},
        %Line{spans: [%Span{content: "ExDashboard - monitor everything"}], alignment: :center},
        %Line{spans: [%Span{content: "Layout: #{view_str}"}], alignment: :center},
      ]
    }
  end

  def make_footer() do
    options = ["[Tab] cycle", "[f]ocus a widget"]
    rows = options
    |> Enum.with_index()
    |> Enum.reduce(
        [[], [], []],
        fn {string, index}, rows ->
          row = rem(index, 3)
          List.update_at(rows, row, &(&1 ++ [Span.new(string)]))
        end)

    %Table{
      rows: rows
    }
  end

  def focus_wrapper(state, widget, key) do
    border =
      if Focus.focused?(state.widgets_focus, key),
        do: %Style{fg: :cyan},
        else: %Style{fg: :gray}

    if Map.has_key?(widget, :border_style) do
      %{widget | border_style: border}
    else
      %{widget | block: %{widget.block | border_style: border}}
    end
  end

  defp panels(%{width: w, height: h}) do
    area = %Rect{x: 0, y: 0, width: w, height: h}

    [header, body, footer] =
      Layout.split(area, :vertical, [{:length, 3}, {:min, 0}, {:length, 3}])

    [sidebar, main] =
      Layout.split(body, :horizontal, [
        {:percentage, 25},
        {:percentage, 75}
      ])

    [w1, w2, w3, w4] =
      Layout.split(sidebar, :vertical, [
        {:percentage, 25},
        {:percentage, 25},
        {:percentage, 25},
        {:percentage, 25}
      ])

    {header, footer, w1, w2, w3, w4, main}
  end

  defp register_regions(state, w, h) do
    {_header, _footer, w1_rect, w2_rect, w3_rect, w4_rect, _main_rect} = panels(%{width: w, height: h})

    focus =
      Focus.set_regions(state.widgets_focus, %{
        w1: w1_rect,
        w2: w2_rect,
        w3: w3_rect,
        w4: w4_rect
      })

    %{state | widgets_focus: focus}
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
