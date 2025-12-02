extends CanvasLayer

@onready var btn_deselect = $BtnDeselect
@onready var selection_box = $SelectionBox
@onready var btn_mode = $BtnSelectMode

var is_selection_mode_active : bool = false

signal on_deselect_pressed

func _ready():
	if btn_deselect:
		# 1. Mantenemos la señal normal (para PC o Lápiz)
		btn_deselect.pressed.connect(_on_btn_deselect_pressed)

		# 2. AGREGAMOS la señal de input directo (para el Dedo)
		btn_deselect.gui_input.connect(_on_btn_deselect_gui_input)

		btn_deselect.visible = false

	if btn_mode:
		btn_mode.toggled.connect(_on_mode_toggled)
		btn_mode.gui_input.connect(_on_btn_mode_gui_input)

func _on_btn_deselect_gui_input(event):
	if event is InputEventScreenTouch and event.pressed:
		_on_btn_deselect_pressed()
		get_viewport().set_input_as_handled() # Evita mover el personaje al tocar el botón

func _on_btn_deselect_pressed():
	on_deselect_pressed.emit()
	hide_selection_menu()

func _on_btn_mode_gui_input(event):
	if event is InputEventScreenTouch and event.pressed:
		# MANUALMENTE cambiamos el estado del botón (On <-> Off)
		btn_mode.button_pressed = !btn_mode.button_pressed
		
		# Llamamos a la lógica de cambio de modo
		_on_mode_toggled(btn_mode.button_pressed)
		
		# Evitamos que la cámara se mueva al tocar el botón
		get_viewport().set_input_as_handled()

func _on_mode_toggled(button_pressed):
	is_selection_mode_active = button_pressed
	print("Modo Selección: ", is_selection_mode_active) # Debug

func show_selection_menu():
	if btn_deselect:
		btn_deselect.visible = true

func hide_selection_menu():
	if btn_deselect:
		btn_deselect.visible = false
		
