defmodule Pulk.Player.PlayerManager do
  use GenServer

  def start_link(init_args) do
    player = Keyword.fetch!(init_args, :player)

    GenServer.start_link(
      __MODULE__,
      %{player: player},
      name: via_tuple(player.player_id)
    )
  end

  @spec is_player_present?(String.t()) :: boolean()
  def is_player_present?(player_id) do
    case Pulk.Registry.lookup({__MODULE__, player_id}) do
      [] -> false
      _ -> true
    end
  end

  def get_player(pid) do
    GenServer.call(pid, :get_player)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:get_player, _from, %{player: player} = state) do
    {:reply, player, state}
  end

  def lookup(player_id) do
    case Pulk.Registry.lookup({__MODULE__, player_id}) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end

  def via_tuple(player_id) do
    Pulk.Registry.via_tuple({__MODULE__, player_id})
  end
end
