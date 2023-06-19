defmodule Pulk.Game.BoardSnapshot do
  @moduledoc """
  Entity that is used to display board state to an observer (anyone who is not the player itself)
  """

  use TypedStruct
  use Domo

  alias Pulk.Game.PositionedPiece
  alias Pulk.Game.Matrix
  alias Pulk.Game.Board

  typedstruct do
    field :active_piece, PositionedPiece.t()

    field :buffer_zone_size, non_neg_integer(), default: 2

    field :matrix, Matrix.t(), enforce: true

    field :status, Board.status(), enforce: true
  end
end
