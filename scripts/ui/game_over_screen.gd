extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const Settings := preload("res://autoload/settings.gd")

const AUTO_ADVANCE_SEC: float = 6.0

@onready var _summary_label: Label = %SummaryLabel
@onready var _countdown_label: Label = %CountdownLabel
@onready var _progress_bar: TextureProgressBar = %ProgressBar
@onready var _continue_button: Button = %ContinueButton
@onready var _share_button: Button = %ShareButton

var _analytics: AnalyticsStub
var _settings: Settings
var _summary_data: Dictionary = {}
var _remaining_time: float = AUTO_ADVANCE_SEC
var _auto_dispatched: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_analytics = AnalyticsStub.get_instance()
	_settings = Settings.get_instance()
	_continue_button.pressed.connect(_on_continue_pressed)
	_share_button.pressed.connect(_on_share_pressed)
	set_process(true)
	_progress_bar.max_value = AUTO_ADVANCE_SEC
	_progress_bar.value = AUTO_ADVANCE_SEC
	_update_summary_label()
	_update_countdown_display()

func apply_metadata(metadata: Dictionary) -> void:
	_summary_data = metadata.duplicate(true)
	_update_summary_label()
	_emit_game_over_event(false)

func _process(delta: float) -> void:
	if _auto_dispatched:
		return
	_remaining_time = maxf(_remaining_time - delta, 0.0)
	if not _is_reduced_motion():
		_progress_bar.value = _remaining_time
	_update_countdown_display()
	if _remaining_time <= 0.0:
		_auto_dispatched = true
		_emit_game_over_event(true)
		_log_menu_nav(StringName("game_over_auto"))
		SceneDirector.get_instance().transition_to(StringName("records"), {"entry": "auto"})

func _on_continue_pressed() -> void:
	if _auto_dispatched:
		return
	_auto_dispatched = true
	_log_menu_nav(StringName("game_over_continue"))
	SceneDirector.get_instance().transition_to(StringName("records"), {"entry": "game_over"})

func _on_share_pressed() -> void:
	_log_menu_nav(StringName("game_over_share"))
	# Placeholder: integrate sharing workflow later.

func _update_summary_label() -> void:
	var score := int(_summary_data.get("score", 0))
	var wave := int(_summary_data.get("wave", 1))
	var reason := String(_summary_data.get("failure_reason", _summary_data.get("reason", "timeout"))).capitalize()
	var combo := int(_summary_data.get("combo_peak", _summary_data.get("combo", 0)))
	var duration := float(_summary_data.get("duration_sec", 0.0))
	var duration_text := ""
	if duration > 0.0:
		duration_text = "\nRun Duration: %.1fs" % duration
	_summary_label.text = "Score: %d\nWave Reached: %d\nCombo Peak: %d\nReason: %s%s" % [
		score,
		wave,
		combo,
		reason,
		duration_text,
	]

func _update_countdown_display() -> void:
	var seconds := int(ceil(_remaining_time))
	_countdown_label.text = "Auto advancing in %d" % max(seconds, 0)
	if _is_reduced_motion():
		_progress_bar.visible = false

func _is_reduced_motion() -> bool:
	return _settings != null and _settings.is_reduced_motion_enabled()

func _emit_game_over_event(auto: bool) -> void:
	if _analytics == null:
		return
	var payload := {
		"score": int(_summary_data.get("score", 0)),
		"wave": int(_summary_data.get("wave", 1)),
		"failure_reason": String(_summary_data.get("failure_reason", _summary_data.get("reason", "timeout"))),
		"duration_sec": float(_summary_data.get("duration_sec", 0.0)),
		"auto": auto,
		"timestamp_ms": Time.get_ticks_msec(),
	}
	_analytics.log_event(StringName("game_over_shown"), payload)

func _log_menu_nav(action: StringName) -> void:
	if _analytics == null:
		return
	_analytics.log_event(StringName("menu_nav"), {
		"source": StringName("game_over"),
		"action": action,
		"timestamp_ms": Time.get_ticks_msec(),
	})
