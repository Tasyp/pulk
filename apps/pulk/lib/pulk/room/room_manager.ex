defmodule Pulk.Room.RoomManager do
  @moduledoc """
  GenServer that keeps state of an active room
  """
  require Logger

  alias Pulk.Room
  alias Pulk.Player
  alias Pulk.Room.GameMode

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

  @spec create_room(Room.t()) :: {:ok, Room.t()} | {:error, term()}
  def create_room(%Room{} = room) do
    case DynamicSupervisor.start_child(
           Pulk.GameSupervisor,
           {Room.RoomSupervisor, [room: room]}
         ) do
      {:ok, _} -> {:ok, room}
      {:error, {:already_started, _}} -> {:error, :already_started}
    end
  end

  @spec add_player(Room.t(), Player.t()) :: {:ok, Player.t()} | {:error, term()}
  def add_player(%Room{room_id: room_id}, %Player{room_id: player_room_id} = player)
      when room_id == player_room_id,
      do: {:ok, player}

  def add_player(
        %Room{} = room,
        %Player{} = player
      ) do
    room_player = Player.assign_room(player, room)

    case DynamicSupervisor.start_child(
           Room.PlayersSupervisor.via_tuple(room),
           {Player.PlayerManager, [player: room_player, room: room]}
         ) do
      {:ok, _} -> {:ok, room_player}
      {:error, {:already_started, _}} -> {:error, :already_added}
      {:error, :max_children} -> {:error, :too_many_players}
    end
  end

  @spec remove_player(Room.t(), Player.t()) :: :ok | {:error, term()}
  def remove_player(
        %Room{room_id: room_id},
        %Pulk.Player{player_id: player_id}
      ) do
    with {:ok, player_pid} <- Player.PlayerManager.lookup(player_id) do
      DynamicSupervisor.terminate_child(
        Room.PlayersSupervisor.via_tuple(room_id),
        player_pid
      )
    end
  end

  @spec get_players(Room.t()) :: {:ok, list(Player.t())} | {:error, term()}
  def get_players(%Room{} = room) do
    with :ok <- is_room_present?(room.room_id) do
      DynamicSupervisor.which_children(Room.PlayersSupervisor.via_tuple(room))
      |> Enum.filter(fn
        {:undefined, :restarting, _, _} -> false
        {:undefined, _pid, :worker, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {_id, pid, _type, _module} ->
        case Player.PlayerManager.fetch_player(pid) do
          {:ok, player} -> player
          error -> error
        end
      end)
      |> take_error()
    end
  end

  defp take_error(items) do
    case Enum.find(items, &match_error/1) do
      nil -> {:ok, items}
      error -> error
    end
  end

  defp match_error({:error, _}), do: true
  defp match_error(_), do: false

  @spec fetch_room_boards(Room.t()) ::
          {:ok, list({Player.t(), Pulk.Game.Board.t()})} | {:error, term()}
  def fetch_room_boards(%Room{} = room) do
    with {:ok, players} <- get_players(room) do
      players
      |> Enum.map(fn %Player{player_id: player_id} = player ->
        case Player.PlayerManager.get_board(player_id) do
          {:ok, board} -> {player, board}
          {:error, reason} -> {:error, reason}
        end
      end)
      |> take_error()
    end
  end

  @spec fetch_available_room() :: {:ok, Room.t()} | {:error, term()}
  def fetch_available_room() do
    available_room =
      get_all_room_managers()
      |> Enum.map(
        &Task.Supervisor.async_nolink(Pulk.TaskSupervisor, fn ->
          get_availability(&1)
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

  @spec fetch_room(String.t()) :: {:ok, Room.t()} | {:error, term()}
  def fetch_room(room_id) do
    with :ok <- is_room_present?(room_id) do
      GenServer.call(via_tuple(room_id), :get_room)
    end
  end

  def recalculate_room_status(room_id) do
    GenServer.cast(via_tuple(room_id), :recalculate_room_status)
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
      is_available: player_count < room.max_player_limit && room.status == :initial,
      player_count: player_count
    }

    {:reply, {:ok, response}, state}
  end

  @impl true
  def handle_call(:get_room, _from, %{room: room} = state) do
    {:reply, {:ok, room}, state}
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
