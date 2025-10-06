extends Node3D
class_name CabinetItemPool

const CabinetItemCatalog := preload("res://scripts/resources/cabinet_item_catalog.gd")
const CabinetItemDescriptor := preload("res://scripts/resources/cabinet_item_descriptor.gd")

@export var catalog: CabinetItemCatalog
@export var items_per_descriptor: int = 3
@export var pool_root_path: NodePath

var _pool_root: Node3D
var _available: Dictionary = {}
var _active_lookup: Dictionary = {}
var _target_items_per_descriptor: int = 0
var _current_clutter_level: int = 0
var _current_density_multiplier: float = 1.0

func _ready() -> void:
    _pool_root = get_node_or_null(pool_root_path) as Node3D
    if _pool_root == null:
        _pool_root = self
    _build_pool()

func acquire_item(descriptor_id: StringName) -> Node3D:
    if descriptor_id == StringName():
        return null
    var bucket: Array = _available.get(descriptor_id, [])
    var item: Node3D
    if bucket.is_empty():
        item = _instantiate_descriptor(descriptor_id)
    else:
        item = bucket.pop_back()
    if item == null:
        return null
    _available[descriptor_id] = bucket
    _active_lookup[item] = descriptor_id
    item.visible = true
    return item

func release_item(item: Node3D) -> void:
    if item == null:
        return
    var descriptor_id: StringName = get_descriptor_for(item)
    _active_lookup.erase(item)
    if descriptor_id != StringName():
        if not _available.has(descriptor_id):
            _available[descriptor_id] = []
        var bucket: Array = _available[descriptor_id]
        if not bucket.has(item):
            bucket.append(item)
        _available[descriptor_id] = bucket
    item.visible = false
    item.global_transform = Transform3D.IDENTITY
    if item.get_parent() != _pool_root:
        _pool_root.add_child(item)

func get_descriptor_for(item: Node3D) -> StringName:
    return _active_lookup.get(item, StringName())

func configure_for_wave(wave_index: int, clutter_level: int, density_multiplier: float, items_per_descriptor_target: int) -> void:
    _current_clutter_level = max(clutter_level, 0)
    _current_density_multiplier = max(density_multiplier, 0.0)
    _target_items_per_descriptor = max(items_per_descriptor_target, items_per_descriptor)
    _ensure_capacity(_target_items_per_descriptor)

func get_current_clutter_level() -> int:
    return _current_clutter_level

func get_current_density_multiplier() -> float:
    return _current_density_multiplier

func _ensure_capacity(target: int) -> void:
    if catalog == null or target <= 0:
        return
    for descriptor in catalog.get_descriptors():
        if descriptor == null or not (descriptor is CabinetItemDescriptor):
            continue
        var typed_descriptor: CabinetItemDescriptor = descriptor
        var descriptor_id: StringName = typed_descriptor.descriptor_id
        if descriptor_id == StringName():
            continue
        if not _available.has(descriptor_id):
            _available[descriptor_id] = []
        var bucket: Array = _available[descriptor_id]
        var active_count: int = 0
        for active in _active_lookup.keys():
            if _active_lookup[active] == descriptor_id:
                active_count += 1
        var total: int = bucket.size() + active_count
        if total >= target:
            continue
        var needed: int = target - total
        for _i in range(needed):
            var item := _instantiate_descriptor(descriptor_id)
            if item:
                item.visible = false
                bucket.append(item)
        _available[descriptor_id] = bucket

func _build_pool() -> void:
    _available.clear()
    _active_lookup.clear()
    if catalog == null:
        return
    for descriptor in catalog.get_descriptors():
        if descriptor == null or not (descriptor is CabinetItemDescriptor):
            continue
        var typed_descriptor: CabinetItemDescriptor = descriptor
        var descriptor_id: StringName = typed_descriptor.descriptor_id
        if descriptor_id == StringName():
            continue
        _available[descriptor_id] = []
        for _i in range(max(items_per_descriptor, 1)):
            var item := _instantiate_descriptor(descriptor_id)
            if item:
                item.visible = false
                _available[descriptor_id].append(item)

func _instantiate_descriptor(descriptor_id: StringName) -> Node3D:
    if catalog == null:
        return null
    var descriptor: CabinetItemDescriptor = catalog.get_descriptor(descriptor_id)
    if descriptor == null or descriptor.scene == null:
        return null
    var instance := descriptor.scene.instantiate()
    if instance is Node3D:
        var node: Node3D = instance as Node3D
        node.visible = false
        node.name = String(descriptor.descriptor_id) + StringName("_pooled")
        node.set_meta("descriptor_id", descriptor.descriptor_id)
        _pool_root.add_child(node)
        return node
    instance.queue_free()
    return null

func debug_get_available(descriptor_id: StringName) -> int:
    var bucket: Array = _available.get(descriptor_id, [])
    return bucket.size()

func debug_get_active_count() -> int:
    return _active_lookup.size()
