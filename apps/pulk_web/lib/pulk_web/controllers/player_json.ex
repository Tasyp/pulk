defmodule PulkWeb.PlayerJSON do
  alias Pulk.Player

  def index(%{player: %Player{} = player}) do
    %{data: %{"player_id" => player.player_id}}
  end
end
