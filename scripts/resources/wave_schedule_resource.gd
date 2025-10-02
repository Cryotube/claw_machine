extends Resource
class_name WaveScheduleResource

@export var starting_lives: int = 3
@export var wave_lengths: Array[int] = [4, 5, 6]
@export var loop_from_index: int = 0

func get_wave_lengths() -> Array[int]:
    return wave_lengths.duplicate(true)

func get_starting_lives() -> int:
    return max(starting_lives, 0)

func get_loop_from_index() -> int:
    if wave_lengths.is_empty():
        return 0
    return clampi(loop_from_index, 0, wave_lengths.size() - 1)
