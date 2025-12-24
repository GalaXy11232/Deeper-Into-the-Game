extends CanvasLayer

@onready var game: Game = $".."
@onready var game_zone: Node2D = %GameZone

@onready var timer_label: Label = $TimerLabel
@onready var game_timer: Timer = $GameTimer

const MATCH_DURATION := 1#120 # seconds
const PREGAME_TIME := 1 # seconds

# ['starting', 'running', 'ended']
var game_state: String = ''

func _ready() -> void:
	game_timer.wait_time = MATCH_DURATION
	game_timer.one_shot = true

func _process(_delta: float) -> void: 
	if game_state != '':
		update_game_timer()

func update_game_timer() -> void:
	if game_state == 'starting':
		timer_label.text = "Starting in %d" % (int(game_timer.time_left) + 1)
	elif game_state == 'running':
		timer_label.text = "%02d:%02d" % Funcs.format_time_left(game_timer)

@rpc('call_local')
func _initiate_game_start() -> void:
	game_state = 'starting'
	game_timer.start(PREGAME_TIME)
	
	await game_timer.timeout # Pretty bad to await in the same function for 3 seconds but oh well
	
	game_state = 'running'
	game_timer.start(MATCH_DURATION)


func timer_label_blink(iterations: int, wait_time: float = 0.8) -> void:
	await get_tree().create_timer(wait_time / 2).timeout
	
	for _i in range(iterations):
		timer_label.hide()
		await get_tree().create_timer(wait_time / 1.5).timeout
		timer_label.show()
		await get_tree().create_timer(wait_time).timeout

func _on_game_timer_timeout() -> void:
	if game_state != 'running': return
	
	timer_label_blink(3)
	game_zone.get_node_or_null(str(multiplayer.get_unique_id())).change_immobility(true)
