defmodule Pulk.Player.PlayerManager do
  @moduledoc """
  GenServer that keeps state of an active player
  """

  use GenServer

  require Logger

  alias Phoenix.PubSub
  alias Pulk.Player
  alias Pulk.Board
  alias Pulk.Board.BoardUpdate
  alias Pulk.Piece.PieceUpdate
  alias Pulk.Room.RoomManager
  alias Pulk.Board.Gravity

  def start_link(init_args) do
    player = Keyword.fetch!(init_args, :player)
    room = Keyword.fetch!(init_args, :room)

    GenServer.start_link(
      __MODULE__,
      %{player: player, room: room},
      name: via(player.player_id)
    )
  end

  @spec is_player_present?(String.t()) :: :ok | {:error, :unknown_player}
  def is_player_present?(player_id) do
    case Pulk.Registry.lookup({__MODULE__, player_id}) do
      [] -> {:error, :unknown_player}
      _ -> :ok
    end
  end

  @spec fetch_player(String.t() | pid()) :: {:error, :unknown_player} | {:ok, Pulk.t()}
  def fetch_player(player_id) when is_bitstring(player_id) do
    with :ok <- is_player_present?(player_id) do
      GenServer.call(via(player_id), :fetch_player)
    end
  end

  def fetch_player(pid) when is_pid(pid) do
    GenServer.call(pid, :fetch_player)
  end

  def fetch_player(_), do: {:error, :unknown_player}

  @spec fetch_player_and_create_if_needed(player_id :: String.t()) ::
          {:ok, Player.t()} | {:error, :invalid_player_id}
  def fetch_player_and_create_if_needed(player_id) when is_bitstring(player_id) do
    case fetch_player(player_id) do
      {:ok, player} ->
        {:ok, player}

      {:error, :unknown_player} ->
        case Player.new(%{player_id: player_id}) do
          {:ok, player} -> {:ok, player}
          {:error, _reason} -> {:error, :invalid_player_id}
        end
    end
  end

  def fetch_player_and_create_if_needed(_), do: {:error, :invalid_player_id}

  @spec get_board(String.t() | pid()) :: {:ok, Board.t()} | {:error, :unknown_player}
  def get_board(player_id) when is_bitstring(player_id) do
    with :ok <- is_player_present?(player_id) do
      GenServer.call(via(player_id), :get_board)
    end
  end

  def get_board(pid) when is_pid(pid) do
    GenServer.call(pid, :get_board)
  end

  def get_board(_), do: {:error, :unknown_player}

  @spec update_board(String.t() | pid(), BoardUpdate.t()) :: {:ok, Board.t()} | {:error, term()}
  def update_board(player_id, %BoardUpdate{} = board_update) when is_bitstring(player_id) do
    with :ok <- is_player_present?(player_id) do
      GenServer.call(via(player_id), {:update_board, board_update})
    end
  end

  def update_board(pid, %BoardUpdate{} = board_update) when is_pid(pid) do
    GenServer.call(pid, {:update_board, board_update})
  end

  def update_board(_, _), do: {:error, :invalid_update}

  def update_matrix(pid, raw_matrix) do
    GenServer.call(pid, {:update_matrix, raw_matrix})
  end

  def set_placement(pid, placement) do
    GenServer.call(pid, {:set_placement, placement})
  end

  @spec subscribe_to_board_updates(String.t()) :: :ok | {:error, term()}
  def subscribe_to_board_updates(player_id) when is_bitstring(player_id) do
    PubSub.subscribe(Pulk.PubSub, "player:#{player_id}:board")
  end

  def subscribe_to_board_updates(_), do: {:error, :invalid_player_id}

  def publish_board(pid) do
    GenServer.cast(pid, :publish_board)
  end

  def lookup(player_id) do
    case Pulk.Registry.lookup({__MODULE__, player_id}) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

  def via(player_id) do
    Pulk.Registry.via_tuple({__MODULE__, player_id})
  end

  defp do_update_board(board, board_update, room_id, opts \\ []) do
    recalculate? =
      cond do
        Keyword.has_key?(opts, :recalculate?) ->
          Keyword.fetch!(opts, :recalculate?)

        BoardUpdate.has_piece_update_type?(board_update, :hard_drop) ->
          true

        true ->
          # By default, let's not recalculate board
          false
      end

    case Board.update(board, board_update, Keyword.merge(opts, recalculate?: recalculate?)) do
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

  defp process_lock_delay(%{board: board, lock_delay_timer: lock_delay_timer} = state) do
    if Board.can_update_active_piece?(board) do
      state
    else
      if lock_delay_timer != nil do
        Process.cancel_timer(lock_delay_timer)
      end

      lock_delay_timer = schedule_lock_delay_tick(board.lock_delay)
      %{state | lock_delay_timer: lock_delay_timer}
    end
  end

  defp schedule_lock_delay_tick(lock_delay) do
    Process.send_after(self(), :lock_delay_tick, lock_delay)
  end

  defp schedule_soft_drop_tick(board) do
    tick_delay = Gravity.calculate(Board.level(board)) / 16

    Process.send_after(self(), :soft_drop_tick, round(:timer.seconds(tick_delay)))
  end

  @impl true
  def init(%{room: %Pulk.Room{} = room, player: %Pulk.Player{} = player}) do
    {size_x, size_y} = room.board_size
    {:ok, board} = Board.new(size_x, size_y)

    # TODO: Start tick timer when board is actually started
    Process.send_after(self(), :timer_tick, :timer.seconds(1))

    {:ok, %{player: player, board: board, soft_drop_timer: nil, lock_delay_timer: nil}}
  end

  @impl true
  def handle_call(:fetch_player, _from, %{player: player} = state) do
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
          state =
            %{state | board: board}
            |> process_lock_delay()

          {{:ok, board}, state}

        {:error, reason} ->
          {{:error, reason}, state}
      end

    state =
      state
      |> process_soft_drop_change(board_update)

    publish_board(self())

    {:reply, response, state}
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
        %{
          board: board,
          player: player,
          soft_drop_timer: soft_drop_timer,
          lock_delay_timer: lock_delay_timer
        } = state
      ) do
    state =
      if soft_drop_timer == nil && lock_delay_timer == nil && board.active_piece !== nil do
        board_update =
          BoardUpdate.new!(
            active_piece_update:
              PieceUpdate.update_active_piece(board, :simple, %{direction: :down})
          )

        case do_update_board(board, board_update, player.room_id, recalculate?: false) do
          {:ok, board} ->
            %{state | board: board}
            |> process_lock_delay()

          {:error, _reason} ->
            state
        end
      else
        state
      end

    publish_board(self())

    tick_delay = Gravity.calculate(Board.level(board))
    Process.send_after(self(), :timer_tick, round(:timer.seconds(tick_delay)))
    # Logger.debug("Tick for player #{player.player_id}: #{tick_delay}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:soft_drop_tick, %{board: board, player: player} = state) do
    board_update =
      BoardUpdate.new!(
        active_piece_update: PieceUpdate.update_active_piece(board, :simple, %{direction: :down})
      )

    state =
      case do_update_board(board, board_update, player.room_id, recalculate?: false) do
        {:ok, board} ->
          soft_drop_timer = schedule_soft_drop_tick(board)

          %{state | board: board, soft_drop_timer: soft_drop_timer}
          |> process_lock_delay()

        {:error, _reason} ->
          %{state | soft_drop_timer: nil}
      end

    publish_board(self())

    {:noreply, state}
  end

  @impl true
  def handle_info(:lock_delay_tick, %{board: board, player: player} = state) do
    board_update = BoardUpdate.new!()

    state =
      case do_update_board(board, board_update, player.room_id, recalculate?: true) do
        {:ok, board} ->
          %{state | board: board, lock_delay_timer: nil}

        {:error, _reason} ->
          %{state | lock_delay_timer: nil}
      end

    publish_board(self())

    {:noreply, state}
  end
end
