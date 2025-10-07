extends Node
class_name PracticeOrchestrator

const OrderService := preload("res://autoload/order_service.gd")
const GameState := preload("res://autoload/game_state.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")
const OrderCatalog := preload("res://scripts/resources/order_catalog.gd")
const SceneDirector := preload("res://autoload/scene_director.gd")
const TutorialOverlay := preload("res://scripts/ui/tutorial_overlay.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")

const ORDER_CATALOG: OrderCatalog = preload("res://resources/data/order_catalog.tres")

@export var session_root_path: NodePath
@export var instructions_overlay_path: NodePath
@export var respawn_delay_sec: float = 1.5

var _session_root: Node
var _order_service: OrderService
var _game_state: GameState
var _tutorial_overlay: TutorialOverlay
var _active_order_id: StringName = StringName()
var _order_index: int = 0
var _started: bool = false
var _analytics: AnalyticsStub

func start() -> void:
	if _started:
		return
	_started = true
	_session_root = get_node_or_null(session_root_path)
	_tutorial_overlay = get_node_or_null(instructions_overlay_path) as TutorialOverlay
	_order_service = OrderService.get_instance()
	_game_state = GameState.get_instance()
	_analytics = AnalyticsStub.get_instance()
	_prepare_environment()
	_connect_signals()
	_show_instructions()
	_spawn_practice_order()

func stop() -> void:
	if not _started:
		return
	_disconnect_signals()
	_started = false

func _prepare_environment() -> void:
	if _game_state:
		_game_state.reset_state()
	if _session_root:
		var wave_controller := _session_root.get_node_or_null("WaveController")
		if wave_controller:
			wave_controller.set_process(false)
			wave_controller.queue_free()
	if _order_service:
		_order_service.clear_all()

func _connect_signals() -> void:
	if _tutorial_overlay and not _tutorial_overlay.dismissed.is_connected(_on_overlay_dismissed):
		_tutorial_overlay.dismissed.connect(_on_overlay_dismissed)
	if _order_service:
		if not _order_service.order_resolved_success.is_connected(_on_order_resolved_success):
			_order_service.order_resolved_success.connect(_on_order_resolved_success)
		if not _order_service.order_resolved_failure.is_connected(_on_order_resolved_failure):
			_order_service.order_resolved_failure.connect(_on_order_resolved_failure)

func _disconnect_signals() -> void:
	if _tutorial_overlay and _tutorial_overlay.dismissed.is_connected(_on_overlay_dismissed):
		_tutorial_overlay.dismissed.disconnect(_on_overlay_dismissed)
	if _order_service:
		if _order_service.order_resolved_success.is_connected(_on_order_resolved_success):
			_order_service.order_resolved_success.disconnect(_on_order_resolved_success)
		if _order_service.order_resolved_failure.is_connected(_on_order_resolved_failure):
			_order_service.order_resolved_failure.disconnect(_on_order_resolved_failure)

func _show_instructions() -> void:
	if _tutorial_overlay:
		_tutorial_overlay.show_overlay(
			"Practice the claw freely.\nGrab seafood, drop in the chute, and try different moves.",
			StringName("practice_overlay_instructions")
		)

func _on_overlay_dismissed() -> void:
	# No-op; overlay acts as informational banner.
	pass

func _spawn_practice_order(force: bool = false) -> void:
	if _order_service == null or ORDER_CATALOG == null or ORDER_CATALOG.orders.is_empty():
		return
	if not force and _active_order_id != StringName():
		return
	var definition := ORDER_CATALOG.get_next(_order_index)
	_order_index += 1
	if definition == null:
		return
	var dto := OrderRequestDto.new()
	dto.order_id = StringName("practice_%s_%d" % [String(definition.order_id), Time.get_ticks_msec()])
	dto.seafood_name = String(definition.localization_key)
	dto.icon_path = definition.icon_path
	dto.tutorial_hint_key = definition.tutorial_hint_key
	dto.descriptor_id = definition.descriptor_id
	dto.icon_texture = definition.icon
	dto.highlight_palette = definition.highlight_palette
	dto.patience_duration = maxf(definition.patience_duration * 1.5, 5.0)
	dto.warning_threshold = definition.warning_threshold
	dto.critical_threshold = definition.critical_threshold
	dto.base_score = max(definition.base_score, 50)
	dto.wave_index = 0
	_order_service.request_order(dto)
	_active_order_id = dto.order_id

func _schedule_respawn() -> void:
	var timer := get_tree().create_timer(max(respawn_delay_sec, 0.1))
	timer.timeout.connect(_on_respawn_timeout, CONNECT_ONE_SHOT)

func _on_respawn_timeout() -> void:
	_active_order_id = StringName()
	_spawn_practice_order()

func _on_order_resolved_success(order_id: StringName, payload: Dictionary) -> void:
	if order_id != _active_order_id:
		return
	_log_practice_result(StringName("success"), payload)
	_schedule_respawn()

func _on_order_resolved_failure(order_id: StringName, reason: StringName, payload: Dictionary) -> void:
	if order_id != _active_order_id:
		return
	_log_practice_result(reason, payload)
	_schedule_respawn()

func _log_practice_result(result: StringName, payload: Dictionary) -> void:
	if _analytics == null:
		return
	var data := {
		"result": result,
		"timestamp_ms": Time.get_ticks_msec(),
		"descriptor_id": payload.get("descriptor_id", StringName()),
		"remaining_time": payload.get("remaining_time", 0.0),
		"normalized_remaining": payload.get("normalized_remaining", 0.0),
	}
	_analytics.log_event(StringName("practice_result"), data)

func exit_to_menu() -> void:
	SceneDirector.get_instance().transition_to(StringName("main_menu"), {"entry": "practice_exit"})
