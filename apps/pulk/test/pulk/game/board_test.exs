defmodule Pulk.Game.BoardTest do
  use ExUnit.Case

  alias Pulk.Piece
  alias Pulk.Board
  alias Pulk.Matrix
  alias Pulk.Board.BoardUpdate
  alias Pulk.Piece.PieceUpdate
  alias Pulk.Piece.PositionedPiece

  describe "Board.update/2" do
    test "it rejects updates that rotate active piece to an already occupied coordinates" do
      input_matrix =
        m([
          [" ", " ", " ", " ", " "],
          [" ", " ", " ", " ", " "],
          [" ", " ", " ", " ", " "],
          [" ", "T", " ", " ", " "],
          ["T", "T", "T", " ", " "]
        ])

      # With active piece
      # m([
      #   [" ", " ", " ", " ", " "],
      #   [" ", " ", "S", "S", " "],
      #   [" ", "S", "S", " ", " "],
      #   [" ", "T", " ", " ", " "],
      #   ["T", "T", "T", " ", " "],
      # ])

      {:ok, input_board} =
        Board.new(
          5,
          5,
          %{
            matrix: input_matrix,
            active_piece:
              PositionedPiece.new!(
                piece: Piece.new!("S"),
                coordinates: [
                  {1, 1},
                  {2, 1},
                  {0, 2},
                  {1, 2}
                ],
                base_point: {1, 2}
              )
          }
        )

      # Expected result
      # m([
      #   [" ", " ", " ", " ", " "],
      #   ["S", " ", " ", " ", " "],
      #   ["S", "S", " ", " ", " "],
      #   [" ", "S", " ", " ", " "],
      #   ["T", "T", "T", " ", " "],
      # ])
      update_result =
        Board.update(
          input_board,
          BoardUpdate.new!(
            active_piece_update:
              PieceUpdate.new!(
                piece: Piece.new!("S"),
                update_type: :simple,
                relative_rotation: :left
              )
          )
        )

      assert update_result == {:error, :invalid_move}
    end
  end

  defp m(pieces) do
    pieces
    |> Enum.map(fn row ->
      row
      |> Enum.map(&Piece.new!(String.trim(&1)))
    end)
    |> Matrix.new!()
  end
end
