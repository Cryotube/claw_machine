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
const VirtualJoystick = preload("res://scripts/ui/virtual_joystick.gd")
const SessionScorePanel = preload("res://scripts/ui/session_score_panel.gd")
const GameState = preload("res://autoload/game_state.gd")
const FailureBanner = preload("res://scripts/ui/failure_banner.gd")
const SessionHUD = preload("res://scripts/ui/session_hud.gd")
const OrderCatalog := preload("res://scripts/resources/order_catalog.gd")
const ORDER_CATALOG: OrderCatalog = preload("res://resources/data/order_catalog.tres")
const TutorialOverlay := preload("res://scripts/ui/tutorial_overlay.gd")

@onready var _queue: CustomerQueue = %CustomerQueue
@onready var _order_banner: OrderBanner = %OrderBanner
@onready var _patience_meter: PatienceMeter = %PatienceMeter
@onready var _controls_root: Control = %Controls
@onready var _joystick: VirtualJoystick = %VirtualJoystick
@onready var _extend_button: BaseButton = %ExtendButton
@onready var _retract_button: BaseButton = %RetractButton
@onready var _score_panel: SessionScorePanel = %SessionScorePanel
@onready var _failure_banner: FailureBanner = %FailureBanner
@onready var _session_hud: SessionHUD = $UI
@onready var _tutorial_overlay: TutorialOverlay = %TutorialOverlay

var _active_order_id: StringName = StringName()
var _debug_order_index: int = 0

func _ready() -> void:
    randomize()
    _connect_signals()
    _initialize_score_panel()
    _update_safe_area()
    _show_tutorial_if_needed()

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
        hub.combo_updated.connect(_on_combo_updated)

func _initialize_score_panel() -> void:
    if _score_panel == null:
        return
    var state := GameState.get_instance()
    if state:
        _score_panel.set_initial_values(state.get_score(), state.get_combo(), state.get_lives())

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
        if hub.combo_updated.is_connected(_on_combo_updated):
            hub.combo_updated.disconnect(_on_combo_updated)

func _on_order_requested(order: OrderRequestDto) -> void:
    _active_order_id = order.order_id
    if _patience_meter:
        _patience_meter.bind_order(order.order_id, order.patience_duration, order.warning_threshold, order.critical_threshold)
        _patience_meter.set_stage(PatienceMeter.PATIENCE_STAGE_PENDING)

func _on_order_cleared(order_id: StringName) -> void:
    if order_id != _active_order_id:
        return
    _active_order_id = StringName()
    if _patience_meter:
        _patience_meter.clear()

func _on_patience_updated(order_id: StringName, normalized_remaining: float) -> void:
    if order_id != _active_order_id:
        return
    if _patience_meter:
        _patience_meter.update_remaining(normalized_remaining)

func _on_patience_stage_changed(order_id: StringName, stage: int) -> void:
    if order_id != _active_order_id:
        return
    if _patience_meter:
        _patience_meter.set_stage(stage)
    if _order_banner:
        _order_banner.update_stage(stage)
    var audio := AudioDirector.get_instance()
    if audio:
        match stage:
            PatienceMeter.PATIENCE_STAGE_WARNING:
                audio.play_event(StringName("patience_warning"))
            PatienceMeter.PATIENCE_STAGE_CRITICAL:
                audio.play_event(StringName("patience_critical"))

func _on_combo_updated(combo_count: int, multiplier: float) -> void:
    if _order_banner:
        _order_banner.update_combo(combo_count, multiplier)

func _show_tutorial_if_needed() -> void:
    var settings := Settings.get_instance()
    if settings == null:
        return
    if settings.tutorial_completed:
        return
    if _tutorial_overlay:
        _tutorial_overlay.dismissed.connect(_on_tutorial_dismissed, CONNECT_ONE_SHOT)
        _tutorial_overlay.show_overlay()

func _on_tutorial_dismissed() -> void:
    var settings := Settings.get_instance()
    if settings and settings.has_method("mark_tutorial_complete"):
        settings.mark_tutorial_complete()

func _spawn_debug_order() -> void:
    if ORDER_CATALOG == null or ORDER_CATALOG.orders.is_empty():
        return
    var definition := ORDER_CATALOG.get_next(_debug_order_index)
    _debug_order_index += 1
    if definition == null:
        return
    var dto := OrderRequestDto.new()
    dto.order_id = StringName("debug_%s_%d" % [String(definition.order_id), Time.get_ticks_msec()])
    dto.seafood_name = String(definition.localization_key)
    dto.icon_path = definition.icon_path
    dto.tutorial_hint_key = definition.tutorial_hint_key
    dto.descriptor_id = definition.descriptor_id
    dto.highlight_palette = definition.highlight_palette
    dto.icon_texture = definition.icon
    dto.patience_duration = definition.patience_duration
    dto.warning_threshold = definition.warning_threshold
    dto.critical_threshold = definition.critical_threshold
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
    if _session_hud:
        _session_hud.update_layout(is_portrait, padding)
    _layout_claw_controls(viewport_size, padding, is_portrait)

func _layout_claw_controls(viewport_size: Vector2, padding: Vector2, is_portrait: bool) -> void:
    if _controls_root == null:
        return
    var joystick_margin := Vector2(48.0, 48.0)
    if _joystick:
        var joystick_position := Vector2(padding.x + joystick_margin.x, viewport_size.y - padding.y - _joystick.size.y - joystick_margin.y)
        if not is_portrait:
            joystick_position.y = viewport_size.y - padding.y - _joystick.size.y - joystick_margin.y * 0.5
        _joystick.position = joystick_position
    var button_offset := Vector2(120.0, 140.0)
    if _extend_button:
        var grab_position := Vector2(viewport_size.x - padding.x - _extend_button.size.x - button_offset.x, viewport_size.y - padding.y - _extend_button.size.y - button_offset.y)
        if not is_portrait:
            grab_position.y = viewport_size.y * 0.6 - _extend_button.size.y * 0.5
        _extend_button.position = grab_position
    if _retract_button:
        var drop_position := Vector2(viewport_size.x - padding.x - _retract_button.size.x - button_offset.x * 0.6, viewport_size.y - padding.y - _retract_button.size.y - button_offset.y * 1.4)
        if not is_portrait:
            drop_position.y = viewport_size.y * 0.46 - _retract_button.size.y * 0.5
        _retract_button.position = drop_position
