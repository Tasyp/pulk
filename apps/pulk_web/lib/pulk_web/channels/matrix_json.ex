defmodule PulkWeb.MatrixJSON do
  alias Pulk.Game.Matrix
  alias Pulk.Game.Piece

  @type matrix_json :: list(list(String.t()))

  @spec to_json(Matrix.t()) :: matrix_json()
  def to_json(%Matrix{value: matrix}) do
    matrix
    |> Enum.map(&Enum.map(&1, fn row -> Piece.to_string(row) end))
  end

  @spec from_json(matrix_json()) :: {:ok, Matrix.t()} | {:error, any()}
  def from_json(raw_matrix) do
    with :ok <- is_matrix_parsable?(raw_matrix) do
      matrix =
        raw_matrix
        |> Enum.map(&Enum.map(&1, fn cell -> Piece.new!(piece_type: cell) end))

      Matrix.new(matrix)
    end
  end

  @spec is_matrix_parsable?(matrix_json()) :: :ok | {:error, :invalid_figure}
  defp is_matrix_parsable?(raw_matrix) do
    parsable? =
      raw_matrix
      |> Enum.flat_map(fn row ->
        Enum.map(row, fn cell -> Piece.is_supported_piece?(cell) end)
      end)
      |> Enum.all?()

    if parsable? do
      :ok
    else
      {:error, :invalid_figure}
    end
  end
end
