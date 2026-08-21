defmodule Exdashboard.Widgets.Slskd.Small do
  defstruct [:data, border_style: nil]


  defimpl ExRatatui.Widget do
    alias ExRatatui.Widgets.{Block, Gauge, Paragraph}
    alias ExRatatui.Text.Span
    alias ExRatatui.Style
    alias ExRatatui.Layout
    alias ExRatatui.Layout.Rect

    def render(
          %{data: %{application_info: app_info, transfers: transfers}, border_style: border_style},
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

        extract_and_sum = fn list, field ->
          Enum.reduce(list, 0, fn %{"directories" => dirs}, acc ->
            Enum.reduce(dirs, 0, fn %{"files" => files}, acc ->
              acc + Enum.reduce(files, 0, fn %{^field => val}, acc -> acc + val end)
            end) + acc
          end)
        end

        file_count = fn list ->
          count = Enum.reduce(list, 0, fn %{"directories" => dirs}, acc ->
            acc + Enum.reduce(dirs, 0, fn %{"fileCount" => f_cnt}, acc -> f_cnt + acc end)
          end)
          if count == 0, do: 1, else: count
        end

        dl_speed = extract_and_sum.(transfers[:downloads], "averageSpeed") / file_count.(transfers[:downloads])
        up_speed = extract_and_sum.(transfers[:uploads], "averageSpeed") / file_count.(transfers[:uploads])
        dl_speed_ratio = dl_speed / default_rate_limit
        up_speed_ratio = up_speed / default_rate_limit / 5
        dl_label = Exdashboard.Widgets.Utils.stringify_bytes(dl_speed)
        up_label = Exdashboard.Widgets.Utils.stringify_bytes(up_speed)

        dl_style = %Style{fg: :green}
        up_style = %Style{fg: :cyan}

        connection_status = app_info["server"]["isConnected"]
        connection_color = if connection_status, do: :green, else: :red
        connection_string = if connection_status, do: "connected", else: "disconnected"

      [
        {%Block{
           title: " slskd ",
           borders: [:all],
           border_style: border_style,
           border_type: :rounded
         }, rect},
        {%Gauge{
           ratio: dl_speed_ratio,
           label: dl_label,
           gauge_style: dl_style,
           block: %Block{title: "download"}
         }, download_speed_rect},
        {%Gauge{
           ratio: up_speed_ratio,
           label: up_label,
           gauge_style: up_style,
           block: %Block{title: "upload"}
        }, upload_speed_rect},
        {%Paragraph{
          text: [
            %Span{content: "Connection status: "},
            %Span{content: connection_string, style: %Style{fg: connection_color}}
          ]
        }, footer},
      ]
    end
  end
end
