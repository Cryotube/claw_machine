extends Resource
class_name CabinetItemDescriptor

@export var descriptor_id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var highlight_palette: StringName = StringName("default")
@export var icon: Texture2D
@export var anchor_offset: Vector3 = Vector3.ZERO
