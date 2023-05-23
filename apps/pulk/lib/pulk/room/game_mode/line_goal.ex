defmodule Pulk.Room.GameMode.LineGoal do
  use TypedStruct

  alias Pulk.Room.GameMode
  alias Pulk.Room
  alias Pulk.RoomContext
  alias Pulk.Game.Board

  @behaviour GameMode.Behaviour

  typedstruct do
    field :line_goal, pos_integer(), default: 40
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
    {:ok, room_boards} = RoomContext.get_room_boards(room)

    winner =
      room_boards
      |> Enum.find(fn {_player, board} -> Board.has_lines_cleared(board, line_goal) end)

    next_room =
      case winner do
        {_player, _board} ->
          {:ok, room} = Room.update_status(room, :complete)
          room

        _ ->
          room
      end

    {:ok, next_room, state}
  end
end
