extends Node

const SAVE_PATH := "user://claw_machine_save.json"
const SAVE_DEBOUNCE_SEC := 0.35
const CURRENT_SCHEMA_VERSION := 1

static var _instance: Node

var _state: Dictionary = {}
var _pending_save: bool = false
var _save_timer: Timer
var _override_save_path: String = ""

func _ready() -> void:
	_instance = self
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	add_child(_save_timer)
	_save_timer.timeout.connect(_flush_pending_save)
	_load_from_disk()

static func get_instance() -> Node:
	return _instance

func is_tutorial_completed() -> bool:
	var tutorial: Dictionary = _state.get("tutorial", {})
	return bool(tutorial.get("completed", false))

func get_tutorial_state() -> Dictionary:
	var tutorial: Dictionary = _state.get("tutorial", {})
	return tutorial.duplicate(true)

func set_tutorial_completion(completed: bool, metadata: Dictionary = {}) -> void:
	var tutorial: Dictionary = _state.get("tutorial", {})
	tutorial["completed"] = completed
	if completed:
		var meta: Dictionary = metadata.duplicate(true)
		var completed_at: int = int(meta.get("completed_at_ms", Time.get_ticks_msec()))
		tutorial["completed_at_ms"] = completed_at
		var context_value = meta.get("context", "unknown")
		if context_value != null:
			tutorial["context"] = String(context_value)
	else:
		tutorial["completed_at_ms"] = 0
		if tutorial.has("context"):
			tutorial.erase("context")
	_state["tutorial"] = tutorial
	queue_save()

func is_reduced_motion_enabled() -> bool:
	var accessibility: Dictionary = _state.get("accessibility", {})
	return bool(accessibility.get("reduced_motion", false))

func set_reduced_motion_enabled(enabled: bool) -> void:
	var accessibility: Dictionary = _state.get("accessibility", {})
	accessibility["reduced_motion"] = enabled
	_state["accessibility"] = accessibility
	queue_save()

func get_accessibility_state() -> Dictionary:
	var accessibility: Dictionary = _state.get("accessibility", {})
	return accessibility.duplicate(true)

func get_state() -> Dictionary:
	return _state.duplicate(true)

func replace_state(state: Dictionary) -> void:
	_state = state.duplicate(true)
	_apply_defaults()
	queue_save()

func queue_save(delay_sec: float = SAVE_DEBOUNCE_SEC) -> void:
	if _save_timer == null:
		return
	_save_timer.stop()
	_pending_save = true
	var interval: float = max(delay_sec, 0.01)
	_save_timer.start(interval)

func flush_now() -> void:
	_flush_pending_save()

func set_override_save_path(path: String) -> void:
	_override_save_path = path

func _load_from_disk() -> void:
	var path: String = _effective_save_path()
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file:
			var content: String = file.get_as_text()
			var parsed: Variant = JSON.parse_string(content)
			if parsed is Dictionary:
				_state = parsed
	_apply_defaults()

func _apply_defaults() -> void:
	if _state.is_empty():
		_state = {}
	var meta: Dictionary = _state.get("meta", {})
	meta["schema_version"] = CURRENT_SCHEMA_VERSION
	_state["meta"] = meta
	var tutorial: Dictionary = _state.get("tutorial", {})
	tutorial["completed"] = bool(tutorial.get("completed", false))
	if tutorial.get("completed", false):
		tutorial["completed_at_ms"] = int(tutorial.get("completed_at_ms", Time.get_ticks_msec()))
	else:
		tutorial["completed_at_ms"] = 0
		if tutorial.has("context"):
			tutorial.erase("context")
	_state["tutorial"] = tutorial
	var accessibility: Dictionary = _state.get("accessibility", {})
	accessibility["reduced_motion"] = bool(accessibility.get("reduced_motion", false))
	_state["accessibility"] = accessibility

func _flush_pending_save() -> void:
	if not _pending_save:
		return
	_pending_save = false
	var path: String = _effective_save_path()
	var json: String = JSON.stringify(_state, "  ", false)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json)
	else:
		push_warning("PersistenceService: Failed to open %s for writing" % path)

func _effective_save_path() -> String:
	return _override_save_path if _override_save_path != "" else SAVE_PATH
