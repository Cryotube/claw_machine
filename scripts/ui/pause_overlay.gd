extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_resume_button.pressed.connect(_on_resume)
	_restart_button.pressed.connect(_on_restart)
	_options_button.pressed.connect(_on_options)
	_quit_button.pressed.connect(_on_quit)
	_resume_button.grab_focus()

func apply_metadata(metadata: Dictionary) -> void:
	if metadata.has("resume_focus"):
		var button_name := String(metadata["resume_focus"])
		var node := get_node_or_null(button_name)
		if node and node is Control:
			(node as Control).grab_focus()

func _on_resume() -> void:
	SceneDirector.get_instance().pop_overlay()

func _on_restart() -> void:
	var director := SceneDirector.get_instance()
	director.pop_overlay()
	director.transition_to(StringName("session"), {"entry": "restart"})

func _on_options() -> void:
	SceneDirector.get_instance().push_overlay(StringName("options"), {"context": "pause"})

func _on_quit() -> void:
	var director := SceneDirector.get_instance()
	director.pop_overlay()
	director.transition_to(StringName("main_menu"), {"entry": "pause_quit"})
