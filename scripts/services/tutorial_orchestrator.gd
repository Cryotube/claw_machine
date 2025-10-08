extends Node
class_name TutorialOrchestrator

const SceneDirector := preload("res://autoload/scene_director.gd")
const OrderService := preload("res://autoload/order_service.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const Settings := preload("res://autoload/settings.gd")
const GameState := preload("res://autoload/game_state.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")
const OrderCatalog := preload("res://scripts/resources/order_catalog.gd")
const ClawInputController := preload("res://scripts/gameplay/claw_input_controller.gd")
const TutorialOverlay := preload("res://scripts/ui/tutorial_overlay.gd")
const ORDER_CATALOG: OrderCatalog = preload("res://resources/data/order_catalog.tres")

enum TutorialStep {
	INTRO,
	AIM,
	LOWER,
	GRIP,
	DROP,
	SERVE,
	COMPLETE
}

@export var session_root_path: NodePath

var _session_root: Node
var _claw_input: ClawInputController
var _tutorial_overlay: TutorialOverlay
var _wave_controller: Node

var _order_service: OrderService
var _signal_hub: SignalHub
var _analytics: AnalyticsStub
var _settings: Settings

var _current_step: int = TutorialStep.INTRO
var _step_started_ms: int = 0
var _active_order_id: StringName = StringName()
var _tutorial_order_index: int = 0
var _completed: bool = false
var _started: bool = false
const STEP_COPY := {
	TutorialStep.INTRO: {
		"key": StringName("tutorial_step_intro"),
		"fallback": "Welcome to Claw & Snackle!\nWe'll guide you through your first order.",
	},
	TutorialStep.AIM: {
		"key": StringName("tutorial_step_aim"),
		"fallback": "Step 1: Drag the joystick to aim the claw above the seafood.",
	},
	TutorialStep.LOWER: {
		"key": StringName("tutorial_step_lower"),
		"fallback": "Step 2: Hold the GRAB button to lower the claw.",
	},
	TutorialStep.GRIP: {
		"key": StringName("tutorial_step_grip"),
		"fallback": "Step 3: Release GRAB to close the claw around the seafood.",
	},
	TutorialStep.DROP: {
		"key": StringName("tutorial_step_drop"),
		"fallback": "Step 4: Move to the chute and tap DROP to carry the seafood over.",
	},
	TutorialStep.SERVE: {
		"key": StringName("tutorial_step_serve"),
		"fallback": "Final Step: Drop the seafood in the chute to serve the cat!",
	},
	TutorialStep.COMPLETE: {
		"key": StringName("tutorial_step_complete"),
		"fallback": "Tutorial complete! Tap to return to the menu.",
	},
}

const FAILURE_COPY := {
	"key": StringName("tutorial_step_retry"),
	"fallback": "Almost! Let's try again.\nAim the claw and keep an eye on the patience meter.",
}

const SUMMARY_COPY := {
	"key": StringName("tutorial_summary_complete"),
	"fallback": "Nice work! You completed onboarding.\nHead back to the menu to start a score run.",
}

func start() -> void:
	if _started:
		return
	_started = true
	_session_root = get_node_or_null(session_root_path)
	if _session_root == null:
		push_warning("TutorialOrchestrator: session root not assigned")
		return
	_claw_input = _session_root.get_node_or_null("ClawInputController") as ClawInputController
	_tutorial_overlay = _session_root.get_node_or_null("UI/TutorialOverlay") as TutorialOverlay
	_wave_controller = _session_root.get_node_or_null("WaveController")

	_order_service = OrderService.get_instance()
	_signal_hub = SignalHub.get_instance()
	_analytics = AnalyticsStub.get_instance()
	_settings = Settings.get_instance()
	_prepare_environment()
	_connect_signals()
	_enter_step(TutorialStep.INTRO)

func _prepare_environment() -> void:
	if _order_service:
		_order_service.clear_all()
	if _wave_controller:
		_wave_controller.set_process(false)
		_wave_controller.queue_free()
	var state := GameState.get_instance()
	if state:
		state.reset_state()

func _connect_signals() -> void:
	if _tutorial_overlay and not _tutorial_overlay.dismissed.is_connected(_on_overlay_dismissed):
		_tutorial_overlay.dismissed.connect(_on_overlay_dismissed)
	if _claw_input:
		if not _claw_input.movement_input.is_connected(_on_movement_input):
			_claw_input.movement_input.connect(_on_movement_input)
		if not _claw_input.extend_pressed.is_connected(_on_extend_pressed):
			_claw_input.extend_pressed.connect(_on_extend_pressed)
		if not _claw_input.extend_released.is_connected(_on_extend_released):
			_claw_input.extend_released.connect(_on_extend_released)
		if not _claw_input.retract_pressed.is_connected(_on_retract_pressed):
			_claw_input.retract_pressed.connect(_on_retract_pressed)
	if _order_service:
		if not _order_service.order_resolved_success.is_connected(_on_order_success):
			_order_service.order_resolved_success.connect(_on_order_success)
		if not _order_service.order_resolved_failure.is_connected(_on_order_failure):
			_order_service.order_resolved_failure.connect(_on_order_failure)

func _disconnect_signals() -> void:
	if _tutorial_overlay and _tutorial_overlay.dismissed.is_connected(_on_overlay_dismissed):
		_tutorial_overlay.dismissed.disconnect(_on_overlay_dismissed)
	if _claw_input:
		if _claw_input.movement_input.is_connected(_on_movement_input):
			_claw_input.movement_input.disconnect(_on_movement_input)
		if _claw_input.extend_pressed.is_connected(_on_extend_pressed):
			_claw_input.extend_pressed.disconnect(_on_extend_pressed)
		if _claw_input.extend_released.is_connected(_on_extend_released):
			_claw_input.extend_released.disconnect(_on_extend_released)
		if _claw_input.retract_pressed.is_connected(_on_retract_pressed):
			_claw_input.retract_pressed.disconnect(_on_retract_pressed)
	if _order_service:
		if _order_service.order_resolved_success.is_connected(_on_order_success):
			_order_service.order_resolved_success.disconnect(_on_order_success)
		if _order_service.order_resolved_failure.is_connected(_on_order_failure):
			_order_service.order_resolved_failure.disconnect(_on_order_failure)

func _enter_step(step: int) -> void:
	_current_step = step
	_step_started_ms = Time.get_ticks_msec()
	match step:
		TutorialStep.INTRO:
			_set_control_gates(false, false, false)
		TutorialStep.AIM:
			_set_control_gates(true, false, false)
			_ensure_order_spawned()
		TutorialStep.LOWER:
			_set_control_gates(true, true, false)
		TutorialStep.GRIP:
			_set_control_gates(true, true, false)
		TutorialStep.DROP:
			_set_control_gates(true, true, true)
		TutorialStep.SERVE:
			_set_control_gates(true, true, true)
		TutorialStep.COMPLETE:
			_set_control_gates(true, true, true)
	_display_step_overlay(step)

func _set_control_gates(movement: bool, extend: bool, retract: bool) -> void:
	if _claw_input:
		_claw_input.set_control_gates(movement, extend, retract)

func _display_step_overlay(step: int) -> void:
	var entry: Dictionary = STEP_COPY.get(step, {})
	var key: StringName = entry.get("key", StringName())
	var fallback: String = entry.get("fallback", "")
	_show_overlay_localized(key, fallback)

func _show_overlay_localized(text_key: StringName, fallback: String) -> void:
	if _tutorial_overlay:
		_tutorial_overlay.show_overlay(fallback, text_key)

func _on_overlay_dismissed() -> void:
	match _current_step:
		TutorialStep.INTRO:
			_complete_step(TutorialStep.INTRO)
		TutorialStep.COMPLETE:
			_finalize_tutorial()
		_:
			pass

func _on_movement_input(vector: Vector2) -> void:
	if _current_step != TutorialStep.AIM:
		return
	if vector.length() < 0.25:
		return
	_complete_step(TutorialStep.AIM)

func _on_extend_pressed() -> void:
	if _current_step == TutorialStep.LOWER:
		_complete_step(TutorialStep.LOWER)

func _on_extend_released() -> void:
	if _current_step == TutorialStep.GRIP:
		_complete_step(TutorialStep.GRIP)

func _on_retract_pressed() -> void:
	if _current_step == TutorialStep.DROP:
		_complete_step(TutorialStep.DROP)

func _on_order_success(order_id: StringName, _payload: Dictionary) -> void:
	if _current_step != TutorialStep.SERVE:
		return
	if _active_order_id != StringName() and order_id != _active_order_id:
		return
	_active_order_id = StringName()
	_complete_step(TutorialStep.SERVE)

func _on_order_failure(order_id: StringName, _reason: StringName, _payload: Dictionary) -> void:
	if _active_order_id == StringName() or order_id != _active_order_id:
		return
	_active_order_id = StringName()
	_show_overlay_localized(FAILURE_COPY.get("key", StringName()), FAILURE_COPY.get("fallback", ""))
	_ensure_order_spawned(true)
	_enter_step(TutorialStep.AIM)

func _complete_step(step: int) -> void:
	var duration_ms := Time.get_ticks_msec() - _step_started_ms
	_log_step_completion(step, duration_ms)
	var next_step := _next_step(step)
	if next_step == TutorialStep.COMPLETE:
		if _settings and _settings.has_method("mark_tutorial_complete"):
			_settings.mark_tutorial_complete("tutorial_orchestrator")
		if _analytics:
			_analytics.log_event(StringName("tutorial_completed"), {
				"timestamp_ms": Time.get_ticks_msec()
			})
	_enter_step(next_step)

func _next_step(step: int) -> int:
	match step:
		TutorialStep.INTRO:
			return TutorialStep.AIM
		TutorialStep.AIM:
			return TutorialStep.LOWER
		TutorialStep.LOWER:
			return TutorialStep.GRIP
		TutorialStep.GRIP:
			return TutorialStep.DROP
		TutorialStep.DROP:
			return TutorialStep.SERVE
		TutorialStep.SERVE:
			return TutorialStep.COMPLETE
		_:
			return TutorialStep.COMPLETE

func _log_step_completion(step: int, duration_ms: int) -> void:
	if _analytics == null:
		return
	var payload := {
		"step_id": _step_to_string(step),
		"duration": float(duration_ms) / 1000.0
	}
	_analytics.log_event(StringName("tutorial_step_completed"), payload)

func _step_to_string(step: int) -> String:
	match step:
		TutorialStep.INTRO:
			return "intro"
		TutorialStep.AIM:
			return "aim"
		TutorialStep.LOWER:
			return "lower"
		TutorialStep.GRIP:
			return "grip"
		TutorialStep.DROP:
			return "drop"
		TutorialStep.SERVE:
			return "serve"
		TutorialStep.COMPLETE:
			return "complete"
		_:
			return "unknown"

func _ensure_order_spawned(force: bool = false) -> void:
	if _order_service == null:
		return
	if not force and _active_order_id != StringName():
		return
	if force:
		_order_service.clear_all()
	var definition: Variant = _next_order_definition()
	if definition == null:
		return
	var dto := OrderRequestDto.new()
	dto.order_id = StringName("tutorial_%d" % Time.get_ticks_msec())
	dto.seafood_name = String(definition.localization_key)
	dto.icon_path = definition.icon_path
	dto.tutorial_hint_key = definition.tutorial_hint_key
	dto.descriptor_id = definition.descriptor_id
	dto.icon_texture = definition.icon
	dto.highlight_palette = definition.highlight_palette
	dto.patience_duration = definition.patience_duration
	dto.warning_threshold = definition.warning_threshold
	dto.critical_threshold = definition.critical_threshold
	_order_service.request_order(dto)
	_active_order_id = dto.order_id

func _next_order_definition():
	if ORDER_CATALOG == null or ORDER_CATALOG.orders.is_empty():
		return null
	var count := ORDER_CATALOG.orders.size()
	var index := clampi(_tutorial_order_index, 0, count - 1)
	_tutorial_order_index = (index + 1) % count
	return ORDER_CATALOG.orders[index]

func _finalize_tutorial() -> void:
	if _completed:
		return
	_completed = true
	_disconnect_signals()
	if _claw_input:
		_claw_input.reset_control_gates()
	if _tutorial_overlay:
		_tutorial_overlay.dismissed.connect(_on_summary_dismissed, CONNECT_ONE_SHOT)
		_show_overlay_localized(SUMMARY_COPY.get("key", StringName()), SUMMARY_COPY.get("fallback", "Tutorial complete!"))
	else:
		SceneDirector.get_instance().transition_to(StringName("main_menu"), {"entry": "tutorial_complete"})

func _on_summary_dismissed() -> void:
	SceneDirector.get_instance().transition_to(StringName("main_menu"), {"entry": "tutorial_complete"})
