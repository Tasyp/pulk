defmodule Pulk.Matrix do
  @moduledoc """
  Entity that represenets game field
  """

  require Logger

  use TypedStruct
  use Domo, gen_constructor_name: :_new, remote_types_as_any: [{Matrex, :t}]

  alias Pulk.Matrix
  alias Matrex
  alias Pulk.Piece
  alias Pulk.Piece.PositionedPiece
  alias Pulk.Matrix.Coordinates

  @type line :: [Piece.t()]
  @type matrix :: [line()]

  typedstruct do
    field :value, Matrex.t(), enforce: true
  end

  @spec new!(pos_integer(), pos_integer()) :: t()
  def new!(size_x, size_y) do
    matrix = Matrex.new(size_y, size_x, fn -> Piece.new!() |> Piece.to_integer() end)
    _new!(value: matrix)
  end

  @spec new!(Matrex.t()) :: t()
  def new!(matrix) do
    _new!(value: from_piece_matrix(matrix))
  end

  def new(matrix) do
    _new(value: from_piece_matrix(matrix))
  end

  def from_piece_matrix(piece_matrix) do
    piece_matrix
    |> Enum.map(fn row ->
      row
      |> Enum.map(fn cell ->
        case cell do
          _ when is_number(cell) -> cell
          piece -> Piece.to_integer(piece)
        end
      end)
    end)
    |> Matrex.new()
  end

  @spec get_matrix_lines(t()) :: matrix()
  def get_matrix_lines(%__MODULE__{value: matrix}) do
    Matrex.to_list_of_lists(matrix)
    |> Enum.map(fn row ->
      row
      |> Enum.map(&(Piece.new!(&1)))
    end)
  end

  @spec has_matching_size?(t(), {pos_integer(), pos_integer()}) ::
          :ok | {:error, :invalid_size}
  def has_matching_size?(%__MODULE__{value: matrix}, {size_x, size_y}) do
    case Matrex.size(matrix) do
      {^size_x, ^size_y} -> :ok
      _ -> {:error, :invalid_size}
    end
  end

  @spec map_cells(t(), Coordinates.collection(), Piece.t()) :: t()
  def map_cells(%__MODULE__{value: matrix} = state, coordinates, piece) do
    matrix = map_matrix_cells(matrix, coordinates, piece)
    %{state | value: matrix}
  end

  def map_matrix_cells(matrix, coordinates, piece) do
    coordinates
      |> Enum.reduce(matrix, fn {x, y}, matrix ->
        Matrex.set(matrix, y + 1, x + 1, Piece.to_integer(piece))
      end)
  end

  @spec add_piece(t(), PositionedPiece.t()) :: t()
  def add_piece(
        %__MODULE__{} = matrix,
        %PositionedPiece{piece: piece, coordinates: coordinates}
      ) do
    matrix
    |> map_cells(coordinates, piece)
  end

  @spec add_ghost_piece(t(), PositionedPiece.t() | nil) :: t()
  def add_ghost_piece(%__MODULE__{} = matrix, nil) do
    matrix
  end

  def add_ghost_piece(%__MODULE__{} = matrix, %PositionedPiece{} = positioned_piece) do
    %PositionedPiece{coordinates: coordinates} = do_hard_drop(matrix, positioned_piece)

    matrix
    |> map_cells(coordinates, Piece.ghost_piece())
  end

  @spec can_insert_peace?(t(), PositionedPiece.t()) :: boolean()
  def can_insert_peace?(%__MODULE__{} = matrix, %PositionedPiece{coordinates: coordinates}) do
    coordinates
    |> Enum.map(fn {x, y} -> at(matrix, x, y) end)
    |> Enum.all?(&(&1 !== nil && Piece.new!(&1) |> Piece.is_empty?()))
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
    {new!(Matrex.to_list_of_lists(matrix)), filled_lines_count}
  end

  @spec do_remove_filled_lines(Matrex.t()) :: {Matrex.t(), non_neg_integer()}
  @spec do_remove_filled_lines(Matrex.t(), non_neg_integer()) :: {Matrex.t(), non_neg_integer()}
  defp do_remove_filled_lines(matrix, filled_lines_count \\ 0) do
    maybe_filled_line_idx =
      matrix
      |> Matrex.list_of_rows()
      |> Enum.find_index(&line_filled?/1)

    case maybe_filled_line_idx do
      nil ->
        {matrix, filled_lines_count}

      line_idx ->
        {_rows_count, column_count} = Matrex.size(matrix)

        next_matrix =
          line_idx..0//-1
          |> Enum.to_list()
          |> List.foldl(matrix, fn
            0, acc ->
              coordinates = 0..(column_count - 1)
                |> Enum.map(&({&1, 0}))

              acc
              |> map_matrix_cells(coordinates, Piece.new!())

            idx, acc ->
              replace_row(acc, idx + 1, Matrex.row(acc, idx))
          end)

        do_remove_filled_lines(
          next_matrix,
          filled_lines_count + 1
        )
    end
  end

  defp at(%__MODULE__{value: matrix}, x, y) do
    try do
      Matrex.at(matrix, x + 1, y + 1)
    rescue
      ArgumentError -> nil
    end
  end

  defp replace_row(matrix, idx, row) do
    {_rows_count, column_count} = Matrex.size(matrix)

    1..column_count
    |> Enum.reduce(matrix, fn column_idx, matrix ->
      value = Matrex.at(row, 1, column_idx)

      Matrex.set(matrix, idx, column_idx, value)
    end)
  end

  @spec line_filled?(line()) :: boolean()
  defp line_filled?(line) do
    Enum.all?(line, &Kernel.not(Piece.new!(&1) |> Piece.is_empty?()))
  end
end

defimpl Jason.Encoder, for: [Pulk.Matrix] do
  alias Pulk.Matrix

  def encode(struct, opts) do
    Jason.Encode.list(
      struct
      |> Matrix.get_matrix_lines(),
      opts
    )
  end
end
