defmodule Pulk.Board.BoardUpdate do
  @moduledoc """
  Entity that is used to update board state via public interfaces
  """

  use TypedStruct
  use Domo

  alias Pulk.Piece.PieceUpdate

  typedstruct do
    field :active_piece_update, PieceUpdate.t()
  end

  def has_piece_update_type?(%{active_piece_update: nil}, _update_type) do
    false
  end

  def has_piece_update_type?(board_update, update_type) do
    board_update.active_piece_update.update_type == update_type
  end
end
