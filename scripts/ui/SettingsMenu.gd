extends Control
## Settings Menu

@onready var master_slider: HSlider = $Panel/VBox/MasterVolume/Slider
@onready var music_slider: HSlider = $Panel/VBox/MusicVolume/Slider
@onready var sfx_slider: HSlider = $Panel/VBox/SFXVolume/Slider
@onready var quality_option: OptionButton = $Panel/VBox/Quality/Option
@onready var sensitivity_slider: HSlider = $Panel/VBox/Sensitivity/Slider
@onready var show_fps_check: CheckBox = $Panel/VBox/ShowFPS
@onready var back_button: Button = $Panel/VBox/BackButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_load_current_settings()
	if master_slider:
		master_slider.value_changed.connect(_on_master_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if quality_option:
		quality_option.item_selected.connect(_on_quality_selected)
	if sensitivity_slider:
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	if show_fps_check:
		show_fps_check.toggled.connect(_on_fps_toggled)
	if back_button:
		back_button.pressed.connect(_on_back)

func _load_current_settings() -> void:
	var s := SaveManager.settings
	if master_slider:
		master_slider.value = s.get("master_volume", 1.0) * 100.0
	if music_slider:
		music_slider.value = s.get("music_volume", 0.8) * 100.0
	if sfx_slider:
		sfx_slider.value = s.get("sfx_volume", 1.0) * 100.0
	if sensitivity_slider:
		sensitivity_slider.value = s.get("sensitivity", 1.0) * 100.0
	if show_fps_check:
		show_fps_check.button_pressed = s.get("show_fps", false)
	if quality_option:
		match s.get("quality", "medium"):
			"low": quality_option.selected = 0
			"medium": quality_option.selected = 1
			"high": quality_option.selected = 2

func _on_master_changed(value: float) -> void:
	SaveManager.update_setting("master_volume", value / 100.0)

func _on_music_changed(value: float) -> void:
	SaveManager.update_setting("music_volume", value / 100.0)

func _on_sfx_changed(value: float) -> void:
	SaveManager.update_setting("sfx_volume", value / 100.0)

func _on_quality_selected(index: int) -> void:
	var q := ["low", "medium", "high"][index]
	SaveManager.update_setting("quality", q)

func _on_sensitivity_changed(value: float) -> void:
	SaveManager.update_setting("sensitivity", value / 100.0)
	InputManager.update_settings()

func _on_fps_toggled(pressed: bool) -> void:
	SaveManager.update_setting("show_fps", pressed)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
