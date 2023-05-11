defmodule PulkWeb.RoomChannel do
  use PulkWeb, :channel
  alias Pulk.RoomContext
  alias Pulk.PlayerContext
  alias Pulk.Game.Board

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
           {:ok, room_boards} <- RoomContext.get_room_boards(room_id) do
        {:ok, room_boards}
      end

    socket =
      socket
      |> assign(:player_id, player_id)
      |> assign(:room_id, room_id)

    case response do
      {:ok, room_boards} ->
        {
          :ok,
          %{
            "player_id" => player_id,
            "boards" =>
              room_boards
              |> Map.new(fn {%Pulk.Player{} = player, %Pulk.Game.Board{} = board} ->
                {player.player_id, Board.to_raw_matrix(board)}
              end)
          },
          socket
        }

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
