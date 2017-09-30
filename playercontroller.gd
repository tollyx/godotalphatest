extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
const gravity = 8.2 * 1000

const MAX_SPEED = 800
const JUMP_SPEED = 2 * 1000
const JUMP_MARGIN = 0.25
const JUMP_AMOUNT = 2
const DASH_SPEED = 2000
const DASH_AMOUNT = 1
const DASH_COOLDOWN = 0.15
const DASH_LENGTH = 0.15
const MIN_MOVE_DISTANCE = 0.025
const MOUSE_SENSIVITY = 0.2
var fixed_delta = 1.0/60.0

var velocity = Vector3()
var knockback = Vector3()
var anim
var airtime = 0
var jumps = 0
var dashes = 0
var is_hit = false
var dashing = 0.0

func _ready():# Called every time the node is added to the scene.
	add_to_group("players")
	anim = $AnimationPlayer

func get_camera_target_node():
	return $Model/CameraAxis/CameraTarget

func set_player(playerId):
	set_network_master(playerId, false)

func grab_camera():
	get_node("/root/World/Camera").set_camera_target(get_camera_target_node())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

var time_since_fixed = 0.0
var trans_at_start_of_frame = Transform()
func _process(delta):
	$Model.global_transform = trans_at_start_of_frame.interpolate_with($Body.global_transform, time_since_fixed/fixed_delta)
	time_since_fixed += delta

func _fixed_process(delta):
	fixed_delta = delta
	time_since_fixed = 0.0
	trans_at_start_of_frame = $Body.global_transform
	
	if $Body.is_on_floor() and velocity.y <= 0:
		airtime = 0
		jumps = 0
		dashes = 0
		velocity.y = 0
		is_hit = false
	elif dashing <= 0:
		if airtime > JUMP_MARGIN and jumps == 0:
			jumps += 1
		airtime += delta
		
		var gravdelta = gravity * delta
		velocity.y -= gravdelta
	
	if is_network_master():
		if not (is_hit or dashing > 0):
			var dir = Vector3()
			var cam_xform = $Model/CameraAxis/CameraTarget.global_transform
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
			velocity += dir * MAX_SPEED
		
		dashing -= delta
		rpc_unreliable("set_movement", $Body.translation, velocity, $Body.rotation)
		rpc_unreliable("set_look_angle", $Model/CameraAxis.rotation.x)
	
	var floor_normal = Vector3(0, 1, 0)
	var prevpos = $Body.translation
	
	$Body.move_and_slide(velocity * delta, floor_normal)
	
	if prevpos.distance_to($Body.translation) < MIN_MOVE_DISTANCE:
		$Body.translation = prevpos

sync func set_position(pos):
	$Body.translation = pos
	$Model.translation = pos
	trans_at_start_of_frame = $Model.global_transform

remote func set_movement(pos, vel, rot):
	$Body.translation = pos
	velocity = vel
	$Body.rotation = rot

sync func hit(dir):
	velocity = dir.normalized() * 1000
	velocity.y = 1000
	is_hit = true
	dashing = 0

sync func dash(dir):
	dashing = DASH_LENGTH
	velocity = dir.normalized() * DASH_SPEED

remote func set_look_angle(angle):
	$Model/CameraAxis.rotation.x = angle

sync func attack():
	if anim.get_current_animation() == "idle_r":
		anim.play("attack_r")
		anim.queue("idle_l")
	else:
		anim.play("attack_l")
		anim.queue("idle_r")
	var slash = gamestate.slash_scene.instance()
	slash.translation = $Body.translation
	slash.rotation = $Body.rotation
	slash.velocity = Vector3(0,0,-10).rotated(Vector3(0,1,0), $Body.rotation.y)
	slash.set_owner($Body)
	get_node("/root/World").add_child(slash)

func _input(event):
	if is_network_master():
		if(event is InputEventMouseMotion):
			var rot_h = -deg2rad(event.relative.x) * MOUSE_SENSIVITY
			var rot_v = -deg2rad(event.relative.y) * MOUSE_SENSIVITY
			$Body.rotate_y(rot_h)
			$Model/CameraAxis.rotate_x(rot_v)
			var rot = $Model/CameraAxis.get_rotation_deg()
			rot.x = clamp(rot.x, -70, 30)
			$Model/CameraAxis.rotation_deg = rot
			
		elif(event is InputEventKey and not event.is_echo()):
			if event.pressed and event.scancode == KEY_R:
				$Body.translation = Vector3(0, 10, 0)
			elif event.scancode == KEY_SPACE:
				if event.pressed:
					if jumps < JUMP_AMOUNT:
						velocity.y = JUMP_SPEED
						jumps += 1
					dashing = 0
				elif velocity.y > 0:
					velocity.y = 0
			elif event.scancode == KEY_SHIFT and event.pressed and dashing < -DASH_COOLDOWN and dashes < DASH_AMOUNT:
				dashes += 1
				var dir = Vector3()
				var cam_xform = $Model/CameraAxis/CameraTarget.global_transform
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
				if dir != Vector3():
					rpc("dash", dir)
		elif(event is InputEventMouseButton):
			if event.pressed and event.button_index == 1 and anim.get_current_animation().begins_with("idle"):
				rpc("attack")
