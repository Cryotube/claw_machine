extends Resource
class_name WaveConfigResource

const WaveSettingsDto := preload("res://scripts/dto/wave_settings_dto.gd")
const SpawnCurveProfile := preload("res://scripts/resources/spawn_curve_profile.gd")
const ClutterProfileResource := preload("res://scripts/resources/clutter_profile_resource.gd")

@export var spawn_profile: SpawnCurveProfile
@export var patience_multipliers: PackedFloat32Array = PackedFloat32Array()
@export var patience_floor: float = 0.5
@export var clutter_profile: ClutterProfileResource
@export var base_metadata: Dictionary = {}
@export var analytics_wave_tags: PackedStringArray = PackedStringArray()

func get_settings(wave_index: int) -> WaveSettingsDto:
    var sanitized_wave: int = max(1, wave_index)
    var schedule := _build_schedule(sanitized_wave)
    var patience_multiplier: float = _get_patience_multiplier(sanitized_wave)
    var clutter_level: int = _get_clutter_level(sanitized_wave)
    var density_multiplier: float = _get_density_multiplier(sanitized_wave)
    var metadata := base_metadata.duplicate(true)
    metadata["wave_index"] = sanitized_wave
    metadata["spawn_count"] = schedule.size()
    metadata["patience_multiplier"] = patience_multiplier
    metadata["clutter_level"] = clutter_level
    metadata["density_multiplier"] = density_multiplier
    if analytics_wave_tags.size() > 0:
        var tag_index: int = min(sanitized_wave - 1, analytics_wave_tags.size() - 1)
        metadata["analytics_tag"] = StringName(analytics_wave_tags[tag_index])
    return WaveSettingsDto.new(
        sanitized_wave,
        schedule,
        patience_multiplier,
        clutter_level,
        density_multiplier,
        metadata
    )

func get_wave_count() -> int:
    var spawn_count: int = spawn_profile.get_wave_count() if spawn_profile != null else 0
    var patience_count: int = patience_multipliers.size()
    var clutter_count: int = clutter_profile.get_wave_count() if clutter_profile != null else 0
    var analytics_count: int = analytics_wave_tags.size()
    return max(max(spawn_count, patience_count), max(clutter_count, analytics_count))

func _build_schedule(wave_index: int) -> PackedFloat32Array:
    if spawn_profile == null:
        var fallback := PackedFloat32Array()
        fallback.push_back(3.0)
        return fallback
    return spawn_profile.build_schedule(wave_index)

func _get_patience_multiplier(wave_index: int) -> float:
    if patience_multipliers.is_empty():
        return 1.0
    var index: int = clampi(wave_index - 1, 0, patience_multipliers.size() - 1)
    var value: float = patience_multipliers[index]
    return max(value, patience_floor)

func _get_clutter_level(wave_index: int) -> int:
    if clutter_profile == null:
        return wave_index
    return clutter_profile.get_clutter_level(wave_index)

func _get_density_multiplier(wave_index: int) -> float:
    if clutter_profile == null:
        return 1.0
    return clutter_profile.get_density_multiplier(wave_index)
