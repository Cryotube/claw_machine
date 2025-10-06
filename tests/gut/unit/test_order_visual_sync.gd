extends "res://tests/gut/gut_stub.gd"

const ORDER_VISUAL_SYNC_PATH := "res://scripts/services/order_visual_sync.gd"
const ACCESSIBILITY_SERVICE_PATH := "res://autoload/accessibility_service.gd"
const ORDER_BANNER_SCENE_PATH := "res://ui/components/OrderBanner.tscn"
const OrderBanner := preload("res://scripts/ui/order_banner.gd")

const SignalHub := preload("res://autoload/signal_hub.gd")
const OrderService := preload("res://autoload/order_service.gd")
const AudioDirector := preload("res://autoload/audio_director.gd")
const OrderRequestDto := preload("res://scripts/dto/order_request_dto.gd")
const AccessibilityService := preload("res://autoload/accessibility_service.gd")
const OrderVisualSyncScript := preload("res://scripts/services/order_visual_sync.gd")

var _signal_hub: SignalHub
var _order_service: OrderService
var _audio_director: AudioDirector
var _accessibility: AccessibilityService

func before_each() -> void:
    _signal_hub = SignalHub.new()
    add_child_autofree(_signal_hub)
    _order_service = OrderService.new()
    add_child_autofree(_order_service)
    _audio_director = AudioDirector.new()
    add_child_autofree(_audio_director)

    var accessibility_script: Script = load(ACCESSIBILITY_SERVICE_PATH)
    assert_true(accessibility_script != null, "Accessibility service script should exist")
    _accessibility = accessibility_script.new()
    add_child_autofree(_accessibility)

    wait_frames(1)

func _make_icon_texture() -> Texture2D:
    var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
    img.fill(Color(1, 0, 0, 1))
    var texture := ImageTexture.create_from_image(img)
    return texture

func _make_order(order_id: String, descriptor: String) -> OrderRequestDto:
    var order := OrderRequestDto.new()
    order.order_id = StringName(order_id)
    order.seafood_name = "order_%s" % descriptor
    order.tutorial_hint_key = StringName("tutorial_hint_default")
    order.icon_texture = _make_icon_texture()
    order.icon_path = "res://ui/icons/%s.png" % descriptor
    order.descriptor_id = StringName(descriptor)
    return order

func test_visual_sync_broadcasts_descriptor_and_updates_banner() -> void:
    var sync_script: Script = load(ORDER_VISUAL_SYNC_PATH)
    assert_true(sync_script != null, "OrderVisualSync script should exist")

    var banner_scene: PackedScene = load(ORDER_BANNER_SCENE_PATH)
    assert_true(banner_scene != null, "OrderBanner scene must exist")
    var banner_node := banner_scene.instantiate()
    add_child_autofree(banner_node)
    var banner := banner_node as OrderBanner
    assert_true(banner != null, "OrderBanner scene should use OrderBanner script")
    if banner == null:
        return

    var emitted: Array = []
    _signal_hub.connect("order_visualized", func(descriptor_id: StringName, icon: Texture2D, order_id: StringName) -> void:
        emitted.append({
            "descriptor": descriptor_id,
            "icon": icon,
            "order_id": order_id,
        })
    )

    var sync_node := sync_script.new() as OrderVisualSyncScript
    sync_node.order_banner = banner
    add_child_autofree(sync_node)
    wait_frames(1)

    var order := _make_order("order_sync", "salmon")
    _order_service.request_order(order)
    wait_frames(1)

    assert_eq(emitted.size(), 1, "Visualized signal should emit once")
    assert_eq(emitted[0]["descriptor"], StringName("salmon"), "Descriptor should forward from order")
    assert_true(emitted[0]["icon"] is Texture2D, "Icon texture should flow through the signal")
    assert_eq(emitted[0]["order_id"], StringName("order_sync"), "Order id should accompany visualization signal")

    var icon_rect: TextureRect = banner.get_node("Panel/Content/Portrait/Frame/CatTexture")
    assert_true(icon_rect.texture is Texture2D, "OrderBanner should receive texture from DTO")

func test_visual_sync_emits_clear_on_completion() -> void:
    var sync_script: Script = load(ORDER_VISUAL_SYNC_PATH)
    assert_true(sync_script != null, "OrderVisualSync script should exist")

    var banner_scene: PackedScene = load(ORDER_BANNER_SCENE_PATH)
    assert_true(banner_scene != null, "OrderBanner scene must exist")
    var banner_node := banner_scene.instantiate()
    add_child_autofree(banner_node)
    var banner := banner_node as OrderBanner
    assert_true(banner != null, "OrderBanner scene should use OrderBanner script")
    if banner == null:
        return

    var cleared: Array[Dictionary] = []
    _signal_hub.connect("order_visual_cleared", func(descriptor_id: StringName, order_id: StringName) -> void:
        cleared.append({
            "descriptor": descriptor_id,
            "order_id": order_id,
        })
    )

    var sync_node := sync_script.new() as OrderVisualSyncScript
    sync_node.order_banner = banner
    add_child_autofree(sync_node)
    wait_frames(1)

    var order := _make_order("order_sync", "salmon")
    _order_service.request_order(order)
    wait_frames(1)

    _order_service.complete_order(order.order_id)
    wait_frames(1)
    assert_eq(cleared.size(), 1, "Cleared signal should emit once")
    assert_eq(cleared[0]["descriptor"], StringName("salmon"), "Descriptor should carry through cleared signal")
    assert_eq(cleared[0]["order_id"], StringName("order_sync"), "Order id should match cleared order")
    assert_false(banner.visible, "Banner should hide after order completion")

func test_visual_sync_handles_wrong_item() -> void:
    var sync_script: Script = load(ORDER_VISUAL_SYNC_PATH)
    assert_true(sync_script != null, "OrderVisualSync script should exist")

    var banner_scene: PackedScene = load(ORDER_BANNER_SCENE_PATH)
    var banner_node := banner_scene.instantiate()
    add_child_autofree(banner_node)
    var banner := banner_node as OrderBanner
    assert_true(banner != null, "OrderBanner scene should use OrderBanner script")
    if banner == null:
        return

    var mismatches: Array[Dictionary] = []
    _signal_hub.connect("order_visual_mismatch", func(descriptor_id: StringName, order_id: StringName) -> void:
        mismatches.append({
            "descriptor": descriptor_id,
            "order_id": order_id,
        })
    )

    var sync_node := sync_script.new() as OrderVisualSyncScript
    sync_node.order_banner = banner
    add_child_autofree(sync_node)
    wait_frames(1)

    var order := _make_order("order_sync", "salmon")
    _order_service.request_order(order)
    wait_frames(1)

    sync_node.notify_wrong_item(order.order_id)
    wait_frames(1)

    assert_eq(mismatches.size(), 1, "Mismatch signal should fire")
    assert_eq(mismatches[0]["descriptor"], StringName("salmon"), "Mismatch should carry descriptor")
    assert_eq(mismatches[0]["order_id"], StringName("order_sync"), "Mismatch should carry order id")

    var failure_state: bool = banner.get_meta("failure_active") if banner.has_meta("failure_active") else false
    assert_true(failure_state, "Banner should mark failure state for animation triggers")

    if _audio_director.has_method("debug_get_last_event"):
        assert_eq(_audio_director.debug_get_last_event(), StringName("order_mismatch_warning"), "Mismatch should trigger warning audio")
