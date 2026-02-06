extends Control

# Update these paths to match your project.
const SCENE_SAVE_SELECT := "res://scenes/ui/SaveSelect.tscn"
const SCENE_CREATE_TOWN := "res://scenes/ui/CreateTown.tscn" # renamed from CreateCharacter
const SCENE_SETTINGS := "res://scenes/ui/Settings.tscn"
const SCENE_DEV_SEED_INSPECTOR := "res://scenes/ui/DevSeedInspector.tscn"

@onready var btn_start: Button = _get_button_or_null(^"Margin/VBox/Buttons/StartBtn")
@onready var btn_settings: Button = _get_button_or_null(^"Margin/VBox/Buttons/SettingsBtn")
@onready var btn_quit: Button = _get_button_or_null(^"Margin/VBox/Buttons/QuitBtn")

func _get_button_or_null(path: NodePath) -> Button:
	var n: Node = get_node_or_null(path)
	if n == null:
		return null
	return n as Button

func _ready() -> void:
	# MainMenu.tscn currently uses StartBtn / SettingsBtn / QuitBtn.
	# Start goes to SaveSelect; SaveSelect handles picking/creating saves.
	if btn_start != null:
		btn_start.pressed.connect(_go_save_select)
	else:
		push_error("MainMenu: StartBtn not found at Margin/VBox/Buttons/StartBtn")

	if btn_settings != null:
		btn_settings.pressed.connect(_go_settings)
	else:
		push_error("MainMenu: SettingsBtn not found at Margin/VBox/Buttons/SettingsBtn")

	if btn_quit != null:
		btn_quit.pressed.connect(_quit_game)
	else:
		push_error("MainMenu: QuitBtn not found at Margin/VBox/Buttons/QuitBtn")


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo and k.keycode == KEY_F12:
		get_tree().change_scene_to_file(SCENE_DEV_SEED_INSPECTOR)

func _go_save_select() -> void:
	get_tree().change_scene_to_file(SCENE_SAVE_SELECT)

func _go_create_town() -> void:
	get_tree().change_scene_to_file(SCENE_CREATE_TOWN)

func _go_settings() -> void:
	get_tree().change_scene_to_file(SCENE_SETTINGS)

func _quit_game() -> void:
	get_tree().quit()
