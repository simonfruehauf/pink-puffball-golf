extends CharacterBody3D

enum Modes {SHORT = 0, LONG = 1, JUMP = 2}

@export var max_force: float = 25.0
@export var force: float = 15.0
@export var bounce_factor = 0.5
@export var drag = 0.2
@export var friction = 0.8
var can_shoot = true
var stop_below_velocity: float = 0.53
var shotstart = false
@export var step_size: float = 5.0
var force_increment_size: float = 5.0
@export var fake_ball : CharacterBody3D
var aim_rotation: float = 0.0
var v: Vector3 = Vector3(1, 1, 0)
@export var mode: Modes = Modes.SHORT
@export var force_bar : ProgressBar
@export var mode_label : Label
var freeze = false
var gravity = -ProjectSettings.get_setting("physics/3d/default_gravity_vector")
@onready var collisionshape = $Collision

var trajectories : Array

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
		velocity = Vector3.ZERO
		freeze = false
		shotstart = true
		#draw_preview()
		#apply_central_impulse(v)
		velocity += v * get_physics_process_delta_time()
		simulate(self)
		await get_tree().create_timer(0.25).timeout
		shotstart = false
	else:
		print("Cant shoot.")

func rotate_aim(dir):
	aim_rotation += step_size * dir
	set_v(force)
	draw_preview()
	return

func adjust_force(f):
	force += force_increment_size * f
	force = clampf(force, 0, max_force)
	force_bar.value = force
	set_v(force)
	draw_preview()
	return

## Simulates either the preview ball or the real ball to 150 iterations. 
## TODO In the future, should probably stop at the second bounce OR X iterations, whatever comes first.
func simulate(ball) -> Array[Vector3]:
	if ball == fake_ball:
		ball.transform = self.transform
		ball.velocity = Vector3.ZERO
		ball.velocity += v * get_physics_process_delta_time()
	var path: Array[Vector3]
	for i in range(1, 150):
		if ball != fake_ball:
			await get_tree().create_timer(get_physics_process_delta_time()).timeout
		var collision = ball.move_and_collide(ball.velocity)
		if collision:
			var normal = collision.get_normal()
			# Split velocity into normal (vertical) and tangent (horizontal) components
			var velocity_normal = ball.velocity.project(normal)
			var velocity_tangent = ball.velocity - velocity_normal
			# Apply bounce to the normal component
			velocity_normal = velocity_normal.bounce(normal) * bounce_factor
			# Apply friction to the tangent component (slows horizontal movement)
			velocity_tangent *= (1.0 - friction * get_physics_process_delta_time())
			ball.velocity = velocity_normal + velocity_tangent
		else:
			ball.velocity -= gravity * get_physics_process_delta_time()
		# Apply air resistance (drag) to all movement
		ball.velocity *= (1.0 - drag * get_physics_process_delta_time())
		
		path.append(ball.global_position)
	if ball != fake_ball:
		ball.freeze = true
		ball.can_shoot = true
	return path

func set_v(f: float):
	var x = cos(deg_to_rad(aim_rotation)) * f 
	x *=  0.4 if mode == Modes.JUMP else (1.0 if mode == Modes.SHORT else 2.0)
	var z = sin(deg_to_rad(aim_rotation)) * f 
	z *=  0.4 if mode == Modes.JUMP else (1.0 if mode == Modes.SHORT else 2.0)
	var y = 15.0 if mode == Modes.JUMP else 0.0
	v = Vector3(x, y, z)

func draw_preview():
	for item in trajectories:
		if item:
			item.queue_free()
	trajectories.clear()
	
	var path = await simulate(fake_ball)
	var i = path[0]

	
	for p in path:
		trajectories.append(create_line_segment(i, p))
		i = p
	return

func draw_preview_raycast():
	var tstep = 0.05
	var vel = v 
	var start_pos = global_position
	var g = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	#var drag = linear_damp
	var line_start = start_pos
	var line_end = start_pos
	
	# Clear previous trajectory lines
	for item in trajectories:
		item.queue_free()
	trajectories.clear()
	
	# Calculate and draw trajectory points
	for i in range(1, 151):
		vel = vel + g * tstep  #  gravity 
		#vel = vel * (1.0 - (drag / mass) * tstep) #  drag including mass, but since mass is 1kg it doesnt do shit
		line_end = line_start + (vel * tstep) # move end point
		
		# collisions
		var query = PhysicsRayQueryParameters3D.create(line_start, line_end)
		query.exclude = [self]  # dont collide with self again
		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(query)
		
		# Visualize
		create_line_segment(line_start, line_end)
		# if collision detected, stop drawing
		if result:
			break

		# reset
		line_start = line_end

func create_line_segment(start, end):
	# Create MeshInstance3D for the trajectory segment
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = Color(1, 0.0, 0.0, 1.0) 
	material.emission_enabled = true
	material.flags_unshaded = true
	
	# Create line segment
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(start)
	immediate_mesh.surface_add_vertex(end)
	immediate_mesh.surface_end()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = material
	
	var c = mesh_instance
	c.top_level = true
	add_child(c)
	trajectories.append(c)
