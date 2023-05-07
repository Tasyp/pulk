defmodule PulkWeb.RoomController do
  use PulkWeb, :controller

  alias Pulk.RoomContext
  alias Pulk.Room

  def index(conn, _params) do
    room =
      case RoomContext.get_available_room() do
        {:ok, room} ->
          room

        {:error, :all_rooms_busy} ->
          {:ok, room} = RoomContext.create_room(Room.create())
          room
      end

    render(conn, :index, room: room)
  end
end
