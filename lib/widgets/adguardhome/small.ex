defmodule Exdashboard.Widgets.Adguardhome.Small do
  defstruct [:data, :border_style]

  defimpl ExRatatui.Widget do
    alias ExRatatui.Widgets.{Block, Chart, Paragraph}
    alias ExRatatui.Style
    alias ExRatatui.Layout
    alias ExRatatui.Layout.Rect
    alias Exdashboard.Widgets.Adguardhome
    alias ExRatatui.Text
    alias ExRatatui.Text.{Line, Span}

    def render(%{data: data, border_style: border_style}, %Rect{} = rect) do
      [header, main, footer] = Layout.split(rect, :vertical, [{:length, 1}, {:min, 1}, {:length, 1}], margin: 1)

      stats = data.stats
      p_time = Kernel.round(stats["avg_processing_time"] * 1000)

      max_dns_queries = Enum.max(stats["dns_queries"])
      [
        {%Block{
           title: " adguardhome ",
           borders: [:all],
           border_style: border_style,
           border_type: :rounded
         }, rect},
        {%Paragraph{
            text: "DNS queries [#{max_dns_queries}]"
        }, header},
        {%Chart{
          datasets: [%Chart.Dataset{
            data: Enum.zip(0..24, stats["dns_queries"]),
            marker: :braille,
            style: %Style{fg: :green}
          }],
          y_axis: %Chart.Axis{bounds: {0, max_dns_queries + 200}},
          x_axis: %Chart.Axis{bounds: {0, 24}},

          }, main},
        {%Paragraph{
            text: Line.new([
              Span.new("Processing time: "),
              Span.new("#{p_time}ms", style: %Style{fg: color_p_time(p_time)})
            ])
        }, footer},
      ]
    end

    def color_p_time(time) do
      cond do
        time >= 150 -> :red
        time >= 90 -> :yellow
        true -> :green
      end
    end
  end


end
