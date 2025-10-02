extends "res://tests/gut/gut_stub.gd"

const ClawInputController := preload("res://scripts/gameplay/claw_input_controller.gd")
const ClawRigSolver := preload("res://scripts/gameplay/claw_rig_solver.gd")

class SolverStub:
    extends ClawRigSolver
    var move_vectors: Array[Vector2] = []
    var begin_count: int = 0
    var grip_count: int = 0
    var retract_count: int = 0

    func _ready() -> void:
        pass

    func set_move_vector(vector: Vector2) -> void:
        move_vectors.append(vector)

    func begin_lower() -> void:
        begin_count += 1

    func execute_grip() -> void:
        grip_count += 1

    func retract_to_idle() -> void:
        retract_count += 1

class JoystickStub:
    extends Node
    signal vector_changed(vector: Vector2)

    func emit_vector(vector: Vector2) -> void:
        emit_signal("vector_changed", vector)

var _controller: ClawInputController
var _solver: SolverStub
var _joystick: JoystickStub
var _extend_button: Button
var _retract_button: Button

func before_each() -> void:
    _solver = SolverStub.new()
    _joystick = JoystickStub.new()
    _extend_button = Button.new()
    _retract_button = Button.new()
    _controller = ClawInputController.new()
    _controller.solver = _solver
    _controller.joystick = _joystick
    _controller.extend_button = _extend_button
    _controller.retract_button = _retract_button
    _controller.smoothing = 0.0

    add_child_autofree(_solver)
    add_child_autofree(_joystick)
    add_child_autofree(_extend_button)
    add_child_autofree(_retract_button)
    add_child_autofree(_controller)
    wait_frames(1)

func test_vector_forwarded_to_solver() -> void:
    var vector := Vector2(0.6, -0.4)
    _joystick.emit_vector(vector)
    wait_frames(1)

    assert_eq(_solver.move_vectors.size(), 1, "Expected solver to receive one move vector")
    if _solver.move_vectors.size() == 1:
        assert_eq(_solver.move_vectors[0], vector, "Move vector should match joystick input when smoothing is zero")

func test_extend_button_triggers_lower_and_grip() -> void:
    _extend_button.emit_signal("button_down")
    wait_frames(1)
    _extend_button.emit_signal("button_up")
    wait_frames(1)

    assert_eq(_solver.begin_count, 1, "Extend press should begin lowering")
    assert_eq(_solver.grip_count, 1, "Extend release should trigger grip execution")

func test_retract_button_triggers_retract() -> void:
    _retract_button.emit_signal("button_down")
    wait_frames(1)

    assert_eq(_solver.retract_count, 1, "Retract press should command solver to retract")
