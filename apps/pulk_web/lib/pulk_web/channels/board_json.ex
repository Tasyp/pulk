defimpl Jason.Encoder, for: [Pulk.Game.Board] do
  alias Pulk.Game.Board

  @visible_fields [
    :score,
    :cleared_lines_count,
    :piece_in_hold,
    :active_piece,
    :status,
    :placement
  ]

  def encode(struct, opts) do
    next_struct =
      struct
      |> Map.from_struct()
      |> Map.take(@visible_fields)
      |> Map.put(:level, Board.level(struct))
      |> Map.put(:piece_queue, Board.piece_queue(struct))
      |> Map.put(:matrix, Board.matrix(struct))

    Jason.Encode.map(next_struct, opts)
  end
end
