extends Node

const Settings := preload("res://autoload/settings.gd")

static var _instance: Node
var _last_event: StringName = StringName()
var _master_volume: float = 1.0
var _music_volume: float = 1.0
var _sfx_volume: float = 1.0
var _haptic_strength: float = 1.0

func _ready() -> void:
	_instance = self
	var settings := Settings.get_instance()
	if settings:
		settings.audio_volume_changed.connect(_on_audio_volume_changed)
		settings.haptic_strength_changed.connect(_on_haptic_strength_changed)
		_master_volume = settings.get_master_volume()
		_music_volume = settings.get_music_volume()
		_sfx_volume = settings.get_sfx_volume()
		_haptic_strength = settings.get_haptic_strength()
	_apply_volume(StringName("master"), _master_volume)
	_apply_volume(StringName("music"), _music_volume)
	_apply_volume(StringName("sfx"), _sfx_volume)

static func get_instance() -> Node:
	return _instance

func play_event(event_name: StringName) -> void:
	# Placeholder for audio hook; intentionally empty for prototype.
	_last_event = event_name

func debug_get_last_event() -> StringName:
	return _last_event

func get_haptic_strength() -> float:
	return _haptic_strength

func _on_audio_volume_changed(channel: StringName, value: float) -> void:
	match channel:
		StringName("master"):
			_master_volume = value
		StringName("music"):
			_music_volume = value
		StringName("sfx"):
			_sfx_volume = value
	_apply_volume(channel, value)

func _on_haptic_strength_changed(strength: float) -> void:
	_haptic_strength = clampf(strength, 0.0, 1.0)

func _apply_volume(channel: StringName, value: float) -> void:
	var bus_name := ""
	match channel:
		StringName("master"):
			bus_name = "Master"
		StringName("music"):
			bus_name = "Music"
		StringName("sfx"):
			bus_name = "SFX"
		_:
			return
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var normalized := clampf(value, 0.0, 1.0)
	var db := linear_to_db(max(normalized, 0.001))
	AudioServer.set_bus_volume_db(bus_index, db)
