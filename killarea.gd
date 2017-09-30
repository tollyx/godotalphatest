extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	connect("body_entered", self, "reset_player")

func reset_player(node):
	if node is KinematicBody:
		node.translation = Vector3(0, 10, 0)
		