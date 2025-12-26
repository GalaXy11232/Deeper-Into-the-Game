class_name Sample
extends Area2D

@onready var turn_into_specimen_timer: Timer = $turn_into_specimen
@onready var specimen_progress: ProgressBar = $"Specimen Progress"
@onready var game_zone: Node2D = $".."

const SPECIMEN_PATH = preload("res://Other/specimen.tscn")
const BASKET_SCORE := 10
const _PENALTY_2_SAMPLES_IN_OZONE := -10
const SPECIMEN_TRANSFORM_TIMESPAN := 3.0 # seconds

var pickupable := true

func _ready() -> void:
	turn_into_specimen_timer.wait_time = SPECIMEN_TRANSFORM_TIMESPAN
	turn_into_specimen_timer.one_shot = false
	
	specimen_progress.max_value = 100
	specimen_progress.value = 0
	specimen_progress.hide()

func _physics_process(_delta: float) -> void:
	if not turn_into_specimen_timer.is_stopped():
		var lt := SPECIMEN_TRANSFORM_TIMESPAN - turn_into_specimen_timer.time_left
		var rt := SPECIMEN_TRANSFORM_TIMESPAN
		var rb := specimen_progress.max_value
		_change_specimen_progress_value.rpc(lt * rb / rt) # Regula de 3 simpla type shi

@rpc('any_peer', 'call_local')
func _change_specimen_progress_value(value: float) -> void:
	specimen_progress.visible = true
	specimen_progress.value = value

func _on_body_entered(body: Node2D) -> void:
	if body is TestPlayer and body.has_node("InventoryNode") and pickupable:
		var inventory_node: Node = body.get_node("InventoryNode")
		
		# Check if inventory is full
		if inventory_node.inventory.size() < inventory_node.MAX_INVENTORY_SIZE:
			var sample_clone = self.duplicate()
			sample_clone.set_meta('team', body.team)
			
			body.get_node("InventoryNode").pickup_sample(sample_clone)
			turn_into_specimen_timer.stop()
			queue_free.call_deferred()

func _on_turn_into_specimen() -> void:
	print("turned %s into specimen" % self.name)
	specimen_progress.hide()
	_summon_specimen.rpc()
	_remove_self.rpc()

@rpc('call_local')
func _summon_specimen() -> void:
	var specimen = SPECIMEN_PATH.instantiate()
	specimen.global_position = global_position
	game_zone.add_child(specimen)


func check_for_overlapping_areas(game_ui_node: CanvasLayer):
	var areas_array = get_overlapping_areas()
	
	for area in areas_array:
		var area_name: String = area.name.to_lower()
		if not ('red' in area_name or 'blue' in area_name): continue
		
		var team = get_meta('team')
		var area_team := 'red' if 'red' in area_name else 'blue'
		var area_type := 'basket' if 'basket' in area_name else 'ozone'
		
		if area_type == 'basket':
			game_ui_node.modify_team_score.rpc(team, BASKET_SCORE if area_team == team else -BASKET_SCORE)
			_remove_self.rpc()
		
		elif area_type == 'ozone' and area_team == team:
			var other_samples_in_area = area.get_overlapping_areas().filter( func(entry): return entry is Sample and entry.pickupable )
			if other_samples_in_area.size() > 1: # If any sample other than the current one
				game_ui_node.modify_team_score.rpc(team, Funcs.force_negative(_PENALTY_2_SAMPLES_IN_OZONE))
				
			turn_into_specimen_timer.start()


func change_pickupability(value = !pickupable) -> void: 
	pickupable = value

@rpc('any_peer', 'call_local')
func _remove_self() -> void:
	queue_free.call_deferred()
