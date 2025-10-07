extends "res://tests/gut/gut_stub.gd"

const TutorialScene := preload("res://scenes/tutorial/TutorialPlayground.tscn")
const SceneDirector := preload("res://autoload/scene_director.gd")
const Settings := preload("res://autoload/settings.gd")
const OrderService := preload("res://autoload/order_service.gd")

var _playground

func before_each() -> void:
	var settings := Settings.get_instance()
	if settings:
		settings.tutorial_completed = false
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
	var overlay := _playground.get_node("SessionRoot/UI/TutorialOverlay")
	var orchestrator := _playground.get_node("TutorialOrchestrator")
	var claw_input := _playground.get_node("SessionRoot/ClawInputController")

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
