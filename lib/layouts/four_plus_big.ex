defmodule Exdashboard.Layouts.FourPlusBig do
  alias Exdashboard.Widgets
  alias ExRatatui.{Layout, Event, Focus, Style}

  def make_state() do
    %{
      widgets_focus: Focus.new([:w1, :w2, :w3, :w4]),
      widgets: [
        { :w1, :beszel},
        { :w2, :adguardhome},
        { :w3, :qbittorrent},
        { :w4, :dummy},
      ],
      main_widget_name: :beszel,
    }
  end

  def name do
    "4 small + big"
  end

  def render(state, frame) do
    {w1_rect, w2_rect, w3_rect, w4_rect, main_rect} = panels(frame)

    ws = Enum.zip(state.widgets, [w1_rect, w2_rect, w3_rect, w4_rect])
    |> Enum.map(fn {{widget_pos, widget_name}, rect} ->
      widget = Exdashboard.Widgets.Store.get(widget_name)
      {focus_wrapper(state, widget.small, widget_pos), rect}
    end)

    main_widget = Exdashboard.Widgets.Store.get(state.main_widget_name)
    ws ++ [{main_widget.big, main_rect}]
  end

  def panels(rect) do
    [sidebar, main] =
      Layout.split(rect, :horizontal, [
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

    {w1, w2, w3, w4, main}
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

  def options do
    ["[Tab] cycle widgets", "[f]ocus a widget"]
  end

  def handle_key(key, state) do
    {focus, key} = Focus.handle_key(state.widgets_focus, key)
    state = %{state | widgets_focus: focus}

    state =
      case key do
        %Event.Key{code: "f", kind: "press"} ->
          {_, main_widget_name} = List.keyfind(state.widgets, Focus.current(focus), 0)
          %{state | main_widget_name: main_widget_name}
        key -> state
      end

    {state, key}
  end
end
