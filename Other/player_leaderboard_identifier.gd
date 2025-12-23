class_name PlayerLeaderboardIdentifier
extends HBoxContainer

@onready var username_label: Label = $NameContainer/Name
@onready var team_label: Label = $TeamContainer/Team

func _enter_tree() -> void:
	set_multiplayer_authority(1)

func setup_identifier(username: String, team: String) -> void:
	name = username
	username_label.text = username
	team_label.text = team.capitalize()
	
	team_label.add_theme_color_override('font_color', Color.RED if team == 'red' else Color.BLUE)
