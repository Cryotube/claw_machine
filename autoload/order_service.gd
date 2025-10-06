extends Node

const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")
const SignalHub = preload("res://autoload/signal_hub.gd")
const GameState = preload("res://autoload/game_state.gd")

const FAILURE_RESTART_WINDOW_SEC := 2.0

signal order_requested(order: OrderRequestDto)
signal order_updated(order_id: StringName, normalized_remaining: float)
signal order_cleared(order_id: StringName)
signal patience_stage_changed(order_id: StringName, stage: int)
signal order_visualized(order: OrderRequestDto)
signal order_visual_cleared(order_id: StringName, descriptor_id: StringName)
signal order_visual_mismatch(order_id: StringName, descriptor_id: StringName)
signal order_resolved_success(order_id: StringName, payload: Dictionary)
signal order_resolved_failure(order_id: StringName, reason: StringName, payload: Dictionary)

static var _instance: Node

var _orders: Dictionary = {}
var _wave_patience_multiplier: float = 1.0
var _wave_score_multiplier: float = 1.0
var _configured_wave_index: int = 1
var _durations: Dictionary = {}
var _stage_cache: Dictionary = {}
var _descriptors: Dictionary = {}
var _icons: Dictionary = {}

func configure_wave(patience_multiplier: float, score_multiplier: float, wave_index: int) -> void:
    _wave_patience_multiplier = maxf(patience_multiplier, 0.1)
    _wave_score_multiplier = maxf(score_multiplier, 0.0)
    _configured_wave_index = max(1, wave_index)

func _ready() -> void:
    _instance = self

static func get_instance() -> Node:
    return _instance

func _process(delta: float) -> void:
    advance_time(delta)

func request_order(order: OrderRequestDto) -> void:
    if order == null:
        push_warning("Attempted to request a null order")
        return
    var order_copy: OrderRequestDto = order.duplicate(true) if order.has_method("duplicate") else OrderRequestDto.new()
    if order_copy == null:
        order_copy = OrderRequestDto.new()
    if order_copy.order_id == StringName():
        order_copy.order_id = order.order_id
    order_copy.seafood_name = order.seafood_name
    order_copy.icon_path = order.icon_path
    order_copy.tutorial_hint_key = order.tutorial_hint_key
    order_copy.descriptor_id = order.descriptor_id
    order_copy.icon_texture = order.icon_texture
    order_copy.highlight_palette = order.highlight_palette
    order_copy.patience_duration = order.patience_duration
    order_copy.warning_threshold = order.warning_threshold
    order_copy.critical_threshold = order.critical_threshold
    order_copy.base_score = order.base_score
    if order_copy.wave_index == 0:
        order_copy.wave_index = _configured_wave_index
    order_copy.patience_duration = maxf(order_copy.patience_duration * _wave_patience_multiplier, 0.1)
    var scaled_score := int(round(max(order_copy.base_score, 0) * _wave_score_multiplier))
    order_copy.base_score = max(scaled_score, 0)

    var order_id := StringName(order_copy.order_id)
    _orders[order_id] = order_copy
    _durations[order_id] = maxf(order_copy.patience_duration, 0.001)
    _stage_cache[order_id] = 0
    _descriptors[order_id] = order_copy.descriptor_id
    _icons[order_id] = order_copy.icon_texture

    emit_signal("order_requested", order_copy)
    emit_signal("order_updated", order_id, 1.0)
    emit_signal("patience_stage_changed", order_id, 0)
    emit_signal("order_visualized", order_copy)
    var hub: Node = SignalHub.get_instance()
    if hub:
        hub.announce_order(order_copy)
        hub.update_patience(order_id, 1.0)
        hub.broadcast_stage(order_id, 0)

func advance_time(delta: float) -> void:
    if delta <= 0.0 or _orders.is_empty():
        return
    var expired: Array[StringName] = []
    for order_id in _orders.keys():
        var dto: OrderRequestDto = _orders[order_id]
        var remaining: float = maxf(0.0, dto.patience_duration - delta)
        dto.patience_duration = remaining

        var duration: float = float(_durations.get(order_id, 0.001))
        var normalized: float = clampf(remaining / duration, 0.0, 1.0)
        emit_signal("order_updated", order_id, normalized)
        var hub: Node = SignalHub.get_instance()
        if hub:
            hub.update_patience(order_id, normalized)

        var stage: int = _determine_stage(dto, normalized)
        if stage != _stage_cache.get(order_id, -1):
            _stage_cache[order_id] = stage
            emit_signal("patience_stage_changed", order_id, stage)
            if hub:
                hub.broadcast_stage(order_id, stage)

        if remaining <= 0.0:
            expired.append(order_id)
    for order_id in expired:
        _resolve_timeout(order_id)

