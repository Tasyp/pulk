defmodule Pulk.Player.PlayerManager do
  @moduledoc """
  GenServer that keeps state of an active player
  """

  use GenServer

  require Logger

  alias Phoenix.PubSub
  alias Pulk.Game.Board
  alias Pulk.Room.RoomManager
  alias Pulk.Game.Gravity

  def start_link(init_args) do
    player = Keyword.fetch!(init_args, :player)
    room = Keyword.fetch!(init_args, :room)

    GenServer.start_link(
      __MODULE__,
      %{player: player, room: room},
      name: via_tuple(player.player_id)
    )
  end

  @spec is_player_present?(String.t()) :: :ok | {:error, :unknown_player}
  def is_player_present?(player_id) do
    case Pulk.Registry.lookup({__MODULE__, player_id}) do
      [] -> {:error, :unknown_player}
      _ -> :ok
    end
  end

  def get_player(pid) do
    GenServer.call(pid, :get_player)
  end

  def get_board(pid) do
    GenServer.call(pid, :get_board)
  end

  def update_board(pid, board_update, opts \\ []) do
    GenServer.call(pid, {:update_board, board_update, opts})
  end

  def update_board_status(pid, board_status) do
    GenServer.call(pid, {:update_board_status, board_status})
  end

  def update_matrix(pid, raw_matrix) do
    GenServer.call(pid, {:update_matrix, raw_matrix})
  end

  def set_placement(pid, placement) do
    GenServer.call(pid, {:set_placement, placement})
  end

  def subscribe_to_board_updates(player_id) do
    PubSub.subscribe(Pulk.PubSub, "player:#{player_id}:board")
  end

  def publish_board(pid) do
    GenServer.cast(pid, {:publish_board})
  end

  def lookup(player_id) do
    case Pulk.Registry.lookup({__MODULE__, player_id}) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

  def via_tuple(player_id) do
    Pulk.Registry.via_tuple({__MODULE__, player_id})
  end

  @impl true
  def init(%{room: %Pulk.Room{} = room, player: %Pulk.Player{} = player}) do
    {size_x, size_y} = room.board_size
    {:ok, board} = Board.new(size_x, size_y)

    # TODO: Start tick timer when board is actually completed
    Process.send_after(self(), :timer_tick, :timer.seconds(5))

    {:ok, %{player: player, board: board}}
  end

  @impl true
  def handle_call(:get_player, _from, %{player: player} = state) do
    {:reply, {:ok, player}, state}
  end

  @impl true
  def handle_call(:get_board, _from, %{board: board} = state) do
    {:reply, {:ok, board}, state}
  end

  @impl true
  def handle_call({:update_matrix, matrix}, _from, %{board: board} = state) do
    {response, state} =
      case Board.update_matrix(board, matrix) do
        {:ok, board} -> {{:ok, board}, %{state | board: board}}
        {:error, reason} -> {{:error, reason}, state}
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call(
        {:update_board, board_update, opts},
        _from,
        %{board: board, player: player} = state
      ) do
    recalculate? = Keyword.get(opts, :recalculate?, false)

    {response, state} =
      case Board.update(board, board_update, recalculate?: recalculate?) do
        {:ok, board} ->
          RoomManager.recalculate_room_status(player.room_id)

          {{:ok, board}, %{state | board: board}}

        {:error, reason} ->
          {{:error, reason}, state}
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call(
        {:update_board_status, board_status},
        _from,
        %{board: board} = state
      ) do
    {:ok, board} = Board.update_status(board, board_status)
    {:reply, {:ok, board}, %{state | board: board}}
  end

  @impl true
  def handle_call({:set_placement, placement}, _from, %{board: board} = state) do
    {:ok, board} = Board.set_placement(board, placement)
    {:reply, {:ok, board}, %{state | board: board}}
  end

  @impl true
  def handle_cast({:publish_board}, %{board: board, player: player} = state) do
    case PubSub.broadcast(
           Pulk.PubSub,
           "player:#{player.player_id}:board",
           {:internal_board_update, board}
         ) do
      {:error, reason} ->
        Logger.error("Board broadcast for player #{player.player_id}: #{inspect(reason)}")

      _ ->
        # ignore
        nil
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:timer_tick, %{board: %Board{status: :complete}, player: player} = state) do
    # Board is complete. We can safely stop ticking.
    {:noreply, state}
  end

  @impl true
  def handle_info(:timer_tick, %{board: board, player: player} = state) do
    # Move blocks by one down
    tick_delay = Gravity.calculate(Board.level(board))
    Process.send_after(self(), :timer_tick, round(:timer.seconds(tick_delay)))
    Logger.debug("Tick for player #{player.player_id}: #{tick_delay}")
    {:noreply, state}
  end
end
