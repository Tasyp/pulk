defmodule Pulk.Game.Matrix do
  alias Pulk.Game.Figure

  @type t :: list(list(Figure.t()))
  @type loosy_matrix :: list(list(String.t()))

  @spec create(pos_integer(), pos_integer()) :: t()
  def create(sizeX, sizeY) do
    1..sizeY
    |> Enum.map(fn _ -> 1..sizeX |> Enum.map(fn _ -> Figure.create!() end) end)
  end

  @spec to_raw_matrix(t()) :: loosy_matrix()
  def to_raw_matrix(matrix) do
    matrix
    |> Enum.map(&Enum.map(&1, fn row -> Figure.to_string(row) end))
  end

  @spec is_matrix_size_correct?(loosy_matrix(), {pos_integer(), pos_integer()}) ::
          :ok | {:error, :invalid_size}
  def is_matrix_size_correct?(raw_matrix, {sizeX, sizeY}) do
    actualSizeY = length(raw_matrix)

    actualSizesX =
      raw_matrix |> Enum.map(fn row -> length(row) end) |> MapSet.new() |> Enum.to_list()

    cond do
      actualSizeY != sizeY -> {:error, :invalid_size}
      actualSizesX != [sizeX] -> {:error, :invalid_size}
      true -> :ok
    end
  end

  @spec is_matrix_parsable?(loosy_matrix()) :: :ok | {:error, :invalid_figures}
  def is_matrix_parsable?(raw_matrix) do
    parsable? =
      raw_matrix
      |> Enum.flat_map(fn row ->
        Enum.map(row, fn cell -> Figure.is_supported_figure?(cell) end)
      end)
      |> Enum.all?()

    if parsable? do
      :ok
    else
      {:error, :invalid_figures}
    end
  end

  @spec remove_filled_lines(t()) :: {t(), non_neg_integer()}
  def remove_filled_lines(matrix) do
    {reversed_matrix, filled_lines_count} = do_remove_filled_lines(Enum.reverse(matrix))
    {Enum.reverse(reversed_matrix), filled_lines_count}
  end

  @spec do_remove_filled_lines(t()) :: {t(), non_neg_integer()}
  @spec do_remove_filled_lines(t(), non_neg_integer()) :: {t(), non_neg_integer()}
  defp do_remove_filled_lines(reversed_matrix, filled_lines_count \\ 0) do
    [last_line | remaining_lines] = reversed_matrix

    if Enum.all?(last_line, &Kernel.not(Figure.is_empty?(&1))) do
      do_remove_filled_lines(remaining_lines, filled_lines_count + 1)
    else
      {reversed_matrix, filled_lines_count}
    end
  end
end
