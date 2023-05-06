alias Pulk.GameMaster
alias Pulk.RoomMaster

{:ok, room} = GameMaster.create_room(Pulk.Room.create())
player = Pulk.Player.create()
