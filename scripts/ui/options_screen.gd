extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")
const Settings := preload("res://autoload/settings.gd")
const AccessibilityService := preload("res://autoload/accessibility_service.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")

const PALETTES: Array[StringName] = [
	StringName("default"),
	StringName("warm"),
	StringName("cool"),
	StringName("neon"),
]
const CAPTION_LABELS := {
	StringName("small"): "Small",
	StringName("medium"): "Medium",
	StringName("large"): "Large",
}

@onready var _close_button: Button = %CloseButton
@onready var _tabs: TabContainer = %Tabs

# Controls tab
@onready var _camera_slider: HSlider = %CameraSensitivitySlider
@onready var _invert_x_toggle: CheckBox = %InvertXToggle
@onready var _invert_y_toggle: CheckBox = %InvertYToggle
@onready var _tutorial_reset_button: Button = %TutorialResetButton

# Audio tab
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _haptic_strength_slider: HSlider = %HapticStrengthSlider

# Accessibility tab
@onready var _reduced_motion_toggle: CheckBox = %ReducedMotionToggle
@onready var _colorblind_option: OptionButton = %ColorblindOption
@onready var _subtitles_toggle: CheckBox = %SubtitlesToggle
@onready var _caption_size_option: OptionButton = %CaptionSizeOption

var _settings: Settings
var _accessibility: AccessibilityService
var _analytics: AnalyticsStub
var _metadata: Dictionary = {}
var _caption_sizes: Array[StringName] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_settings = Settings.get_instance()
	_accessibility = AccessibilityService.get_instance()
	_analytics = AnalyticsStub.get_instance()
	_close_button.pressed.connect(_on_close_pressed)
	_tabs.tab_changed.connect(_on_tab_changed)
	_camera_slider.value_changed.connect(_on_camera_slider_changed)
	_invert_x_toggle.toggled.connect(_on_invert_x_toggled)
	_invert_y_toggle.toggled.connect(_on_invert_y_toggled)
	_tutorial_reset_button.pressed.connect(_on_tutorial_reset_pressed)
	_master_slider.value_changed.connect(_on_master_volume_changed)
	_music_slider.value_changed.connect(_on_music_volume_changed)
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	_haptic_strength_slider.value_changed.connect(_on_haptic_strength_changed)
	_reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	_colorblind_option.item_selected.connect(_on_palette_selected)
	_subtitles_toggle.toggled.connect(_on_subtitles_toggled)
	_caption_size_option.item_selected.connect(_on_caption_size_selected)
	_populate_colorblind_items()
	_populate_caption_items()
	_sync_from_settings()

func apply_metadata(metadata: Dictionary) -> void:
	_metadata = metadata.duplicate(true)
	if _metadata.has("tab"):
		var tab_name := StringName(String(_metadata["tab"]))
		var tab_index := _find_tab_index(tab_name)
		if tab_index >= 0:
			_tabs.current_tab = tab_index

func _populate_colorblind_items() -> void:
	_colorblind_option.clear()
	for i in range(PALETTES.size()):
		var label := _palette_label(PALETTES[i])
		_colorblind_option.add_item(label, i)

func _populate_caption_items() -> void:
	_caption_size_option.clear()
	_caption_sizes.clear()
	var sizes: Array[StringName] = []
	if _settings:
		sizes = _settings.get_caption_size_options()
	if sizes.is_empty():
		sizes = [StringName("small"), StringName("medium"), StringName("large")]
	for i in range(sizes.size()):
		var size: StringName = sizes[i]
		_caption_sizes.append(size)
		var label: String = CAPTION_LABELS.get(size, String(size))
		_caption_size_option.add_item(label, i)
		_caption_size_option.set_item_metadata(i, size)

func _sync_from_settings() -> void:
	if _settings:
		_camera_slider.value = _settings.get_camera_sensitivity()
		_invert_x_toggle.button_pressed = _settings.is_invert_x_enabled()
		_invert_y_toggle.button_pressed = _settings.is_invert_y_enabled()
		_master_slider.value = _settings.get_master_volume()
		_music_slider.value = _settings.get_music_volume()
		_sfx_slider.value = _settings.get_sfx_volume()
		_haptic_strength_slider.value = _settings.get_haptic_strength()
		_reduced_motion_toggle.button_pressed = _settings.is_reduced_motion_enabled()
		_subtitles_toggle.button_pressed = _settings.are_subtitles_enabled()
		var caption_size := _settings.get_caption_size()
		var caption_index := _caption_sizes.find(caption_size)
		if caption_index >= 0:
			_caption_size_option.select(caption_index)
	if _accessibility:
		var palette := _accessibility.get_colorblind_palette()
		var palette_index := PALETTES.find(palette)
		_colorblind_option.select(max(palette_index, 0))

