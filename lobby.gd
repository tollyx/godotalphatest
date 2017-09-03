extends Control


func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")

func _on_host_pressed():
	var name = get_node("connect/name").text
	if name == "":
		get_node("error").dialog_text="Please enter a Nickname."
		get_node("error").popup_centered_minsize()
		return
	get_node("connect").hide()
	gamestate.host_game(name)

func _on_join_pressed():
	var name = get_node("connect/name").text
	if name == "":
		get_node("error").dialog_text="Please enter a Nickname."
		get_node("error").popup_centered_minsize()
		return
	
	var ip = get_node("connect/ip").text
	if (not ip.is_valid_ip_address()):
		get_node("error").dialog_text="Please enter a valid IP address."
		get_node("error").popup_centered_minsize()
		return

	get_node("connect/host").disabled=true
	get_node("connect/join").disabled=true
	
	get_node("connecting").show()
	get_node("connect").hide()
	gamestate.join_game(ip, name)
	# refresh_lobby() gets called by the player_list_changed signal

func _on_connection_success():
	get_node("connecting").hide()

func _on_connection_failed():
	get_node("connect").show()
	get_node("connect/host").disabled=false
	get_node("connect/join").disabled=false
	get_node("connecting").hide()
	get_node("error").dialog_text="Connection failed."
	get_node("error").popup_centered_minsize()

func _on_game_ended():
	show()
	get_node("connect").show()
	get_node("connect/host").disabled=false
	get_node("connect/join").disabled=false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_game_error(errtxt):
	get_node("error").dialog_text=errtxt
	get_node("error").popup_centered_minsize()

func _on_start_pressed():
	gamestate.begin_game()
