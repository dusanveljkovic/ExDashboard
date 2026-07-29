defmodule Exdashboard.Widgets.Adguardhome.Main do
  defstruct [:client, :stats, :counter]
  alias Exdashboard.Widgets.Adguardhome

  def mount() do
    base_url = ""
    username = ""
    password = ""
    token = "Basic " <> Base.encode64("#{username}:#{password}")
    client = %{base_url: base_url, token: token}

    data = %Adguardhome.Main{
      client: client,
      stats: %{},
      counter: 0
    }

    {:ok, data}
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
    new_stats = stats(data.client)
    new_counter = data.counter + 1
    %{data | stats: new_stats, counter: new_counter}
  end
end
