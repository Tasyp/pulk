defmodule Pulk.Game.Coordinates do
  @moduledoc """
  Collection of helper methods to operate on coordinates
  """

  @type t() :: {x :: integer(), y :: integer()}
  @type collection() :: [t()]

  @spec to_set(collection()) :: MapSet.t(t())
  def to_set(coordinates) do
    coordinates
    |> MapSet.new()
  end

  @spec get_coordinates_width(collection()) :: non_neg_integer()
  def get_coordinates_width(coordinates) do
    x_coordinates =
      coordinates
      |> Enum.map(fn {x, _y} -> x end)

    min_x = Enum.min(x_coordinates)
    max_x = Enum.max(x_coordinates)

    max_x - min_x + 1
  end

  @spec shift_point_by(t(), shift_by :: {integer(), integer()}) :: t()
  def shift_point_by({x, y}, {shift_x, shift_y}) do
    {x + shift_x, y + shift_y}
  end

  @spec shift_coordinates_by(list(t()), shift_by :: {integer(), integer()}) :: collection()
  def shift_coordinates_by(coordinates, shift_by) do
    coordinates
    |> Enum.map(&shift_point_by(&1, shift_by))
  end

  @spec rotate_point(
          point_to_rotate :: t(),
          angle :: integer(),
          center_point :: t()
        ) :: t()
  def rotate_point({px, py}, angle, {cx, cy}) do
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
