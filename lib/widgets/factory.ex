defmodule Exdashboard.Widgets.Factory do
  alias ExRatatui.Widgets.{Paragraph, Block}
  alias ExRatatui.Style
  alias Exdashboard.Widgets

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

  def create_widget(module, options \\ [])
  def create_widget(:dummy, _options), do: error_widget("dummy")
  def create_widget(module, options) do
    mount_f = &module.mount/0
    factory_f = &module.build(&1, options)
    case mount_f.() do
      {:ok, data} ->
        factory_f.(data)
      {:error, reason} ->
        error_widget(reason)
    end
  end

  def populate_store() do
    Widgets.Store.put(:beszel, create_widget(Widgets.Beszel.Main, [system_name: "debian-server"]))
    Widgets.Store.put(:adguardhome, create_widget(Widgets.Adguardhome.Main))
    Widgets.Store.put(:qbittorrent, create_widget(Widgets.Qbittorrent.Main))
    Widgets.Store.put(:slskd, create_widget(Widgets.Slskd.Main))
    Widgets.Store.put(:dummy, create_widget(:dummy))
  end
end
