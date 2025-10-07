extends Node
class_name ClawInputController

const ClawRigSolver := preload("res://scripts/gameplay/claw_rig_solver.gd")

@export var solver: ClawRigSolver
@export var joystick: Node
@export var extend_button: BaseButton
@export var retract_button: BaseButton
@export_range(0.0, 1.0, 0.01) var smoothing: float = 0.15
@export_range(0.0, 0.5, 0.01) var dead_zone: float = 0.05

signal movement_input(vector: Vector2)
signal extend_pressed()
signal extend_released()
signal retract_pressed()

var _current_vector: Vector2 = Vector2.ZERO
var _is_ready: bool = false
var _joystick_callable: Callable = Callable()
var _movement_enabled: bool = true
var _extend_enabled: bool = true
var _retract_enabled: bool = true

func _ready() -> void:
    _bind_inputs()
    _is_ready = true

func _exit_tree() -> void:
    _unbind_inputs()
    _is_ready = false

func set_move_vector(vector: Vector2) -> void:
    if not _is_ready:
        return
    _forward_vector(vector)

func set_control_gates(movement: bool, extend: bool, retract: bool) -> void:
    _movement_enabled = movement
    _extend_enabled = extend
    _retract_enabled = retract
    if not _movement_enabled and solver:
        solver.set_move_vector(Vector2.ZERO)

func reset_control_gates() -> void:
    set_control_gates(true, true, true)

func _bind_inputs() -> void:
    if joystick and joystick.has_signal("vector_changed"):
        _joystick_callable = Callable(self, "_on_vector_changed")
        joystick.connect("vector_changed", _joystick_callable)
    if extend_button:
        extend_button.button_down.connect(_on_extend_pressed)
        extend_button.button_up.connect(_on_extend_released)
    if retract_button:
        retract_button.button_down.connect(_on_retract_pressed)

func _unbind_inputs() -> void:
    if joystick and joystick.has_signal("vector_changed") and _joystick_callable.is_valid() and joystick.is_connected("vector_changed", _joystick_callable):
        joystick.disconnect("vector_changed", _joystick_callable)
    if extend_button:
        if extend_button.button_down.is_connected(_on_extend_pressed):
            extend_button.button_down.disconnect(_on_extend_pressed)
        if extend_button.button_up.is_connected(_on_extend_released):
            extend_button.button_up.disconnect(_on_extend_released)
    if retract_button and retract_button.button_down.is_connected(_on_retract_pressed):
        retract_button.button_down.disconnect(_on_retract_pressed)
    _joystick_callable = Callable()

func _on_vector_changed(vector: Vector2) -> void:
    if not _is_ready:
        return
    _forward_vector(vector)

func _forward_vector(vector: Vector2) -> void:
    if solver == null:
        return
    if not _movement_enabled:
        solver.set_move_vector(Vector2.ZERO)
        return
    var applied: Vector2 = _apply_smoothing(_apply_dead_zone(vector))
    solver.set_move_vector(applied)
    movement_input.emit(applied)

func _apply_dead_zone(vector: Vector2) -> Vector2:
    if vector.length_squared() < dead_zone * dead_zone:
        return Vector2.ZERO
    return vector.limit_length(1.0)

func _apply_smoothing(target: Vector2) -> Vector2:
    var weight := clampf(1.0 - smoothing, 0.05, 1.0)
    _current_vector = _current_vector.lerp(target, weight)
    return _current_vector

func _on_extend_pressed() -> void:
    if not _extend_enabled:
        return
    if solver:
        solver.begin_lower()
    extend_pressed.emit()

func _on_extend_released() -> void:
    if not _extend_enabled:
        return
    if solver:
        solver.execute_grip()
    extend_released.emit()

func _on_retract_pressed() -> void:
    if not _retract_enabled:
        return
    if solver:
        solver.retract_to_idle()
    retract_pressed.emit()
