defmodule Pulk.Game.Board do
  alias Pulk.Game.Figure
  alias Pulk.Game.Matrix

  @type t :: %__MODULE__{
          sizeX: pos_integer(),
          sizeY: pos_integer(),
          level: non_neg_integer(),
          score: non_neg_integer(),
          piece_in_hold: Figure.t() | nil,
          active_figure: Figure.t() | nil,
          matrix: Matrix.t()
        }

  @enforce_keys [:sizeX, :sizeY, :score, :level, :piece_in_hold, :active_figure, :matrix]
  defstruct [:sizeX, :sizeY, :score, :level, :piece_in_hold, :active_figure, :matrix]

  @spec create({pos_integer(), pos_integer()}) :: t()
  def create({sizeX, sizeY}) do
    %__MODULE__{
      sizeX: sizeX,
      sizeY: sizeY,
      score: 0,
      level: 1,
      piece_in_hold: nil,
      active_figure: nil,
      matrix: Matrix.create(sizeX, sizeY)
    }
  end

  @spec create(pos_integer(), pos_integer()) :: t()
  def create(sizeX, sizeY) do
    create({sizeX, sizeY})
  end

  @spec to_raw_matrix(t()) :: Matrix.loosy_matrix()
  def to_raw_matrix(%__MODULE__{matrix: matrix}) do
    Matrix.to_raw_matrix(matrix)
  end

  @spec update_from_raw_matrix(t(), Matrix.loosy_matrix()) ::
          {:ok, t()} | {:error, :invalid_figures} | {:error, :invalid_size}
  def update_from_raw_matrix(%__MODULE__{} = board, raw_matrix) do
    with :ok <- Matrix.is_matrix_parsable?(raw_matrix),
         :ok <- Matrix.is_matrix_size_correct?(raw_matrix, {board.sizeX, board.sizeY}) do
      parsed_matrix =
        raw_matrix
        |> Enum.map(&Enum.map(&1, fn cell -> Figure.create!(cell) end))

      {:ok, %{board | matrix: parsed_matrix}}
    end
  end
end
