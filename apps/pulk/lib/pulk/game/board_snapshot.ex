defmodule Pulk.Game.BoardSnapshot do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.Matrix

  typedstruct do
    field :piece_in_hold, Piece.t()

    field :active_piece,
          %{piece: Piece.t(), coordinates: [{non_neg_integer(), non_neg_integer()}]}

    field :matrix, Matrix.t(), enforce: true
  end
end
