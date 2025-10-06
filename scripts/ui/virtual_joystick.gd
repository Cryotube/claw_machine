extends Control
class_name VirtualJoystick

signal vector_changed(vector: Vector2)

@export_range(0.0, 1.0, 0.01) var dead_zone: float = 0.08
@export_range(0.1, 2.0, 0.01) var sensitivity: float = 1.0

var _current_vector: Vector2 = Vector2.ZERO
var _is_active: bool = false
var _touch_id: int = -1
var _center: Vector2 = Vector2.ZERO
var _radius: float = 1.0

@onready var _handle: Control = %Handle
@onready var _background: Control = $Background

func _ready() -> void:
    set_process_unhandled_input(true)
    _refresh_geometry()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        _refresh_geometry()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if _touch_id == -1:
                _touch_id = touch.index
                _is_active = true
                _update_vector(touch.position)
        elif touch.index == _touch_id:
            _touch_id = -1
            _is_active = false
            _set_vector(Vector2.ZERO)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == _touch_id:
            _update_vector(drag.position)

func set_input_vector(vector: Vector2) -> void:
    _set_vector(vector)

func _update_vector(position: Vector2) -> void:
    var local_position := _to_local(position)
    if _radius <= 0.0:
        return
    var local: Vector2 = local_position / _radius
    _set_vector(local * sensitivity)

func _set_vector(vector: Vector2) -> void:
    var adjusted: Vector2 = vector.limit_length(1.0)
    if adjusted.length_squared() < dead_zone * dead_zone:
        adjusted = Vector2.ZERO
    if _current_vector.is_equal_approx(adjusted):
        return
    _current_vector = adjusted
    _update_handle_position()
    vector_changed.emit(_current_vector)

func reset() -> void:
    _touch_id = -1
    _is_active = false
    _set_vector(Vector2.ZERO)

func _refresh_geometry() -> void:
    var rect := _background.get_global_rect()
    _center = rect.position + rect.size * 0.5
    _radius = min(rect.size.x, rect.size.y) * 0.5
    _update_handle_position()

func _to_local(position: Vector2) -> Vector2:
    return position - _center

func _update_handle_position() -> void:
    if _handle == null:
        return
    var offset := _current_vector * _radius * 0.6
    _handle.global_position = _center + offset - _handle.size * 0.5
