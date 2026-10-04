extends Node
## SaveManager - Handles save/load of progress, settings, achievements
## Autoload singleton

const SAVE_PATH := "user://nexvora_save.json"
const SETTINGS_PATH := "user://nexvora_settings.json"

signal save_completed
signal load_completed
signal achievement_unlocked(id: String)

var player_data: Dictionary = {
	"player_name": "Runner",
	"level": 1,
	"xp": 0,
	"credits": 0,
	"unlocked_outfits": ["default"],
	"current_outfit": "default",
	"missions_completed": [],
	"achievements": [],
	"best_times": {},
	"total_play_time": 0.0
}

var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"ui_volume": 0.9,
	"quality": "medium",
	"sensitivity": 1.0,
	"invert_y": false,
	"show_fps": false,
	"touch_layout": "default",
	"language": "en"
}

var default_achievements: Dictionary = {
	"first_run": {"name": "First Steps", "desc": "Complete your first run", "unlocked": false},
	"wall_master": {"name": "Wall Master", "desc": "Wall-run for 30 seconds total", "unlocked": false},
	"speed_demon": {"name": "Speed Demon", "desc": "Reach 20 m/s", "unlocked": false},
	"drone_hunter": {"name": "Drone Hunter", "desc": "Destroy 10 security drones", "unlocked": false},
	"mission_01": {"name": "Rooftop Runner", "desc": "Complete Mission 01", "unlocked": false},
	"collector": {"name": "Collector", "desc": "Unlock 5 outfits", "unlocked": false},
	"survivor": {"name": "Survivor", "desc": "Survive 5 minutes in free roam", "unlocked": false}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	load_game()
	print("[SaveManager] Initialized")

func save_game() -> void:
	player_data["total_play_time"] = GameManager.play_time + player_data.get("total_play_time", 0.0)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(player_data, "\t"))
		file.close()
		save_completed.emit()
		print("[SaveManager] Game saved")
	else:
		push_error("[SaveManager] Failed to save game")

func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json := JSON.new()
			var err := json.parse(file.get_as_text())
			file.close()
			if err == OK:
				player_data = json.data
				load_completed.emit()
				print("[SaveManager] Game loaded")
			else:
				push_error("[SaveManager] Failed to parse save file")
	else:
		print("[SaveManager] No save file found, using defaults")

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()
		print("[SaveManager] Settings saved")

func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var json := JSON.new()
			var err := json.parse(file.get_as_text())
			file.close()
			if err == OK:
				settings = json.data
				AudioManager.apply_settings(settings)
				GameManager.set_quality(settings.get("quality", "medium"))
				print("[SaveManager] Settings loaded")
	else:
		save_settings()

func unlock_achievement(id: String) -> void:
	if id not in player_data["achievements"]:
		player_data["achievements"].append(id)
		achievement_unlocked.emit(id)
		save_game()
		print("[SaveManager] Achievement unlocked: ", id)

func has_achievement(id: String) -> bool:
	return id in player_data["achievements"]

func add_xp(amount: int) -> void:
	player_data["xp"] += amount
	# Simple level up every 1000 XP
	var new_level := 1 + int(player_data["xp"] / 1000)
	if new_level > player_data["level"]:
		player_data["level"] = new_level
		print("[SaveManager] Level up! Now level ", new_level)
	save_game()

func add_credits(amount: int) -> void:
	player_data["credits"] += amount
	save_game()

func unlock_outfit(outfit_id: String) -> void:
	if outfit_id not in player_data["unlocked_outfits"]:
		player_data["unlocked_outfits"].append(outfit_id)
		if player_data["unlocked_outfits"].size() >= 5:
			unlock_achievement("collector")
		save_game()

func set_outfit(outfit_id: String) -> void:
	if outfit_id in player_data["unlocked_outfits"]:
		player_data["current_outfit"] = outfit_id
		save_game()

func complete_mission(mission_id: String, time: float) -> void:
	if mission_id not in player_data["missions_completed"]:
		player_data["missions_completed"].append(mission_id)
	var best: float = player_data["best_times"].get(mission_id, 999999.0)
	if time < best:
		player_data["best_times"][mission_id] = time
	unlock_achievement("mission_" + mission_id)
	save_game()

func update_setting(key: String, value: Variant) -> void:
	settings[key] = value
	save_settings()
	if key in ["master_volume", "music_volume", "sfx_volume", "ui_volume"]:
		AudioManager.apply_settings(settings)
	elif key == "quality":
		GameManager.set_quality(value)
