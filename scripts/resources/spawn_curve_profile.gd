extends Resource
class_name SpawnCurveProfile

@export var orders_per_wave: PackedInt32Array = PackedInt32Array()
@export var start_interval_sec: PackedFloat32Array = PackedFloat32Array()
@export var end_interval_sec: PackedFloat32Array = PackedFloat32Array()
@export var warmup_delay_sec: PackedFloat32Array = PackedFloat32Array()

func get_wave_count() -> int:
    return _max_size()

func build_schedule(wave_index: int) -> PackedFloat32Array:
    var index: int = _resolve_index(wave_index)
    var count: int = max(_get_int(orders_per_wave, index, 1), 1)
    var start_interval: float = max(_get_float(start_interval_sec, index, 3.0), 0.05)
    var end_interval: float = max(_get_float(end_interval_sec, index, start_interval), 0.05)
    var schedule := PackedFloat32Array()
    schedule.resize(count)
    if count <= 1:
        schedule[0] = start_interval
        return schedule
    var denominator: float = float(count - 1)
    for i in range(count):
        var t: float = float(i) / denominator
        schedule[i] = max(lerpf(start_interval, end_interval, t), 0.05)
    return schedule

func get_warmup_delay(wave_index: int) -> float:
    var index: int = _resolve_index(wave_index)
    return max(_get_float(warmup_delay_sec, index, 0.0), 0.0)

func _resolve_index(wave_index: int) -> int:
    var sanitized: int = max(1, wave_index) - 1
    var size: int = _max_size()
    if size <= 0:
        return 0
    return clampi(sanitized, 0, size - 1)

func _max_size() -> int:
    var size: int = orders_per_wave.size()
    size = max(size, start_interval_sec.size())
    size = max(size, end_interval_sec.size())
    size = max(size, warmup_delay_sec.size())
    return size

func _get_int(array: PackedInt32Array, index: int, fallback: int) -> int:
    if array.is_empty():
        return fallback
    var clamped: int = clampi(index, 0, array.size() - 1)
    return array[clamped]

func _get_float(array: PackedFloat32Array, index: int, fallback: float) -> float:
    if array.is_empty():
        return fallback
    var clamped: int = clampi(index, 0, array.size() - 1)
    return array[clamped]
