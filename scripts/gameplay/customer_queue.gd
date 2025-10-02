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
var _deferred_releases: Dictionary = {}

@export var failure_release_default_sec: float = 0.5

func _ready() -> void:
    _collect_spawn_markers()
    var hub: Node = SignalHub.get_instance()
    if hub:
        hub.order_requested.connect(_on_order_requested)
        hub.order_cleared.connect(_on_order_cleared)
        hub.order_resolved_failure.connect(_on_order_failure)

func _exit_tree() -> void:
    var hub: Node = SignalHub.get_instance()
    if hub:
        if hub.order_requested.is_connected(_on_order_requested):
            hub.order_requested.disconnect(_on_order_requested)
        if hub.order_cleared.is_connected(_on_order_cleared):
            hub.order_cleared.disconnect(_on_order_cleared)
        if hub.order_resolved_failure.is_connected(_on_order_failure):
            hub.order_resolved_failure.disconnect(_on_order_failure)
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
    if customer.has_meta("order_id"):
        customer.remove_meta("order_id")
    if _deferred_releases.has(order_id):
        var entry: Dictionary = _deferred_releases[order_id]
        entry["customer"] = customer
        _deferred_releases[order_id] = entry
        _try_finalize_deferred_release(order_id)
        return
    _release_customer(customer)

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

func get_customer_for_order(order_id: StringName) -> Node3D:
    return _order_to_customer.get(order_id, null)

func defer_release(order_id: StringName, payload: Dictionary, delay_sec: float) -> void:
    if order_id == StringName():
        return
    var entry: Dictionary = (_deferred_releases.get(order_id, {
        "customer": null,
        "timer_complete": false,
        "payload": payload.duplicate(true),
    }) as Dictionary)
    entry["payload"] = payload.duplicate(true)
    var delay: float = max(delay_sec, 0.0)
    var existing_timer := entry.get("timer", null) as SceneTreeTimer
    if existing_timer != null:
        existing_timer.queue_free()
    if delay <= 0.0:
        entry["timer_complete"] = true
        entry.erase("timer")
    else:
        var timer: SceneTreeTimer = get_tree().create_timer(delay)
        timer.timeout.connect(_on_deferred_timer_timeout.bind(order_id))
        entry["timer"] = timer
        entry["timer_complete"] = false
    _deferred_releases[order_id] = entry
    _try_finalize_deferred_release(order_id)

func _on_order_failure(order_id: StringName, reason: StringName, payload: Dictionary) -> void:
    var delay := float(payload.get("restart_window_sec", failure_release_default_sec))
    defer_release(order_id, payload, delay)

func _mark_deferred_ready(order_id: StringName) -> void:
    if not _deferred_releases.has(order_id):
        return
    var entry: Dictionary = _deferred_releases[order_id]
    entry["timer_complete"] = true
    entry.erase("timer")
    _deferred_releases[order_id] = entry
    _try_finalize_deferred_release(order_id)

func _on_deferred_timer_timeout(order_id: StringName) -> void:
    _mark_deferred_ready(order_id)

func _try_finalize_deferred_release(order_id: StringName) -> void:
    if not _deferred_releases.has(order_id):
        return
    var entry: Dictionary = _deferred_releases[order_id]
    var ready: bool = bool(entry.get("timer_complete", false))
    var customer: Node3D = entry.get("customer", null)
    if customer == null or not ready:
        return
    _deferred_releases.erase(order_id)
    _release_customer(customer)
    var hub: Node = SignalHub.get_instance()
    if hub:
        hub.broadcast_order_failure_resolved(order_id, entry.get("payload", {}))

func _release_customer(customer: Node3D) -> void:
    if customer == null:
        return
    _active_customers.erase(customer)
    customer.visible = false
    if not _pool.has(customer):
        _pool.append(customer)
    _try_spawn_pending()
