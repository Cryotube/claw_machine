extends Resource
class_name OrderDefinition

@export var order_id: StringName
@export var descriptor_id: StringName
@export var localization_key: StringName
@export var tutorial_hint_key: StringName
@export var icon: Texture2D
@export var icon_path: String
@export var highlight_palette: StringName = StringName("default")
@export var patience_duration: float = 12.0
@export var warning_threshold: float = 0.35
@export var critical_threshold: float = 0.15
