extends RigidBody3D

enum Modes {SHORT = 0, LONG = 1, JUMP = 2}

@export var max_force: float = 10.0
@export var force: float = 5.0
var can_shoot = true
var stop_below_velocity: float = 0.15
var shotstart = false
@export var step_size: float = 5.0
var force_increment_size: float = 2.5
@export var gravity : Vector3 = Vector3(0, 9.8, 0.0)

var aim_rotation: float = 0.0
var v: Vector3 = Vector3(1, 1, 0)
@export var mode: Modes = Modes.SHORT
@export var force_bar : ProgressBar
@export var mode_label : Label

func _ready() -> void:
	force_bar.min_value = 0
	force_bar.max_value = max_force
	force_bar.value = force

func _unhandled_input(event):
	if event.is_action_pressed("shoot"):
		shoot()
	elif event.is_action_pressed("mode_switch"):
		mode_switch()
	
	# Handle aim rotation
	if event.is_action("rotate_left"):
		if event.is_pressed():
			rotate_aim(-1.0)
	
	if event.is_action("rotate_right"):
		if event.is_pressed():
			rotate_aim(1.0)
	
	# Handle force adjustment
	if event.is_action_pressed("increase_force"):
		adjust_force(1.0)
	elif event.is_action_pressed("decrease_force"):
		adjust_force(-1.0)

func mode_switch():
	mode = (mode + 1) % 3
	mode_label.text = Modes.keys()[mode]
	set_v(force)
	draw_preview()

func shoot():
	if can_shoot:
		can_shoot = false
		freeze = false
		shotstart = true
		print(v)
		apply_central_impulse(v)
		await get_tree().create_timer(0.25).timeout
		shotstart = false

func rotate_aim(dir):
	aim_rotation += step_size * dir
	draw_preview()
	set_v(force)
	return

func adjust_force(f):
	force += force_increment_size * f
	force = clampf(force, 0, max_force)
	force_bar.value = force
	set_v(force)
	draw_preview()
	return

func draw_preview():
	return
	
func _physics_process(delta):
	if linear_velocity.length() < stop_below_velocity && !shotstart:
		freeze = true
		can_shoot = true

func set_v(f: float):
	var x = cos(deg_to_rad(aim_rotation)) * f
	var z = sin(deg_to_rad(aim_rotation)) * f
	v = Vector3(x, f if mode == Modes.JUMP else 0.0, z)
	print(force)
	print(v)
