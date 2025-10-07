extends Node

const DEFAULT_COMBO_CAP := 5

signal score_changed(total_score: int, delta: int)
signal combo_changed(combo_count: int, multiplier: float)
signal lives_changed(lives: int)
signal wave_changed(wave_index: int)

static var _instance: Node

var _combo_curve: Curve
var _combo_curve_cap: int = DEFAULT_COMBO_CAP
var _wave_schedule: Array[int] = []
var _starting_lives: int = 3

var _score: int = 0
var _combo: int = 0
var _combo_peak: int = 0
var _lives: int = 3
var _wave_index: int = 0
var _orders_into_wave: int = 0
var _failure_streak: int = 0

func _ready() -> void:
    _instance = self
    if _combo_curve == null:
        _combo_curve = _make_default_curve()
    _combo_curve.bake()

static func get_instance() -> Node:
    return _instance

func configure(options: Dictionary) -> void:
    if options.has("starting_lives"):
        _starting_lives = max(0, int(options["starting_lives"]))
    if options.has("combo_curve") and options["combo_curve"] is Curve:
        _combo_curve = options["combo_curve"]
        _combo_curve.bake()
    elif options.has("combo_curve_path"):
        var loaded_curve := load(String(options["combo_curve_path"]))
        if loaded_curve is Curve:
            _combo_curve = loaded_curve
            _combo_curve.bake()
    if options.has("combo_curve_max_combo"):
        _combo_curve_cap = max(1, int(options["combo_curve_max_combo"]))
    if options.has("wave_schedule"):
        _wave_schedule = []
        for value in options["wave_schedule"]:
            _wave_schedule.append(int(value))
    elif options.has("wave_schedule_path"):
        var loaded := load(String(options["wave_schedule_path"]))
        if loaded is Resource and loaded.has_method("get"):
            var schedule: Variant = loaded.get("wave_lengths")
            if schedule is Array:
                _wave_schedule = []
                for entry in schedule:
                    _wave_schedule.append(int(entry))
    if options.has("score_reset" ) and bool(options["score_reset"]):
        reset_state()

func reset_state() -> void:
    _score = 0
    _combo = 0
    _combo_peak = 0
    _lives = _starting_lives
    _wave_index = 0
    _orders_into_wave = 0
    _failure_streak = 0

func apply_success(base_points: int, normalized_remaining: float, metadata: Dictionary = {}) -> Dictionary:
    var clamped_remaining := clampf(normalized_remaining, 0.0, 1.0)
    _combo += 1
    if _combo > _combo_peak:
        _combo_peak = _combo
    var multiplier := _get_combo_multiplier(_combo)
    var scaled_points := int(round(base_points * multiplier))
    var time_bonus := int(round(base_points * clamped_remaining * 0.5))
    var delta: int = max(scaled_points + time_bonus, 0)
    _score += delta
    _orders_into_wave += 1
    _failure_streak = 0

    var result_wave_index: int = int(metadata.get("wave_index", _wave_index))
    if _should_advance_wave():
        _wave_index += 1
        _orders_into_wave = 0
        result_wave_index = _wave_index
        emit_signal("wave_changed", _wave_index)

    emit_signal("score_changed", _score, delta)
    emit_signal("combo_changed", _combo, multiplier)

    return {
        "score_delta": delta,
        "total_score": _score,
        "combo": _combo,
        "combo_multiplier": multiplier,
        "lives": _lives,
        "wave_index": result_wave_index,
        "combo_reset": false,
        "combo_peak": _combo_peak,
    }

func apply_failure(reason: StringName, metadata: Dictionary = {}) -> Dictionary:
    var combo_was_active := _combo > 0
    var previous_combo := _combo
    _combo = 0
    if _lives > 0:
        _lives -= 1
    _failure_streak += 1
    var multiplier := _get_combo_multiplier(_combo)
    emit_signal("combo_changed", _combo, multiplier)
    emit_signal("lives_changed", _lives)

    return {
        "score_delta": 0,
        "total_score": _score,
        "combo": _combo,
        "combo_multiplier": multiplier,
        "lives": _lives,
        "wave_index": metadata.get("wave_index", _wave_index),
        "combo_reset": combo_was_active,
        "failure_reason": reason,
        "combo_snapshot": previous_combo,
        "failure_streak": _failure_streak,
        "combo_peak": _combo_peak,
    }

func get_score() -> int:
    return _score

func get_combo() -> int:
    return _combo

func get_combo_peak() -> int:
    return _combo_peak

func get_lives() -> int:
    return _lives

func get_wave_index() -> int:
    return _wave_index

func get_failure_streak() -> int:
    return _failure_streak

func _get_combo_multiplier(combo: int) -> float:
    if combo <= 0:
        return 1.0
    var cap := float(maxi(1, _combo_curve_cap))
    var normalized := clampf(float(combo - 1) / cap, 0.0, 1.0)
    if _combo_curve:
        return _combo_curve.sample(normalized)
    return 1.0 + normalized

func _should_advance_wave() -> bool:
    if _wave_schedule.is_empty():
        return false
    var index: int = clampi(_wave_index, 0, _wave_schedule.size() - 1)
    var required := int(_wave_schedule[index])
    return required > 0 and _orders_into_wave >= required

func _make_default_curve() -> Curve:
    var curve := Curve.new()
    curve.add_point(Vector2(0.0, 1.0))
    curve.add_point(Vector2(1.0, 2.0))
    return curve
