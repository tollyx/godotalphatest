extends Camera

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var cameratarget = null

func set_camera_target(spatialnode):
	if spatialnode != null && spatialnode is Spatial:
		cameratarget = spatialnode
		global_transform = cameratarget.global_transform
	else:
		cameratarget = null

func _ready():
	# Called every time the node is added to the scene.
	#set_camera_target(get_node("../Player").get_camera_target_node())
	pass

func _process(delta):
	if cameratarget != null:
		global_transform = cameratarget.global_transform