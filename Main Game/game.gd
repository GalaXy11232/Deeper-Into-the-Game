class_name Game
extends Node

@onready var game_zone: Node2D = %GameZone
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var menu_ui: CanvasLayer = $MenuUI
@onready var host_ui: CanvasLayer = $HostUI
@onready var lobby_ui: CanvasLayer = $LobbyUI
@onready var game_ui: CanvasLayer = $GameUI

const SERVER_PORT: int = 14689
const MAX_PLAYERS: int = 2#4

const TESTPLAYER_PATH = preload("res://Characters/testplayer.tscn")

var peer = ENetMultiplayerPeer.new()
var players: Array[Dictionary] = [] ## Players will be stored as dicts containing their data

func _ready() -> void:
	$GameZone/Camera2D.offset = Vector2.ZERO
	game_zone.hide()
	menu_ui.show()
	host_ui.hide()
	lobby_ui.hide()
	game_ui.hide()
	
	peer = ENetMultiplayerPeer.new()
	multiplayer_spawner.spawn_function = add_player
	
	#multiplayer.peer_connected.connect(_peer_connected) # related to leaderboards, this function caused problems
	multiplayer.peer_disconnected.connect(_peer_disconnected)


func _on_host_pressed() -> void:
	## Also check if host's name is valid
	var host_name = %"Username Entry".text.strip_edges()
	if len(host_name) == 0:
		rpc_id(1, '_join_request_failed', 'You must enter a valid name!')
		return
	
	peer = ENetMultiplayerPeer.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	
	multiplayer.multiplayer_peer = peer
	
	multiplayer_spawner.spawn({
		'pid': multiplayer.get_unique_id(),
		'player_name': host_name
	})
	
	## Also add host to players list
	players.append({
		'pid': multiplayer.get_unique_id(),
		'player_name': host_name
	})
	
	$LobbyUI/Control/Players.text = "Players: %d \nWaiting for players..." % players.size()
	
	game_zone.show()
	menu_ui.hide()
	lobby_ui.show()
	host_ui.show() # Also show hostUI only for the server host


func _on_join_pressed() -> void:
	var client_name = %"Username Entry".text
	client_name = client_name.strip_edges() # Remove unnecessary spaces
	
	## All checks passed, client can be created
	peer = ENetMultiplayerPeer.new()
	peer.create_client(%"Host Server IP".text, SERVER_PORT)
	
	multiplayer.multiplayer_peer = peer
	await multiplayer.connected_to_server
	
	#print(multiplayer.multiplayer_peer, ' ', multiplayer.has_multiplayer_peer())
	
	rpc_id(1, 'handle_join_request', client_name)


@rpc('any_peer', 'call_local')
func handle_join_request(player_name) -> void:
	if !is_multiplayer_authority(): return
	var pid := multiplayer.get_remote_sender_id()
	
	## Check if name is valid
	if len(player_name) == 0:
		_join_request_failed.rpc('You must enter a valid name!')
		multiplayer.peer_disconnected.emit(pid)
		return
	
	## Check if name already exists
	if not is_name_available(player_name):
		_join_request_failed.rpc('Name already exists!')
		multiplayer.peer_disconnected.emit(pid)
		return
	
	## Check if max players
	if players.size() == MAX_PLAYERS:
		_join_request_failed.rpc('Maximum number of players reached!')
		multiplayer.peer_disconnected.emit(pid)
		return
	
	multiplayer_spawner.spawn({
		'pid': pid,
		'player_name': player_name
	})
	
	players.append({
		'pid': pid,
		'player_name': player_name
	})
	
	if !multiplayer.is_server(): lobby_ui._update_labels_as_host.rpc_id(1)
	else: lobby_ui._update_labels_as_host()
	
	_join_request_successful.rpc_id(pid)
	_peer_connected(pid)

@rpc('call_local')
func _update_labels(players_size) -> void:
	#var alliance_members: int = len(%"Red Alliance Container".get_children() + %"Blue Alliance Container".get_children())
	$LobbyUI/Control/Players.text = "Players: %d" % players_size
	$LobbyUI/Control/Players.text += "\nWaiting for players..." if players_size != MAX_PLAYERS else "\nReady to start!"

@rpc('call_local')
func _join_request_failed(message) -> void:
	%ErrorLabel.text = str(message)
	%ErrorLabel.show()

@rpc('call_local')
func _join_request_successful() -> void:
	menu_ui.hide()
	lobby_ui.show()
	game_zone.show()

func _peer_connected(pid: int) -> void:
	if !multiplayer.is_server(): return
	
	## Sync leaderboards
	var nodes_to_sync: Dictionary = {}
	for child in (%"Red Alliance Container".get_children() + %"Blue Alliance Container".get_children()):
		nodes_to_sync[child.get_node("%Name").text] = child.get_node("%Team").text
	
	#rpc_id(pid, 'sync_leaderboards', nodes_to_sync)
	sync_leaderboards.rpc_id(pid, nodes_to_sync)

@rpc('call_local')
func sync_leaderboards(data, mode = 'add'):
	if mode == 'add': 
		for player_name in data.keys():
			var team = data[player_name]
			lobby_ui._instantiate_leaderboard_entry(player_name, team)
			
	elif mode == 'remove':
		lobby_ui._remove_leaderboard_entry.rpc(data.get('player_name'))


func _peer_disconnected(pid: int) -> void:
	if multiplayer.multiplayer_peer and !is_multiplayer_authority(): return
	
	var player = game_zone.get_node_or_null(str(pid))
	if player:
		var player_identifier: Dictionary = {
			'pid': pid,
			'player_name': player.get_node_or_null('username').text
		}
		
		players.erase(player_identifier)
		player.queue_free()
		
		if !multiplayer.is_server(): lobby_ui._update_labels_as_host.rpc_id(1)
		else: lobby_ui._update_labels_as_host()
		
		#_update_labels.rpc(players.size()) # Also update labels after leaving
		sync_leaderboards.rpc(player_identifier, 'remove')
		
		if !multiplayer.is_server(): lobby_ui._update_labels_as_host.rpc_id(1)
		else: lobby_ui._update_labels_as_host()


func is_name_available(player_name: String) -> bool:
	for child in game_zone.get_children():
		if child is CharacterBody2D and child.get_node('username').text == player_name.strip_edges():
			return false
	return true 


func add_player(data: Dictionary):
	var player = TESTPLAYER_PATH.instantiate()
	var pid = data.get('pid')
	var player_name = data.get('player_name')
	
	player.name = str(pid)
	player.get_node('username').text = player_name.strip_edges()
	
	player.global_position = Vector2(randi_range(100, 900), randi_range(100, 700))
	
	return player
