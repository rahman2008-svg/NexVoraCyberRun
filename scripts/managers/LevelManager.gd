extends Node3D
## LevelManager - Handles level-specific logic, checkpoints, missions

@export var level_name: String = "Test Arena"
@export var is_time_trial: bool = false
@export var target_time: float = 120.0

var level_time: float = 0.0
var is_active: bool = true

@onready var player: CharacterBody3D = $Player
@onready var spawn_point: Marker3D = $SpawnPoint

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.PLAYING
	if player and spawn_point:
		player.global_position = spawn_point.global_position
	print("[LevelManager] Level loaded: ", level_name)

func _process(delta: float) -> void:
	if is_active and GameManager.current_state == GameManager.GameState.PLAYING:
		level_time += delta

func respawn_player() -> void:
	if player and spawn_point:
		player.global_position = spawn_point.global_position
		player.velocity = Vector3.ZERO
		player.health = player.max_health
		player.current_state = player.State.IDLE
		print("[LevelManager] Player respawned")

func on_checkpoint(checkpoint_id: String) -> void:
	GameManager.reach_checkpoint(checkpoint_id)
	# Update spawn to last checkpoint if desired
	# spawn_point.global_position = ...

func complete_level() -> void:
	is_active = false
	GameManager.complete_mission(level_name)
	SaveManager.complete_mission(level_name.to_lower().replace(" ", "_"), level_time)
	SaveManager.add_xp(100)
	SaveManager.add_credits(50)
