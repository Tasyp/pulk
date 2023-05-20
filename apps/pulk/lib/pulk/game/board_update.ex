defmodule Pulk.Game.BoardUpdate do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.Matrix
  alias Pulk.Game.PositionedPiece

  typedstruct do
    field :piece_in_hold, Piece.t()

    field :active_piece, PositionedPiece.t()

    field :matrix, Matrix.t(), enforce: true
  end
end