func complete_order(order_id: StringName) -> void:
    _finalize_order(order_id)

func _finalize_order(order_id: StringName) -> void:
    if not _orders.has(order_id):
        return
    var descriptor_id: StringName = _descriptors.get(order_id, StringName())
    _orders.erase(order_id)
    _durations.erase(order_id)
    _stage_cache.erase(order_id)
    _descriptors.erase(order_id)
    _icons.erase(order_id)
    emit_signal("order_cleared", order_id)
    emit_signal("order_visual_cleared", order_id, descriptor_id)
    var hub := SignalHub.get_instance()
    if hub:
        hub.announce_order_cleared(order_id)

func clear_all() -> void:
    _orders.clear()
    _durations.clear()
    _stage_cache.clear()
    _descriptors.clear()
    _icons.clear()

func _determine_stage(order: OrderRequestDto, normalized_remaining: float) -> int:
    if normalized_remaining <= order.critical_threshold:
        return 2
    if normalized_remaining <= order.warning_threshold:
        return 1
    return 0

func report_wrong_item(order_id: StringName) -> void:
    if not _orders.has(order_id):
        return
    var descriptor_id: StringName = _descriptors.get(order_id, StringName())
    emit_signal("order_visual_mismatch", order_id, descriptor_id)
    var hub := SignalHub.get_instance()
    if hub:
        hub.broadcast_stage(order_id, _stage_cache.get(order_id, 0))

func deliver_item(order_id: StringName, descriptor_id: StringName) -> void:
    if order_id == StringName() or descriptor_id == StringName():
        return
    if not _orders.has(order_id):
        return
    var expected: StringName = _descriptors.get(order_id, StringName())
    var payload := _build_resolution_payload(order_id)
    payload["delivered_descriptor_id"] = descriptor_id
    payload["expected_descriptor_id"] = expected
    if expected == descriptor_id:
        payload["result"] = StringName("success")
        emit_signal("order_resolved_success", order_id, payload)
        _finalize_order(order_id)
    else:
        var reason := StringName("mismatch")
        payload = _build_resolution_payload(order_id, reason)
        payload["result"] = reason
        emit_signal("order_resolved_failure", order_id, reason, payload)
        report_wrong_item(order_id)
        _finalize_order(order_id)

func debug_get_active_order_ids() -> Array[StringName]:
    var ids: Array[StringName] = []
    for key in _orders.keys():
        ids.append(key)
    return ids

func _resolve_timeout(order_id: StringName) -> void:
    if not _orders.has(order_id):
        return
    var reason := StringName("timeout")
    var payload := _build_resolution_payload(order_id, reason)
    payload["result"] = reason
    emit_signal("order_resolved_failure", order_id, reason, payload)
    _finalize_order(order_id)

func _build_resolution_payload(order_id: StringName, reason: StringName = StringName()) -> Dictionary:
    var dto: OrderRequestDto = _orders.get(order_id, null)
    var duration: float = float(_durations.get(order_id, 0.001))
    var remaining: float = 0.0
    if dto:
        remaining = clampf(dto.patience_duration, 0.0, duration)
    var normalized: float = 0.0
    if duration > 0.0:
        normalized = clampf(remaining / duration, 0.0, 1.0)
    var snapshot: OrderRequestDto = dto
    if dto and dto.has_method("duplicate"):
        snapshot = dto.duplicate(true)
    var game_state := GameState.get_instance()
    var combo_snapshot: int = 0
    if game_state and game_state.has_method("get_combo"):
        combo_snapshot = int(game_state.get_combo())
    var payload_reason := reason if reason != StringName() else StringName()
    return {
        "order_id": order_id,
        "order": snapshot,
        "remaining_time": remaining,
        "duration": duration,
        "normalized_remaining": normalized,
        "base_score": dto.base_score if dto else 0,
        "wave_index": dto.wave_index if dto else 0,
        "expected_descriptor_id": _descriptors.get(order_id, StringName()),
        "combo_snapshot": combo_snapshot,
        "reason": payload_reason,
        "restart_window_sec": FAILURE_RESTART_WINDOW_SEC,
    }
