extends Node

# Sfx.gd
#
# Centralised sound effect manager.  Attaching this script to an
# AutoLoad allows any script to play click, hover or page flip sounds.
# The sound files should be placed in `res://assets/sfx/` and assigned
# to the exported variables in the inspector.  If no sound is set the
# functions safely do nothing.

@export var click_sound: AudioStream
@export var hover_sound: AudioStream
@export var page_sound: AudioStream

func play_click() -> void:
	if click_sound:
		get_tree().create_tween().tween_property(self, "_play_sound", click_sound, 0)

func play_hover() -> void:
	if hover_sound:
		get_tree().create_tween().tween_property(self, "_play_sound", hover_sound, 0)

func play_page() -> void:
	if page_sound:
		get_tree().create_tween().tween_property(self, "_play_sound", page_sound, 0)

func _play_sound(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.play()
	player.finished.connect(player.queue_free)
