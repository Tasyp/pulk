defmodule Pulk.Player do
  @type t :: %__MODULE__{
          room_id: String.t() | nil,
          player_id: String.t()
        }

  @enforce_keys [:player_id]
  defstruct [:player_id, :room_id]

  def create do
    %__MODULE__{player_id: generate_id()}
  end

  def assign_room(%Pulk.Player{} = player, %Pulk.Room{room_id: room_id}) do
    %{player | room_id: room_id}
  end

  def generate_id do
    Ecto.UUID.generate()
  end
end
