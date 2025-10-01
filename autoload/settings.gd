extends Node

static var _instance: Node

var safe_area_padding_portrait: Vector2 = Vector2(32, 48)
var safe_area_padding_landscape: Vector2 = Vector2(48, 32)

func _ready() -> void:
    _instance = self

static func get_instance() -> Node:
    return _instance

func get_safe_padding(is_portrait: bool) -> Vector2:
    return safe_area_padding_portrait if is_portrait else safe_area_padding_landscape
