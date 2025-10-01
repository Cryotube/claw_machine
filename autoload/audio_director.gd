extends Node

static var _instance: Node

func _ready() -> void:
    _instance = self

static func get_instance() -> Node:
    return _instance

func play_event(event_name: StringName) -> void:
    # Placeholder for audio hook; intentionally empty for prototype.
    pass
