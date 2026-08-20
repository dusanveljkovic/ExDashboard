defmodule Exdashboard.Layouts.FourPlusBig do
  alias Exdashboard.Widgets
  alias ExRatatui.{Layout, Event, Focus, Style}

  def make_state() do
    %{
      widgets_focus: Focus.new([:w1, :w2, :w3, :w4]),
      widgets: [
        { :w1, Widgets.Factory.create_widget(Widgets.Beszel.Main, [system_name: "debian-server"])},
        { :w2, Widgets.Factory.create_widget(Widgets.Adguardhome.Main)},
        { :w3, Widgets.Factory.create_widget(Widgets.Qbittorrent.Main)},
        { :w4, Widgets.Factory.create_widget(:dummy)},
      ],
      main_widget_name: :w1,
    }
  end

  def name do
    "4 small + big"
  end

  def render(state, frame) do
    {w1_rect, w2_rect, w3_rect, w4_rect, main_rect} = panels(frame)

    ws = Enum.zip(state.widgets, [w1_rect, w2_rect, w3_rect, w4_rect])
    |> Enum.map(fn {{widget_name, widget}, rect} ->
      {focus_wrapper(state, widget.small, widget_name), rect}
    end)

    main_widget = List.keyfind(state.widgets, state.main_widget_name, 0) |> elem(1)
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
          %{state | main_widget_name: Focus.current(focus)}
        key -> state
      end

    {state, key}
  end
end
