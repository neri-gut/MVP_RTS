extends Node3D

# --- REFERENCIAS ---
@export var game_ui : GameUI
@onready var elevation_node = $Elevation
@onready var camera = $Elevation/Camera3D

# Sub-Componentes
@onready var mover = $CameraMover
@onready var selector = $UnitSelector

func _ready():

	# Inicializamos los subsistemas pasándoles lo que necesitan
	mover.setup(self, elevation_node, camera)
	selector.setup(camera, game_ui)
	
	# Conectar UI
	if game_ui:
		if game_ui.has_signal("on_deselect_pressed"):
			game_ui.on_deselect_pressed.connect(selector.deselect_all)
	#TODO: Se debe refactorizar ya que todos lo personajes tendran el nodo de seleccion

func _process(delta):
	# Delegamos el movimiento suave
	mover.update_transform(delta)

func _unhandled_input(event):
	# Verificar modo en UI
	var is_selection_mode = false
	if game_ui: is_selection_mode = game_ui.is_selection_mode_active
	
	# --- INPUTS TÁCTILES ---
	
	# 1. GESTIÓN DE CAJA (Prioridad 1)
	if event is InputEventScreenTouch:
		if event.pressed:
			if is_selection_mode:
				selector.start_box(event.position)
			else:
				# Si no es modo caja, es un toque potencial, 
				# pero esperamos a ver si es drag para no disparar tap accidentalmente
				pass
		else:
			# Soltar dedo
			if selector.is_dragging_box:
				selector.end_box(event.position)

	elif event is InputEventScreenDrag:
		if selector.is_dragging_box:
			selector.update_box(event.position)
			return # ¡STOP! No mover cámara si dibujamos caja

	# 2. MOVIMIENTO DE CÁMARA (Si no hay caja)
	if not selector.is_dragging_box:
		if event is InputEventSingleScreenDrag:
			mover.handle_pan(event.relative)
		elif event is InputEventScreenPinch:
			mover.handle_zoom(event.relative)
		elif event is InputEventScreenTwist:
			mover.handle_rotate(event.relative)
		
		# 3. SELECCIÓN/ORDEN (TAP)
		elif event is InputEventSingleScreenTap:
			if not is_selection_mode:
				selector.handle_tap(event.position)
