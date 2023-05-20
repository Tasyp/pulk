defmodule Pulk.Game.BoardSnapshot do
  use TypedStruct
  use Domo

  alias Pulk.Game.PositionedPiece
  alias Pulk.Game.Matrix

  typedstruct do
    field :active_piece, PositionedPiece.t()

    field :matrix, Matrix.t(), enforce: true
  end
end
