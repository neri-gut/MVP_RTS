extends CharacterBody3D

# Referencia al anillo de selección
@onready var selection_ring = $SelectionRing

# Variable para saber si está seleccionado
var is_selected : bool = false

func _ready():
	# Asegurarnos que empiece apagado por si acaso
	if selection_ring:
		selection_ring.visible = false

# Función pública para seleccionar esta unidad
func select():
	is_selected = true
	if selection_ring:
		selection_ring.visible = true
	# Aquí podrías reproducir un sonido tipo "¡Sí, señor!"

# Función pública para deseleccionar
func deselect():
	is_selected = false
	if selection_ring:
		selection_ring.visible = false
