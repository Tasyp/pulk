defmodule Pulk.Board.UpdateHandler do
  alias Pulk.Board
  alias Pulk.Board.BoardUpdate
  alias Pulk.RoomManager

  @spec handle_update(pid, BoardUpdate.t(), Board.t(), String.t())
  def handle_update(receiver, %BoardUpdate{} = board_update, %Board{} = board, opts \\ []) do
    opts_with_defaults =
      opts
      |> Keyword.merge(recalculate?: recalculate?(opts))

    {response, state} =
      case Board.update(board, board_update, opts_with_defaults) do
        {:ok, board} ->
          {:ok, board |> process_lock_delay()}

        {:error, reason} ->
          {{:error, reason}, board}
      end

    state =
      state
      |> process_soft_drop_change(board_update)

    {response, state}
  end

  defp recalculate?(%BoardUpdate{} = board_update, opts) do
    cond do
      Keyword.has_key?(opts, :recalculate?) ->
        Keyword.fetch!(opts, :recalculate?)

      BoardUpdate.has_piece_update_type?(board_update, :hard_drop) ->
        true

      true ->
        # By default, let's not recalculate board
        false
    end
  end

  defp process_soft_drop_change(
    receiver,
    %Board{soft_drop_timer: soft_drop_timer} = board,
    %BoardUpdate{} = board_update
  ) do
    cond do
      BoardUpdate.has_piece_update_type?(board_update, :soft_drop_start) ->
        soft_drop_timer = schedule_soft_drop_tick(receiver, board)

        %{board | soft_drop_timer: soft_drop_timer}

       soft_drop_timer != nil ->
        Process.cancel_timer(soft_drop_timer)

        %{board | soft_drop_timer: nil}

      true ->
        board
    end
  end

  defp schedule_soft_drop_tick(receiver, board) do
    tick_delay = Gravity.calculate(Board.level(board)) / 16

    Process.send_after(self(), :soft_drop_tick, round(:timer.seconds(tick_delay)))
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
end
