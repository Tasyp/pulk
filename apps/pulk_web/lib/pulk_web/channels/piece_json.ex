defmodule PulkWeb.PieceJSON do
  alias Pulk.Game.Piece

  @spec from_json(String.t() | nil) :: {:ok, Piece.t() | nil} | {:error, :invalid_figure}
  def from_json(piece) do
    if piece != nil do
      case Piece.new(piece) do
        {:ok, piece} -> {:ok, piece}
        {:error, _} -> {:error, :invalid_figure}
      end
    else
      {:ok, nil}
    end
  end
end

defimpl Jason.Encoder, for: [Pulk.Game.Piece] do
  alias Pulk.Game.Piece

  def encode(struct, opts) do
    Jason.Encode.list(
      Piece.to_string(struct),
      opts
    )
  end
end
