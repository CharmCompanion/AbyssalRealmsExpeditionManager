extends RefCounted
class_name AIAddons

# Centralized detection of optional AI addons.
# IMPORTANT: Do not reference addon classes directly here (would hard-depend).

static func has_limboai() -> bool:
	# LimboAI is typically installed under res://addons/limboai/
	# We detect by folder presence rather than class names to avoid parse-time dependencies.
	return DirAccess.dir_exists_absolute("res://addons/limboai")

static func has_gdplanningai() -> bool:
	# GdPlanningAI recommended install folder: res://addons/GdPlanningAI
	return DirAccess.dir_exists_absolute("res://addons/GdPlanningAI")
