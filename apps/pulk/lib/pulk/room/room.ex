defmodule Pulk.Room do
  @type t :: %__MODULE__{
          room_id: String.t(),
          started_at: DateTime.t() | nil,
          max_player_limit: Integer.t(),
          # {X, Y} coordinates
          board_size: {pos_integer(), pos_integer()}
        }

  @enforce_keys [:room_id, :max_player_limit, :board_size]
  defstruct [:room_id, :max_player_limit, :started_at, :board_size]

  @default_player_limit 4
  @default_board_size {10, 20}

  @spec create() :: Pulk.Room.t()
  @spec create(Map.t()) :: Pulk.Room.t()
  def create(attrs \\ %{}) when is_map(attrs) do
    %__MODULE__{
      room_id: Map.get(attrs, :room_id) || generate_id(),
      max_player_limit: Map.get(attrs, :max_player_limit, @default_player_limit),
      board_size: Map.get(attrs, :board_size, @default_board_size)
    }
  end

  @spec generate_id() :: Ecto.UUID.t()
  def generate_id do
    Ecto.UUID.generate()
  end
end
