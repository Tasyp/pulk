defmodule Pulk.Game.Board do
  alias Pulk.Game.Figure

  @type t :: %__MODULE__{
          sizeX: pos_integer(),
          sizeY: pos_integer(),
          matrix: list(list(Figure.t()))
        }

  @enforce_keys [:sizeX, :sizeY, :matrix]
  defstruct [:sizeX, :sizeY, :matrix]

  @spec create({pos_integer(), pos_integer()}) :: t()
  def create({sizeX, sizeY}) do
    %__MODULE__{
      sizeX: sizeX,
      sizeY: sizeY,
      matrix: build_matrix(sizeX, sizeY)
    }
  end

  @spec create(pos_integer(), pos_integer()) :: t()
  def create(sizeX, sizeY) do
    create({sizeX, sizeY})
  end

  @spec to_raw_matrix(t()) :: list(list(String.t()))
  def to_raw_matrix(%__MODULE__{matrix: matrix}) do
    matrix
    |> Enum.map(&Enum.map(&1, fn row -> Figure.to_string(row) end))
  end

  @spec build_matrix(pos_integer(), pos_integer()) :: list(list(Figure.t()))
  def build_matrix(sizeX, sizeY) do
    1..sizeY
    |> Enum.map(fn _ -> 1..sizeX |> Enum.map(fn _ -> Figure.create!() end) end)
  end

  @spec update_board(t(), list(list(String.t()))) ::
          {:ok, t()} | {:error, :invalid_figures} | {:error, :invalid_size}
  def update_board(%__MODULE__{} = board, raw_matrix) do
    with :ok <- is_board_parsable?(raw_matrix),
         :ok <- is_board_size_correct?(board, raw_matrix) do
      parsed_matrix =
        raw_matrix
        |> Enum.map(&Enum.map(&1, fn cell -> Figure.create!(cell) end))

      {:ok, %{board | matrix: parsed_matrix}}
    end
  end

  @spec is_board_size_correct?(t(), list(list(String.t()))) :: :ok | {:error, :invalid_size}
  def is_board_size_correct?(%__MODULE__{sizeX: sizeX, sizeY: sizeY}, raw_matrix) do
    actualSizeY = length(raw_matrix)

    actualSizesX =
      raw_matrix |> Enum.map(fn row -> length(row) end) |> MapSet.new() |> Enum.to_list()

    cond do
      actualSizeY != sizeY -> {:error, :invalid_size}
      actualSizesX != [sizeX] -> {:error, :invalid_size}
      true -> :ok
    end
  end

  @spec is_board_parsable?(list(list(String.t()))) :: :ok | {:error, :invalid_figures}
  def is_board_parsable?(raw_matrix) do
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
end
