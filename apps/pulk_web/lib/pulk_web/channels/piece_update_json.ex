defmodule PulkWeb.PieceUpdateJSON do
  require Logger

  alias Pulk.Piece.PieceUpdate
  alias PulkWeb.PieceJSON

  @update_types ~w[simple soft_drop_start soft_drop_stop hard_drop hold]
  @directions ~w[left right down]
  @rotations ~w[left right]

  @type piece_update_json :: %{
          piece: String.t(),
          update_type: String.t(),
          relative_rotation: String.t() | nil,
          direction: String.t() | nil
        }

  @spec from_json(map() | nil) ::
          {:ok, PieceUpdate.t() | nil}
          | {:error, term()}
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
         {:ok, relative_rotation} <- parse_rotation(Map.get(input, "relative_rotation")),
         {:ok, direction} <- parse_direction(Map.get(input, "direction")),
         {:ok, piece_update} <-
           PieceUpdate.new(
             piece: piece,
             update_type: update_type,
             relative_rotation: relative_rotation,
             direction: direction
           ) do
      {:ok, piece_update}
    else
      {:error, reason} when is_list(reason) ->
        Logger.debug("Piece update was malformed: #{inspect(reason)} ")
        {:error, :malformed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def from_json(_), do: {:error, :malformed}

  defp parse_update_type(update_type) when update_type in @update_types do
    {:ok, String.to_existing_atom(update_type)}
  end

  defp parse_update_type(_), do: {:error, :invalid_update_type}

  defp parse_rotation(relative_rotation) when relative_rotation in @rotations do
    {:ok, String.to_existing_atom(relative_rotation)}
  end

  defp parse_rotation(nil), do: {:ok, nil}
  defp parse_rotation(_), do: {:error, :invalid_rotation}

  defp parse_direction(direction) when direction in @directions do
    {:ok, String.to_existing_atom(direction)}
  end

  defp parse_direction(nil), do: {:ok, nil}
  defp parse_direction(_), do: {:error, :invalid_direction}
end
