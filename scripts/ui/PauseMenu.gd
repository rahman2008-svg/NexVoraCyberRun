extends CanvasLayer
## Pause Menu Overlay

@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var settings_btn: Button = $Panel/VBox/SettingsButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.game_paused.connect(_on_paused)
	GameManager.game_resumed.connect(_on_resumed)
	if resume_btn:
		resume_btn.pressed.connect(_on_resume)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu)

func _on_paused() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_resumed() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume() -> void:
	GameManager.resume_game()

func _on_settings() -> void:
	# Could open settings overlay; for simplicity return later
	pass

func _on_menu() -> void:
	GameManager.return_to_menu()
