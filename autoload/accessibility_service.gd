extends Node

const PersistenceService := preload("res://autoload/persistence_service.gd")

signal colorblind_palette_changed(palette_id: StringName)

static var _instance: Node

var _current_palette: StringName = StringName("default")

func _ready() -> void:
	_instance = self
	var persistence := PersistenceService.get_instance()
	if persistence and persistence.has_method("get_accessibility_state"):
		var state: Dictionary = persistence.get_accessibility_state()
		var stored := StringName(String(state.get("palette", _current_palette)))
		_current_palette = stored
	colorblind_palette_changed.emit(_current_palette)

static func get_instance() -> Node:
	return _instance

func set_colorblind_palette(palette_id: StringName) -> void:
	if palette_id == _current_palette:
		return
	_current_palette = palette_id
	colorblind_palette_changed.emit(_current_palette)
	var persistence := PersistenceService.get_instance()
	if persistence and persistence.has_method("set_colorblind_palette"):
		persistence.set_colorblind_palette(_current_palette)

func get_colorblind_palette() -> StringName:
	return _current_palette
