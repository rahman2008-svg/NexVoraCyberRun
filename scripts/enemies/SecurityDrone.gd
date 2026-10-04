extends CharacterBody3D
## Security Drone AI - Patrols and chases the player

class_name SecurityDrone

enum AIState { PATROL, CHASE, ATTACK, RETURN }

@export var move_speed: float = 4.5
@export var chase_speed: float = 7.0
@export var detection_range: float = 22.0
@export var attack_range: float = 8.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.5
@export var max_health: float = 50.0

var health: float = 50.0
var current_state: AIState = AIState.PATROL
var player: Node3D = null
var attack_timer: float = 0.0
var patrol_origin: Vector3
var patrol_target: Vector3
var patrol_radius: float = 12.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var detection_area: Area3D = $DetectionArea

func _ready() -> void:
	health = max_health
	patrol_origin = global_position
	_pick_new_patrol_target()
	add_to_group("enemies")
	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	
	attack_timer = max(0.0, attack_timer - delta)
	
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		current_state = AIState.PATROL
		return
	
	var dist_to_player := global_position.distance_to(player.global_position)
	
	match current_state:
		AIState.PATROL:
			_process_patrol(delta)
			if dist_to_player < detection_range:
				current_state = AIState.CHASE
		AIState.CHASE:
			_process_chase(delta, dist_to_player)
			if dist_to_player > detection_range * 1.4:
				current_state = AIState.RETURN
			elif dist_to_player < attack_range:
				current_state = AIState.ATTACK
		AIState.ATTACK:
			_process_attack(delta, dist_to_player)
			if dist_to_player > attack_range * 1.3:
				current_state = AIState.CHASE
		AIState.RETURN:
			_process_return(delta)
			if global_position.distance_to(patrol_origin) < 2.0:
				current_state = AIState.PATROL
			elif dist_to_player < detection_range * 0.8:
				current_state = AIState.CHASE
	
	# Hover effect
	global_position.y = patrol_origin.y + sin(Time.get_ticks_msec() * 0.003) * 0.3
	
	move_and_slide()

func _process_patrol(delta: float) -> void:
	var dir := (patrol_target - global_position).normalized()
	dir.y = 0
	velocity = dir * move_speed
	if global_position.distance_to(patrol_target) < 1.5:
		_pick_new_patrol_target()
	_look_at_direction(dir)

func _process_chase(delta: float, dist: float) -> void:
	var dir := (player.global_position - global_position).normalized()
	dir.y = 0
	velocity = dir * chase_speed
	_look_at_direction(dir)

func _process_attack(delta: float, dist: float) -> void:
	velocity = Vector3.ZERO
	_look_at_direction((player.global_position - global_position).normalized())
	if attack_timer <= 0.0:
		_perform_attack()
		attack_timer = attack_cooldown

func _process_return(delta: float) -> void:
	var dir := (patrol_origin - global_position).normalized()
	dir.y = 0
	velocity = dir * move_speed
	_look_at_direction(dir)

func _perform_attack() -> void:
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage)
		print("[Drone] Attacked player for ", attack_damage)

func _pick_new_patrol_target() -> void:
	var angle := randf() * TAU
	var dist := randf_range(3.0, patrol_radius)
	patrol_target = patrol_origin + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _look_at_direction(dir: Vector3) -> void:
	if dir.length() > 0.1:
		var target_pos := global_position + dir
		look_at(Vector3(target_pos.x, global_position.y, target_pos.z), Vector3.UP)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	# Simple death - remove
	SaveManager.add_credits(10)
	SaveManager.add_xp(25)
	queue_free()
	print("[Drone] Destroyed")
