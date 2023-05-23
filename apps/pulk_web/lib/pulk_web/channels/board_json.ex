defimpl Jason.Encoder, for: [Pulk.Game.Board] do
  alias Pulk.Game.Board

  @visible_fields [:score, :cleared_lines_count, :piece_in_hold, :active_piece, :matrix, :status]

  def encode(struct, opts) do
    next_struct =
      struct
      |> Map.from_struct()
      |> Map.take(@visible_fields)
      |> Map.put(:level, Board.level(struct))

    Jason.Encode.map(next_struct, opts)
  end
end
