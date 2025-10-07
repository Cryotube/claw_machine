extends Node

const PersistenceService := preload("res://autoload/persistence_service.gd")

signal haptics_toggled(enabled: bool)
signal haptic_strength_changed(strength: float)
signal camera_sensitivity_changed(sensitivity: float)
signal invert_x_toggled(enabled: bool)
signal invert_y_toggled(enabled: bool)
signal subtitles_toggled(enabled: bool)
signal caption_size_changed(size: StringName)
signal audio_volume_changed(channel: StringName, value: float)
signal reduced_motion_toggled(enabled: bool)

static var _instance: Node

const CAPTION_SIZES: Array[StringName] = [
	StringName("small"),
	StringName("medium"),
	StringName("large"),
]

var safe_area_padding_portrait: Vector2 = Vector2(32, 48)
var safe_area_padding_landscape: Vector2 = Vector2(48, 32)

var tutorial_completed: bool = false
var _haptics_enabled: bool = true
var _haptic_strength: float = 1.0
var _camera_sensitivity: float = 1.0
var _invert_x: bool = false
var _invert_y: bool = false
var _subtitle_enabled: bool = false
var _caption_size: StringName = StringName("medium")
var _audio_master: float = 1.0
var _audio_music: float = 1.0
var _audio_sfx: float = 1.0
var _reduced_motion_enabled: bool = false

func _ready() -> void:
	_instance = self
	_load_from_persistence()

static func get_instance() -> Node:
	return _instance

func get_safe_padding(is_portrait: bool) -> Vector2:
	return safe_area_padding_portrait if is_portrait else safe_area_padding_landscape

func set_haptics_enabled(value: bool) -> void:
	var normalized := bool(value)
	if _haptics_enabled == normalized:
		return
	_haptics_enabled = normalized
	haptics_toggled.emit(_haptics_enabled)
	_persist_control_settings()

func is_haptics_enabled() -> bool:
	return _haptics_enabled

func set_haptic_strength(value: float) -> void:
	var normalized := clampf(value, 0.0, 1.0)
	if is_equal_approx(_haptic_strength, normalized):
		return
	_haptic_strength = normalized
	haptic_strength_changed.emit(_haptic_strength)
	_persist_control_settings()

func get_haptic_strength() -> float:
	return _haptic_strength

func set_camera_sensitivity(value: float) -> void:
	var clamped := clampf(value, 0.5, 2.0)
	if is_equal_approx(_camera_sensitivity, clamped):
		return
	_camera_sensitivity = clamped
	camera_sensitivity_changed.emit(_camera_sensitivity)
	_persist_control_settings()

func get_camera_sensitivity() -> float:
	return _camera_sensitivity

func set_invert_x_enabled(value: bool) -> void:
	var normalized := bool(value)
	if _invert_x == normalized:
		return
	_invert_x = normalized
	invert_x_toggled.emit(_invert_x)
	_persist_control_settings()

func is_invert_x_enabled() -> bool:
	return _invert_x

func set_invert_y_enabled(value: bool) -> void:
	var normalized := bool(value)
	if _invert_y == normalized:
		return
	_invert_y = normalized
	invert_y_toggled.emit(_invert_y)
	_persist_control_settings()

func is_invert_y_enabled() -> bool:
	return _invert_y

func set_subtitles_enabled(value: bool) -> void:
	var normalized := bool(value)
	if _subtitle_enabled == normalized:
		return
	_subtitle_enabled = normalized
	subtitles_toggled.emit(_subtitle_enabled)
	_persist_control_settings()

func are_subtitles_enabled() -> bool:
	return _subtitle_enabled

func set_caption_size(size: StringName) -> void:
	var normalized := size if CAPTION_SIZES.has(size) else StringName("medium")
	if _caption_size == normalized:
		return
	_caption_size = normalized
	caption_size_changed.emit(_caption_size)
	_persist_control_settings()

func get_caption_size() -> StringName:
	return _caption_size

func get_caption_size_options() -> Array[StringName]:
	return CAPTION_SIZES.duplicate()

func set_master_volume(value: float) -> void:
	var normalized := clampf(value, 0.0, 1.0)
	if is_equal_approx(_audio_master, normalized):
		return
	_audio_master = normalized
	audio_volume_changed.emit(StringName("master"), _audio_master)
	_persist_audio_settings()

