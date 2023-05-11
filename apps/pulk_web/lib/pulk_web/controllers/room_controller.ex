defmodule PulkWeb.RoomController do
  use PulkWeb, :controller

  alias Pulk.RoomContext
  alias Pulk.PlayerContext
  alias Pulk.Room

  def index(conn, _params) do
    player =
      case Map.get(conn.query_params, "player_id") do
        nil ->
          nil

        player_id ->
          case PlayerContext.get_player(player_id) do
            {:error, _reason} -> nil
            {:ok, player} -> {:ok, player}
          end
      end

    {:ok, %Room{} = room} =
      case player do
        nil ->
          case RoomContext.get_available_room() do
            {:ok, room} ->
              {:ok, room}

            {:error, :all_rooms_busy} ->
              RoomContext.create_room(Room.create())
          end

        {:ok, player} ->
          RoomContext.get_room(player.room_id)
      end

    render(conn, :index, room: room)
  end
end
