defmodule PulkWeb.BoardUpdateJSON do
  require Logger

  alias Pulk.Game.BoardUpdate
  alias PulkWeb.MatrixJSON
  alias PulkWeb.PieceJSON

  @type active_piece ::
          %{piece: String.t(), coordinates: [{non_neg_integer(), non_neg_integer()}]}

  @type board_update_json :: %{
          piece_in_hold: String.t() | nil,
          active_piece: active_piece(),
          matrix: MatrixJSON.matrix_json()
        }

  @spec from_json(board_update_json()) ::
          {:ok, BoardUpdate.t()}
          | {:error, :malformed}
          | {:error, :invalid_figure}
          | {:error, :invalid_matrix}
  def from_json(%{
        "matrix" => matrix,
        "piece_in_hold" => piece_in_hold,
        "active_piece" => active_piece
      }) do
    with {:ok, matrix} <- MatrixJSON.from_json(matrix),
         {:ok, piece_in_hold} <- PieceJSON.from_json(piece_in_hold),
         {:ok, active_piece} <- parse_active_piece_json(active_piece),
         {:ok, board_update} <-
           BoardUpdate.new(
             matrix: matrix,
             piece_in_hold: piece_in_hold,
             active_piece: active_piece
           ) do
      {:ok, board_update}
    else
      {:error, reason} when is_list(reason) ->
        Logger.warn("Board update creation faield when all validations have passed: #{reason}")
        {:error, :malformed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def from_json(_) do
    {:error, :malformed}
  end

  @spec parse_active_piece_json(active_piece() | nil) ::
          {:ok, BoardUpdate.active_piece() | nil} | {:error, :invalid_figure}
  defp parse_active_piece_json(nil) do
    {:ok, nil}
  end

  defp parse_active_piece_json(%{piece: piece, coordinates: coordinates})
       when is_list(coordinates) do
    with {:ok, piece} <- PieceJSON.from_json(piece) do
      {:ok, %{piece: piece, coordinates: coordinates}}
    end
  end

  defp parse_active_piece_json(_) do
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
