extends Node

const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")

signal order_requested(order: OrderRequestDto)
signal order_cleared(order_id: StringName)
signal patience_updated(order_id: StringName, normalized_remaining: float)
signal patience_stage_changed(order_id: StringName, stage: int)
signal order_visualized(descriptor_id: StringName, icon: Texture2D, order_id: StringName)
signal order_visual_cleared(descriptor_id: StringName, order_id: StringName)
signal order_visual_mismatch(descriptor_id: StringName, order_id: StringName)
signal claw_grab_started(order_id: StringName)
signal claw_grab_failed(order_id: StringName)
signal claw_item_captured(descriptor_id: StringName, order_id: StringName)
signal claw_item_released(descriptor_id: StringName, order_id: StringName)
signal score_updated(total_score: int, delta: int)
signal combo_updated(combo_count: int, multiplier: float)
signal lives_updated(lives: int)
signal order_resolved_success(order_id: StringName, payload: Dictionary)
signal order_resolved_failure(order_id: StringName, reason: StringName, payload: Dictionary)
signal order_failure_resolved(order_id: StringName, payload: Dictionary)
signal wave_started(wave_index: int, metadata: Dictionary)
signal wave_progress(wave_index: int, spawned: int, total: int)
signal wave_warning(wave_index: int, payload: Dictionary)
signal wave_completed(wave_index: int, summary: Dictionary)
signal navigation_transition(scene_id: StringName, metadata: Dictionary)
signal overlay_shown(overlay_id: StringName, metadata: Dictionary)
signal overlay_hidden(overlay_id: StringName)

static var _instance: Node

func _ready() -> void:
    _instance = self

static func get_instance() -> Node:
    return _instance

func announce_order(order: OrderRequestDto) -> void:
    emit_signal("order_requested", order)

func announce_order_cleared(order_id: StringName) -> void:
    emit_signal("order_cleared", order_id)

func update_patience(order_id: StringName, normalized_remaining: float) -> void:
    emit_signal("patience_updated", order_id, normalized_remaining)

func broadcast_stage(order_id: StringName, stage: int) -> void:
    emit_signal("patience_stage_changed", order_id, stage)

func broadcast_visualized(descriptor_id: StringName, icon: Texture2D, order_id: StringName) -> void:
    emit_signal("order_visualized", descriptor_id, icon, order_id)

func broadcast_visual_cleared(descriptor_id: StringName, order_id: StringName) -> void:
    emit_signal("order_visual_cleared", descriptor_id, order_id)

func broadcast_visual_mismatch(descriptor_id: StringName, order_id: StringName) -> void:
    emit_signal("order_visual_mismatch", descriptor_id, order_id)

func broadcast_claw_grab_started(order_id: StringName) -> void:
    emit_signal("claw_grab_started", order_id)

func broadcast_claw_grab_failed(order_id: StringName) -> void:
    emit_signal("claw_grab_failed", order_id)

func broadcast_claw_item_captured(descriptor_id: StringName, order_id: StringName) -> void:
    emit_signal("claw_item_captured", descriptor_id, order_id)

func broadcast_claw_item_released(descriptor_id: StringName, order_id: StringName) -> void:
    emit_signal("claw_item_released", descriptor_id, order_id)

func broadcast_score_update(total_score: int, delta: int) -> void:
    emit_signal("score_updated", total_score, delta)

func broadcast_combo_update(combo_count: int, multiplier: float) -> void:
    emit_signal("combo_updated", combo_count, multiplier)

func broadcast_lives_update(lives: int) -> void:
    emit_signal("lives_updated", lives)

func broadcast_order_success(order_id: StringName, payload: Dictionary) -> void:
    emit_signal("order_resolved_success", order_id, payload)

func broadcast_order_failure(order_id: StringName, reason: StringName, payload: Dictionary) -> void:
    emit_signal("order_resolved_failure", order_id, reason, payload)

func broadcast_order_failure_resolved(order_id: StringName, payload: Dictionary) -> void:
    emit_signal("order_failure_resolved", order_id, payload)

func broadcast_wave_started(wave_index: int, metadata: Dictionary) -> void:
    emit_signal("wave_started", wave_index, metadata.duplicate(true))

func broadcast_wave_progress(wave_index: int, spawned: int, total: int) -> void:
    emit_signal("wave_progress", wave_index, spawned, total)

func broadcast_wave_warning(wave_index: int, payload: Dictionary) -> void:
    emit_signal("wave_warning", wave_index, payload.duplicate(true))

func broadcast_wave_completed(wave_index: int, summary: Dictionary) -> void:
    emit_signal("wave_completed", wave_index, summary.duplicate(true))

func broadcast_navigation(scene_id: StringName, metadata: Dictionary) -> void:
    emit_signal("navigation_transition", scene_id, metadata.duplicate(true))

func broadcast_overlay_shown(overlay_id: StringName, metadata: Dictionary) -> void:
    emit_signal("overlay_shown", overlay_id, metadata.duplicate(true))

func broadcast_overlay_hidden(overlay_id: StringName) -> void:
    emit_signal("overlay_hidden", overlay_id)
