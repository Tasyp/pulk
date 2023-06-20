defmodule Pulk.Game.Matrix do
  @moduledoc """
  Entity that represenets game field
  """

  require Logger

  use TypedStruct
  use Domo, gen_constructor_name: :_new

  alias Pulk.Game.Piece
  alias Pulk.Game.PositionedPiece
  alias Pulk.Game.Coordinates

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

  @spec get_matrix_lines(t()) :: matrix()
  def get_matrix_lines(%__MODULE__{value: matrix}) do
    matrix
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

  def to_map(%__MODULE__{value: matrix}) do
    matrix
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, column_idx} ->
      line
      |> Enum.with_index()
      |> Enum.map(fn {cell, row_idx} ->
        {{row_idx, column_idx}, cell}
      end)
    end)
    |> Map.new()
  end

  @spec map_rows(
          t(),
          callback :: (Piece.t(), {non_neg_integer(), non_neg_integer()} -> Piece.t())
        ) :: t()
  def map_rows(%__MODULE__{} = matrix, callback) do
    matrix_value =
      matrix.value
      |> Enum.with_index()
      |> Enum.map(fn {column, column_idx} ->
        column
        |> Enum.with_index()
        |> Enum.map(fn {row, row_idx} -> callback.(row, {column_idx, row_idx}) end)
      end)

    %{matrix | value: matrix_value}
  end

  @spec add_piece(t(), PositionedPiece.t()) :: t()
  def add_piece(
        %__MODULE__{} = matrix,
        %PositionedPiece{piece: piece, coordinates: coordinates}
      ) do
    coordinates_set = Coordinates.to_set(coordinates)

    matrix
    |> map_rows(fn row_value, {column_idx, row_idx} ->
      if MapSet.member?(coordinates_set, {row_idx, column_idx}) do
        piece
      else
        row_value
      end
    end)
  end

  @spec add_ghost_piece(t(), PositionedPiece.t() | nil) :: t()
  def add_ghost_piece(%__MODULE__{} = matrix, nil) do
    matrix
  end

  def add_ghost_piece(%__MODULE__{} = matrix, %PositionedPiece{} = positioned_piece) do
    %PositionedPiece{coordinates: coordinates} = do_hard_drop(matrix, positioned_piece)
    coordinates_set = Coordinates.to_set(coordinates)

    matrix
    |> map_rows(fn row_value, {column_idx, row_idx} ->
      if MapSet.member?(coordinates_set, {row_idx, column_idx}) do
        Piece.ghost_piece()
      else
        row_value
      end
    end)
  end

  @spec can_insert_peace?(t(), PositionedPiece.t()) :: boolean()
  def can_insert_peace?(%__MODULE__{} = matrix, %PositionedPiece{coordinates: coordinates}) do
    matrix_map =
      matrix
      |> to_map()

    coordinates
    |> Enum.all?(fn coordinates ->
      current_value =
        matrix_map
        |> Map.get(coordinates)

      current_value !== nil && Piece.is_empty?(current_value)
    end)
  end

  @spec do_hard_drop(t(), PositionedPiece.t()) :: t()
  def do_hard_drop(%__MODULE__{} = matrix, %PositionedPiece{} = current_piece) do
    case PositionedPiece.move(current_piece, :down) do
      {:ok, positioned_piece} ->
        if can_insert_peace?(matrix, positioned_piece) do
          do_hard_drop(matrix, positioned_piece)
        else
          current_piece
        end

      {:error, :invalid_move} ->
        current_piece
    end
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

  @spec line_filled?(line()) :: boolean()
  defp line_filled?(line) do
    Enum.all?(line, &Kernel.not(Piece.is_empty?(&1)))
  end
end
