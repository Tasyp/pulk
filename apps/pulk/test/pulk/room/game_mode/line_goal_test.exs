defmodule Pulk.Room.GameMode.LineGoalTest do
  use ExUnit.Case, async: true

  alias Pulk.Room.GameMode.LineGoal
  alias Pulk.Board
  alias Pulk.Room
  alias Pulk.Player

  @line_count_goal 5

  describe "LineGoal.can_be_room_closed?/2" do
    test "is true when there is a winner game" do
      board_a = get_board(%{status: :ongoing, cleared_lines_count: @line_count_goal})
      board_b = get_board(%{status: :ongoing})
      board_c = get_board(%{status: :ongoing})

      assert LineGoal.can_be_room_closed?([board_a, board_b, board_c], @line_count_goal) == true
    end

    test "is true if there is only one player left" do
      board_a = get_board(%{status: :complete})
      board_b = get_board(%{status: :complete})
      board_c = get_board(%{status: :ongoing})

      assert LineGoal.can_be_room_closed?([board_a, board_b, board_c], @line_count_goal) == true
    end

    test "is true if all players have lost" do
      board_a = get_board(%{status: :complete})
      board_b = get_board(%{status: :complete})
      board_c = get_board(%{status: :complete})

      assert LineGoal.can_be_room_closed?([board_a, board_b, board_c], @line_count_goal) == true
    end

    test "is false if there is only one player left but there was never more players" do
      board_a = get_board(%{status: :ongoing})

      assert LineGoal.can_be_room_closed?([board_a], @line_count_goal) == false
    end

    test "is false if there is no winner" do
      board_a = get_board(%{status: :ongoing, cleared_lines_count: 3})
      board_b = get_board(%{status: :ongoing})
      board_c = get_board(%{status: :complete})

      assert LineGoal.can_be_room_closed?([board_a, board_b, board_c], @line_count_goal) == false
    end
  end

  describe "LineGoal.get_player_placements/2" do
    setup context do
      room = Room.new!(%{status: Map.get(context, :room_status, :playing)})
      %{room: room}
    end

    @tag room_status: :complete
    test "places all players if room is complete", %{room: room} do
      player_board_a = get_player_board(room.room_id, %{status: :ongoing, cleared_lines_count: 3})
      player_board_b = get_player_board(room.room_id, %{status: :ongoing, cleared_lines_count: 2})
      player_board_c = get_player_board(room.room_id, %{status: :ongoing, cleared_lines_count: 4})

      assert LineGoal.get_player_placements(room, [player_board_c, player_board_a, player_board_b]) ==
               [
                 {get_player(player_board_b), 3},
                 {get_player(player_board_a), 2},
                 {get_player(player_board_c), 1}
               ]
    end

    @tag room_status: :complete
    test "places last playing player on the first place in a complete room", %{room: room} do
      player_board_a = get_player_board(room.room_id, %{status: :ongoing, cleared_lines_count: 1})

      player_board_b =
        get_player_board(room.room_id, %{status: :complete, placement: 2, cleared_lines_count: 2})

      player_board_c =
        get_player_board(room.room_id, %{status: :complete, placement: 3, cleared_lines_count: 4})

      assert LineGoal.get_player_placements(room, [player_board_c, player_board_a, player_board_b]) ==
               [
                 {get_player(player_board_a), 1}
               ]
    end

    @tag room_status: :complete
    test "prioritizes playing players in a complete room", %{room: room} do
      player_board_a = get_player_board(room.room_id, %{status: :ongoing, cleared_lines_count: 1})

      player_board_b =
        get_player_board(room.room_id, %{status: :complete, cleared_lines_count: 2})

      player_board_c =
        get_player_board(room.room_id, %{status: :complete, cleared_lines_count: 4})

      player_board_d = get_player_board(room.room_id, %{status: :ongoing, cleared_lines_count: 3})

      assert LineGoal.get_player_placements(room, [
               player_board_c,
               player_board_a,
               player_board_b,
               player_board_d
             ]) ==
               [
                 {get_player(player_board_b), 4},
                 {get_player(player_board_c), 3},
                 {get_player(player_board_a), 2},
                 {get_player(player_board_d), 1}
               ]
    end

    @tag room_status: :playing
    test "does not affect already placed players", %{room: room} do
      player_board_a =
        get_player_board(room.room_id, %{status: :complete, placement: 3, cleared_lines_count: 4})

      player_board_b =
        get_player_board(room.room_id, %{status: :complete, cleared_lines_count: 3})

      player_board_c = get_player_board(room.room_id, %{status: :complete})

      assert LineGoal.get_player_placements(room, [player_board_a, player_board_b, player_board_c]) ==
               [
                 {get_player(player_board_c), 2},
                 {get_player(player_board_b), 1}
               ]
    end

    @tag room_status: :playing
    test "ignores playing players", %{room: room} do
      player_board_a =
        get_player_board(room.room_id, %{status: :complete, cleared_lines_count: 4})

      player_board_b = get_player_board(room.room_id, %{status: :ongoing, cleared_lines_count: 3})
      player_board_c = get_player_board(room.room_id, %{status: :ongoing})

      assert LineGoal.get_player_placements(room, [player_board_a, player_board_b, player_board_c]) ==
               [
                 {get_player(player_board_a), 3}
               ]
    end
  end

  defp get_player({player, _board}) do
    player
  end

  defp get_player_board(room_id, attrs, size_x \\ 10, size_y \\ 10) do
    player = Player.new!(%{room_id: room_id})
    {player, get_board(attrs, size_x, size_y)}
  end

  defp get_board(attrs, size_x \\ 10, size_y \\ 10) do
    {:ok, board} = Board.new(size_x, size_y, attrs)
    board
  end
end
