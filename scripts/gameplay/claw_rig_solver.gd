extends Node3D
class_name ClawRigSolver

const SignalHub := preload("res://autoload/signal_hub.gd")
const OrderService := preload("res://autoload/order_service.gd")
const CabinetItemPool := preload("res://scripts/gameplay/cabinet_item_pool.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")
const AudioDirector := preload("res://autoload/audio_director.gd")

enum ClawState {
    IDLE,
    AIMING,
    DESCENDING,
    GRIPPING,
    CARRYING,
    DROPPING
}

@export var item_pool_path: NodePath
@export var drop_zone_path: NodePath
@export var move_speed: float = 2.6
@export var descend_speed: float = 3.0
@export var raise_speed: float = 3.5
@export var release_impulse: float = 2.8
@export var min_bounds: Vector3 = Vector3(-1.6, 0.0, -1.2)
@export var max_bounds: Vector3 = Vector3(1.6, 0.0, 1.2)
@export var min_grab_height: float = -1.15
@export var rest_grab_height: float = -0.3

var item_pool: CabinetItemPool

@onready var _arm_root: Node3D = get_node_or_null("ArmRoot") as Node3D
@onready var _grabber: Node3D = get_node_or_null("ArmRoot/Grabber") as Node3D
@onready var _hold_point: Marker3D = get_node_or_null("ArmRoot/Grabber/HoldPoint") as Marker3D
@onready var _grip_area: Area3D = get_node_or_null("ArmRoot/Grabber/GripArea") as Area3D

var _drop_zone: Area3D
var _signal_hub: SignalHub
var _order_service: OrderService
var _audio: AudioDirector

var _state: int = ClawState.IDLE
var _move_vector: Vector2 = Vector2.ZERO
var _grab_height: float = rest_grab_height
var _active_order: StringName = StringName()
var _target_descriptor: StringName = StringName()
var _held_item: RigidBody3D
var _held_descriptor: StringName = StringName()
var _candidate_bodies: Dictionary = {}
var _hidden_static_by_order: Dictionary = {}
var _released_items: Dictionary = {}
var _execute_grip_requested: bool = false

func _ready() -> void:
    if item_pool == null and item_pool_path != NodePath():
        item_pool = get_node_or_null(item_pool_path) as CabinetItemPool
    _signal_hub = SignalHub.get_instance()
    _order_service = OrderService.get_instance()
    _audio = AudioDirector.get_instance()
    _drop_zone = get_node_or_null(drop_zone_path) as Area3D
    if _drop_zone:
        _drop_zone.body_entered.connect(_on_drop_zone_body_entered)
    if _grip_area:
        _grip_area.body_entered.connect(_on_grip_area_body_entered)
        _grip_area.body_exited.connect(_on_grip_area_body_exited)
    _connect_events()
    set_physics_process(true)

func _exit_tree() -> void:
    if _drop_zone and _drop_zone.body_entered.is_connected(_on_drop_zone_body_entered):
        _drop_zone.body_entered.disconnect(_on_drop_zone_body_entered)
    if _grip_area:
        if _grip_area.body_entered.is_connected(_on_grip_area_body_entered):
            _grip_area.body_entered.disconnect(_on_grip_area_body_entered)
        if _grip_area.body_exited.is_connected(_on_grip_area_body_exited):
            _grip_area.body_exited.disconnect(_on_grip_area_body_exited)
    _disconnect_events()

func _connect_events() -> void:
    if _signal_hub:
        if not _signal_hub.order_visualized.is_connected(_on_order_visualized):
            _signal_hub.order_visualized.connect(_on_order_visualized)
        if not _signal_hub.order_visual_cleared.is_connected(_on_order_visual_cleared):
            _signal_hub.order_visual_cleared.connect(_on_order_visual_cleared)
    if _order_service:
        if not _order_service.order_cleared.is_connected(_on_order_cleared):
            _order_service.order_cleared.connect(_on_order_cleared)
        if not _order_service.order_resolved_failure.is_connected(_on_order_failed):
            _order_service.order_resolved_failure.connect(_on_order_failed)

func _disconnect_events() -> void:
    if _signal_hub:
        if _signal_hub.order_visualized.is_connected(_on_order_visualized):
            _signal_hub.order_visualized.disconnect(_on_order_visualized)
        if _signal_hub.order_visual_cleared.is_connected(_on_order_visual_cleared):
            _signal_hub.order_visual_cleared.disconnect(_on_order_visual_cleared)
    if _order_service:
        if _order_service.order_cleared.is_connected(_on_order_cleared):
            _order_service.order_cleared.disconnect(_on_order_cleared)
        if _order_service.order_resolved_failure.is_connected(_on_order_failed):
            _order_service.order_resolved_failure.disconnect(_on_order_failed)

