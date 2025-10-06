extends "res://tests/gut/gut_stub.gd"

const ClawRigScene := preload("res://scenes/session/ClawRig.tscn")
const ClawRigSolver := preload("res://scripts/gameplay/claw_rig_solver.gd")
const CabinetItemPool := preload("res://scripts/gameplay/cabinet_item_pool.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")
const OrderService := preload("res://autoload/order_service.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")

class CabinetItemPoolStub:
    extends CabinetItemPool

    var request_log: Array[StringName] = []
    var release_log: Array[RigidBody3D] = []
    var descriptor_override: StringName = StringName()
    var last_acquired: RigidBody3D
    var _descriptor_lookup: Dictionary = {}

    func _ready() -> void:
        catalog = null

    func acquire_item(descriptor_id: StringName) -> RigidBody3D:
        var target := descriptor_override if descriptor_override != StringName() else descriptor_id
        request_log.append(target)
        var body := RigidBody3D.new()
        body.freeze = true
        body.sleeping = true
        body.linear_velocity = Vector3.ZERO
        body.angular_velocity = Vector3.ZERO
        body.mass = 0.4
        body.gravity_scale = 1.0
        body.visible = true
        body.name = String(target)
        body.set_meta("descriptor_id", target)
        var shape := CollisionShape3D.new()
        shape.shape = BoxShape3D.new()
        shape.shape.extents = Vector3(0.2, 0.2, 0.2)
        body.add_child(shape)
        add_child(body)
        _descriptor_lookup[body] = target
        last_acquired = body
        return body

    func release_item(item: RigidBody3D) -> void:
        release_log.append(item)
        _descriptor_lookup.erase(item)
        item.queue_free()

    func get_descriptor_for(item: Node3D) -> StringName:
        return _descriptor_lookup.get(item, StringName())

var _signal_hub: SignalHub
var _order_service: OrderService
var _solver: ClawRigSolver
var _pool: CabinetItemPoolStub
var _started_events: Array[StringName] = []
var _captured_events: Array = []
var _released_events: Array = []
var _failed_events: Array[StringName] = []
var _orders_cleared: Array[StringName] = []
var _order_mismatches: Array[StringName] = []

func before_each() -> void:
    _signal_hub = SignalHub.new()
    add_child_autofree(_signal_hub)

    _order_service = OrderService.new()
    add_child_autofree(_order_service)

    _pool = CabinetItemPoolStub.new()
    add_child_autofree(_pool)

    var claw_scene := ClawRigScene.instantiate() as ClawRigSolver
    var drop_zone := Area3D.new()
    drop_zone.name = "TestDropZone"
    var shape := CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    shape.shape.extents = Vector3(0.4, 0.4, 0.4)
    drop_zone.add_child(shape)
    claw_scene.add_child(drop_zone)
    claw_scene.drop_zone_path = NodePath("TestDropZone")
    claw_scene.item_pool = _pool
    add_child_autofree(claw_scene)
    _solver = claw_scene
    wait_frames(1)
    _connect_signals()

func _connect_signals() -> void:
    if _signal_hub.has_signal("claw_grab_started"):
        _signal_hub.claw_grab_started.connect(func(order_id: StringName) -> void:
            _started_events.append(order_id)
        )
    if _signal_hub.has_signal("claw_item_captured"):
        _signal_hub.claw_item_captured.connect(func(descriptor_id: StringName, order_id: StringName) -> void:
            _captured_events.append([descriptor_id, order_id])
        )
    if _signal_hub.has_signal("claw_item_released"):
        _signal_hub.claw_item_released.connect(func(descriptor_id: StringName, order_id: StringName) -> void:
            _released_events.append([descriptor_id, order_id])
        )
    if _signal_hub.has_signal("claw_grab_failed"):
        _signal_hub.claw_grab_failed.connect(func(order_id: StringName) -> void:
            _failed_events.append(order_id)
        )
    if _order_service.has_signal("order_cleared"):
        _order_service.order_cleared.connect(func(order_id: StringName) -> void:
            _orders_cleared.append(order_id)
        )
    if _order_service.has_signal("order_visual_mismatch"):
        _order_service.order_visual_mismatch.connect(func(order_id: StringName, _descriptor: StringName) -> void:
            _order_mismatches.append(order_id)
        )

func after_each() -> void:
    _order_service.clear_all()
    _started_events.clear()
    _captured_events.clear()
    _released_events.clear()
    _failed_events.clear()
    _orders_cleared.clear()
    _order_mismatches.clear()
    _pool.descriptor_override = StringName()

func test_begin_lower_emits_started_event_and_grips_item() -> void:
    var descriptor := StringName("salmon")
    var order_id := _prepare_active_order(descriptor)
    _place_display_item(descriptor)

    _solver.begin_lower()
    wait_frames(4)
    _solver.execute_grip()
    wait_frames(6)

    assert_true(_started_events.size() >= 1, "Expected grab start signal")
    assert_eq(_solver.debug_get_state_name(), "CARRYING", "Solver should carry item after grip")
    assert_has(_captured_events, [descriptor, order_id], "Captured event should include descriptor and order")

func test_drop_routes_through_order_service() -> void:
    var descriptor := StringName("tuna")
    var order_id := _prepare_active_order(descriptor)
    _place_display_item(descriptor)

    _solver.begin_lower()
    wait_frames(3)
    _solver.execute_grip()
    wait_frames(4)
    _solver.retract_to_idle()
    wait_frames(3)

    var dropped_item := _pool.last_acquired
    _solver.process_drop(dropped_item)
    wait_frames(1)

    assert_has(_orders_cleared, order_id, "Order service should clear order after drop")
    assert_has(_released_events, [descriptor, order_id], "Release event should broadcast descriptor")

func test_wrong_item_triggers_mismatch() -> void:
    var descriptor := StringName("crab")
    var order_id := _prepare_active_order(descriptor)
    _pool.descriptor_override = StringName("shrimp")
    _place_display_item(descriptor)

    _solver.begin_lower()
    wait_frames(3)
    _solver.execute_grip()
    wait_frames(4)
    _solver.retract_to_idle()
    wait_frames(3)

    var dropped_item := _pool.last_acquired
    _solver.process_drop(dropped_item)
    wait_frames(1)

    assert_has(_order_mismatches, order_id, "Mismatch should be reported when wrong item delivered")
    assert_true(_pool.release_log.size() >= 1, "Item should be returned to pool after mismatch")

func _prepare_active_order(descriptor_id: StringName) -> StringName:
    var dto := OrderRequestDto.new()
    dto.order_id = StringName("order_%s" % String(descriptor_id))
    dto.descriptor_id = descriptor_id
    dto.seafood_name = "Test"
    dto.icon_path = "res://ui/icons/test.png"
    dto.tutorial_hint_key = StringName("hint")
    dto.icon_texture = null
    dto.patience_duration = 10.0
    dto.warning_threshold = 0.5
    dto.critical_threshold = 0.2
    var service := OrderService.get_instance()
    service.request_order(dto)
    _solver._on_order_visualized(descriptor_id, null, dto.order_id)
    return dto.order_id

func _place_display_item(descriptor_id: StringName) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.set_meta("descriptor_id", descriptor_id)
    var shape := CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    shape.shape.extents = Vector3(0.3, 0.3, 0.3)
    body.add_child(shape)
    add_child_autofree(body)
    var grip_area := _solver.get_node("ArmRoot/Grabber/GripArea") as Area3D
    body.global_transform = grip_area.global_transform
    _solver._on_grip_area_body_entered(body)
    return body

