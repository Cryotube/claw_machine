extends "res://tests/gut/gut_stub.gd"

const MainMenu := preload("res://ui/screens/main_menu.tscn")
const SceneDirector := preload("res://autoload/scene_director.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")

var _director: Node
var _analytics: AnalyticsStub
var _signal_hub: Node
var _last_transition: Dictionary = {}
var _last_overlay: Dictionary = {}
var _navigation_events: Array[Dictionary] = []

func before_each() -> void:
	_director = SceneDirector.get_instance()
	_analytics = AnalyticsStub.get_instance()
	_signal_hub = SignalHub.get_instance()
	assert_true(_director != null, "SceneDirector singleton should be present for main menu tests")
	assert_true(_analytics != null, "Analytics stub should be available")
	assert_true(_signal_hub != null, "Signal hub should be available")
	_last_transition.clear()
	_last_overlay.clear()
	_navigation_events.clear()
	if _analytics:
		_analytics.clear_events()
	_director_connect()
	await director_transition_to(StringName("main_menu"))

func after_each() -> void:
	director_disconnect()
	if _analytics:
		_analytics.clear_events()
	await director_transition_to(StringName("title"))

func test_start_tile_transitions_to_session_and_logs() -> void:
	var menu := MainMenu.instantiate()
	add_child_autofree(menu)
	await wait_frames(4)
	var start_button: Button = menu.get_node_or_null("%StartTile")
	assert_true(start_button != null, "Main menu should expose StartTile button")
	if start_button == null:
		return
	start_button.emit_signal("pressed")
	await wait_frames(40)
	assert_eq(_last_transition.get("scene_id"), StringName("session"), "Start tile should switch to gameplay session")
	assert_true(_assert_last_menu_nav(StringName("main_menu"), StringName("start")), "Start tile should log analytics event")

func test_practice_tile_transitions_to_practice_scene() -> void:
	var menu := MainMenu.instantiate()
	add_child_autofree(menu)
	await wait_frames(4)
	var practice_button: Button = menu.get_node_or_null("%PracticeTile")
	assert_true(practice_button != null, "Main menu should expose PracticeTile button")
	if practice_button == null:
		return
	practice_button.emit_signal("pressed")
	await wait_frames(40)
	assert_eq(_last_transition.get("scene_id"), StringName("practice"), "Practice tile should load practice playground")
	assert_true(_assert_last_menu_nav(StringName("main_menu"), StringName("practice")), "Practice tile should log analytics event")

func test_options_tile_pushes_overlay_with_menu_context() -> void:
	var menu := MainMenu.instantiate()
	add_child_autofree(menu)
	await wait_frames(4)
	var options_button: Button = menu.get_node_or_null("%OptionsTile")
	assert_true(options_button != null, "Main menu should expose OptionsTile button")
	if options_button == null:
		return
	options_button.emit_signal("pressed")
	await wait_frames(6)
	assert_eq(_last_overlay.get("overlay_id"), StringName("options"), "Options tile should push options overlay")
	var metadata: Dictionary = _last_overlay.get("metadata", {})
	assert_eq(metadata.get("context"), "main_menu", "Options overlay metadata should capture main menu context")
	SceneDirector.get_instance().pop_overlay()
	await wait_frames(4)

func test_records_tile_transitions_to_records() -> void:
	var menu := MainMenu.instantiate()
	add_child_autofree(menu)
	await wait_frames(4)
	var records_button: Button = menu.get_node_or_null("%RecordsTile")
	assert_true(records_button != null, "Main menu should expose RecordsTile button")
	if records_button == null:
		return
	records_button.emit_signal("pressed")
	await wait_frames(40)
	assert_eq(_last_transition.get("scene_id"), StringName("records"), "Records tile should navigate to records screen")
	assert_true(_assert_last_menu_nav(StringName("main_menu"), StringName("records")), "Records tile should log analytics event")

func test_apply_metadata_broadcasts_entry_navigation() -> void:
	var menu := MainMenu.instantiate()
	add_child_autofree(menu)
	await wait_frames(4)
	var metadata := {
		"entry": "tutorial_return",
		"origin": "tutorial",
	}
	menu.call("apply_metadata", metadata)
	await wait_frames(2)
	var matches := []
	for event in _navigation_events:
		if event.get("scene_id") == StringName("main_menu"):
			matches.append(event)
	assert_true(matches.size() > 0, "Metadata application should broadcast navigation event via signal hub")
	if matches.size() > 0:
		var payload: Dictionary = matches.back().get("metadata", {})
		assert_eq(payload.get("entry"), "tutorial_return", "Navigation metadata should include entry context")

func director_connect() -> void:
	if _director == null:
		return
	_director.scene_transitioned.connect(_on_scene_transitioned)
	_director.overlay_pushed.connect(_on_overlay_pushed)
	if _signal_hub and not _signal_hub.navigation_transition.is_connected(_on_navigation_event):
		_signal_hub.navigation_transition.connect(_on_navigation_event)

func director_disconnect() -> void:
	if _director:
		if _director.scene_transitioned.is_connected(_on_scene_transitioned):
			_director.scene_transitioned.disconnect(_on_scene_transitioned)
		if _director.overlay_pushed.is_connected(_on_overlay_pushed):
			_director.overlay_pushed.disconnect(_on_overlay_pushed)
	if _signal_hub and _signal_hub.navigation_transition.is_connected(_on_navigation_event):
		_signal_hub.navigation_transition.disconnect(_on_navigation_event)

func director_transition_to(scene_id: StringName) -> void:
	if _director == null:
		return
	if _director.is_transition_in_progress():
		await wait_frames(20)
	_director.transition_to(scene_id)
	await wait_frames(30)

func _assert_last_menu_nav(source: StringName, action: StringName) -> bool:
	if _analytics == null:
		return false
	var events := _analytics.debug_get_events()
	for i in range(events.size() - 1, -1, -1):
		var entry := events[i]
		if entry.get("event") != StringName("menu_nav"):
			continue
		var payload: Dictionary = entry.get("payload", {})
		if payload.get("source") == source and payload.get("action") == action:
			return true
	return false

func _on_scene_transitioned(scene_id: StringName, metadata: Dictionary) -> void:
	_last_transition = {
		"scene_id": scene_id,
		"metadata": metadata.duplicate(true),
	}

func _on_overlay_pushed(overlay_id: StringName, metadata: Dictionary) -> void:
	_last_overlay = {
		"overlay_id": overlay_id,
		"metadata": metadata.duplicate(true),
	}

func _on_navigation_event(scene_id: StringName, metadata: Dictionary) -> void:
	_navigation_events.append({
		"scene_id": scene_id,
		"metadata": metadata.duplicate(true),
	})