func set_move_vector(vector: Vector2) -> void:
    _move_vector = vector
    if vector.length_squared() > 0.0001 and _state == ClawState.IDLE:
        _transition_to(ClawState.AIMING)
    elif vector.is_zero_approx() and _state == ClawState.AIMING:
        _transition_to(ClawState.IDLE)

func begin_lower() -> void:
    if _state == ClawState.DESCENDING or _state == ClawState.GRIPPING:
        return
    if _active_order == StringName():
        return
    _execute_grip_requested = false
    _transition_to(ClawState.DESCENDING)
    _broadcast_grab_started()
    if _audio:
        _audio.play_event(StringName("claw_lower_start"))

func execute_grip() -> void:
    _execute_grip_requested = true
    if _state == ClawState.AIMING or _state == ClawState.DESCENDING:
        _transition_to(ClawState.GRIPPING)
        _attempt_grip()

func retract_to_idle() -> void:
    if _held_item:
        _drop_held_item()
        return
    _transition_to(ClawState.IDLE)

func process_drop(body: RigidBody3D) -> void:
    if body == null:
        return
    if not _released_items.has(body):
        return
    var release_info: Dictionary = _released_items.get(body, {})
    _released_items.erase(body)
    var descriptor_id: StringName = item_pool.get_descriptor_for(body)
    if descriptor_id == StringName():
        var stored_descriptor: Variant = release_info.get("descriptor", descriptor_id)
        if stored_descriptor is StringName:
            descriptor_id = stored_descriptor
        elif body.has_meta("descriptor_id"):
            descriptor_id = body.get_meta("descriptor_id")
    var stored_order: Variant = release_info.get("order", _active_order)
    var order_id: StringName = stored_order if stored_order is StringName else _active_order
    if _order_service and order_id != StringName():
        _order_service.deliver_item(order_id, descriptor_id)
    _broadcast_item_released(descriptor_id, order_id)
    item_pool.release_item(body)
    _restore_static_for_order(order_id)
    _transition_to(ClawState.IDLE)

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

func _physics_process(delta: float) -> void:
    _update_horizontal(delta)
    _update_vertical(delta)

func _update_horizontal(delta: float) -> void:
    if _arm_root == null:
        return
    if _move_vector.is_zero_approx():
        return
    var displacement: Vector3 = Vector3(_move_vector.x, 0.0, _move_vector.y) * move_speed * delta
    var new_position: Vector3 = _arm_root.position + displacement
    new_position.x = clampf(new_position.x, min_bounds.x, max_bounds.x)
    new_position.z = clampf(new_position.z, min_bounds.z, max_bounds.z)
    _arm_root.position = new_position

func _update_vertical(delta: float) -> void:
    if _grabber == null:
        return
    match _state:
        ClawState.DESCENDING:
            _grab_height = maxf(min_grab_height, _grab_height - descend_speed * delta)
            if _grab_height <= min_grab_height + 0.01 or _execute_grip_requested:
                _transition_to(ClawState.GRIPPING)
                _attempt_grip()
        ClawState.CARRYING:
            _grab_height = move_toward(_grab_height, rest_grab_height, raise_speed * delta)
            if is_equal_approx(_grab_height, rest_grab_height) or _grab_height > rest_grab_height - 0.01:
                _grab_height = rest_grab_height
                _transition_to(ClawState.AIMING if not _move_vector.is_zero_approx() else ClawState.IDLE)
        ClawState.GRIPPING:
            _grab_height = clampf(_grab_height, min_grab_height, rest_grab_height)
        _:
            _grab_height = move_toward(_grab_height, rest_grab_height, raise_speed * delta)
    var grabber_position: Vector3 = _grabber.position
    grabber_position.y = _grab_height
    _grabber.position = grabber_position

func _attempt_grip() -> void:
    if item_pool == null:
        _fail_grip()
        return
    if _hold_point == null:
        _fail_grip()
        return
    var descriptor_id: StringName = _choose_descriptor()
    if descriptor_id == StringName():
        _fail_grip()
        return
    var static_body: Node = _candidate_bodies.get(descriptor_id, null)
    var grabbed_item: RigidBody3D = item_pool.acquire_item(descriptor_id)
    if grabbed_item == null:
        _fail_grip()
        return
    if static_body and static_body is Node:
        _hide_static_body(descriptor_id, static_body)
    _held_item = grabbed_item
    _held_descriptor = descriptor_id
    grabbed_item.freeze = true
    grabbed_item.linear_velocity = Vector3.ZERO
    grabbed_item.angular_velocity = Vector3.ZERO
    grabbed_item.global_transform = _hold_point.global_transform
    grabbed_item.reparent(_hold_point)
    _transition_to(ClawState.CARRYING)
    _broadcast_item_captured(descriptor_id)
    if _audio:
        _audio.play_event(StringName("claw_grab_success"))
    _execute_grip_requested = false

