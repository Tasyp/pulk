defmodule PulkWeb.RoomController do
  use PulkWeb, :controller

  def index(conn, _params) do
    {:ok, room} =
      conn
      |> get_conn_player_id()
      |> Pulk.get_player()
      |> Pulk.fetch_player_room()

    render(conn, :index, room: room)
  end

  defp get_conn_player_id(conn), do: Map.get(conn.query_params, "player_id")
end
