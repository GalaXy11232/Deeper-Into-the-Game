extends Node

func format_time_left(timer: Timer) -> Array:
	var left := timer.time_left
	var minutes_left: int = int(int(ceil(left)) / 60.0)
	var seconds_left: int = int(ceil(left)) % 60
	
	return [minutes_left, seconds_left]

func label_blink_interval(timer_label: Label, iterations: int, wait_time: float = 0.8) -> void:
	await get_tree().create_timer(wait_time / 2).timeout
	
	for _i in range(iterations):
		timer_label.hide()
		await get_tree().create_timer(wait_time / 1.5).timeout
		timer_label.show()
		await get_tree().create_timer(wait_time).timeout
