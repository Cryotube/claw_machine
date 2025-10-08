extends "res://tests/gut/gut_stub.gd"

const GameOverScreen := preload("res://ui/screens/game_over_screen.tscn")
const SceneDirector := preload("res://autoload/scene_director.gd")
const Settings := preload("res://autoload/settings.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")

var _director: Node
var _settings: Settings
var _analytics: AnalyticsStub
var _settings_snapshot: Dictionary = {}

func before_each() -> void:
	_director = SceneDirector.get_instance()
	_settings = Settings.get_instance()
	_analytics = AnalyticsStub.get_instance()
	assert_true(_director != null, "SceneDirector singleton should exist for game over tests")
	assert_true(_settings != null, "Settings singleton should exist for game over tests")
	assert_true(_analytics != null, "Analytics stub should exist for game over tests")
	_settings_snapshot = {
		"reduced_motion": _settings.is_reduced_motion_enabled(),
	}
	_analytics.clear_events()
	_settings.set_reduced_motion_enabled(false)
	await _director_transition_to(StringName("records"))

func after_each() -> void:
	if _analytics:
		_analytics.clear_events()
	if _settings_snapshot.has("reduced_motion"):
		_settings.set_reduced_motion_enabled(_settings_snapshot.get("reduced_motion", false))
	await _director_transition_to(StringName("title"))

func test_apply_metadata_updates_summary_and_logs_event() -> void:
	var screen := await _instantiate_game_over_screen()
	var metadata := {
		"score": 555,
		"wave": 9,
		"failure_reason": "timeout",
		"duration_sec": 75.0,
		"combo_peak": 4,
	}
	screen.call("apply_metadata", metadata)
	await wait_frames(2)
	var summary_label: Label = screen.get_node_or_null("%SummaryLabel")
	assert_true(summary_label != null, "Game over screen should expose summary label")
	if summary_label == null:
		return
	var text := summary_label.text
	assert_true(text.find("Score: 555") != -1, "Summary should include score value")
	assert_true(text.find("Wave Reached: 9") != -1, "Summary should include wave value")
	var event: Variant = _find_last_event(StringName("game_over_shown"))
	assert_true(event != null, "Applying metadata should log game_over_shown event")
	if event:
		var payload: Dictionary = event.get("payload", {})
		assert_eq(payload.get("score"), 555, "Analytics payload should capture score")
		assert_false(payload.get("auto", true), "Initial game over analytics should record manual display")

func test_auto_advance_transitions_to_records_after_timeout() -> void:
	var screen := await _instantiate_game_over_screen()
	screen.call("apply_metadata", {"score": 100})
	await wait_frames(1)
	screen.set("_remaining_time", 0.15)
	screen.set("_auto_dispatched", false)
	var transition_event: Dictionary = {}
	_director.scene_transitioned.connect(func(scene_id, metadata):
		transition_event = {"id": scene_id, "metadata": metadata.duplicate(true)}
	, CONNECT_ONE_SHOT)
	await wait_frames(40)
	assert_eq(transition_event.get("id"), StringName("records"), "Auto advance should transition to records screen")
	var metadata: Dictionary = transition_event.get("metadata", {})
	assert_eq(metadata.get("entry"), StringName("auto"), "Auto advance should tag metadata with auto entry")
	var event: Variant = _find_last_event(StringName("menu_nav"))
	assert_true(event != null, "Auto advance should log menu_nav analytics event")
	if event:
		var payload: Dictionary = event.get("payload", {})
		assert_eq(payload.get("action"), StringName("game_over_auto"), "Auto advance analytics should record auto action")

func test_continue_button_transitions_and_logs_event() -> void:
	var screen := await _instantiate_game_over_screen()
	screen.call("apply_metadata", {"score": 200})
	await wait_frames(1)
	var continue_button: Button = screen.get_node_or_null("%ContinueButton")
	assert_true(continue_button != null, "Game over screen should expose continue button")
	if continue_button == null:
		return
	var transition_event: Dictionary = {}
	_director.scene_transitioned.connect(func(scene_id, metadata):
		transition_event = {"id": scene_id, "metadata": metadata.duplicate(true)}
	, CONNECT_ONE_SHOT)
	continue_button.emit_signal("pressed")
	await wait_frames(40)
	assert_eq(transition_event.get("id"), StringName("records"), "Continue button should transition to records screen")
	var metadata: Dictionary = transition_event.get("metadata", {})
	assert_eq(metadata.get("entry"), StringName("game_over"), "Continue button should tag metadata with game_over entry")
	var event: Variant = _find_last_event(StringName("menu_nav"))
	assert_true(event != null, "Continue button should log menu_nav event")
	if event:
		var payload: Dictionary = event.get("payload", {})
		assert_eq(payload.get("action"), StringName("game_over_continue"), "Analytics payload should record continue action")

func test_reduced_motion_hides_progress_bar() -> void:
	_settings.set_reduced_motion_enabled(true)
	var screen := await _instantiate_game_over_screen()
	var progress_bar: TextureProgressBar = screen.get_node_or_null("%ProgressBar")
	assert_true(progress_bar != null, "Game over screen should expose progress bar")
	if progress_bar == null:
		return
	assert_false(progress_bar.visible, "Progress bar should hide when reduced motion enabled")

func _instantiate_game_over_screen() -> Control:
	var node := GameOverScreen.instantiate()
	add_child_autofree(node)
	await wait_frames(4)
	return node

func _find_last_event(event_name: StringName) -> Variant:
	if _analytics == null:
		return null
	var events := _analytics.debug_get_events()
	for i in range(events.size() - 1, -1, -1):
		var entry := events[i]
		if entry.get("event") == event_name:
			return entry
	return null

func _director_transition_to(scene_id: StringName) -> void:
	if _director == null:
		return
	if _director.is_transition_in_progress():
		await wait_frames(20)
	_director.transition_to(scene_id)
	await wait_frames(30)
