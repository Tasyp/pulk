alias Pulk.RoomContext

{:ok, room} = RoomContext.create_room(Pulk.Room.create())
player = Pulk.Player.create()
