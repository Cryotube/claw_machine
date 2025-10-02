extends "res://tests/gut/gut_stub.gd"

const ClawRigSolver := preload("res://scripts/gameplay/claw_rig_solver.gd")
const CabinetItemPool := preload("res://scripts/gameplay/cabinet_item_pool.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const OrderService := preload("res://autoload/order_service.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")

class CabinetItemPoolStub:
    extends CabinetItemPool
    var request_log: Array[StringName] = []
    var release_log: Array[Node3D] = []

    func _ready() -> void:
        pass

    func add_item(descriptor_id: StringName, node: Node3D) -> void:
        if not _available.has(descriptor_id):
            _available[descriptor_id] = []
        _available[descriptor_id].append(node)
        _active_lookup[node] = descriptor_id

    func acquire_item(descriptor_id: StringName) -> Node3D:
        request_log.append(descriptor_id)
        var bucket: Array = _available.get(descriptor_id, [])
        if bucket.is_empty():
            return null
        var item: Node3D = bucket.pop_back()
        _available[descriptor_id] = bucket
        _active_lookup[item] = descriptor_id
        return item

    func release_item(item: Node3D) -> void:
        if item == null:
            return
        release_log.append(item)
        var descriptor_id: StringName = _active_lookup.get(item, StringName())
        _active_lookup.erase(item)
        if descriptor_id == StringName():
            return
        if not _available.has(descriptor_id):
            _available[descriptor_id] = []
        var bucket: Array = _available[descriptor_id]
        bucket.append(item)
        _available[descriptor_id] = bucket

    func get_descriptor_for(item: Node3D) -> StringName:
        return _active_lookup.get(item, StringName())

var _signal_hub: SignalHub
var _order_service: OrderService
var _solver: ClawRigSolver
var _pool: CabinetItemPoolStub

var _started_events: Array[StringName] = []
var _captured_events: Array = []
var _failed_events: Array[StringName] = []
var _released_events: Array = []
var _orders_cleared: Array[StringName] = []
var _order_mismatches: Array[StringName] = []

func before_each() -> void:
    _signal_hub = SignalHub.new()
    add_child_autofree(_signal_hub)
    _order_service = OrderService.new()
    add_child_autofree(_order_service)
    _pool = CabinetItemPoolStub.new()
    add_child_autofree(_pool)
    _solver = ClawRigSolver.new()
    _solver.item_pool = _pool
    add_child_autofree(_solver)
    _connect_signals()
    wait_frames(1)

func _connect_signals() -> void:
    if _signal_hub.has_signal("claw_grab_started"):
        _signal_hub.claw_grab_started.connect(func(order_id: StringName) -> void:
            _started_events.append(order_id)
        )
    if _signal_hub.has_signal("claw_item_captured"):
        _signal_hub.claw_item_captured.connect(func(descriptor_id: StringName, order_id: StringName) -> void:
            _captured_events.append([descriptor_id, order_id])
        )
    if _signal_hub.has_signal("claw_grab_failed"):
        _signal_hub.claw_grab_failed.connect(func(order_id: StringName) -> void:
            _failed_events.append(order_id)
        )
    if _signal_hub.has_signal("claw_item_released"):
        _signal_hub.claw_item_released.connect(func(descriptor_id: StringName, order_id: StringName) -> void:
            _released_events.append([descriptor_id, order_id])
        )
    if _order_service.has_signal("order_cleared"):
        _order_service.order_cleared.connect(func(order_id: StringName) -> void:
            _orders_cleared.append(order_id)
        )
    if _order_service.has_signal("order_visual_mismatch"):
        _order_service.order_visual_mismatch.connect(func(order_id: StringName, _descriptor: StringName) -> void:
            _order_mismatches.append(order_id)
        )

func after_each() -> void:
    _order_service.clear_all()

func test_begin_lower_emits_started_event() -> void:
    var descriptor_id := StringName("salmon")
    var order := _make_order(StringName("order_salmon"), descriptor_id)
    _order_service.request_order(order)
    wait_frames(1)
    _signal_hub.broadcast_visualized(descriptor_id, null, order.order_id)

    _solver.begin_lower()
    wait_frames(1)

    assert_eq(_started_events.size(), 1, "Expect claw_grab_started to fire once")
    assert_eq(_solver.debug_get_state_name(), "DESCENDING", "Solver should enter DESCENDING state")

func test_grip_success_captures_item_and_clears_order() -> void:
    var descriptor_id := StringName("shrimp")
    var order_id := StringName("order_shrimp")
    _order_service.request_order(_make_order(order_id, descriptor_id))
    wait_frames(1)
    _signal_hub.broadcast_visualized(descriptor_id, null, order_id)

    var pooled_item := Node3D.new()
    _pool.add_item(descriptor_id, pooled_item)

    _solver.begin_lower()
    wait_frames(1)
    _solver.execute_grip()
    wait_frames(1)

    assert_eq(_captured_events.size(), 1, "Expected captured event after successful grip")
    assert_eq(_solver.debug_get_state_name(), "CARRYING", "Solver should hold item after grip")

    _solver.retract_to_idle()
    wait_frames(1)

    assert_eq(_released_events.size(), 1, "Expected release event when retracting")
    assert_has(_orders_cleared, order_id, "Order should be cleared after successful delivery")
    assert_eq(_solver.debug_get_state_name(), "IDLE", "Solver should return to idle after retract")
    assert_eq(_pool.release_log.size(), 1, "Item should be returned to pool")

func test_grip_failure_emits_failure_signal() -> void:
    var descriptor_id := StringName("lobster")
    var order_id := StringName("order_lobster")
    _order_service.request_order(_make_order(order_id, descriptor_id))
    wait_frames(1)
    _signal_hub.broadcast_visualized(descriptor_id, null, order_id)

    _solver.begin_lower()
    wait_frames(1)
    _solver.execute_grip()
    wait_frames(1)

    assert_eq(_failed_events.size(), 1, "Should emit failure when pool lacks item")
    assert_eq(_solver.debug_get_state_name(), "IDLE", "Solver should return to idle after failed grip")

func test_wrong_item_reports_mismatch() -> void:
    var descriptor_id := StringName("crab")
    var order_id := StringName("order_crab")
    _order_service.request_order(_make_order(order_id, descriptor_id))
    wait_frames(1)
    _signal_hub.broadcast_visualized(descriptor_id, null, order_id)

    var wrong_item := Node3D.new()
    _pool.add_item(StringName("shrimp"), wrong_item)

    _solver.begin_lower()
    wait_frames(1)
    _solver.set("_target_descriptor", StringName("shrimp"))
    _solver.execute_grip()
    wait_frames(1)
    _solver.retract_to_idle()
    wait_frames(1)

    assert_has(_order_mismatches, order_id, "Delivering wrong item should trigger mismatch")
    assert_eq(_solver.debug_get_state_name(), "IDLE", "Solver returns to idle after mismatch")

func _make_order(order_id: StringName, descriptor_id: StringName) -> OrderRequestDto:
    var dto := OrderRequestDto.new()
    dto.order_id = order_id
    dto.descriptor_id = descriptor_id
    dto.seafood_name = "Test"
    dto.icon_path = "res://ui/icons/test.png"
    dto.tutorial_hint_key = StringName("hint")
    dto.icon_texture = null
    dto.patience_duration = 10.0
    dto.warning_threshold = 0.5
    dto.critical_threshold = 0.2
    dto.highlight_palette = StringName("default")
    return dto
