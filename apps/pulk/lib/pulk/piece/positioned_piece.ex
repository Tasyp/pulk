defmodule Pulk.Piece.PositionedPiece do
  @moduledoc """
  Entity that represents positioned piece
  """

  use TypedStruct
  use Domo

  alias Pulk.Piece
  alias Pulk.Piece.Rotation
  alias Pulk.Matrix.Coordinates

  @type direction() :: :down | :left | :right

  typedstruct enforce: true do
    field :piece, Piece.t()

    field :rotation, Rotation.t(), default: :O

    field :base_point, Coordinates.t()

    field :coordinates, [Coordinates.t()]
  end

  def has_piece_type?(%__MODULE__{piece: piece}, %Piece{} = piece_to_compare) do
    Piece.eq?(piece, piece_to_compare)
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
        %__MODULE__{} = positioned_piece,
        direction
      ) do
    shift =
      case direction do
        :down ->
          {0, 1}

        :left ->
          {-1, 0}

        :right ->
          {1, 0}
      end

    move_by(positioned_piece, shift)
  end

  @spec move_by(t(), {non_neg_integer(), non_neg_integer()}) ::
          {:ok, t()} | {:error, :invalid_move}
  def move_by(
        %__MODULE__{coordinates: coordinates, base_point: base_point} = positioned_piece,
        {shift_x, shift_y}
      )
      when is_integer(shift_x) and is_integer(shift_y) do
    apply_shift = fn {x, y} ->
      {x + shift_x, y + shift_y}
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

  @spec rotate(t(), Rotation.relative_rotation(), pos_integer()) :: {:ok, t()}
  @spec rotate(t(), Rotation.relative_rotation()) :: {:ok, t()}
  def rotate(
        %__MODULE__{rotation: rotation, piece: piece} = positioned_piece,
        relative_rotation,
        test_idx \\ 1
      ) do
    rotation_angle = Rotation.relative_rotation_angle(relative_rotation)
    next_rotation_type = Rotation.apply_relative_rotation(rotation, relative_rotation)

    with {:ok, shift_by} <-
           Rotation.get_wall_kick_shift(piece, {rotation, next_rotation_type}, test_idx),
         coordinates = rotate_coordinates(positioned_piece, rotation_angle, shift_by),
         {:ok, positioned_piece} <-
           ensure_type(%{
             positioned_piece
             | coordinates: coordinates,
               rotation: next_rotation_type
           }) do
      {:ok, positioned_piece}
    else
      {:error, _reason} -> {:error, :invalid_move}
    end
  end

  defp rotate_coordinates(
         %__MODULE__{coordinates: coordinates, base_point: base_point},
         rotation_angle,
         shift_by
       ) do
    coordinates
    |> Enum.map(&Coordinates.rotate_point(&1, rotation_angle, base_point))
    |> Coordinates.shift_coordinates_by(shift_by)
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

defimpl Jason.Encoder, for: [Pulk.Piece.PositionedPiece] do
  def encode(struct, opts) do
    Jason.Encode.map(
      struct
      |> Map.from_struct()
      |> Map.put(:coordinates, Enum.map(struct.coordinates, &Tuple.to_list(&1)))
      |> Map.put(:base_point, Tuple.to_list(struct.base_point)),
      opts
    )
  end
end
