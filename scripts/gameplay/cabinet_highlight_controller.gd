extends Node3D
class_name CabinetHighlightController

const SignalHub := preload("res://autoload/signal_hub.gd")
const AccessibilityService := preload("res://autoload/accessibility_service.gd")
const DEFAULT_THEME := preload("res://resources/materials/cabinet_highlight_theme.tres")
const PROTAN_SOURCE := preload("res://resources/materials/palette/warning_material.tres")
const DEUTAN_SOURCE := preload("res://resources/materials/palette/success_material.tres")
const TRITAN_SOURCE := preload("res://resources/materials/palette/primary_material.tres")
const ERROR_SOURCE := preload("res://resources/materials/palette/error_material.tres")

@export var highlight_pool_scene: PackedScene
@export var marker_root_path: NodePath = NodePath("Anchors")
@export var descriptor_keys: PackedStringArray = []
@export var marker_paths: Array[NodePath] = []
@export var icon_billboard_path: NodePath
@export var pool_size: int = 6

signal highlight_ready(descriptor_id: StringName)

var _signal_hub: SignalHub
var _accessibility: AccessibilityService
var _icon_billboard: Node
var _pool: Array[Node3D] = []
var _active_highlights: Dictionary = {}
var _descriptor_markers: Dictionary = {}
var _current_palette: StringName = StringName("default")
var _palette_materials: Dictionary = {}

func _ready() -> void:
    _ensure_palette_cache()
    _signal_hub = SignalHub.get_instance()
    _accessibility = AccessibilityService.get_instance()
    _icon_billboard = get_node_or_null(icon_billboard_path)
    _cache_markers()
    _populate_pool()
    if _signal_hub:
        _signal_hub.order_visualized.connect(_on_order_visualized)
        _signal_hub.order_visual_cleared.connect(_on_order_visual_cleared)
        _signal_hub.order_visual_mismatch.connect(_on_order_visual_mismatch)
    if _accessibility:
        _current_palette = _accessibility.get_colorblind_palette()
        _accessibility.colorblind_palette_changed.connect(_on_palette_changed)

func refresh_markers() -> void:
    _cache_markers()

func _ensure_palette_cache() -> void:
    if not _palette_materials.is_empty():
        return
    _palette_materials[StringName("default")] = _duplicate_theme(DEFAULT_THEME)
    _palette_materials[StringName("protan")] = _make_palette_material(PROTAN_SOURCE)
    _palette_materials[StringName("deutan")] = _make_palette_material(DEUTAN_SOURCE)
    _palette_materials[StringName("tritan")] = _make_palette_material(TRITAN_SOURCE)
    _palette_materials[StringName("error")] = _make_palette_material(ERROR_SOURCE)

func _make_palette_material(source: StandardMaterial3D) -> StandardMaterial3D:
    var material := _duplicate_theme(DEFAULT_THEME)
    if source:
        var highlight_color: Color = source.albedo_color
        material.albedo_color = highlight_color
        material.emission = highlight_color
        material.emission_enabled = true
    return material

func _duplicate_theme(theme: StandardMaterial3D) -> StandardMaterial3D:
    if theme == null:
        return StandardMaterial3D.new()
    return theme.duplicate() as StandardMaterial3D

func _cache_markers() -> void:
    _descriptor_markers.clear()
    if descriptor_keys.size() == marker_paths.size() and not descriptor_keys.is_empty():
        for i in descriptor_keys.size():
            var marker := get_node_or_null(marker_paths[i])
            if marker is Node3D:
                _descriptor_markers[StringName(descriptor_keys[i])] = marker
        return
    var root := get_node_or_null(marker_root_path)
    if root is Node:
        for child in root.get_children():
            if child is Node3D:
                _descriptor_markers[StringName(child.name)] = child

func _populate_pool() -> void:
    _pool.clear()
    var target: int = max(pool_size, 0)
    for _i in range(target):
        var highlight: Node3D = _instantiate_highlight()
        highlight.visible = false
        add_child(highlight)
        _pool.append(highlight)

