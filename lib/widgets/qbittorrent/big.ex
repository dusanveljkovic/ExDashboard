defmodule Exdashboard.Widgets.Qbittorrent.Big do
  defstruct [:data, border_style: nil]

  defimpl ExRatatui.Widget do
    alias ExRatatui.Widgets.{Block, Table}
    alias ExRatatui.Text.Span
    alias ExRatatui.Style
    alias ExRatatui.Layout.Rect
    alias Exdashboard.Widgets.Utils

    def render(
          %{data: %{torrents: torrents}},
          %Rect{} = rect
        ) do

      torrent_rows = make_torrent_rows(torrents)

      [
         {%Table{
          header: ["", "Name", "Size", "Progress", "Status", "Seeds", "Peers", "Down speed", "Up speed", "Ratio"],
          header_style: %Style{modifiers: [:bold]},
          widths: [{:max, 1}, {:min, 10}, {:max, 10}, {:max, 5}, {:max, 10}, {:max, 5}, {:max, 5}, {:max, 10}, {:max, 10}, {:max, 5}],
          rows: torrent_rows,
          block: %Block{
            title: " qbittorrent - Big ",
            borders: [:all],
            border_type: :rounded,
            padding: {1, 1, 1, 1}
          }}, rect}
      ]
    end

    def make_torrent_rows(torrents) do
      Enum.map(torrents,
      fn %{"name" => name,
      "size" => size_b,
      "progress" => progress,
      "state" => status,
      "num_seeds" => seeds,
      "num_leechs" => peers,
      "dlspeed" => down_speed,
      "upspeed" => up_speed,
      "ratio" => ratio
      } ->
        icon = case status do
          "stalledUP" -> %Span{content: "⬆", style: %Style{fg: :cyan}}
          "uploading" -> %Span{content: "⬆", style: %Style{fg: :cyan}}
          "downloading" -> %Span{content: "⬇", style: %Style{fg: :green}}
          "stalledDL" -> %Span{content: "⬇", style: %Style{fg: :green}}
          :else -> %Span{content: "?", style: %Style{fg: :yellow}}
        end
        size_str = Utils.stringify_bytes(size_b)
        progress = Float.to_string(Float.round(progress * 100.0, 2))
        dl_speed_str = Utils.stringify_bytes(down_speed)
        up_speed_str = Utils.stringify_bytes(up_speed)
        ratio = Float.to_string(Float.round(ratio * 1.0, 2))

        [icon,
          name,
          size_str,
          progress,
          status,
          Integer.to_string(seeds),
          Integer.to_string(peers),
          dl_speed_str,
          up_speed_str,
          ratio]
      end)
    end
  end
end
