defmodule PulkWeb.RoomChannel do
  @moduledoc """
  Channel used to communicate with frontend about game room changes
  """
  require Logger

  use PulkWeb, :channel

  @impl true
  def join("room:" <> room_id, %{"player_id" => player_id}, socket) do
    case Pulk.join_room(player_id, room_id) do
      {:ok, room_boards} ->
        socket =
          socket
          |> assign(:player_id, player_id)
          |> assign(:room_id, room_id)

        :ok = Pulk.subscribe_to_board_updates(player_id)

        {:ok, compose_join_response(room_boards, player_id), socket}

      {:error, reason} ->
        {:error, %{reason: to_string(reason)}}
    end
  end

  @impl true
  def handle_in("board_update", board_update_json, socket) do
    player_id = socket_player_id(socket)
    board_update = PulkWeb.BoardUpdateJSON.from_json(board_update_json)

    response =
      with {:ok, board} <- Pulk.update_board(player_id, board_update) do
        {:ok, board}
      else
        {:error, reason} ->
          {:error, %{reason: to_string(reason)}}
      end

    {:reply, response, socket}
  end

  @impl true
  def handle_info({:internal_board_update, board}, socket) do
    send_board_to_others(socket, board)
    push(socket, "board_update", board)
    {:noreply, socket}
  end

  defp socket_player_id(socket), do: socket.assigns.player_id

  defp send_board_to_others(socket, board) do
    broadcast_from(socket, "board_snapshot_update", %{
      "board_snapshot" => Pulk.compose_board_snapshot(board),
      "player_id" => socket_player_id(socket)
    })
  end

  defp compose_join_response(room_boards, player_id)
       when is_list(room_boards) and is_bitstring(player_id) do
    {player_board, other_boards} =
      room_boards
      |> group_boards_by_player_id
      |> separate_other_player_boards(player_id)

    other_snapshots =
      other_boards
      |> Map.new(&compose_player_board_snapshot/1)

    %{player_board: player_board, other_snapshots: other_snapshots}
  end

  defp group_boards_by_player_id(room_boards),
    do: Map.new(room_boards, fn {player, board} -> {player.player_id, board} end)

  defp separate_other_player_boards(grouped_room_boards, current_player_id)
       when is_map(grouped_room_boards),
       do: Map.pop!(grouped_room_boards, current_player_id)

  defp compose_player_board_snapshot({player, board}),
    do: {player, Pulk.compose_board_snapshot(board)}
end
