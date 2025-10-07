extends Node

const AnalyticsStub := preload("res://autoload/analytics_stub.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const Settings := preload("res://autoload/settings.gd")

const FADE_DURATION_SEC := 0.18
const FADE_COLOR := Color(0, 0, 0, 1)

const SCENE_REGISTRY: Dictionary[StringName, String] = {
	StringName("title"): "res://ui/screens/title_screen.tscn",
	StringName("main_menu"): "res://ui/screens/main_menu.tscn",
	StringName("session"): "res://scenes/session/SessionRoot.tscn",
	StringName("tutorial"): "res://scenes/tutorial/TutorialPlayground.tscn",
	StringName("practice_stub"): "res://ui/screens/practice_placeholder.tscn",
	StringName("records"): "res://ui/screens/records_screen.tscn",
	StringName("game_over"): "res://ui/screens/game_over_screen.tscn",
}

const OVERLAY_REGISTRY: Dictionary[StringName, String] = {
	StringName("pause"): "res://ui/screens/pause_overlay.tscn",
	StringName("options"): "res://ui/screens/options_screen.tscn",
}

signal scene_transitioned(scene_id: StringName, metadata: Dictionary)
signal overlay_pushed(overlay_id: StringName, metadata: Dictionary)
signal overlay_popped(overlay_id: StringName)

static var _instance: Node

var _active_scene_id: StringName = StringName()
var _active_scene: Node
var _scene_parent: Node
var _ui_layer: CanvasLayer
var _ui_base_holder: Control
var _overlay_holder: Control
var _fade_layer: ColorRect
var _overlay_stack: Array[Dictionary] = []
var _transition_in_progress: bool = false
var _analytics: AnalyticsStub
var _hub: SignalHub
var _settings: Node
var _reduced_motion_enabled: bool = false

func _ready() -> void:
	_instance = self
	_scene_parent = Node.new()
	_scene_parent.name = "SceneDirectorWorld"
	get_tree().root.call_deferred("add_child", _scene_parent)

	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	_ui_layer.name = "SceneDirectorUI"
	get_tree().root.call_deferred("add_child", _ui_layer)

	_ui_base_holder = Control.new()
	_ui_base_holder.name = "BaseUI"
	_ui_base_holder.anchor_right = 1.0
	_ui_base_holder.anchor_bottom = 1.0
	_ui_layer.add_child(_ui_base_holder)

	_overlay_holder = Control.new()
	_overlay_holder.name = "OverlayHolder"
	_overlay_holder.anchor_right = 1.0
	_overlay_holder.anchor_bottom = 1.0
	_ui_layer.add_child(_overlay_holder)

	_fade_layer = ColorRect.new()
	var initial_fade_color: Color = FADE_COLOR
	initial_fade_color.a = 0.0
	_fade_layer.color = initial_fade_color
	_fade_layer.anchor_right = 1.0
	_fade_layer.anchor_bottom = 1.0
	_fade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_fade_layer)

	_analytics = AnalyticsStub.get_instance()
	_hub = SignalHub.get_instance()
	_settings = Settings.get_instance()
	if _settings and _settings.has_signal("reduced_motion_toggled"):
		_settings.reduced_motion_toggled.connect(_on_reduced_motion_toggled)
	if _settings and _settings.has_method("is_reduced_motion_enabled"):
		_reduced_motion_enabled = _settings.is_reduced_motion_enabled()

	if _active_scene_id == StringName():
		transition_to(StringName("title"))

static func get_instance() -> Node:
	return _instance

func get_current_scene_id() -> StringName:
	return _active_scene_id

func is_transition_in_progress() -> bool:
	return _transition_in_progress

