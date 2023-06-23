defimpl Jason.Encoder, for: [Pulk.Board.BoardSnapshot] do
  def encode(struct, opts) do
    Jason.Encode.map(
      Map.from_struct(struct),
      opts
    )
  end
end
