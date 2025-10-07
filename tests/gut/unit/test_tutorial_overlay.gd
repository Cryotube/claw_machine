extends "res://tests/gut/gut_stub.gd"

const TutorialOverlayScene := preload("res://ui/components/TutorialOverlay.tscn")
const TutorialOverlay := preload("res://scripts/ui/tutorial_overlay.gd")
const LocalizationService := preload("res://autoload/localization_service.gd")

var _overlay: TutorialOverlay
var _localization
var _original_locale: StringName = StringName("en")

func before_each() -> void:
	_localization = LocalizationService.get_instance()
	if _localization:
		_original_locale = _localization.get_locale()
	_overlay = TutorialOverlayScene.instantiate()
	add_child_autofree(_overlay)
	await wait_frames(1)

func after_each() -> void:
	if _localization and _localization.has_method("set_locale"):
		_localization.set_locale(_original_locale)
	await wait_frames(1)

func test_overlay_updates_with_locale_change() -> void:
	if _overlay == null:
		assert_true(false, "TutorialOverlay did not instantiate")
		return
	var callouts := _overlay.get_node("Panel/VBox/Callouts") as RichTextLabel
	assert_true(callouts != null, "Callouts label should exist on overlay")
	if callouts == null:
		return
	await wait_frames(1)
	var english_text := callouts.text
	var expected_english := english_text
	if _localization:
		expected_english = _localization.get_text(StringName("tutorial_overlay_default_callouts"), StringName("en"))
		localization_set_locale(StringName("ja"))
	await wait_frames(2)
	var japanese_text := callouts.text
	var expected_japanese := japanese_text
	if _localization:
		expected_japanese = _localization.get_text(StringName("tutorial_overlay_default_callouts"), StringName("ja"))
	assert_eq(japanese_text, expected_japanese, "Callouts text should match localized Japanese copy")
	if _localization:
		localization_set_locale(StringName("en"))
	await wait_frames(2)
	assert_eq(callouts.text, expected_english, "Callouts text should revert to English copy")

func localization_set_locale(locale: StringName) -> void:
	if _localization == null:
		return
	if _localization.has_method("set_locale"):
		_localization.set_locale(locale)
