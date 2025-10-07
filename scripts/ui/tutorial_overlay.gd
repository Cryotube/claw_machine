extends Control
class_name TutorialOverlay

const LocalizationService := preload("res://autoload/localization_service.gd")

signal dismissed

@export var auto_hide_seconds: float = 0.0
@export var default_text_key: StringName = StringName("tutorial_overlay_default_callouts")
@export var title_key: StringName = StringName("tutorial_overlay_title")
@export var cta_text_key: StringName = StringName("tutorial_overlay_cta")

@onready var _title_label: Label = %Title
@onready var _callouts: RichTextLabel = %Callouts
@onready var _cta_button: Button = %ContinueButton
@onready var _timer: Timer = $AutoHideTimer

var _localization: Node
var _default_title_fallback: String = ""
var _default_text_fallback: String = ""
var _default_cta_fallback: String = ""
var _active_text_key: StringName = StringName()
var _active_fallback: String = ""

func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cache_fallbacks()
	_localization = LocalizationService.get_instance()
	if _localization and _localization.has_signal("locale_changed"):
		_localization.locale_changed.connect(_on_locale_changed)
	_apply_localized_title()
	_apply_localized_cta()
	_reset_default_callouts()
	if _cta_button:
		_cta_button.pressed.connect(_on_continue_pressed)
	if _timer:
		_timer.timeout.connect(_on_timer_timeout)

func show_overlay(instructions: String = "", text_key: StringName = StringName()) -> void:
	if text_key != StringName():
		_active_text_key = text_key
		_active_fallback = instructions
	elif instructions.is_empty():
		_active_text_key = default_text_key
		_active_fallback = _default_text_fallback
	else:
		_active_text_key = StringName()
		_active_fallback = instructions
	_apply_localized_callouts()
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	if auto_hide_seconds > 0.0 and _timer:
		_timer.start(auto_hide_seconds)

func dismiss_overlay() -> void:
	if not visible:
		return
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _timer and _timer.is_stopped() == false:
		_timer.stop()
	dismissed.emit()

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		dismiss_overlay()
	elif event is InputEventKey and event.is_pressed():
		dismiss_overlay()

func _on_continue_pressed() -> void:
	dismiss_overlay()

func _on_timer_timeout() -> void:
	dismiss_overlay()

func _on_locale_changed(_locale: StringName) -> void:
	_apply_localized_title()
	_apply_localized_cta()
	_apply_localized_callouts()

func _cache_fallbacks() -> void:
	if _title_label:
		_default_title_fallback = _title_label.text
	if _callouts:
		_default_text_fallback = _callouts.text
	if _cta_button:
		_default_cta_fallback = _cta_button.text

func _reset_default_callouts() -> void:
	_active_text_key = default_text_key
	_active_fallback = _default_text_fallback
	_apply_localized_callouts()

func _apply_localized_title() -> void:
	if _title_label == null:
		return
	var resolved := _resolve_text(title_key, _default_title_fallback)
	_title_label.text = resolved

func _apply_localized_cta() -> void:
	if _cta_button == null:
		return
	var resolved := _resolve_text(cta_text_key, _default_cta_fallback)
	_cta_button.text = resolved

func _apply_localized_callouts() -> void:
	if _callouts == null:
		return
	var fallback := _active_fallback
	if fallback.is_empty():
		fallback = _default_text_fallback
	var resolved := _resolve_text(_active_text_key, fallback)
	_callouts.text = resolved

func _resolve_text(key: StringName, fallback: String) -> String:
	if _localization == null:
		_localization = LocalizationService.get_instance()
	if key != StringName() and _localization and _localization.has_method("get_text"):
		return _localization.get_text(key)
	return fallback
