defmodule Pulk.Room.RoomManager do
  use GenServer, restart: :permanent

  def start_link(init_args) do
    room = Keyword.fetch!(init_args, :room)

    GenServer.start_link(
      __MODULE__,
      %{room: room},
      name: via_tuple(room.room_id)
    )
  end

  def get_availability(pid) do
    GenServer.call(pid, :get_availability)
  end

  @spec is_room_present?(String.t()) :: :ok | {:error, :unknown_room}
  def is_room_present?(room_id) do
    case Pulk.Registry.lookup({__MODULE__, room_id}) do
      [] -> {:error, :unknown_room}
      _ -> :ok
    end
  end

  def via_tuple(room_id) do
    Pulk.Registry.via_tuple({__MODULE__, room_id})
  end

  def get_room(pid) do
    GenServer.call(pid, :get_room)
  end

  @spec via_tuple(String.t()) :: {:via, Registry, {Pulk.Registry, any}}
  def get_all_room_managers() do
    :pg.get_members(__MODULE__)
  end

  # Callbacks

  @impl true
  def init(state) do
    :pg.join(__MODULE__, self())
    {:ok, state}
  end

  @impl true
  def handle_call(:get_availability, _from, %{room: room} = state) do
    %{specs: player_count} =
      DynamicSupervisor.count_children(Pulk.Room.PlayersSupervisor.via_tuple(room))

    response = %{
      room: room,
      is_available: player_count < room.max_player_limit,
      player_count: player_count
    }

    {:reply, {:ok, response}, state}
  end

  @impl true
  def handle_call(:get_room, _from, %{room: room} = state) do
    {:reply, room, state}
  end
end
