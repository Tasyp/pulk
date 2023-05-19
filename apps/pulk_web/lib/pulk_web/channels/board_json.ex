defimpl Jason.Encoder, for: [Pulk.Game.Board] do
  def encode(struct, opts) do
    Jason.Encode.map(
      Map.drop(Map.from_struct(struct), [:sizeX, :sizeY]),
      opts
    )
  end
end
