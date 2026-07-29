defmodule Exdashboard.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Exdashboard.TUI, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Exdashboard.Supervisor)
  end
end
