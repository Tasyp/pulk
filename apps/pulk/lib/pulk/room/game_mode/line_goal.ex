defmodule Pulk.Room.GameMode.LineGoal do
  require Logger

  use TypedStruct

  alias Pulk.Room.GameMode
  alias Pulk.Room
  alias Pulk.RoomContext
  alias Pulk.Game.Board
  alias Pulk.Player.PlayerManager

  @behaviour GameMode.Behaviour

  typedstruct do
    field(:line_goal, pos_integer(), default: 40)
  end

  @impl true
  def init(%{line_goal: line_goal}) do
    {:ok, %__MODULE__{line_goal: line_goal}}
  end

  @impl true
  def handle_room_update(
        %__MODULE__{line_goal: line_goal} = state,
        %Pulk.Room{} = room
      ) do
    room_boards = get_room_boards_by_cleared_line_count(room)

    maybe_winner = get_winner(room_boards, line_goal)

    next_room =
      case maybe_winner do
        {:ok, _player_board} ->
          {:ok, room} = Room.update_status(room, :complete)
          room

        :error ->
          room
      end

    # Makes sure all players got placings
    set_player_placements(next_room, room_boards)

    {:ok, state, next_room}
  end

  defp get_room_boards_by_cleared_line_count(room) do
    {:ok, room_boards} = RoomContext.get_room_boards(room)

    room_boards
    |> Enum.sort_by(fn {_player, board} -> board.cleared_lines_count end, :desc)
  end

  defp get_winner(room_boards, line_goal) do
    active_boards =
      room_boards
      |> Enum.filter(fn {_player, board} -> board.status != :complete end)

    maybe_winner = List.first(active_boards)

    case maybe_winner do
      {player, board} ->
        cond do
          # 1. Check if the player has reached the goal, then we can consider them as a winner
          Board.has_lines_cleared(board, line_goal) ->
            {:ok, {player, board}}

          # 2. Check if there is only one playing board left and room is not just for one, then we can complete the game
          length(active_boards) == 1 && length(room_boards) > 1 ->
            set_player_placement(player, 1)

            {:ok, {player, board}}

          # 3. No winner. Let's continue playing
          true ->
            :error
        end

      # There are no active players in the room. Race condition?
      _ ->
        Logger.warning("Tried to find a winner in a room with no active players")
        :error
    end
  end

  defp set_player_placement(player, placement) do
    PlayerManager.set_placement(PlayerManager.via_tuple(player.player_id), placement)
  end

  defp set_player_placements(%Room{status: :complete}, player_boards) do
    player_boards
    |> Enum.with_index(1)
    |> Enum.each(fn {{player, _board}, idx} -> set_player_placement(player, idx) end)
  end

  defp set_player_placements(%Room{}, player_boards) do
    board_count = player_boards |> length

    already_placed_players_count =
      player_boards
      |> Enum.filter(fn {_player, board} ->
        board.status == :complete && board.placement == nil
      end)
      |> length

    player_boards
    |> Enum.filter(fn {_player, board} -> board.status == :complete end)
    |> Enum.sort_by(fn {_player, board} -> board.cleared_lines_count end, :asc)
    |> Enum.with_index(Enum.max([already_placed_players_count - 1, 0]))
    |> Enum.each(fn {{player, _board}, idx} -> set_player_placement(player, board_count - idx) end)
  end
end
