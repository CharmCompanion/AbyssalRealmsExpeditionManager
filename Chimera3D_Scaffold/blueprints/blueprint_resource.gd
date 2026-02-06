# Resource for blueprint data (list of parts, transforms, metadata)
extends Resource

class_name BlueprintResource

@export var parts: Array = [] # List of {part_resource, transform}
@export var name: String = ""
@export var metadata: Dictionary = {}
