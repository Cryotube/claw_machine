extends Node

const SceneDirector := preload("res://autoload/scene_director.gd")

func _ready() -> void:
	var director := SceneDirector.get_instance()
	if director and director.get_current_scene_id() == StringName():
		director.transition_to(StringName("title"))
