extends Node

static var _instance: Node
var _last_event: StringName = StringName()

func _ready() -> void:
    _instance = self

static func get_instance() -> Node:
    return _instance

func play_event(event_name: StringName) -> void:
    # Placeholder for audio hook; intentionally empty for prototype.
    _last_event = event_name

func debug_get_last_event() -> StringName:
    return _last_event
