# Resource definition for a modular building part
extends Resource

class_name PartResource

# Example properties
@export var mesh: Mesh
@export var socket_data: Dictionary
@export var material_cost: int = 0
@export var part_type: String
