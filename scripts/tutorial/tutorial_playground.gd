extends Node3D

@onready var _orchestrator: TutorialOrchestrator = %TutorialOrchestrator

func _ready() -> void:
	if _orchestrator:
		_orchestrator.start()
