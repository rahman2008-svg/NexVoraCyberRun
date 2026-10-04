extends CharacterBody3D
## Advanced Parkour Player Controller for NexVora CyberRun
## Supports: run, sprint, jump, double jump, slide, wall-run, climb, grapple

class_name PlayerController

signal health_changed(new_health: float)
signal stamina_changed(new_stamina: float)
signal died
signal grappled
signal landed

# Movement parameters
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var slide_speed: float = 11.0
@export var acceleration: float = 12.0
@export var friction: float = 10.0
@export var air_acceleration: float = 4.0
@export var jump_velocity: float = 6.5
@export var gravity: float = 18.0
@export var max_fall_speed: float = 25.0

# Parkour parameters
@export var wall_run_speed: float = 8.0
@export var wall_run_gravity: float = 3.0
@export var wall_run_duration: float = 1.8
@export var climb_speed: float = 3.5
@export var grapple_speed: float = 18.0
@export var grapple_range: float = 25.0
@export var slide_duration: float = 0.9
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

# Camera
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var wall_ray_left: RayCast3D = $WallRayLeft
@onready var wall_ray_right: RayCast3D = $WallRayRight
@onready var climb_ray: RayCast3D = $ClimbRay
@onready var grapple_ray: RayCast3D = $GrappleRay
@onready var floor_ray: RayCast3D = $FloorRay

# State
enum State { IDLE, RUN, SPRINT, JUMP, FALL, SLIDE, WALL_RUN, CLIMB, GRAPPLE, DEAD }
var current_state: State = State.IDLE

var health: float = 100.0
var max_health: float = 100.0
var stamina: float = 100.0
var max_stamina: float = 100.0
var stamina_regen: float = 15.0
var stamina_drain_sprint: float = 12.0

var can_double_jump: bool = true
var is_sliding: bool = false
var slide_timer: float = 0.0
var wall_run_timer: float = 0.0
var wall_normal: Vector3 = Vector3.ZERO
var is_wall_running: bool = false
var is_climbing: bool = false
var climb_timer: float = 0.0
var is_grappling: bool = false
var grapple_point: Vector3 = Vector3.ZERO
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var mouse_sensitivity: float = 0.003
var camera_rotation_x: float = 0.0

# Original collision for slide
var original_shape_height: float = 1.8
var original_shape_y: float = 0.9

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		original_shape_height = collision_shape.shape.height
		original_shape_y = collision_shape.position.y
	print("[Player] Ready")

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	var look := InputManager.get_look_delta(event)
	if look != Vector2.ZERO:
		rotate_y(-look.x * 0.01)
		camera_rotation_x = clamp(camera_rotation_x - look.y * 0.01, deg_to_rad(-80), deg_to_rad(60))
		camera_pivot.rotation.x = camera_rotation_x

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	_update_timers(delta)
	_handle_stamina(delta)
	
	var input_dir := InputManager.get_move_vector()
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var on_floor := is_on_floor()
	
	# Coyote time
	if on_floor:
		coyote_timer = coyote_time
		can_double_jump = true
	else:
		coyote_timer -= delta
	
	# Jump buffer
	if InputManager.is_action_pressed("jump") or Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	# State machine
	match current_state:
		State.GRAPPLE:
			_process_grapple(delta)
		State.WALL_RUN:
			_process_wall_run(delta, direction)
		State.CLIMB:
			_process_climb(delta)
		State.SLIDE:
			_process_slide(delta, direction)
		_:
			_process_normal_movement(delta, direction, on_floor)
	
	move_and_slide()
	_update_state(on_floor)
	_check_wall_run(direction)
	_check_climb()

func _update_timers(delta: float) -> void:
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			_end_slide()
	if is_wall_running:
		wall_run_timer -= delta
		if wall_run_timer <= 0.0:
			_end_wall_run()

func _handle_stamina(delta: float) -> void:
	if current_state == State.SPRINT and velocity.length() > 1.0:
		stamina = max(0.0, stamina - stamina_drain_sprint * delta)
		if stamina <= 0.0:
			current_state = State.RUN
	else:
		stamina = min(max_stamina, stamina + stamina_regen * delta)
	stamina_changed.emit(stamina)

func _process_normal_movement(delta: float, direction: Vector3, on_floor: bool) -> void:
	# Gravity
	if not on_floor:
		velocity.y = max(velocity.y - gravity * delta, -max_fall_speed)
	
	# Jump
	if jump_buffer_timer > 0.0 and (coyote_timer > 0.0 or can_double_jump):
		if coyote_timer <= 0.0 and can_double_jump:
			can_double_jump = false
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		current_state = State.JUMP
	
	# Horizontal movement
	var target_speed := walk_speed
	if InputManager.is_action_pressed("sprint") and stamina > 0.0 and on_floor:
		target_speed = sprint_speed
		current_state = State.SPRINT
	elif on_floor and direction.length() > 0.1:
		current_state = State.RUN
	elif on_floor:
		current_state = State.IDLE
	
	var accel := acceleration if on_floor else air_acceleration
	if direction.length() > 0.1:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, accel * delta)
	else:
		var fric := friction if on_floor else friction * 0.3
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)
		velocity.z = move_toward(velocity.z, 0.0, fric * delta)
	
	# Slide
	if InputManager.is_action_pressed("slide") and on_floor and velocity.length() > walk_speed * 0.8 and not is_sliding:
		_start_slide()
	
	# Grapple
	if Input.is_action_just_pressed("grapple") or InputManager.is_action_pressed("grapple"):
		_try_grapple()

