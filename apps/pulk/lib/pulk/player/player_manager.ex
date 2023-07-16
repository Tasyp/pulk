defmodule Pulk.Player.PlayerManager do
  @moduledoc """
  GenServer that keeps state of an active player
  """

  use GenServer

  require Logger

  alias Pulk.Player
  alias Pulk.Board
  alias Pulk.Board.BoardUpdate
  alias Pulk.Board.BoardSubscription
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
    case GenServer.whereis(via(player_id)) do
      nil -> {:error, :unknown_player}
      _ -> :ok
    end
  end

  @spec remove_player(String.t()) :: :ok | {:error, :unknown_player}
  def remove_player(player_id) when is_bitstring(player_id) do
    with :ok <- is_player_present?(player_id) do
      GenServer.call(via(player_id), :remove_player)
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

  @spec update_board(String.t() | pid(), BoardUpdate.t()) :: :ok | {:error, term()}
  def update_board(player_id, %BoardUpdate{} = board_update) when is_bitstring(player_id) do
    with :ok <- is_player_present?(player_id) do
      GenServer.call(via(player_id), {:update_board, board_update})
    end
  end

  def update_board(pid, %BoardUpdate{} = board_update) when is_pid(pid) do
    GenServer.call(pid, {:update_board, board_update})
  end

  def update_board(_, _), do: {:error, :invalid_update}

  @spec set_placement(GenServer.server() | String.t(), pos_integer()) ::
          {:ok, Board.t()} | {:error, term()}
  def set_placement(player_id, placement) when is_bitstring(player_id),
    do: set_placement(via(player_id), placement)

  def set_placement(pid, placement) do
    GenServer.call(pid, {:set_placement, placement})
  end

  @spec publish_board(GenServer.server() | String.t()) :: :ok
  def publish_board(player_id) when is_bitstring(player_id), do: publish_board(via(player_id))

  def publish_board(pid) do
    GenServer.cast(pid, :publish_board)
  end

  @spec lookup(String.t()) :: {:ok, pid()} | {:error, :not_found}
  def lookup(player_id) when is_bitstring(player_id) do
    case Pulk.Registry.lookup({__MODULE__, player_id}) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

  @impl true
  def init(%{room: %Pulk.Room{room_id: room_id} = room, player: %Pulk.Player{} = player}) do
    :pg.join({__MODULE__, room_id}, self())

    {size_x, size_y} = room.board_size
    {:ok, board} = Board.new(size_x, size_y)

    state =
      %{player: player, board: board, soft_drop_timer: nil, lock_delay_timer: nil}
      # TODO: Init tick timer when board is actually started
      |> schedule_timer_tick(:timer.seconds(1))

    {:ok, state}
  end

  @impl true
  def handle_call(:fetch_player, _from, %{player: player} = state) do
    {:reply, {:ok, player}, state}
  end

  @impl true
  def handle_call(:remove_player, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call(:get_board, _from, %{board: board} = state) do
    {:reply, {:ok, board}, state}
  end

  @impl true
  def handle_call({:set_placement, placement}, _from, %{board: board} = state) do
    {response, state} =
      case Board.set_placement(board, placement) do
        {:ok, board} ->
          {{:ok, board}, %{state | board: board}}

        {:error, reason} ->
          {{:error, reason}, state}
      end

    {:reply, response, state}
  end

  @impl true
  def handle_call(
        {:update_board, board_update},
        _from,
        state
      ) do
    next_state =
      state
      |> process_board_update(board_update)
      |> process_lock_delay()
      |> process_soft_drop(board_update)
      |> extract_state()

    publish_board(self())

    {:reply, :ok, next_state}
  end

  @impl true
  def handle_cast(:publish_board, %{board: board, player: %Player{player_id: player_id}} = state) do
    BoardSubscription.publish(player_id, board)

    {:noreply, state}
  end

  @impl true
  def handle_info(:soft_drop_tick, state) do
    board_update = compose_board_update(state, :soft_drop_start)

    next_state =
      state
      |> process_board_update(board_update)
      |> process_lock_delay()
      |> process_soft_drop(board_update)
      |> extract_state()

    publish_board(self())

    {:noreply, next_state}
  end

  @impl true
  def handle_info(:timer_tick, %{board: %Board{status: :complete}} = state) do
    # Board is complete. We can safely stop ticking.
    {:noreply, state}
  end

  @impl true
  def handle_info(
        :timer_tick,
        state
      ) do
    next_state =
      state
      |> maybe_process_timer_tick()
      |> schedule_timer_tick()
      |> extract_state()

    publish_board(self())

    {:noreply, next_state}
  end

  @impl true
  def handle_info(:lock_delay_tick, state) do
    # Empty board update to trigger recalculation
    board_update = compose_board_update(state)

    next_state =
      state
      |> process_board_update(board_update, recalculate?: true)
      |> clear_lock_delay()
      |> extract_state()

    publish_board(self())

    {:noreply, next_state}
  end

  # Private API

  defp via(player_id) do
    Pulk.Registry.via_tuple({__MODULE__, player_id})
  end

  defp compose_board_update(state, board_update_input \\ nil)

  defp compose_board_update(%{board: board}, arguments) when is_map(arguments),
    do:
      BoardUpdate.new!(
        active_piece_update: PieceUpdate.update_active_piece(board, :simple, arguments)
      )

  defp compose_board_update(_state, nil), do: BoardUpdate.new!()

  defp compose_board_update(%{board: board}, update_type) when is_atom(update_type),
    do: BoardUpdate.new!(active_piece_update: PieceUpdate.update_active_piece(board, update_type))

  defp process_board_update(
         %{board: board, player: %Player{room_id: room_id}} = state,
         %BoardUpdate{} = board_update,
         opts \\ []
       ) do
    # RoomManager will need to fetch state of all room boards so it will be
    # executed only after current board update is processed
    RoomManager.recalculate_room_status(room_id)

    case Board.update(board, board_update, opts) do
      {:ok, board} ->
        state
        |> Map.put(:board, board)
        |> put_update_metadata(success?: true)

      {:error, reason} ->
        Logger.debug("Board update failed. Reason: #{inspect(reason)}")

        state
        |> put_update_metadata(success?: false)
    end
  end

  defp process_soft_drop(
         %{board: board, soft_drop_timer: soft_drop_timer} = state,
         board_update
       ) do
    cond do
      BoardUpdate.has_piece_update_type?(board_update, :soft_drop_start) ->
        soft_drop_timer = schedule_soft_drop_tick(board)

        %{state | soft_drop_timer: soft_drop_timer}

      soft_drop_timer != nil ->
        Process.cancel_timer(state.soft_drop_timer)

        %{state | soft_drop_timer: nil}

      true ->
        state
    end
  end

  defp schedule_soft_drop_tick(board) do
    tick_delay_in_ms = round(Gravity.calculate(Board.level(board)) / 16 * 1000)

    Process.send_after(self(), :soft_drop_tick, tick_delay_in_ms)
  end

  defp process_lock_delay(%{update_metadata: %{success?: false}} = state), do: state

  defp process_lock_delay(
         %{board: %Board{can_update_active_piece?: true}, update_metadata: %{success?: true}} =
           state
       ) do
    state
  end

  defp process_lock_delay(
         %{lock_delay_timer: lock_delay_timer, update_metadata: %{success?: true}} = state
       )
       when lock_delay_timer != nil do
    Process.cancel_timer(lock_delay_timer)
    process_lock_delay(%{state | lock_delay_timer: nil})
  end

  defp process_lock_delay(
         %{board: board, lock_delay_timer: nil, update_metadata: %{success?: true}} = state
       ) do
    lock_delay_timer = schedule_lock_delay_tick(board.lock_delay)
    %{state | lock_delay_timer: lock_delay_timer}
  end

  defp clear_lock_delay(state), do: %{state | lock_delay_timer: nil}

  defp schedule_lock_delay_tick(lock_delay) do
    Process.send_after(self(), :lock_delay_tick, lock_delay)
  end

  defp schedule_timer_tick(state, delay_in_ms \\ nil)

  defp schedule_timer_tick(%{board: board} = state, nil) do
    tick_delay_in_ms = round(Gravity.calculate(Board.level(board)) * 1000)
    Process.send_after(self(), :timer_tick, tick_delay_in_ms)
    state
  end

  defp schedule_timer_tick(state, delay_in_ms) do
    Process.send_after(self(), :timer_tick, delay_in_ms)
    state
  end

  defp maybe_process_timer_tick(
         %{soft_drop_timer: soft_drop_timer, lock_delay_timer: lock_delay_timer, board: board} =
           state
       ) do
    can_process_tick? =
      soft_drop_timer == nil && lock_delay_timer == nil && board.active_piece !== nil

    state
    |> do_process_timer_tick(can_process_tick?)
  end

  defp do_process_timer_tick(state, false = _process?), do: state

  defp do_process_timer_tick(state, true = _process?) do
    board_update = compose_board_update(state, %{direction: :down})

    state
    |> process_board_update(board_update, recalculate?: false)
    |> process_lock_delay()
  end

  defp put_update_metadata(state, keywords) when is_list(keywords) do
    keywords_map = Enum.into(keywords, %{})

    update_metadata =
      state
      |> Map.get(:update_metadata, %{})
      |> Map.merge(keywords_map)

    Map.put(state, :update_metadata, update_metadata)
  end

  defp extract_state(state), do: Map.delete(state, :update_metadata)
end
