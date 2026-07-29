defmodule Exdashboard.Widgets.Beszel.Big do
  defstruct [:data, :system_name, border_style: nil]

  defimpl ExRatatui.Widget do
    alias ExRatatui.Widgets.{Paragraph, Block, Chart}
    alias ExRatatui.Widgets.Chart.{Axis, Dataset}
    alias ExRatatui.Style
    alias ExRatatui.Layout
    alias ExRatatui.Layout.Rect
    alias Exdashboard.Widgets.Beszel

    @min_cpu_usage 15
    @min_temperature 70

    defp make_header(name, %{
           "os_name" => os_name,
           "kernel" => kernel,
           "cpu" => cpu,
           "memory" => memory
         }) do
      "#{name} | #{os_name} | #{kernel} | #{cpu} | #{Float.round(memory / 1024 / 1024 / 1024, 2)}GB"
    end

    def render(
          %{data: data, system_name: name, border_style: border_style},
          %Rect{} = rect
        ) do
      system = Enum.find(data.systems, fn x -> x["name"] == name end)
      system_stats = Map.get(data.stats, system["id"], %{})
      system_details = Map.get(data.details, system["id"], %{})
      history = Map.get(data.history, system["id"], %{})

      [header, body] =
        Layout.split(rect, :vertical, [{:length, 2}, {:fill, 1}], margin: 1)

      [left, right] =
        Layout.split(body, :horizontal, [{:percentage, 50}, {:percentage, 50}], margin: 1)

      [top_left, bottom_left] =
        Layout.split(left, :vertical, [{:percentage, 50}, {:percentage, 50}])

      [top_right, bottom_right] =
        Layout.split(right, :vertical, [{:percentage, 50}, {:percentage, 50}])

      cpu_bound = max(Enum.max(history.cpu), @min_cpu_usage)
      cpu_labels = equi_points(cpu_bound, "%")
      temperature_bound = max(Enum.max(history.temperature), @min_temperature)
      temperature_labels = equi_points(temperature_bound, "°C")
      ram_bound = system_stats["m"]
      ram_labels = equi_points(ram_bound, "GB")
      disk_bound = system_stats["d"]
      disk_labels = equi_points(disk_bound, "GB")

      time_labels = ["-1h", "-30m", "now"]

      [
        {%Block{
           title: " beszel - Big ",
           borders: [:all],
           border_type: :rounded
         }, rect},
        {%Paragraph{
           text: make_header(name, system_details),
           style: %Style{modifiers: [:bold]}
         }, header},
        {%Chart{
           datasets: [
             %Dataset{
               marker: :half_block,
               graph_type: :line,
               style: %Style{fg: :cyan},
               data: Enum.zip(0..60, history.cpu)
             }
           ],
           y_axis: %Axis{bounds: {0.0, cpu_bound}, labels: cpu_labels},
           x_axis: %Axis{bounds: {0, 60}, labels: time_labels},
           block: chart_block("CPU usage", :cyan)
         }, top_left},
        {%Chart{
           datasets: [
             %Dataset{
               marker: :half_block,
               graph_type: :line,
               style: %Style{fg: :blue},
               data: Enum.zip(0..60, history.temperature)
             }
           ],
           y_axis: %Axis{bounds: {0.0, temperature_bound}, labels: temperature_labels},
           x_axis: %Axis{bounds: {0, 60}, labels: time_labels},
           block: chart_block("Temperature", :blue)
         }, top_right},
        {%Chart{
           datasets: [
             %Dataset{
               marker: :half_block,
               graph_type: :line,
               style: %Style{fg: :green},
               data: Enum.zip(0..60, history.ram_used)
             }
           ],
           y_axis: %Axis{bounds: {0.0, ram_bound}, labels: ram_labels},
           x_axis: %Axis{bounds: {0, 60}, labels: time_labels},
           block: chart_block("RAM usage", :green)
         }, bottom_left},
        {%Chart{
           datasets: [
             %Dataset{
               marker: :half_block,
               graph_type: :line,
               style: %Style{fg: :magenta},
               data: Enum.zip(0..60, history.disk_used)
             }
           ],
           y_axis: %Axis{bounds: {0.0, disk_bound}, labels: disk_labels},
           x_axis: %Axis{bounds: {0, 60}, labels: time_labels},
           block: chart_block("Disk usage", :magenta)
         }, bottom_right}
      ]
    end

    defp chart_block(title, color) do
      %Block{
        border_style: %Style{fg: color},
        title: title,
        borders: [:all],
        border_type: :rounded,
        padding: {1, 1, 1, 0}
      }
    end

    defp equi_points(max, suffix, count \\ 5) do
      Enum.map(0..(count - 1), fn i -> "#{Kernel.round(i * max / (count - 1))}#{suffix}" end)
    end
  end
end
