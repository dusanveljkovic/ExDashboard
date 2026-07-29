defmodule Exdashboard do
  use ExRatatui.App

  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Paragraph}
  alias ExRatatui.Event

  @impl true
  def mount(_opts) do
    {:ok, %{count: 0}}
  end

  @impl true
  def render(state, frame) do
    area = %Rect{x: 0, y: 0, width: frame.width, height: frame.height}

    paragraph = %Paragraph{
      text: "Count: #{state.count}",
      style: %Style{fg: :green, modifiers: [:bold]},
      alignment: :center,
      block: %Block{
        title: "Hello world",
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: :cyan}
      }
    }

    [{paragraph, area}]
  end

  @impl true
  def handle_event(%Event.Key{code: "q", kind: "press"}, state), do: {:stop, state}

  def handle_event(%ExRatatui.Event.Key{code: code, kind: "press"}, state)
      when code in ["up", "k"] do
    {:noreply, %{state | count: state.count + 1}}
  end

  def handle_event(%ExRatatui.Event.Key{code: code, kind: "press"}, state)
      when code in ["down", "j"] do
    {:noreply, %{state | count: state.count - 1}}
  end

  def handle_event(_event, state), do: {:noreply, state}
end
