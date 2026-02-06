extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect back button
	$PageContainer/LeftPage/LeftPageContent/BackButton.pressed.connect(_on_back_pressed)
	
	# Load and display stats if available
	load_stats()

func load_stats():
	# TODO: Load actual save data and populate stats
	# This is a placeholder implementation
	pass

func _on_back_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
