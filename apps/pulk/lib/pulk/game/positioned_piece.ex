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
  @type relative_rotation() :: :left | :right

  @type direction() :: :down | :left | :right

  @rotations [
    :O,
    :R,
    :L,
    :two
  ]

  typedstruct enforce: true do
    field(:piece, Piece.t())

    field(:rotation, rotation(), default: :O)

    field(:base_point, {non_neg_integer(), non_neg_integer()})

    field(:coordinates, [{non_neg_integer(), non_neg_integer()}])
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
    piece_width = get_coordinates_width(base_coordinates)

    y_shift = 0
    x_shift = floor((size_x - piece_width) / 2)
    shift_by = {x_shift, y_shift}

    shifted_coordinates =
      base_coordinates
      |> shift_coordinates_by(shift_by)

    shifted_base_point = shift_point_by(base_point, shift_by)

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

  @spec rotate(t(), relative_rotation()) :: {:ok, t()}
  def rotate(%__MODULE__{} = positioned_piece, relative_rotation) do
    offset = relative_rotation_to_offset(relative_rotation)
    next_rotation = apply_relative_rotation(positioned_piece, relative_rotation)

    rotation_angle = 90 * offset

    coordinates =
      positioned_piece.coordinates
      |> Enum.map(&rotate_point(&1, rotation_angle, positioned_piece.base_point))

    case ensure_type(%{
           positioned_piece
           | coordinates: coordinates,
             rotation: next_rotation
         }) do
      {:ok, position_piece} -> {:ok, position_piece}
      {:error, _} -> {:error, :invalid_move}
    end
  end

  @spec apply_relative_rotation(t(), relative_rotation()) :: rotation()
  defp apply_relative_rotation(%__MODULE__{rotation: rotation}, relative_rotation) do
    current_rotation_idx =
      @rotations
      |> Enum.find_index(&(&1 == rotation))

    next_rotation_idx =
      (current_rotation_idx + relative_rotation_to_offset(relative_rotation))
      |> rem(length(@rotations))

    Enum.fetch!(@rotations, next_rotation_idx)
  end

  defp relative_rotation_to_offset(relative_rotation) do
    case relative_rotation do
      :left -> -1
      :right -> 1
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
            {3, 0},
            {4, 0}
          ],
          {2, 0}
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

  defp get_coordinates_width(coordinates) do
    x_coordinates =
      coordinates
      |> Enum.map(fn {x, _y} -> x end)

    min_x = Enum.min(x_coordinates)
    max_x = Enum.max(x_coordinates)

    max_x - min_x + 1
  end

  defp shift_point_by({x, y}, {shift_x, shift_y}) do
    {x + shift_x, y + shift_y}
  end

  defp shift_coordinates_by(coordinates, shift_by) do
    coordinates
    |> Enum.map(&shift_point_by(&1, shift_by))
  end

  @spec rotate_point(
          point_to_rotate ::
            {integer(), integer()},
          angle :: integer(),
          center_point :: {integer(), integer()}
        ) :: {integer(), integer()}
  defp rotate_point({px, py}, angle, {cx, cy}) do
    # Translate the coordinate system
    px_translated = px - cx
    py_translated = py - cy

    # Convert angle to radians
    angle_rad = :math.pi() * angle / 180.0

    # Rotate the point around the origin
    px_rotated = px_translated * :math.cos(angle_rad) - py_translated * :math.sin(angle_rad)
    py_rotated = px_translated * :math.sin(angle_rad) + py_translated * :math.cos(angle_rad)

    # Translate the coordinate system back
    {round(px_rotated + cx), round(py_rotated + cy)}
  end
end
