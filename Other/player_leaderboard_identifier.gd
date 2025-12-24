class_name PlayerLeaderboardIdentifier
extends HBoxContainer

@onready var username_label: Label = %Name
@onready var team_label: Label = %Team
@onready var background: ColorRect = $Background

func _enter_tree() -> void:
	set_multiplayer_authority(1)

func _ready() -> void:
	background.custom_minimum_size = Vector2(420, 60)

func setup_identifier(username: String, team: String) -> void:
	name = username
	username_label.text = username
	team_label.text = team.capitalize()
	
	team_label.add_theme_color_override('font_color', Color.RED if team.to_lower() == 'red' else Color.BLUE)
