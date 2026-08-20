defmodule Exdashboard.Widgets.Adguardhome.Main do
  defstruct [:client, :stats]
  alias Exdashboard.Widgets.Adguardhome

  def mount() do
    with  {:ok, base_url} <- System.fetch_env("ADGUARD_URL"),
          {:ok, username} <- System.fetch_env("ADGUARD_USERNAME"),
          {:ok, password} <- System.fetch_env("ADGUARD_PASSWORD"),
          token = "Basic " <> Base.encode64("#{username}:#{password}"),
          client = %{base_url: base_url, token: token},
          {:ok, data} <- refresh(%Adguardhome.Main{client: client, stats: %{}}) do
      {:ok, data}
    else
      {:error, {:query_failed, _status, _body}} -> {:error, "Query failed for ADGUARD"}
      :error -> {:error, "Parameters for ADGUARD not set propertly"}
    end
  end

  def stats(client) do
    url = client.base_url <> "/control/stats"

    case Req.get(url,
           headers: [{"Authorization", client.token}],
           connect_options: [transport_opts: [verify: :verify_none]]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def refresh(data) do
    with {:ok, new_stats} <- stats(data.client) do
      {:ok, %{data | stats: new_stats}}
    else
      {:error, {status, body}} -> {:error, {:query_failed, status, body}}
    end
  end

  def build(data, _options \\ []) do
    %{
      data: data,
      small: %Adguardhome.Small{data: data},
      big: %Adguardhome.Big{data: data},
      refresh_f: &refresh/1,
      refresh_ms: 10_000
    }
  end
end
