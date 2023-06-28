defmodule Pulk do
  alias Pulk.Board.BoardSnapshot
  alias Pulk.RoomContext
  alias Pulk.PlayerContext
  alias Pulk.Player
  alias Pulk.Board.BoardUpdate
  alias Pulk.Board
  alias Pulk.BoardSnapshot

  @spec fetch_player(player_id :: String.t()) :: {:ok, Player.t()} | {:error, :unknown_player}
  def fetch_player(player_id) when is_bitstring(player_id) do
    PlayerContext.get_player(player_id)
  end

  def fetch_player(_), do: {:error, :unknown_player}

  @spec get_player(String.t() | nil) :: Player.t() | nil
  def get_player(player_id \\ nil)

  def get_player(player_id) when is_bitstring(player_id) do
    case PlayerContext.get_player(player_id) do
      {:ok, player} -> player
      _ -> nil
    end
  end

  def get_player(nil), do: Player.new!()

  @spec fetch_player_room(player :: Player.t() | nil) :: {:ok, Room.t()} | {:error, term()}
  def fetch_player_room(player \\ nil)

  def fetch_player_room(%Player{room_id: room_id}) when is_bitstring(room_id) do
    RoomContext.get_room(room_id)
  end

  def fetch_player_room(_) do
    RoomContext.get_available_room()
  end

  @spec fetch_room(room_id :: String.t()) :: {:error, :unknown_room} | {:ok, Room.t()}
  def fetch_room(room_id) when is_bitstring(room_id) do
    RoomContext.get_room(room_id)
  end

  def fetch_room(_), do: {:error, :unknown_room}

  @spec join_room(player_id :: String.t(), room_id :: String.t()) ::
          {:ok, list({Player.t(), Board.t()})} | {:error, term()}
  def join_room(player_id, room_id) do
    with {:ok, player} <- PlayerContext.fetch_player_and_create_if_needed(player_id),
         {:ok, room} <- fetch_room(room_id),
         {:ok, _assigned_player} <- RoomContext.add_player(room, player),
         {:ok, room_boards} <- RoomContext.get_room_boards(room) do
      {:ok, room_boards}
    end
  end

  @spec update_board(player_id :: String.t(), board_update :: BoardUpdate.t()) ::
          {:ok, Board.t()} | {:error, term()}
  def update_board(player_id, %BoardUpdate{} = board_update) when is_bitstring(player_id) do
    PlayerContext.update_board(player_id, board_update)
  end

  def update_board(_player_id, %BoardUpdate{} = _board_update), do: {:error, :unknown_player}
  def update_board(_player_id, _board_update), do: {:error, :invalid_update}

  @spec subscribe_to_board_updates(player_id :: String.t()) :: :ok | {:error, term()}
  def subscribe_to_board_updates(player_id) do
    PlayerContext.subscribe_to_board_updates(player_id)
  end

  @spec compose_board_snapshot(Board.t()) :: BoardSnapshot.t()
  def compose_board_snapshot(%Board{} = board) do
    Board.to_snapshot(board)
  end
end
