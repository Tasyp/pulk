defmodule Pulk.Game.BoardSnapshot do
  use TypedStruct
  use Domo

  alias Pulk.Game.PositionedPiece
  alias Pulk.Game.Matrix
  alias Pulk.Game.BoardState

  typedstruct do
    field :active_piece, PositionedPiece.t()

    field :matrix, Matrix.t(), enforce: true

    field :state, BoardState.t(), enforce: true
  end
end
