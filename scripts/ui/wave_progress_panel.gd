extends Control
class_name WaveProgressPanel

@export var warning_flash_duration_sec: float = 2.0

@onready var _progress_bar: ProgressBar = %WaveProgressBar
@onready var _wave_label: Label = %WaveLabel
@onready var _status_label: Label = %WaveStatusLabel

var _total_orders: int = 1
var _warning_timer: SceneTreeTimer

func show_wave(wave_index: int, total_orders: int, patience_multiplier: float, score_multiplier: float) -> void:
    _total_orders = max(total_orders, 1)
    if _progress_bar:
        _progress_bar.max_value = _total_orders
        _progress_bar.value = 0
    if _wave_label:
        _wave_label.text = "Wave %d" % wave_index
    if _status_label:
        _status_label.text = _format_status(patience_multiplier, score_multiplier)
    show()

func update_progress(spawned: int) -> void:
    if _progress_bar == null:
        return
    _progress_bar.value = clamp(spawned, 0, _total_orders)

func show_warning(message: String) -> void:
    if _status_label == null:
        return
    _status_label.text = message
    _restart_warning_timer()

func show_wave_completed(summary: Dictionary) -> void:
    if _status_label == null:
        return
    var resolved: int = int(summary.get("resolved", 0))
    var duration_ms: int = int(summary.get("duration_ms", 0))
    var seconds: float = duration_ms / 1000.0
    _status_label.text = "Wave clear: %d orders in %.1fs" % [resolved, seconds]

func hide_warning() -> void:
    if _status_label == null:
        return
    _status_label.text = ""

func _restart_warning_timer() -> void:
    if _warning_timer and _warning_timer.timeout.is_connected(_on_warning_timeout):
        _warning_timer.timeout.disconnect(_on_warning_timeout)
    var tree := get_tree()
    if tree == null:
        return
    _warning_timer = tree.create_timer(max(warning_flash_duration_sec, 0.1))
    _warning_timer.timeout.connect(_on_warning_timeout)

func _on_warning_timeout() -> void:
    hide_warning()

func _format_status(patience_multiplier: float, score_multiplier: float) -> String:
    var patience_pct := int(round(patience_multiplier * 100.0))
    var score_pct := int(round(score_multiplier * 100.0))
    return "Patience: %d%% | Score: %d%%" % [patience_pct, score_pct]
