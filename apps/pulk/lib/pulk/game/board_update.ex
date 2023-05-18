defmodule Pulk.Game.BoardUpdate do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.Matrix

  @type active_piece :: %{piece: Piece.t(), coordinates: [{non_neg_integer(), non_neg_integer()}]}

  typedstruct do
    field :piece_in_hold, Piece.t()

    field :active_piece, active_piece()

    field :matrix, Matrix.t(), enforce: true
  end
end
