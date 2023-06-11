defmodule Pulk.Game.PieceBag do
  use TypedStruct
  use Domo, gen_constructor_name: :_new

  alias Pulk.Game.PositionedPiece
  alias Pulk.Game.Piece

  typedstruct do
    field(:piece_queue, list(Piece.t()), enforce: true)
  end

  def new!() do
    _new!(piece_queue: generate_piece_queue())
  end

  @spec get_piece(t(), {pos_integer(), pos_integer()}) :: {t(), PositionedPiece.t()}
  def get_piece(%__MODULE__{piece_queue: piece_queue} = bag, {size_x, size_y}) do
    piece_queue = extend_queue_on_demand(piece_queue)

    [next_piece | piece_queue] = piece_queue

    positioned_piece = PositionedPiece.new_initial_piece!(next_piece, {size_x, size_y})

    {%{bag | piece_queue: piece_queue}, positioned_piece}
  end

  @spec get_queue_preview(t()) :: list(Piece.t())
  def get_queue_preview(%__MODULE__{piece_queue: piece_queue}) do
    piece_queue
    |> Enum.take(3)
  end

  defp extend_queue_on_demand(piece_queue) do
    if length(piece_queue) < 7 do
      piece_queue ++ generate_piece_queue()
    else
      piece_queue
    end
  end

  defp generate_piece_queue() do
    Enum.shuffle(Piece.pieces())
  end
end
