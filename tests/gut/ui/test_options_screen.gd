extends "res://tests/gut/gut_stub.gd"

const OptionsScreen := preload("res://ui/screens/options_screen.tscn")
const Settings := preload("res://autoload/settings.gd")
const AccessibilityService := preload("res://autoload/accessibility_service.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")

var _settings: Settings
var _accessibility: AccessibilityService
var _analytics: AnalyticsStub
var _settings_snapshot: Dictionary = {}
var _palette_snapshot: StringName = StringName()

func before_each() -> void:
	_settings = Settings.get_instance()
	_accessibility = AccessibilityService.get_instance()
	_analytics = AnalyticsStub.get_instance()
	assert_true(_settings != null, "Settings singleton should be available")
	assert_true(_accessibility != null, "Accessibility service should be available")
	assert_true(_analytics != null, "Analytics stub should be available")
	_snapshot_settings()
	_palette_snapshot = _accessibility.get_colorblind_palette()
	_analytics.clear_events()

func after_each() -> void:
	_restore_settings()
	if _accessibility and _palette_snapshot != StringName():
		_accessibility.set_colorblind_palette(_palette_snapshot)
	if _analytics:
		_analytics.clear_events()

func test_sync_from_settings_populates_controls() -> void:
	_settings.set_camera_sensitivity(1.25)
	_settings.set_invert_x_enabled(true)
	_settings.set_invert_y_enabled(true)
	_settings.set_master_volume(0.7)
	_settings.set_music_volume(0.55)
	_settings.set_sfx_volume(0.45)
	_settings.set_haptics_enabled(false)
	_settings.set_haptic_strength(0.4)
	_settings.set_reduced_motion_enabled(true)
	_settings.set_subtitles_enabled(true)
	_settings.set_caption_size(StringName("large"))
	_accessibility.set_colorblind_palette(StringName("cool"))

	var options := _instantiate_options()
	var camera_slider: HSlider = options.get_node_or_null("%CameraSensitivitySlider")
	var invert_x: CheckBox = options.get_node_or_null("%InvertXToggle")
	var invert_y: CheckBox = options.get_node_or_null("%InvertYToggle")
	var master_slider: HSlider = options.get_node_or_null("%MasterSlider")
	var music_slider: HSlider = options.get_node_or_null("%MusicSlider")
	var sfx_slider: HSlider = options.get_node_or_null("%SfxSlider")
	var haptics_toggle: CheckBox = options.get_node_or_null("%HapticsToggle")
	var haptic_strength: HSlider = options.get_node_or_null("%HapticStrengthSlider")
	var reduced_toggle: CheckBox = options.get_node_or_null("%ReducedMotionToggle")
	var subtitles_toggle: CheckBox = options.get_node_or_null("%SubtitlesToggle")
	var caption_option: OptionButton = options.get_node_or_null("%CaptionSizeOption")
	var palette_option: OptionButton = options.get_node_or_null("%ColorblindOption")
	assert_true(camera_slider != null, "Options screen should expose camera slider")
	assert_true(invert_x != null and invert_y != null, "Options screen should expose invert toggles")
	assert_true(master_slider != null and music_slider != null and sfx_slider != null, "Options screen should expose volume sliders")
	assert_true(haptics_toggle != null and haptic_strength != null, "Options screen should expose haptics controls")
	assert_true(reduced_toggle != null and subtitles_toggle != null, "Options screen should expose accessibility toggles")
	assert_true(caption_option != null and palette_option != null, "Options screen should expose selection controls")
	if camera_slider == null or invert_x == null or invert_y == null or master_slider == null or music_slider == null or sfx_slider == null or haptics_toggle == null or haptic_strength == null or reduced_toggle == null or subtitles_toggle == null or caption_option == null or palette_option == null:
		return
	assert_eq(camera_slider.value, 1.25, "Camera slider should reflect stored sensitivity")
	assert_true(invert_x.button_pressed, "Invert X toggle should be on")
	assert_true(invert_y.button_pressed, "Invert Y toggle should be on")
	assert_eq(master_slider.value, 0.7, "Master volume slider should reflect settings")
	assert_eq(music_slider.value, 0.55, "Music slider should reflect settings")
	assert_eq(sfx_slider.value, 0.45, "SFX slider should reflect settings")
	assert_false(haptics_toggle.button_pressed, "Haptics toggle should be off")
	assert_eq(haptic_strength.value, 0.4, "Haptic strength slider should match settings")
	assert_true(reduced_toggle.button_pressed, "Reduced motion toggle should reflect settings")
	assert_true(subtitles_toggle.button_pressed, "Subtitles toggle should reflect settings")
	assert_eq(caption_option.get_item_metadata(caption_option.get_selected_id()), StringName("large"), "Caption size option should select stored value")
	assert_eq(palette_option.get_item_text(palette_option.selected), "Cool", "Palette selector should choose current palette")

