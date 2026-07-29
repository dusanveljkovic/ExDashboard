defmodule Exdashboard.Widgets.Factory do
  alias Exdashboard.Widgets

  def beszel(data, system_name) do
    %{
      data: data,
      small: %Widgets.Beszel.Small{data: data, system_name: system_name},
      big: %Widgets.Beszel.Big{data: data, system_name: system_name},
      refresh_f: &Widgets.Beszel.Main.refresh/1,
      refresh_ms: 60_000
    }
  end

  def adguardhome(data) do
    %{
      data: data,
      small: %Widgets.Adguardhome.Small{data: data},
      big: %Widgets.Adguardhome.Small{data: data},
      refresh_f: &Widgets.Adguardhome.Main.refresh/1,
      refresh_ms: 10_000
    }
  end
end
