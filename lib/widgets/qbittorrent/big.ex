defmodule Exdashboard.Widgets.Qbittorrent.Big do
  defstruct [:data, border_style: nil]

  defimpl ExRatatui.Widget do
    alias ExRatatui.Widgets.{Block, Table}
    alias ExRatatui.Style
    alias ExRatatui.Layout
    alias ExRatatui.Layout.Rect

    def render(
          %{data: data},
          %Rect{} = rect
        ) do

      stats = data.stats

      [left, right] =
        Layout.split(rect, :horizontal, [{:percentage, 50}, {:percentage, 50}], margin: 1)

      [top_left, bottom_left] =
        Layout.split(left, :vertical, [{:percentage, 50}, {:percentage, 50}])

      [top_right, bottom_right] =
        Layout.split(right, :vertical, [{:percentage, 50}, {:percentage, 50}])

      general_stats = make_general_stats(stats)
      top_client_rows = to_table_rows(stats["top_clients"])
      top_queried_domains = to_table_rows(stats["top_queried_domains"])
      top_blocked_domains = to_table_rows(stats["top_blocked_domains"])

      [
        {%Block{
           title: " adguardhome - Big ",
           borders: [:all],
           border_type: :rounded
         }, rect},
         {%Table{
          rows: general_stats,
          block: %Block{
            title: " General statistics ",
            borders: [:all],
            border_type: :rounded
          }
         }, top_left},
         {%Table{
          rows: top_client_rows,
          header: ["Client", "Request count"],
          block: %Block{
            title: " Top clients ",
            borders: [:all],
            border_type: :rounded
          }
         }, top_right},
         {%Table{
          rows: top_queried_domains,
          header: ["Domain", "Request count"],
          block: %Block{
            title: " Top queried domains ",
            borders: [:all],
            border_type: :rounded
          }
         }, bottom_left},
         {%Table{
          rows: top_blocked_domains,
          header: ["Domain", "Request count"],
          block: %Block{
            title: " Top blocked domains ",
            borders: [:all],
            border_type: :rounded
          }
         }, bottom_right}

      ]
    end

    defp make_general_stats(stats) do
      [
        ["DNS Queries", Integer.to_string(stats["num_dns_queries"])],
        ["Blocked by filteres", Integer.to_string(stats["num_blocked_filtering"])],
        ["Blocked malware/phishing", Integer.to_string(stats["num_replaced_safebrowsing"])],
        ["Average processing time", "#{Kernel.round(stats["avg_processing_time"] * 1000)}ms"]
      ]
    end
    defp to_table_rows(data) do
      Enum.map(data, fn map ->
          {key, val} = hd(Map.to_list(map))
          [key, (if is_integer(val), do: Integer.to_string(val), else: val)]
        end)
    end
  end
end
