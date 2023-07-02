defmodule Pulk.Piece.Rotation do
  @moduledoc """
  Collection of helper methods for rotating pieces
  """

  # Source: https://harddrop.com/wiki/SRS
  # 0 = spawn state
  # R = state resulting from a clockwise rotation ("right") from spawn
  # L = state resulting from a counter-clockwise ("left") rotation from spawn
  # 2 = state resulting from 2 successive rotations in either direction from spawn.
  @type t() :: :O | :R | :L | :two
  @type relative_rotation() :: :left | :right

  @rotations [
    :O,
    :R,
    :L,
    :two
  ]
  @rotation_in_degrees 90

  @spec apply_relative_rotation(t(), relative_rotation()) :: t()
  def apply_relative_rotation(rotation, relative_rotation) do
    current_rotation_idx =
      @rotations
      |> Enum.find_index(&(&1 == rotation))

    next_rotation_idx =
      (current_rotation_idx + relative_rotation_to_offset(relative_rotation))
      |> rem(length(@rotations))

    Enum.fetch!(@rotations, next_rotation_idx)
  end

  @spec relative_rotation_angle(relative_rotation()) :: integer()
  def relative_rotation_angle(relative_rotation) do
    offset = relative_rotation_to_offset(relative_rotation)
    @rotation_in_degrees * offset
  end

  @spec relative_rotation_to_offset(relative_rotation()) :: integer()
  def relative_rotation_to_offset(relative_rotation) do
    case relative_rotation do
      :left -> -1
      :right -> 1
    end
  end
end
