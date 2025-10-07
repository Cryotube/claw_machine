extends Node

const PersistenceService := preload("res://autoload/persistence_service.gd")

signal haptics_toggled(enabled: bool)
signal camera_sensitivity_changed(sensitivity: float)
signal reduced_motion_toggled(enabled: bool)

static var _instance: Node

var safe_area_padding_portrait: Vector2 = Vector2(32, 48)
var safe_area_padding_landscape: Vector2 = Vector2(48, 32)
var tutorial_completed: bool = false
var _haptics_enabled: bool = true
var _camera_sensitivity: float = 1.0
var _reduced_motion_enabled: bool = false

func set_haptics_enabled(value: bool) -> void:
	if _haptics_enabled == value:
		return
	_haptics_enabled = value
	haptics_toggled.emit(_haptics_enabled)

func is_haptics_enabled() -> bool:
	return _haptics_enabled

func set_camera_sensitivity(value: float) -> void:
	var clamped := clampf(value, 0.5, 2.0)
	if is_equal_approx(_camera_sensitivity, clamped):
		return
	_camera_sensitivity = clamped
	camera_sensitivity_changed.emit(_camera_sensitivity)

func get_camera_sensitivity() -> float:
	return _camera_sensitivity

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

func _ready() -> void:
	_instance = self
	var persistence := PersistenceService.get_instance()
	if persistence and persistence.has_method("get_tutorial_state"):
		var tutorial_state: Dictionary = persistence.get_tutorial_state()
		tutorial_completed = bool(tutorial_state.get("completed", false))
	if persistence and persistence.has_method("get_accessibility_state"):
		var accessibility: Dictionary = persistence.get_accessibility_state()
		_reduced_motion_enabled = bool(accessibility.get("reduced_motion", false))

static func get_instance() -> Node:
	return _instance

func get_safe_padding(is_portrait: bool) -> Vector2:
	return safe_area_padding_portrait if is_portrait else safe_area_padding_landscape

func mark_tutorial_complete(context: String = "settings") -> void:
	if tutorial_completed:
		return
	tutorial_completed = true
	var persistence := PersistenceService.get_instance()
	if persistence and persistence.has_method("set_tutorial_completion"):
		persistence.set_tutorial_completion(true, {"context": context})
