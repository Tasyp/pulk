defmodule Pulk.RoomContext do
  @moduledoc """
  A context to manipulate rooms. It is intended to be the only publicly available way to do it.

  Containts a collection of method to operatate on rooms.

  ## Examples

      iex> {:ok, room} = RoomContext.create_room(Pulk.Room.new!())
      iex> {:ok, player} = RoomContext.add_player(room, Pulk.Player.new!())

  """
  alias Pulk.PlayerContext
  alias Pulk.Player.PlayerManager
  alias Pulk.Room.RoomManager
  alias Pulk.Room
  alias Pulk.Player

  @spec create_room(Room.t()) :: {:ok, Room.t()} | {:error, :already_started}
  def create_room(%Room{} = room) do
    case DynamicSupervisor.start_child(
           Pulk.GameSupervisor,
           {Room.RoomSupervisor, [room: room]}
         ) do
      {:ok, _} -> {:ok, room}
      {:error, {:already_started, _}} -> {:error, :already_started}
    end
  end

  @spec add_player(Room.t(), Player.t()) ::
          {:ok, Player.t()} | {:error, :already_added} | {:error, :too_many_players}
  def add_player(
        %Room{} = room,
        %Pulk.Player{} = player
      ) do
    if room.room_id == player.room_id do
      {:ok, player}
    else
      room_player = Pulk.Player.assign_room(player, room)

      case DynamicSupervisor.start_child(
             Room.PlayersSupervisor.via_tuple(room),
             {Pulk.Player.PlayerManager, [player: room_player, room: room]}
           ) do
        {:ok, _} -> {:ok, room_player}
        {:error, {:already_started, _}} -> {:error, :already_added}
        {:error, :max_children} -> {:error, :too_many_players}
      end
    end
  end

  @spec remove_player(Room.t(), Player.t()) :: :ok | {:error, :not_found}
  def remove_player(
        %Room{} = room,
        %Pulk.Player{} = player
      ) do
    with {:ok, player_pid} <- Pulk.Player.PlayerManager.lookup(player.player_id) do
      DynamicSupervisor.terminate_child(
        Room.PlayersSupervisor.via_tuple(room.room_id),
        player_pid
      )
    end
  end

  @spec get_players(Room.t()) :: list(Player.t())
  def get_players(%Room{} = room) do
    with :ok <- RoomManager.is_room_present?(room.room_id) do
      DynamicSupervisor.which_children(Room.PlayersSupervisor.via_tuple(room))
      |> Enum.filter(fn
        {:undefined, :restarting, _, _} -> false
        {:undefined, _pid, :worker, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {_id, pid, _type, _module} ->
        Pulk.Player.PlayerManager.fetch_player(pid)
      end)
      |> Enum.filter(fn
        {:ok, _player} -> true
        _ -> false
      end)
      |> Enum.map(fn {:ok, player} -> player end)
    end
  end

  @spec get_available_room() :: {:ok, Room.t()} | {:error, term()}
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
        {:ok, {:ok, %{is_available: true}}} -> true
        _ -> false
      end)
      |> Enum.map(fn {:ok, {:ok, response}} -> response end)
      |> Enum.sort_by(fn %{player_count: player_count} -> player_count end, :desc)
      |> List.first()

    case available_room do
      %{room: %Room{} = room} -> {:ok, room}
      _ -> create_room(Room.new!())
    end
  end

  @spec get_all_rooms() :: list(Room.t())
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

  @spec get_room(String.t()) :: {:error, :unknown_room} | {:ok, Room.t()}
  def get_room(room_id) do
    with :ok <- RoomManager.is_room_present?(room_id) do
      RoomManager.get_room(room_id)
    end
  end

  @spec get_room_boards(Room.t()) ::
          {:error, :unknown_room} | {:ok, list({Player.t(), Pulk.Game.Board.t()})}
  def get_room_boards(room) do
    boards =
      room
      |> get_players()
      |> Enum.map(fn player ->
        {:ok, board} = PlayerManager.get_board(player.player_id)
        {player, board}
      end)

    {:ok, boards}
  end

  @spec update_status(Room.t(), Room.status()) :: {:error, :unknown_room} | {:ok, Room.t()}
  def update_status(%Room{room_id: room_id}, status) do
    with :ok <- RoomManager.is_room_present?(room_id) do
      RoomManager.update_status(RoomManager.via_tuple(room_id), status)
    end
  end

  @spec is_room_available?(Room.t()) :: :ok | {:error, :unknown_room} | {:error, :room_busy}
  def is_room_available?(%Room{room_id: room_id}) do
    room_availability =
      with :ok <- RoomManager.is_room_present?(room_id) do
        RoomManager.get_availability(RoomManager.via_tuple(room_id))
      end

    case room_availability do
      {:error, reason} -> {:error, reason}
      {:ok, %{is_available: true}} -> :ok
      _ -> {:error, :room_busy}
    end
  end
end
