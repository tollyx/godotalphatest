extends KinematicBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
const gravity = 92

const MAX_SPEED = 800
const JUMP_SPEED = 25
const MAX_SLOPE_ANGLE = 30
const MOUSE_SENSIVITY = 0.05

slave var slave_vel = Vector3()
slave var slave_pos = Vector3()
slave var slave_rot = Vector3()
var velocity = Vector3()

func get_camera_target_node():
	return get_node("CameraAxis/CameraTarget")

func set_player(playerId):
	set_network_master(playerId, true)
	if is_network_master():
		get_node("/root/World/Camera").set_camera_target(get_camera_target_node())
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready():# Called every time the node is added to the scene.
	add_to_group("players")
	slave_pos = translation
	slave_rot = rotation

func _fixed_process(delta):
	var dir = Vector3()
	var cam_xform = get_node("CameraAxis/CameraTarget").get_global_transform()
	
	if is_network_master():
		if (Input.is_key_pressed(KEY_W)):
			dir += -cam_xform.basis[2]
		if (Input.is_key_pressed(KEY_S)):
			dir += cam_xform.basis[2]
		if (Input.is_key_pressed(KEY_A)):
			dir += -cam_xform.basis[0]
		if (Input.is_key_pressed(KEY_D)):
			dir += cam_xform.basis[0]
		dir.y = 0
		dir = dir.normalized()
		
		velocity.x = 0
		velocity.z = 0
		
		velocity += dir * MAX_SPEED * delta
		
		if(is_on_floor() and Input.is_key_pressed(KEY_SPACE)):
			velocity.y = JUMP_SPEED
		else:
			velocity.y += -gravity * delta
		
		rset_unreliable("slave_vel", velocity)
		rset_unreliable("slave_pos", translation)
	else:
		velocity = slave_vel
		translation = slave_pos
		rotation = slave_rot

	velocity = move_and_slide(velocity, Vector3(0,1,0))
	
	if not is_network_master():
		slave_vel = velocity
		slave_pos = translation
	
func _input(event):
	if is_network_master():
		if(event is InputEventMouseMotion):
			var axis = get_node("CameraAxis")
			var rot_h = -event.relative.x/10 * MOUSE_SENSIVITY
			var rot_v = -event.relative.y/10 * MOUSE_SENSIVITY
			rotate_y(rot_h)
			axis.rotate_x(rot_v)
			var rot = axis.get_rotation_deg()
			rot.x = clamp(rot.x, -80, 30)
			axis.rotation_deg = rot
			rset_unreliable("slave_rot", rotation)
