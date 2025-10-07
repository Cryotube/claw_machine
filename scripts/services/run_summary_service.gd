extends Node
class_name RunSummaryService

const SignalHub := preload("res://autoload/signal_hub.gd")
const GameState := preload("res://autoload/game_state.gd")
const PersistenceService := preload("res://autoload/persistence_service.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")

const RUN_SUMMARY_EVENT := StringName("run_summary")

var _hub: SignalHub
var _game_state: GameState
var _persistence: PersistenceService
var _analytics: AnalyticsStub

var _run_active: bool = false
var _run_start_ms: int = 0
var _failure_reason: String = "unknown"
var _latest_wave: int = 0
var _wave_history: Array[Dictionary] = []
var _summary_cache: Dictionary = {}
var _best_combo_peak: int = 0

func _ready() -> void:
	_hub = SignalHub.get_instance()
	_game_state = GameState.get_instance()
	_persistence = PersistenceService.get_instance()
	_analytics = AnalyticsStub.get_instance()
	_connect_signals()

func start_run(metadata: Dictionary = {}) -> void:
	_run_active = true
	_run_start_ms = Time.get_ticks_msec()
	_failure_reason = String(metadata.get("failure_reason", "unknown"))
	_latest_wave = 0
	_wave_history.clear()
	_best_combo_peak = 0
	_summary_cache = {}
	_broadcast_reset(metadata)

func abort_run() -> void:
	_run_active = false
	_summary_cache = {}

func finalize_run(extra: Dictionary = {}) -> Dictionary:
	var summary := _build_summary(extra)
	_summary_cache = summary.duplicate(true)
	_run_active = false
	_emit_analytics(summary)
	if _hub:
		_hub.broadcast_run_summary(summary.duplicate(true))
	return summary

func get_last_summary() -> Dictionary:
	return _summary_cache.duplicate(true)

func _connect_signals() -> void:
	if _hub:
		if not _hub.wave_completed.is_connected(_on_wave_completed):
			_hub.wave_completed.connect(_on_wave_completed)
		if not _hub.order_resolved_failure.is_connected(_on_order_failure):
			_hub.order_resolved_failure.connect(_on_order_failure)
	if _game_state:
		if not _game_state.combo_changed.is_connected(_on_combo_changed):
			_game_state.combo_changed.connect(_on_combo_changed)
		if not _game_state.wave_changed.is_connected(_on_wave_changed):
			_game_state.wave_changed.connect(_on_wave_changed)

func _on_wave_completed(_wave: int, summary: Dictionary) -> void:
	if not _run_active:
		return
	_wave_history.append(summary.duplicate(true))
	_latest_wave = maxi(_latest_wave, int(summary.get("wave_index", _wave)))

func _on_order_failure(_order_id: StringName, reason: StringName, _payload: Dictionary) -> void:
	if not _run_active:
		return
	_failure_reason = String(reason)

func _on_combo_changed(combo: int, _multiplier: float) -> void:
	if combo > _best_combo_peak:
		_best_combo_peak = combo

func _on_wave_changed(wave_index: int) -> void:
	if not _run_active:
		return
	_latest_wave = maxi(_latest_wave, wave_index)

func _build_summary(extra: Dictionary) -> Dictionary:
	var score := 0
	var lives := 0
	var combo_peak := _best_combo_peak
	var wave_index := _latest_wave
	if _game_state:
		score = _game_state.get_score()
		lives = _game_state.get_lives()
		combo_peak = maxi(combo_peak, _game_state.get_combo_peak())
		wave_index = maxi(wave_index, _game_state.get_wave_index())
	var duration_sec := 0.0
	if _run_start_ms > 0:
		var elapsed_ms := Time.get_ticks_msec() - _run_start_ms
		duration_sec = max(elapsed_ms / 1000.0, 0.0)
	var summary := {
		"score": score,
		"wave": wave_index,
		"failure_reason": extra.get("failure_reason", _failure_reason),
		"duration_sec": extra.get("duration_sec", duration_sec),
		"combo_peak": combo_peak,
		"lives_remaining": lives,
		"timestamp_sec": Time.get_unix_time_from_system(),
		"waves": _duplicate_wave_history(),
	}
	for key in extra.keys():
		summary[key] = extra[key]
	return summary

func _duplicate_wave_history() -> Array:
	var copy: Array = []
	for entry in _wave_history:
		copy.append(entry.duplicate(true))
	return copy

func _emit_analytics(summary: Dictionary) -> void:
	if _analytics == null:
		return
	var payload := summary.duplicate(true)
	payload["schema_version"] = StringName("v1")
	payload["timestamp_ms"] = Time.get_ticks_msec()
	_analytics.log_event(RUN_SUMMARY_EVENT, payload)

func _broadcast_reset(metadata: Dictionary) -> void:
	if _hub == null:
		return
	var reset_summary := {
		"score": 0,
		"wave": 0,
		"failure_reason": metadata.get("failure_reason", "pending"),
		"duration_sec": 0.0,
		"combo_peak": 0,
		"lives_remaining": metadata.get("lives_remaining", 0),
		"timestamp_sec": Time.get_unix_time_from_system(),
		"waves": [],
	}
	_hub.broadcast_run_summary(reset_summary)
