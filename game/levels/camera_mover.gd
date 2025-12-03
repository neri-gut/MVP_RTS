class_name CameraMover
extends Node

# --- CONFIGURACIÓN ---
@export_group("Movimiento")
@export var pan_speed : float = 1.0
@export var rotation_speed : float = 0.05
@export var zoom_speed : float = 1.0
@export var smooth_speed : float = 10.0
@export var min_height : float = 5.0
@export var max_height : float = 40.0

# --- REFERENCIAS (Se asignan desde el Controller o auto-búsqueda) ---
var camera_root : Node3D
var elevation_node : Node3D
var camera : Camera3D

# --- ESTADO INTERNO ---
var _target_pos : Vector3
var _target_height : float
var _target_rotation_y : float

func setup(root: Node3D, elev: Node3D, cam: Camera3D):
	camera_root = root
	elevation_node = elev
	camera = cam
	
	# Inicializar objetivos
	_target_pos = camera_root.global_position
	_target_rotation_y = camera_root.rotation.y
	_target_height = elevation_node.position.y

func update_transform(delta):
	if not camera_root: return
	
	# 1. Aplicar Paneo
	camera_root.global_position = camera_root.global_position.lerp(_target_pos, smooth_speed * delta)
	
	# 2. Aplicar Rotación
	camera_root.rotation.y = lerp_angle(camera_root.rotation.y, _target_rotation_y, smooth_speed * delta)
	
	# 3. Aplicar Zoom (Altura)
	var new_local_pos = Vector3(0, _target_height, 0)
	elevation_node.position = elevation_node.position.lerp(new_local_pos, smooth_speed * delta)

# --- FUNCIONES DE INPUT (Llamadas por el Controller) ---

func handle_pan(relative_drag : Vector2):
	var cam_forward = camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x
	
	cam_forward.y = 0; cam_right.y = 0
	cam_forward = cam_forward.normalized(); cam_right = cam_right.normalized()
	
	var move_direction = (cam_right * -relative_drag.x) + (cam_forward * -relative_drag.y)
	
	# Factor de altura para mover más rápido si estamos lejos
	var height_factor = _target_height / 10.0
	_target_pos += move_direction * pan_speed * height_factor * 0.05

func handle_zoom(relative_pinch : float):
	_target_height -= relative_pinch * zoom_speed
	_target_height = clamp(_target_height, min_height, max_height)

func handle_rotate(relative_twist : float):
	_target_rotation_y += relative_twist * rotation_speed
