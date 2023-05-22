defmodule Pulk.Game.MatrixTest do
  use ExUnit.Case

  alias Pulk.Game.Matrix
  alias Pulk.Game.Piece

  describe "Matrix.remove_filled_lines/1" do
    test "it should remove filled lines and shift existing ones when only the top is incomplete" do
      matrix =
        Matrix.new!([
          [p("O"), p("O"), p()],
          [p("O"), p("T"), p("T")],
          [p("T"), p("T"), p("T")]
        ])

      expected_matrix =
        Matrix.new!([
          [p(), p(), p()],
          [p(), p(), p()],
          [p("O"), p("O"), p()]
        ])

      {matrix, cleared_lines_count} = Matrix.remove_filled_lines(matrix)

      assert matrix == expected_matrix
      assert cleared_lines_count == 2
    end

    test "it should remove filled lines when all are filled" do
      matrix =
        Matrix.new!([
          [p("O"), p("O"), p("O")],
          [p("O"), p("T"), p("T")],
          [p("T"), p("T"), p("T")]
        ])

      expected_matrix =
        Matrix.new!([
          [p(), p(), p()],
          [p(), p(), p()],
          [p(), p(), p()]
        ])

      {matrix, cleared_lines_count} = Matrix.remove_filled_lines(matrix)

      assert matrix == expected_matrix
      assert cleared_lines_count == 3
    end

    test "it should remove filled lines when filled line is in the middle" do
      matrix =
        Matrix.new!([
          [p(), p(), p()],
          [p("O"), p(""), p("T")],
          [p("O"), p("T"), p("T")],
          [p("T"), p(), p("O")],
          [p(), p(), p()]
        ])

      expected_matrix =
        Matrix.new!([
          [p(), p(), p()],
          [p(), p(), p()],
          [p("O"), p(), p("T")],
          [p("T"), p(), p("O")],
          [p(), p(), p()]
        ])

      {matrix, cleared_lines_count} = Matrix.remove_filled_lines(matrix)

      assert matrix == expected_matrix
      assert cleared_lines_count == 1
    end
  end

  defp p(piece \\ "") do
    Piece.new!(piece)
  end
end
