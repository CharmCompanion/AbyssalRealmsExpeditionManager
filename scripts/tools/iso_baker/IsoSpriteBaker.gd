@tool
extends Node

# Tool scene to bake 3D GLB buildings into isometric 2D sprites.
# Run this scene (F6) in the editor.
# Output goes to res://assets/iso_buildings/<Name>/<Name>_dir0.png .. dir7.png
#
# NOTE: Writing to res:// is editor-only. This is meant as a content pipeline step.

@export var output_root: String = "res://assets/iso_buildings"
@export var bake_on_ready: bool = false
@export var viewport_size: Vector2i = Vector2i(512, 512)
@export var camera_size: float = 6.0
@export var camera_height: float = 10.0
@export var camera_pitch_degrees: float = 35.264 # classic iso-ish pitch
@export var camera_yaw_degrees: float = 45.0 # classic iso-ish yaw

@export var models: Array[String] = [
	"res://assets/buildings/Cottage.glb",
	"res://assets/buildings/Manor.glb",
	"res://assets/buildings/Temple.glb",
	"res://assets/buildings/School.glb",
	"res://assets/buildings/Guild.glb",
	"res://assets/buildings/Bank.glb",
	"res://assets/buildings/Estate.glb",
]

@onready var vp: SubViewport = $Viewport
@onready var root3d: Node3D = $Viewport/Root3D
@onready var cam: Camera3D = $Viewport/Root3D/Camera3D

var _current_instance: Node3D

func _ready() -> void:
	# Safety: only do filesystem writes in editor.
	if not Engine.is_editor_hint():
		return

	vp.size = viewport_size
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = camera_size

	if bake_on_ready:
		bake_all()

func bake_all() -> void:
	if not Engine.is_editor_hint():
		push_warning("[IsoSpriteBaker] Must be run in the editor")
		return

	DirAccess.make_dir_recursive_absolute(output_root)

	for model_path in models:
		if model_path.strip_edges() == "":
			continue
		bake_model(model_path)

	print("[IsoSpriteBaker] Done")

func bake_model(model_path: String) -> void:
	var name := _basename_no_ext(model_path)
	var out_dir := output_root.path_join(name)
	DirAccess.make_dir_recursive_absolute(out_dir)

	_cleanup_current()

	var packed := load(model_path) as PackedScene
	if packed == null:
		push_warning("[IsoSpriteBaker] Missing model: " + model_path)
		return

	var scene: Node = packed.instantiate()
	_current_instance = scene as Node3D
	if _current_instance == null:
		push_warning("[IsoSpriteBaker] Model did not instance as Node3D: " + model_path)
		if scene:
			scene.queue_free()
		return

	root3d.add_child(_current_instance)
	_center_model(_current_instance)

	for dir in range(8):
		_set_iso_camera(dir)
		await get_tree().process_frame
		await get_tree().process_frame
		var img := vp.get_texture().get_image()
		if img == null:
			push_warning("[IsoSpriteBaker] Failed to capture viewport")
			continue
		img.convert(Image.FORMAT_RGBA8)
		img = _trim_transparent(img)
		var out_path := out_dir.path_join("%s_dir%d.png" % [name, dir])
		var err := img.save_png(out_path)
		if err != OK:
			push_warning("[IsoSpriteBaker] save_png failed: %s (%s)" % [out_path, str(err)])
		else:
			print("[IsoSpriteBaker] Wrote ", out_path)

	_cleanup_current()

func _set_iso_camera(dir: int) -> void:
	# 8 directions: rotate yaw 45 degrees each.
	var yaw := camera_yaw_degrees + float(dir) * 45.0
	cam.position = Vector3(0, camera_height, 0)
	cam.rotation_degrees = Vector3(-camera_pitch_degrees, yaw, 0)

func _cleanup_current() -> void:
	if is_instance_valid(_current_instance):
		_current_instance.queue_free()
		_current_instance = null

func _basename_no_ext(p: String) -> String:
	var f := p.get_file()
	return f.substr(0, f.length() - 4) if f.to_lower().ends_with(".glb") else f

func _center_model(n: Node3D) -> void:
	# Simple center: use AABB of MeshInstances if available.
	var aabb := AABB()
	var first := true
	for mi in n.get_children():
		if mi is MeshInstance3D:
			var m := mi as MeshInstance3D
			var ma := m.get_aabb()
			if first:
				aabb = ma
				first = false
			else:
				aabb = aabb.merge(ma)
	if not first:
		n.position = -aabb.get_center()

func _trim_transparent(img: Image) -> Image:
	# Crop to tight non-transparent bounds.
	var w := img.get_width()
	var h := img.get_height()
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	for y in range(h):
		for x in range(w):
			var a := img.get_pixel(x, y).a
			if a > 0.01:
				if x < min_x: min_x = x
				if y < min_y: min_y = y
				if x > max_x: max_x = x
				if y > max_y: max_y = y
	if max_x < min_x or max_y < min_y:
		return img
	var out := Image.create(max_x - min_x + 1, max_y - min_y + 1, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(min_x, min_y, out.get_width(), out.get_height()), Vector2i.ZERO)
	return out
