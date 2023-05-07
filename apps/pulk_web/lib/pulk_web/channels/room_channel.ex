defmodule PulkWeb.RoomChannel do
  use PulkWeb, :channel
  alias Pulk.RoomContext
  alias Pulk.Game.Board

  @impl true
  def join("room:" <> room_id, _message, socket) do
    player = Pulk.Player.create()

    response =
      with {:ok, room} = RoomContext.get_room(room_id) do
        RoomContext.add_player(room, player)
      end

    assign(socket, :player_id, player.player_id)
    assign(socket, :room_id, room_id)

    case response do
      :ok -> {:ok, socket}
      {:error, reason} -> {:error, %{reason: to_string(reason)}}
    end
  end

  @impl true
  def handle_in("board_update", %{"matrix" => matrix}, socket) do
    if Board.is_matrix_parsable?(matrix) do
      broadcast(socket, "board_update", %{
        "matrix" => matrix,
        "player_id" => socket.assigns.player_id
      })
    end

    {:noreply, socket}
  end
end
