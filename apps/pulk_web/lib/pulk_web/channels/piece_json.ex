defmodule PulkWeb.PieceJSON do
  alias Pulk.Piece

  @spec from_json(String.t() | nil) :: {:ok, Piece.t() | nil} | {:error, term()}

  def from_json(nil) do
    {:ok, nil}
  end

  def from_json(piece) when is_bitstring(piece) do
    case Piece.new(piece) do
      {:ok, piece} -> {:ok, piece}
      {:error, _} -> {:error, :invalid_figure}
    end
  end

  def from_json(_) do
    {:error, :invalid_figure}
  end
end
