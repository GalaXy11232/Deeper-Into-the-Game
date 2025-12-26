extends CanvasLayer

@onready var game: Game = $".."
@onready var game_zone: Node2D = %GameZone
@onready var game_camera: Camera2D = $"../GameZone/Camera2D"
@onready var red_alliance_container: VBoxContainer = %"Red Alliance Container"
@onready var blue_alliance_container: VBoxContainer = %"Blue Alliance Container"

@onready var red_spawns: Node = $"../GameZone/Spawnpoints/Red"
@onready var blue_spawns: Node = $"../GameZone/Spawnpoints/Blue"

@onready var menu_ui: CanvasLayer = $"../MenuUI"
@onready var lobby_ui: CanvasLayer = $"../LobbyUI"
@onready var game_ui: CanvasLayer = $"../GameUI"


func _on_start_game_pressed() -> void:
	if len(red_alliance_container.get_children() + blue_alliance_container.get_children()) == game.MAX_PLAYERS:
		_move_all_to_arena.rpc()
	
@rpc('call_local')
func _move_all_to_arena() -> void:
	$"Control/Start Game".hide() # Hide button
	
	menu_ui.hide()
	lobby_ui.hide()
	game_camera.global_position = Vector2.RIGHT * 1920 * 2
	
	var pid := multiplayer.get_unique_id()
	var player = game_zone.get_node_or_null(str(pid))
	if !player: return
	
	var player_name = player.get_node('username').text
	
	var index := 0
	# Check first in the red container for current player
	if red_alliance_container.get_children().any( func(entry): return entry.get_node('%Name').text == player_name ):
		for entry in red_alliance_container.get_children():
			if entry is PlayerLeaderboardIdentifier and entry.get_node('%Name').text == player_name:
				player.global_position = red_spawns.get_child(index).global_position
				#player.set_meta('team', 'red')
				player.team = 'red'
				break
			index += 1
	
	index = 0
	if blue_alliance_container.get_children().any( func(entry): return entry.get_node('%Name').text == player_name ):
		for entry in blue_alliance_container.get_children():
			if entry is PlayerLeaderboardIdentifier and entry.get_node('%Name').text == player_name:
				player.global_position = blue_spawns.get_child(index).global_position
				#player.set_meta('team', 'blue')
				player.team = 'blue'
				break
			index += 1
	
	game_ui.show()
	
	if !multiplayer.is_server():
		_request_host_to_start_game.rpc_id(1)
	
@rpc('any_peer')
func _request_host_to_start_game(): 
	game_ui._initiate_game_start.rpc()
