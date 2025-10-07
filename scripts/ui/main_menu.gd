extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")

@onready var _start_button: Button = %StartButton
@onready var _tutorial_button: Button = %TutorialButton
@onready var _practice_button: Button = %PracticeButton
@onready var _options_button: Button = %OptionsButton
@onready var _records_button: Button = %RecordsButton
@onready var _quit_button: Button = %QuitButton

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_start_button.pressed.connect(_on_start_pressed)
	_tutorial_button.pressed.connect(_on_tutorial_pressed)
	_practice_button.pressed.connect(_on_practice_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_records_button.pressed.connect(_on_records_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_start_button.grab_focus()

func apply_metadata(metadata: Dictionary) -> void:
	if metadata.has("entry"):
		var hub := SignalHub.get_instance()
		if hub:
			hub.broadcast_navigation(StringName("main_menu"), metadata)

func _on_start_pressed() -> void:
	SceneDirector.get_instance().transition_to(StringName("session"), {"entry": "score_run"})

func _on_tutorial_pressed() -> void:
	SceneDirector.get_instance().transition_to(StringName("tutorial"), {"entry": "tutorial"})

func _on_practice_pressed() -> void:
	SceneDirector.get_instance().transition_to(StringName("practice_stub"), {"entry": "practice"})

func _on_options_pressed() -> void:
	SceneDirector.get_instance().push_overlay(StringName("options"), {"context": "main_menu"})

func _on_records_pressed() -> void:
	SceneDirector.get_instance().transition_to(StringName("records"), {"entry": "records"})

func _on_quit_pressed() -> void:
	get_tree().quit()
