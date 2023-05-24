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

    maybe_winner = List.first(room_boards)

    next_room =
      case maybe_winner do
        {_player, board} ->
          if Board.has_lines_cleared(board, line_goal) do
            {:ok, room} = Room.update_status(room, :complete)

            set_player_placement(room_boards)

            room
          else
            room
          end

        _ ->
          room
      end

    {:ok, state, next_room}
  end

  defp get_room_boards_by_cleared_line_count(room) do
    {:ok, room_boards} = RoomContext.get_room_boards(room)

    room_boards
    |> Enum.sort_by(fn {_player, board} -> board.cleared_lines_count end, :desc)
  end

  defp set_player_placement(player_boards) do
    player_boards
    |> Enum.with_index(1)
    |> Enum.each(fn {{player, _board}, idx} ->
      PlayerManager.set_placement(PlayerManager.via_tuple(player.player_id), idx)
    end)
  end
end
