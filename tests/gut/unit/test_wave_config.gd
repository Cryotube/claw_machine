extends "res://tests/gut/gut_stub.gd"

const WAVE_CONFIG_PATH := "res://resources/data/wave_config.tres"

func _load_wave_config() -> Resource:
    return load(WAVE_CONFIG_PATH) as Resource

func _to_float32_array(value: Variant) -> PackedFloat32Array:
    if value is PackedFloat32Array:
        return value
    if value is Array:
        var floats: PackedFloat32Array = PackedFloat32Array()
        floats.resize(value.size())
        for i in value.size():
            floats[i] = float(value[i])
        return floats
    return PackedFloat32Array()

func test_wave_config_resource_exists() -> void:
    assert_true(ResourceLoader.exists(WAVE_CONFIG_PATH), "Wave config resource should be committed for designers")

func test_wave_config_returns_wave_settings() -> void:
    var resource: Resource = _load_wave_config()
    assert_true(resource != null, "Wave config resource should load")
    if resource == null:
        return
    assert_true(resource.has_method("get_settings"), "Wave config must expose get_settings")
    var settings: Object = resource.call("get_settings", 1)
    assert_true(settings != null, "Wave settings should return a data object")

func test_wave_settings_escalate_difficulty_by_wave() -> void:
    var resource: Resource = _load_wave_config()
    assert_true(resource != null, "Wave config resource should load")
    if resource == null:
        return
    var first_wave: Object = resource.call("get_settings", 1)
    var later_wave: Object = resource.call("get_settings", 3)
    assert_true(first_wave != null and later_wave != null, "Should return settings for requested waves")
    if first_wave == null or later_wave == null:
        return
    var first_schedule: PackedFloat32Array = _to_float32_array(first_wave.get("spawn_schedule"))
    var later_schedule: PackedFloat32Array = _to_float32_array(later_wave.get("spawn_schedule"))
    assert_true(first_schedule.size() > 0, "Wave schedule should not be empty for early waves")
    assert_true(later_schedule.size() >= first_schedule.size(), "Later waves should not have fewer orders scheduled")
    if later_schedule.size() > 0 and first_schedule.size() > 0:
        var first_interval: float = first_schedule[0]
        var later_last: float = later_schedule[later_schedule.size() - 1]
        assert_true(later_last < first_interval, "Later waves should accelerate spawn cadence")
    var first_multiplier: float = float(first_wave.get("patience_multiplier"))
    var later_multiplier: float = float(later_wave.get("patience_multiplier"))
    assert_true(later_multiplier < first_multiplier, "Later waves should reduce patience multipliers")
    var first_clutter: int = int(first_wave.get("cabinet_clutter_level"))
    var later_clutter: int = int(later_wave.get("cabinet_clutter_level"))
    assert_true(later_clutter > first_clutter, "Later waves should increase cabinet clutter")
