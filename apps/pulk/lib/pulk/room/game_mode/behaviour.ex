defmodule Pulk.Room.GameMode.Behaviour do
  alias Pulk.Room

  @callback init(init_args :: term()) :: {:ok, state :: term} | {:error, reason :: atom}

  @callback handle_room_update(state :: term, room :: Room.t()) ::
              {:ok, state :: term, room :: Room.t()} | {:error, reason :: atom}
end
