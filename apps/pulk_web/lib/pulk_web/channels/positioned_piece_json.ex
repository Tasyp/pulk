defmodule PulkWeb.PositionedPieceJSON do
  alias Pulk.Game.PositionedPiece
  alias PulkWeb.PieceJSON

  @type positioned_piece_json :: %{
          piece: String.t(),
          coordinates: [{non_neg_integer(), non_neg_integer()}]
        }

  @spec from_json(map() | nil) ::
          {:ok, PositionedPiece.t() | nil}
          | {:error, :invalid_figure}
          | {:error, :invalid_positioned_piece}

  def from_json(nil) do
    {:ok, nil}
  end

  def from_json(%{"piece" => piece, "coordinates" => coordinates}) when is_list(coordinates) do
    with {:ok, piece} <- PieceJSON.from_json(piece),
         {:ok, coordinates} <- parse_coordinates(coordinates) do
      {:ok, PositionedPiece.new!(piece: piece, coordinates: coordinates)}
    end
  end

  def from_json(_) do
    {:error, :invalid_active_piece}
  end

  defp parse_coordinates(coordinates) when is_list(coordinates) do
    if Enum.all?(coordinates, &Kernel.is_list(&1)) do
      {:ok, Enum.map(coordinates, &List.to_tuple(&1))}
    else
      {:error, :invalid_positioned_piece}
    end
  end
end

defimpl Jason.Encoder, for: [Pulk.Game.PositionedPiece] do
  def encode(struct, opts) do
    Jason.Encode.map(
      %{Map.from_struct(struct) | coordinates: Enum.map(struct.coordinates, &Tuple.to_list(&1))},
      opts
    )
  end
end
