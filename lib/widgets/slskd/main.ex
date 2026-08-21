defmodule Exdashboard.Widgets.Slskd.Main do
  defstruct [:client, :application_info, :transfers]

  alias Exdashboard.Widgets.Slskd
  def mount() do
    with  {:ok, base_url} <- System.fetch_env("SLSKD_URL"),
          {:ok, api_key} <- System.fetch_env("SLSKD_API_KEY"),
          {:ok, data} <- refresh(
            %Slskd.Main{client: %{base_url: base_url, api_key: api_key},
            application_info: %{}, transfers: %{}}) do

      {:ok, data}
    else
      {:error, {:query_failed, _status, _body}} -> {:error, "Query failed for QBITTORRENT"}
      :error -> {:error, "Parameters for SLSKD not set propertly"}
    end
  end

  def refresh(%Slskd.Main{client: client} = data) do
    with {:ok, app_info} <- query(client, "/api/v0/application"),
    {:ok, downloads} <- query(client, "/api/v0/transfers/downloads"),
    {:ok, uploads} <- query(client, "/api/v0/transfers/uploads") do
      {:ok, %{data | application_info: app_info, transfers: %{downloads: downloads, uploads: uploads}}}
    else
      {:error, {status, body}} -> {:error, {:query_failed, status, body}}
    end
  end

  def query(%{base_url: base_url, api_key: api_key}, url_extension) do
    url = base_url <> url_extension
    case Req.get(url, headers: [{"X-Api-Key", api_key}]) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def build(data, _options \\ []) do
    %{
      data: data,
      small: %Slskd.Small{data: data},
      big: %Slskd.Big{data: data},
      refresh_f: &refresh/1,
      refresh_ms: 1_000
    }
  end
end
