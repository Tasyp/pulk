defmodule Pulk.Game.Matrix do
  use TypedStruct
  use Domo, gen_constructor_name: :_new

  alias Pulk.Game.Piece

  @type matrix :: [[Piece.t()]]

  typedstruct do
    field :value, matrix(), enforce: true
  end

  @spec new!(pos_integer(), pos_integer()) :: t()
  def new!(sizeX, sizeY) do
    matrix =
      1..sizeY
      |> Enum.map(fn _ -> 1..sizeX |> Enum.map(fn _ -> Piece.new!() end) end)

    _new!(value: matrix)
  end

  @spec new!(matrix()) :: t()
  def new!(matrix) do
    _new!(value: matrix)
  end

  def new(matrix) do
    _new(value: matrix)
  end

  @spec has_matching_size?(t(), {pos_integer(), pos_integer()}) ::
          :ok | {:error, :invalid_size}
  def has_matching_size?(%__MODULE__{value: matrix}, {sizeX, sizeY}) do
    actualSizeY = length(matrix)

    actualSizesX = matrix |> Enum.map(fn row -> length(row) end) |> MapSet.new() |> Enum.to_list()

    cond do
      actualSizeY != sizeY -> {:error, :invalid_size}
      actualSizesX != [sizeX] -> {:error, :invalid_size}
      true -> :ok
    end
  end

  @spec remove_filled_lines(t()) :: {t(), non_neg_integer()}
  def remove_filled_lines(%__MODULE__{value: matrix}) do
    {reversed_matrix, filled_lines_count} = do_remove_filled_lines(Enum.reverse(matrix))
    {new!(Enum.reverse(reversed_matrix)), filled_lines_count}
  end

  @spec do_remove_filled_lines(matrix()) :: {matrix(), non_neg_integer()}
  @spec do_remove_filled_lines(matrix(), non_neg_integer()) :: {matrix(), non_neg_integer()}
  defp do_remove_filled_lines(reversed_matrix, filled_lines_count \\ 0) do
    [last_line | remaining_lines] = reversed_matrix

    if Enum.all?(last_line, &Kernel.not(Piece.is_empty?(&1))) do
      do_remove_filled_lines(remaining_lines, filled_lines_count + 1)
    else
      {reversed_matrix, filled_lines_count}
    end
  end
end
