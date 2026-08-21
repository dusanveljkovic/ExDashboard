defmodule Exdashboard.TUI do
  @version "beta"
  use ExRatatui.App

  alias ExRatatui.Layout.Rect
  alias ExRatatui.{Layout, Event, Focus, Style}
  alias ExRatatui.Widgets.{Block, Paragraph, Table}
  alias ExRatatui.Text.{Line, Span}

  @default_layout Exdashboard.Layouts.FourPlusBig
  def change_layout(layout) do
    layout.make_state()
    |> Map.put(:layout, layout)
    |> Map.put(:updated, nil)
  end
  @impl true
  def mount(_opts) do
    Exdashboard.Widgets.Factory.populate_store()
    GenServer.call(Exdashboard.Widgets.Store, :register_refreshes)
    state = change_layout(@default_layout)

    {:ok, state}
  end

  @impl true
  def handle_info({:refresh, id}, state) do
    {:noreply, %{state | updated: id}}
  end

  @impl true
  def render(%{layout: layout} = state, frame) do
    {header_rect, body_rect, footer_rect} = panels(frame)
    layout_render = layout.render(state, body_rect)

    [
      {make_header(layout.name()), header_rect},
      {make_footer(layout.options()), footer_rect},
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

  def make_footer(more_options) do
    options = ["[q]uit"] ++ more_options
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
  def handle_event(%Event.Key{code: "l", kind: "press"}, state) do
    new_layout = case state.layout do
      Exdashboard.Layouts.FourPlusBig -> Exdashboard.Layouts.Sixteen
      Exdashboard.Layouts.Sixteen -> Exdashboard.Layouts.FourPlusBig
    end
    {:noreply, change_layout(new_layout)}
  end

  @impl true
  def handle_event(%Event.Key{kind: "press"} = key, %{layout: layout} = state) do
    {state, key} = layout.handle_key(key, state)

    case key do
      nil ->
        {:noreply, state}

      key ->
        {:noreply, state}
    end
  end

  def handle_event(_event, state), do: {:noreply, state}
end
