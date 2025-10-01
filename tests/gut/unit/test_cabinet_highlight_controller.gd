extends "res://tests/gut/gut_stub.gd"

const CABINET_CONTROLLER_SCENE_PATH := "res://scenes/session/CabinetHighlightController.tscn"
const HIGHLIGHT_MESH_SCENE_PATH := "res://scenes/session/CabinetHighlightMesh.tscn"
const ACCESSIBILITY_SERVICE_PATH := "res://autoload/accessibility_service.gd"

const SignalHub := preload("res://autoload/signal_hub.gd")
const AccessibilityService := preload("res://autoload/accessibility_service.gd")
const CabinetHighlightControllerScript := preload("res://scripts/gameplay/cabinet_highlight_controller.gd")

var _signal_hub: SignalHub
var _accessibility: AccessibilityService

func before_each() -> void:
    _signal_hub = SignalHub.new()
    add_child_autofree(_signal_hub)

    var accessibility_script: Script = load(ACCESSIBILITY_SERVICE_PATH)
    assert_true(accessibility_script != null, "Accessibility service must exist")
    _accessibility = accessibility_script.new()
    add_child_autofree(_accessibility)

    wait_frames(1)

func _instantiate_controller(pool_size: int = 2) -> CabinetHighlightControllerScript:
    var controller_scene: PackedScene = load(CABINET_CONTROLLER_SCENE_PATH)
    assert_true(controller_scene != null, "CabinetHighlightController scene should exist")
    var controller := controller_scene.instantiate() as CabinetHighlightControllerScript
    controller.pool_size = pool_size
    var pool_scene := load(HIGHLIGHT_MESH_SCENE_PATH) as PackedScene
    controller.highlight_pool_scene = pool_scene
    assert_true(controller.highlight_pool_scene != null, "Highlight pool scene must exist")
    add_child_autofree(controller)
    wait_frames(1)
    return controller

func _emit_visual(descriptor: String, icon: Texture2D = null) -> void:
    if icon == null:
        icon = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
    _signal_hub.emit_signal("order_visualized", StringName(descriptor), icon, StringName("order_%s" % descriptor))

func _emit_clear(descriptor: String) -> void:
    _signal_hub.emit_signal("order_visual_cleared", StringName(descriptor), StringName("order_%s" % descriptor))

func test_highlight_reuses_pool_instances() -> void:
    var controller: CabinetHighlightControllerScript = _instantiate_controller(1)
    var initial_pool_available: int = controller.debug_get_available_pool()
    assert_eq(initial_pool_available, 1, "Controller should populate pool")

    _emit_visual("salmon")
    wait_frames(1)

    var active_id: int = controller.debug_get_active_highlight_id()
    assert_true(active_id != 0, "Highlight instance should be active")
    assert_eq(controller.debug_get_active_descriptor(), StringName("salmon"), "Active descriptor should match event")

    _emit_clear("salmon")
    wait_frames(1)
    assert_eq(controller.debug_get_active_highlight_id(), 0, "Highlight should release after clear")

    _emit_visual("salmon")
    wait_frames(1)
    assert_eq(controller.debug_get_active_highlight_id(), active_id, "Controller should reuse pooled highlight instance")

func test_palette_switch_updates_highlight_theme() -> void:
    var controller: CabinetHighlightControllerScript = _instantiate_controller(2)
    _emit_visual("salmon")
    wait_frames(1)

    assert_eq(controller.debug_get_active_palette(), StringName("default"), "Palette should default")
    _accessibility.set_colorblind_palette(StringName("protan"))
    wait_frames(1)
    assert_eq(controller.debug_get_active_palette(), StringName("protan"), "Palette change should propagate to controller")
