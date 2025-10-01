extends Node

const SessionRootScene = preload("res://scenes/session/SessionRoot.tscn")
const OrderServiceScript = preload("res://autoload/order_service.gd")
const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")

const FRAME_COUNT := 600

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    await get_tree().process_frame
    var session_root = SessionRootScene.instantiate()
    add_child(session_root)
    await get_tree().process_frame
    _seed_orders()
    await get_tree().process_frame
    var start_ms := Time.get_ticks_msec()
    for _i in FRAME_COUNT:
        await get_tree().process_frame
    var duration_ms := Time.get_ticks_msec() - start_ms
    var average_frame_ms := float(duration_ms) / float(FRAME_COUNT)
    print("Frames:", FRAME_COUNT, "Duration(ms):", duration_ms, "Avg(ms):", average_frame_ms)
    if average_frame_ms > 16.67:
        push_error("Average frame time %.2f ms exceeds 16.67 ms budget" % average_frame_ms)
        get_tree().quit(1)
    else:
        print("Performance within 60 FPS budget")
        get_tree().quit()

func _seed_orders() -> void:
    var order_service = OrderServiceScript.get_instance()
    if order_service == null:
        push_error("OrderService instance missing; cannot seed orders")
        return
    for i in range(3):
        var dto := OrderRequestDto.new()
        dto.order_id = StringName("perf_order_%d" % i)
        dto.seafood_name = "order_salmon_nigiri"
        dto.tutorial_hint_key = StringName("tutorial_hint_default")
        dto.patience_duration = 8.0
        dto.warning_threshold = 0.4
        dto.critical_threshold = 0.2
        order_service.request_order(dto)
