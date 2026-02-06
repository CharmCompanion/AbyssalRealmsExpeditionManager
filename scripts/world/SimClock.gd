extends Node
class_name SimClock

signal day_advanced(day: int)

@export var seconds_per_day: float = 30.0

var day: int = 0
var _accum: float = 0.0

func _ready() -> void:
	set_process(true)

func set_day(new_day: int) -> void:
	day = maxi(0, int(new_day))

func _process(delta: float) -> void:
	_accum += maxf(0.0, delta)
	var step := maxf(0.1, seconds_per_day)
	while _accum >= step:
		_accum -= step
		day += 1
		day_advanced.emit(day)
