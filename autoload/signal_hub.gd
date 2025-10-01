extends Node

const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")

signal order_requested(order: OrderRequestDto)
signal order_cleared(order_id: StringName)
signal patience_updated(order_id: StringName, normalized_remaining: float)
signal patience_stage_changed(order_id: StringName, stage: int)
signal order_visualized(descriptor_id: StringName, icon: Texture2D, order_id: StringName)
signal order_visual_cleared(descriptor_id: StringName, order_id: StringName)
signal order_visual_mismatch(descriptor_id: StringName, order_id: StringName)

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
