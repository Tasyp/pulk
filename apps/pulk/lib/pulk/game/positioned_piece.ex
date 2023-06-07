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

  @spec move(t(), direction()) :: {:ok, t()} | {:error, :invalid_move}
  def move(%__MODULE__{coordinates: coordinates} = positioned_piece, direction) do
    updated_coordinates =
      case direction do
        :down ->
          coordinates
          |> Enum.map(fn {x, y} -> {x, Enum.max(y - 1, 0)} end)

        :left ->
          coordinates
          |> Enum.map(fn {x, y} -> {Enum.max(x - 1, 0), y} end)

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
end
