defmodule Pulk.Piece.Rotation do
  alias Pulk.Piece

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
    :L,
    :O,
    :R,
    :two
  ]
  @rotation_in_degrees 90

  @non_i_wall_kick %{
    {:O, :R} => {{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
    {:R, :O} => {{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
    {:R, :two} => {{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}},
    {:two, :R} => {{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}},
    {:two, :L} => {{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}},
    {:L, :two} => {{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}},
    {:L, :O} => {{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}},
    {:O, :L} => {{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}}
  }

  @i_wall_kick %{
    {:O, :R} => {{0, 0}, {-2, 0}, {1, 0}, {-2, -1}, {1, 2}},
    {:R, :O} => {{0, 0}, {2, 0}, {-1, 0}, {2, 1}, {-1, -2}},
    {:R, :two} => {{0, 0}, {-1, 0}, {2, 0}, {-1, 2}, {2, -1}},
    {:two, :R} => {{0, 0}, {1, 0}, {-2, 0}, {1, -2}, {-2, 1}},
    {:two, :L} => {{0, 0}, {2, 0}, {-1, 0}, {2, 1}, {-1, -2}},
    {:L, :two} => {{0, 0}, {-2, 0}, {1, 0}, {-2, -1}, {1, 2}},
    {:L, :O} => {{0, 0}, {1, 0}, {-2, 0}, {1, -2}, {-2, 1}},
    {:O, :L} => {{0, 0}, {-1, 0}, {2, 0}, {-1, 2}, {2, -1}}
  }

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

  @spec get_wall_kick_shift(Piece.t(), {t(), t()}, pos_integer()) :: {integer(), integer()}
  def get_wall_kick_shift(%Piece{piece_type: piece}, {base_rotation, next_rotation}, test_idx)
      when piece == "I" and
             is_map_key(@i_wall_kick, {base_rotation, next_rotation}) and
             test_idx > 0 and test_idx < 6 do
    shift_by =
      @i_wall_kick[{base_rotation, next_rotation}]
      |> elem(test_idx - 1)

    {:ok, shift_by}
  end

  def get_wall_kick_shift(%Piece{piece_type: piece}, {base_rotation, next_rotation}, test_idx)
      when piece != "I" and
             is_map_key(@non_i_wall_kick, {base_rotation, next_rotation}) and
             test_idx > 0 and test_idx < 6 do
    shift_by =
      @non_i_wall_kick[{base_rotation, next_rotation}]
      |> elem(test_idx - 1)

    {:ok, shift_by}
  end

  def get_wall_kick_shift(_piece, _rotation, _test_idx), do: {:error, :invalid_rotation}
end
