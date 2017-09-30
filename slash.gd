extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var active_time
var alive_time
var velocity = Vector3()
var owner

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	active_time = .1
	alive_time = .1
	connect("body_entered", self, "hit")

func hit(body):
	if is_network_master() and active_time > 0:
		if body is KinematicBody and body != owner:
			body.get_parent().rpc("hit", velocity)
			print("WHACK!")

func set_owner(owner_node):
	owner = owner_node

func _process(delta):
	
	if alive_time <= 0:
		queue_free()
	translation += velocity * delta
	active_time -= delta
	alive_time -= delta
