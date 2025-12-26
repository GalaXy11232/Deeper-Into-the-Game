class_name TestPlayer
extends CharacterBody2D

@onready var inventory_node: InventoryNode = $InventoryNode

@export var SPEED = 300
@export var SPRINTING_SPEED = 500


var immobile: bool = false
var team: String
var direction_remnant: Vector2

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _input(ev: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_F:
		#print(get_meta('team', 'null'))
		print(direction_remnant)

func _physics_process(_delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and !is_multiplayer_authority():
		return
	
	if not immobile:
		var direction := Input.get_vector('left', 'right', 'up', 'down')
		
		if Input.is_action_pressed('sprint'):
			velocity = direction * SPRINTING_SPEED
		else:
			velocity = direction * SPEED
	
		move_and_slide()
		if direction:
			direction_remnant = direction
		
		# had an idea for pushable samples, didnt quite work out
		#for i in get_slide_collision_count():
			#var collision := get_slide_collision(i)
			#if collision.get_collider() is Sample:
				#collision.get_collider().apply_central_impulse(-collision.get_normal() * push_force)
				#
				#velocity = collision.get_normal() * 4
				#move_and_collide(velocity)

func change_immobility(value: bool = !immobile) -> void:
	immobile = value
