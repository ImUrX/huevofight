extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var client = get_node("../Client")

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

remotesync func pre_configure_game():
	get_tree().set_pause(true)
	var selfPeerID = get_tree().get_network_unique_id()

	# Load world
	var world = load("res://scenes/Game.tscn").instance()
	get_node("/root").add_child(world)

	# Load my player
	var my_player = preload("res://scenes/Player.tscn").instance()
	my_player.set_name(str(selfPeerID))
	my_player.set_network_master(selfPeerID) # Will be explained later
	get_node("/root/Game/Players").add_child(my_player)

	# Load other players
	for p in players_info:
		var player = preload("res://scenes/Player.tscn").instance()
		player.set_name(str(p))
		player.set_network_master(p) # Will be explained later
		get_node("/root/Game/Players").add_child(player)

	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
	# The server can call get_tree().get_rpc_sender_id() to find out who said they were done.
	rpc_id(1, "done_preconfiguring")

var players_done = []
remote func done_preconfiguring():
	var who = get_tree().get_rpc_sender_id()
	players_done.append(who)

	if players_done.size() == players_info.size():
		rpc("post_configure_game")

remote func post_configure_game():
	# Only the server is allowed to tell a client to unpause
	if 1 == get_tree().get_rpc_sender_id():
		get_tree().set_pause(false)
		# Game starts now!

func show_players():
	$List.text = "Connected people:"
	$List.text += "\n%s" % own_info["name"]
	for id in players_info:
		$List.text += "\n%s" % players_info[id]["name"]

func _on_StartButton_pressed():
	client.seal_lobby()
	rpc("pre_configure_game")
