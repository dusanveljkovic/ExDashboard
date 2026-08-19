defmodule Exdashboard.Widgets.Factory do
  alias Exdashboard.Widgets
  alias ExRatatui.Widgets.{Paragraph, Block}
  alias ExRatatui.Style

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
      big: %Widgets.Adguardhome.Big{data: data},
      refresh_f: &Widgets.Adguardhome.Main.refresh/1,
      refresh_ms: 10_000
    }
  end

  def qbittorrent(data) do
    %{
      data: data,
      small: %Widgets.Qbittorrent.Small{data: data},
      big: %Widgets.Qbittorrent.Big{data: data},
      refresh_f: &Widgets.Qbittorrent.Main.refresh/1,
      refresh_ms: 10_000
    }
  end

  def error_widget(reason) do
    %{
      data: reason,
      small: %Paragraph{text: reason, block: %Block{
        title: " error ",
           borders: [:all],
           border_style: %Style{},
           border_type: :rounded}},
      big: %Paragraph{text: reason, block: %Block{
        title: " error ",
           borders: [:all],
           border_style: %Style{},
           border_type: :rounded}},
      refresh_f: &Function.identity/1,
      refresh_ms: 0
    }
  end

  defp _create_widget(mount_f, factory_f) do
    case mount_f.() do
      {:ok, data} ->
        factory_f.(data)
      {:error, reason} ->
        error_widget(reason)
    end
  end

  def create_widget(name, options \\ []) do
    case name do
      :beszel -> _create_widget(
        &Widgets.Beszel.Main.mount/0,
        &beszel(&1, Keyword.get(options, :system_name)))
      :adguardhome -> _create_widget(
        &Widgets.Adguardhome.Main.mount/0,
        &adguardhome/1)
      :qbittorrent -> _create_widget(
        &Widgets.Qbittorrent.Main.mount/0,
        &qbittorrent/1
      )
      :dummy -> error_widget("Dummy")
    end
  end
end
