defmodule Exdashboard.Widgets.Beszel.Main do
  defstruct [:client, :systems, :stats, :history, :details]
  alias Exdashboard.Widgets.Beszel

  def connect(base_url, email, password) do
    url = base_url <> "/api/collections/users/auth-with-password"

    case Req.post(url, json: %{identity: email, password: password}) do
      {:ok, %Req.Response{status: 200, body: %{"token" => token}}} ->
        {:ok, %{base_url: base_url, token: token}}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:auth_failed, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def list(client, collection, opts \\ []) do
    params = opts |> Keyword.take([:filter, :sort, :fields, :perPage, :page]) |> Enum.into(%{})
    url = client.base_url <> "/api/collections/#{collection}/records"

    case Req.get(url, headers: [{"Authorization", client.token}], params: params) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def systems(client, opts \\ []), do: list(client, "systems", opts)

  def latest_stat(client, system_id, type \\ "1m") do
    filter = ~s(system = "#{system_id}" && type = "#{type}")

    case list(client, "system_stats", filter: filter, sort: "-created", perPage: 1) do
      {:ok, %{"items" => [item | _]}} -> {:ok, item["stats"] || %{}}
      {:ok, %{"items" => []}} -> {:ok, %{}}
      error -> error
    end
  end

  def history(client, system_id, minutes \\ 60, type \\ "1m") do
    since =
      DateTime.utc_now()
      |> DateTime.add(-minutes * 60, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_naive()
      |> NaiveDateTime.to_iso8601()
      |> String.replace("T", " ")
      |> Kernel.<>("Z")

    filter = ~s(system = "#{system_id}" && type = "#{type}" && created >= "#{since}")

    case list(client, "system_stats", filter: filter, sort: "created", perPage: minutes + 5) do
      {:ok, %{"items" => items}} -> {:ok, make_history(items)}
      error -> error
    end
  end

  def get_details(client, system_id) do
    filter = ~s(system="#{system_id}")

    case list(client, "system_details", filter: filter, perPage: 1) do
      {:ok, %{"items" => [item | _]}} -> {:ok, item || %{}}
      {:ok, %{"items" => []}} -> {:ok, %{}}
      error -> error
    end
  end

  defp make_history(items) do
    %{
      cpu: Enum.map(items, fn i -> get_in(i, ["stats", "cpu"]) || 0.0 end),
      ram_used: Enum.map(items, fn i -> get_in(i, ["stats", "mu"]) || 0.0 end),
      disk_used: Enum.map(items, fn i -> get_in(i, ["stats", "du"]) || 0.0 end),
      temperature: Enum.map(items, fn i -> get_in(i, ["stats", "t", "k10temp"]) || 0.0 end)
    }
  end

  def mount() do
    base_url = ""
    email = ""
    password = ""

    with {:ok, client} <- connect(base_url, email, password) do
      data = %Beszel.Main{
        client: client,
        systems: [],
        stats: %{}
      }

      {:ok, data}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def refresh(%Beszel.Main{} = data) do
    case systems(data.client, sort: "name") do
      {:ok, %{"items" => systems}} ->
        stats =
          Map.new(systems, fn sys ->
            case latest_stat(data.client, sys["id"]) do
              {:ok, s} -> {sys["id"], s}
              {:error, _} -> {sys["id"], %{}}
            end
          end)

        history =
          Map.new(systems, fn sys ->
            case history(data.client, sys["id"]) do
              {:ok, h} -> {sys["id"], h}
              {:error, _} -> {sys["id"], %{}}
            end
          end)

        details =
          Map.new(systems, fn sys ->
            case get_details(data.client, sys["id"]) do
              {:ok, s} -> {sys["id"], s}
              {:error, _} -> {sys["id"], %{}}
            end
          end)

        %Beszel.Main{data | systems: systems, stats: stats, history: history, details: details}
    end
  end

  def metrics_for(%Beszel.Main{systems: systems, stats: stats}, system_name) do
    system = Enum.find(systems, fn x -> x["name"] == system_name end)
    s = Map.get(stats, system["id"], %{})

    %{
      name: system["name"],
      cpu_ratio: ratio(s["cpu"]),
      ram_ratio: ratio(s["mp"]),
      mem_ratio: ratio(s["dp"]),
      ram_label: "#{s["m"]}GB / #{s["mu"]}GB",
      mem_label: "#{s["d"]}GB / #{s["du"]}GB"
    }
  end

  defp ratio(v) when is_number(v),
    do: v |> Kernel./(100.0) |> max(0.0) |> min(1.0) |> Float.round(2)

  defp ratio(_), do: 0.0

  def color_for(ratio) do
    cond do
      ratio >= 0.9 -> :red
      ratio >= 0.7 -> :yellow
      true -> :green
    end
  end
end
