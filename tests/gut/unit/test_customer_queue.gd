extends GutTest

const OrderService = preload("res://autoload/order_service.gd")
const SignalHub = preload("res://autoload/signal_hub.gd")
const CustomerQueueScene = preload("res://scenes/session/CustomerQueue.tscn")
const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")

var _signal_hub: SignalHub
var _order_service: OrderService
var _queue: CustomerQueue

func before_each() -> void:
    _signal_hub = SignalHub.new()
    add_child_autofree(_signal_hub)
    _order_service = OrderService.new()
    add_child_autofree(_order_service)
    _queue = CustomerQueueScene.instantiate()
    add_child_autofree(_queue)
    wait_frames(1)

func after_each() -> void:
    _order_service.clear_all()

func test_spawn_reuses_pool() -> void:
    var order_a := _make_order("order_a")
    _order_service.request_order(order_a)
    wait_frames(1)
    assert_eq(_queue.debug_get_active_count(), 1, "First customer should spawn")
    var first_id := _queue.debug_get_last_spawned_rid()

    _order_service.complete_order(StringName("order_a"))
    wait_frames(1)
    assert_eq(_queue.debug_get_active_count(), 0, "Queue should be empty after completion")
    assert_true(_queue.debug_get_pool_size() > 0, "Customer should move to pool")

    var order_b := _make_order("order_b")
    _order_service.request_order(order_b)
    wait_frames(1)
    assert_eq(_queue.debug_get_active_count(), 1, "Second customer should spawn")
    assert_eq(_queue.debug_get_last_spawned_rid(), first_id, "Instance should be reused from pool")

func test_max_concurrent_enforced() -> void:
    _queue.max_concurrent = 2
    for i in 3:
        _order_service.request_order(_make_order("order_%d" % i))
    wait_frames(1)
    assert_eq(_queue.debug_get_active_count(), 2, "Queue enforces max concurrent cats")

func test_patience_stage_signals() -> void:
    var stages: Array[int] = []
    _signal_hub.patience_stage_changed.connect(func(_order_id: StringName, stage: int) -> void:
        stages.append(stage)
    )
    var order := _make_order("order_stage")
    order.patience_duration = 10.0
    order.warning_threshold = 0.5
    order.critical_threshold = 0.2
    _order_service.request_order(order)
    wait_frames(1)

    _order_service.advance_time(6.0)
    wait_frames(1)
    _order_service.advance_time(3.5)
    wait_frames(1)

    assert_true(stages.has(1), "Should emit warning stage")
    assert_true(stages.has(2), "Should emit critical stage")

func _make_order(id_str: String) -> OrderRequestDto:
    var dto := OrderRequestDto.new()
    dto.order_id = StringName(id_str)
    dto.seafood_name = "order_salmon_nigiri"
    dto.icon_path = "res://ui/icons/salmon.png"
    dto.tutorial_hint_key = StringName("tutorial_hint_default")
    dto.patience_duration = 12.0
    dto.warning_threshold = 0.35
    dto.critical_threshold = 0.15
    return dto
