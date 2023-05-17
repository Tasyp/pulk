defmodule Pulk.Game.Board do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.Matrix

  typedstruct enforce: true do
    field :sizeX, pos_integer()
    field :sizeY, pos_integer()
    field :level, non_neg_integer(), default: 1
    field :score, non_neg_integer(), default: 0
    field :piece_in_hold, Piece.t(), enforce: false

    field :active_figure,
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
end
