defmodule PulkWeb.BoardJSON do
  alias Pulk.Game.Board
  alias PulkWeb.MatrixJSON

  def to_json(%Board{matrix: matrix} = board) do
    %{board | matrix: MatrixJSON.to_json(matrix)}
  end
end

defimpl Jason.Encoder, for: [Pulk.Game.Board] do
  alias PulkWeb.BoardJSON

  def encode(struct, opts) do
    Jason.Encode.map(
      Map.drop(BoardJSON.to_json(struct), [:sizeX, :sizeY]),
      opts
    )
  end
end
