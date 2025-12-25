extends CanvasLayer

@onready var game: Game = $".."
@onready var red_team_checkbox: CheckBox = $Control/RedTeam
@onready var blue_team_checkbox: CheckBox = $Control/BlueTeam
@onready var game_zone: Node2D = %GameZone
@onready var red_alliance_container: VBoxContainer = %"Red Alliance Container"
@onready var blue_alliance_container: VBoxContainer = %"Blue Alliance Container"

const PLAYER_LEADERBOARD_IDENTIFIER_PATH = preload("res://Other/player_leaderboard_identifier.tscn")

var current_team: String = 'none'
var leaderboard_references: Dictionary = {} ## { player_name: leaderboard_node }

func _on_blue_team_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		## Check for team availability
		if blue_alliance_container.get_children().size() == int((game.MAX_PLAYERS + 1) / 2.0):
			print("Blue team is full")
			blue_team_checkbox.set_pressed_no_signal(false)
			return
		
		current_team = 'blue'
		red_team_checkbox.set_pressed_no_signal(false)
		
		modify_leaderboard.rpc(['remove'])
		modify_leaderboard.rpc(['add', 'blue'])
		
	else:
		current_team = 'none'
		modify_leaderboard.rpc(['remove'])

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		print(leaderboard_references)

func _on_red_team_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		## Check for team availability
		if red_alliance_container.get_children().size() == int((game.MAX_PLAYERS + 1) / 2.0):
			print("Red team is full")
			red_team_checkbox.set_pressed_no_signal(false)
			return
		
		current_team = 'red'
		blue_team_checkbox.set_pressed_no_signal(false)
		
		modify_leaderboard.rpc(['remove'])
		modify_leaderboard.rpc(['add', 'red'])
	else:
		current_team = 'none'
		modify_leaderboard.rpc(['remove'])

@rpc('any_peer', 'call_local')
func _instantiate_leaderboard_entry(player_name, team) -> void:
	var leaderboard_entry = PLAYER_LEADERBOARD_IDENTIFIER_PATH.instantiate()
	if team.to_lower() == 'red':
		red_alliance_container.add_child(leaderboard_entry)
	elif team.to_lower() == 'blue': 
		blue_alliance_container.add_child(leaderboard_entry)
	else: return # Unexpected error handling
	leaderboard_entry.setup_identifier(player_name, team)

	# Keep track of nodes inside the server host
	leaderboard_references.set( player_name, leaderboard_entry )

@rpc('any_peer', 'call_local')
func _remove_leaderboard_entry(player_name) -> void:
	var entry = leaderboard_references.get(player_name, null)
	
	if entry and leaderboard_references.has(player_name):
		leaderboard_references.erase(player_name)
		entry.queue_free()


@rpc('any_peer', 'call_local')
func modify_leaderboard(mode_data: Array) -> void:
	var pid = multiplayer.get_remote_sender_id()
	var player = game_zone.get_node_or_null(str( pid ))
	if !player: return
	
	var mode: String = mode_data[0]
	var team: String = '' if mode_data.size() == 1 else mode_data[1]
	var player_name = player.get_node('username').text
	
	if mode == 'add':
		_instantiate_leaderboard_entry(player_name, team)
	elif mode == 'remove':
		_remove_leaderboard_entry(player_name)
	
	if !multiplayer.is_server(): _update_labels_as_host.rpc_id(1)
	else: _update_labels_as_host()

@rpc('any_peer')
func _update_labels_as_host() -> void:
	game._update_labels.rpc(leaderboard_references.size())
