extends Node3D
class_name CustomerAvatar

@export_range(0.0, 0.3, 0.01) var bob_height: float = 0.08
@export_range(0.1, 6.0, 0.1) var bob_speed: float = 2.0

var _base_translation: Vector3
var _time_offset: float = 0.0
@onready var _visual: MeshInstance3D = $Visual

func _ready() -> void:
    _base_translation = position
    _time_offset = randf() * TAU
    set_process(true)

func _process(delta: float) -> void:
    var phase := (Time.get_ticks_msec() / 1000.0) * bob_speed + _time_offset
    position.y = _base_translation.y + sin(phase) * bob_height

func set_palette(color: Color) -> void:
    if _visual and _visual.material_override and _visual.material_override is StandardMaterial3D:
        var mat := _visual.material_override as StandardMaterial3D
        mat.albedo_color = color
        mat.emission = color.darkened(0.25)
