class_name SelectionComponent
extends Node3D

signal on_selected
signal on_deselected

@onready var selection_ring = $SelectionRing

var is_selected : bool = false

func _ready() :
	if selection_ring:
		selection_ring.visible = false

func select():
	is_selected = true
	if selection_ring: selection_ring.visible = true
	on_selected.emit()

func deselect():
	is_selected = false
	if selection_ring: selection_ring.visible = false
	on_deselected.emit()
