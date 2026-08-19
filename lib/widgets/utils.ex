defmodule Exdashboard.Widgets.Utils do
  def humanize_bytes(bytes) when bytes < 1_024, do: {bytes, "B"}
  def humanize_bytes(bytes) when bytes < 1_048_576, do: {Float.round(bytes / 1_024, 2), "KiB"}
  def humanize_bytes(bytes) when bytes < 1_073_741_824, do: {Float.round(bytes / 1_048_576, 2), "MiB"}
  def humanize_bytes(bytes) when is_integer(bytes) , do: {Float.round(bytes / 1_073_741_824, 2), "GiB"}
end
