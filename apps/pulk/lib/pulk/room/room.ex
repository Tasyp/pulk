defmodule Pulk.Room do
  @type t :: %__MODULE__{
          room_id: String.t(),
          started_at: DateTime.t() | nil,
          max_player_limit: Integer.t()
        }

  @enforce_keys [:room_id, :max_player_limit]
  defstruct [:room_id, :max_player_limit, :started_at]

  @default_player_limit 5

  @spec create(Map.t()) :: Pulk.Room.t()
  def create(attrs \\ %{}) when is_map(attrs) do
    %__MODULE__{
      room_id: Map.get(attrs, :room_id, generate_id()) || generate_id(),
      max_player_limit: Map.get(attrs, :max_player_limit, @default_player_limit)
    }
  end

  def generate_id do
    Ecto.UUID.generate()
  end
end
