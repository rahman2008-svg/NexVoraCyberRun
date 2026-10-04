extends CanvasLayer
## In-game HUD

@onready var health_bar: ProgressBar = $MarginContainer/VBox/HealthBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBox/StaminaBar
@onready var speed_label: Label = $MarginContainer/VBox/SpeedLabel
@onready var time_label: Label = $TopRight/TimeLabel
@onready var score_label: Label = $TopRight/ScoreLabel
@onready var fps_label: Label = $TopRight/FPSLabel
@onready var crosshair: Label = $Center/Crosshair

var player: PlayerController = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player") as PlayerController
	if player:
		player.health_changed.connect(_on_health_changed)
		player.stamina_changed.connect(_on_stamina_changed)
		_on_health_changed(player.health)
		_on_stamina_changed(player.stamina)
	fps_label.visible = SaveManager.settings.get("show_fps", false)

func _process(_delta: float) -> void:
	if player and is_instance_valid(player):
		speed_label.text = "SPD: %.1f m/s" % player.get_speed()
	time_label.text = GameManager.get_play_time_formatted()
	score_label.text = "SCORE: %d" % GameManager.score
	if fps_label.visible:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _on_health_changed(value: float) -> void:
	if health_bar:
		health_bar.value = value

func _on_stamina_changed(value: float) -> void:
	if stamina_bar:
		stamina_bar.value = value
