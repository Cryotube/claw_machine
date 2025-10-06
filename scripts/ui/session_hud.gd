extends CanvasLayer
class_name SessionHUD

const SignalHub := preload("res://autoload/signal_hub.gd")
const SessionScorePanel := preload("res://scripts/ui/session_score_panel.gd")
const OrderBanner := preload("res://scripts/ui/order_banner.gd")
const PatienceMeter := preload("res://scripts/ui/patience_meter.gd")
const FailureBanner := preload("res://scripts/ui/failure_banner.gd")
const WaveProgressPanel := preload("res://scripts/ui/wave_progress_panel.gd")

@onready var _score_panel: SessionScorePanel = %SessionScorePanel
@onready var _order_banner: OrderBanner = %OrderBanner
@onready var _patience_meter: PatienceMeter = %PatienceMeter
@onready var _failure_banner: FailureBanner = %FailureBanner
@onready var _wave_panel: WaveProgressPanel = %WaveProgressPanel

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
    if _wave_panel:
        var inset := Vector2(padding.x, padding.y)
        _wave_panel.position = Vector2(inset.x + 32.0, inset.y + 12.0)

func _connect_signals() -> void:
    if _signal_hub == null:
        return
    if not _signal_hub.order_resolved_failure.is_connected(_on_order_failure):
        _signal_hub.order_resolved_failure.connect(_on_order_failure)
    if not _signal_hub.wave_started.is_connected(_on_wave_started):
        _signal_hub.wave_started.connect(_on_wave_started)
    if not _signal_hub.wave_progress.is_connected(_on_wave_progress):
        _signal_hub.wave_progress.connect(_on_wave_progress)
    if not _signal_hub.wave_warning.is_connected(_on_wave_warning):
        _signal_hub.wave_warning.connect(_on_wave_warning)
    if not _signal_hub.wave_completed.is_connected(_on_wave_completed):
        _signal_hub.wave_completed.connect(_on_wave_completed)

func _disconnect_signals() -> void:
    if _signal_hub == null:
        return
    if _signal_hub.order_resolved_failure.is_connected(_on_order_failure):
        _signal_hub.order_resolved_failure.disconnect(_on_order_failure)
    if _signal_hub.wave_started.is_connected(_on_wave_started):
        _signal_hub.wave_started.disconnect(_on_wave_started)
    if _signal_hub.wave_progress.is_connected(_on_wave_progress):
        _signal_hub.wave_progress.disconnect(_on_wave_progress)
    if _signal_hub.wave_warning.is_connected(_on_wave_warning):
        _signal_hub.wave_warning.disconnect(_on_wave_warning)
    if _signal_hub.wave_completed.is_connected(_on_wave_completed):
        _signal_hub.wave_completed.disconnect(_on_wave_completed)

func _on_order_failure(_order_id: StringName, _reason: StringName, _payload: Dictionary) -> void:
    if _score_panel:
        _score_panel.flash_lives()

func _on_wave_started(wave_index: int, metadata: Dictionary) -> void:
    if _wave_panel == null:
        return
    var total_orders: int = int(metadata.get("total_orders", metadata.get("spawn_count", 0)))
    var patience_multiplier: float = float(metadata.get("patience_multiplier", 1.0))
    var score_multiplier: float = float(metadata.get("score_multiplier", 1.0))
    _wave_panel.show_wave(wave_index, total_orders, patience_multiplier, score_multiplier)

func _on_wave_progress(_wave_index: int, spawned: int, total: int) -> void:
    if _wave_panel == null:
        return
    _wave_panel.update_progress(spawned)

func _on_wave_warning(_wave_index: int, payload: Dictionary) -> void:
    if _wave_panel == null:
        return
    var current_interval: float = float(payload.get("current_interval", 0.0))
    var next_interval: float = float(payload.get("next_interval", 0.0))
    var message := "Spawn speed up: %.1fs → %.1fs" % [current_interval, next_interval]
    _wave_panel.show_warning(message)

func _on_wave_completed(_wave_index: int, summary: Dictionary) -> void:
    if _wave_panel == null:
        return
    _wave_panel.show_wave_completed(summary)
