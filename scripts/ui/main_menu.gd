extends Control

const SceneDirector := preload("res://autoload/scene_director.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const LocalizationService := preload("res://autoload/localization_service.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")

const HEADER_KEY := StringName("main_menu_header")
const TILE_KEYS := {
	StringName("start"): StringName("main_menu_start"),
	StringName("tutorial"): StringName("main_menu_tutorial"),
	StringName("practice"): StringName("main_menu_practice"),
	StringName("options"): StringName("main_menu_options"),
	StringName("records"): StringName("main_menu_records"),
	StringName("quit"): StringName("main_menu_quit"),
}

@onready var _header_label: Label = %Header
@onready var _start_tile: Button = %StartTile
@onready var _tutorial_tile: Button = %TutorialTile
@onready var _practice_tile: Button = %PracticeTile
@onready var _options_tile: Button = %OptionsTile
@onready var _records_tile: Button = %RecordsTile
@onready var _quit_tile: Button = %QuitTile

var _localization: Node
var _analytics: AnalyticsStub
var _fallback_text: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cache_fallback_text()
	_localization = LocalizationService.get_instance()
	if _localization and _localization.has_signal("locale_changed"):
		_localization.locale_changed.connect(_on_locale_changed)
	_apply_localization()
	_analytics = AnalyticsStub.get_instance()
	_start_tile.pressed.connect(_on_start_pressed)
	_tutorial_tile.pressed.connect(_on_tutorial_pressed)
	_practice_tile.pressed.connect(_on_practice_pressed)
	_options_tile.pressed.connect(_on_options_pressed)
	_records_tile.pressed.connect(_on_records_pressed)
	_quit_tile.pressed.connect(_on_quit_pressed)
	_start_tile.grab_focus()

func apply_metadata(metadata: Dictionary) -> void:
	if metadata.has("entry"):
		var hub := SignalHub.get_instance()
		if hub:
			hub.broadcast_navigation(StringName("main_menu"), metadata)

func _cache_fallback_text() -> void:
	if _header_label:
		_fallback_text[StringName("header")] = _header_label.text
	_fallback_text[StringName("start")] = _start_tile.text
	_fallback_text[StringName("tutorial")] = _tutorial_tile.text
	_fallback_text[StringName("practice")] = _practice_tile.text
	_fallback_text[StringName("options")] = _options_tile.text
	_fallback_text[StringName("records")] = _records_tile.text
	_fallback_text[StringName("quit")] = _quit_tile.text

func _apply_localization() -> void:
	if _localization == null:
		return
	if _header_label:
		_header_label.text = _get_text(HEADER_KEY, _fallback_text.get(StringName("header"), _header_label.text))
	_start_tile.text = _get_text(TILE_KEYS[StringName("start")], _fallback_text[StringName("start")])
	_tutorial_tile.text = _get_text(TILE_KEYS[StringName("tutorial")], _fallback_text[StringName("tutorial")])
	_practice_tile.text = _get_text(TILE_KEYS[StringName("practice")], _fallback_text[StringName("practice")])
	_options_tile.text = _get_text(TILE_KEYS[StringName("options")], _fallback_text[StringName("options")])
	_records_tile.text = _get_text(TILE_KEYS[StringName("records")], _fallback_text[StringName("records")])
	_quit_tile.text = _get_text(TILE_KEYS[StringName("quit")], _fallback_text[StringName("quit")])

func _get_text(key: StringName, fallback: String) -> String:
	if _localization and _localization.has_method("get_text"):
		return _localization.get_text(key)
	return fallback

func _on_locale_changed(_locale: StringName) -> void:
	_apply_localization()

func _on_start_pressed() -> void:
	_log_menu_nav(StringName("start"))
	SceneDirector.get_instance().transition_to(StringName("session"), {"entry": "score_run"})

func _on_tutorial_pressed() -> void:
	_log_menu_nav(StringName("tutorial"))
	SceneDirector.get_instance().transition_to(StringName("tutorial"), {"entry": "tutorial"})

func _on_practice_pressed() -> void:
	_log_menu_nav(StringName("practice"))
	SceneDirector.get_instance().transition_to(StringName("practice"), {"entry": "practice"})

func _on_options_pressed() -> void:
	_log_menu_nav(StringName("options"))
	SceneDirector.get_instance().push_overlay(StringName("options"), {"context": "main_menu"})

func _on_records_pressed() -> void:
	_log_menu_nav(StringName("records"))
	SceneDirector.get_instance().transition_to(StringName("records"), {"entry": "records"})

func _on_quit_pressed() -> void:
	_log_menu_nav(StringName("quit"))
	get_tree().quit()

func _log_menu_nav(action: StringName) -> void:
	if _analytics:
		_analytics.log_event(StringName("menu_nav"), {
			"source": StringName("main_menu"),
			"action": action,
			"timestamp_ms": Time.get_ticks_msec(),
		})
