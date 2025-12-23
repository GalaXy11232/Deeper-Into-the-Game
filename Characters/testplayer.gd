class_name TestPlayer
extends CharacterBody2D

@export var SPEED = 300
@export var SPRINTING_SPEED = 500

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority():
		return
		
	var direction := Input.get_vector('left', 'right', 'up', 'down')
	
	if Input.is_action_pressed('sprint'):
		velocity = direction * SPRINTING_SPEED
	else:
		velocity = direction * SPEED
	
	move_and_slide()
