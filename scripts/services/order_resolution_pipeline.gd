extends Node
class_name OrderResolutionPipeline

const OrderService := preload("res://autoload/order_service.gd")
const GameState := preload("res://autoload/game_state.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const AudioDirector := preload("res://autoload/audio_director.gd")
const PersistenceService := preload("res://autoload/persistence_service.gd")
const SceneDirector := preload("res://autoload/scene_director.gd")
const ComboCurveProfile := preload("res://scripts/resources/combo_curve_profile.gd")
const WaveScheduleResource := preload("res://scripts/resources/wave_schedule_resource.gd")
const AnalyticsConfigResource := preload("res://scripts/resources/analytics_config_resource.gd")
const RunSummaryService := preload("res://scripts/services/run_summary_service.gd")

const COMBO_CURVE_PATH := "res://resources/data/combo_curve.tres"
const WAVE_SCHEDULE_PATH := "res://resources/data/wave_schedule.tres"
const ANALYTICS_CONFIG_PATH := "res://resources/data/analytics_config.tres"

@export var run_summary_service_path: NodePath

var _order_service: OrderService
var _game_state: GameState
var _signal_hub: SignalHub
var _analytics: AnalyticsStub
var _audio: AudioDirector
var _persistence: PersistenceService
var _run_summary: RunSummaryService
var _run_start_time_ms: int = 0
var _game_over_dispatched: bool = false

func _ready() -> void:
    _refresh_references()
    _apply_configuration()
    _connect_signals()

func _exit_tree() -> void:
    _disconnect_signals()

func _refresh_references() -> void:
    _order_service = OrderService.get_instance()
    _game_state = GameState.get_instance()
    _signal_hub = SignalHub.get_instance()
    _analytics = AnalyticsStub.get_instance()
    _audio = AudioDirector.get_instance()
    _persistence = PersistenceService.get_instance()
    if run_summary_service_path != NodePath():
        _run_summary = get_node_or_null(run_summary_service_path) as RunSummaryService
    else:
        _run_summary = null

func _apply_configuration() -> void:
    _configure_game_state()
    _configure_analytics()

func _connect_signals() -> void:
    if _order_service:
        if not _order_service.order_resolved_success.is_connected(_on_order_success):
            _order_service.order_resolved_success.connect(_on_order_success)
        if not _order_service.order_resolved_failure.is_connected(_on_order_failure):
            _order_service.order_resolved_failure.connect(_on_order_failure)

func _disconnect_signals() -> void:
    if _order_service:
        if _order_service.order_resolved_success.is_connected(_on_order_success):
            _order_service.order_resolved_success.disconnect(_on_order_success)
        if _order_service.order_resolved_failure.is_connected(_on_order_failure):
            _order_service.order_resolved_failure.disconnect(_on_order_failure)

func _configure_game_state() -> void:
    if _game_state == null:
        return
    var options: Dictionary = {}
    var combo_curve_resource := _load_resource(COMBO_CURVE_PATH)
    if combo_curve_resource is ComboCurveProfile:
        options["combo_curve"] = combo_curve_resource.to_curve()
        options["combo_curve_max_combo"] = maxi(1, combo_curve_resource.points.size())
    var wave_schedule_resource := _load_resource(WAVE_SCHEDULE_PATH)
    if wave_schedule_resource is WaveScheduleResource:
        var lengths: Array = wave_schedule_resource.wave_lengths
        if lengths is Array and not lengths.is_empty():
            options["wave_schedule"] = lengths
        options["starting_lives"] = wave_schedule_resource.get_starting_lives()
    if not options.is_empty():
        options["score_reset"] = true
        _game_state.configure(options)
    _run_start_time_ms = Time.get_ticks_msec()
    _game_over_dispatched = false
    if _run_summary:
        _run_summary.start_run({
            "lives_remaining": _game_state.get_lives() if _game_state else 0,
        })

func _configure_analytics() -> void:
    if _analytics == null:
        return
    var config := _load_resource(ANALYTICS_CONFIG_PATH)
    if config is AnalyticsConfigResource:
        _analytics.configure(config)

func _load_resource(path: String) -> Resource:
    if path.is_empty():
        return null
    if not ResourceLoader.exists(path):
        return null
    return load(path)

func _on_order_success(order_id: StringName, payload: Dictionary) -> void:
    if _game_state == null:
        return
    var base_points: int = int(payload.get("base_score", 0))
    var normalized: float = float(payload.get("normalized_remaining", 0.0))
    var metadata := {
        "wave_index": payload.get("wave_index", 0),
        "descriptor_id": payload.get("expected_descriptor_id", StringName()),
    }
    var state := _game_state.apply_success(base_points, normalized, metadata)
    _broadcast_success(order_id, payload, state)
    _log_analytics(StringName("order_fulfilled"), order_id, payload, state, StringName("success"))
    _play_audio(StringName("order_success"))

func _on_order_failure(order_id: StringName, reason: StringName, payload: Dictionary) -> void:
    if _game_state == null:
        return
    var metadata := {
        "wave_index": payload.get("wave_index", 0),
        "descriptor_id": payload.get("expected_descriptor_id", StringName()),
    }
    var state := _game_state.apply_failure(reason, metadata)
    _broadcast_failure(order_id, reason, payload, state)
    _log_analytics(StringName("order_failed"), order_id, payload, state, reason)
    _play_audio(StringName("order_failure"))
    _maybe_handle_game_over(state, reason)

func _broadcast_success(order_id: StringName, payload: Dictionary, state: Dictionary) -> void:
    if _signal_hub:
        var delta: int = int(state.get("score_delta", 0))
        if delta != 0:
            _signal_hub.broadcast_score_update(int(state.get("total_score", 0)), delta)
        _signal_hub.broadcast_combo_update(int(state.get("combo", 0)), float(state.get("combo_multiplier", 1.0)))
        var combined := payload.duplicate(true)
        combined.merge(state, true)
        combined["order_id"] = order_id
        combined["result"] = StringName("success")
        _signal_hub.broadcast_order_success(order_id, combined)

func _broadcast_failure(order_id: StringName, reason: StringName, payload: Dictionary, state: Dictionary) -> void:
    if _signal_hub:
        _signal_hub.broadcast_combo_update(int(state.get("combo", 0)), float(state.get("combo_multiplier", 1.0)))
        _signal_hub.broadcast_lives_update(int(state.get("lives", 0)))
        var combined := payload.duplicate(true)
        combined.merge(state, true)
        combined["order_id"] = order_id
        combined["result"] = reason
        combined["reason"] = reason
        combined["combo_snapshot"] = state.get("combo_snapshot", combined.get("combo_snapshot", 0))
        combined["failure_streak"] = state.get("failure_streak", combined.get("failure_streak", 0))
        _signal_hub.broadcast_order_failure(order_id, reason, combined)

func _log_analytics(event_name: StringName, order_id: StringName, payload: Dictionary, state: Dictionary, result: StringName) -> void:
    if _analytics == null:
        return
    var analytics_payload := _build_analytics_payload(order_id, payload, state, result)
    _analytics.log_event(event_name, analytics_payload)

func _build_analytics_payload(order_id: StringName, payload: Dictionary, state: Dictionary, result: StringName) -> Dictionary:
    return {
        "order_id": order_id,
        "descriptor_id": payload.get("expected_descriptor_id", StringName()),
        "delivered_descriptor_id": payload.get("delivered_descriptor_id", StringName()),
        "remaining_time": payload.get("remaining_time", 0.0),
        "normalized_remaining": payload.get("normalized_remaining", 0.0),
        "combo": state.get("combo", 0),
        "combo_multiplier": state.get("combo_multiplier", 1.0),
        "score_delta": state.get("score_delta", 0),
        "total_score": state.get("total_score", 0),
        "wave_index": state.get("wave_index", 0),
        "lives": state.get("lives", 0),
        "result": result,
        "reason": payload.get("reason", result),
        "combo_snapshot": state.get("combo_snapshot", payload.get("combo_snapshot", 0)),
        "failure_streak": state.get("failure_streak", 0),
    }

func _play_audio(event_name: StringName) -> void:
    if _audio and event_name != StringName():
        _audio.play_event(event_name)

func _maybe_handle_game_over(state: Dictionary, reason: StringName) -> void:
    if _game_over_dispatched:
        return
    var lives := int(state.get("lives", 0))
    if lives > 0:
        return
    _game_over_dispatched = true
    var now_ms := Time.get_ticks_msec()
    var duration_sec := max((now_ms - _run_start_time_ms) / 1000.0, 0.0)
    var summary: Dictionary
    if _run_summary:
        summary = _run_summary.finalize_run({
            "failure_reason": String(reason),
            "duration_sec": float(duration_sec),
        })
        summary["timestamp_ms"] = now_ms
    else:
        summary = {
            "score": _game_state.get_score() if _game_state else 0,
            "wave": int(state.get("wave_index", _game_state.get_wave_index() if _game_state else 0)),
            "failure_reason": String(reason),
            "duration_sec": float(duration_sec),
            "combo_peak": _game_state.get_combo_peak() if _game_state else int(state.get("combo_peak", 0)),
            "timestamp_sec": Time.get_unix_time_from_system(),
            "timestamp_ms": now_ms,
        }
    if _persistence and _persistence.has_method("append_run_record"):
        _persistence.append_run_record(summary)
    var director := SceneDirector.get_instance()
    if director:
        director.request_game_over(summary)
