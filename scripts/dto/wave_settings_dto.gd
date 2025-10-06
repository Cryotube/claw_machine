extends RefCounted
class_name WaveSettingsDto

var wave_index: int = 1
var spawn_schedule: PackedFloat32Array = PackedFloat32Array()
var warmup_delay_sec: float = 0.0
var patience_multiplier: float = 1.0
var cabinet_clutter_level: int = 0
var cabinet_density_multiplier: float = 1.0
var score_multiplier: float = 1.0
var metadata: Dictionary = {}

func _init(
    wave_index_value: int = 1,
    schedule: PackedFloat32Array = PackedFloat32Array(),
    warmup_delay: float = 0.0,
    patience_multiplier_value: float = 1.0,
    clutter_level: int = 0,
    density_multiplier: float = 1.0,
    score_multiplier_value: float = 1.0,
    metadata_value: Dictionary = {}
) -> void:
    wave_index = max(1, wave_index_value)
    spawn_schedule = _copy_schedule(schedule)
    warmup_delay_sec = max(warmup_delay, 0.0)
    patience_multiplier = max(patience_multiplier_value, 0.1)
    cabinet_clutter_level = max(0, clutter_level)
    cabinet_density_multiplier = max(density_multiplier, 0.0)
    score_multiplier = max(score_multiplier_value, 0.0)
    metadata = metadata_value.duplicate(true)

func duplicate() -> WaveSettingsDto:
    return WaveSettingsDto.new(
        wave_index,
        spawn_schedule,
        warmup_delay_sec,
        patience_multiplier,
        cabinet_clutter_level,
        cabinet_density_multiplier,
        score_multiplier,
        metadata
    )

func with_metadata(extra: Dictionary) -> WaveSettingsDto:
    var combined: Dictionary = metadata.duplicate(true)
    combined.merge(extra, true)
    return WaveSettingsDto.new(
        wave_index,
        spawn_schedule,
        warmup_delay_sec,
        patience_multiplier,
        cabinet_clutter_level,
        cabinet_density_multiplier,
        score_multiplier,
        combined
    )

func _copy_schedule(schedule: PackedFloat32Array) -> PackedFloat32Array:
    var copy := PackedFloat32Array()
    var length: int = schedule.size()
    copy.resize(length)
    for index in length:
        copy[index] = schedule[index]
    return copy
