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

# --- REFERENCIAS ---
@onready var elevation_node = $Elevation
@onready var camera = $Elevation/Camera3D

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
		
	# --- D. SELECCIÓN (TAP / TOQUE SIMPLE) --- (NUEVO)
	elif event is InputEventSingleScreenTap:
		_handle_selection(event.position)

# --- FUNCIONES DE SELECCIÓN (NUEVO) ---

func _handle_selection(screen_position):
	# 1. Obtenemos el "espacio físico" del mundo
	var space_state = get_world_3d().direct_space_state
	
	# 2. Proyectamos el rayo desde la cámara
	var ray_origin = camera.project_ray_origin(screen_position)
	var ray_end = ray_origin + camera.project_ray_normal(screen_position) * 1000.0
	
	# 3. Configuramos la búsqueda física
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = selection_mask # Solo chocamos con lo que esté en esta capa
	
	# 4. Lanzamos el rayo
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		# ¿Lo que tocamos tiene el método 'select'? (Es decir, ¿es una unidad?)
		if collider.has_method("select"):
			_select_unit(collider)
		else:
			# Tocamos el suelo o un árbol
			_deselect_all()
	else:
		# Tocamos el cielo
		_deselect_all()

func _select_unit(unit):
	# Por ahora, comportamiento simple: Solo 1 a la vez
	_deselect_all()
	
	unit.select()
	selected_units.append(unit)
	# print("Seleccionado: ", unit.name)

func _deselect_all():
	for unit in selected_units:
		unit.deselect()
	selected_units.clear()
