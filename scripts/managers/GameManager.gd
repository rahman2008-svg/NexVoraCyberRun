extends Node
## GameManager - Central game state and scene management
## Autoload singleton

signal game_started
signal game_paused
signal game_resumed
signal mission_completed(mission_id: String)
signal player_died
signal checkpoint_reached(checkpoint_id: String)

enum GameState { MENU, PLAYING, PAUSED, MISSION_COMPLETE, GAME_OVER }

var current_state: GameState = GameState.MENU
var current_level: String = ""
var current_mission: Dictionary = {}
var is_free_roam: bool = false
var play_time: float = 0.0
var score: int = 0
var checkpoints_reached: Array[String] = []

# Quality settings
var quality_preset: String = "medium"  # low, medium, high
var target_fps: int = 60
var shadows_enabled: bool = true
var reflections_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] Initialized - NexVora CyberRun v1.0.0")

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		play_time += delta

func start_game(level_path: String = "res://scenes/levels/TestArena.tscn", free_roam: bool = false) -> void:
	current_level = level_path
	is_free_roam = free_roam
	checkpoints_reached.clear()
	score = 0
	play_time = 0.0
	current_state = GameState.PLAYING
	get_tree().change_scene_to_file(level_path)
	game_started.emit()
	print("[GameManager] Game started: ", level_path)

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit()

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		game_resumed.emit()

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()

func return_to_menu() -> void:
	current_state = GameState.MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func complete_mission(mission_id: String) -> void:
	current_state = GameState.MISSION_COMPLETE
	mission_completed.emit(mission_id)
	SaveManager.unlock_achievement("mission_" + mission_id)
	SaveManager.save_game()

func on_player_died() -> void:
	current_state = GameState.GAME_OVER
	player_died.emit()

func reach_checkpoint(checkpoint_id: String) -> void:
	if checkpoint_id not in checkpoints_reached:
		checkpoints_reached.append(checkpoint_id)
		checkpoint_reached.emit(checkpoint_id)
		print("[GameManager] Checkpoint reached: ", checkpoint_id)

func add_score(points: int) -> void:
	score += points

func set_quality(preset: String) -> void:
	quality_preset = preset
	match preset:
		"low":
			target_fps = 30
			shadows_enabled = false
			reflections_enabled = false
			Engine.max_fps = 30
		"medium":
			target_fps = 45
			shadows_enabled = true
			reflections_enabled = false
			Engine.max_fps = 45
		"high":
			target_fps = 60
			shadows_enabled = true
			reflections_enabled = true
			Engine.max_fps = 60
	print("[GameManager] Quality set to: ", preset)

func get_play_time_formatted() -> String:
	var minutes := int(play_time) / 60
	var seconds := int(play_time) % 60
	return "%02d:%02d" % [minutes, seconds]