func _on_close_pressed() -> void:
	SceneDirector.get_instance().pop_overlay_by_id(StringName("options"))

func _on_tab_changed(_tab: int) -> void:
	# Placeholder for future analytics on tab switches.
	pass

func _on_camera_slider_changed(value: float) -> void:
	if _settings:
		_settings.set_camera_sensitivity(value)
	_log_option_change(StringName("camera_sensitivity"), value, StringName("controls"))

func _on_invert_x_toggled(pressed: bool) -> void:
	if _settings:
		_settings.set_invert_x_enabled(pressed)
	_log_option_change(StringName("invert_x"), pressed, StringName("controls"))

func _on_invert_y_toggled(pressed: bool) -> void:
	if _settings:
		_settings.set_invert_y_enabled(pressed)
	_log_option_change(StringName("invert_y"), pressed, StringName("controls"))

func _on_tutorial_reset_pressed() -> void:
	if _settings:
		_settings.reset_tutorial_completion("options_reset")
	_log_option_change(StringName("tutorial_reset"), StringName("triggered"), StringName("controls"))

func _on_master_volume_changed(value: float) -> void:
	if _settings:
		_settings.set_master_volume(value)
	_log_option_change(StringName("master_volume"), value, StringName("audio"))

func _on_music_volume_changed(value: float) -> void:
	if _settings:
		_settings.set_music_volume(value)
	_log_option_change(StringName("music_volume"), value, StringName("audio"))

func _on_sfx_volume_changed(value: float) -> void:
	if _settings:
		_settings.set_sfx_volume(value)
	_log_option_change(StringName("sfx_volume"), value, StringName("audio"))

func _on_haptic_strength_changed(value: float) -> void:
	if _settings:
		_settings.set_haptic_strength(value)
	_log_option_change(StringName("haptic_strength"), value, StringName("audio"))

func _on_reduced_motion_toggled(pressed: bool) -> void:
	if _settings:
		_settings.set_reduced_motion_enabled(pressed)
	_log_accessibility_toggle(StringName("reduced_motion"), pressed)

func _on_palette_selected(index: int) -> void:
	var palette := PALETTES[clampi(index, 0, PALETTES.size() - 1)]
	if _accessibility:
		_accessibility.set_colorblind_palette(palette)
	_log_accessibility_toggle(StringName("colorblind_palette"), String(palette))

func _on_subtitles_toggled(pressed: bool) -> void:
	if _settings:
		_settings.set_subtitles_enabled(pressed)
	_log_accessibility_toggle(StringName("subtitles"), pressed)

func _on_caption_size_selected(index: int) -> void:
	var metadata: Variant = _caption_size_option.get_item_metadata(index)
	if metadata is StringName:
		var caption_size: StringName = metadata
		if _settings:
			_settings.set_caption_size(caption_size)
		_log_accessibility_toggle(StringName("caption_size"), String(caption_size))

func _palette_label(palette: StringName) -> String:
	var map := {
		StringName("default"): "Default",
		StringName("warm"): "Warm",
		StringName("cool"): "Cool",
		StringName("neon"): "Neon",
	}
	return map.get(palette, String(palette))

func _find_tab_index(tab_name: StringName) -> int:
	for i in range(_tabs.get_tab_count()):
		if StringName(_tabs.get_tab_title(i).to_lower().replace(" ", "_")) == tab_name:
			return i
	return -1

func _log_option_change(setting: StringName, value: Variant, tab: StringName) -> void:
	if _analytics == null:
		return
	_analytics.log_event(StringName("options_adjusted"), {
		"setting": setting,
		"value": value,
		"tab": tab,
		"timestamp_ms": Time.get_ticks_msec(),
	})

func _log_accessibility_toggle(setting: StringName, value: Variant) -> void:
	if _analytics == null:
		return
	_analytics.log_event(StringName("toggle_accessibility"), {
		"setting": setting,
		"value": value,
		"context": StringName("options"),
		"timestamp_ms": Time.get_ticks_msec(),
	})
