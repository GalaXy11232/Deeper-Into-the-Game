class_name TestPlayer
extends CharacterBody2D

@export var SPEED = 300
@export var SPRINTING_SPEED = 500

var immobile: bool = false

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func change_immobility(value: bool = !immobile) -> void:
	immobile = value

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
