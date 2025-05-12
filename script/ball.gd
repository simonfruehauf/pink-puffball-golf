extends RigidBody3D

## Kirby-style Golf Ball Mechanics ##
enum ShotType { PUTT, POWER, LOB }
@export var turn_increment: float = 15.0  # Degrees per snap turn

# Shooting properties
var current_direction: Vector3 = Vector3.FORWARD
var shot_type: ShotType = ShotType.PUTT
var shot_presets = {
	ShotType.PUTT: {"force": 5.0, "angle": 0.0},
	ShotType.POWER: {"force": 10.0, "angle": 5.0},
	ShotType.LOB: {"force": 7.0, "angle": 45.0}
}
@export var label : Label
@export var label2 : Label
var shot_power = 0.1
var charging = false
var charging_dir = 1.0
func _input(event):
	# Direction control
	if Input.is_action_just_pressed("turn_left"):
		current_direction = current_direction.rotated(Vector3.UP, deg_to_rad(turn_increment))
	if Input.is_action_just_pressed("turn_right"):
		current_direction = current_direction.rotated(Vector3.UP, deg_to_rad(-turn_increment))
	# Shot selection
	if Input.is_action_just_pressed("shot_next"):
		shot_type = wrapi(shot_type + 1, 0, ShotType.size())
	if Input.is_action_just_pressed("shot_prev"):
		shot_type = wrapi(shot_type - 1, 0, ShotType.size())
	if Input.is_action_just_pressed("shoot") && charging:
		shoot()
		charging = false
	elif Input.is_action_just_pressed("shoot") && !charging:
		charging = true

func _physics_process(delta: float) -> void:
	if shot_power > 2.0:
		charging_dir = -1.0
		shot_power = 2.0
	elif shot_power < 0.1:
		charging_dir = 1.0
		shot_power = 0.1
	if charging:
		shot_power += 0.02 * charging_dir
	else:
		shot_power = 0.1

	label.text = str(shot_power)
	label2.text = str(shot_type)
func shoot():
	var launch_vector = current_direction.rotated(
		Vector3.RIGHT, 
		deg_to_rad(shot_presets[shot_type].angle)
		).normalized() * shot_presets[shot_type].force * shot_power
	apply_impulse(launch_vector, Vector3.ZERO)
	return
	
func visualize():
	return
