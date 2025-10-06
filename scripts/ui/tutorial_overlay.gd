extends Control
class_name TutorialOverlay

signal dismissed

@export var auto_hide_seconds: float = 0.0

@onready var _callouts: RichTextLabel = %Callouts
@onready var _cta_button: Button = %ContinueButton
@onready var _timer: Timer = $AutoHideTimer

func _ready() -> void:
    hide()
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    if _cta_button:
        _cta_button.pressed.connect(_on_continue_pressed)
    if _timer:
        _timer.timeout.connect(_on_timer_timeout)

func show_overlay(instructions: String = "") -> void:
    if instructions.is_empty():
        instructions = _callouts.text if _callouts else ""
    elif _callouts:
        _callouts.text = instructions
    show()
    mouse_filter = Control.MOUSE_FILTER_STOP
    if auto_hide_seconds > 0.0 and _timer:
        _timer.start(auto_hide_seconds)

func dismiss_overlay() -> void:
    if not visible:
        return
    hide()
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    if _timer and _timer.is_stopped() == false:
        _timer.stop()
    dismissed.emit()

func _gui_input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventScreenTouch and event.pressed:
        dismiss_overlay()
    elif event is InputEventKey and event.is_pressed():
        dismiss_overlay()

func _on_continue_pressed() -> void:
    dismiss_overlay()

func _on_timer_timeout() -> void:
    dismiss_overlay()

