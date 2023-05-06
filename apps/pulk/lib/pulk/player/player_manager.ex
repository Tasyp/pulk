defmodule Pulk.Player.PlayerManager do
  use GenServer

  alias Pulk.Game.Board

  def start_link(init_args) do
    player = Keyword.fetch!(init_args, :player)
    room = Keyword.fetch!(init_args, :room)

    GenServer.start_link(
      __MODULE__,
      %{player: player, room: room},
      name: via_tuple(player.player_id)
    )
  end

  @spec is_player_present?(String.t()) :: :ok | {:error, :unknown_player}
  def is_player_present?(player_id) do
    case Pulk.Registry.lookup({__MODULE__, player_id}) do
      [] -> {:error, :unknown_player}
      _ -> :ok
    end
  end

  def get_player(pid) do
    GenServer.call(pid, :get_player)
  end

  def get_board(pid) do
    GenServer.call(pid, :get_board)
  end

  def update_raw_matrix(pid, raw_matrix) do
    GenServer.call(pid, {:update_raw_matrix, raw_matrix})
  end

  @impl true
  def init(%{room: %Pulk.Room{} = room, player: %Pulk.Player{} = player}) do
    board = Board.create(room.board_size)
    {:ok, %{player: player, board: board}}
  end

  @impl true
  def handle_call(:get_player, _from, %{player: player} = state) do
    {:reply, {:ok, player}, state}
  end

  @impl true
  def handle_call(:get_board, _from, %{board: board} = state) do
    {:reply, {:ok, board}, state}
  end

  @impl true
  def handle_call({:update_raw_matrix, raw_matrix}, _from, %{board: board} = state) do
    {response, state} =
      case Board.update_from_raw_matrix(board, raw_matrix) do
        {:ok, board} -> {{:ok, board}, %{state | board: board}}
        error -> {error, state}
      end

    {:reply, response, state}
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
