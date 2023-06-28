defmodule Pulk.PlayerContext do
  @moduledoc """
  A context to manipulate players. It is intended to be the only publicly available way to do it.

  Containts a collection of method to operatate on players.
  """

  alias Pulk.Player
  alias Pulk.Player.PlayerManager
  alias Pulk.Board
  alias Pulk.Matrix
  alias Pulk.Board.BoardUpdate

  @spec get_player(String.t()) :: {:error, :unknown_player} | {:ok, Pulk.t()}
  def get_player(player_id) do
    with :ok <- PlayerManager.is_player_present?(player_id) do
      PlayerManager.get_player(player_id)
    end
  end

  @spec fetch_player_and_create_if_needed(player_id :: String.t()) ::
          {:ok, Player.t()} | {:error, :invalid_player_id}
  def fetch_player_and_create_if_needed(player_id) when is_bitstring(player_id) do
    case get_player(player_id) do
      {:ok, player} ->
        {:ok, player}

      {:error, :unknown_player} ->
        case Player.new(%{player_id: player_id}) do
          {:ok, player} -> {:ok, player}
          {:error, _reason} -> {:error, :invalid_player_id}
        end
    end
  end

  def fetch_player_and_create_if_needed(_), do: {:error, :invalid_player_id}

  @spec get_board(String.t()) :: {:ok, Board.t()} | {:error, :unknown_player}
  def get_board(player_id) do
    with :ok <- PlayerManager.is_player_present?(player_id) do
      PlayerManager.get_board(PlayerManager.via(player_id))
    end
  end

  @spec update_board_matrix(String.t(), Matrix.t()) ::
          {:ok, Board.t()}
          | {:error, :unknown_player}
          | {:error, :invalid_size}
  def update_board_matrix(player_id, matrix) do
    with :ok <- PlayerManager.is_player_present?(player_id) do
      PlayerManager.update_matrix(PlayerManager.via(player_id), matrix)
    end
  end

  @spec update_board(String.t(), BoardUpdate.t()) ::
          {:ok, Board.t()}
          | {:error, :unknown_player}
          | {:error, :invalid_update}
          | {:error, :board_complete}
  def update_board(player_id, board_update) do
    with :ok <- PlayerManager.is_player_present?(player_id) do
      PlayerManager.update_board(PlayerManager.via(player_id), board_update)
    end
  end

  @spec update_board(String.t(), Board.state()) ::
          {:ok, Board.t()} | {:error, :unknown_player}
  def update_board_status(player_id, board_status) do
    with :ok <- PlayerManager.is_player_present?(player_id) do
      PlayerManager.update_board_status(PlayerManager.via(player_id), board_status)
    end
  end

  @spec subscribe_to_board_updates(String.t()) :: :ok | {:error, term}
  def subscribe_to_board_updates(player_id) do
    PlayerManager.subscribe_to_board_updates(player_id)
  end
end
