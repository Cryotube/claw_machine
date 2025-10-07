extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const LocalizationService := preload("res://autoload/localization_service.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")

const TITLE_KEY := StringName("title_screen_title")
const SUBTITLE_KEY := StringName("title_screen_subtitle")
const START_KEY := StringName("title_screen_start")
const TOGGLE_KEY := StringName("title_screen_toggle_locale")

@onready var _title_label: Label = get_node_or_null("SafeArea/LayoutRoot/TitleLabel")
@onready var _subtitle_label: Label = get_node_or_null("SafeArea/LayoutRoot/Subtitle")
@onready var _primary_tile: Button = get_node_or_null("%PrimaryTile")
@onready var _tutorial_tile: Button = get_node_or_null("%TutorialTile")
@onready var _practice_tile: Button = get_node_or_null("%PracticeTile")
@onready var _options_tile: Button = get_node_or_null("%OptionsTile")
@onready var _records_tile: Button = get_node_or_null("%RecordsTile")
@onready var _locale_button: Button = get_node_or_null("%LocaleButton")

var _localization: Node
var _title_fallback: String = ""
var _subtitle_fallback: String = ""
var _primary_fallback: String = ""
var _tutorial_fallback: String = ""
var _practice_fallback: String = ""
var _options_fallback: String = ""
var _records_fallback: String = ""
var _toggle_fallback: String = ""
var _analytics: AnalyticsStub

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cache_fallback_text()
	_localization = LocalizationService.get_instance()
	if _localization:
		if _localization.has_signal("locale_changed"):
			_localization.locale_changed.connect(_on_locale_changed)
		_apply_localization()
	_analytics = AnalyticsStub.get_instance()
	if _primary_tile:
		_primary_tile.pressed.connect(_on_start_pressed)
	if _tutorial_tile:
		_tutorial_tile.pressed.connect(_on_tutorial_pressed)
	if _practice_tile:
		_practice_tile.pressed.connect(_on_practice_pressed)
	if _options_tile:
		_options_tile.pressed.connect(_on_options_pressed)
	if _records_tile:
		_records_tile.pressed.connect(_on_records_pressed)
	if _locale_button:
		_locale_button.pressed.connect(_on_locale_pressed)
	if has_focus() == false and _primary_tile:
		_primary_tile.grab_focus()

func _cache_fallback_text() -> void:
	if _title_label:
		_title_fallback = _title_label.text
	if _subtitle_label:
		_subtitle_fallback = _subtitle_label.text
	if _primary_tile:
		_primary_fallback = _primary_tile.text
	if _tutorial_tile:
		_tutorial_fallback = _tutorial_tile.text
	if _practice_tile:
		_practice_fallback = _practice_tile.text
	if _options_tile:
		_options_fallback = _options_tile.text
	if _records_tile:
		_records_fallback = _records_tile.text
	if _locale_button:
		_toggle_fallback = _locale_button.text

func _apply_localization() -> void:
	if _localization == null:
		return
	if _title_label:
		_title_label.text = _localize_text(TITLE_KEY, _title_fallback)
	if _subtitle_label:
		_subtitle_label.text = _localize_text(SUBTITLE_KEY, _subtitle_fallback)
	if _primary_tile:
		_primary_tile.text = _localize_text(START_KEY, _primary_fallback)
	if _tutorial_tile:
		_tutorial_tile.text = _localize_text(StringName("title_screen_tutorial"), _tutorial_fallback)
	if _practice_tile:
		_practice_tile.text = _localize_text(StringName("title_screen_practice"), _practice_fallback)
	if _options_tile:
		_options_tile.text = _localize_text(StringName("title_screen_options"), _options_fallback)
	if _records_tile:
		_records_tile.text = _localize_text(StringName("title_screen_records"), _records_fallback)
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
	_log_menu_nav(StringName("title_start_run"))
	SceneDirector.get_instance().transition_to(StringName("session"), {"entry": "title_start"})

func _on_tutorial_pressed() -> void:
	_log_menu_nav(StringName("title_tutorial"))
	SceneDirector.get_instance().transition_to(StringName("tutorial"), {"entry": "title_tutorial"})

func _on_practice_pressed() -> void:
	_log_menu_nav(StringName("title_practice"))
	SceneDirector.get_instance().transition_to(StringName("practice"), {"entry": "title_practice"})

func _on_options_pressed() -> void:
	_log_menu_nav(StringName("title_options"))
	SceneDirector.get_instance().push_overlay(StringName("options"), {"context": "title"})

func _on_records_pressed() -> void:
	_log_menu_nav(StringName("title_records"))
	SceneDirector.get_instance().transition_to(StringName("records"), {"entry": "title_records"})

func _on_locale_pressed() -> void:
	if _localization and _localization.has_method("toggle_locale"):
		_localization.toggle_locale()
	var hub := SignalHub.get_instance()
	if hub:
		hub.broadcast_navigation(StringName("locale_toggle"), {"source": "title"})

func _log_menu_nav(action: StringName) -> void:
	if _analytics:
		_analytics.log_event(StringName("menu_nav"), {
			"source": StringName("title"),
			"action": action,
			"timestamp_ms": Time.get_ticks_msec(),
		})
