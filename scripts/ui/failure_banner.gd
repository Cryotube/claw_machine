extends Control
class_name FailureBanner

const SignalHub := preload("res://autoload/signal_hub.gd")

@export var grace_period_sec: float = 2.0

var _signal_hub: SignalHub
var _hide_timer: SceneTreeTimer
var _title_label: Label
var _detail_label: Label
var _last_reason: StringName = StringName()

func _ready() -> void:
    _signal_hub = SignalHub.get_instance()
    _ensure_labels()
    visible = false
    _connect_signals()

func _exit_tree() -> void:
    _disconnect_signals()
    _cancel_hide_timer()

func _ensure_labels() -> void:
    _title_label = get_node_or_null("Title") as Label
    if _title_label == null:
        _title_label = Label.new()
        _title_label.name = "Title"
        _title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        add_child(_title_label)
    _detail_label = get_node_or_null("Detail") as Label
    if _detail_label == null:
        _detail_label = Label.new()
        _detail_label.name = "Detail"
        _detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _detail_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
        _detail_label.position = Vector2(0.0, 36.0)
        add_child(_detail_label)

func _connect_signals() -> void:
    if _signal_hub == null:
        return
    if not _signal_hub.order_resolved_failure.is_connected(_on_order_failure):
        _signal_hub.order_resolved_failure.connect(_on_order_failure)
    if not _signal_hub.order_failure_resolved.is_connected(_on_failure_resolved):
        _signal_hub.order_failure_resolved.connect(_on_failure_resolved)
    if not _signal_hub.order_resolved_success.is_connected(_on_order_success):
        _signal_hub.order_resolved_success.connect(_on_order_success)

func _disconnect_signals() -> void:
    if _signal_hub == null:
        return
    if _signal_hub.order_resolved_failure.is_connected(_on_order_failure):
        _signal_hub.order_resolved_failure.disconnect(_on_order_failure)
    if _signal_hub.order_failure_resolved.is_connected(_on_failure_resolved):
        _signal_hub.order_failure_resolved.disconnect(_on_failure_resolved)
    if _signal_hub.order_resolved_success.is_connected(_on_order_success):
        _signal_hub.order_resolved_success.disconnect(_on_order_success)

func _on_order_failure(order_id: StringName, reason: StringName, payload: Dictionary) -> void:
    _last_reason = reason
    visible = true
    _update_labels(reason, payload)
    _schedule_hide()

func _on_failure_resolved(_order_id: StringName, _payload: Dictionary) -> void:
    _schedule_hide()

func _on_order_success(_order_id: StringName, _payload: Dictionary) -> void:
    clear_banner()

func _update_labels(reason: StringName, payload: Dictionary) -> void:
    var reason_text := String(reason)
    if reason_text.is_empty():
        reason_text = "failure"
    _title_label.text = reason_text.capitalize() + "!"
    var combo_snapshot := int(payload.get("combo_snapshot", -1))
    var lives_remaining := int(payload.get("lives", -1))
    var detail_parts: Array[String] = []
    detail_parts.append("reason: %s" % reason_text.to_lower())
    if combo_snapshot > 0:
        detail_parts.append("Combo reset from %d" % combo_snapshot)
    if lives_remaining >= 0:
        detail_parts.append("Lives left: %d" % lives_remaining)
    if detail_parts.is_empty():
        detail_parts.append("Shake it off and try again")
    _detail_label.text = ", ".join(detail_parts)

func _schedule_hide() -> void:
    _cancel_hide_timer()
    if grace_period_sec <= 0.0:
        clear_banner()
        return
    _hide_timer = get_tree().create_timer(grace_period_sec)
    _hide_timer.timeout.connect(clear_banner)

func _cancel_hide_timer() -> void:
    if _hide_timer:
        if _hide_timer.timeout.is_connected(clear_banner):
            _hide_timer.timeout.disconnect(clear_banner)
        _hide_timer.queue_free()
        _hide_timer = null

func clear_banner() -> void:
    _cancel_hide_timer()
    visible = false

func update_safe_area(is_portrait: bool, padding: Vector2) -> void:
    if is_portrait:
        anchor_left = 0.15
        anchor_right = 0.85
        anchor_top = 0.2
        anchor_bottom = 0.35
    else:
        anchor_left = 0.32
        anchor_right = 0.68
        anchor_top = 0.12
        anchor_bottom = 0.24
    offset_left = padding.x
    offset_right = -padding.x
    offset_top = padding.y
    offset_bottom = 0.0

func debug_get_banner_text() -> String:
    return _title_label.text + " " + _detail_label.text
