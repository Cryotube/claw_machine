extends Control
class_name OrderBanner

const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")
const LocalizationService = preload("res://autoload/localization_service.gd")
const OrderAssetLibrary := preload("res://scripts/services/order_asset_library.gd")

const STAGE_LABELS: Array[String] = ["Calm", "Hurry", "Critical"]
const STAGE_COLORS: Array = [
    {"bg": Color(0.168627, 0.529412, 0.431373, 1.0), "fg": Color(0.921569, 1.0, 0.964706, 1.0)},
    {"bg": Color(0.870588, 0.576471, 0.105882, 1.0), "fg": Color(0.054902, 0.047059, 0.015686, 1.0)},
    {"bg": Color(0.827451, 0.258824, 0.32549, 1.0), "fg": Color(1.0, 0.94902, 0.94902, 1.0)},
]
const PALETTE_COLORS: Dictionary = {
    StringName("default"): Color(0.270588, 0.372549, 0.478431, 1.0),
    StringName("warm"): Color(0.768627, 0.462745, 0.333333, 1.0),
    StringName("cool"): Color(0.321569, 0.509804, 0.623529, 1.0),
    StringName("neon"): Color(0.368627, 0.780392, 0.678431, 1.0)
}

@onready var _item_label: Label = %OrderLabel
@onready var _hint_label: RichTextLabel = %HintLabel
@onready var _cat_texture: TextureRect = %CatTexture
@onready var _patience_chip: Label = %PatienceChip
@onready var _combo_label: Label = %ComboLabel
@onready var _failure_icon: ColorRect = %FailureIcon
@onready var _portrait_frame: ColorRect = $Panel/Content/Portrait/Frame

var _active_order_id: StringName = StringName()
var _failure_active: bool = false
var _current_icon: Texture2D
var _current_stage: int = 0

func _ready() -> void:
    hide()

func show_order(order: OrderRequestDto) -> void:
    if order == null:
        return
    _active_order_id = order.order_id
    var localization = LocalizationService.get_instance()
    var item_key: StringName = StringName(order.seafood_name)
    var hint_key: StringName = order.tutorial_hint_key
    var item_text: String = localization.get_text(item_key) if localization else String(item_key)
    var hint_text: String = localization.get_text(hint_key) if localization else String(hint_key)
    _item_label.text = item_text
    _hint_label.text = hint_text
    _apply_icon(order.icon_texture, order.icon_path, order.descriptor_id)
    _apply_palette(order.highlight_palette)
    update_stage(0)
    _failure_active = false
    if has_meta("failure_active"):
        set_meta("failure_active", false)
    _failure_icon.visible = false
    _combo_label.visible = false
    show()

func clear_order() -> void:
    _active_order_id = StringName()
    _item_label.text = ""
    _hint_label.text = ""
    _cat_texture.texture = null
    _current_icon = null
    _failure_active = false
    if has_meta("failure_active"):
        set_meta("failure_active", false)
    _failure_icon.visible = false
    _combo_label.visible = false
    hide()

func update_safe_area(is_portrait: bool, padding: Vector2) -> void:
    var margin: Vector2 = padding if is_portrait else Vector2(padding.x * 0.6, padding.y * 0.4)
    anchor_left = 0.04
    anchor_top = 0.035
    anchor_right = 0.96
    anchor_bottom = 0.22 if is_portrait else 0.18
    offset_left = margin.x
    offset_top = margin.y
    offset_right = -margin.x
    offset_bottom = -margin.y * 0.25

func trigger_failure_feedback() -> void:
    _failure_active = true
    set_meta("failure_active", true)
    _failure_icon.visible = true

func is_failure_active() -> bool:
    return _failure_active

func _apply_icon(texture: Texture2D, path: String, descriptor_id: StringName) -> void:
    var resolved: Texture2D = texture
    if resolved == null:
        resolved = OrderAssetLibrary.get_icon(descriptor_id, path)
    _current_icon = resolved
    _cat_texture.texture = resolved

func update_stage(stage: int) -> void:
    var clamped := clampi(stage, 0, STAGE_LABELS.size() - 1)
    _current_stage = clamped
    var stage_label_text: String = STAGE_LABELS[clamped]
    _patience_chip.text = stage_label_text.to_upper()
    var stage_data: Dictionary = STAGE_COLORS[clamped]
    _patience_chip.add_theme_color_override("font_color", _resolve_color(stage_data, "fg", Color.WHITE))
    # Stage chip background handled via theme; no extra indicator node required.

func update_combo(combo: int, multiplier: float) -> void:
    if combo <= 1:
        _combo_label.visible = false
        return
    _combo_label.visible = true
    _combo_label.text = "Combo ×%d  (%.2f×)" % [combo, multiplier]

func _apply_palette(palette_id: StringName) -> void:
    _portrait_frame.color = _resolve_palette_color(palette_id, _portrait_frame.color)

func debug_get_active_order_id() -> StringName:
    return _active_order_id

func debug_get_current_icon() -> Texture2D:
    return _current_icon

func _resolve_color(data: Dictionary, key: String, fallback: Color) -> Color:
    var value: Variant = data.get(key, fallback)
    return value if value is Color else fallback

func _resolve_palette_color(palette_id: StringName, fallback: Color) -> Color:
    var default_value: Variant = PALETTE_COLORS.get(StringName("default"), fallback)
    var selection: Variant = PALETTE_COLORS.get(palette_id, default_value)
    if selection is Color:
        return selection
    if default_value is Color:
        return default_value
    return fallback
