defmodule Pulk.Player.PlayerManager do
  @moduledoc """
  GenServer that keeps state of an active player
  """

  use GenServer

  require Logger

  alias Phoenix.PubSub
  alias Pulk.Game.Board
  alias Pulk.Game.BoardUpdate
  alias Pulk.Game.PiecePositionUpdate
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

  def update_board(pid, board_update) do
    GenServer.call(pid, {:update_board, board_update})
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
    GenServer.cast(pid, :publish_board)
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

  defp do_update_board(board, board_update, room_id) do
    # TODO: Detect if there is a need to start lock timer or soft timer
    case Board.update(board, board_update) do
      {:ok, board} ->
        RoomManager.recalculate_room_status(room_id)

        {:ok, board}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_soft_drop_change(
         %{board: board, soft_drop_timer: soft_drop_timer} = state,
         board_update
       ) do
    cond do
      BoardUpdate.has_piece_update_type?(board_update, :soft_drop_start) ->
        soft_drop_timer = schedule_soft_drop_tick(board)

        %{state | soft_drop_timer: soft_drop_timer}

      BoardUpdate.has_piece_update_type?(board_update, :soft_drop_stop) && soft_drop_timer != nil ->
        Process.cancel_timer(state.soft_drop_timer)

        %{state | soft_drop_timer: nil}

      soft_drop_timer != nil ->
        Process.cancel_timer(state.soft_drop_timer)

        %{state | soft_drop_timer: nil}

      true ->
        state
    end
  end

  defp schedule_soft_drop_tick(board) do
    tick_delay = Gravity.calculate(Board.level(board)) / 2

    Process.send_after(self(), :soft_drop_tick, round(:timer.seconds(tick_delay)))
  end

  @impl true
  def init(%{room: %Pulk.Room{} = room, player: %Pulk.Player{} = player}) do
    {size_x, size_y} = room.board_size
    {:ok, board} = Board.new(size_x, size_y)

    # TODO: Start tick timer when board is actually started
    Process.send_after(self(), :timer_tick, :timer.seconds(1))

    {:ok, %{player: player, board: board, soft_drop_timer: nil}}
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
        {:update_board, board_update},
        _from,
        %{board: board, player: player} = state
      ) do
    {response, state} =
      case do_update_board(board, board_update, player.room_id) do
        {:ok, board} ->
          {{:ok, board}, %{state | board: board}}

        {:error, reason} ->
          {{:error, reason}, state}
      end

    state = process_soft_drop_change(state, board_update)
    # TODO: Detect if there is a need to start lock timer

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
  def handle_cast(:publish_board, %{board: board, player: player} = state) do
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
  def handle_info(:timer_tick, %{board: %Board{status: :complete}} = state) do
    # Board is complete. We can safely stop ticking.
    {:noreply, state}
  end

  @impl true
  def handle_info(
        :timer_tick,
        %{board: board, player: player, soft_drop_timer: soft_drop_timer} = state
      ) do
    state =
      cond do
        soft_drop_timer == nil && board.active_piece !== nil ->
          board_update =
            BoardUpdate.new!(
              active_piece_update:
                PiecePositionUpdate.update_active_piece(board, :simple, %{direction: :down})
            )

          case do_update_board(board, board_update, player.room_id) do
            {:ok, board} ->
              %{state | board: board}

            {:error, _reason} ->
              state
          end

        true ->
          state
      end

    publish_board(self())

    tick_delay = Gravity.calculate(Board.level(board))
    Process.send_after(self(), :timer_tick, round(:timer.seconds(tick_delay)))
    Logger.debug("Tick for player #{player.player_id}: #{tick_delay}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:soft_drop_tick, %{board: board, player: player} = state) do
    board_update =
      BoardUpdate.new!(
        active_piece_update:
          PiecePositionUpdate.update_active_piece(board, :simple, %{direction: :down})
      )

    state =
      case do_update_board(board, board_update, player.room_id) do
        {:ok, board} ->
          soft_drop_timer = schedule_soft_drop_tick(board)

          %{state | board: board, soft_drop_timer: soft_drop_timer}

        {:error, _reason} ->
          %{state | soft_drop_timer: nil}
      end

    {:noreply, state}
  end
end
