extends CanvasLayer

@onready var game: Game = $".."
@onready var game_zone: Node2D = %GameZone
@onready var menu_ui: CanvasLayer = $"../MenuUI"
@onready var multiplayer_spawner: MultiplayerSpawner = $"../MultiplayerSpawner"

@onready var timer_label: Label = $TimerLabel
@onready var game_timer: Timer = $GameTimer
@onready var camera: Camera2D = $"../GameZone/Camera2D"

@onready var blue_score_label: Label = $BlueScore
@onready var red_score_label: Label = $RedScore

var red_score: int = 0
var blue_score: int = 0

const MATCH_DURATION := 5#120 # seconds
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
	blue_score_label.text = str(blue_score)
	red_score_label.text = str(red_score)
	
	game_state = 'starting'
	game_timer.start(PREGAME_TIME)
	
	await game_timer.timeout # Pretty bad to await in the same function for 3 seconds but oh well
	
	game_state = 'running'
	game_timer.start(MATCH_DURATION)

func _on_game_timer_timeout() -> void:
	if game_state != 'running': return
	
	game_zone.get_node_or_null(str(multiplayer.get_unique_id())).change_immobility(true)
	await Funcs.label_blink_interval(timer_label, 0)
	await get_tree().create_timer(0.25).timeout
	
	#_handle_team_scores_on_end.rpc(1)
	_game_finished(red_score, blue_score)
	await get_tree().create_timer(0).timeout
	
	if multiplayer.has_multiplayer_peer():
		_disconnect_peer(multiplayer.get_unique_id())


func _disconnect_peer(pid: int) -> void:
	# Generates errors but theres nothing I can do
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	
	await get_tree().create_timer(0.2).timeout
	
	var player = game_zone.get_node_or_null(str(pid))
	if player: 
		player.queue_free()
	camera.global_position = Vector2.ZERO
	
	get_tree().change_scene_to_file("res://Main Game/game.tscn")

func _game_finished(_red_score: int, _blue_score: int) -> void:
	var t = $"../Label"
	if _red_score != _blue_score:
		t.text = "RED" if _red_score > _blue_score else "BLUE"
	else:
		t.text = "DRAW"


@rpc('any_peer', 'call_local')
func modify_team_score(team: String, value: int) -> void:
	team = team.to_lower()
	print(team, ' ', multiplayer.get_unique_id())
	
	if team == 'red':
		red_score += value
		red_score_label.text = str(red_score)
		
	elif team == 'blue':
		blue_score += value
		blue_score_label.text = str(blue_score)



### ==================== GAME ELEMENTS INTERACTIONS ==================== ###
func _on_red_body_entered(body: Node2D) -> void:
	var team = body.get_meta('team', '').to_lower()
	
	if team == 'red':
		modify_team_score.rpc(team, 10)

func _on_blue_body_entered(body: Node2D) -> void:
	var team = body.get_meta('team', '').to_lower()
	
	if team == 'blue':
		modify_team_score.rpc(team, 10)
