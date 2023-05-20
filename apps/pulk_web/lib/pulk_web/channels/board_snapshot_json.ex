defimpl Jason.Encoder, for: [Pulk.Game.BoardSnapshot] do
  def encode(struct, opts) do
    Jason.Encode.map(
      Map.from_struct(struct),
      opts
    )
  end
end
