defmodule Pulk.Room.PlayersSupervisor do
  @moduledoc """
  Supervisor that controls room players
  """

  use DynamicSupervisor, restart: :permanent

  def start_link(init_arg) do
    room = Keyword.fetch!(init_arg, :room)

    DynamicSupervisor.start_link(__MODULE__, room, name: via_tuple(room))
  end

  @impl true
  def init(%Pulk.Room{max_player_limit: max_player_limit}) do
    DynamicSupervisor.init(max_children: max_player_limit, strategy: :one_for_one)
  end

  def via_tuple(%Pulk.Room{room_id: room_id}) do
    Pulk.Registry.via_tuple({__MODULE__, room_id})
  end
end
