defmodule Pulk.Piece do
  @moduledoc """
  Entity that represenets game piece type
  """

  use TypedStruct
  use Domo, gen_constructor_name: :_new

  @pieces_types [
    "I",
    "O",
    "T",
    "S",
    "Z",
    "J",
    "L"
  ]
  @ghost_type "X"
  @empty_value ""
  @supported_values MapSet.new(@pieces_types ++ [@ghost_type, @empty_value])

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

  def new!(piece_idx) when is_number(piece_idx) do
    piece_type = Enum.at(@supported_values, round(piece_idx))
    _new!(piece_type: piece_type)
  end

  def new!(piece_type) do
    _new!(piece_type: piece_type)
  end

  def pieces() do
    @pieces_types |> Enum.map(&new!(&1))
  end

  def ghost_piece() do
    new!(@ghost_type)
  end

  def eq?(%__MODULE__{piece_type: left_piece}, %__MODULE__{piece_type: right_piece}) do
    left_piece == right_piece
  end

  @spec is_supported_piece?(String.t()) :: :ok | {:error, :invalid_piece}
  def is_supported_piece?(raw_piece) do
    if MapSet.member?(@supported_values, raw_piece) do
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

  def to_integer(%__MODULE__{piece_type: piece_type}) do
    Enum.find_index(@supported_values, &(&1 == piece_type))
  end
end

defimpl Inspect, for: Pulk.Piece do
  def inspect(piece, _opts) do
    case piece.piece_type do
      "" ->
        " "

      value ->
        value
    end
  end
end

defimpl Jason.Encoder, for: [Pulk.Piece] do
  alias Pulk.Piece

  def encode(struct, opts) do
    Jason.Encode.string(
      Piece.to_string(struct),
      opts
    )
  end
end
