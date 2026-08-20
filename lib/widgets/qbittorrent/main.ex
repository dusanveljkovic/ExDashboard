defmodule Exdashboard.Widgets.Qbittorrent.Main do
  defstruct [:client, :transfer_info, :torrents]
  alias Exdashboard.Widgets.Qbittorrent

  def connect(base_url, username, password) do
    url = base_url <> "/api/v2/auth/login"

    case Req.post(url, form: [username: username, password: password]) do
      {:ok, %Req.Response{status: 200}} ->
        {:ok, %{base_url: base_url}}

      {:ok, %Req.Response{status: 204}} ->
        {:ok, %{base_url: base_url}}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:auth_failed, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
  def mount() do
    with  {:ok, base_url} <- System.fetch_env("QBITTORRENT_URL"),
          {:ok, username} <- System.fetch_env("QBITTORRENT_USERNAME"),
          {:ok, password} <- System.fetch_env("QBITTORRENT_PASSWORD"),
          {:ok, client} <- connect(base_url, username, password),
          {:ok, data} <- refresh(%Qbittorrent.Main{client: client, transfer_info: %{}, torrents: []}) do
      {:ok, data}
    else
      {:error, {:auth_failed, _status, _body}} -> {:error, "Auth failed for QBITTORRENT"}
      {:error, {:query_failed, _status, _body}} -> {:error, "Query failed for QBITTORRENT"}
      :error -> {:error, "Parameters for QIBTORRENT not set propertly"}
    end
  end

  def query_torrents(client) do
    url = client.base_url <> "/api/v2/torrents/info"

    case Req.get(url,
           connect_options: [transport_opts: [verify: :verify_none]]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def query_transfer_info(client) do
    url = client.base_url <> "/api/v2/transfer/info"

    case Req.get(url,
           connect_options: [transport_opts: [verify: :verify_none]]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def refresh(%{client: client} = data) do
    with {:ok, torrents} <- query_torrents(client),
         {:ok, transfer_info} <- query_transfer_info(client) do
       {:ok, %{data | torrents: torrents, transfer_info: transfer_info}}
     else
      {:error, {status, body}} -> {:error, {:query_failed, status, body}}
     end

  end

  def build(data, _options \\ []) do
    %{
      data: data,
      small: %Qbittorrent.Small{data: data},
      big: %Qbittorrent.Big{data: data},
      refresh_f: &refresh/1,
      refresh_ms: 1_000
    }
  end
end
