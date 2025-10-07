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
const SENSITIVITY_PRESETS: Array[float] = [0.75, 1.0, 1.25]

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _haptics_toggle: CheckBox = %HapticsToggle
@onready var _palette_button: Button = %PaletteButton
@onready var _sensitivity_button: Button = %SensitivityButton

var _settings: Settings
var _accessibility: AccessibilityService
var _analytics: AnalyticsStub
var _palette_index: int = 0
var _sensitivity_index: int = 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_settings = Settings.get_instance()
	_accessibility = AccessibilityService.get_instance()
	_analytics = AnalyticsStub.get_instance()
	SceneDirector.get_instance().lock_input(true)
	_resume_button.pressed.connect(_on_resume)
	_restart_button.pressed.connect(_on_restart)
	_options_button.pressed.connect(_on_options)
	_quit_button.pressed.connect(_on_quit)
	_haptics_toggle.toggled.connect(_on_haptics_toggled)
	_palette_button.pressed.connect(_on_palette_pressed)
	_sensitivity_button.pressed.connect(_on_sensitivity_pressed)
	_resume_button.grab_focus()
	_sync_from_settings()

func _exit_tree() -> void:
	SceneDirector.get_instance().lock_input(false)

func apply_metadata(metadata: Dictionary) -> void:
	if metadata.has("resume_focus"):
		var button_name := String(metadata["resume_focus"])
		var node := get_node_or_null(button_name)
		if node and node is Control:
			(node as Control).grab_focus()

func _sync_from_settings() -> void:
	if _settings:
		if _settings.has_method("is_haptics_enabled"):
			_haptics_toggle.button_pressed = _settings.is_haptics_enabled()
		if _settings.has_method("get_camera_sensitivity"):
			var sensitivity := _settings.get_camera_sensitivity()
			_sensitivity_index = _nearest_sensitivity_index(sensitivity)
			_update_sensitivity_button()
	if _accessibility:
		var palette := _accessibility.get_colorblind_palette()
		_palette_index = PALETTES.find(palette)
		if _palette_index == -1:
			_palette_index = 0
	_update_palette_button()

func _on_resume() -> void:
	SceneDirector.get_instance().lock_input(false)
	SceneDirector.get_instance().pop_overlay()

func _on_restart() -> void:
	var director := SceneDirector.get_instance()
	SceneDirector.get_instance().lock_input(false)
	director.pop_overlay()
	director.transition_to(StringName("session"), {"entry": "restart"})

func _on_options() -> void:
	SceneDirector.get_instance().push_overlay(StringName("options"), {"context": "pause"})

func _on_quit() -> void:
	var director := SceneDirector.get_instance()
	SceneDirector.get_instance().lock_input(false)
	director.pop_overlay()
	director.transition_to(StringName("main_menu"), {"entry": "pause_quit"})

func _on_haptics_toggled(pressed: bool) -> void:
	if _settings:
		_settings.set_haptics_enabled(pressed)
	_log_toggle(StringName("haptics"), pressed)

func _on_palette_pressed() -> void:
	_palette_index = (_palette_index + 1) % PALETTES.size()
	var palette := PALETTES[_palette_index]
	if _accessibility:
		_accessibility.set_colorblind_palette(palette)
	_update_palette_button()
	_log_toggle(StringName("colorblind_palette"), String(palette))

func _on_sensitivity_pressed() -> void:
	_sensitivity_index = (_sensitivity_index + 1) % SENSITIVITY_PRESETS.size()
	var value := SENSITIVITY_PRESETS[_sensitivity_index]
	if _settings:
		_settings.set_camera_sensitivity(value)
	_update_sensitivity_button()
	_log_toggle(StringName("camera_sensitivity_preset"), value)

func _update_palette_button() -> void:
	var palette := PALETTES[_palette_index]
	var label := "Palette: %s" % [_palette_label(palette)]
	_palette_button.text = label

func _update_sensitivity_button() -> void:
	var value := SENSITIVITY_PRESETS[_sensitivity_index]
	_sensitivity_button.text = "Sensitivity: %.2f×" % value

func _nearest_sensitivity_index(current: float) -> int:
	var closest_index := 0
	var best_delta := INF
	for i in range(SENSITIVITY_PRESETS.size()):
		var delta := abs(SENSITIVITY_PRESETS[i] - current)
		if delta < best_delta:
			best_delta = delta
			closest_index = i
	return closest_index

func _log_toggle(setting: StringName, value: Variant) -> void:
	if _analytics == null:
		return
	_analytics.log_event(StringName("toggle_accessibility"), {
		"setting": setting,
		"value": value,
		"context": StringName("pause"),
		"timestamp_ms": Time.get_ticks_msec(),
	})

func _palette_label(palette: StringName) -> String:
	var map := {
		StringName("default"): "Default",
		StringName("warm"): "Warm",
		StringName("cool"): "Cool",
		StringName("neon"): "Neon",
	}
	return map.get(palette, String(palette))
