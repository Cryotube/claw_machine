extends "res://tests/gut/gut_stub.gd"

const SignalHub := preload("res://autoload/signal_hub.gd")
const FailureBanner := preload("res://scripts/ui/failure_banner.gd")

var _signal_hub: SignalHub
var _banner: FailureBanner

func before_each() -> void:
    _signal_hub = SignalHub.new()
    add_child_autofree(_signal_hub)

    _banner = FailureBanner.new()
    _banner.grace_period_sec = 0.1
    add_child_autofree(_banner)

    wait_frames(1)

func test_failure_banner_displays_reason_and_hides_after_grace_period() -> void:
    assert_false(_banner.visible, "Banner should start hidden")

    var payload := {
        "reason": StringName("timeout"),
        "combo": 0,
        "lives": 2,
        "combo_snapshot": 3,
    }

    _signal_hub.broadcast_order_failure(StringName("order_banner"), StringName("timeout"), payload)
    wait_frames(1)

    assert_true(_banner.visible, "Banner should become visible after failure")
    assert_true(_banner.debug_get_banner_text().find("timeout") != -1, "Banner text should include failure reason")

    await get_tree().create_timer(0.2).timeout
    wait_frames(1)

    assert_false(_banner.visible, "Banner should hide after grace period")

func test_failure_banner_clears_on_manual_reset() -> void:
    _signal_hub.broadcast_order_failure(StringName("order_banner"), StringName("mismatch"), {"reason": StringName("mismatch")})
    wait_frames(1)
    assert_true(_banner.visible, "Banner should show after failure")
    _banner.clear_banner()
    wait_frames(1)
    assert_false(_banner.visible, "Banner should hide after explicit clear")
