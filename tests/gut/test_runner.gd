extends Node

const GutTest = preload("res://tests/gut/gut_stub.gd")
const TEST_SCRIPTS := [
    preload("res://tests/gut/unit/test_customer_queue.gd"),
    preload("res://tests/gut/unit/test_order_banner.gd"),
]

var _total_failures: int = 0
var _total_tests: int = 0

func _ready() -> void:
    _execute()

func _execute() -> void:
    call_deferred("_run")

func _run() -> void:
    await get_tree().process_frame
    for script in TEST_SCRIPTS:
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
        _maybe_await(test_instance.before_each())
        _maybe_await(test_instance.callv(method_name, []))
        _maybe_await(test_instance.after_each())
        if test_instance._has_failures():
            _total_failures += test_instance._get_failures().size()
        test_instance._finish_test()
    remove_child(test_instance)
    test_instance.queue_free()

func _maybe_await(result) -> void:
    if result is GDScriptFunctionState:
        await result
