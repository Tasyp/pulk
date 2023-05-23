defmodule Pulk.Game.BoardSnapshot do
  use TypedStruct
  use Domo

  alias Pulk.Game.PositionedPiece
  alias Pulk.Game.Matrix
  alias Pulk.Game.Board

  typedstruct do
    field(:active_piece, PositionedPiece.t())

    field(:matrix, Matrix.t(), enforce: true)

    field(:status, Board.status(), enforce: true)
  end
end
