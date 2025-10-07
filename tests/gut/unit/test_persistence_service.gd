extends "res://tests/gut/gut_stub.gd"

const PersistenceService := preload("res://autoload/persistence_service.gd")

var _service: Node
var _test_path := "user://test_persistence_service.json"

func before_each() -> void:
	_service = PersistenceService.get_instance()
	assert_true(_service != null, "PersistenceService singleton should be available")
	if _service == null:
		return
	_service.set_override_save_path(_test_path)
	_service.replace_state({})
	_service.flush_now()
	_delete_test_file()

func after_each() -> void:
	if _service:
		_service.replace_state({})
		_service.flush_now()
		_service.set_override_save_path("")
	_delete_test_file()

func test_tutorial_completion_persists_to_disk() -> void:
	if _service == null:
		return
	_service.set_tutorial_completion(true, {
		"context": "unit_test",
		"completed_at_ms": 42
	})
	_service.flush_now()
	assert_true(_service.is_tutorial_completed(), "Tutorial flag should be marked complete")
	var tutorial_state: Dictionary = _service.get_tutorial_state()
	assert_true(tutorial_state.get("completed", false), "Tutorial state should indicate completion")
	assert_eq(tutorial_state.get("context"), "unit_test", "Context metadata should persist")
	assert_eq(int(tutorial_state.get("completed_at_ms", 0)), 42, "Completed timestamp should persist")
	var file: FileAccess = FileAccess.open(_test_path, FileAccess.READ)
	assert_true(file != null, "Save file should be created on disk")
	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		assert_true(parsed is Dictionary, "Save file should parse as dictionary")
		if parsed is Dictionary:
			var tutorial: Dictionary = parsed.get("tutorial", {})
			assert_true(tutorial.get("completed", false), "Save data should record completion flag")
			assert_eq(int(tutorial.get("completed_at_ms", 0)), 42, "Save data should record timestamp")
			assert_eq(tutorial.get("context"), "unit_test", "Save data should record context string")

func test_reduced_motion_flag_persists() -> void:
	if _service == null:
		return
	_service.set_reduced_motion_enabled(true)
	_service.flush_now()
	assert_true(_service.is_reduced_motion_enabled(), "Reduced motion flag should be enabled")
	var file: FileAccess = FileAccess.open(_test_path, FileAccess.READ)
	assert_true(file != null, "Save file should exist after reduced motion toggle")
	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		assert_true(parsed is Dictionary, "Save file should parse as dictionary")
		if parsed is Dictionary:
			var accessibility: Dictionary = parsed.get("accessibility", {})
			assert_true(accessibility.get("reduced_motion", false), "Accessibility state should record reduced motion flag")

func test_run_history_appends_and_caps() -> void:
	if _service == null:
		return
	for i in range(30):
		_service.append_run_record({
			"score": i,
			"wave": i % 6,
			"duration_sec": 5.0 + float(i),
			"failure_reason": "timeout",
			"timestamp_sec": 100 + i,
		})
	_service.flush_now()
	var runs := _service.get_run_records()
	assert_true(runs.size() <= 25, "Run history should cap at 25 entries")
	assert_eq(int(runs[0].get("score", -1)), 29, "Most recent run should be first in history")
	var summary := _service.get_records_summary()
	assert_eq(int(summary.get("high_score", -1)), 29, "High score should track maximum score")
	assert_eq(int(summary.get("best_wave", -1)), 5, "Best wave should track highest wave reached")
	var fastest := float(summary.get("fastest_duration_sec", 0.0))
	assert_true(fastest > 0.0, "Fastest duration should record minimum non-zero duration")
	assert_eq(int(summary.get("previous_score", -1)), 28, "Previous score should reflect the run before the latest")

func _delete_test_file() -> void:
	if not FileAccess.file_exists(_test_path):
		return
	var absolute := ProjectSettings.globalize_path(_test_path)
	var err := DirAccess.remove_absolute(absolute)
	if err != OK:
		push_warning("test_persistence_service: failed to delete temp file at %s (err=%d)" % [absolute, err])
