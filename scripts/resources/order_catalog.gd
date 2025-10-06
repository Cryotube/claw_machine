extends Resource
class_name OrderCatalog

const OrderDefinition := preload("res://scripts/resources/order_definition.gd")

@export var orders: Array = []

func get_order(order_id: StringName) -> OrderDefinition:
    for definition in orders:
        if definition == null:
            continue
        if definition.order_id == order_id:
            return definition
    return null

func get_next(index: int) -> OrderDefinition:
    if orders.is_empty():
        return null
    var clamped_index: int = wrapi(index, 0, orders.size())
    return orders[clamped_index] as OrderDefinition
