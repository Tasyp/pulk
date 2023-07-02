defmodule PulkWeb.PieceUpdateJSON do
  @update_types ~w[simple soft_drop_start soft_drop_stop hard_drop hold]
  @directions ~w[left right down]
  @rotations ~w[left right]

  @type piece_update_json :: %{
          piece: String.t(),
          update_type: String.t(),
          relative_rotation: String.t() | nil,
          direction: String.t() | nil
        }

  def from_json(input) when is_map(input) do
    %{}
    |> parse_piece(input)
    |> parse_update_type(input)
    |> parse_rotation(input)
    |> parse_direction(input)
  end

  def from_json(_), do: %{}

  defp parse_piece(output, %{"piece" => piece}), do: Map.put(output, :piece, piece)
  defp parse_piece(output, _), do: output

  defp parse_update_type(output, input),
    do: parse_atom_value(output, input, {:update_type, @update_types})

  defp parse_rotation(output, input),
    do: parse_atom_value(output, input, {:relative_rotation, @rotations})

  defp parse_direction(output, input),
    do: parse_atom_value(output, input, {:direction, @directions})

  defp parse_atom_value(output, input, {key, allowed_values}) do
    input_value = Map.get(input, Atom.to_string(key))

    parsed_value =
      if Enum.member?(allowed_values, input_value),
        do: String.to_existing_atom(input_value),
        else: nil

    Map.put(output, key, parsed_value)
  end
end
