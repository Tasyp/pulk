defmodule Pulk.Game.GameSupervisor do
  @moduledoc """
  Root supervisor that controls all game rooms
  """

  use DynamicSupervisor, restart: :permanent

  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
