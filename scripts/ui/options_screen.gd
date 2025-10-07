extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")
const Settings := preload("res://autoload/settings.gd")
const AccessibilityService := preload("res://autoload/accessibility_service.gd")

@onready var _close_button: Button = %CloseButton
@onready var _haptics_toggle: CheckBox = %HapticsToggle
@onready var _reduced_motion_toggle: CheckBox = %ReducedMotionToggle
@onready var _colorblind_option: OptionButton = %ColorblindOption
@onready var _sensitivity_slider: HSlider = %SensitivitySlider

var _metadata: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_close_button.pressed.connect(_on_close_pressed)
	_haptics_toggle.toggled.connect(_on_haptics_toggled)
	_reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	_colorblind_option.item_selected.connect(_on_palette_selected)
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_populate_colorblind_items()
	_sync_from_settings()

func apply_metadata(metadata: Dictionary) -> void:
	_metadata = metadata.duplicate(true)

func _populate_colorblind_items() -> void:
	_colorblind_option.clear()
	_colorblind_option.add_item("Default", 0)
	_colorblind_option.add_item("Warm", 1)
	_colorblind_option.add_item("Cool", 2)
	_colorblind_option.add_item("Neon", 3)

func _on_close_pressed() -> void:
	SceneDirector.get_instance().pop_overlay_by_id(StringName("options"))

func _on_haptics_toggled(pressed: bool) -> void:
	var settings := Settings.get_instance()
	if settings:
		settings.set_haptics_enabled(pressed)

func _on_reduced_motion_toggled(pressed: bool) -> void:
	var settings := Settings.get_instance()
	if settings:
		settings.set_reduced_motion_enabled(pressed)

func _on_palette_selected(index: int) -> void:
	var palette_map := {
		0: StringName("default"),
		1: StringName("warm"),
		2: StringName("cool"),
		3: StringName("neon"),
	}
	var selected := palette_map.get(index, StringName("default"))
	var service := AccessibilityService.get_instance()
	if service:
		service.set_colorblind_palette(selected)

func _on_sensitivity_changed(value: float) -> void:
	var settings := Settings.get_instance()
	if settings:
		settings.set_camera_sensitivity(value)

func _sync_from_settings() -> void:
	var settings := Settings.get_instance()
	if settings:
		if settings.has_method("is_haptics_enabled"):
			_haptics_toggle.button_pressed = settings.is_haptics_enabled()
		if settings.has_method("is_reduced_motion_enabled"):
			_reduced_motion_toggle.button_pressed = settings.is_reduced_motion_enabled()
		if settings.has_method("get_camera_sensitivity"):
			_sensitivity_slider.value = settings.get_camera_sensitivity()
