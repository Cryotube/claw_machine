extends Node

static var _instance: Node

var _events: Array[Dictionary] = []
var _schema_version: StringName = StringName("v1")
var _flush_batch_size: int = 5
var _max_buffer_size: int = 50
var _flush_interval_sec: float = 2.5
var _local_log_path: String = "user://analytics.log"

func _ready() -> void:
    _instance = self

static func get_instance() -> Node:
    return _instance

func configure(config: Resource) -> void:
    if config == null:
        return
    if config.has_method("get_schema_version"):
        _schema_version = StringName(config.get_schema_version())
    elif config.has_method("get"):
        _schema_version = StringName(config.get("schema_version"))
    if config.has_method("get_flush_batch_size"):
        _flush_batch_size = max(config.get_flush_batch_size(), 1)
    elif config.has_method("get"):
        _flush_batch_size = max(int(config.get("flush_batch_size")), 1)
    if config.has_method("get_max_buffer_size"):
        _max_buffer_size = max(config.get_max_buffer_size(), 1)
    elif config.has_method("get"):
        _max_buffer_size = max(int(config.get("max_buffer_size")), 1)
    if config.has_method("get_flush_interval_sec"):
        _flush_interval_sec = max(config.get_flush_interval_sec(), 0.1)
    elif config.has_method("get"):
        _flush_interval_sec = max(float(config.get("flush_interval_sec")), 0.1)
    if config.has_method("get_local_log_path"):
        _local_log_path = String(config.get_local_log_path())
    elif config.has_method("get"):
        _local_log_path = String(config.get("local_log_path"))

func log_event(event_name: StringName, payload: Dictionary) -> void:
    if _events.size() >= _max_buffer_size:
        _events.pop_front()
    _events.append({
        "event": event_name,
        "payload": payload.duplicate(true),
    })

func clear_events() -> void:
    _events.clear()

func debug_get_events() -> Array[Dictionary]:
    return _events.duplicate(true)

func get_configuration() -> Dictionary:
    return {
        "schema_version": _schema_version,
        "flush_batch_size": _flush_batch_size,
        "max_buffer_size": _max_buffer_size,
        "flush_interval_sec": _flush_interval_sec,
        "local_log_path": _local_log_path,
    }
