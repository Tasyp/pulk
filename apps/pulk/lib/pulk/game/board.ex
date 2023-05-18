defmodule Pulk.Game.Board do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.Matrix
  alias Pulk.Game.BoardUpdate

  typedstruct enforce: true do
    field :sizeX, pos_integer()
    field :sizeY, pos_integer()
    field :level, non_neg_integer(), default: 1
    field :score, non_neg_integer(), default: 0
    field :piece_in_hold, Piece.t(), enforce: false

    field :active_piece,
          %{piece: Piece.t(), coordinates: [{non_neg_integer(), non_neg_integer()}]},
          enforce: false

    field :matrix, Matrix.t()
  end

  @spec update_matrix(t(), Matrix.t()) :: {:ok, t()} | {:error, :invalid_size}
  def update_matrix(%__MODULE__{} = board, matrix) do
    with :ok <- Matrix.has_matching_size?(matrix, {board.sizeX, board.sizeY}),
         {:ok, next_board} <- ensure_type(%{board | matrix: matrix}) do
      {:ok, next_board}
    end
  end

  @spec update(t(), BoardUpdate.t()) :: {:ok, BoardUpdate.t()} | {:error, :invalid_update}
  def update(%__MODULE__{} = board, %BoardUpdate{} = board_update) do
    next_board = %{
      board
      | piece_in_hold: board_update.piece_in_hold,
        active_piece: board_update.active_piece,
        matrix: board_update.matrix
    }

    case ensure_type(next_board) do
      {:ok, board} -> {:ok, board}
      {:error, _} -> {:error, :invalid_update}
    end
  end
end
