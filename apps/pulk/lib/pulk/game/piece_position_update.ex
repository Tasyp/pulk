defmodule Pulk.Game.PiecePositionUpdate do
  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.PositionedPiece
  alias Pulk.Game.Board

  @type direction() :: :down | :left | :right

  @type update_type() :: :simple | :soft_drop_start | :soft_drop_stop | :hard_drop

  @type relative_rotation() :: :left | :right

  typedstruct enforce: true do
    field(:piece, Piece.t())

    field(:update_type, update_type())

    # Either of these must be present for a simple update
    field(:relative_rotation, relative_rotation(), enforce: false)
    field(:direction, direction(), enforce: false)
  end

  @spec update_active_piece(Board.t(), update_type()) :: t()
  @spec update_active_piece(Board.t(), update_type(), map()) :: t()
  def update_active_piece(%Board{active_piece: %PositionedPiece{piece: piece}}, :simple, %{
        relative_rotation: relative_rotation
      }) do
    new!(
      piece: piece,
      update_type: :simple,
      relative_rotation: relative_rotation
    )
  end

  def update_active_piece(%Board{active_piece: %PositionedPiece{piece: piece}}, :simple, %{
        direction: direction
      }) do
    new!(
      piece: piece,
      update_type: :simple,
      direction: direction
    )
  end

  def update_active_piece(%Board{active_piece: %PositionedPiece{piece: piece}}, update_type) do
    new!(
      piece: piece,
      update_type: update_type
    )
  end
end
