defmodule Exdashboard.Widgets.Slskd.Big do
  defstruct [:data, border_style: nil]

  defimpl ExRatatui.Widget do
    alias ExRatatui.Widgets.{Block, Table}
    alias ExRatatui.Text.Span
    alias ExRatatui.Style
    alias ExRatatui.Layout.Rect
    alias Exdashboard.Widgets.Utils

    def render(
          %{data: data},
          %Rect{} = rect
        ) do

      [
        {%Block{}, rect}
      ]
    end
  end
end
