extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")

@onready var _summary_label: Label = %SummaryLabel
@onready var _continue_button: Button = %ContinueButton

func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)

func apply_metadata(metadata: Dictionary) -> void:
	var score := metadata.get("score", 0)
	var wave := metadata.get("wave", 1)
	var reason := metadata.get("reason", "timeout")
	_summary_label.text = "Score: %d\nWave: %d\nReason: %s" % [int(score), int(wave), String(reason).capitalize()]

func _on_continue_pressed() -> void:
	SceneDirector.get_instance().transition_to(StringName("main_menu"), {"entry": "game_over"})
