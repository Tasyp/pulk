defmodule Pulk.Game.Board do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.Matrix
  alias Pulk.Game.BoardUpdate
  alias Pulk.Game.BoardSnapshot
  alias Pulk.Game.PositionedPiece

  @points_per_line 100

  typedstruct enforce: true do
    field :sizeX, pos_integer()
    field :sizeY, pos_integer()
    field :score, non_neg_integer(), default: 0
    field :cleared_lines_count, non_neg_integer(), default: 0
    field :piece_in_hold, Piece.t(), enforce: false

    field :active_piece, PositionedPiece.t(), enforce: false

    field :matrix, Matrix.t()
  end

  @spec level(t()) :: pos_integer()
  def level(%__MODULE__{cleared_lines_count: cleared_lines_count}) do
    trunc(cleared_lines_count / 10) + 1
  end

  @spec to_snapshot(t()) :: BoardSnapshot.t()
  def to_snapshot(%__MODULE__{active_piece: active_piece, matrix: matrix}) do
    BoardSnapshot.new!(active_piece: active_piece, matrix: matrix)
  end

  @spec update_matrix(t(), Matrix.t()) ::
          {:ok, t()} | {:error, :invalid_size} | {:error, :invalid_matrix}
  def update_matrix(%__MODULE__{} = board, matrix) do
    with :ok <- Matrix.has_matching_size?(matrix, {board.sizeX, board.sizeY}),
         {:ok, next_board} <- ensure_type(%{board | matrix: matrix}) do
      {:ok, next_board}
    else
      {:error, list_reason} when is_list(list_reason) ->
        {:error, :invalid_matrix}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec update(t(), BoardUpdate.t(), keyword()) ::
          {:ok, BoardUpdate.t()} | {:error, :invalid_update}
  def update(%__MODULE__{} = board, %BoardUpdate{} = board_update, opts \\ []) do
    recalculate? = Keyword.get(opts, :recalculate?, false)

    next_board =
      %{
        board
        | piece_in_hold: board_update.piece_in_hold,
          active_piece: board_update.active_piece,
          matrix: board_update.matrix
      }
      |> maybe_remove_filled_lines(recalculate?)

    case ensure_type(next_board) do
      {:ok, board} -> {:ok, board}
      {:error, _} -> {:error, :invalid_update}
    end
  end

  @spec maybe_remove_filled_lines(t(), boolean()) :: t()
  def maybe_remove_filled_lines(%__MODULE__{} = board, true) do
    {matrix, filled_lines_count} = Matrix.remove_filled_lines(board.matrix)

    next_board =
      board
      |> Map.put(:matrix, matrix)
      |> maybe_remove_filled_lines(filled_lines_count)

    next_board
  end

  def maybe_remove_filled_lines(%__MODULE__{} = board, false) do
    board
  end

  @spec recalculate_score(t(), non_neg_integer()) :: t()
  def recalculate_score(%__MODULE__{} = board, cleared_lines_count_increase) do
    score_increase =
      if cleared_lines_count_increase == 4 do
        @points_per_line * 10
      else
        cleared_lines_count_increase * @points_per_line
      end

    %{
      board
      | cleared_lines_count: board.cleared_lines_count + cleared_lines_count_increase,
        score: board.score + score_increase
    }
  end
end
