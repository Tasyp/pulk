defmodule Pulk.Player do
  @type t :: %__MODULE__{
          room_id: String.t() | nil,
          player_id: String.t()
        }

  @enforce_keys [:player_id]
  defstruct [:player_id, :room_id]

  @spec create() :: Pulk.Player.t()
  @spec create(Map.t()) :: Pulk.Player.t()
  def create(attrs \\ %{}) do
    %__MODULE__{
      player_id: Map.get(attrs, :player_id) || generate_id(),
      room_id: Map.get(attrs, :room_id)
    }
  end

  @spec assign_room(Pulk.Player.t(), Pulk.Room.t()) :: Pulk.Player.t()
  def assign_room(%Pulk.Player{} = player, %Pulk.Room{room_id: room_id}) do
    %{player | room_id: room_id}
  end

  @spec generate_id() :: Ecto.UUID.t()
  def generate_id do
    Ecto.UUID.generate()
  end
end
