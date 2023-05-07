defmodule PulkWeb.RoomJSON do
  alias Pulk.Room

  def index(%{room: %Room{} = room}) do
    %{data: %{"room_id" => room.room_id}}
  end
end
