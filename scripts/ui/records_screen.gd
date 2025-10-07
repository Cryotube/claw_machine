extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")
const GameState := preload("res://autoload/game_state.gd")

@onready var _back_button: Button = %BackButton
@onready var _summary_label: Label = %SummaryLabel
@onready var _history_container: VBoxContainer = %HistoryContainer

func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_refresh_summary()

func apply_metadata(metadata: Dictionary) -> void:
	_refresh_summary(metadata)

func _refresh_summary(metadata: Dictionary = {}) -> void:
	var state := GameState.get_instance()
	var score_text := "No runs recorded yet."
	if state:
		var total_score := state.get_score()
		var combo := state.get_combo()
		var wave := state.get_wave_index()
		score_text = "High Score: %d\nCombo Peak: %d\nWave Reached: %d" % [total_score, combo, wave]
	if metadata.has("summary_text"):
		score_text = String(metadata["summary_text"])
	_summary_label.text = score_text
	_clear_history()
	if metadata.has("history") and metadata["history"] is Array:
		for entry in metadata["history"]:
			var label := Label.new()
			label.text = String(entry)
			_history_container.add_child(label)

func _on_back_pressed() -> void:
	SceneDirector.get_instance().transition_to(StringName("main_menu"), {"entry": "records_back"})

func _clear_history() -> void:
	for child in _history_container.get_children():
		child.queue_free()
