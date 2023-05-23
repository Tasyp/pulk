defmodule PulkWeb.PlayerController do
  use PulkWeb, :controller

  alias Pulk.Player

  def index(conn, _params) do
    player = Player.new!()

    render(conn, :index, player: player)
  end
end
