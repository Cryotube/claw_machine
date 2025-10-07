extends "res://tests/gut/gut_stub.gd"

const SceneDirector := preload("res://autoload/scene_director.gd")
const Settings := preload("res://autoload/settings.gd")

func before_each() -> void:
	var director := SceneDirector.get_instance()
	if director == null:
		return
	await wait_frames(2)
	director.transition_to(StringName("title"))
	await wait_frames(20)

func test_transition_to_main_menu() -> void:
	var director := SceneDirector.get_instance()
	assert_true(director != null, "SceneDirector singleton should be available")
	if director == null:
		return
	director.transition_to(StringName("main_menu"))
	await wait_frames(20)
	assert_eq(director.get_current_scene_id(), StringName("main_menu"), "SceneDirector should load main menu scene")

func test_transition_to_tutorial_scene() -> void:
	var director := SceneDirector.get_instance()
	if director == null:
		return
	director.transition_to(StringName("tutorial"))
	await wait_frames(20)
	assert_eq(director.get_current_scene_id(), StringName("tutorial"), "SceneDirector should load tutorial scene")

func test_transition_to_practice_scene() -> void:
	var director := SceneDirector.get_instance()
	if director == null:
		return
	director.transition_to(StringName("practice"))
	await wait_frames(20)
	assert_eq(director.get_current_scene_id(), StringName("practice"), "SceneDirector should load practice scene")

func test_push_pop_pause_overlay() -> void:
	var director := SceneDirector.get_instance()
	if director == null:
		return
	director.transition_to(StringName("session"))
	await wait_frames(20)
	director.push_overlay(StringName("pause"), {"context": "test"})
	await wait_frames(4)
	assert_true(get_tree().paused, "Tree should pause when pause overlay shown")
	director.pop_overlay()
	await wait_frames(4)
	assert_false(get_tree().paused, "Tree should resume when pause overlay closed")

func test_reduced_motion_skips_fade_wait() -> void:
	var director := SceneDirector.get_instance()
	var settings := Settings.get_instance()
	if director == null or settings == null:
		return
	settings.set_reduced_motion_enabled(true)
	director.transition_to(StringName("main_menu"))
	await wait_frames(3)
	assert_false(director.is_transition_in_progress(), "Transition should complete quickly when reduced motion enabled")
	settings.set_reduced_motion_enabled(false)
	await wait_frames(5)
