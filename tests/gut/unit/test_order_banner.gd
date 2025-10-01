extends "res://tests/gut/gut_stub.gd"

const LocalizationService = preload("res://autoload/localization_service.gd")
const OrderBannerScene = preload("res://ui/components/OrderBanner.tscn")
const PatienceMeterScene = preload("res://ui/components/PatienceMeter.tscn")
const PatienceMeterScript = preload("res://scripts/ui/patience_meter.gd")
const OrderRequestDto = preload("res://scripts/dto/order_request_dto.gd")

var _localization

func before_each() -> void:
    _localization = LocalizationService.new()
    add_child_autofree(_localization)
    wait_frames(1)

func test_order_banner_uses_localized_strings() -> void:
    _localization.set_locale_dictionary({
        StringName("order_salmon_nigiri"): "Salmon Nigiri",
        StringName("tutorial_hint_default"): "Serve quickly to keep customers happy!"
    })
    var banner = OrderBannerScene.instantiate()
    add_child_autofree(banner)
    wait_frames(1)

    var order := OrderRequestDto.new()
    order.order_id = StringName("order_banner")
    order.seafood_name = "order_salmon_nigiri"
    order.tutorial_hint_key = StringName("tutorial_hint_default")

    banner.show_order(order)

    var item_label: Label = banner.get_node("Panel/HBoxContainer/VBoxContainer/ItemLabel")
    var hint_label: RichTextLabel = banner.get_node("Panel/HBoxContainer/VBoxContainer/HintLabel")

    assert_eq(item_label.text, "Salmon Nigiri", "Banner should localize menu item name")
    assert_eq(hint_label.text, "Serve quickly to keep customers happy!", "Banner should localize tutorial hint")
    assert_true(banner.visible, "Banner shows when order active")

    banner.clear_order()
    assert_false(banner.visible, "Banner hides when cleared")

func test_patience_meter_stage_colors() -> void:
    var meter = PatienceMeterScene.instantiate()
    add_child_autofree(meter)
    wait_frames(1)

    meter.bind_order(StringName("order_meter"), 12.0)
    meter.set_stage(PatienceMeterScript.PATIENCE_STAGE_PENDING)
    meter.update_remaining(0.8)

    var indicator: ColorRect = meter.get_node("Background/VBoxContainer/StageIndicator")
    assert_eq(indicator.color, meter.pending_color, "Pending color should apply")

    meter.set_stage(PatienceMeterScript.PATIENCE_STAGE_WARNING)
    assert_eq(indicator.color, meter.warning_color, "Warning color should apply")

    meter.set_stage(PatienceMeterScript.PATIENCE_STAGE_CRITICAL)
    assert_eq(indicator.color, meter.critical_color, "Critical color should apply")
    assert_true(meter.visible, "Meter remains visible until cleared")

    meter.clear()
    assert_false(meter.visible, "Meter hides when cleared")
