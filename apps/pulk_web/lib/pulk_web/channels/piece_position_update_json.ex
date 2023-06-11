defmodule PulkWeb.PiecePositionUpdateJSON do
  require Logger

  alias Pulk.Game.PiecePositionUpdate
  alias PulkWeb.PieceJSON

  @type piece_position_update_json :: %{
          piece: String.t(),
          update_type: String.t(),
          rotation: String.t() | nil,
          direction: String.t() | nil
        }

  @spec from_json(map() | nil) ::
          {:ok, PiecePositionUpdate.t() | nil}
          | {:error, :invalid_piece}
          | {:error, :invalid_update_type}
          | {:error, :invalid_rotation}
          | {:error, :invalid_direction}
          | {:error, :malformed}
  def from_json(nil) do
    {:ok, nil}
  end

  def from_json(
        %{
          "piece" => piece,
          "update_type" => update_type
        } = input
      ) do
    with {:ok, piece} <- PieceJSON.from_json(piece),
         {:ok, update_type} <- parse_update_type(update_type),
         {:ok, rotation} <- parse_rotation(Map.get(input, "rotation")),
         {:ok, direction} <- parse_direction(Map.get(input, "direction")),
         {:ok, piece_update} <-
           PiecePositionUpdate.new(
             piece: piece,
             update_type: update_type,
             rotation: rotation,
             direction: direction
           ) do
      {:ok, piece_update}
    else
      {:error, reason} when is_list(reason) ->
        Logger.debug("Piece position update was malformed: #{inspect(reason)} ")
        {:error, :malformed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def from_json(_) do
    Logger.debug("Piece position update has missing fields")
    {:error, :malformed}
  end

  defp parse_update_type(update_type) do
    case update_type do
      "simple" ->
        {:ok, :simple}

      "soft_drop_start" ->
        {:ok, :soft_drop_start}

      "soft_drop_stop" ->
        {:ok, :soft_drop_stop}

      "hard_drop" ->
        {:ok, :hard_drop}

      _ ->
        {:error, :invalid_update_type}
    end
  end

  defp parse_rotation(rotation) do
    case rotation do
      "O" ->
        {:ok, :O}

      "R" ->
        {:ok, :R}

      "L" ->
        {:ok, :L}

      "two" ->
        {:ok, :two}

      nil ->
        {:ok, nil}

      _ ->
        {:error, :invalid_rotation}
    end
  end

  defp parse_direction(direction) do
    case direction do
      "down" ->
        {:ok, :down}

      "left" ->
        {:ok, :left}

      "right" ->
        {:ok, :right}

      nil ->
        {:ok, nil}

      _ ->
        {:error, :invalid_direction}
    end
  end
end

defimpl Jason.Encoder, for: [Pulk.Game.PiecePositionUpdate] do
  def encode(struct, opts) do
    Jason.Encode.map(
      Map.from_struct(struct),
      opts
    )
  end
end
