defmodule Exdashboard.Widgets.Beszel.Small do
  defstruct [:data, :system_name, border_style: nil]

  defimpl ExRatatui.Widget do
    alias ExRatatui.Widgets.{Paragraph, Block, Gauge}
    alias ExRatatui.Style
    alias ExRatatui.Layout
    alias ExRatatui.Layout.Rect
    alias Exdashboard.Widgets.Beszel

    def render(
          %{data: data, system_name: name, border_style: border_style},
          %Rect{} = rect
        ) do
      metrics = Beszel.Main.metrics_for(data, name)

      [title_row, cpu_rect, mem_rect, disk_rect] =
        Layout.split(
          rect,
          :vertical,
          [
            {:percentage, 10},
            {:min, 1},
            {:min, 1},
            {:min, 1}
          ],
          margin: 1
        )

      [
        {%Block{
           title: " beszel ",
           borders: [:all],
           border_style: border_style,
           border_type: :rounded
         }, rect},
        {%Paragraph{text: name, style: %Style{modifiers: [:bold]}}, title_row},
        {%Gauge{
           ratio: metrics.cpu_ratio,
           gauge_style: %Style{fg: Beszel.Main.color_for(metrics.cpu_ratio)},
           block: %Block{title: "cpu"}
         }, cpu_rect},
        {%Gauge{
           ratio: metrics.ram_ratio,
           label: metrics.ram_label,
           gauge_style: %Style{fg: Beszel.Main.color_for(metrics.ram_ratio)},
           block: %Block{title: "ram"}
         }, mem_rect},
        {%Gauge{
           ratio: metrics.mem_ratio,
           label: metrics.mem_label,
           gauge_style: %Style{fg: Beszel.Main.color_for(metrics.mem_ratio)},
           block: %Block{title: "mem"}
         }, disk_rect}
      ]
    end
  end
end
