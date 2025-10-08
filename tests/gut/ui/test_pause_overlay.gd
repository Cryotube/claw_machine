extends "res://tests/gut/gut_stub.gd"

const SceneDirector := preload("res://autoload/scene_director.gd")
const Settings := preload("res://autoload/settings.gd")
const AccessibilityService := preload("res://autoload/accessibility_service.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")

var _director: Node
var _settings: Settings
var _accessibility: AccessibilityService
var _analytics: AnalyticsStub
var _settings_snapshot: Dictionary = {}
var _palette_snapshot: StringName = StringName()

func before_each() -> void:
	_director = SceneDirector.get_instance()
	_settings = Settings.get_instance()
	_accessibility = AccessibilityService.get_instance()
	_analytics = AnalyticsStub.get_instance()
	assert_true(_director != null, "SceneDirector singleton should be loaded")
	assert_true(_settings != null, "Settings singleton should be available")
	assert_true(_accessibility != null, "Accessibility service should be available")
	assert_true(_analytics != null, "Analytics stub should be available")
	_snapshot_settings()
	_palette_snapshot = _accessibility.get_colorblind_palette()
	if _analytics:
		_analytics.clear_events()
	if _director:
		_director.pop_all_overlays()
		_director.lock_input(false)
	get_tree().paused = false
	await _director_transition_to(StringName("session"))

func after_each() -> void:
	if _director:
		_director.pop_all_overlays()
		_director.lock_input(false)
	get_tree().paused = false
	if _analytics:
		_analytics.clear_events()
	_restore_settings()
	if _accessibility and _palette_snapshot != StringName():
		_accessibility.set_colorblind_palette(_palette_snapshot)
	await _director_transition_to(StringName("title"))

func test_pause_overlay_pauses_tree_and_resume_unpauses() -> void:
	var overlay := await _push_pause_overlay()
	assert_true(get_tree().paused, "Pause overlay should pause the scene tree")
	var resume_button: Button = overlay.get_node_or_null("%ResumeButton")
	assert_true(resume_button != null, "Pause overlay should expose resume button")
	if resume_button == null:
		return
	resume_button.emit_signal("pressed")
	await wait_frames(4)
	assert_false(get_tree().paused, "Resume button should unpause the scene tree")
	assert_true(_is_overlay_stack_empty(), "Overlay stack should be empty after resume")

func test_palette_button_cycles_palette_and_logs() -> void:
	_accessibility.set_colorblind_palette(StringName("default"))
	var overlay := await _push_pause_overlay()
	var palette_button: Button = overlay.get_node_or_null("%PaletteButton")
	assert_true(palette_button != null, "Pause overlay should expose palette button")
	if palette_button == null:
		return
	var palettes: Array[StringName] = overlay.PALETTES
	var current_index := palettes.find(_accessibility.get_colorblind_palette())
	var expected_index := (current_index + 1) % palettes.size()
	palette_button.emit_signal("pressed")
	await wait_frames(2)
	assert_eq(_accessibility.get_colorblind_palette(), palettes[expected_index], "Palette button should cycle to next palette")
	var event: Variant = _find_last_event(StringName("toggle_accessibility"))
	assert_true(event != null, "Palette button should emit accessibility analytics event")
	if event:
		var payload: Dictionary = event.get("payload", {})
		assert_eq(payload.get("setting"), StringName("colorblind_palette"), "Analytics payload should reference colorblind palette")
		assert_eq(payload.get("context"), StringName("pause"), "Analytics context should mark pause overlay")

func test_sensitivity_button_cycles_presets_and_updates_settings() -> void:
	_settings.set_camera_sensitivity(1.0)
	var overlay := await _push_pause_overlay()
	var sensitivity_button: Button = overlay.get_node_or_null("%SensitivityButton")
	assert_true(sensitivity_button != null, "Pause overlay should expose sensitivity button")
	if sensitivity_button == null:
		return
	var presets: Array[float] = overlay.SENSITIVITY_PRESETS
	var current_value := _settings.get_camera_sensitivity()
	var current_index := 0
	for i in range(presets.size()):
		if is_equal_approx(presets[i], current_value):
			current_index = i
			break
	sensitivity_button.emit_signal("pressed")
	await wait_frames(2)
	var expected_index := (current_index + 1) % presets.size()
	assert_true(is_equal_approx(_settings.get_camera_sensitivity(), presets[expected_index]), "Sensitivity button should advance to next preset")
	var event: Variant = _find_last_event(StringName("toggle_accessibility"))
	assert_true(event != null, "Sensitivity button should log analytics event")
	if event:
		var payload: Dictionary = event.get("payload", {})
		assert_eq(payload.get("setting"), StringName("camera_sensitivity_preset"), "Analytics payload should indicate sensitivity preset change")
		assert_eq(float(payload.get("value", -1.0)), presets[expected_index], "Analytics payload should capture preset value")

