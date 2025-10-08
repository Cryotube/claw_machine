extends Node

const GutTest = preload("res://tests/gut/gut_stub.gd")
const TEST_PATHS := [
    # Unit tests
    "res://tests/gut/unit/test_customer_queue.gd",
    "res://tests/gut/unit/test_order_banner.gd",
    "res://tests/gut/unit/test_cabinet_highlight_controller.gd",
    "res://tests/gut/unit/test_order_visual_sync.gd",
    "res://tests/gut/unit/test_claw_input_controller.gd",
    "res://tests/gut/unit/test_claw_rig_solver.gd",
    "res://tests/gut/unit/test_persistence_service.gd",
    "res://tests/gut/unit/test_tutorial_overlay.gd",
    "res://tests/gut/unit/test_wave_config.gd",
    # UI tests
    "res://tests/gut/ui/test_scene_director.gd",
    "res://tests/gut/ui/test_tutorial_orchestrator.gd",
    "res://tests/gut/ui/test_title_screen.gd",
    "res://tests/gut/ui/test_main_menu.gd",
    "res://tests/gut/ui/test_options_screen.gd",
    "res://tests/gut/ui/test_pause_overlay.gd",
    "res://tests/gut/ui/test_records_screen.gd",
    "res://tests/gut/ui/test_game_over_screen.gd",
]

var _total_failures: int = 0
var _total_tests: int = 0

func _ready() -> void:
    _execute()

func _execute() -> void:
    call_deferred("_run")

func _run() -> void:
    await get_tree().process_frame
    for path in TEST_PATHS:
        var script: GDScript = load(path)
        if script == null:
            push_error("Failed to load test script at %s" % path)
            _total_failures += 1
            continue
        await _run_script(script)
    if _total_failures > 0:
        push_error("Test run completed with %d failures across %d tests" % [_total_failures, _total_tests])
        get_tree().quit(1)
        return
    print("All %d tests passed" % _total_tests)
    get_tree().quit()

func _run_script(script: GDScript) -> void:
    var test_instance: GutTest = script.new()
    add_child(test_instance)
    var methods: Array[String] = []
    for method_info in test_instance.get_method_list():
        var name: String = method_info.name
        if name.begins_with("test_"):
            methods.append(name)
    methods.sort()
    for method_name in methods:
        _total_tests += 1
        test_instance._prepare_test(method_name)
        var state = test_instance.callv("before_each", [])
        await _await_if_state(state)
        state = test_instance.callv(method_name, [])
        await _await_if_state(state)
        state = test_instance.callv("after_each", [])
        await _await_if_state(state)
        if test_instance._has_failures():
            _total_failures += test_instance._get_failures().size()
        test_instance._finish_test()
    remove_child(test_instance)
    test_instance.queue_free()

func _await_if_state(state) -> void:
    if state is Object and state.is_class("GDScriptFunctionState"):
        await state
