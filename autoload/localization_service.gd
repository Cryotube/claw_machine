extends Node

static var _instance: Node

var _strings: Dictionary = {
    StringName("order_salmon_nigiri"): "Salmon Nigiri",
    StringName("order_tuna_roll"): "Tuna Roll",
    StringName("tutorial_hint_default"): "Serve quickly to keep customers happy!"
}

func _ready() -> void:
    _instance = self

static func get_instance() -> Node:
    return _instance

func get_text(key: StringName) -> String:
    if key in _strings:
        return _strings[key]
    return String(key)

func set_locale_dictionary(strings: Dictionary) -> void:
    _strings = strings.duplicate(true)
