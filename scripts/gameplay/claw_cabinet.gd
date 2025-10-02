extends Node3D
class_name ClawCabinet

const CabinetItemCatalog := preload("res://scripts/resources/cabinet_item_catalog.gd")
const CabinetItemDescriptor := preload("res://scripts/resources/cabinet_item_descriptor.gd")
const CabinetHighlightController := preload("res://scripts/gameplay/cabinet_highlight_controller.gd")

@export var catalog: CabinetItemCatalog
@export var display_root_path: NodePath = NodePath("SeafoodDisplay")
@export var highlight_controller_path: NodePath = NodePath("CabinetHighlightController")
@export var columns: int = 5
@export var column_spacing: float = 0.9
@export var row_spacing: float = 0.9
@export var base_position: Vector3 = Vector3(-1.8, 0.15, -0.9)
@export var item_height: float = 0.0
@export var highlight_height: float = 0.45

var _display_root: Node3D
var _highlight_controller: CabinetHighlightController
var _anchors_root: Node3D

func _ready() -> void:
    _display_root = get_node_or_null(display_root_path) as Node3D
    _highlight_controller = get_node_or_null(highlight_controller_path) as CabinetHighlightController
    if _highlight_controller:
        _anchors_root = _highlight_controller.get_node_or_null(_highlight_controller.marker_root_path) as Node3D
    if catalog == null or _display_root == null or _anchors_root == null:
        return
    _populate_items()

func _populate_items() -> void:
    _clear_existing()
    var descriptors: Array = catalog.get_descriptors()
    var total: int = descriptors.size()
    if total == 0:
        return
    var max_columns: int = max(columns, 1)
    _highlight_controller.pool_size = max(_highlight_controller.pool_size, total)
    var index: int = 0
    for descriptor in descriptors:
        if descriptor == null or not (descriptor is CabinetItemDescriptor):
            continue
        var typed_descriptor: CabinetItemDescriptor = descriptor
        var local_position: Vector3 = _calculate_position(index, max_columns) + typed_descriptor.anchor_offset
        var item_instance: Node3D = _instantiate_descriptor(typed_descriptor)
        if item_instance:
            item_instance.position = local_position + Vector3(0.0, item_height, 0.0)
            item_instance.name = String(typed_descriptor.descriptor_id)
            item_instance.set_meta("descriptor_id", typed_descriptor.descriptor_id)
            _display_root.add_child(item_instance)
        _create_marker(typed_descriptor.descriptor_id, local_position)
        index += 1
    _highlight_controller.refresh_markers()

func _clear_existing() -> void:
    if _display_root:
        for child in _display_root.get_children():
            child.queue_free()
    if _anchors_root:
        for child in _anchors_root.get_children():
            child.queue_free()

func _calculate_position(index: int, max_columns: int) -> Vector3:
    var column: int = index % max_columns
    var row: int = index / max_columns
    var x := base_position.x + float(column) * column_spacing
    var y := base_position.y
    var z := base_position.z + float(row) * row_spacing
    return Vector3(x, y, z)

func _instantiate_descriptor(descriptor: CabinetItemDescriptor) -> Node3D:
    if descriptor.scene == null:
        return null
    var instance: Node = descriptor.scene.instantiate()
    if instance is Node3D:
        return instance as Node3D
    instance.queue_free()
    return null

func _create_marker(descriptor_id: StringName, local_position: Vector3) -> void:
    if _anchors_root == null:
        return
    var marker := Marker3D.new()
    marker.name = String(descriptor_id)
    marker.position = local_position + Vector3(0.0, highlight_height, 0.0)
    _anchors_root.add_child(marker)

func debug_get_descriptor_count() -> int:
    return catalog.descriptors.size() if catalog else 0
