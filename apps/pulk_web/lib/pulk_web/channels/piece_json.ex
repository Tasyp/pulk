defmodule PulkWeb.PieceJSON do
  alias Pulk.Game.Piece

  @spec from_json(String.t() | nil) :: {:ok, Piece.t() | nil} | {:error, :invalid_figure}

  def from_json(nil) do
    {:ok, nil}
  end

  def from_json(piece) when is_binary(piece) do
    case Piece.new(piece_type: piece) do
      {:ok, piece} -> {:ok, piece}
      {:error, _} -> {:error, :invalid_figure}
    end
  end

  def from_json(_) do
    {:error, :invalid_figure}
  end
end

defimpl Jason.Encoder, for: [Pulk.Game.Piece] do
  alias Pulk.Game.Piece

  def encode(struct, opts) do
    Jason.Encode.string(
      Piece.to_string(struct),
      opts
    )
  end
end
