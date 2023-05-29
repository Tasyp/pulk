defmodule Pulk.Room.GameMode.LineGoal do
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
    room_player_boards = get_room_boards_by_cleared_line_count(room)

    room_boards =
      room_player_boards
      |> Enum.map(fn {_player, board} -> board end)

    next_room =
      if can_be_room_closed?(room_boards, line_goal) do
        {:ok, room} = Room.update_status(room, :complete)
        room
      else
        room
      end

    get_player_placements(next_room, room_player_boards)
    |> Enum.map(fn {player, placement} ->
      set_player_placement(player, placement)
    end)

    {:ok, state, next_room}
  end

  @spec can_be_room_closed?(list(Board.t()), pos_integer()) :: boolean()
  def can_be_room_closed?(room_boards, line_goal) do
    active_boards =
      room_boards
      |> Enum.filter(&(&1.status != :complete))

    maybe_winner = List.first(active_boards)

    case maybe_winner do
      # If all players have lost, then game can be completed
      nil ->
        true

      board ->
        cond do
          # If the player has reached the goal, then we can consider them as a winner
          Board.has_lines_cleared(board, line_goal) ->
            true

          # If there is only one playing board left and room is not just for one, then we can complete the game
          length(active_boards) == 1 && length(room_boards) > 1 ->
            true

          # No winner. Let's continue playing
          true ->
            false
        end
    end
  end

  @doc """
  Calculates placements for player boards.
  """
  @spec get_player_placements(Room.t(), list({Player.t(), Pulk.Game.Board.t()})) ::
          list({Player.t(), pos_integer()})
  def get_player_placements(%Room{status: :complete}, player_boards) do
    do_player_placements(player_boards, true)
  end

  def get_player_placements(%Room{}, player_boards) do
    do_player_placements(player_boards, false)
  end

  defp do_player_placements(player_boards, include_ongoing_boards) do
    matching_status? = fn board ->
      if include_ongoing_boards do
        true
      else
        board.status == :complete
      end
    end

    board_count = player_boards |> length

    already_placed_players_count =
      player_boards
      |> Enum.filter(fn {_player, board} ->
        matching_status?.(board) && board.placement != nil
      end)
      |> length

    player_boards
    |> Enum.filter(fn {_player, board} -> matching_status?.(board) && board.placement == nil end)
    |> Enum.sort_by(
      fn {_player, board} ->
        # Add status priority index to put active and completed players into different buckets.
        # This allows to give higher placing to active players.
        {get_board_status_sort_idx(board.status), board.cleared_lines_count}
      end,
      :asc
    )
    |> Enum.with_index(Enum.max([already_placed_players_count, 0]))
    |> Enum.map(fn {{player, _board}, idx} -> {player, board_count - idx} end)
  end

  defp get_board_status_sort_idx(status) do
    case status do
      :ongoing ->
        3

      :complete ->
        2

      _ ->
        1
    end
  end

  defp get_room_boards_by_cleared_line_count(room) do
    {:ok, room_boards} = RoomContext.get_room_boards(room)

    room_boards
    |> Enum.sort_by(fn {_player, board} -> board.cleared_lines_count end, :desc)
  end

  defp set_player_placement(player, placement) do
    PlayerManager.set_placement(PlayerManager.via_tuple(player.player_id), placement)
  end
end
