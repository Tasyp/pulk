defmodule Pulk.Room do
  use TypedStruct
  use Domo, gen_constructor_name: :_new

  @type coordinates() :: {pos_integer(), pos_integer()}

  typedstruct enforce: true do
    field :room_id, String.t()
    field :started_at, DateTime.t(), enforce: false
    field :max_player_limit, pos_integer(), default: 4
    field :board_size, coordinates(), default: {10, 20}
  end

  @spec new!(t()) :: t()
  @spec new!() :: t()
  def new!(room \\ %{}) do
    _new!(room |> prefill_room)
  end

  @spec new(t()) :: {:ok, t()} | {:error, list()}
  @spec new() :: {:ok, t()} | {:error, list()}
  def new(room \\ %{}) do
    _new(room |> prefill_room)
  end

  defp prefill_room(room) do
    room
    |> Map.put_new(:room_id, generate_id())
  end

  @spec generate_id() :: String.t()
  def generate_id do
    FriendlyID.generate(3, separator: "-", transform: &:string.lowercase/1)
  end
end
