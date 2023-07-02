defmodule PulkWeb.PlayerController do
  use PulkWeb, :controller

  def index(conn, _params) do
    player = Pulk.get_player()

    render(conn, :index, player: player)
  end
end
