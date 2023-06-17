defmodule PulkWeb.MatrixJSON do
  alias Pulk.Game.Matrix
  alias Pulk.Game.Piece

  @type matrix_json :: list(list(String.t()))

  @spec from_json(matrix_json()) ::
          {:ok, Matrix.t()} | {:error, :invalid_figure} | {:error, :invalid_matrix}
  def from_json(raw_matrix) do
    with :ok <- is_matrix_parsable?(raw_matrix) do
      matrix =
        raw_matrix
        |> Enum.map(&Enum.map(&1, fn cell -> Piece.new!(cell) end))

      case Matrix.new(matrix) do
        {:ok, matrix} ->
          {:ok, matrix}

        {:error, _} ->
          {:error, :invalid_matrix}
      end
    end
  end

  @spec is_matrix_parsable?(matrix_json()) ::
          :ok | {:error, :invalid_figure} | {:error, :invalid_matrix}
  defp is_matrix_parsable?(raw_matrix) when is_list(raw_matrix) do
    parsable? =
      raw_matrix
      |> Enum.flat_map(fn
        row when is_list(row) ->
          Enum.map(row, fn
            cell when is_binary(cell) ->
              Piece.is_supported_piece?(cell)

            _ ->
              false
          end)

        _ ->
          [false]
      end)
      |> Enum.all?()

    if parsable? do
      :ok
    else
      {:error, :invalid_figure}
    end
  end

  defp is_matrix_parsable?(_) do
    {:error, :invalid_matrix}
  end
end

defimpl Jason.Encoder, for: [Pulk.Game.Matrix] do
  alias Pulk.Game.Matrix

  def encode(struct, opts) do
    Jason.Encode.list(
      struct
      |> Matrix.remove_buffer_zone()
      |> Matrix.get_matrix_lines(),
      opts
    )
  end
end
