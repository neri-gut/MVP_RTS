extends Node3D

# --- CONFIGURACIÓN ---
@export_group("Velocidades")
@export var pan_speed : float = 1.0     # Velocidad de movimiento
@export var rotation_speed : float = 0.05 # Sensibilidad de rotación (Twist)
@export var zoom_speed : float = 1.0    # Sensibilidad del pellizco
@export var smooth_speed : float = 10.0 # Que tan suave se detiene

@export_group("Límites de Zoom (Altura Y)")
@export var min_height : float = 5.0    # Altura mínima (Zoom In máximo)
@export var max_height : float = 40.0   # Altura máxima (Zoom Out máximo)

# --- REFERENCIAS ---
# Usamos @onready para agarrar el nodo hijo "Elevation"
# Nota: Asume que el nodo se llama exactamente "Elevation"
@onready var elevation_node = $Elevation
@onready var camera = $Elevation/Camera3D

# --- VARIABLES INTERNAS ---
var _target_pos : Vector3
var _target_height : float
var _target_rotation_y : float

func _ready():
	# Inicializamos los objetivos con la posición actual para que no salte al inicio
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
		# Creamos una nueva posición manteniendo X y Z en 0 (local), solo cambiamos Y
		var new_local_pos = Vector3(0, _target_height, 0)
		elevation_node.position = elevation_node.position.lerp(new_local_pos, smooth_speed * delta)

func _unhandled_input(event):
	# --- GESTIÓN DE INPUTS CON EL PLUGIN ---
	
	# --- A. ARRASTRE (PANEO NATURAL) ---
	if event is InputEventSingleScreenDrag:
		# 1. Obtener hacia dónde mira la cámara REALMENTE
		var cam_forward = camera.global_transform.basis.z
		var cam_right = camera.global_transform.basis.x
		
		# 2. Aplanar los vectores (Ignorar inclinación Y)
		# Queremos movernos sobre el suelo, no volar hacia el cielo/suelo
		cam_forward.y = 0
		cam_right.y = 0
		
		# 3. Normalizar (para que la velocidad sea constante)
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()
		
		# 4. Calcular el movimiento relativo a la VISTA de la cámara
		# -event.relative.x : Mover dedo a izquierda -> Camara a derecha
		# -event.relative.y : Mover dedo arriba -> Camara atrás
		var move_direction = (cam_right * -event.relative.x) + (cam_forward * -event.relative.y)
		
		# 5. Aplicar movimiento
		var height_factor = _target_height / 10.0
		_target_pos += move_direction * pan_speed * height_factor * 0.05

	# B. PELLIZCO (ZOOM DE ALTURA)
	elif event is InputEventScreenPinch:
		# event.relative es positivo si separas dedos, negativo si juntas
		var zoom_change = event.relative
		
		# Si separo dedos (zoom_change > 0), quiero bajar la altura (Zoom In)
		# Por tanto, RESTAMOS.
		_target_height -= zoom_change * zoom_speed
		
		# Limitamos la altura (Clamp)
		_target_height = clamp(_target_height, min_height, max_height)

	# --- C. GIRO (TWIST - ROTACIÓN) ---
	elif event is InputEventScreenTwist:
		# El plugin nos da 'event.relative' como el ángulo girado en radianes
		# Simplemente lo restamos o sumamos al objetivo
		_target_rotation_y += event.relative * rotation_speed
