defmodule Pulk.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Pulk.PubSub},
      Pulk.Pg,
      {Task.Supervisor, name: Pulk.TaskSupervisor},
      Pulk.Registry,
      Pulk.GameSupervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Pulk.Supervisor)
  end
end
