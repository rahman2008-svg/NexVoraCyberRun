extends Control
## Main Menu Controller

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var free_roam_button: Button = $VBoxContainer/FreeRoamButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.MENU
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	version_label.text = "v1.0.0 | NexVora Lab’s Ofc"
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if free_roam_button:
		free_roam_button.pressed.connect(_on_free_roam_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	print("[MainMenu] Ready")

func _on_play_pressed() -> void:
	GameManager.start_game("res://scenes/levels/TestArena.tscn", false)

func _on_free_roam_pressed() -> void:
	GameManager.start_game("res://scenes/levels/TestArena.tscn", true)

func _on_settings_pressed() -> void:
	# For now toggle a simple settings panel or change scene
	get_tree().change_scene_to_file("res://scenes/ui/SettingsMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
