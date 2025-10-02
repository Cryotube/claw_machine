extends Control
class_name SessionScorePanel

const SignalHub := preload("res://autoload/signal_hub.gd")

@onready var _score_label: Label = %ScoreValue
@onready var _combo_label: Label = %ComboValue
@onready var _lives_label: Label = %LivesValue

var _pending_score: Dictionary = {}
var _pending_combo: Dictionary = {}
var _pending_lives: int = -1
var _lives_flash_timer: SceneTreeTimer

func _ready() -> void:
    _connect_signals()

func _exit_tree() -> void:
    _disconnect_signals()
    _cancel_lives_flash()

func _connect_signals() -> void:
    var hub := SignalHub.get_instance()
    if hub == null:
        return
    if not hub.score_updated.is_connected(_on_score_updated):
        hub.score_updated.connect(_on_score_updated)
    if not hub.combo_updated.is_connected(_on_combo_updated):
        hub.combo_updated.connect(_on_combo_updated)
    if not hub.lives_updated.is_connected(_on_lives_updated):
        hub.lives_updated.connect(_on_lives_updated)

func _disconnect_signals() -> void:
    var hub := SignalHub.get_instance()
    if hub == null:
        return
    if hub.score_updated.is_connected(_on_score_updated):
        hub.score_updated.disconnect(_on_score_updated)
    if hub.combo_updated.is_connected(_on_combo_updated):
        hub.combo_updated.disconnect(_on_combo_updated)
    if hub.lives_updated.is_connected(_on_lives_updated):
        hub.lives_updated.disconnect(_on_lives_updated)

func _on_score_updated(total_score: int, delta: int) -> void:
    _pending_score = {"total": total_score, "delta": delta}
    call_deferred("_apply_score_update")

func _on_combo_updated(combo_count: int, multiplier: float) -> void:
    _pending_combo = {"combo": combo_count, "multiplier": multiplier}
    call_deferred("_apply_combo_update")

func _on_lives_updated(lives: int) -> void:
    _pending_lives = lives
    call_deferred("_apply_lives_update")

func _apply_score_update() -> void:
    if _score_label == null or _pending_score.is_empty():
        return
    _score_label.text = str(_pending_score.get("total", 0))
    _pending_score.clear()

func _apply_combo_update() -> void:
    if _combo_label == null or _pending_combo.is_empty():
        return
    var combo := int(_pending_combo.get("combo", 0))
    var multiplier := float(_pending_combo.get("multiplier", 1.0))
    _combo_label.text = "%d× (%.2f)" % [combo, multiplier]
    _pending_combo.clear()

func _apply_lives_update() -> void:
    if _lives_label == null or _pending_lives < 0:
        return
    _lives_label.text = str(_pending_lives)
    _pending_lives = -1

func update_safe_area(is_portrait: bool, padding: Vector2) -> void:
    anchor_left = 0.03 if is_portrait else 0.02
    anchor_top = 0.02
    anchor_right = 0.32 if is_portrait else 0.28
    anchor_bottom = 0.14 if is_portrait else 0.12
    offset_left = padding.x
    offset_top = padding.y
    offset_right = -padding.x * 0.5
    offset_bottom = 0.0

func set_initial_values(score: int, combo: int, lives: int) -> void:
    if _score_label:
        _score_label.text = str(score)
    if _combo_label:
        _combo_label.text = "%d× (1.00)" % combo
    if _lives_label:
        _lives_label.text = str(lives)

func flash_lives() -> void:
    if _lives_label == null:
        return
    _cancel_lives_flash()
    _lives_label.modulate = Color(1.0, 0.5, 0.5)
    _lives_flash_timer = get_tree().create_timer(0.35)
    _lives_flash_timer.timeout.connect(_on_lives_flash_timeout)

func _cancel_lives_flash() -> void:
    if _lives_flash_timer:
        if _lives_flash_timer.timeout.is_connected(_on_lives_flash_timeout):
            _lives_flash_timer.timeout.disconnect(_on_lives_flash_timeout)
        _lives_flash_timer.queue_free()
        _lives_flash_timer = null

func _on_lives_flash_timeout() -> void:
    _lives_flash_timer = null
    if _lives_label:
        _lives_label.modulate = Color(1, 1, 1)
