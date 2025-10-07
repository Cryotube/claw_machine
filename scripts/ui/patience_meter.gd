extends Control
class_name PatienceMeter

const PATIENCE_STAGE_PENDING := 0
const PATIENCE_STAGE_WARNING := 1
const PATIENCE_STAGE_CRITICAL := 2

const STAGE_DATA: Array = [
	{"color": Color(0.329412, 0.67451, 0.568627, 1.0), "label": "Calm"},
	{"color": Color(0.870588, 0.576471, 0.105882, 1.0), "label": "Hurry"},
	{"color": Color(0.827451, 0.258824, 0.32549, 1.0), "label": "Critical"},
]

@onready var _progress: ProgressBar = %Progress
@onready var _stage_indicator: ColorRect = %StageIndicator
@onready var _stage_label: Label = %StageLabel

var _order_id: StringName = StringName()
var _patience_duration: float = 0.0

func _ready() -> void:
	hide()

func bind_order(order_id: StringName, patience_duration: float, warning_threshold: float = 0.35, critical_threshold: float = 0.15) -> void:
	_order_id = order_id
	_patience_duration = patience_duration
	_progress.value = 1.0
	_progress.step = 0.01
	show()

func update_remaining(normalized_remaining: float) -> void:
	_progress.value = clampf(normalized_remaining, 0.0, 1.0)

func set_stage(stage: int) -> void:
	var clamped := clampi(stage, 0, STAGE_DATA.size() - 1)
	var data: Dictionary = STAGE_DATA[clamped]
	_stage_indicator.color = _resolve_stage_color(data, _stage_indicator.color)
	if _stage_label:
		var label_variant: Variant = data.get("label", "Calm")
		_stage_label.text = String(label_variant).to_upper()

func clear() -> void:
	hide()
	_order_id = StringName()
	_patience_duration = 0.0
	_progress.value = 1.0

func update_safe_area(is_portrait: bool, padding: Vector2) -> void:
	anchor_left = 0.66 if is_portrait else 0.64
	anchor_right = 0.95
	anchor_top = 0.035
	anchor_bottom = 0.19 if is_portrait else 0.17
	offset_left = padding.x * 0.5
	offset_right = -padding.x
	offset_top = padding.y * 0.5
	offset_bottom = -padding.y * 0.2

func debug_get_order_id() -> StringName:
	return _order_id

func _resolve_stage_color(data: Dictionary, fallback: Color) -> Color:
	var value: Variant = data.get("color", fallback)
	return value if value is Color else fallback
