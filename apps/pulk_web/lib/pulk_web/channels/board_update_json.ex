defmodule PulkWeb.BoardUpdateJSON do
  require Logger

  alias Pulk.Game.BoardUpdate
  alias PulkWeb.MatrixJSON
  alias PulkWeb.PieceJSON
  alias PulkWeb.PositionedPieceJSON

  @type board_update_json :: %{
          piece_in_hold: String.t() | nil,
          active_piece: PositionedPieceJSON.positioned_piece_json(),
          matrix: MatrixJSON.matrix_json()
        }

  @spec from_json(map()) ::
          {:ok, BoardUpdate.t()}
          | {:error, :malformed}
          | {:error, :invalid_figure}
          | {:error, :invalid_matrix}
          | {:error, :invalid_positioned_piece}
  def from_json(%{
        "matrix" => matrix,
        "piece_in_hold" => piece_in_hold,
        "active_piece" => active_piece
      }) do
    with {:ok, matrix} <- MatrixJSON.from_json(matrix),
         {:ok, piece_in_hold} <- PieceJSON.from_json(piece_in_hold),
         {:ok, active_piece} <- PositionedPieceJSON.from_json(active_piece),
         {:ok, board_update} <-
           BoardUpdate.new(
             matrix: matrix,
             piece_in_hold: piece_in_hold,
             active_piece: active_piece
           ) do
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
