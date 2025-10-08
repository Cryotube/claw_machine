extends "res://tests/gut/gut_stub.gd"

const RecordsScreen := preload("res://ui/screens/records_screen.tscn")
const SceneDirector := preload("res://autoload/scene_director.gd")
const PersistenceService := preload("res://autoload/persistence_service.gd")

var _director: Node
var _persistence: PersistenceService
var _persistence_snapshot: Dictionary = {}
var _temp_save_path := "user://test_records_screen.json"

func before_each() -> void:
	_director = SceneDirector.get_instance()
	_persistence = PersistenceService.get_instance()
	assert_true(_director != null, "SceneDirector singleton should be present")
	assert_true(_persistence != null, "Persistence service singleton should be present")
	_persistence_snapshot = _persistence.get_save_state()
	_persistence.set_override_save_path(_temp_save_path)
	await _director_transition_to(StringName("records"))

func after_each() -> void:
	if _persistence:
		_persistence.replace_state(_persistence_snapshot.duplicate(true))
		_persistence.flush_now()
		_persistence.set_override_save_path("")
	_delete_temp_file()
	await _director_transition_to(StringName("title"))

func test_records_screen_renders_summary_from_persistence() -> void:
	var state := {
		"summary": {
			"high_score": 420,
			"best_wave": 7,
			"previous_score": 310,
			"last_run": {"score": 360, "wave": 6, "failure_reason": "timeout"},
			"fastest_duration_sec": 42.5,
		},
		"runs": [
			{"timestamp_sec": 1700000000, "score": 360, "wave": 6, "failure_reason": "timeout", "duration_sec": 48.2},
			{"timestamp_sec": 1699999900, "score": 310, "wave": 5, "failure_reason": "drop", "duration_sec": 55.0},
		],
	}
	_persistence.replace_state(state)
	var records := await _instantiate_records_screen()
	var summary_label: Label = records.get_node_or_null("%SummaryLabel")
	var history_container: VBoxContainer = records.get_node_or_null("%HistoryContainer")
	assert_true(summary_label != null and history_container != null, "Records screen should expose summary and history elements")
	if summary_label == null or history_container == null:
		return
	var summary_text := summary_label.text
	assert_true(summary_text.find("High Score: 420") != -1, "Summary should include high score value")
	assert_true(summary_text.find("Best Wave: 7") != -1, "Summary should include best wave value")
	assert_true(summary_text.find("Last Run: 360") != -1, "Summary should include last run score")
	assert_eq(history_container.get_child_count(), 2, "History container should render one label per run")
	var first_entry := history_container.get_child(0) as Label
	assert_true(first_entry != null, "History entries should be labels")
	if first_entry:
		assert_true(first_entry.text.find("Score 360") != -1, "First history entry should reflect most recent run")

func test_records_screen_shows_empty_state_when_no_runs() -> void:
	_persistence.replace_state({"runs": [], "summary": {}})
	var records := await _instantiate_records_screen()
	var history_container: VBoxContainer = records.get_node_or_null("%HistoryContainer")
	assert_true(history_container != null, "Records screen should expose history container")
	if history_container == null:
		return
	assert_eq(history_container.get_child_count(), 1, "Empty state should render a placeholder label")
	var placeholder := history_container.get_child(0) as Label
	assert_true(placeholder != null, "Placeholder should be a label node")
	if placeholder:
		assert_true(placeholder.text.find("Play your first run") != -1, "Placeholder label should encourage first run")

func test_back_button_transitions_to_main_menu() -> void:
	_persistence.replace_state({})
	var records := await _instantiate_records_screen()
	var back_button: Button = records.get_node_or_null("%BackButton")
	assert_true(back_button != null, "Records screen should expose back button")
	if back_button == null:
		return
	var transition_event: Dictionary = {}
	_director.scene_transitioned.connect(func(scene_id, metadata):
		transition_event = {"id": scene_id, "metadata": metadata.duplicate(true)}
	, CONNECT_ONE_SHOT)
	back_button.emit_signal("pressed")
	await wait_frames(40)
	assert_eq(transition_event.get("id"), StringName("main_menu"), "Back button should return to main menu")
	var metadata: Dictionary = transition_event.get("metadata", {})
	assert_eq(metadata.get("entry"), StringName("records_back"), "Back navigation should include records_back metadata")

func test_apply_metadata_overrides_summary_text() -> void:
	_persistence.replace_state({})
	var records := await _instantiate_records_screen()
	var summary_label: Label = records.get_node_or_null("%SummaryLabel")
	assert_true(summary_label != null, "Records screen should expose summary label")
	if summary_label == null:
		return
	records.call("apply_metadata", {"summary_text": "Custom Summary"})
	await wait_frames(1)
	assert_eq(summary_label.text, "Custom Summary", "apply_metadata should override summary text when provided")

func _instantiate_records_screen() -> Control:
	var node := RecordsScreen.instantiate()
	add_child_autofree(node)
	await wait_frames(4)
	return node

func _delete_temp_file() -> void:
	if not FileAccess.file_exists(_temp_save_path):
		return
	var absolute := ProjectSettings.globalize_path(_temp_save_path)
	var err := DirAccess.remove_absolute(absolute)
	if err != OK:
		push_warning("test_records_screen: failed to delete temp save file %s (err=%d)" % [absolute, err])

func _director_transition_to(scene_id: StringName) -> void:
	if _director == null:
		return
	if _director.is_transition_in_progress():
		await wait_frames(20)
	_director.transition_to(scene_id)
	await wait_frames(30)