func test_options_button_pushes_options_overlay() -> void:
	var overlay := await _push_pause_overlay()
	var options_button: Button = overlay.get_node_or_null("%OptionsButton")
	assert_true(options_button != null, "Pause overlay should expose options button")
	if options_button == null:
		return
	var overlay_event: Dictionary = {}
	_director.overlay_pushed.connect(func(id, metadata):
		overlay_event = {"id": id, "metadata": metadata.duplicate(true)}
	, CONNECT_ONE_SHOT)
	options_button.emit_signal("pressed")
	await wait_frames(4)
	assert_eq(overlay_event.get("id"), StringName("options"), "Options button should push options overlay on stack")
	var metadata: Dictionary = overlay_event.get("metadata", {})
	assert_eq(metadata.get("context"), "pause", "Options overlay metadata should include pause context")
	_director.pop_overlay()
	await wait_frames(2)

func test_quit_button_transitions_to_main_menu() -> void:
	await _director_transition_to(StringName("session"))
	var overlay := await _push_pause_overlay()
	var quit_button: Button = overlay.get_node_or_null("%QuitButton")
	assert_true(quit_button != null, "Pause overlay should expose quit button")
	if quit_button == null:
		return
	var transition_event: Dictionary = {}
	_director.scene_transitioned.connect(func(scene_id, metadata):
		transition_event = {"id": scene_id, "metadata": metadata.duplicate(true)}
	, CONNECT_ONE_SHOT)
	quit_button.emit_signal("pressed")
	await wait_frames(40)
	assert_eq(transition_event.get("id"), StringName("main_menu"), "Quit button should navigate back to main menu")
	var metadata: Dictionary = transition_event.get("metadata", {})
	assert_eq(metadata.get("entry"), StringName("pause_quit"), "Quit transition should include pause metadata")
	assert_true(_is_overlay_stack_empty(), "Pause overlay should be removed after quitting")

func _push_pause_overlay() -> Control:
	if _director == null:
		return null
	_director.pop_all_overlays()
	_director.push_overlay(StringName("pause"))
	await wait_frames(4)
	var overlay := _get_active_overlay()
	assert_true(overlay != null, "Pause overlay should be instantiated")
	return overlay

func _get_active_overlay() -> Control:
	var holder := get_tree().root.get_node_or_null("SceneDirectorUI/OverlayHolder")
	if holder == null or holder.get_child_count() == 0:
		return null
	var child := holder.get_child(holder.get_child_count() - 1)
	return child as Control

func _is_overlay_stack_empty() -> bool:
	var holder := get_tree().root.get_node_or_null("SceneDirectorUI/OverlayHolder")
	return holder == null or holder.get_child_count() == 0

func _find_last_event(event_name: StringName) -> Variant:
	if _analytics == null:
		return null
	var events := _analytics.debug_get_events()
	for i in range(events.size() - 1, -1, -1):
		var entry := events[i]
		if entry.get("event") == event_name:
			return entry
	return null

func _snapshot_settings() -> void:
	_settings_snapshot = {
		"camera_sensitivity": _settings.get_camera_sensitivity(),
		"haptics_enabled": _settings.is_haptics_enabled(),
		"haptic_strength": _settings.get_haptic_strength(),
		"reduced_motion": _settings.is_reduced_motion_enabled(),
	}

func _restore_settings() -> void:
	if _settings_snapshot.is_empty():
		return
	_settings.set_camera_sensitivity(_settings_snapshot.get("camera_sensitivity", 1.0))
	_settings.set_haptics_enabled(_settings_snapshot.get("haptics_enabled", true))
	_settings.set_haptic_strength(_settings_snapshot.get("haptic_strength", 1.0))
	_settings.set_reduced_motion_enabled(_settings_snapshot.get("reduced_motion", false))

func _director_transition_to(scene_id: StringName) -> void:
	if _director == null:
		return
	if _director.is_transition_in_progress():
		await wait_frames(20)
	_director.transition_to(scene_id)
	await wait_frames(30)
