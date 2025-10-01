extends Node3D
class_name SessionRoot

const OrderService = preload("res://autoload/order_service.gd")
const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")
const SignalHub = preload("res://autoload/signal_hub.gd")
const Settings = preload("res://autoload/settings.gd")
const CustomerQueue = preload("res://scripts/gameplay/customer_queue.gd")
const PatienceMeter = preload("res://scripts/ui/patience_meter.gd")
const OrderBanner = preload("res://scripts/ui/order_banner.gd")
const AudioDirector = preload("res://autoload/audio_director.gd")

@onready var _queue: CustomerQueue = %CustomerQueue
@onready var _order_banner: OrderBanner = %OrderBanner
@onready var _patience_meter: PatienceMeter = %PatienceMeter

var _active_order_id: StringName = StringName()

func _ready() -> void:
    _connect_signals()
    _update_safe_area()

func _exit_tree() -> void:
    _disconnect_signals()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        _update_safe_area()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_trigger_order"):
        _spawn_debug_order()
    elif event.is_action_pressed("serve_current_order") and _active_order_id != StringName():
        OrderService.get_instance().complete_order(_active_order_id)

func _connect_signals() -> void:
    var hub := SignalHub.get_instance()
    if hub:
        hub.order_requested.connect(_on_order_requested)
        hub.order_cleared.connect(_on_order_cleared)
        hub.patience_updated.connect(_on_patience_updated)
        hub.patience_stage_changed.connect(_on_patience_stage_changed)

func _disconnect_signals() -> void:
    var hub := SignalHub.get_instance()
    if hub:
        if hub.order_requested.is_connected(_on_order_requested):
            hub.order_requested.disconnect(_on_order_requested)
        if hub.order_cleared.is_connected(_on_order_cleared):
            hub.order_cleared.disconnect(_on_order_cleared)
        if hub.patience_updated.is_connected(_on_patience_updated):
            hub.patience_updated.disconnect(_on_patience_updated)
        if hub.patience_stage_changed.is_connected(_on_patience_stage_changed):
            hub.patience_stage_changed.disconnect(_on_patience_stage_changed)

func _on_order_requested(order: OrderRequestDto) -> void:
    _active_order_id = order.order_id
    _order_banner.show_order(order)
    _patience_meter.bind_order(order.order_id, order.patience_duration, order.warning_threshold, order.critical_threshold)
    _patience_meter.set_stage(PatienceMeter.PATIENCE_STAGE_PENDING)

func _on_order_cleared(order_id: StringName) -> void:
    if order_id != _active_order_id:
        return
    _active_order_id = StringName()
    _order_banner.clear_order()
    _patience_meter.clear()

func _on_patience_updated(order_id: StringName, normalized_remaining: float) -> void:
    if order_id != _active_order_id:
        return
    _patience_meter.update_remaining(normalized_remaining)

func _on_patience_stage_changed(order_id: StringName, stage: int) -> void:
    if order_id != _active_order_id:
        return
    _patience_meter.set_stage(stage)
    var audio := AudioDirector.get_instance()
    if audio:
        match stage:
            PatienceMeter.PATIENCE_STAGE_WARNING:
                audio.play_event(StringName("patience_warning"))
            PatienceMeter.PATIENCE_STAGE_CRITICAL:
                audio.play_event(StringName("patience_critical"))

func _spawn_debug_order() -> void:
    var dto := OrderRequestDto.new()
    dto.order_id = StringName("debug_order_%d" % Time.get_ticks_msec())
    dto.seafood_name = "order_salmon_nigiri"
    dto.icon_path = ""
    dto.tutorial_hint_key = StringName("tutorial_hint_default")
    dto.patience_duration = 12.0
    dto.warning_threshold = 0.4
    dto.critical_threshold = 0.2
    var service := OrderService.get_instance()
    if service:
        service.request_order(dto)

func _update_safe_area() -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    var is_portrait := viewport_size.y >= viewport_size.x
    var settings := Settings.get_instance()
    var padding := Vector2.ZERO
    if settings:
        padding = settings.get_safe_padding(is_portrait)
    _order_banner.update_safe_area(is_portrait, padding)
    _patience_meter.update_safe_area(is_portrait, padding)
