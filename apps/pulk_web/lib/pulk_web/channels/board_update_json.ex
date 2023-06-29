defmodule PulkWeb.BoardUpdateJSON do
  require Logger

  alias Pulk.Board.BoardUpdate
  alias PulkWeb.PieceUpdateJSON

  @type board_update_json :: %{
          active_piece_update: PieceUpdateJSON.piece_position_update_json()
        }

  @spec from_json(map()) ::
          {:ok, BoardUpdate.t()} | {:error, term()}
  def from_json(%{
        "active_piece_update" => active_piece_update
      }) do
    with {:ok, active_piece_update} <- PieceUpdateJSON.from_json(active_piece_update),
         {:ok, board_update} <-
           BoardUpdate.new(active_piece_update: active_piece_update) do
      {:ok, board_update}
    else
      {:error, reason} when is_list(reason) ->
        Logger.warning(
          "Board update creation faield when all validations have passed: #{inspect(reason)}"
        )

        {:error, :malformed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def from_json(_), do: {:error, :malformed}
end
