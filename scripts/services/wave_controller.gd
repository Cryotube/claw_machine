extends Node
class_name WaveController

const OrderService := preload("res://autoload/order_service.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const GameState := preload("res://autoload/game_state.gd")
const OrderCatalog := preload("res://scripts/resources/order_catalog.gd")
const OrderDefinition := preload("res://scripts/resources/order_definition.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")
const WaveConfigResource := preload("res://scripts/resources/wave_config_resource.gd")
const WaveSettingsDto := preload("res://scripts/dto/wave_settings_dto.gd")
const CustomerQueue := preload("res://scripts/gameplay/customer_queue.gd")
const CabinetItemPool := preload("res://scripts/gameplay/cabinet_item_pool.gd")

@export var wave_config: WaveConfigResource
@export var order_catalog: OrderCatalog
@export var customer_queue_path: NodePath
@export var cabinet_pool_path: NodePath
@export var spawn_warning_threshold_ratio: float = 0.2

var _order_service: OrderService
var _signal_hub: SignalHub
var _analytics: AnalyticsStub
var _game_state: GameState
var _queue: CustomerQueue
var _cabinet_pool: CabinetItemPool

var _current_wave: int = 1
var _active_settings: WaveSettingsDto
var _spawned_orders: int = 0
var _resolved_orders: int = 0
var _order_sequence_index: int = 0
var _wave_start_time_ms: int = 0
var _wave_in_progress: bool = false
var _last_spawn_success: bool = false

func _ready() -> void:
    _order_service = OrderService.get_instance()
    _signal_hub = SignalHub.get_instance()
    _analytics = AnalyticsStub.get_instance()
    _game_state = GameState.get_instance()
    _queue = get_node_or_null(customer_queue_path) as CustomerQueue
    _cabinet_pool = get_node_or_null(cabinet_pool_path) as CabinetItemPool
    _connect_services()
    _start_initial_wave()

func _exit_tree() -> void:
    if _order_service:
        if _order_service.order_resolved_success.is_connected(_on_order_resolved_success):
            _order_service.order_resolved_success.disconnect(_on_order_resolved_success)
        if _order_service.order_resolved_failure.is_connected(_on_order_resolved_failure):
            _order_service.order_resolved_failure.disconnect(_on_order_resolved_failure)
    if _game_state and _game_state.wave_changed.is_connected(_on_wave_changed):
        _game_state.wave_changed.disconnect(_on_wave_changed)

func _connect_services() -> void:
    if _order_service:
        if not _order_service.order_resolved_success.is_connected(_on_order_resolved_success):
            _order_service.order_resolved_success.connect(_on_order_resolved_success)
        if not _order_service.order_resolved_failure.is_connected(_on_order_resolved_failure):
            _order_service.order_resolved_failure.connect(_on_order_resolved_failure)
    if _game_state and not _game_state.wave_changed.is_connected(_on_wave_changed):
        _game_state.wave_changed.connect(_on_wave_changed)

func _start_initial_wave() -> void:
    var baseline_index: int = 0
    if _game_state:
        baseline_index = _game_state.get_wave_index()
    _begin_wave(baseline_index + 1)

func _on_wave_changed(wave_index: int) -> void:
    var next_wave: int = wave_index + 1
    if next_wave <= _current_wave:
        return
    _complete_wave_summary()
    _begin_wave(next_wave)

func _begin_wave(target_wave: int) -> void:
    if wave_config == null:
        push_warning("Wave configuration resource missing; cannot drive progression")
        return
    _current_wave = max(1, target_wave)
    _active_settings = wave_config.get_settings(_current_wave)
    _spawned_orders = 0
    _resolved_orders = 0
    _wave_start_time_ms = Time.get_ticks_msec()
    _wave_in_progress = true
    if _order_service:
        _order_service.configure_wave(_active_settings.patience_multiplier, _active_settings.score_multiplier, _current_wave)
    if _cabinet_pool != null:
        _cabinet_pool.configure_for_wave(
            _current_wave,
            _active_settings.cabinet_clutter_level,
            _active_settings.cabinet_density_multiplier,
            _resolve_items_per_descriptor()
        )
    if _queue != null:
        _queue.configure_wave(_active_settings, Callable(self, "_spawn_next_order"))
    _broadcast_wave_started()

func _resolve_items_per_descriptor() -> int:
    var metadata: Dictionary = _active_settings.metadata
    if metadata.has("items_per_descriptor"):
        return int(metadata["items_per_descriptor"])
    return max(_active_settings.cabinet_clutter_level + 2, 3)

func _spawn_next_order() -> void:
    _last_spawn_success = false
    if order_catalog == null or _order_service == null:
        return
    var definition: OrderDefinition = order_catalog.get_next(_order_sequence_index)
    _order_sequence_index += 1
    if definition == null:
        return
    var dto := OrderRequestDto.new()
    var order_id := StringName("wave_%s_%s" % [_current_wave, _spawned_orders + 1])
    dto.order_id = order_id
    dto.seafood_name = String(definition.localization_key)
    dto.icon_path = definition.icon_path
    dto.tutorial_hint_key = definition.tutorial_hint_key
    dto.descriptor_id = definition.descriptor_id
    dto.icon_texture = definition.icon
    dto.highlight_palette = definition.highlight_palette
    dto.patience_duration = maxf(definition.patience_duration, 0.1)
    dto.warning_threshold = definition.warning_threshold
    dto.critical_threshold = definition.critical_threshold
    dto.base_score = 100
    dto.wave_index = _current_wave
    _order_service.request_order(dto)
    _spawned_orders += 1
    _last_spawn_success = true
    _broadcast_wave_progress()
    _maybe_emit_spawn_warning()

func _maybe_emit_spawn_warning() -> void:
    if _signal_hub == null or _active_settings == null:
        return
    var schedule: PackedFloat32Array = _active_settings.spawn_schedule
    if schedule.is_empty():
        return
    var current_index: int = clampi(_spawned_orders - 1, 0, schedule.size() - 1)
    if current_index >= schedule.size() - 1:
        return
    var current_interval: float = schedule[current_index]
    var next_interval: float = schedule[current_index + 1]
    if current_interval <= 0.0:
        current_interval = next_interval
    if current_interval <= 0.0:
        return
    var reduction: float = current_interval - next_interval
    if reduction <= 0.0:
        return
    var ratio: float = reduction / current_interval
    if ratio < spawn_warning_threshold_ratio:
        return
    var payload := {
        "wave_index": _current_wave,
        "current_interval": current_interval,
        "next_interval": next_interval,
        "spawned": _spawned_orders,
        "total": _active_settings.spawn_schedule.size(),
    }
    _signal_hub.broadcast_wave_warning(_current_wave, payload)

func _on_order_resolved_success(order_id: StringName, payload: Dictionary) -> void:
    _handle_resolution(payload)

func _on_order_resolved_failure(order_id: StringName, reason: StringName, payload: Dictionary) -> void:
    _handle_resolution(payload)

func _handle_resolution(payload: Dictionary) -> void:
    if not _wave_in_progress or _active_settings == null:
        return
    var payload_wave: int = int(payload.get("wave_index", _current_wave))
    if payload_wave != _current_wave:
        return
    _resolved_orders += 1
    if _resolved_orders >= _active_settings.spawn_schedule.size():
        _complete_wave_summary()

func _complete_wave_summary() -> void:
    if not _wave_in_progress or _active_settings == null:
        return
    _wave_in_progress = false
    var duration_ms: int = Time.get_ticks_msec() - _wave_start_time_ms
    var summary := {
        "wave_index": _current_wave,
        "spawned": _spawned_orders,
        "resolved": _resolved_orders,
        "patience_multiplier": _active_settings.patience_multiplier,
        "score_multiplier": _active_settings.score_multiplier,
        "clutter_level": _active_settings.cabinet_clutter_level,
        "density_multiplier": _active_settings.cabinet_density_multiplier,
        "duration_ms": duration_ms,
    }
    if _analytics:
        _analytics.log_event(StringName("wave_completed"), summary)
    if _signal_hub:
        _signal_hub.broadcast_wave_completed(_current_wave, summary)

func _broadcast_wave_started() -> void:
    if _signal_hub == null or _active_settings == null:
        return
    var metadata := _active_settings.metadata.duplicate(true)
    metadata["spawn_schedule"] = _active_settings.spawn_schedule
    metadata["warmup_delay_sec"] = _active_settings.warmup_delay_sec
    metadata["patience_multiplier"] = _active_settings.patience_multiplier
    metadata["score_multiplier"] = _active_settings.score_multiplier
    metadata["clutter_level"] = _active_settings.cabinet_clutter_level
    metadata["density_multiplier"] = _active_settings.cabinet_density_multiplier
    metadata["total_orders"] = _active_settings.spawn_schedule.size()
    _signal_hub.broadcast_wave_started(_current_wave, metadata)
    _broadcast_wave_progress()
    if _analytics:
        _analytics.log_event(StringName("wave_started"), metadata)

func _broadcast_wave_progress() -> void:
    if _signal_hub == null or _active_settings == null:
        return
    var total := _active_settings.spawn_schedule.size()
    _signal_hub.broadcast_wave_progress(_current_wave, _spawned_orders, total)

func debug_is_ready() -> bool:
    return _order_service != null and _queue != null

func debug_get_spawned_orders() -> int:
    return _spawned_orders

func debug_get_order_sequence() -> int:
    return _order_sequence_index


func debug_get_last_spawn_success() -> bool:
    return _last_spawn_success

func debug_override_order_service(service: OrderService) -> void:
    _order_service = service
