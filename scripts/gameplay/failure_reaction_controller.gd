extends Node
class_name FailureReactionController

const SignalHub := preload("res://autoload/signal_hub.gd")
const AudioDirector := preload("res://autoload/audio_director.gd")
const CustomerQueue := preload("res://scripts/gameplay/customer_queue.gd")

@export var queue_path: NodePath
@export var release_delay_sec: float = 0.4
@export var effect_scene: PackedScene

var _queue: CustomerQueue
var _signal_hub: SignalHub
var _audio: AudioDirector
var _effect_pool: Array[Node3D] = []
var _active_effects: Dictionary = {}
var _all_effects: Array[Node3D] = []
var _last_reason: StringName = StringName()

func _ready() -> void:
    _resolve_references()
    _connect_signals()

func _exit_tree() -> void:
    _disconnect_signals()
    _queue = null

func set_queue(queue: CustomerQueue) -> void:
    _queue = queue

func _resolve_references() -> void:
    if _queue == null and queue_path != NodePath():
        _queue = get_node_or_null(queue_path) as CustomerQueue
    _signal_hub = SignalHub.get_instance()
    _audio = AudioDirector.get_instance()

func _connect_signals() -> void:
    if _signal_hub:
        if not _signal_hub.order_resolved_failure.is_connected(_on_order_failure):
            _signal_hub.order_resolved_failure.connect(_on_order_failure)
        if not _signal_hub.order_failure_resolved.is_connected(_on_failure_resolved):
            _signal_hub.order_failure_resolved.connect(_on_failure_resolved)

func _disconnect_signals() -> void:
    if _signal_hub:
        if _signal_hub.order_resolved_failure.is_connected(_on_order_failure):
            _signal_hub.order_resolved_failure.disconnect(_on_order_failure)
        if _signal_hub.order_failure_resolved.is_connected(_on_failure_resolved):
            _signal_hub.order_failure_resolved.disconnect(_on_failure_resolved)

func _on_order_failure(order_id: StringName, reason: StringName, payload: Dictionary) -> void:
    _last_reason = reason
    var queue := _queue
    if queue == null:
        queue = get_node_or_null(queue_path) as CustomerQueue
        _queue = queue

    if queue:
        var customer := queue.get_customer_for_order(order_id)
        if customer:
            var effect := _acquire_effect()
            customer.add_child(effect)
            if effect is Node3D:
                var node_effect := effect as Node3D
                node_effect.transform = Transform3D.IDENTITY
                node_effect.visible = true
            _active_effects[order_id] = effect
        var delay_sec := float(payload.get("restart_window_sec", release_delay_sec))
        queue.defer_release(order_id, payload, delay_sec)

    _play_audio(reason)

func _on_failure_resolved(order_id: StringName, _payload: Dictionary) -> void:
    if _active_effects.has(order_id):
        var effect: Node3D = _active_effects[order_id]
        _active_effects.erase(order_id)
        _release_effect(effect)

func _acquire_effect() -> Node3D:
    if not _effect_pool.is_empty():
        return _effect_pool.pop_back()
    var instance := _instantiate_effect()
    _all_effects.append(instance)
    return instance

func _instantiate_effect() -> Node3D:
    if effect_scene:
        var packed := effect_scene.instantiate()
        if packed is Node3D:
            var node := packed as Node3D
            node.visible = false
            add_child(node)
            return node
        packed.queue_free()
    var fallback := Node3D.new()
    fallback.name = "FailureEffect"
    fallback.visible = false
    add_child(fallback)
    return fallback

func _release_effect(effect: Node3D) -> void:
    if effect == null:
        return
    if effect.get_parent() and effect.get_parent() != self:
        effect.get_parent().remove_child(effect)
        add_child(effect)
    effect.visible = false
    _effect_pool.append(effect)

func _play_audio(reason: StringName) -> void:
    if _audio == null:
        _audio = AudioDirector.get_instance()
    if _audio == null:
        return
    var event_name := _build_audio_event(reason)
    if event_name != StringName():
        _audio.play_event(event_name)

func _build_audio_event(reason: StringName) -> StringName:
    match String(reason):
        "timeout":
            return StringName("failure_timeout")
        "mismatch":
            return StringName("failure_mismatch")
        _:
            return StringName("failure_generic")

func debug_get_effect_instance_ids() -> Array[int]:
    var ids: Array[int] = []
    for effect in _all_effects:
        if effect:
            ids.append(effect.get_instance_id())
    return ids

func debug_get_last_reason() -> StringName:
    return _last_reason
