defmodule Pulk.PlayerContext do
  alias Pulk.Player.PlayerManager
  alias Pulk.Game.Board
  alias Pulk.Game.Matrix
  alias Pulk.Game.BoardUpdate

  @spec get_player(String.t()) :: {:error, :unknown_player} | {:ok, Pulk.Player.t()}
  def get_player(player_id) do
    with :ok <- PlayerManager.is_player_present?(player_id) do
      PlayerManager.get_player(PlayerManager.via_tuple(player_id))
    end
  end

  @spec get_board(String.t()) :: {:ok, Board.t()} | {:error, :unknown_player}
  def get_board(player_id) do
    with :ok <- PlayerManager.is_player_present?(player_id) do
      PlayerManager.get_board(PlayerManager.via_tuple(player_id))
    end
  end

  @spec update_board_matrix(String.t(), Matrix.t()) ::
          {:ok, Board.t()}
          | {:error, :unknown_player}
          | {:error, :invalid_size}
  def update_board_matrix(player_id, matrix) do
    with :ok <- PlayerManager.is_player_present?(player_id) do
      PlayerManager.update_matrix(PlayerManager.via_tuple(player_id), matrix)
    end
  end

  @spec update_board(String.t(), BoardUpdate.t(), keyword()) ::
          {:ok, Board.t()}
          | {:error, :unknown_player}
          | {:error, :invalid_update}
          | {:error, :board_complete}
  def update_board(player_id, board_update, opts \\ []) do
    with :ok <- PlayerManager.is_player_present?(player_id) do
      PlayerManager.update_board(PlayerManager.via_tuple(player_id), board_update, opts)
    end
  end
end