func test_camera_slider_updates_settings_and_logs_event() -> void:
	_settings.set_camera_sensitivity(1.0)
	var options := _instantiate_options()
	var slider: HSlider = options.get_node_or_null("%CameraSensitivitySlider")
	assert_true(slider != null, "Camera slider should be available for interaction")
	if slider == null:
		return
	slider.value = 1.6
	slider.emit_signal("value_changed", slider.value)
	await wait_frames(1)
	assert_true(is_equal_approx(_settings.get_camera_sensitivity(), 1.6), "Camera slider should update settings value")
	var event: Variant = _find_last_event(StringName("options_adjusted"))
	assert_true(event != null, "Camera slider update should log analytics event")
	if event:
		var payload: Dictionary = event.get("payload", {})
		assert_eq(payload.get("setting"), StringName("camera_sensitivity"), "Analytics payload should reference camera sensitivity setting")
		assert_eq(float(payload.get("value", 0.0)), 1.6, "Analytics payload should include updated slider value")
		assert_eq(payload.get("tab"), StringName("controls"), "Camera slider analytics event should tag controls tab")

func test_reduced_motion_toggle_updates_settings_and_logs() -> void:
	_settings.set_reduced_motion_enabled(false)
	var options := _instantiate_options()
	var toggle: CheckBox = options.get_node_or_null("%ReducedMotionToggle")
	assert_true(toggle != null, "Reduced motion toggle should be available")
	if toggle == null:
		return
	toggle.button_pressed = true
	toggle.emit_signal("toggled", true)
	await wait_frames(1)
	assert_true(_settings.is_reduced_motion_enabled(), "Reduced motion toggle should persist setting")
	var event: Variant = _find_last_event(StringName("toggle_accessibility"))
	assert_true(event != null, "Reduced motion toggle should produce accessibility analytics event")
	if event:
		var payload: Dictionary = event.get("payload", {})
		assert_eq(payload.get("setting"), StringName("reduced_motion"), "Accessibility analytics should reference reduced motion setting")
		assert_true(payload.get("value"), "Accessibility analytics should record toggle value")
		assert_eq(payload.get("context"), StringName("options"), "Accessibility analytics context should be options overlay")

func test_apply_metadata_selects_requested_tab() -> void:
	var options := _instantiate_options()
	var tabs: TabContainer = options.get_node_or_null("%Tabs")
	assert_true(tabs != null, "Options screen should provide tab container")
	if tabs == null:
		return
	options.call("apply_metadata", {"tab": "audio"})
	await wait_frames(1)
	assert_eq(StringName(tabs.get_tab_title(tabs.current_tab).to_lower().replace(" ", "_")), StringName("audio"), "Metadata should switch to audio tab")

func test_tutorial_reset_button_resets_completion_flag() -> void:
	_settings.mark_tutorial_complete("unit_test_setup")
	var options := _instantiate_options()
	var reset_button: Button = options.get_node_or_null("%TutorialResetButton")
	assert_true(reset_button != null, "Options screen should provide tutorial reset button")
	if reset_button == null:
		return
	reset_button.emit_signal("pressed")
	await wait_frames(1)
	assert_false(_settings.tutorial_completed, "Reset button should clear tutorial completion flag")
	var event: Variant = _find_last_event(StringName("options_adjusted"))
	assert_true(event != null, "Tutorial reset should log analytics adjustment event")
	if event:
		var payload: Dictionary = event.get("payload", {})
		assert_eq(payload.get("setting"), StringName("tutorial_reset"), "Analytics payload should mark tutorial reset action")
		assert_eq(payload.get("value"), StringName("triggered"), "Analytics payload should record triggered value")
		assert_eq(payload.get("tab"), StringName("controls"), "Tutorial reset analytics should tag controls tab")

func _instantiate_options() -> Control:
	var packed := OptionsScreen.instantiate()
	add_child_autofree(packed)
	await wait_frames(4)
	return packed

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
		"invert_x": _settings.is_invert_x_enabled(),
		"invert_y": _settings.is_invert_y_enabled(),
		"master_volume": _settings.get_master_volume(),
		"music_volume": _settings.get_music_volume(),
		"sfx_volume": _settings.get_sfx_volume(),
		"haptics_enabled": _settings.is_haptics_enabled(),
		"haptic_strength": _settings.get_haptic_strength(),
		"reduced_motion": _settings.is_reduced_motion_enabled(),
		"subtitles": _settings.are_subtitles_enabled(),
		"caption_size": _settings.get_caption_size(),
		"tutorial_completed": _settings.tutorial_completed,
	}

func _restore_settings() -> void:
	if _settings_snapshot.is_empty():
		return
	_settings.set_camera_sensitivity(_settings_snapshot.get("camera_sensitivity", 1.0))
	_settings.set_invert_x_enabled(_settings_snapshot.get("invert_x", false))
	_settings.set_invert_y_enabled(_settings_snapshot.get("invert_y", false))
	_settings.set_master_volume(_settings_snapshot.get("master_volume", 1.0))
	_settings.set_music_volume(_settings_snapshot.get("music_volume", 1.0))
	_settings.set_sfx_volume(_settings_snapshot.get("sfx_volume", 1.0))
	_settings.set_haptics_enabled(_settings_snapshot.get("haptics_enabled", true))
	_settings.set_haptic_strength(_settings_snapshot.get("haptic_strength", 1.0))
	_settings.set_reduced_motion_enabled(_settings_snapshot.get("reduced_motion", false))
	_settings.set_subtitles_enabled(_settings_snapshot.get("subtitles", false))
	_settings.set_caption_size(_settings_snapshot.get("caption_size", StringName("medium")))
	if _settings_snapshot.get("tutorial_completed", false):
		_settings.mark_tutorial_complete("restore")
	else:
		_settings.reset_tutorial_completion("restore")
