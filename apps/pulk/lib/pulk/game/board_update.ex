defmodule Pulk.Game.BoardUpdate do
  @moduledoc """
  Entity that is used to update board state from outisde
  """

  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.PiecePositionUpdate

  typedstruct do
    field(:piece_in_hold, Piece.t())

    field(:active_piece_update, PiecePositionUpdate.t())
  end

  def has_piece_update_type?(%{active_piece_update: nil}, _update_type) do
    false
  end

  def has_piece_update_type?(board_update, update_type) do
    board_update.active_piece_update.update_type == update_type
  end
end
