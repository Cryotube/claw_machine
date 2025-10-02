extends "res://tests/gut/gut_stub.gd"

const OrderService := preload("res://autoload/order_service.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const GameState := preload("res://autoload/game_state.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const AudioDirector := preload("res://autoload/audio_director.gd")
const CustomerQueueScene := preload("res://scenes/session/CustomerQueue.tscn")
const OrderResolutionPipeline := preload("res://scripts/services/order_resolution_pipeline.gd")
const FailureReactionController := preload("res://scripts/gameplay/failure_reaction_controller.gd")

var _signal_hub: SignalHub
var _order_service: OrderService
var _game_state: GameState
var _analytics: AnalyticsStub
var _audio: AudioDirector
var _queue: Node3D
var _pipeline: OrderResolutionPipeline
var _reaction: FailureReactionController

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

    _queue = CustomerQueueScene.instantiate()
    add_child_autofree(_queue)

    _pipeline = OrderResolutionPipeline.new()
    add_child_autofree(_pipeline)

    _reaction = FailureReactionController.new()
    _reaction.release_delay_sec = 0.1
    add_child_autofree(_reaction)

    _reaction.set_queue(_queue)

    var combo_curve := Curve.new()
    combo_curve.add_point(Vector2(0.0, 1.0))
    combo_curve.add_point(Vector2(1.0, 2.0))

    _game_state.configure({
        "starting_lives": 3,
        "combo_curve": combo_curve,
        "wave_schedule": [3, 3, 3],
        "score_reset": true,
    })

    wait_frames(1)

func test_failure_reaction_defers_release_and_reuses_effect() -> void:
    var order_a := _make_order("order_fx_a", "salmon")
    _order_service.request_order(order_a)
    wait_frames(1)

    _order_service.deliver_item(order_a.order_id, StringName("wrong_descriptor"))
    wait_frames(1)

    assert_eq(_audio.debug_get_last_event(), StringName("failure_mismatch"), "Audio director should receive mismatch cue")
    assert_eq(_queue.debug_get_active_count(), 1, "Customer should remain active briefly for reaction")

    await get_tree().create_timer(0.2).timeout
    wait_frames(1)

    assert_eq(_queue.debug_get_active_count(), 0, "Customer should be released after delay")
    assert_true(_queue.debug_get_pool_size() > 0, "Customer should return to pool")

    var effect_ids_after_first: Array[int] = _reaction.debug_get_effect_instance_ids()
    assert_eq(effect_ids_after_first.size(), 1, "One effect instance should be active after first failure")

    var order_b := _make_order("order_fx_b", "tuna")
    _order_service.request_order(order_b)
    wait_frames(1)

    _order_service.deliver_item(order_b.order_id, StringName("wrong_descriptor"))
    await get_tree().create_timer(0.2).timeout
    wait_frames(1)

    var effect_ids_after_second: Array[int] = _reaction.debug_get_effect_instance_ids()
    assert_eq(effect_ids_after_second.size(), 1, "Pool should still track single reusable effect instance")
    assert_eq(effect_ids_after_second[0], effect_ids_after_first[0], "Effect instance should be reused from pool")

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
