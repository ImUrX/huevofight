extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

# Called every frame. 'delta' is the elapsed time since the previous frame.
var players_info = {}
var own_info := { name = "" }

func _player_connected(id):
	# Called on both clients and server when a peer connects. Send my info to it.
	rpc_id(id, "register_player", own_info)

func _player_disconnected(id):
	players_info.erase(id) # Erase player from info.

func _connected_ok():
	pass # Only called on clients, not server. Will go unused; not useful here.

func _server_disconnected():
	pass # Server kicked us; show error and abort.

func _connected_fail():
	pass # Could not even connect to server; abort.

remote func register_player(info):
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	# Store the info
	players_info[id] = info
	show_players()

func show_players():
	$List.text = "Connected people:"
	$List.text += "\n%s" % own_info["name"]
	for player in players_info:
		$List.text += "\n%s" % player["name"]
