class_name OrderAssetLibrary

const OrderCatalog := preload("res://scripts/resources/order_catalog.gd")
const OrderDefinition := preload("res://scripts/resources/order_definition.gd")
const ORDER_CATALOG_PATH := "res://resources/data/order_catalog.tres"

static var _catalog: OrderCatalog
static var _icons_by_descriptor: Dictionary = {}
static var _icons_by_path: Dictionary = {}

static func get_icon(descriptor_id: StringName, path: String = "") -> Texture2D:
    _ensure_cache()
    if _icons_by_descriptor.has(descriptor_id):
        return _icons_by_descriptor[descriptor_id]
    if not path.is_empty():
        var key := StringName(path)
        if _icons_by_path.has(key):
            return _icons_by_path[key]
    return null

static func get_icon_for_descriptor(descriptor_id: StringName) -> Texture2D:
    _ensure_cache()
    return _icons_by_descriptor.get(descriptor_id, null)

static func get_icon_for_path(path: String) -> Texture2D:
    if path.is_empty():
        return null
    _ensure_cache()
    return _icons_by_path.get(StringName(path), null)

static func _ensure_cache() -> void:
    if not _icons_by_descriptor.is_empty():
        return
    if _catalog == null:
        var loaded := load(ORDER_CATALOG_PATH)
        if loaded is OrderCatalog:
            _catalog = loaded
        else:
            return
    for definition in _catalog.orders:
        if not (definition is OrderDefinition):
            continue
        var order_def: OrderDefinition = definition
        var icon: Texture2D = order_def.icon
        if icon:
            _icons_by_descriptor[order_def.descriptor_id] = icon
            var resource_path: String = icon.resource_path
            if not resource_path.is_empty():
                _icons_by_path[StringName(resource_path)] = icon
    _icons_by_descriptor = _icons_by_descriptor.duplicate()
    _icons_by_path = _icons_by_path.duplicate()
