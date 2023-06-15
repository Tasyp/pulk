defmodule Pulk.Player do
  @moduledoc """
  Entity that keeps information about a player
  """

  use TypedStruct
  use Domo, gen_constructor_name: :_new

  typedstruct do
    field :room_id, String.t()
    field :player_id, String.t(), enforce: true
  end

  @spec new!(map()) :: t()
  @spec new!() :: t()
  def new!(room \\ %{}) do
    _new!(room |> prefill_player)
  end

  @spec new(map()) :: {:ok, t()} | {:error, list()}
  @spec new() :: {:ok, t()} | {:error, list()}
  def new(room \\ %{}) do
    _new(room |> prefill_player)
  end

  defp prefill_player(player) do
    player
    |> Map.put_new(:player_id, generate_id())
  end

  @spec assign_room(Pulk.Player.t(), Pulk.Room.t()) :: Pulk.Player.t()
  def assign_room(%Pulk.Player{} = player, %Pulk.Room{room_id: room_id}) do
    %{player | room_id: room_id}
  end

  @spec generate_id() :: String.t()
  def generate_id do
    Nanoid.generate()
  end
end
