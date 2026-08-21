defmodule Exdashboard.Widgets.Utils do
  def humanize_bytes(bytes) when bytes < 1_024, do: {bytes, "B"}
  def humanize_bytes(bytes) when bytes < 1_048_576, do: {Float.round(bytes / 1_024, 2), "KiB"}
  def humanize_bytes(bytes) when bytes < 1_073_741_824, do: {Float.round(bytes / 1_048_576, 2), "MiB"}
  def humanize_bytes(bytes) when is_integer(bytes) or is_float(bytes) , do: {Float.round(bytes / 1_073_741_824, 2), "GiB"}
  def stringify_bytes(bytes, sep \\ " ") do
    {size, label} = humanize_bytes(bytes)
    Float.to_string(size * 1.0) <> sep <> label
  end
end
