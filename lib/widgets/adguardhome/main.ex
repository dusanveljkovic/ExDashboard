defmodule Exdashboard.Widgets.Adguardhome.Main do
  defstruct [:client, :stats, :counter]
  alias Exdashboard.Widgets.Adguardhome

  def mount() do
    with  {:ok, base_url} <- System.fetch_env("ADGUARD_URL"),
          {:ok, username} <- System.fetch_env("ADGUARD_USERNAME"),
          {:ok, password} <- System.fetch_env("ADGUARD_PASSWORD") do
      token = "Basic " <> Base.encode64("#{username}:#{password}")
      client = %{base_url: base_url, token: token}

      data = %Adguardhome.Main{
      client: client,
      stats: %{},
      }

      data = refresh(data)

      {:ok, data}
    else
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
    {:ok, new_stats} = stats(data.client)
    %{data | stats: new_stats}
  end
end
