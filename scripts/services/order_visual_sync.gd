extends Node
class_name OrderVisualSync

const OrderService := preload("res://autoload/order_service.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const AudioDirector := preload("res://autoload/audio_director.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")
const OrderBanner := preload("res://scripts/ui/order_banner.gd")
const OrderAssetLibrary := preload("res://scripts/services/order_asset_library.gd")

@export var order_banner: OrderBanner

var _order_service: OrderService
var _signal_hub: SignalHub
var _audio: AudioDirector
var _order_descriptors: Dictionary = {}
var _order_icons: Dictionary = {}

func _ready() -> void:
    _order_service = OrderService.get_instance()
    _signal_hub = SignalHub.get_instance()
    _audio = AudioDirector.get_instance()
    if _order_service:
        if _order_service.has_signal("order_visualized"):
            _order_service.connect("order_visualized", Callable(self, "_on_service_visualized"))
        if _order_service.has_signal("order_visual_cleared"):
            _order_service.connect("order_visual_cleared", Callable(self, "_on_service_visual_cleared"))
        if _order_service.has_signal("order_visual_mismatch"):
            _order_service.connect("order_visual_mismatch", Callable(self, "_on_service_mismatch"))
        _order_service.order_requested.connect(_on_order_requested)

func _on_order_requested(order: OrderRequestDto) -> void:
    _cache_order_visual(order)

func _on_service_visualized(order: OrderRequestDto) -> void:
    if order == null:
        return
    _cache_order_visual(order)
    _emit_visual(order.descriptor_id, order.order_id)
    if order_banner:
        order_banner.show_order(order)

func _on_service_visual_cleared(order_id: StringName, descriptor_id: StringName) -> void:
    _order_icons.erase(order_id)
    _order_descriptors.erase(order_id)
    if order_banner:
        order_banner.clear_order()
    if _signal_hub:
        _signal_hub.broadcast_visual_cleared(descriptor_id, order_id)

func _on_service_mismatch(order_id: StringName, descriptor_id: StringName) -> void:
    if descriptor_id == StringName() and _order_descriptors.has(order_id):
        descriptor_id = _order_descriptors[order_id]
    if _signal_hub:
        _signal_hub.broadcast_visual_mismatch(descriptor_id, order_id)
    if _audio:
        _audio.play_event(StringName("order_mismatch_warning"))
    if order_banner:
        order_banner.trigger_failure_feedback()
    _emit_visual(descriptor_id, order_id)

func notify_wrong_item(order_id: StringName) -> void:
    var descriptor_id: StringName = _order_descriptors.get(order_id, StringName())
    _on_service_mismatch(order_id, descriptor_id)

func _cache_order_visual(order: OrderRequestDto) -> void:
    if order == null:
        return
    var descriptor_id: StringName = order.descriptor_id
    var order_id: StringName = order.order_id
    _order_descriptors[order_id] = descriptor_id
    var icon: Texture2D = order.icon_texture
    if icon == null:
        icon = OrderAssetLibrary.get_icon(descriptor_id, order.icon_path)
    _order_icons[order_id] = icon

func _emit_visual(descriptor_id: StringName, order_id: StringName) -> void:
    if _signal_hub == null:
        return
    var icon: Texture2D = _order_icons.get(order_id, null)
    _signal_hub.broadcast_visualized(descriptor_id, icon, order_id)
