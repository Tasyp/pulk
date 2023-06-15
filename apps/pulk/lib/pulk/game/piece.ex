defmodule Pulk.Game.Piece do
  @moduledoc """
  Entity that represenets game piece type
  """

  use TypedStruct
  use Domo, gen_constructor_name: :_new

  @supported_pieces MapSet.new(["", "I", "O", "T", "S", "Z", "J", "L", "X"])

  @type piece_type :: String.t()
  precond piece_type: &is_supported_piece?/1

  typedstruct do
    field :piece_type, piece_type(), default: ""
  end

  def new(piece_type) do
    _new(piece_type: piece_type)
  end

  def new!() do
    _new!()
  end

  def new!(piece_type) do
    _new!(piece_type: piece_type)
  end

  @spec is_supported_piece?(String.t()) :: :ok | {:error, :invalid_piece}
  def is_supported_piece?(raw_piece) do
    if MapSet.member?(@supported_pieces, raw_piece) do
      :ok
    else
      {:error, :invalid_piece}
    end
  end

  @spec is_empty?(t()) :: boolean()
  def is_empty?(%__MODULE__{piece_type: piece}) do
    piece == ""
  end

  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{piece_type: piece_type}) do
    piece_type
  end
end

defimpl Inspect, for: Pulk.Game.Piece do
  def inspect(piece, _opts) do
    piece.piece_type
  end
end
