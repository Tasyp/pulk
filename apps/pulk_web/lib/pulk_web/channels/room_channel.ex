defmodule PulkWeb.RoomChannel do
  use PulkWeb, :channel
  alias Pulk.RoomContext
  alias Pulk.PlayerContext
  alias Pulk.Game.Board

  @impl true
  def join("room:" <> room_id, _message, socket) do
    player = Pulk.Player.create()

    response =
      with {:ok, room} <- RoomContext.get_room(room_id) do
        RoomContext.add_player(room, player)
      end

    socket = assign(socket, :player_id, player.player_id)
    socket = assign(socket, :room_id, room_id)

    case response do
      {:ok, _player} -> {:ok, %{"player_id" => player.player_id}, socket}
      {:error, reason} -> {:error, %{reason: to_string(reason)}}
    end
  end

  @impl true
  def handle_in("board_update", %{"matrix" => matrix}, socket) do
    response =
      case PlayerContext.update_board_matrix(socket.assigns.player_id, matrix) do
        {:ok, board} ->
          broadcast(socket, "board_update", %{
            "matrix" => Board.to_raw_matrix(board),
            "player_id" => socket.assigns.player_id
          })

          # TODO: Handle broadcast failure properly
          :ok

        {:error, reason} ->
          {:error, %{reason: to_string(reason)}}
      end

    {:reply, response, socket}
  end
end
