defmodule Pulk.Game.PiecePositionUpdate do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece

  @type direction :down | :left | :right

  # Source: https://harddrop.com/wiki/SRS
  # 0 = spawn state
  # R = state resulting from a clockwise rotation ("right") from spawn
  # L = state resulting from a counter-clockwise ("left") rotation from spawn
  # 2 = state resulting from 2 successive rotations in either direction from spawn.
  @type rotation :0 | :r | :l | :2

  typedstruct enforce: true do
    field :piece, Piece.t()

    field :rotation, rotation(), enforce: false

    field :direction, direction(), enforce: false
  end
end
