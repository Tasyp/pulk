defimpl Jason.Encoder, for: [Pulk.Game.PositionedPiece] do
  def encode(struct, opts) do
    Jason.Encode.map(
      struct
      |> Map.from_struct()
      |> Map.put(:coordinates, Enum.map(struct.coordinates, &Tuple.to_list(&1)))
      |> Map.put(:base_point, Tuple.to_list(struct.base_point)),
      opts
    )
  end
end
