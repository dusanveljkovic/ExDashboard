defmodule Exdashboard.Layouts.Sixteen do
  alias Exdashboard.Widgets
  alias ExRatatui.{Layout, Event, Focus, Style}

  def make_state() do
    %{
      widgets_focus: Focus.new(
        [:w1, :w2, :w3, :w4, :w5, :w6, :w7, :w8, :w9, :w10, :w11, :w12, :w13, :w14, :w15, :w16]),
      widgets: [
        { :w1, Widgets.Factory.create_widget(Widgets.Beszel.Main, [system_name: "debian-server"])},
        { :w2, Widgets.Factory.create_widget(Widgets.Adguardhome.Main)},
        { :w3, Widgets.Factory.create_widget(Widgets.Qbittorrent.Main)},
        { :w4, Widgets.Factory.create_widget(:dummy)},
        { :w5, Widgets.Factory.create_widget(:dummy)},
        { :w6, Widgets.Factory.create_widget(:dummy)},
        { :w7, Widgets.Factory.create_widget(:dummy)},
        { :w8, Widgets.Factory.create_widget(:dummy)},
        { :w9, Widgets.Factory.create_widget(:dummy)},
        { :w10, Widgets.Factory.create_widget(:dummy)},
        { :w11, Widgets.Factory.create_widget(:dummy)},
        { :w12, Widgets.Factory.create_widget(:dummy)},
        { :w13, Widgets.Factory.create_widget(:dummy)},
        { :w14, Widgets.Factory.create_widget(:dummy)},
        { :w15, Widgets.Factory.create_widget(:dummy)},
        { :w16, Widgets.Factory.create_widget(:dummy)}
      ],
      main_widget_name: :w1,
    }
  end

  def name do
    "16 small"
  end

  def render(state, frame) do
    w_rects = panels(frame)
    Enum.zip(state.widgets, w_rects)
    |> Enum.map(fn {{widget_name, widget}, rect} ->
      {focus_wrapper(state, widget.small, widget_name), rect}
    end)
  end

  def panels(rect) do
    rows =
      Layout.split(rect, :vertical, [
        {:percentage, 25},
        {:percentage, 25},
        {:percentage, 25},
        {:percentage, 25}
      ])
    Enum.reduce(rows, [], fn row, acc ->
      acc ++ Layout.split(row, :horizontal, [
        {:percentage, 25},
        {:percentage, 25},
        {:percentage, 25},
        {:percentage, 25}
      ])
    end)
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
    ["[Tab] cycle widgets"]
  end

  def handle_key(key, state) do
    {focus, key} = Focus.handle_key(state.widgets_focus, key)
    state = %{state | widgets_focus: focus}

    #case key do
    #  %Event.Key{code: "f", kind: "press"} ->
    #    {:noreply, %{state | main_widget_name: Focus.current(focus)}}
    #end

    {state, key}
  end
end