func _drop_held_item() -> void:
    if _held_item == null:
        return
    var descriptor_id: StringName = _held_descriptor
    var order_id := _active_order
    var item: RigidBody3D = _held_item
    _held_item = null
    _held_descriptor = StringName()
    item.freeze = false
    item.sleeping = false
    if _hold_point and _hold_point.is_inside_tree():
        item.reparent(get_parent())
        item.global_transform = _hold_point.global_transform
    item.linear_velocity = Vector3.ZERO
    item.angular_velocity = Vector3.ZERO
    item.apply_impulse(Vector3.ZERO, Vector3.DOWN * release_impulse)
    _released_items[item] = {
        "descriptor": descriptor_id,
        "order": order_id,
    }
    _transition_to(ClawState.DROPPING)
    if _audio:
        _audio.play_event(StringName("claw_release"))

func _restore_static_for_order(order_id: StringName) -> void:
    if order_id == StringName():
        return
    if not _hidden_static_by_order.has(order_id):
        return
    var info: Dictionary = _hidden_static_by_order[order_id]
    _hidden_static_by_order.erase(order_id)
    var static_body: Node = info.get("body", null)
    if static_body and static_body is Node3D:
        static_body.visible = true
        static_body.process_mode = Node.PROCESS_MODE_INHERIT

func _hide_static_body(descriptor_id: StringName, static_body: Node) -> void:
    if static_body == null:
        return
    static_body.visible = false
    if _active_order != StringName():
        _hidden_static_by_order[_active_order] = {
            "descriptor": descriptor_id,
            "body": static_body,
        }
    if _candidate_bodies.has(descriptor_id):
        _candidate_bodies.erase(descriptor_id)

func _choose_descriptor() -> StringName:
    if _target_descriptor != StringName() and _candidate_bodies.has(_target_descriptor):
        return _target_descriptor
    for descriptor in _candidate_bodies.keys():
        return descriptor
    return StringName()

func _fail_grip() -> void:
    _broadcast_grab_failed()
    _transition_to(ClawState.IDLE)
    _execute_grip_requested = false
    if _audio:
        _audio.play_event(StringName("claw_grab_fail"))

func _on_order_visualized(descriptor_id: StringName, _icon: Texture2D, order_id: StringName) -> void:
    _target_descriptor = descriptor_id
    _active_order = order_id

func _on_order_visual_cleared(descriptor_id: StringName, order_id: StringName) -> void:
    if order_id != _active_order:
        return
    if descriptor_id == _target_descriptor:
        _target_descriptor = StringName()
    _restore_static_for_order(order_id)
    _active_order = StringName()

func _on_order_cleared(order_id: StringName) -> void:
    if order_id != _active_order:
        _restore_static_for_order(order_id)
        return
    if _held_item:
        _held_item.reparent(get_parent())
        item_pool.release_item(_held_item)
        _held_item = null
        _held_descriptor = StringName()
    _restore_static_for_order(order_id)
    _active_order = StringName()
    _target_descriptor = StringName()
    _transition_to(ClawState.IDLE)

func _on_order_failed(order_id: StringName, _reason: StringName, _payload: Dictionary) -> void:
    if order_id == _active_order and _held_item:
        _held_item.reparent(get_parent())
        item_pool.release_item(_held_item)
        _held_item = null
        _held_descriptor = StringName()
    _restore_static_for_order(order_id)

func _on_drop_zone_body_entered(body: Node) -> void:
    if body is RigidBody3D:
        process_drop(body as RigidBody3D)

func _on_grip_area_body_entered(body: Node) -> void:
    if body == null:
        return
    if not body.has_meta("descriptor_id"):
        return
    var descriptor_id: StringName = body.get_meta("descriptor_id")
    _candidate_bodies[descriptor_id] = body

func _on_grip_area_body_exited(body: Node) -> void:
    if body == null:
        return
    if not body.has_meta("descriptor_id"):
        return
    var descriptor_id: StringName = body.get_meta("descriptor_id")
    if _candidate_bodies.has(descriptor_id):
        _candidate_bodies.erase(descriptor_id)

func _transition_to(new_state: int) -> void:
    if _state == new_state:
        return
    _state = new_state

func _broadcast_grab_started() -> void:
    if _signal_hub:
        _signal_hub.broadcast_claw_grab_started(_active_order)

func _broadcast_grab_failed() -> void:
    if _signal_hub:
        _signal_hub.broadcast_claw_grab_failed(_active_order)

func _broadcast_item_captured(descriptor_id: StringName) -> void:
    if _signal_hub:
        _signal_hub.broadcast_claw_item_captured(descriptor_id, _active_order)

func _broadcast_item_released(descriptor_id: StringName, order_id: StringName) -> void:
    if _signal_hub:
        var target_order := order_id if order_id != StringName() else _active_order
        _signal_hub.broadcast_claw_item_released(descriptor_id, target_order)
