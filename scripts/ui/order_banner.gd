extends Control
class_name OrderBanner

const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")
const LocalizationService = preload("res://autoload/localization_service.gd")

@onready var _item_label: Label = %ItemLabel
@onready var _hint_label: RichTextLabel = %HintLabel
@onready var _icon_texture_rect: TextureRect = %IconTexture

var _active_order_id: StringName = StringName()

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
    _apply_icon(order.icon_path)
    show()

func clear_order() -> void:
    _active_order_id = StringName()
    _item_label.text = ""
    _hint_label.text = ""
    _icon_texture_rect.texture = null
    hide()

func update_safe_area(is_portrait: bool, padding: Vector2) -> void:
    var margin: Vector2 = padding if is_portrait else Vector2(padding.x, padding.y * 0.5)
    anchor_left = 0.05
    anchor_top = 0.04
    anchor_right = 0.95
    anchor_bottom = 0.2 if is_portrait else 0.18
    offset_left = margin.x
    offset_top = margin.y
    offset_right = -margin.x
    offset_bottom = 0.0

func _apply_icon(path: String) -> void:
    if path.is_empty():
        _icon_texture_rect.texture = null
        return
    if ResourceLoader.exists(path):
        _icon_texture_rect.texture = load(path)
    else:
        _icon_texture_rect.texture = null

func debug_get_active_order_id() -> StringName:
    return _active_order_id
