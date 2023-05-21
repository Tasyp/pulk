defmodule PulkWeb.RoomChannel do
  use PulkWeb, :channel

  alias Pulk.RoomContext
  alias Pulk.PlayerContext
  alias Pulk.Game.Board
  alias Pulk.Game.BoardSnapshot

  @impl true
  def join("room:" <> room_id, %{"player_id" => player_id}, socket) do
    player =
      case PlayerContext.get_player(player_id) do
        {:ok, player} -> player
        {:error, :unknown_player} -> Pulk.Player.create(%{player_id: player_id})
      end

    response =
      with {:ok, room} <- RoomContext.get_room(room_id),
           {:ok, _player} <- RoomContext.add_player(room, player),
           {:ok, room_boards} <- RoomContext.get_room_boards(room) do
        {:ok, room_boards}
      end

    socket =
      socket
      |> assign(:player_id, player_id)
      |> assign(:room_id, room_id)

    case response do
      {:ok, room_boards} ->
        {:ok, compose_join_response(room_boards, player_id), socket}

      {:error, reason} ->
        {:error, %{reason: to_string(reason)}}
    end
  end

  @impl true
  def handle_in("board_update", board_update_json, socket) do
    response =
      with {:ok, board_update} <- PulkWeb.BoardUpdateJSON.from_json(board_update_json),
           {:ok, board} <-
             PlayerContext.update_board(socket.assigns.player_id, board_update, recalculate?: true) do
        broadcast(socket, "board_snapshot_update", %{
          "board_snapshot" => Board.to_snapshot(board),
          "player_id" => socket.assigns.player_id
        })

        {:ok, board}
      else
        {:error, reason} ->
          {:error, %{reason: to_string(reason)}}
      end

    {:reply, response, socket}
  end

  @spec compose_join_response(list({Player.t(), Board.t()}), String.t()) :: %{
          player_board: Board.t(),
          other_snapshots: BoardSnapshot.t()
        }
  defp compose_join_response(room_boards, player_id) do
    boards_by_player = Map.new(room_boards, fn {player, board} -> {player.player_id, board} end)

    {player_board, other_boards} = Map.pop!(boards_by_player, player_id)

    other_snapshots =
      other_boards
      |> Enum.map(fn {player_id, board} -> {player_id, Board.to_snapshot(board)} end)
      |> Map.new()

    %{player_board: player_board, other_snapshots: other_snapshots}
  end
end
