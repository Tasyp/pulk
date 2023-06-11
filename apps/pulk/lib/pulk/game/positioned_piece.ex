defmodule Pulk.Game.PositionedPiece do
  @moduledoc """
  Entity that represents positioned piece
  """

  use TypedStruct
  use Domo

  alias Pulk.Game.Piece

  # Source: https://harddrop.com/wiki/SRS
  # 0 = spawn state
  # R = state resulting from a clockwise rotation ("right") from spawn
  # L = state resulting from a counter-clockwise ("left") rotation from spawn
  # 2 = state resulting from 2 successive rotations in either direction from spawn.
  @type rotation() :: :O | :R | :L | :two

  @type direction() :: :down | :left | :right

  typedstruct enforce: true do
    field(:piece, Piece.t())

    field(:rotation, rotation(), default: :O)

    field(:coordinates, [{non_neg_integer(), non_neg_integer()}])
  end

  @spec new_initial_piece!(Piece.t(), {pos_integer(), pos_integer()}) :: t()
  def new_initial_piece!(%Piece{} = piece, {size_x, size_y}) do
    coordinates = get_initial_coordinates(piece, {size_x, size_y})

    new!(
      piece: piece,
      coordinates: coordinates
    )
  end

  def get_initial_coordinates(%Piece{} = piece, {size_x, _size_y}) do
    base_coordinates = get_piece_coordinates(piece)
    piece_width = get_coordinates_width(base_coordinates)

    y_shift = 0
    x_shift = round((size_x - piece_width) / 2)

    base_coordinates
    |> shift_coordinates_by({x_shift, y_shift})
  end

  @spec move(t(), direction()) :: {:ok, t()} | {:error, :invalid_move}
  def move(%__MODULE__{coordinates: coordinates} = positioned_piece, direction) do
    updated_coordinates =
      case direction do
        :down ->
          coordinates
          |> Enum.map(fn {x, y} -> {x, y + 1} end)

        :left ->
          coordinates
          |> Enum.map(fn {x, y} -> {Enum.max([x - 1, 0]), y} end)

        :right ->
          coordinates
          |> Enum.map(fn {x, y} -> {x + 1, y} end)
      end

    case ensure_type(%{positioned_piece | coordinates: updated_coordinates}) do
      {:ok, position_piece} -> {:ok, position_piece}
      {:error, _} -> {:error, :invalid_move}
    end
  end

  @spec rotate(t(), rotation()) :: t()
  def rotate(%__MODULE__{} = positioned_piece, _rotation) do
    positioned_piece
  end

  defp get_piece_coordinates(%Piece{piece_type: piece_type}) do
    case piece_type do
      "I" ->
        [
          {0, 0},
          {1, 0},
          {2, 0},
          {3, 0},
          {4, 0}
        ]

      "O" ->
        [
          {0, 0},
          {0, 1},
          {1, 0},
          {1, 1}
        ]

      "T" ->
        [
          {1, 0},
          {0, 1},
          {1, 1},
          {2, 1}
        ]

      "S" ->
        [
          {1, 0},
          {2, 0},
          {0, 1},
          {1, 1}
        ]

      "Z" ->
        [
          {0, 0},
          {1, 0},
          {1, 1},
          {2, 1}
        ]

      "J" ->
        [
          {0, 0},
          {0, 1},
          {1, 1},
          {2, 1}
        ]

      "L" ->
        [
          {2, 0},
          {0, 1},
          {1, 1},
          {2, 1}
        ]
    end
  end

  defp get_coordinates_width(coordinates) do
    x_coordinates =
      coordinates
      |> Enum.map(fn {x, _y} -> x end)

    min_x = Enum.min(x_coordinates)
    max_x = Enum.max(x_coordinates)

    max_x - min_x + 1
  end

  defp shift_coordinates_by(coordinates, {shift_x, shift_y}) do
    coordinates
    |> Enum.map(fn {x, y} -> {x + shift_x, y + shift_y} end)
  end
end
