extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const LocalizationService := preload("res://autoload/localization_service.gd")

const TITLE_KEY := StringName("title_screen_title")
const SUBTITLE_KEY := StringName("title_screen_subtitle")
const START_KEY := StringName("title_screen_start")
const TOGGLE_KEY := StringName("title_screen_toggle_locale")

@onready var _title_label: Label = get_node_or_null("VBox/TitleLabel")
@onready var _subtitle_label: Label = get_node_or_null("VBox/Subtitle")
@onready var _start_button: Button = get_node_or_null("VBox/StartButton")
@onready var _locale_button: Button = get_node_or_null("VBox/LocaleButton")

var _localization: Node
var _title_fallback: String = ""
var _subtitle_fallback: String = ""
var _start_fallback: String = ""
var _toggle_fallback: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cache_fallback_text()
	_localization = LocalizationService.get_instance()
	if _localization:
		if _localization.has_signal("locale_changed"):
			_localization.locale_changed.connect(_on_locale_changed)
		_apply_localization()
	if _start_button:
		_start_button.pressed.connect(_on_start_pressed)
	if _locale_button:
		_locale_button.pressed.connect(_on_locale_pressed)
	if has_focus() == false and _start_button:
		_start_button.grab_focus()

func _cache_fallback_text() -> void:
	if _title_label:
		_title_fallback = _title_label.text
	if _subtitle_label:
		_subtitle_fallback = _subtitle_label.text
	if _start_button:
		_start_fallback = _start_button.text
	if _locale_button:
		_toggle_fallback = _locale_button.text

func _apply_localization() -> void:
	if _localization == null:
		return
	if _title_label:
		_title_label.text = _localize_text(TITLE_KEY, _title_fallback)
	if _subtitle_label:
		_subtitle_label.text = _localize_text(SUBTITLE_KEY, _subtitle_fallback)
	if _start_button:
		_start_button.text = _localize_text(START_KEY, _start_fallback)
	if _locale_button:
		var toggled_text := _localize_text(TOGGLE_KEY, _toggle_fallback)
		_locale_button.text = toggled_text

func _localize_text(key: StringName, fallback: String) -> String:
	if _localization and _localization.has_method("get_text"):
		return _localization.get_text(key)
	return fallback

func _on_locale_changed(_locale: StringName) -> void:
	_apply_localization()

func _on_start_pressed() -> void:
	SceneDirector.get_instance().transition_to(StringName("main_menu"), {"entry": "title_button"})

func _on_locale_pressed() -> void:
	if _localization and _localization.has_method("toggle_locale"):
		_localization.toggle_locale()
	var hub := SignalHub.get_instance()
	if hub:
		hub.broadcast_navigation(StringName("locale_toggle"), {"source": "title"})
