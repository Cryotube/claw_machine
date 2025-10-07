extends Node3D

const PracticeOrchestrator := preload("res://scripts/services/practice_orchestrator.gd")

@onready var _orchestrator: PracticeOrchestrator = %PracticeOrchestrator

func _ready() -> void:
	if _orchestrator:
		_orchestrator.start()
