defmodule Pulk.Game.PositionedPiece do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece

  typedstruct enforce: true do
    field :piece, Piece.t()

    field :coordinates, [{non_neg_integer(), non_neg_integer()}]
  end
end
