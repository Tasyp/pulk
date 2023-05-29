defmodule Pulk.Game.Matrix do
  use TypedStruct
  use Domo, gen_constructor_name: :_new

  alias Pulk.Game.Piece

  @type line :: [Piece.t()]
  @type matrix :: [line()]

  typedstruct do
    field :value, matrix(), enforce: true
  end

  @spec new!(pos_integer(), pos_integer()) :: t()
  def new!(size_x, size_y) do
    matrix =
      1..size_y
      |> Enum.map(fn _ -> 1..size_x |> Enum.map(fn _ -> Piece.new!() end) end)

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
  def has_matching_size?(%__MODULE__{value: matrix}, {size_x, size_y}) do
    actual_size_y = length(matrix)

    actual_sizes_x =
      matrix |> Enum.map(fn row -> length(row) end) |> MapSet.new() |> Enum.to_list()

    cond do
      actual_size_y != size_y -> {:error, :invalid_size}
      actual_sizes_x != [size_x] -> {:error, :invalid_size}
      true -> :ok
    end
  end

  @spec is_complete?(t()) :: boolean()
  def is_complete?(%__MODULE__{value: matrix}) do
    matrix
    |> Enum.all?(&line_not_empty?/1)
  end

  @spec remove_filled_lines(t()) :: {t(), non_neg_integer()}
  def remove_filled_lines(%__MODULE__{value: matrix}) do
    {matrix, filled_lines_count} = do_remove_filled_lines(matrix)
    {new!(matrix), filled_lines_count}
  end

  @spec do_remove_filled_lines(matrix()) :: {matrix(), non_neg_integer()}
  @spec do_remove_filled_lines(matrix(), non_neg_integer()) ::
          {matrix(), non_neg_integer()}
  defp do_remove_filled_lines(matrix, filled_lines_count \\ 0) do
    maybe_filled_line_idx =
      matrix
      |> Enum.find_index(&line_filled?/1)

    case maybe_filled_line_idx do
      nil ->
        {matrix, filled_lines_count}

      line_idx ->
        next_matrix =
          line_idx..0//-1
          |> Enum.to_list()
          |> List.foldl(matrix, fn
            0, acc ->
              empty_line =
                matrix
                |> Enum.at(line_idx)
                |> create_empty_line()

              List.replace_at(acc, 0, empty_line)

            idx, acc ->
              List.replace_at(acc, idx, Enum.at(acc, idx - 1))
          end)

        do_remove_filled_lines(
          next_matrix,
          filled_lines_count + 1
        )
    end
  end

  @spec create_empty_line(line()) :: line()
  defp create_empty_line(line) do
    line
    |> Enum.map(fn _ -> Piece.new!() end)
  end

  @spec line_not_empty?(line()) :: boolean()
  defp line_not_empty?(line) do
    Enum.any?(line, &Kernel.not(Piece.is_empty?(&1)))
  end

  @spec line_filled?(line()) :: boolean()
  defp line_filled?(line) do
    Enum.all?(line, &Kernel.not(Piece.is_empty?(&1)))
  end
end
