extends Control

const SCENE_MAIN_MENU := "res://scenes/ui/MainMenu.tscn"


# Tab buttons
@onready var general_tab: Button = $"ContentRoot/RootVBox/TabsRow/GeneralTab"
@onready var audio_tab: Button = $"ContentRoot/RootVBox/TabsRow/AudioTab"
@onready var video_tab: Button = $"ContentRoot/RootVBox/TabsRow/VideoTab"
@onready var controls_tab: Button = $"ContentRoot/RootVBox/TabsRow/ControlsTab"

# Pages
@onready var general_page: Control = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/GeneralPage"
@onready var audio_page: Control = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/AudioPage"
@onready var video_page: Control = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/VideoPage"
@onready var controls_page: Control = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/ControlsPage"

# General
@onready var show_tips: CheckBox = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/GeneralPage/ShowTips"
@onready var autosave: CheckBox = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/GeneralPage/AutoSave"

# Audio
@onready var master_volume: HSlider = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/AudioPage/MasterVolume"
@onready var music_volume: HSlider = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/AudioPage/MusicVolume"
@onready var sfx_volume: HSlider = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/AudioPage/SfxVolume"

# Video
@onready var display_mode: OptionButton = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/VideoPage/DisplayMode"
@onready var vsync: CheckBox = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/VideoPage/Vsync"

# Controls
@onready var mouse_sensitivity: HSlider = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/ControlsPage/MouseSensitivity"
@onready var invert_y: CheckBox = $"ContentRoot/RootVBox/PagesFrame/PagesMargin/Pages/ControlsPage/InvertY"

# Bottom buttons
@onready var back_btn: Button = $"ContentRoot/RootVBox/BottomRow/Back"
@onready var revert_btn: Button = $"ContentRoot/RootVBox/BottomRow/Revert"
@onready var apply_btn: Button = $"ContentRoot/RootVBox/BottomRow/Apply"


var _tab_group: ButtonGroup
var _tabs: Array[Button] = []
var _pages: Array[Control] = []

# Settings state
var _settings := {
	"show_tips": true,
	"autosave": true,
	"master_volume": 80,
	"music_volume": 70,
	"sfx_volume": 80,
	"display_mode": 0,
	"vsync": true,
	"mouse_sensitivity": 1.0,
	"invert_y": false,
}

func _ready() -> void:
	_tab_group = ButtonGroup.new()

	_tabs = [general_tab, audio_tab, video_tab, controls_tab]
	for b: Button in _tabs:
		b.toggle_mode = true
		b.button_group = _tab_group

	_pages = [general_page, audio_page, video_page, controls_page]

	general_tab.pressed.connect(func() -> void: _show_page(0))
	audio_tab.pressed.connect(func() -> void: _show_page(1))
	video_tab.pressed.connect(func() -> void: _show_page(2))
	controls_tab.pressed.connect(func() -> void: _show_page(3))

	back_btn.pressed.connect(_on_back_pressed)
	revert_btn.pressed.connect(_on_revert_pressed)
	apply_btn.pressed.connect(_on_apply_pressed)

	_show_page(0)

func _show_page(index: int) -> void:
	var i: int = 0
	for p: Control in _pages:
		p.visible = (i == index)
		i += 1

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)


func _on_revert_pressed() -> void:
	_load_settings_into_ui()


func _on_apply_pressed() -> void:
	_save_ui_to_settings()
	# TODO: Actually apply to game (audio, video, etc.)
	# For now, just print for debug
	print("[Settings] Applied:", _settings)
	# Optionally, persist to disk here
	# _save_settings_to_disk()

func _load_settings_into_ui() -> void:
	show_tips.button_pressed = _settings["show_tips"]
	autosave.button_pressed = _settings["autosave"]
	master_volume.value = _settings["master_volume"]
	music_volume.value = _settings["music_volume"]
	sfx_volume.value = _settings["sfx_volume"]
	display_mode.selected = _settings["display_mode"]
	vsync.button_pressed = _settings["vsync"]
	mouse_sensitivity.value = _settings["mouse_sensitivity"]
	invert_y.button_pressed = _settings["invert_y"]

func _save_ui_to_settings() -> void:
	_settings["show_tips"] = show_tips.button_pressed
	_settings["autosave"] = autosave.button_pressed
	_settings["master_volume"] = int(master_volume.value)
	_settings["music_volume"] = int(music_volume.value)
	_settings["sfx_volume"] = int(sfx_volume.value)
	_settings["display_mode"] = display_mode.selected
	_settings["vsync"] = vsync.button_pressed
	_settings["mouse_sensitivity"] = float(mouse_sensitivity.value)
	_settings["invert_y"] = invert_y.button_pressed

