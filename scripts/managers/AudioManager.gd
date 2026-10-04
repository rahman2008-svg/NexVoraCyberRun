extends Node
## AudioManager - Handles all audio playback and settings
## Autoload singleton

signal volume_changed(bus: String, value: float)

const MASTER_BUS := "Master"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const UI_BUS := "UI"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var ui_volume: float = 0.9

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_setup_players()
	print("[AudioManager] Initialized")

func _setup_buses() -> void:
	# Ensure buses exist (Godot creates Master by default)
	# Additional buses can be configured in project settings or here
	pass

func _setup_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = MUSIC_BUS
	music_player.name = "MusicPlayer"
	add_child(music_player)
	
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		player.name = "SFXPlayer%d" % i
		add_child(player)
		sfx_players.append(player)

func play_music(stream: AudioStream, fade_in: float = 0.5) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	music_player.play()

func stop_music(fade_out: float = 0.5) -> void:
	music_player.stop()

func play_sfx(stream: AudioStream, volume_scale: float = 1.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume * master_volume * volume_scale)
			player.pitch_scale = pitch
			player.play()
			return
	# All busy - reuse first
	sfx_players[0].stream = stream
	sfx_players[0].volume_db = linear_to_db(sfx_volume * master_volume * volume_scale)
	sfx_players[0].pitch_scale = pitch
	sfx_players[0].play()

func play_ui(stream: AudioStream) -> void:
	play_sfx(stream, ui_volume)

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(master_volume))
	volume_changed.emit(MASTER_BUS, master_volume)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
	volume_changed.emit(MUSIC_BUS, music_volume)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	volume_changed.emit(SFX_BUS, sfx_volume)

func set_ui_volume(value: float) -> void:
	ui_volume = clampf(value, 0.0, 1.0)
	volume_changed.emit(UI_BUS, ui_volume)

func apply_settings(settings: Dictionary) -> void:
	if settings.has("master_volume"):
		set_master_volume(settings.master_volume)
	if settings.has("music_volume"):
		set_music_volume(settings.music_volume)
	if settings.has("sfx_volume"):
		set_sfx_volume(settings.sfx_volume)
	if settings.has("ui_volume"):
		set_ui_volume(settings.ui_volume)
