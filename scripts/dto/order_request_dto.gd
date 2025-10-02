extends Resource
class_name OrderRequestDto

@export var order_id: StringName
@export var seafood_name: String
@export var icon_path: String
@export var tutorial_hint_key: StringName
@export var descriptor_id: StringName
@export var icon_texture: Texture2D
@export var highlight_palette: StringName = StringName("default")
@export var patience_duration: float = 10.0
@export var warning_threshold: float = 0.35
@export var critical_threshold: float = 0.15
@export var base_score: int = 100
@export var wave_index: int = 0
