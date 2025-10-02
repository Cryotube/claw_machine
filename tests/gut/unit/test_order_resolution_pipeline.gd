extends "res://tests/gut/gut_stub.gd"

const OrderResolutionPipeline := preload("res://scripts/services/order_resolution_pipeline.gd")
const OrderService := preload("res://autoload/order_service.gd")
const GameState := preload("res://autoload/game_state.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")

var _pipeline: OrderResolutionPipeline
var _order_service: OrderService
var _game_state: GameState
var _signal_hub: SignalHub
var _analytics: AnalyticsStub

func before_each() -> void:
    _signal_hub = SignalHub.new()
    add_child_autofree(_signal_hub)

    _order_service = OrderService.new()
    add_child_autofree(_order_service)

    _game_state = GameState.new()
    add_child_autofree(_game_state)

    _analytics = AnalyticsStub.new()
    add_child_autofree(_analytics)

    _pipeline = OrderResolutionPipeline.new()
    add_child_autofree(_pipeline)

    wait_frames(1)

    var combo_curve := Curve.new()
    combo_curve.add_point(Vector2(0.0, 1.0))
    combo_curve.add_point(Vector2(1.0, 2.0))

    _game_state.configure({
        "starting_lives": 3,
        "combo_curve": combo_curve,
        "wave_schedule": [3, 3, 3],
    })
    _game_state.reset_state()

func _make_order(order_id: String, descriptor: String) -> OrderRequestDto:
    var dto := OrderRequestDto.new()
    dto.order_id = StringName(order_id)
    dto.descriptor_id = StringName(descriptor)
    dto.seafood_name = "fish_%s" % descriptor
    dto.icon_path = "res://ui/icons/%s.png" % descriptor
    dto.base_score = 100
    dto.wave_index = 1
    dto.patience_duration = 12.0
    dto.warning_threshold = 0.35
    dto.critical_threshold = 0.2
    return dto

func test_success_resolution_updates_state_and_analytics() -> void:
    var score_events: Array = []
    _signal_hub.connect("score_updated", func(total_score: int, delta: int) -> void:
        score_events.append({"total": total_score, "delta": delta})
    )

    var combo_events: Array = []
    _signal_hub.connect("combo_updated", func(combo_count: int, multiplier: float) -> void:
        combo_events.append({"combo": combo_count, "multiplier": multiplier})
    )

    var life_events: Array = []
    _signal_hub.connect("lives_updated", func(lives: int) -> void:
        life_events.append(lives)
    )

    var order := _make_order("order_success", "salmon")
    _order_service.request_order(order)

    wait_frames(1)

    _order_service.deliver_item(order.order_id, order.descriptor_id)
    wait_frames(1)

    assert_eq(_order_service.debug_get_active_order_ids().size(), 0, "Order should be cleared after success")
    assert_eq(score_events.size(), 1, "Score signal should fire once")
    assert_true(score_events[0]["delta"] > 0, "Score delta should be positive")
    assert_eq(combo_events.size(), 1, "Combo update should emit once")
    assert_eq(combo_events[0]["combo"], 1, "Combo should be one after first success")
    assert_eq(life_events.size(), 0, "Lives should remain unchanged on success")

    var events := _analytics.debug_get_events()
    assert_eq(events.size(), 1, "Analytics should log one event")
    assert_eq(events[0]["event"], StringName("order_fulfilled"), "Should log order_fulfilled event")
    assert_eq(events[0]["payload"].get("combo", -1), 1, "Payload should include combo count")
    assert_eq(events[0]["payload"].get("wave_index", -1), 1, "Payload should include wave index")

func test_failure_resolution_resets_combo_and_logs_event() -> void:
    var combo_events: Array = []
    _signal_hub.connect("combo_updated", func(combo_count: int, multiplier: float) -> void:
        combo_events.append({"combo": combo_count, "multiplier": multiplier})
    )

    var life_events: Array = []
    _signal_hub.connect("lives_updated", func(lives: int) -> void:
        life_events.append(lives)
    )

    var order := _make_order("order_failure", "tuna")
    _order_service.request_order(order)
    wait_frames(1)

    _order_service.deliver_item(order.order_id, StringName("wrong_descriptor"))
    wait_frames(1)

    assert_eq(_order_service.debug_get_active_order_ids().size(), 0, "Order should be cleared after failure")
    assert_true(combo_events.size() >= 1, "Combo should emit at least once for reset")
    assert_eq(combo_events[-1]["combo"], 0, "Combo should reset to zero after failure")
    assert_true(life_events.size() >= 1, "Lives signal should emit on failure")

    var events := _analytics.debug_get_events()
    assert_eq(events.size(), 1, "Analytics should contain single failure event")
    assert_eq(events[0]["event"], StringName("order_failed"), "Failure event should be order_failed")
    assert_eq(events[0]["payload"].get("result"), StringName("mismatch"), "Payload should capture failure reason")
    assert_eq(events[0]["payload"].get("combo"), 0, "Combo should reset in payload")
