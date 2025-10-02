extends Resource
class_name AnalyticsConfigResource

@export var schema_version: StringName = StringName("v1")
@export var flush_batch_size: int = 5
@export var max_buffer_size: int = 50
@export var flush_interval_sec: float = 2.5
@export var local_log_path: String = "user://analytics.log"

func get_schema_version() -> StringName:
    return schema_version

func get_flush_batch_size() -> int:
    return max(flush_batch_size, 1)

func get_max_buffer_size() -> int:
    return max(max_buffer_size, 1)

func get_flush_interval_sec() -> float:
    return max(flush_interval_sec, 0.1)

func get_local_log_path() -> String:
    return local_log_path
