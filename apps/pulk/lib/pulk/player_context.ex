defmodule Pulk.PlayerContext do
  alias Pulk.Player.PlayerManager

  @spec get_player(String.t()) :: {:error, :not_found} | {:ok, Pulk.Player.t()}
  def get_player(player_id) do
    if PlayerManager.is_player_present?(player_id) do
      PlayerManager.get_player(PlayerManager.via_tuple(player_id))
    else
      :error
    end
  end
end
