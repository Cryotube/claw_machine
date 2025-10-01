extends Node
class_name GutTest

var _autofree_nodes: Array[Node] = []
var _current_test: String = ""
var _current_failures: Array[String] = []

func _prepare_test(test_name: String) -> void:
    _current_test = test_name
    _current_failures.clear()

func _finish_test() -> void:
    _cleanup_autofree()
    _current_test = ""

func add_child_autofree(node: Node) -> void:
    add_child(node)
    _autofree_nodes.append(node)

func wait_frames(count: int) -> void:
    for _i in count:
        await get_tree().process_frame

func assert_true(condition: bool, message: String = "") -> void:
    if condition:
        return
    _record_failure(message if message != "" else "Expected condition to be true")

func assert_eq(a, b, message: String = "") -> void:
    if a == b:
        return
    var msg := message if message != "" else "Expected %s == %s" % [str(a), str(b)]
    _record_failure(msg)

func assert_has(container, value, message: String = "") -> void:
    var has_value := false
    if container is Array:
        has_value = value in container
    elif container is Dictionary:
        has_value = container.has(value)
    if not has_value:
        var msg := message if message != "" else "Expected container to include %s" % str(value)
        _record_failure(msg)

func before_each() -> void:
    pass

func after_each() -> void:
    pass

func _record_failure(message: String) -> void:
    var label := _current_test if _current_test != "" else "(unnamed)"
    var formatted := "%s: %s" % [label, message]
    push_error(formatted)
    _current_failures.append(formatted)

func _cleanup_autofree() -> void:
    for node in _autofree_nodes:
        if node and node.is_inside_tree():
            node.queue_free()
    _autofree_nodes.clear()

func _has_failures() -> bool:
    return not _current_failures.is_empty()

func _get_failures() -> Array[String]:
    return _current_failures.duplicate()
