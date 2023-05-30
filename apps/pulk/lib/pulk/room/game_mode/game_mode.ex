defmodule Pulk.Room.GameMode do
  require Logger

  use TypedStruct

  alias Pulk.Room
  alias Pulk.Room.GameMode

  @type mode_type() :: :line_goal
  @type game_mode() :: %{
          type: mode_type(),
          args: term()
        }

  @default_game_mode %{
    type: :line_goal,
    args: %{line_goal: 3}
  }

  @game_modes %{
    line_goal: GameMode.LineGoal
  }

  typedstruct enforce: true do
    field :module, module()
    field :type, mode_type()
    field :state, term(), default: %{}
  end

  @spec new!(mode_type :: mode_type()) :: t()
  def new!(mode_type) do
    %__MODULE__{module: get_game_mode_module(mode_type), type: mode_type}
  end

  @callback init(t(), init_args :: term()) :: {:ok, t()} | {:error, reason :: atom}
  def init(%__MODULE__{module: module} = mode, init_args) do
    state = apply(module, :init, [init_args])

    case state do
      {:ok, state} ->
        {:ok, %{mode | state: state}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec handle_room_update(t(), room :: Room.t()) ::
          {:ok, t(), Room.t()} | {:error, reason :: atom}
  def handle_room_update(
        %__MODULE__{} = mode,
        %{status: :complete} = room
      ) do
    {:ok, mode, room}
  end

  def handle_room_update(%__MODULE__{module: module, state: module_state} = mode, room) do
    state = apply(module, :handle_room_update, [module_state, room])

    case state do
      {:ok, state, room} ->
        {:ok, %{mode | state: state}, room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def default_game_mode do
    @default_game_mode
  end

  @spec get_game_mode_module(mode_type()) :: module()
  defp get_game_mode_module(game_mode) do
    @game_modes[game_mode]
  end
end
