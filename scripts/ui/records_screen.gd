extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")
const PersistenceService := preload("res://autoload/persistence_service.gd")

const MAX_HISTORY := 10

@onready var _back_button: Button = %BackButton
@onready var _summary_label: Label = %SummaryLabel
@onready var _history_container: VBoxContainer = %HistoryContainer

func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_refresh_summary()

func apply_metadata(metadata: Dictionary) -> void:
	_refresh_summary(metadata)

func _refresh_summary(metadata: Dictionary = {}) -> void:
	var persistence := PersistenceService.get_instance()
	if persistence == null:
		_summary_label.text = "No runs recorded yet."
		_render_empty_history()
		return
	var summary := persistence.get_records_summary()
	var high_score := int(summary.get("high_score", 0))
	var best_wave := int(summary.get("best_wave", 0))
	var fastest := float(summary.get("fastest_duration_sec", 0.0))
	var fastest_text := fastest > 0.0 ? "%.1fs" % fastest : "--"
	var last_run: Dictionary = summary.get("last_run", {})
	var last_score := int(last_run.get("score", 0))
	var last_wave := int(last_run.get("wave", 0))
	var last_reason := String(last_run.get("failure_reason", "unknown")).capitalize()
	var previous_score := int(summary.get("previous_score", 0))
	var delta := last_score - previous_score
	var delta_text := previous_score > 0 ? ("%+d" % delta) : "N/A"
	if metadata.has("summary_text"):
		_summary_label.text = String(metadata["summary_text"])
	else:
		_summary_label.text = "High Score: %d\nBest Wave: %d\nLast Run: %d (Wave %d, %s)\nLast Delta: %s\nFastest Run: %s" % [
			high_score,
			best_wave,
			last_score,
			last_wave,
			last_reason,
			delta_text,
			fastest_text,
		]
	_clear_history()
	var runs: Array = persistence.get_run_records(MAX_HISTORY)
	if runs.is_empty():
		_render_empty_history()
	else:
		for run in runs:
			var label := Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			label.text = _format_run_entry(run)
			_history_container.add_child(label)

func _on_back_pressed() -> void:
	SceneDirector.get_instance().transition_to(StringName("main_menu"), {"entry": "records_back"})

func _clear_history() -> void:
	for child in _history_container.get_children():
		child.queue_free()

func _render_empty_history() -> void:
	_clear_history()
	var label := Label.new()
	label.text = "Play your first run to populate history."
	label.horizontal_alignment = HorizontalAlignment.CENTER
	_history_container.add_child(label)

func _format_run_entry(run: Dictionary) -> String:
	var timestamp := int(run.get("timestamp_sec", 0))
	var timestamp_text := "--"
	if timestamp > 0:
		timestamp_text = Time.get_datetime_string_from_unix_time(timestamp)
	var score := int(run.get("score", 0))
	var wave := int(run.get("wave", 0))
	var duration := float(run.get("duration_sec", 0.0))
	var duration_text := duration > 0.0 ? "%.1fs" % duration : "--"
	var reason := String(run.get("failure_reason", "unknown")).capitalize()
	return "%s — Score %d, Wave %d, %s, Duration %s" % [timestamp_text, score, wave, reason, duration_text]