func _instantiate_highlight() -> Node3D:
    if highlight_pool_scene:
        var instance := highlight_pool_scene.instantiate()
        if instance is Node3D:
            return instance
    return Node3D.new()

func _on_order_visualized(descriptor_id: StringName, icon: Texture2D, _order_id: StringName) -> void:
    var highlight := _acquire_highlight(descriptor_id)
    _place_highlight(highlight, descriptor_id)
    _apply_palette(highlight, _current_palette)
    _apply_icon(icon)
    highlight_ready.emit(descriptor_id)

func _on_order_visual_cleared(descriptor_id: StringName, _order_id: StringName) -> void:
    if not _active_highlights.has(descriptor_id):
        return
    var highlight: Node3D = _active_highlights[descriptor_id]
    _active_highlights.erase(descriptor_id)
    _release_highlight(highlight)
    if _active_highlights.is_empty():
        _clear_icon()

func _on_order_visual_mismatch(descriptor_id: StringName, _order_id: StringName) -> void:
    if not _active_highlights.has(descriptor_id):
        return
    var highlight: Node3D = _active_highlights[descriptor_id]
    highlight.set_meta("mismatch_pulse", true)
    _apply_palette(highlight, StringName("error"))

func _on_palette_changed(palette_id: StringName) -> void:
    _current_palette = palette_id
    for highlight in _active_highlights.values():
        _apply_palette(highlight, _current_palette)

func _acquire_highlight(descriptor_id: StringName) -> Node3D:
    if _active_highlights.has(descriptor_id):
        return _active_highlights[descriptor_id]
    var highlight: Node3D
    if _pool.is_empty():
        highlight = _instantiate_highlight()
        add_child(highlight)
    else:
        highlight = _pool.pop_back()
    highlight.visible = true
    highlight.set_meta("mismatch_pulse", false)
    _active_highlights[descriptor_id] = highlight
    return highlight

func _release_highlight(highlight: Node3D) -> void:
    if highlight == null:
        return
    highlight.visible = false
    highlight.set_meta("mismatch_pulse", false)
    _pool.append(highlight)

func _place_highlight(highlight: Node3D, descriptor_id: StringName) -> void:
    var marker: Node3D = _descriptor_markers.get(descriptor_id, null)
    if marker:
        highlight.global_transform = marker.global_transform
    else:
        highlight.global_transform = global_transform

func _apply_palette(highlight: Node3D, palette_id: StringName) -> void:
    if highlight == null:
        return
    var mesh_instance := highlight as MeshInstance3D
    var material: StandardMaterial3D = _palette_materials.get(palette_id, _palette_materials.get(StringName("default"), null)) as StandardMaterial3D
    if mesh_instance and material:
        mesh_instance.material_override = material
    highlight.set_meta("palette_id", palette_id)

func _apply_icon(icon: Texture2D) -> void:
    if _icon_billboard == null:
        return
    if _icon_billboard.has_method("set_texture"):
        _icon_billboard.call("set_texture", icon)
    elif _icon_billboard.has_method("set_material_override") and icon:
        _icon_billboard.set_meta("icon_texture", icon)

func _clear_icon() -> void:
    if _icon_billboard == null:
        return
    if _icon_billboard.has_method("set_texture"):
        _icon_billboard.call("set_texture", null)
    elif _icon_billboard.has_method("set_material_override"):
        _icon_billboard.set_meta("icon_texture", null)

func debug_get_available_pool() -> int:
    return _pool.size()

func debug_get_active_highlight_id() -> int:
    for highlight in _active_highlights.values():
        return highlight.get_instance_id()
    return 0

func debug_get_active_descriptor() -> StringName:
    for descriptor in _active_highlights.keys():
        return descriptor
    return StringName()

func debug_get_active_palette() -> StringName:
    return _current_palette
