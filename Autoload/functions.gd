extends Node

func format_time_left(timer: Timer) -> Array:
	var left := timer.time_left
	var minutes_left: int = int(int(ceil(left)) / 60.0)
	var seconds_left: int = int(ceil(left)) % 60
	
	return [minutes_left, seconds_left]