func get_master_volume() -> float:
	return _audio_master

func set_music_volume(value: float) -> void:
	var normalized := clampf(value, 0.0, 1.0)
	if is_equal_approx(_audio_music, normalized):
		return
	_audio_music = normalized
	audio_volume_changed.emit(StringName("music"), _audio_music)
	_persist_audio_settings()

func get_music_volume() -> float:
	return _audio_music

func set_sfx_volume(value: float) -> void:
	var normalized := clampf(value, 0.0, 1.0)
	if is_equal_approx(_audio_sfx, normalized):
		return
	_audio_sfx = normalized
	audio_volume_changed.emit(StringName("sfx"), _audio_sfx)
	_persist_audio_settings()

func get_sfx_volume() -> float:
	return _audio_sfx

func set_reduced_motion_enabled(value: bool) -> void:
	var normalized := bool(value)
	if _reduced_motion_enabled == normalized:
		return
	_reduced_motion_enabled = normalized
	reduced_motion_toggled.emit(_reduced_motion_enabled)
	var persistence := PersistenceService.get_instance()
	if persistence and persistence.has_method("set_reduced_motion_enabled"):
		persistence.set_reduced_motion_enabled(_reduced_motion_enabled)

func is_reduced_motion_enabled() -> bool:
	return _reduced_motion_enabled

func mark_tutorial_complete(context: String = "settings") -> void:
	if tutorial_completed:
		return
	tutorial_completed = true
	var persistence := PersistenceService.get_instance()
	if persistence and persistence.has_method("set_tutorial_completion"):
		persistence.set_tutorial_completion(true, {"context": context})

func reset_tutorial_completion(context: String = "options") -> void:
	tutorial_completed = false
	var persistence := PersistenceService.get_instance()
	if persistence and persistence.has_method("set_tutorial_completion"):
		persistence.set_tutorial_completion(false, {"context": context})

func _persist_control_settings() -> void:
	var persistence := PersistenceService.get_instance()
	if persistence and persistence.has_method("set_control_settings"):
		persistence.set_control_settings({
			"haptics_enabled": _haptics_enabled,
			"haptic_strength": _haptic_strength,
			"camera_sensitivity": _camera_sensitivity,
			"invert_x": _invert_x,
			"invert_y": _invert_y,
			"subtitles_enabled": _subtitle_enabled,
			"caption_size": String(_caption_size),
		})

func _persist_audio_settings() -> void:
	var persistence := PersistenceService.get_instance()
	if persistence and persistence.has_method("set_audio_settings"):
		persistence.set_audio_settings({
			"master": _audio_master,
			"music": _audio_music,
			"sfx": _audio_sfx,
		})

func _load_from_persistence() -> void:
	var persistence := PersistenceService.get_instance()
	if persistence == null:
		return
	if persistence.has_method("get_tutorial_state"):
		var tutorial_state: Dictionary = persistence.get_tutorial_state()
		tutorial_completed = bool(tutorial_state.get("completed", false))
	if persistence.has_method("get_accessibility_state"):
		var accessibility: Dictionary = persistence.get_accessibility_state()
		_reduced_motion_enabled = bool(accessibility.get("reduced_motion", false))
	if persistence.has_method("get_control_settings"):
		var controls: Dictionary = persistence.get_control_settings()
		_haptics_enabled = bool(controls.get("haptics_enabled", true))
		_haptic_strength = clampf(float(controls.get("haptic_strength", 1.0)), 0.0, 1.0)
		_camera_sensitivity = clampf(float(controls.get("camera_sensitivity", 1.0)), 0.5, 2.0)
		_invert_x = bool(controls.get("invert_x", false))
		_invert_y = bool(controls.get("invert_y", false))
		_subtitle_enabled = bool(controls.get("subtitles_enabled", false))
		var caption_value := StringName(String(controls.get("caption_size", "medium")))
		_caption_size = caption_value if CAPTION_SIZES.has(caption_value) else StringName("medium")
	if persistence.has_method("get_audio_settings"):
		var audio: Dictionary = persistence.get_audio_settings()
		_audio_master = clampf(float(audio.get("master", 1.0)), 0.0, 1.0)
		_audio_music = clampf(float(audio.get("music", 1.0)), 0.0, 1.0)
		_audio_sfx = clampf(float(audio.get("sfx", 1.0)), 0.0, 1.0)
