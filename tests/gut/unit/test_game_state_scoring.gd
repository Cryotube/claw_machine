extends "res://tests/gut/gut_stub.gd"

const GameState := preload("res://autoload/game_state.gd")
const SignalHub := preload("res://autoload/signal_hub.gd")

var _signal_hub: SignalHub
var _game_state: GameState

func before_each() -> void:
    _signal_hub = SignalHub.new()
    add_child_autofree(_signal_hub)

    _game_state = GameState.new()
    add_child_autofree(_game_state)

    wait_frames(1)

    var combo_curve := Curve.new()
    combo_curve.add_point(Vector2(0.0, 1.0))
    combo_curve.add_point(Vector2(1.0, 2.0))

    _game_state.configure({
        "starting_lives": 3,
        "combo_curve": combo_curve,
        "wave_schedule": [3, 3, 3],
    })
    _game_state.reset_state()

func test_apply_success_increments_score_and_combo() -> void:
    var first := _game_state.apply_success(100, 0.5, {
        "wave_index": 0,
        "descriptor_id": StringName("salmon"),
    })

    assert_true(first.has("score_delta"), "Success result should include score delta")
    assert_true(first["score_delta"] > 0, "Score delta should be positive on success")
    assert_eq(_game_state.get_score(), first["total_score"], "Total score should update")
    assert_eq(_game_state.get_combo(), 1, "Combo should increment to 1")
    assert_true(first.has("combo_multiplier"), "Multiplier should be present")
    assert_eq(first["wave_index"], 0, "Wave index should echo input metadata")

    var second := _game_state.apply_success(100, 1.0, {
        "wave_index": 0,
        "descriptor_id": StringName("salmon"),
    })

    assert_true(second["score_delta"] > first["score_delta"], "Second combo should grant higher score delta")
    assert_eq(_game_state.get_combo(), 2, "Combo should increment sequentially")
    assert_true(second["combo_multiplier"] > first["combo_multiplier"], "Multiplier should grow with combo streak")

func test_apply_failure_resets_combo_and_decrements_lives() -> void:
    _game_state.apply_success(100, 0.5, {
        "wave_index": 0,
        "descriptor_id": StringName("tuna"),
    })
    var lives_before := _game_state.get_lives()

    var failure := _game_state.apply_failure(StringName("mismatch"), {
        "wave_index": 0,
        "descriptor_id": StringName("tuna"),
    })

    assert_eq(_game_state.get_combo(), 0, "Combo streak should reset after failure")
    assert_true(failure.get("combo_reset", false), "Failure payload should note combo reset")
    assert_eq(_game_state.get_lives(), lives_before - 1, "Lives should decrement on failure")
    assert_eq(failure["lives"], _game_state.get_lives(), "Result should mirror remaining lives")
