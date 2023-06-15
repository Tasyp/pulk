defmodule Pulk.Room do
  @moduledoc """
  Entity that keeps information about a game room that players can enter to play game.
  """

  use TypedStruct
  use Domo, gen_constructor_name: :_new

  alias Pulk.Room.GameMode

  @type status() :: :initial | :playing | :complete
  @type coordinates() :: {pos_integer(), pos_integer()}

  typedstruct enforce: true do
    field :game_mode, GameMode.game_mode(), default: GameMode.default_game_mode()
    field :status, status(), default: :initial
    field :room_id, String.t()
    field :started_at, DateTime.t(), enforce: false
    field :max_player_limit, pos_integer(), default: 4
    field :board_size, coordinates(), default: {10, 20}
  end

  @spec new!(map()) :: t()
  @spec new!() :: t()
  def new!(room \\ %{}) do
    _new!(room |> prefill_room)
  end

  @spec new(map()) :: {:ok, t()} | {:error, list()}
  @spec new() :: {:ok, t()} | {:error, list()}
  def new(room \\ %{}) do
    _new(room |> prefill_room)
  end

  @spec update_status(room :: t(), status :: status()) :: {:ok, t()}
  def update_status(%__MODULE__{} = room, status) do
    {:ok, ensure_type!(%{room | status: status})}
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
