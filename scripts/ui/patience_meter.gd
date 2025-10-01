extends Control
class_name PatienceMeter

const PATIENCE_STAGE_PENDING := 0
const PATIENCE_STAGE_WARNING := 1
const PATIENCE_STAGE_CRITICAL := 2

@export var pending_color: Color = Color8(96, 255, 145)
@export var warning_color: Color = Color8(255, 217, 102)
@export var critical_color: Color = Color8(255, 111, 111)

@onready var _progress: TextureProgressBar = %ProgressBar
@onready var _stage_indicator: ColorRect = %StageIndicator

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
    match stage:
        PATIENCE_STAGE_PENDING:
            _stage_indicator.color = pending_color
        PATIENCE_STAGE_WARNING:
            _stage_indicator.color = warning_color
        PATIENCE_STAGE_CRITICAL:
            _stage_indicator.color = critical_color
        _:
            _stage_indicator.color = pending_color

func clear() -> void:
    hide()
    _order_id = StringName()
    _patience_duration = 0.0
    _progress.value = 1.0

func update_safe_area(is_portrait: bool, padding: Vector2) -> void:
    anchor_left = 0.65 if is_portrait else 0.6
    anchor_right = 0.95
    anchor_top = 0.05
    anchor_bottom = 0.2 if is_portrait else 0.18
    offset_left = padding.x
    offset_right = -padding.x
    offset_top = padding.y
    offset_bottom = 0.0

func debug_get_order_id() -> StringName:
    return _order_id
