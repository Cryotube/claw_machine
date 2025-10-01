extends Node

const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")

signal order_requested(order: OrderRequestDto)
signal order_cleared(order_id: StringName)
signal patience_updated(order_id: StringName, normalized_remaining: float)
signal patience_stage_changed(order_id: StringName, stage: int)

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
