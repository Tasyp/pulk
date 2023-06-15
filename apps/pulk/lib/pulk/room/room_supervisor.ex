defmodule Pulk.Room.RoomSupervisor do
  @moduledoc """
  Supervisor that controls room related gen servers
  """

  use Supervisor, restart: :permanent

  def start_link(init_arg) do
    %{room: room} = get_arguments(init_arg)
    Supervisor.start_link(__MODULE__, init_arg, name: via_tuple(room))
  end

  @impl true
  def init(init_arg) do
    %{room: room} = get_arguments(init_arg)

    children = [
      {Pulk.Room.RoomManager, [room: room]},
      {Pulk.Room.PlayersSupervisor, [room: room]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def via_tuple(%Pulk.Room{room_id: room_id}) do
    Pulk.Registry.via_tuple({__MODULE__, room_id})
  end

  defp get_arguments(init_arg) do
    room = Keyword.fetch!(init_arg, :room)
    %{room: room}
  end
end
