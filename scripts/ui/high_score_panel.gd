extends Control
class_name HighScorePanel

const PersistenceService := preload("res://autoload/persistence_service.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")

@onready var _high_value: Label = %HighValue
@onready var _delta_value: Label = %DeltaValue

var _current_high_score: int = 0

func _ready() -> void:
	_connect_signals()
	_apply_initial_state()

func _exit_tree() -> void:
	_disconnect_signals()

func update_safe_area(is_portrait: bool, padding: Vector2) -> void:
	anchor_left = 0.7 if is_portrait else 0.68
	anchor_top = 0.02
	anchor_right = 0.96 if is_portrait else 0.94
	anchor_bottom = 0.12
	offset_left = padding.x * 0.5
	offset_top = padding.y
	offset_right = -padding.x
	offset_bottom = 0.0

func _connect_signals() -> void:
	var hub := SignalHub.get_instance()
	if hub:
		if not hub.run_summary_ready.is_connected(_on_run_summary):
			hub.run_summary_ready.connect(_on_run_summary)
		if not hub.high_score_updated.is_connected(_on_high_score_updated):
			hub.high_score_updated.connect(_on_high_score_updated)
		if not hub.score_updated.is_connected(_on_score_updated):
			hub.score_updated.connect(_on_score_updated)

func _disconnect_signals() -> void:
	var hub := SignalHub.get_instance()
	if hub:
		if hub.run_summary_ready.is_connected(_on_run_summary):
			hub.run_summary_ready.disconnect(_on_run_summary)
		if hub.high_score_updated.is_connected(_on_high_score_updated):
			hub.high_score_updated.disconnect(_on_high_score_updated)
		if hub.score_updated.is_connected(_on_score_updated):
			hub.score_updated.disconnect(_on_score_updated)

func _apply_initial_state() -> void:
	var persistence := PersistenceService.get_instance()
	if persistence == null:
		_set_high_score(0)
		_set_delta(0)
		return
	var summary: Dictionary = persistence.get_records_summary()
	_apply_summary(summary)

func _on_run_summary(summary: Dictionary) -> void:
	_apply_summary(summary)

func _on_high_score_updated(high_score: int, previous_high_score: int) -> void:
	_set_high_score(high_score)
	var delta := high_score - previous_high_score
	_set_delta(delta)

func _on_score_updated(total_score: int, _delta: int) -> void:
	var delta := total_score - _current_high_score
	_set_delta(delta)

func _apply_summary(summary: Dictionary) -> void:
	if summary.is_empty():
		return
	if summary.has("high_score"):
		var high_score := int(summary.get("high_score", 0))
		var delta := 0
		if summary.has("last_run"):
			var last_run := summary.get("last_run", {}) as Dictionary
			var previous := int(summary.get("previous_score", summary.get("previous_high_score", 0)))
			delta = int(last_run.get("score", 0)) - previous
		_set_high_score(high_score)
		_set_delta(delta)
	elif summary.has("score"):
		var score := int(summary.get("score", 0))
		var delta := score - _current_high_score
		_set_delta(delta)

func _set_high_score(value: int) -> void:
	_current_high_score = max(value, 0)
	if _high_value:
		_high_value.text = str(_current_high_score)

func _set_delta(delta: int) -> void:
	if _delta_value:
		var prefix := ""
		if delta > 0:
			prefix = "+"
		elif delta < 0:
			prefix = "-"
			delta = abs(delta)
		_delta_value.text = "%s%d" % [prefix, delta]
