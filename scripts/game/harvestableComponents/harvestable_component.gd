class_name HarvestableComponent
extends Node3D

signal on_depleted

@export var resource_type : String = "Gold"
@export var amount_left : int = 500
@export var harvest_speed_penalty : float = 1.0

func harvest(amount : int) -> int:
	var extracted = min(amount, amount_left)
	amount_left -= extracted
	
	print("Recurso extraido: ",  extracted, "| Restante: ", amount_left)
	
	if amount_left <= 0:
			on_depleted.emit()
			get_parent().queue_free()
	
	return extracted
