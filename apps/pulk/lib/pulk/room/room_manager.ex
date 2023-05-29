defmodule Pulk.Room.RoomManager do
  require Logger

  alias Pulk.Room
  alias Pulk.Room.GameMode
  alias Pulk.Player

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

  @spec via_tuple(String.t()) :: {:via, Registry, {Pulk.Registry, any}}
  def via_tuple(room_id) do
    Pulk.Registry.via_tuple({__MODULE__, room_id})
  end

  def get_room(pid) do
    GenServer.call(pid, :get_room)
  end

  def update_status(pid, status) do
    GenServer.call(pid, {:update_status, status})
  end

  def recalculate_room_status(%Player{room_id: room_id}) do
    recalculate_room_status(via_tuple(room_id))
  end

  def recalculate_room_status(pid) do
    GenServer.cast(pid, :recalculate_room_status)
  end

  def get_all_room_managers() do
    :pg.get_members(__MODULE__)
  end

  # Callbacks

  @impl true
  def init(%{room: room}) do
    :pg.join(__MODULE__, self())

    {:ok, game_mode} =
      GameMode.new!(room.game_mode.type)
      |> GameMode.init(room.game_mode.args)

    {:ok, %{room: room, game_mode: game_mode}}
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
    {:reply, {:ok, room}, state}
  end

  @impl true
  def handle_call({:update_status, status}, _from, %{room: room} = state) do
    {:ok, room} = Room.update_status(room, status)
    {:reply, {:ok, room}, %{state | room: room}}
  end

  @impl true
  def handle_cast(:recalculate_room_status, %{room: room, game_mode: game_mode} = state) do
    case GameMode.handle_room_update(game_mode, room) do
      {:ok, game_mode, room} ->
        {:noreply, %{state | game_mode: game_mode, room: room}}

      {:error, reason} ->
        Logger.error("Could not recalculate room #{room.room_id} status: #{inspect(reason)}")
        {:noreply, state}
    end
  end
end