func transition_to(scene_id: StringName, metadata: Dictionary = {}) -> void:
	if _transition_in_progress:
		return
	var path: String = SCENE_REGISTRY.get(scene_id, "")
	if path == "":
		push_warning("SceneDirector: Unknown scene id %s" % String(scene_id))
		return
	_transition_in_progress = true
	await _fade_to(1.0)
	_unload_active_scene()
	var packed: Resource = ResourceLoader.load(path)
	if packed is PackedScene:
		var instance: Node = (packed as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		_attach_base_scene(instance)
		_apply_metadata(instance, metadata)
		_active_scene = instance
		_active_scene_id = scene_id
		_notify_transition(scene_id, metadata)
	else:
		push_warning("SceneDirector: Failed to load scene %s" % path)
	_active_scene_id = scene_id
	_clear_overlays()
	await _fade_to(0.0)
	_transition_in_progress = false

func push_overlay(overlay_id: StringName, metadata: Dictionary = {}) -> void:
	if _transition_in_progress:
		return
	var path: String = OVERLAY_REGISTRY.get(overlay_id, "")
	if path == "":
		push_warning("SceneDirector: Unknown overlay id %s" % String(overlay_id))
		return
	var packed := ResourceLoader.load(path)
	if not (packed is PackedScene):
		push_warning("SceneDirector: Failed to load overlay %s" % path)
		return
	var instance: Node = (packed as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	if instance is Control:
		instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		instance.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay_holder.add_child(instance)
	_apply_metadata(instance, metadata)
	_overlay_stack.append({"id": overlay_id, "node": instance})
	_emit_overlay_pushed(overlay_id, metadata)
	_update_pause_state()

func pop_overlay() -> void:
	if _overlay_stack.is_empty():
		return
	var entry: Dictionary = _overlay_stack.pop_back()
	var node: Node = entry.get("node", null)
	if node and node.is_inside_tree():
		node.queue_free()
	var overlay_id: StringName = entry.get("id", StringName())
	emit_signal("overlay_popped", overlay_id)
	if _hub:
		_hub.broadcast_overlay_hidden(overlay_id)
	_update_pause_state()

func pop_overlay_by_id(overlay_id: StringName) -> void:
	for i in range(_overlay_stack.size() - 1, -1, -1):
		var entry: Dictionary = _overlay_stack[i]
		if entry.get("id", StringName()) == overlay_id:
			_overlay_stack.remove_at(i)
			var node: Node = entry.get("node", null)
			if node and node.is_inside_tree():
				node.queue_free()
			emit_signal("overlay_popped", overlay_id)
			if _hub:
				_hub.broadcast_overlay_hidden(overlay_id)
			_update_pause_state()
			return

func pop_all_overlays() -> void:
	_clear_overlays()

func request_game_over(metadata: Dictionary = {}) -> void:
	transition_to(StringName("game_over"), metadata)

func _attach_base_scene(instance: Node) -> void:
	if instance is Control:
		instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_ui_base_holder.add_child(instance)
	else:
		_scene_parent.add_child(instance)

func _unload_active_scene() -> void:
	if _active_scene:
		if _active_scene.is_inside_tree():
			_active_scene.queue_free()
	_active_scene = null
	_active_scene_id = StringName()

func _clear_overlays() -> void:
	for entry in _overlay_stack:
		var node: Node = entry.get("node", null)
		if node and node.is_inside_tree():
			node.queue_free()
	_overlay_stack.clear()
	_update_pause_state()

func _apply_metadata(instance: Node, metadata: Dictionary) -> void:
	if metadata.is_empty():
		return
	if instance.has_method("apply_metadata"):
		instance.call("apply_metadata", metadata)
	elif instance.has_method("configure"):
		instance.call("configure", metadata)

func _notify_transition(scene_id: StringName, metadata: Dictionary) -> void:
	emit_signal("scene_transitioned", scene_id, metadata.duplicate(true))
	if _hub:
		_hub.broadcast_navigation(scene_id, metadata)
	if _analytics:
		var payload := {
			"scene_id": scene_id,
			"timestamp_ms": Time.get_ticks_msec(),
			"metadata": metadata.duplicate(true),
		}
		_analytics.log_event(StringName("screen_view"), payload)

func _emit_overlay_pushed(overlay_id: StringName, metadata: Dictionary) -> void:
	emit_signal("overlay_pushed", overlay_id, metadata.duplicate(true))
	if _hub:
		_hub.broadcast_overlay_shown(overlay_id, metadata)

func _fade_to(target_alpha: float) -> void:
	if _is_reduced_motion_enabled():
		var color := _fade_layer.color
		color.a = target_alpha
		_fade_layer.color = color
		await get_tree().process_frame
		return
	var tween: Tween = _fade_layer.create_tween()
	tween.tween_property(_fade_layer, "color:a", target_alpha, FADE_DURATION_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _update_pause_state() -> void:
	var should_pause := false
	for entry in _overlay_stack:
		if entry.get("id", StringName()) == StringName("pause"):
			should_pause = true
			break
	get_tree().paused = should_pause

func _on_reduced_motion_toggled(enabled: bool) -> void:
	_reduced_motion_enabled = enabled
	if enabled:
		var color := _fade_layer.color
		color.a = clampf(color.a, 0.0, 1.0)
		_fade_layer.color = color

func _is_reduced_motion_enabled() -> bool:
	return _reduced_motion_enabled
