defmodule Pulk.Game.PositionedPiece do
  @moduledoc """
  Entity that represents positioned piece
  """

  use TypedStruct
  use Domo

  alias Pulk.Game.Piece
  alias Pulk.Game.Rotation
  alias Pulk.Game.Coordinates

  @type direction() :: :down | :left | :right

  typedstruct enforce: true do
    field :piece, Piece.t()

    field :rotation, Rotation.t(), default: :O

    field :base_point, Coordinates.t()

    field :coordinates, [Coordinates.t()]
  end

  @spec new_initial_piece!(Piece.t(), {pos_integer(), pos_integer()}) :: t()
  def new_initial_piece!(%Piece{} = piece, {size_x, size_y}) do
    {coordinates, base_point} = get_initial_coordinates(piece, {size_x, size_y})

    new!(
      piece: piece,
      coordinates: coordinates,
      base_point: base_point
    )
  end

  def get_initial_coordinates(%Piece{} = piece, {size_x, _size_y}) do
    {base_coordinates, base_point} = get_base_piece_coordinates(piece)
    piece_width = Coordinates.get_coordinates_width(base_coordinates)

    y_shift = 0
    x_shift = floor((size_x - piece_width) / 2)
    shift_by = {x_shift, y_shift}

    shifted_coordinates =
      base_coordinates
      |> Coordinates.shift_coordinates_by(shift_by)

    shifted_base_point = Coordinates.shift_point_by(base_point, shift_by)

    {shifted_coordinates, shifted_base_point}
  end

  @spec move(t(), direction()) :: {:ok, t()} | {:error, :invalid_move}
  def move(
        %__MODULE__{coordinates: coordinates, base_point: base_point} = positioned_piece,
        direction
      ) do
    apply_shift = fn {x, y} ->
      case direction do
        :down ->
          {x, y + 1}

        :left ->
          {x - 1, y}

        :right ->
          {x + 1, y}
      end
    end

    updated_coordinates = coordinates |> Enum.map(&apply_shift.(&1))
    updated_base_point = apply_shift.(base_point)

    case ensure_type(%{
           positioned_piece
           | coordinates: updated_coordinates,
             base_point: updated_base_point
         }) do
      {:ok, position_piece} -> {:ok, position_piece}
      {:error, _} -> {:error, :invalid_move}
    end
  end

  @spec rotate(t(), Rotation.relative_rotation()) :: {:ok, t()}
  def rotate(%__MODULE__{rotation: rotation} = positioned_piece, relative_rotation) do
    rotation_angle = Rotation.relative_rotation_angle(relative_rotation)

    coordinates =
      positioned_piece.coordinates
      |> Enum.map(&Coordinates.rotate_point(&1, rotation_angle, positioned_piece.base_point))

    next_rotation_type = Rotation.apply_relative_rotation(rotation, relative_rotation)

    case ensure_type(%{
           positioned_piece
           | coordinates: coordinates,
             rotation: next_rotation_type
         }) do
      {:ok, position_piece} -> {:ok, position_piece}
      {:error, _} -> {:error, :invalid_move}
    end
  end

  defp get_base_piece_coordinates(%Piece{piece_type: piece_type}) do
    case piece_type do
      "I" ->
        {
          [
            {0, 0},
            {1, 0},
            {2, 0},
            {3, 0}
          ],
          {1, 0}
        }

      "O" ->
        {
          [
            {0, 0},
            {0, 1},
            {1, 0},
            {1, 1}
          ],
          {0, 1}
        }

      "T" ->
        {
          [
            {1, 0},
            {0, 1},
            {1, 1},
            {2, 1}
          ],
          {1, 1}
        }

      "S" ->
        {
          [
            {1, 0},
            {2, 0},
            {0, 1},
            {1, 1}
          ],
          {1, 1}
        }

      "Z" ->
        {
          [
            {0, 0},
            {1, 0},
            {1, 1},
            {2, 1}
          ],
          {1, 1}
        }

      "J" ->
        {
          [
            {0, 0},
            {0, 1},
            {1, 1},
            {2, 1}
          ],
          {1, 1}
        }

      "L" ->
        {
          [
            {2, 0},
            {0, 1},
            {1, 1},
            {2, 1}
          ],
          {1, 1}
        }
    end
  end
end
