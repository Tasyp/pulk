defmodule PulkWeb.BoardUpdateJSON do
  alias Pulk.Game.BoardUpdate
  alias PulkWeb.MatrixJSON
  alias PulkWeb.PieceJSON

  @type active_piece ::
          %{piece: String.t(), coordinates: [{non_neg_integer(), non_neg_integer()}]} | nil

  @type board_update_json :: %{
          piece_in_hold: String.t() | nil,
          active_piece: active_piece(),
          matrix: MatrixJSON.matrix_json()
        }

  @spec from_json(board_update_json()) :: {:ok, BoardUpdate.t()} | {:error, any()}
  def from_json(raw_board_update) do
    with {:ok, matrix} <- MatrixJSON.from_json(raw_board_update["matrix"]),
         {:ok, piece_in_hold} <- PieceJSON.from_json(raw_board_update["piece_in_hold"]),
         {:ok, active_piece} <- from_actieve_piece_json(raw_board_update["active_piece"]),
         {:ok, board_update} <-
           BoardUpdate.new(
             matrix: matrix,
             piece_in_hold: piece_in_hold,
             active_piece: active_piece
           ) do
      {:ok, board_update}
    end
  end

  @spec from_actieve_piece_json(active_piece()) ::
          {:ok, BoardUpdate.active_piece() | nil} | {:error, :invalid_figure}
  defp from_actieve_piece_json(raw_active_piece) do
    if raw_active_piece != nil do
      with {:ok, piece} <- PieceJSON.from_json(raw_active_piece.piece) do
        {:ok, %{piece: piece, coordinates: raw_active_piece.coordinates}}
      end
    else
      {:ok, nil}
    end
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
