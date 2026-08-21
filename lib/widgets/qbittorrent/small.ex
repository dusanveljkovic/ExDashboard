defmodule Exdashboard.Widgets.Qbittorrent.Small do
  defstruct [:data, border_style: nil]


  defimpl ExRatatui.Widget do
    alias ExRatatui.Widgets.{Block, Gauge, Paragraph}
    alias ExRatatui.Text.Span
    alias ExRatatui.Style
    alias ExRatatui.Layout
    alias ExRatatui.Layout.Rect

    def render(
          %{data: %{transfer_info: transfer_info}, border_style: border_style},
          %Rect{} = rect
        ) do

      [download_speed_rect, upload_speed_rect, footer] =
        Layout.split(
          rect,
          :vertical,
          [
            {:min, 1},
            {:min, 1},
            {:length, 1},
          ],
          margin: 1
        )
        default_rate_limit = 20480000

        dl_rate_limit = transfer_info["dl_rate_limit"]
        up_rate_limit = transfer_info["up_rate_limit"]
        dl_max_speed = if dl_rate_limit == 0, do: default_rate_limit, else: dl_rate_limit
        up_max_speed = if up_rate_limit == 0, do: default_rate_limit / 2, else: up_rate_limit
        dl_speed_ratio = transfer_info["dl_info_speed"] / dl_max_speed
        up_speed_ratio = transfer_info["up_info_speed"] / up_max_speed
        dl_label = Exdashboard.Widgets.Utils.stringify_bytes(transfer_info["dl_info_speed"])
        up_label = Exdashboard.Widgets.Utils.stringify_bytes(transfer_info["up_info_speed"])
        total_dl_label = Exdashboard.Widgets.Utils.stringify_bytes(transfer_info["dl_info_data"])
        total_up_label = Exdashboard.Widgets.Utils.stringify_bytes(transfer_info["up_info_data"])
        dl_style = %Style{fg: :green}
        up_style = %Style{fg: :cyan}

        connection_status = transfer_info["connection_status"]
        connection_color = case connection_status do
          "connected" -> :green
          "firewalled" -> :yellow
          "disconnected" -> :red
        end

      [
        {%Block{
           title: " qbittorrent ",
           borders: [:all],
           border_style: border_style,
           border_type: :rounded
         }, rect},
        {%Gauge{
           ratio: dl_speed_ratio,
           label: dl_label,
           gauge_style: dl_style,
           block: %Block{title: "download (#{total_dl_label})"}
         }, download_speed_rect},
        {%Gauge{
           ratio: up_speed_ratio,
           label: up_label,
           gauge_style: up_style,
           block: %Block{title: "upload (#{total_up_label})"}
        }, upload_speed_rect},
        {%Paragraph{
          text: [
            %Span{content: "Connection status: "},
            %Span{content: connection_status, style: %Style{fg: connection_color}}
          ]
        }, footer},
      ]
    end
  end
end
