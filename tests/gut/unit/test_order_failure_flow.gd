extends "res://tests/gut/gut_stub.gd"

const OrderResolutionPipeline := preload("res://scripts/services/order_resolution_pipeline.gd")
const OrderService := preload("res://autoload/order_service.gd")
const GameState := preload("res://autoload/game_state.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const AudioDirector := preload("res://autoload/audio_director.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")

var _pipeline: OrderResolutionPipeline
var _order_service: OrderService
var _game_state: GameState
var _signal_hub: SignalHub
var _analytics: AnalyticsStub
var _audio: AudioDirector

func before_each() -> void:
    _signal_hub = SignalHub.new()
    add_child_autofree(_signal_hub)

    _order_service = OrderService.new()
    add_child_autofree(_order_service)

    _game_state = GameState.new()
    add_child_autofree(_game_state)

    _analytics = AnalyticsStub.new()
    add_child_autofree(_analytics)

    _audio = AudioDirector.new()
    add_child_autofree(_audio)

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
        "score_reset": true,
    })

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

func test_failure_payload_includes_reason_and_combo_snapshot() -> void:
    var order_success := _make_order("order_success", "salmon")
    _order_service.request_order(order_success)
    wait_frames(1)
    _order_service.deliver_item(order_success.order_id, order_success.descriptor_id)
    wait_frames(1)

    var captured_payloads: Array[Dictionary] = []
    _signal_hub.order_resolved_failure.connect(func(_order_id: StringName, _reason: StringName, payload: Dictionary) -> void:
        captured_payloads.append(payload.duplicate(true))
    )

    var order_fail := _make_order("order_fail", "tuna")
    _order_service.request_order(order_fail)
    wait_frames(1)
    _order_service.deliver_item(order_fail.order_id, StringName("wrong_descriptor"))
    wait_frames(2)

    assert_eq(captured_payloads.size(), 1, "Should capture one failure payload")
    var payload: Dictionary = captured_payloads[0]
    assert_eq(payload.get("reason", StringName()), StringName("mismatch"), "Payload should annotate mismatch reason")
    assert_eq(payload.get("combo_snapshot", -1), 1, "Payload should capture combo before reset")
    assert_eq(payload.get("combo", -1), 0, "Combo should reset to zero after failure")

    var events: Array[Dictionary] = _analytics.debug_get_events()
    assert_eq(events.size(), 2, "Analytics should record success and failure events")
    var failure_event: Dictionary = events[-1]
    assert_eq(failure_event.get("event"), StringName("order_failed"), "Failure event should be order_failed")
    var failure_payload: Dictionary = failure_event.get("payload", {})
    assert_eq(failure_payload.get("reason", StringName()), StringName("mismatch"), "Analytics payload should include failure reason")
    assert_eq(failure_payload.get("combo_snapshot", -1), 1, "Analytics payload should capture combo snapshot")
