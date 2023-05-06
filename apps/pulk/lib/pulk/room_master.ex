defmodule Pulk.RoomMaster do
  alias Pulk.Room.RoomManager
  alias Pulk.Player.PlayerManager

  @spec create_room(Pulk.Room.t()) :: {:ok, Pulk.Room.t()} | {:error, :already_started}
  def create_room(%Pulk.Room{} = room) do
    case DynamicSupervisor.start_child(
           Pulk.Game.Supervisor,
           {Pulk.Room.RoomSupervisor, [room: room]}
         ) do
      {:ok, _} -> {:ok, room}
      {:error, {:already_started, _}} -> {:error, :already_started}
    end
  end

  @spec add_player(Pulk.Room.t(), Pulk.Player.t()) ::
          {:ok} | {:error, :already_added} | {:error, :too_many_players}
  def add_player(
        %Pulk.Room{} = room,
        %Pulk.Player{} = player
      ) do
    room_player = Pulk.Player.assign_room(player, room)

    case DynamicSupervisor.start_child(
           Pulk.Room.PlayersSupervisor.via_tuple(room),
           {Pulk.Player.PlayerManager, [player: room_player]}
         ) do
      {:ok, _} -> {:ok, room_player}
      {:error, {:already_started, _}} -> {:error, :already_added}
      {:error, :max_children} -> {:error, :too_many_players}
    end
  end

  @spec remove_player(Pulk.Room.t(), Pulk.Player.t()) :: :ok | {:error, :not_found}
  def remove_player(
        %Pulk.Room{} = room,
        %Pulk.Player{} = player
      ) do
    with {:ok, player_pid} <- Pulk.Player.PlayerManager.lookup(player.player_id) do
      DynamicSupervisor.terminate_child(
        Pulk.Room.PlayersSupervisor.via_tuple(room.room_id),
        player_pid
      )
    end
  end

  @spec get_players(Pulk.Room.t()) :: list(Pulk.Player.t())
  def get_players(%Pulk.Room{} = room) do
    DynamicSupervisor.which_children(Pulk.Room.PlayersSupervisor.via_tuple(room))
    |> Enum.filter(fn
      {:undefined, :restarting, _, _} -> false
      {:undefined, _pid, :worker, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {_id, pid, _type, _module} ->
      Pulk.Player.PlayerManager.get_player(pid)
    end)
  end

  @spec get_available_room() :: {:ok, Pulk.Room.t()} | {:error, :all_rooms_busy}
  def get_available_room() do
    room_managers = RoomManager.get_all_room_managers()

    available_room =
      room_managers
      |> Enum.map(
        &Task.Supervisor.async_nolink(Pulk.TaskSupervisor, fn ->
          RoomManager.get_availability(&1)
        end)
      )
      |> Task.yield_many(:timer.seconds(2))
      |> Enum.map(fn {task, res} ->
        res || Task.shutdown(task, :brutal_kill)
      end)
      |> Enum.filter(fn
        {:ok, _value} -> true
        _ -> false
      end)
      |> Enum.map(fn {:ok, response} -> response end)
      |> Enum.sort_by(fn %{player_count: player_count} -> player_count end, :desc)
      |> List.first()

    case available_room do
      %{room: %Pulk.Room{} = room} -> {:ok, room}
      _ -> {:error, :all_rooms_busy}
    end
  end

  @spec get_all_rooms() :: list(Pulk.Room.t())
  def get_all_rooms do
    room_managers = RoomManager.get_all_room_managers()

    rooms =
      room_managers
      |> Enum.map(
        &Task.Supervisor.async(Pulk.TaskSupervisor, fn ->
          RoomManager.get_room(&1)
        end)
      )
      |> Enum.map(&Task.await/1)

    rooms
  end

  @spec get_room(String.t()) :: {:error, :not_found} | {:ok, Pulk.Room.t()}
  def get_room(room_id) do
    if RoomManager.is_room_present?(room_id) do
      RoomManager.get_room(RoomManager.via_tuple(room_id))
    else
      :error
    end
  end
end
