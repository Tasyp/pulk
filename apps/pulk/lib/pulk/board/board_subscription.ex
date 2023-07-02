defmodule Pulk.Board.BoardSubscription do
  @moduledoc """
  A module that encapsulates pubsub subscription for player board updates 
  """
  require Logger

  alias Phoenix.PubSub
  alias Pulk.Board

  @spec subscribe(String.t()) :: :ok | {:error, term()}
  def subscribe(player_id) when is_bitstring(player_id) do
    PubSub.subscribe(Pulk.PubSub, topic_id(player_id))
  end

  def subscribe(_), do: {:error, :invalid_player_id}

  @spec publish(String.t(), Board.t()) :: :ok
  def publish(player_id, %Board{} = board) when is_bitstring(player_id) do
    case PubSub.broadcast(
           Pulk.PubSub,
           topic_id(player_id),
           {:internal_board_update, board}
         ) do
      {:error, reason} ->
        Logger.error("Board broadcast failed for player #{player_id}: #{inspect(reason)}")

      _ ->
        # ignore
        nil
    end

    :ok
  end

  defp topic_id(player_id) when is_bitstring(player_id), do: "player:#{player_id}:board"
end
