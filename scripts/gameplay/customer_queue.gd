extends Node3D
class_name CustomerQueue

const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")
const SignalHub = preload("res://autoload/signal_hub.gd")

@export var customer_scene: PackedScene
@export var spawn_marker_paths: Array[NodePath] = []
@export var max_concurrent: int = 3

var _active_customers: Array[Node3D] = []
var _pool: Array[Node3D] = []
var _spawn_markers: Array[Node3D] = []
var _pending_orders: Array[OrderRequestDto] = []
var _order_to_customer: Dictionary = {}
var _last_spawned_id: int = -1

func _ready() -> void:
    _collect_spawn_markers()
    var hub: Node = SignalHub.get_instance()
    if hub:
        hub.order_requested.connect(_on_order_requested)
        hub.order_cleared.connect(_on_order_cleared)

func _exit_tree() -> void:
    var hub: Node = SignalHub.get_instance()
    if hub:
        if hub.order_requested.is_connected(_on_order_requested):
            hub.order_requested.disconnect(_on_order_requested)
        if hub.order_cleared.is_connected(_on_order_cleared):
            hub.order_cleared.disconnect(_on_order_cleared)
    for customer in _active_customers:
        customer.queue_free()
    _active_customers.clear()
    _pool.clear()
    _pending_orders.clear()
    _order_to_customer.clear()

func _collect_spawn_markers() -> void:
    _spawn_markers.clear()
    for path in spawn_marker_paths:
        var marker := get_node_or_null(path)
        if marker is Node3D:
            _spawn_markers.append(marker)
    if _spawn_markers.is_empty():
        _spawn_markers.append(self)

func _on_order_requested(order: OrderRequestDto) -> void:
    if order == null:
        return
    var max_active: int = max(max_concurrent, 1)
    if _active_customers.size() >= max_active:
        _pending_orders.append(order)
        return
    _spawn_order(order)

func _spawn_order(order: OrderRequestDto) -> void:
    var customer: Node3D = _acquire_customer()
    customer.visible = true
    customer.set_meta("order_id", order.order_id)
    customer.name = "Customer_%s" % String(order.order_id)

    var index: int = min(_active_customers.size(), _spawn_markers.size() - 1)
    var marker: Node3D = _spawn_markers[index]
    customer.global_transform = marker.global_transform

    if customer.get_parent() != self:
        add_child(customer)

    _active_customers.append(customer)
    _order_to_customer[order.order_id] = customer
    _last_spawned_id = customer.get_instance_id()

func _on_order_cleared(order_id: StringName) -> void:
    if not _order_to_customer.has(order_id):
        return
    var customer: Node3D = _order_to_customer[order_id]
    _order_to_customer.erase(order_id)
    _active_customers.erase(customer)
    if customer.has_meta("order_id"):
        customer.remove_meta("order_id")
    customer.visible = false
    _pool.append(customer)
    _try_spawn_pending()

func _try_spawn_pending() -> void:
    if _pending_orders.is_empty():
        return
    var max_active: int = max(max_concurrent, 1)
    if _active_customers.size() >= max_active:
        return
    var next_order: OrderRequestDto = _pending_orders.pop_front()
    _spawn_order(next_order)

func _acquire_customer() -> Node3D:
    if not _pool.is_empty():
        return _pool.pop_back() as Node3D
    if customer_scene:
        return customer_scene.instantiate() as Node3D
    return Node3D.new()

func debug_get_active_count() -> int:
    return _active_customers.size()

func debug_get_pool_size() -> int:
    return _pool.size()

func debug_get_last_spawned_rid() -> int:
    return _last_spawned_id
