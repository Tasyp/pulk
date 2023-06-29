defmodule Pulk.Piece.PieceUpdate do
  @moduledoc """
  An entity that is used to describe piece position change
  """

  use TypedStruct
  use Domo

  alias Pulk.Piece
  alias Pulk.Piece.PositionedPiece
  alias Pulk.Board
  alias Pulk.Piece.Rotation

  @type direction() :: :down | :left | :right

  @type update_type() :: :simple | :soft_drop_start | :soft_drop_stop | :hard_drop | :hold

  typedstruct enforce: true do
    field :piece, Piece.t()

    field :update_type, update_type()

    # Either of these must be present for a simple update
    field :relative_rotation, Rotation.relative_rotation(), enforce: false
    field :direction, direction(), enforce: false
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

defimpl Jason.Encoder, for: [Pulk.Piece.PieceUpdate] do
  def encode(struct, opts) do
    Jason.Encode.map(
      Map.from_struct(struct),
      opts
    )
  end
end
