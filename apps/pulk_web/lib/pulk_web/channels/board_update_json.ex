defmodule PulkWeb.BoardUpdateJSON do
  alias PulkWeb.PieceUpdateJSON

  @type board_update_json :: %{
          active_piece_update: PieceUpdateJSON.piece_position_update_json()
        }

  def from_json(%{
        "active_piece_update" => active_piece_update
      }),
      do: PieceUpdateJSON.from_json(active_piece_update)

  def from_json(_), do: %{}
end
