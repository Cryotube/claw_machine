extends CanvasLayer
class_name SessionHUD

const SignalHub := preload("res://autoload/signal_hub.gd")
const SessionScorePanel := preload("res://scripts/ui/session_score_panel.gd")
const OrderBanner := preload("res://scripts/ui/order_banner.gd")
const PatienceMeter := preload("res://scripts/ui/patience_meter.gd")
const FailureBanner := preload("res://scripts/ui/failure_banner.gd")

@onready var _score_panel: SessionScorePanel = %SessionScorePanel
@onready var _order_banner: OrderBanner = %OrderBanner
@onready var _patience_meter: PatienceMeter = %PatienceMeter
@onready var _failure_banner: FailureBanner = %FailureBanner

var _signal_hub: SignalHub

func _ready() -> void:
    _signal_hub = SignalHub.get_instance()
    _connect_signals()

func _exit_tree() -> void:
    _disconnect_signals()

func update_layout(is_portrait: bool, padding: Vector2) -> void:
    if _order_banner:
        _order_banner.update_safe_area(is_portrait, padding)
    if _patience_meter:
        _patience_meter.update_safe_area(is_portrait, padding)
    if _score_panel:
        _score_panel.update_safe_area(is_portrait, padding)
    if _failure_banner:
        _failure_banner.update_safe_area(is_portrait, padding)

func _connect_signals() -> void:
    if _signal_hub == null:
        return
    if not _signal_hub.order_resolved_failure.is_connected(_on_order_failure):
        _signal_hub.order_resolved_failure.connect(_on_order_failure)

func _disconnect_signals() -> void:
    if _signal_hub == null:
        return
    if _signal_hub.order_resolved_failure.is_connected(_on_order_failure):
        _signal_hub.order_resolved_failure.disconnect(_on_order_failure)

func _on_order_failure(_order_id: StringName, _reason: StringName, _payload: Dictionary) -> void:
    if _score_panel:
        _score_panel.flash_lives()
