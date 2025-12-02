extends Node3D

# --- CONFIGURACIÓN ---
@export_group("Velocidades")
@export var pan_speed : float = 1.0
@export var rotation_speed : float = 0.05
@export var zoom_speed : float = 1.0
@export var smooth_speed : float = 10.0

@export_group("Límites de Zoom (Altura Y)")
@export var min_height : float = 5.0
@export var max_height : float = 40.0

# --- SELECCIÓN (NUEVO) ---
@export_group("Selección")
@export var selection_mask : int = 1 # Capa de colisión (Layer 1 por defecto)

@export_group("Caja")
var drag_start : Vector2
var is_dragging_box : bool = false

# --- REFERENCIAS ---
@onready var elevation_node = $Elevation
@onready var camera = $Elevation/Camera3D
@onready var game_ui = $"../GameUI"

# --- VARIABLES INTERNAS ---
var _target_pos : Vector3
var _target_height : float
var _target_rotation_y : float
var selected_units : Array = [] # Lista para recordar a quién seleccionamos

func _ready():
	_target_pos = global_position
	_target_rotation_y = rotation.y
	
	if elevation_node:
		_target_height = elevation_node.position.y
		
	# Conectar la señal de la UI a nuestra función de deseleccionar
	if game_ui:
		game_ui.on_deselect_pressed.connect(_deselect_all)

func _process(delta):
	# 1. MOVER EL PADRE (PANEO X/Z)
	global_position = global_position.lerp(_target_pos, smooth_speed * delta)
	
	# 2. ROTAR EL PADRE (Giro Y)
	rotation.y = lerp_angle(rotation.y, _target_rotation_y, smooth_speed * delta)
	
	# 3. MOVER EL HIJO (ZOOM Y)
	if elevation_node:
		var new_local_pos = Vector3(0, _target_height, 0)
		elevation_node.position = elevation_node.position.lerp(new_local_pos, smooth_speed * delta)

func _unhandled_input(event):
	# Verificamos si la UI nos dice que estamos en "Modo Selección"
	var selection_mode = false
	if game_ui:
		selection_mode = game_ui.is_selection_mode_active

	# --- 1. GESTIÓN DE LA CAJA (INICIO / FIN) ---
	if event is InputEventScreenTouch:
		if event.pressed:
			if selection_mode:
				# Empezamos a dibujar caja
				is_dragging_box = true
				drag_start = event.position
			else:
				# Aquí podrías poner lógica extra si no es modo selección
				pass
		else:
			# AL SOLTAR EL DEDO
			if is_dragging_box:
				_finish_box_selection(event.position)
				is_dragging_box = false
				if game_ui and game_ui.selection_box: 
					game_ui.selection_box.hide_box()

	# --- 2. DIBUJO VISUAL DE LA CAJA (SOLO SI ESTAMOS DIBUJANDO) ---
	elif event is InputEventScreenDrag:
		if is_dragging_box:
			# Actualizamos el dibujo visual
			if game_ui and game_ui.selection_box:
				game_ui.selection_box.update_box(drag_start, event.position)
			# IMPORTANTE: Detenemos aquí para que no siga procesando
			return 

	# --- 3. CONTROLES DE CÁMARA (DEL PLUGIN) ---
	# Solo ejecutamos esto si NO estamos dibujando una caja
	if not is_dragging_box:
		
		# --- A. ARRASTRE (PANEO NATURAL) ---
		if event is InputEventSingleScreenDrag:
			var cam_forward = camera.global_transform.basis.z
			var cam_right = camera.global_transform.basis.x
			cam_forward.y = 0
			cam_right.y = 0
			cam_forward = cam_forward.normalized()
			cam_right = cam_right.normalized()
			
			var move_direction = (cam_right * -event.relative.x) + (cam_forward * -event.relative.y)
			var height_factor = _target_height / 10.0
			_target_pos += move_direction * pan_speed * height_factor * 0.05

		# --- B. PELLIZCO (ZOOM) ---
		elif event is InputEventScreenPinch:
			var zoom_change = event.relative
			_target_height -= zoom_change * zoom_speed
			_target_height = clamp(_target_height, min_height, max_height)

		# --- C. GIRO (TWIST) ---
		elif event is InputEventScreenTwist:
			_target_rotation_y += event.relative * rotation_speed
			
		# --- D. SELECCIÓN (TAP / TOQUE SIMPLE) ---
		# OJO: Este también estaba mal indentado antes (estaba dentro de Drag)
		elif event is InputEventSingleScreenTap:
			# Solo permitimos tocar para mover si NO estamos en modo caja
			if not selection_mode: 
				_handle_selection(event.position)

# --- FUNCIÓN DE SELECCIÓN MATEMÁTICA ---
func _finish_box_selection(drag_end):
	# Crear el rectángulo matemático (Rect2)
	# Rect2 necesita (origen, tamaño). El tamaño es end - start.
	# abs() asegura que funcione aunque arrastres hacia atrás.
	var rect = Rect2(drag_start, drag_end - drag_start).abs()
	
	# Limpiamos selección anterior si no mantenemos shift (opcional)
	_deselect_all()
	
	# LA MAGIA: Buscar todas las unidades del juego
	# (Lo ideal sería tenerlas en un Grupo "Units")
	var all_units = get_tree().get_nodes_in_group("Units")
	
	for unit in all_units:
		# 1. ¿Dónde está la unidad en la pantalla 2D?
		var screen_pos = camera.unproject_position(unit.global_position)
		
		# 2. ¿Está el punto dentro del rectángulo?
		if rect.has_point(screen_pos):
			# 3. ¿Está visible delante de la cámara? (Evitar seleccionar cosas detrás)
			if not camera.is_position_behind(unit.global_position):
				_select_unit(unit)

# --- FUNCIONES DE SELECCIÓN (NUEVO) ---

func _handle_selection(screen_position):
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.project_ray_origin(screen_position)
	var ray_end = ray_origin + camera.project_ray_normal(screen_position) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = selection_mask
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		var hit_position = result.position # Guardamos el punto exacto del clic
		
		# CASO A: Toco una UNIDAD
		if collider.has_method("select"):
			_select_unit(collider)
			
		# CASO B: Toco el SUELO (y tengo tropas listas)
		else:
			if selected_units.size() > 0:
				# --- AQUÍ ESTABA EL FALTANTE ---
				# Si tengo gente seleccionada, les doy la orden de moverse
				_order_move(hit_position)
			else:
				# Si no tengo nadie, y toco suelo -> Deseleccionar todo
				_deselect_all()
	else:
		_deselect_all()

func _select_unit(unit):
	# Por ahora, comportamiento simple: Solo 1 a la vez
	_deselect_all()
	
	unit.select()
	selected_units.append(unit)
	if game_ui: game_ui.show_selection_menu()

func _deselect_all():
	for unit in selected_units:
		unit.deselect()
	selected_units.clear()
	if game_ui: game_ui.hide_selection_menu()
	
func _order_move(target_position):
	for unit in selected_units:
		if unit.has_method("move_to"):
			unit.move_to(target_position)

	
	
