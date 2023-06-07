defmodule Pulk.Game.PiecePositionUpdate do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.Board

  @type direction() :: :down | :left | :right

  @type update_type() :: :simple | :soft_drop_start | :soft_drop_stop | :hard_drop

  # Source: https://harddrop.com/wiki/SRS
  # 0 = spawn state
  # R = state resulting from a clockwise rotation ("right") from spawn
  # L = state resulting from a counter-clockwise ("left") rotation from spawn
  # 2 = state resulting from 2 successive rotations in either direction from spawn.
  @type rotation() :: :O | :R | :L | :two

  typedstruct enforce: true do
    field(:piece, Piece.t())

    field(:update_type, update_type())

    # Either of these must be present for a simple update
    field(:rotation, rotation(), enforce: false)
    field(:direction, direction(), enforce: false)
  end

  @spec update_active_piece(Board.t(), update_type()) :: t()
  @spec update_active_piece(Board.t(), update_type(), map()) :: t()
  def update_active_piece(%Board{active_piece: piece}, :simple, %{rotation: rotation}) do
    new!(
      piece: piece,
      update_type: :simple,
      rotation: rotation
    )
  end

  def update_active_piece(%Board{active_piece: piece}, :simple, %{direction: direction}) do
    new!(
      piece: piece,
      update_type: :simple,
      direction: direction
    )
  end

  def update_active_piece(%Board{active_piece: piece}, update_type) do
    new!(
      piece: piece,
      update_type: update_type
    )
  end
end
