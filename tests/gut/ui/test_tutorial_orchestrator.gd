extends "res://tests/gut/gut_stub.gd"

const TutorialScene := preload("res://scenes/tutorial/TutorialPlayground.tscn")
const SceneDirector := preload("res://autoload/scene_director.gd")
const Settings := preload("res://autoload/settings.gd")
const OrderService := preload("res://autoload/order_service.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")

var _playground: Node

func before_each() -> void:
	var settings := Settings.get_instance()
	if settings:
		settings.tutorial_completed = false
	var analytics := AnalyticsStub.get_instance()
	if analytics:
		analytics.clear_events()
	_playground = TutorialScene.instantiate()
	add_child_autofree(_playground)
	await wait_frames(10)

func after_each() -> void:
	var director := SceneDirector.get_instance()
	if director:
		director.transition_to(StringName("title"))
	await wait_frames(10)

func test_tutorial_steps_progress_and_complete() -> void:
	var director := SceneDirector.get_instance()
	if director == null:
		return
	var overlay := _playground.get_node("SessionRoot/UI/TutorialOverlay") as TutorialOverlay
	var orchestrator := _playground.get_node("TutorialOrchestrator") as TutorialOrchestrator
	var claw_input := _playground.get_node("SessionRoot/ClawInputController") as ClawInputController

	overlay.dismiss_overlay()
	await wait_frames(5)
	claw_input.emit_signal("movement_input", Vector2(1, 0))
	await wait_frames(8)
	overlay.dismiss_overlay()

	claw_input.emit_signal("extend_pressed")
	await wait_frames(8)
	overlay.dismiss_overlay()

	claw_input.emit_signal("extend_released")
	await wait_frames(8)
	overlay.dismiss_overlay()

	claw_input.emit_signal("retract_pressed")
	await wait_frames(8)
	overlay.dismiss_overlay()

	await wait_frames(5)
	var order_id: StringName = orchestrator.get("_active_order_id")
	OrderService.get_instance().emit_signal("order_resolved_success", order_id, {})
	await wait_frames(8)
	overlay.dismiss_overlay()

	await wait_frames(20)
	assert_true(Settings.get_instance().tutorial_completed, "Tutorial completion flag should be set")
	var analytics := AnalyticsStub.get_instance()
	if analytics:
		var events: Array[Dictionary] = analytics.debug_get_events()
		var step_events: Array[Dictionary] = []
		for event_entry in events:
			if event_entry.get("event", StringName()) == StringName("tutorial_step_completed"):
				step_events.append(event_entry.get("payload", {}))
		assert_eq(step_events.size(), 6, "Tutorial should log analytics events for all steps")
		var expected_steps := ["intro", "aim", "lower", "grip", "drop", "serve"]
		for i in range(expected_steps.size()):
			var payload := step_events[i]
			assert_eq(payload.get("step_id"), expected_steps[i], "Step analytics step_id should match expected order")
			assert_true(payload.has("duration"), "Step analytics payload should include duration")
			assert_true(float(payload.get("duration", -1.0)) >= 0.0, "Step analytics duration should be non-negative")