func _start_slide() -> void:
	is_sliding = true
	slide_timer = slide_duration
	current_state = State.SLIDE
	# Lower collision
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = original_shape_height * 0.45
		collision_shape.position.y = original_shape_y * 0.45
	# Boost forward
	var forward := -transform.basis.z
	velocity = forward * slide_speed + Vector3(0, velocity.y, 0)

func _process_slide(delta: float, direction: Vector3) -> void:
	velocity.y = max(velocity.y - gravity * delta, -max_fall_speed)
	# Maintain slide momentum with slight steering
	var forward := -transform.basis.z
	velocity.x = move_toward(velocity.x, forward.x * slide_speed, 8.0 * delta)
	velocity.z = move_toward(velocity.z, forward.z * slide_speed, 8.0 * delta)
	if Input.is_action_just_pressed("jump"):
		_end_slide()
		velocity.y = jump_velocity * 1.1
		current_state = State.JUMP

func _end_slide() -> void:
	is_sliding = false
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = original_shape_height
		collision_shape.position.y = original_shape_y

func _check_wall_run(direction: Vector3) -> void:
	if is_on_floor() or is_sliding or is_grappling or is_climbing:
		return
	if velocity.y > 2.0:  # Going up strongly
		return
	
	var left_hit := wall_ray_left.is_colliding()
	var right_hit := wall_ray_right.is_colliding()
	
	if (left_hit or right_hit) and direction.length() > 0.3 and not is_wall_running:
		wall_normal = wall_ray_left.get_collision_normal() if left_hit else wall_ray_right.get_collision_normal()
		# Only wall run on roughly vertical walls
		if abs(wall_normal.y) < 0.3:
			_start_wall_run()

func _start_wall_run() -> void:
	is_wall_running = true
	wall_run_timer = wall_run_duration
	current_state = State.WALL_RUN
	velocity.y = max(velocity.y, 1.0)

func _process_wall_run(delta: float, direction: Vector3) -> void:
	# Reduced gravity
	velocity.y = max(velocity.y - wall_run_gravity * delta, -2.0)
	
	# Move along the wall
	var wall_forward := wall_normal.cross(Vector3.UP).normalized()
	if direction.dot(wall_forward) < 0:
		wall_forward = -wall_forward
	
	velocity.x = wall_forward.x * wall_run_speed
	velocity.z = wall_forward.z * wall_run_speed
	
	# Stick to wall slightly
	velocity += -wall_normal * 2.0
	
	if Input.is_action_just_pressed("jump"):
		# Jump off wall
		velocity = (wall_normal * 6.0) + Vector3(0, jump_velocity * 1.1, 0)
		_end_wall_run()
		current_state = State.JUMP
		can_double_jump = true
	
	# End if no longer colliding
	if not wall_ray_left.is_colliding() and not wall_ray_right.is_colliding():
		_end_wall_run()

func _end_wall_run() -> void:
	is_wall_running = false
	wall_run_timer = 0.0

func _check_climb() -> void:
	if is_climbing or is_grappling or is_sliding:
		return
	if climb_ray.is_colliding() and InputManager.is_action_pressed("jump"):
		var col_normal := climb_ray.get_collision_normal()
		if col_normal.y > 0.7:  # Ledge
			_start_climb()

func _start_climb() -> void:
	is_climbing = true
	current_state = State.CLIMB
	velocity = Vector3.ZERO
	climb_timer = 0.6

func _process_climb(delta: float) -> void:
	velocity.y = climb_speed
	velocity.x = 0
	velocity.z = 0
	climb_timer -= delta
	if climb_timer <= 0.0:
		_end_climb()
		velocity.y = 2.0

func _end_climb() -> void:
	is_climbing = false
	climb_timer = 0.0

func _try_grapple() -> void:
	if is_grappling:
		return
	grapple_ray.force_raycast_update()
	if grapple_ray.is_colliding():
		var point := grapple_ray.get_collision_point()
		if global_position.distance_to(point) <= grapple_range:
			grapple_point = point
			is_grappling = true
			current_state = State.GRAPPLE
			grappled.emit()

func _process_grapple(delta: float) -> void:
	var to_point := grapple_point - global_position
	var dist := to_point.length()
	if dist < 1.5 or not InputManager.is_action_pressed("grapple"):
		_end_grapple()
		return
	var dir := to_point.normalized()
	velocity = dir * grapple_speed
	# Face the point
	look_at(Vector3(grapple_point.x, global_position.y, grapple_point.z), Vector3.UP)

func _end_grapple() -> void:
	is_grappling = false
	velocity.y = max(velocity.y, 3.0)

func _update_state(on_floor: bool) -> void:
	if current_state in [State.SLIDE, State.WALL_RUN, State.CLIMB, State.GRAPPLE, State.DEAD]:
		return
	if not on_floor:
		if velocity.y > 0.5:
			current_state = State.JUMP
		else:
			current_state = State.FALL
	elif velocity.length() < 0.5:
		current_state = State.IDLE

func take_damage(amount: float) -> void:
	health = max(0.0, health - amount)
	health_changed.emit(health)
	if health <= 0.0:
		die()

func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health)

func die() -> void:
	current_state = State.DEAD
	velocity = Vector3.ZERO
	died.emit()
	GameManager.on_player_died()

func get_speed() -> float:
	return Vector3(velocity.x, 0, velocity.z).length()
