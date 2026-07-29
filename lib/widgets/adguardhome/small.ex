defmodule Exdashboard.Widgets.Adguardhome.Small do
  defstruct [:data, :border_style]

  defimpl ExRatatui.Widget do
    alias ExRatatui.Widgets.{Paragraph, Block, Gauge}
    alias ExRatatui.Style
    alias ExRatatui.Layout
    alias ExRatatui.Layout.Rect
    alias Exdashboard.Widgets.Adguardhome

    def render(%{data: data, border_style: border_style}, %Rect{} = rect) do
      [
        {%Block{
           title: " adguardhome ",
           borders: [:all],
           border_style: border_style,
           border_type: :rounded
         }, rect},
        {%Paragraph{text: "#{data.counter}"}, rect}
      ]
    end
  end
end
