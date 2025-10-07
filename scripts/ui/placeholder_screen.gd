extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")

@export var title: String = "Placeholder"
@export_multiline var description: String = "Content coming soon."

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _back_button: Button = %BackButton

func _ready() -> void:
	_title_label.text = title
	_body_label.text = description
	_back_button.pressed.connect(_on_back_pressed)

func apply_metadata(metadata: Dictionary) -> void:
	if metadata.has("title"):
		title = String(metadata["title"])
		if _title_label:
			_title_label.text = title
	if metadata.has("description"):
		description = String(metadata["description"])
		if _body_label:
			_body_label.text = description

func _on_back_pressed() -> void:
	SceneDirector.get_instance().transition_to(StringName("main_menu"), {"entry": "placeholder_back"})
