defmodule PulkWeb.BoardUpdateJSON do
  require Logger

  alias Pulk.Game.BoardUpdate
  alias PulkWeb.PieceJSON
  alias PulkWeb.PiecePositionUpdateJSON

  @type board_update_json :: %{
          piece_in_hold: String.t() | nil,
          active_piece_update: PiecePositionUpdateJSON.piece_position_update_json()
        }

  @spec from_json(map()) ::
          {:ok, BoardUpdate.t()}
          | {:error, :invalid_piece}
          | {:error, :invalid_update_type}
          | {:error, :invalid_rotation}
          | {:error, :invalid_direction}
          | {:error, :malformed}
  def from_json(%{
        "piece_in_hold" => piece_in_hold,
        "active_piece_update" => active_piece_update
      }) do
    with {:ok, piece_in_hold} <- PieceJSON.from_json(piece_in_hold),
         {:ok, active_piece_update} <- PiecePositionUpdateJSON.from_json(active_piece_update),
         {:ok, board_update} <-
           BoardUpdate.new(piece_in_hold: piece_in_hold, active_piece_update: active_piece_update) do
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

  def from_json(_) do
    Logger.debug("Board update has missing fields")
    {:error, :malformed}
  end
end

defimpl Jason.Encoder, for: [Pulk.Game.BoardUpdate] do
  def encode(struct, opts) do
    Jason.Encode.map(
      Map.from_struct(struct),
      opts
    )
  end
end
