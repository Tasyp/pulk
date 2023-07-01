defmodule Pulk do
  @moduledoc """
  A core logic module for Pulk.

  Exposes functionality needed to operate a game.
  """
  require Logger

  alias Pulk.Room.RoomManager
  alias Pulk.Player
  alias Pulk.Player.PlayerManager
  alias Pulk.Board
  alias Pulk.Board.BoardUpdate
  alias Pulk.Board.BoardSnapshot
  alias Pulk.Board.BoardSubscription
  alias Pulk.Piece
  alias Pulk.Piece.PieceUpdate

  @doc """
  Returns `Pulk.Player` by an id.
  """
  @spec fetch_player(player_id :: String.t()) :: {:ok, Player.t()} | {:error, term()}
  def fetch_player(player_id) when is_bitstring(player_id) do
    PlayerManager.fetch_player(player_id)
  end

  def fetch_player(_), do: {:error, :unknown_player}

  @doc """
  Returns `Pulk.Player` by an id.

  In case the player doesn't exist, returns `nil`. When `nil` is explicitly passed as an argument, it returns a new
  `Pulk.Player` entity for better composability.
  """
  @spec get_player(String.t() | nil) :: Player.t() | nil
  def get_player(player_id \\ nil)

  def get_player(player_id) when is_bitstring(player_id) do
    case PlayerManager.fetch_player(player_id) do
      {:ok, player} -> player
      _ -> nil
    end
  end

  def get_player(nil), do: Player.new!()

  @doc """
  Returns either a room player is assigned to or any available room with the least amount of players.

  In case `player` is `nil`, it still returns the available room.
  """
  @spec fetch_player_room(player :: Player.t() | nil) :: {:ok, Room.t()} | {:error, term()}
  def fetch_player_room(player \\ nil)

  def fetch_player_room(%Player{room_id: room_id}) when is_bitstring(room_id) do
    RoomManager.fetch_room(room_id)
  end

  def fetch_player_room(_) do
    RoomManager.fetch_available_room()
  end

  @doc """
  Returns `Pulk.Room` by an id.
  """
  @spec fetch_room(room_id :: String.t()) :: {:ok, Room.t()} | {:error, term()}
  def fetch_room(room_id) when is_bitstring(room_id) do
    RoomManager.fetch_room(room_id)
  end

  def fetch_room(_), do: {:error, :unknown_room}

  @doc """
  Joins given game room and returns all game boards (including the just joined player)

  If a player is already a part of a given game room, the function call will still succeed and return the respective
  game boards.

  In case given player doesn't exist, it will be created.
  """
  @spec join_room(player_id :: String.t(), room_id :: String.t()) ::
          {:ok, list({Player.t(), Board.t()})} | {:error, term()}
  def join_room(player_id, room_id) do
    with {:ok, player} <- PlayerManager.fetch_player_and_create_if_needed(player_id),
         {:ok, room} <- RoomManager.fetch_room(room_id),
         {:ok, _assigned_player} <- RoomManager.add_player(room, player) do
      RoomManager.fetch_room_boards(room)
    end
  end

  @doc """
  Updates player board in a current game.

  There are two ways to use it.
  1. You can either pass the already constructed `Pulk.Board.BoardUpdate` and it will be used as-is.
  2. Or you could use the shorthand version that allows you to pass a regular map.

  ## Examples

      iex> Pulk.update_board("my-player-id", %{piece: "J", update_type: :simple, direction: :down})
      {:ok, %Pulk.Board{}}

      iex> Pulk.update_board("my-player-id", %{piece: "J", update_type: :hold})
      {:ok, %Pulk.Board{}}
  """
  @spec update_board(player_id :: String.t(), BoardUpdate.t() | map()) ::
          :ok | {:error, term()}
  def update_board(player_id, %BoardUpdate{} = board_update) when is_bitstring(player_id) do
    PlayerManager.update_board(player_id, board_update)
  end

  def update_board(
        player_id,
        %{
          piece: piece,
          update_type: update_type
        } = input
      )
      when is_bitstring(player_id) do
    with {:ok, piece} <- Piece.new(piece),
         {:ok, piece_update} <-
           PieceUpdate.new(
             piece: piece,
             update_type: update_type,
             relative_rotation: Map.get(input, :relative_rotation),
             direction: Map.get(input, :direction)
           ),
         {:ok, board_update} <- BoardUpdate.new(active_piece_update: piece_update) do
      update_board(player_id, board_update)
    else
      {:error, reason} when is_list(reason) ->
        Logger.debug("Board update was rejected. Reason: #{inspect(reason)}")
        {:error, :invalid_update}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def update_board(_player_id, %BoardUpdate{} = _board_update), do: {:error, :unknown_player}
  def update_board(_player_id, _board_update), do: {:error, :invalid_update}

  @doc """
  Subscribes current process to messages with board updates of a given player.

  Messages come in the format of `{:internal_board_update, %Pulk.Board{}}`
  """
  @spec subscribe_to_board_updates(player_id :: String.t()) :: :ok | {:error, term()}
  def subscribe_to_board_updates(player_id) do
    BoardSubscription.subscribe(player_id)
  end

  @doc """
  Transforms `Pulk.Board` to `Pulk.Board.BoardSnapshot`
  """
  @spec compose_board_snapshot(Board.t()) :: BoardSnapshot.t()
  def compose_board_snapshot(%Board{} = board) do
    Board.to_snapshot(board)
  end
end
