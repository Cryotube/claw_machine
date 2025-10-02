extends Resource
class_name ClutterProfileResource

@export var clutter_levels: PackedInt32Array = PackedInt32Array()
@export var density_multipliers: PackedFloat32Array = PackedFloat32Array()
@export var max_items_per_descriptor: PackedInt32Array = PackedInt32Array()

func get_wave_count() -> int:
    return _max_size()

func get_clutter_level(wave_index: int) -> int:
    if clutter_levels.is_empty():
        return 0
    var index: int = _resolve_index(wave_index, clutter_levels.size())
    return max(clutter_levels[index], 0)

func get_density_multiplier(wave_index: int) -> float:
    if density_multipliers.is_empty():
        return 1.0
    var index: int = _resolve_index(wave_index, density_multipliers.size())
    return max(density_multipliers[index], 0.1)

func get_items_per_descriptor(wave_index: int) -> int:
    if max_items_per_descriptor.is_empty():
        return max(get_clutter_level(wave_index), 1)
    var index: int = _resolve_index(wave_index, max_items_per_descriptor.size())
    return max(max_items_per_descriptor[index], 1)

func _max_size() -> int:
    var size: int = clutter_levels.size()
    size = max(size, density_multipliers.size())
    size = max(size, max_items_per_descriptor.size())
    return size

func _resolve_index(wave_index: int, size_override: int = 0) -> int:
    var sanitized: int = max(1, wave_index) - 1
    var size: int = size_override if size_override > 0 else _max_size()
    if size <= 0:
        return 0
    return clampi(sanitized, 0, size - 1)
