class_name InventoryNode
extends Node2D

@onready var vfx: Control = $VFX
@onready var item_number_label: Label = %ItemNumber
@onready var game_zone = $"../.."

@export var player: CharacterBody2D
@export var MAX_INVENTORY_SIZE := 5
var inventory: Array = []

const VFX_OFFSET := Vector2(0, -100)

func pickup_sample(sample_node) -> void:
	#if !is_multiplayer_authority(): return
	inventory.append(sample_node)

func _physics_process(_delta: float) -> void:
	if player == null or !is_multiplayer_authority(): 
		return
	update_vfx.rpc()
	
	#var arr = []
	#for c in game_zone.get_children():
		#if c is TestPlayer: arr.append(c)
	#
	#for ch in arr:
		#print(ch, ' ', get_meta('team', 'null'), ' ', ch.team)


func _input(ev: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_E:
		drop_top_sample.rpc( player.direction_remnant ) # pass direction_remnant as parameter to make it equal for all players


@rpc('call_local')
func update_vfx() -> void:
	vfx.visible = true if inventory.size() > 0 else false
	vfx.global_position = player.global_position + VFX_OFFSET
	item_number_label.text = "%d / %d" % [inventory.size(), MAX_INVENTORY_SIZE]

@rpc('call_local')
func drop_top_sample(player_direction_remnant: Vector2) -> void:
	var top_sample = inventory.pop_at(0)
	if top_sample == null: return
	
	const TWEEN_TIME := 0.5
	top_sample.global_position = player.global_position# + (player.direction_remnant * 50)
	top_sample.pickupable = false # Avoid emitting body_entered signal on instantiating
	top_sample.modulate.a = 0
	
	game_zone.add_child(top_sample)
	
	var drop_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	var visibility_tween = create_tween().set_parallel()
	drop_tween.tween_property(top_sample, 'global_position', player.global_position + (player_direction_remnant * 50), TWEEN_TIME)
	visibility_tween.tween_property(top_sample, 'modulate:a', 1, TWEEN_TIME)

	await drop_tween.step_finished
	await get_tree().create_timer(0.1).timeout
	
	if is_instance_valid(top_sample): # If not <Freed Object>
		top_sample.pickupable = true
		
		if is_multiplayer_authority() and top_sample.has_method('check_for_overlapping_areas'):
			top_sample.check_for_overlapping_areas( player.get_parent().get_parent().game_ui )
	
