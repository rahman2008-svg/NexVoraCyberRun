extends CanvasLayer
## Mobile Touch Controls - Virtual Joystick + Action Buttons

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var jump_btn: Button = $Actions/JumpButton
@onready var sprint_btn: Button = $Actions/SprintButton
@onready var slide_btn: Button = $Actions/SlideButton
@onready var grapple_btn: Button = $Actions/GrappleButton
@onready var pause_btn: Button = $PauseButton

var joystick_active: bool = false
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_touch_index: int = -1
var max_joystick_distance: float = 60.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = InputManager.is_mobile or InputManager.touch_controls_enabled
	# Also show when emulating touch from mouse in editor
	if OS.has_feature("editor"):
		visible = true
	
	if jump_btn:
		jump_btn.button_down.connect(func(): InputManager.set_touch_action("jump", true))
		jump_btn.button_up.connect(func(): InputManager.set_touch_action("jump", false))
	if sprint_btn:
		sprint_btn.button_down.connect(func(): InputManager.set_touch_action("sprint", true))
		sprint_btn.button_up.connect(func(): InputManager.set_touch_action("sprint", false))
	if slide_btn:
		slide_btn.button_down.connect(func(): InputManager.set_touch_action("slide", true))
		slide_btn.button_up.connect(func(): InputManager.set_touch_action("slide", false))
	if grapple_btn:
		grapple_btn.button_down.connect(func(): InputManager.set_touch_action("grapple", true))
		grapple_btn.button_up.connect(func(): InputManager.set_touch_action("grapple", false))
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_pressed)

func _on_pause_pressed() -> void:
	GameManager.toggle_pause()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	# Mouse emulation for testing
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var fake_touch := InputEventScreenTouch.new()
		fake_touch.position = event.position
		fake_touch.pressed = event.pressed
		fake_touch.index = 0
		_handle_touch(fake_touch)
	elif event is InputEventMouseMotion and joystick_active:
		var fake_drag := InputEventScreenDrag.new()
		fake_drag.position = event.position
		fake_drag.index = 0
		_handle_drag(fake_drag)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Check if touch is in left half for joystick
		if event.position.x < get_viewport().get_visible_rect().size.x * 0.45:
			joystick_active = true
			joystick_touch_index = event.index
			joystick_origin = event.position
			joystick_base.global_position = event.position - joystick_base.size / 2
			joystick_base.visible = true
	else:
		if event.index == joystick_touch_index:
			joystick_active = false
			joystick_touch_index = -1
			InputManager.set_joystick(Vector2.ZERO)
			joystick_knob.position = (joystick_base.size - joystick_knob.size) / 2
			# Optional: hide base when released
			# joystick_base.visible = false

func _handle_drag(event: InputEventScreenDrag) -> void:
	if not joystick_active or event.index != joystick_touch_index:
		return
	var delta := event.position - joystick_origin
	var length := delta.length()
	if length > max_joystick_distance:
		delta = delta.normalized() * max_joystick_distance
	joystick_knob.position = (joystick_base.size - joystick_knob.size) / 2 + delta
	var direction := delta / max_joystick_distance
	# Invert Y for game coordinates (up is negative Y in 2D input usually)
	InputManager.set_joystick(Vector2(direction.x, -direction.y))
