extends Node3D
class_name ClawRigSolver

const SignalHub := preload("res://autoload/signal_hub.gd")
const OrderService := preload("res://autoload/order_service.gd")
const CabinetItemPool := preload("res://scripts/gameplay/cabinet_item_pool.gd")

enum ClawState {
    IDLE,
    AIMING,
    DESCENDING,
    GRIPPING,
    CARRYING,
    DROPPING
}

@export var item_pool: CabinetItemPool
@export var item_pool_path: NodePath
@export_range(0.0, 1.0, 0.01) var grip_threshold: float = 0.85
@export_range(0.0, 2.0, 0.01) var clamp_timeout: float = 0.35
@export_range(0.0, 1.0, 0.01) var release_delay: float = 0.1

var _state: int = ClawState.IDLE
var _move_vector: Vector2 = Vector2.ZERO
var _signal_hub: SignalHub
var _order_service: OrderService
var _active_order: StringName = StringName()
var _target_descriptor: StringName = StringName()
var _held_item: Node3D
var _held_descriptor: StringName = StringName()
var _grip_timer: float = 0.0
var _release_timer: float = 0.0

func _ready() -> void:
    if item_pool == null and item_pool_path != NodePath():
        item_pool = get_node_or_null(item_pool_path) as CabinetItemPool
    _signal_hub = SignalHub.get_instance()
    _order_service = OrderService.get_instance()
    _connect_events()

func _exit_tree() -> void:
    _disconnect_events()

func set_move_vector(vector: Vector2) -> void:
    _move_vector = vector
    if vector.length_squared() > 0.0001 and _state == ClawState.IDLE:
        _transition_to(ClawState.AIMING)
    elif vector.is_zero_approx() and _state == ClawState.AIMING:
        _transition_to(ClawState.IDLE)

func begin_lower() -> void:
    if _state == ClawState.CARRYING or _state == ClawState.GRIPPING:
        return
    _grip_timer = clamp_timeout
    _transition_to(ClawState.DESCENDING)
    _broadcast_grab_started()

func execute_grip() -> void:
    if _state != ClawState.DESCENDING and _state != ClawState.AIMING:
        return
    if _target_descriptor == StringName():
        _fail_grip()
        return
    if item_pool == null:
        _fail_grip()
        return
    var item := item_pool.acquire_item(_target_descriptor)
    if item == null:
        _fail_grip()
        return
    _held_item = item
    _held_descriptor = item_pool.get_descriptor_for(item)
    _grip_timer = clamp_timeout
    _transition_to(ClawState.CARRYING)
    _broadcast_item_captured(_held_descriptor)

func retract_to_idle() -> void:
    if _held_item:
        _release_timer = release_delay
        _release_item()
    _transition_to(ClawState.IDLE)

func _process(delta: float) -> void:
    if _state == ClawState.GRIPPING:
        _grip_timer -= delta
        if _grip_timer <= 0.0:
            execute_grip()
    if _state == ClawState.DROPPING:
        _release_timer -= delta
        if _release_timer <= 0.0:
            _transition_to(ClawState.IDLE)

func _connect_events() -> void:
    if _signal_hub:
        if not _signal_hub.order_visualized.is_connected(_on_order_visualized):
            _signal_hub.order_visualized.connect(_on_order_visualized)
        if not _signal_hub.order_visual_cleared.is_connected(_on_order_visual_cleared):
            _signal_hub.order_visual_cleared.connect(_on_order_visual_cleared)
    if _order_service and not _order_service.order_cleared.is_connected(_on_order_cleared):
        _order_service.order_cleared.connect(_on_order_cleared)

func _disconnect_events() -> void:
    if _signal_hub:
        if _signal_hub.order_visualized.is_connected(_on_order_visualized):
            _signal_hub.order_visualized.disconnect(_on_order_visualized)
        if _signal_hub.order_visual_cleared.is_connected(_on_order_visual_cleared):
            _signal_hub.order_visual_cleared.disconnect(_on_order_visual_cleared)
    if _order_service and _order_service.order_cleared.is_connected(_on_order_cleared):
        _order_service.order_cleared.disconnect(_on_order_cleared)

func _on_order_visualized(descriptor_id: StringName, _icon: Texture2D, order_id: StringName) -> void:
    _target_descriptor = descriptor_id
    _active_order = order_id

func _on_order_visual_cleared(descriptor_id: StringName, order_id: StringName) -> void:
    if descriptor_id == _target_descriptor and order_id == _active_order:
        _target_descriptor = StringName()
        _active_order = StringName()

func _on_order_cleared(order_id: StringName) -> void:
    if order_id == _active_order:
        _target_descriptor = StringName()
        _active_order = StringName()

func _release_item() -> void:
    if item_pool == null or _held_item == null:
        _clear_held_item()
        return
    var descriptor_id: StringName = _held_descriptor
    if descriptor_id == StringName():
        descriptor_id = item_pool.get_descriptor_for(_held_item)
    item_pool.release_item(_held_item)
    _broadcast_item_released(descriptor_id)
    if _order_service:
        _order_service.deliver_item(_active_order, descriptor_id)
    _clear_held_item()
    _transition_to(ClawState.DROPPING)

func _clear_held_item() -> void:
    _held_item = null
    _held_descriptor = StringName()

func _fail_grip() -> void:
    _transition_to(ClawState.IDLE)
    _broadcast_grab_failed()

func _broadcast_grab_started() -> void:
    if _signal_hub:
        _signal_hub.broadcast_claw_grab_started(_active_order)

func _broadcast_grab_failed() -> void:
    if _signal_hub:
        _signal_hub.broadcast_claw_grab_failed(_active_order)

func _broadcast_item_captured(descriptor_id: StringName) -> void:
    if _signal_hub:
        _signal_hub.broadcast_claw_item_captured(descriptor_id, _active_order)

func _broadcast_item_released(descriptor_id: StringName) -> void:
    if _signal_hub:
        _signal_hub.broadcast_claw_item_released(descriptor_id, _active_order)

func _transition_to(new_state: int) -> void:
    if _state == new_state:
        return
    _state = new_state

func debug_get_state_name() -> String:
    match _state:
        ClawState.IDLE:
            return "IDLE"
        ClawState.AIMING:
            return "AIMING"
        ClawState.DESCENDING:
            return "DESCENDING"
        ClawState.GRIPPING:
            return "GRIPPING"
        ClawState.CARRYING:
            return "CARRYING"
        ClawState.DROPPING:
            return "DROPPING"
    return "UNKNOWN"
