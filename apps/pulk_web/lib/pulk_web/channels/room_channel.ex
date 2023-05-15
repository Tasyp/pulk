defmodule PulkWeb.RoomChannel do
  use PulkWeb, :channel
  alias Pulk.RoomContext
  alias Pulk.PlayerContext

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
        boards_by_player =
          Map.new(room_boards, fn {player, board} -> {player.player_id, board} end)

        {:ok, %{"boards" => boards_by_player}, socket}

      {:error, reason} ->
        {:error, %{reason: to_string(reason)}}
    end
  end

  @impl true
  def handle_in("board_update", %{"matrix" => matrix}, socket) do
    response =
      case PlayerContext.update_board_matrix(socket.assigns.player_id, matrix) do
        {:ok, board} ->
          broadcast(socket, "board_update", %{
            "board" => board,
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
