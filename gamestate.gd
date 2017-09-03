extends Node

# Signals to let lobby GUI know what's going on
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


# class member variables go here, for example:
# var a = 2
# var b = "textvar"

const DEFAULT_PORT = 27015
const MAX_PEERS = 4

var player_scene = null
var player_name = "Playa"
var players = {}

func _ready():
	player_scene = load("res://Player.tscn")
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

# Callback from SceneTree
func _player_connected(id):
	print("Player ", id, " connected.")
	pass

# Callback from SceneTree
func _player_disconnected(id):
	print("Player ", id, " disconnected.")
	unregister_player(id)
	for p_id in players:
		rpc_id(p_id, "unregister_player", id)


# Callback from SceneTree, only for clients (not server)
func _connected_ok():
	# Registration of a client beings here, tell everyone that we are here
	print("Connected! Sending register request to server...")
	rpc("register_player", get_tree().get_network_unique_id(), player_name)
	emit_signal("connection_succeeded")
	create_player(get_tree().get_network_unique_id(), player_name)

# Callback from SceneTree, only for clients (not server)
func _server_disconnected():
	get_tree().set_network_peer(null)
	end_game()
	emit_signal("game_error", "Server disconnected")

# Callback from SceneTree, only for clients (not server)
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

func create_player(id, name):
	print("Creating player ", id, " with name ", name, "...")
	var player = player_scene.instance()
	player.translation = Vector3(0,10,0)
	set_name(str(id))
	get_node("/root/World/Players").add_child(player)
	player.set_player(id)
	print("Created player ", id, " with name ", name)

func host_game(name):
	player_name = name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	
	create_player(get_tree().get_network_unique_id(), name)

func join_game(ip, name):
	player_name = name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

func end_game():
	var nodes = get_tree().get_nodes_in_group("players")
	for n in nodes:
		n.queue_free()
		break
	
	get_node("/root/World/Camera").set_camera_target(null)
	emit_signal("game_ended")

remote func register_player(id, name):
	print("Player ", id, " with name ", name, " was registered.")
	create_player(id, name)

	if (get_tree().is_network_server()):
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, player_name) # Send myself to new dude
		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, name) # Send new dude to player
	
	players[id] = name

remote func unregister_player(id):
	var name = players[id]
	players.erase(id)
	
	var nodes = get_tree().get_nodes_in_group("players")
	for n in nodes:
		if n.get_network_master() == id:
			n.queue_free()
			break
	

