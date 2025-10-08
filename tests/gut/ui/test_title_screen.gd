extends "res://tests/gut/gut_stub.gd"

const TitleScreen := preload("res://ui/screens/title_screen.tscn")
const SceneDirector := preload("res://autoload/scene_director.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const LocalizationService := preload("res://autoload/localization_service.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")

var _director: Node
var _analytics: AnalyticsStub
var _localization: Node
var _signal_hub: Node
var _last_transition: Dictionary = {}
var _last_overlay: Dictionary = {}
var _navigation_events: Array[Dictionary] = []

func before_each() -> void:
	_director = SceneDirector.get_instance()
	_analytics = AnalyticsStub.get_instance()
	_localization = LocalizationService.get_instance()
	_signal_hub = SignalHub.get_instance()
	assert_true(_director != null, "SceneDirector singleton should be available for title tests")
	assert_true(_analytics != null, "Analytics stub should be available for tracking events")
	assert_true(_localization != null, "Localization service singleton should be available")
	assert_true(_signal_hub != null, "SignalHub singleton should be available")
	_last_transition.clear()
	_last_overlay.clear()
	if _analytics:
		_analytics.clear_events()
	if _localization and _localization.has_method("set_locale"):
		_localization.set_locale(StringName("en"))
	if _director:
		_director.scene_transitioned.connect(_on_scene_transitioned)
		_director.overlay_pushed.connect(_on_overlay_pushed)
	await director_transition_to(StringName("title"))
	_navigation_events.clear()
	if _signal_hub:
		_signal_hub.navigation_transition.connect(_on_navigation_event)

func after_each() -> void:
	if _director:
		if _director.scene_transitioned.is_connected(_on_scene_transitioned):
			_director.scene_transitioned.disconnect(_on_scene_transitioned)
		if _director.overlay_pushed.is_connected(_on_overlay_pushed):
			_director.overlay_pushed.disconnect(_on_overlay_pushed)
	if _signal_hub and _signal_hub.navigation_transition.is_connected(_on_navigation_event):
		_signal_hub.navigation_transition.disconnect(_on_navigation_event)
	if _localization and _localization.has_method("set_locale"):
		_localization.set_locale(StringName("en"))
	await director_transition_to(StringName("title"))

func test_start_button_transitions_to_session_and_logs_event() -> void:
	var instance := TitleScreen.instantiate()
	add_child_autofree(instance)
	await wait_frames(4)
	var start_button: Button = instance.get_node_or_null("%PrimaryTile")
	assert_true(start_button != null, "Title screen should provide PrimaryTile button")
	if start_button == null:
		return
	start_button.emit_signal("pressed")
	await wait_frames(40)
	assert_eq(_last_transition.get("scene_id"), StringName("session"), "Start tile should transition to session scene")
	var events := _analytics.debug_get_events() if _analytics else []
	var menu_events: Array[Dictionary] = []
	for entry in events:
		if entry.get("event") == StringName("menu_nav"):
			menu_events.append(entry)
	assert_true(menu_events.size() > 0, "Start tile should log menu_nav analytics event")
	if menu_events.size() > 0:
		var payload: Dictionary = menu_events.back().get("payload", {})
		assert_eq(payload.get("source"), StringName("title"), "Analytics source should be title screen")
		assert_eq(payload.get("action"), StringName("title_start_run"), "Analytics action should match start CTA")

func test_options_button_pushes_overlay_with_context_title() -> void:
	var instance := TitleScreen.instantiate()
	add_child_autofree(instance)
	await wait_frames(4)
	var options_button: Button = instance.get_node_or_null("%OptionsTile")
	assert_true(options_button != null, "Title screen should provide options tile")
	if options_button == null:
		return
	options_button.emit_signal("pressed")
	await wait_frames(6)
	assert_eq(_last_overlay.get("overlay_id"), StringName("options"), "Options tile should push options overlay")
	var metadata: Dictionary = _last_overlay.get("metadata", {})
	assert_eq(metadata.get("context"), "title", "Options overlay metadata should record title context")
SceneDirector.get_instance().pop_overlay()
	await wait_frames(4)

func test_locale_button_toggles_locale_and_broadcasts_navigation() -> void:
	var instance := TitleScreen.instantiate()
	add_child_autofree(instance)
	await wait_frames(4)
	var locale_button: Button = instance.get_node_or_null("%LocaleButton")
	assert_true(locale_button != null, "Locale toggle button should be available on title screen")
	if locale_button == null:
		return
	assert_eq(_localization.get_locale(), StringName("en"), "Locale should start as English for test")
	locale_button.emit_signal("pressed")
	await wait_frames(6)
	assert_eq(_localization.get_locale(), StringName("ja"), "Locale toggle should switch to Japanese")
	var matching_events: Array[Dictionary] = []
	for event in _navigation_events:
		if event.get("scene_id") == StringName("locale_toggle"):
			matching_events.append(event)
	assert_true(matching_events.size() > 0, "Locale toggle should broadcast navigation event")
	if matching_events.size() > 0:
		var payload: Dictionary = matching_events.back().get("metadata", {})
		assert_eq(payload.get("source"), "title", "Locale toggle metadata should record originating screen")

func director_transition_to(scene_id: StringName) -> void:
	if _director == null:
		return
	if _director.is_transition_in_progress():
		await wait_frames(20)
	_director.transition_to(scene_id)
	await wait_frames(30)

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
