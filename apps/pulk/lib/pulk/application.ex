defmodule Pulk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Pulk.PubSub},
      # Start Finch
      {Finch, name: Pulk.Finch},
      Pulk.Pg,
      {Task.Supervisor, name: Pulk.TaskSupervisor},
      Pulk.Registry,
      Pulk.Game.GameSupervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Pulk.Supervisor)
  end
end
