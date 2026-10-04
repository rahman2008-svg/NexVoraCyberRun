extends Node
## InputManager - Handles keyboard, gamepad and touch input abstraction
## Autoload singleton

signal touch_joystick_moved(direction: Vector2)
signal touch_action_pressed(action: String)
signal touch_action_released(action: String)

var is_mobile: bool = false
var touch_controls_enabled: bool = true
var look_sensitivity: float = 1.0
var invert_y: bool = false

# Virtual joystick state
var joystick_direction: Vector2 = Vector2.ZERO
var is_joystick_active: bool = false

# Action states for touch
var touch_actions: Dictionary = {
	"jump": false,
	"sprint": false,
	"slide": false,
	"grapple": false,
	"pause": false
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	look_sensitivity = SaveManager.settings.get("sensitivity", 1.0)
	invert_y = SaveManager.settings.get("invert_y", false)
	print("[InputManager] Initialized. Mobile: ", is_mobile)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.toggle_pause()

func get_move_vector() -> Vector2:
	var input_dir := Vector2.ZERO
	
	# Keyboard / gamepad
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_back")
	
	# Override / blend with touch joystick
	if is_joystick_active and joystick_direction.length() > 0.1:
		input_dir = joystick_direction
	
	return input_dir.limit_length(1.0)

func is_action_just_pressed(action: String) -> bool:
	if Input.is_action_just_pressed(action):
		return true
	# Touch actions are edge-triggered via signals, but we can check state
	return false

func is_action_pressed(action: String) -> bool:
	if Input.is_action_pressed(action):
		return true
	return touch_actions.get(action, false)

func set_joystick(direction: Vector2) -> void:
	joystick_direction = direction
	is_joystick_active = direction.length() > 0.05
	touch_joystick_moved.emit(direction)

func set_touch_action(action: String, pressed: bool) -> void:
	if touch_actions.has(action):
		var was_pressed: bool = touch_actions[action]
		touch_actions[action] = pressed
		if pressed and not was_pressed:
			touch_action_pressed.emit(action)
		elif not pressed and was_pressed:
			touch_action_released.emit(action)

func get_look_delta(event: InputEvent) -> Vector2:
	var delta := Vector2.ZERO
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		delta = event.relative * look_sensitivity * 0.1
		if invert_y:
			delta.y = -delta.y
	elif event is InputEventScreenDrag:
		# For touch look (right side of screen usually)
		delta = event.relative * look_sensitivity * 0.15
		if invert_y:
			delta.y = -delta.y
	return delta

func update_settings() -> void:
	look_sensitivity = SaveManager.settings.get("sensitivity", 1.0)
	invert_y = SaveManager.settings.get("invert_y", false)
	touch_controls_enabled = SaveManager.settings.get("touch_layout", "default") != "hidden"
