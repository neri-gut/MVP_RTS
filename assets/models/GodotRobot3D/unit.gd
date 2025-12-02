extends CharacterBody3D

# Referencias
@onready var nav_agent = $NavigationAgent3D
@onready var selection_ring = $SelectionRing

# Configuración
var speed = 5.0

# Estado
var is_selected : bool = false # Para saber si soy el elegido

func _ready():
	# IMPORTANTE: Apagar el anillo al iniciar el juego
	if selection_ring:
		selection_ring.visible = false
		
	# Configuración opcional del agente para que no sea tan estricto
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5

func _physics_process(_delta): # Le puse guion bajo al delta para quitar el warning amarillo
	# Si no tengo ruta pendiente, no hago nada
	if nav_agent.is_navigation_finished():
		return

	# 1. ¿Dónde estoy y a dónde voy en este frame?
	var current_agent_position = global_position
	var next_path_position = nav_agent.get_next_path_position()

	# 2. Calcular dirección y velocidad (ignorando altura Y para la dirección)
	var new_velocity = (next_path_position - current_agent_position).normalized() * speed
	
	# 3. Girar al personaje (Look At suave)
	# Usamos solo X y Z para que no mire al cielo/suelo si hay desnivel
	var look_target = Vector3(next_path_position.x, global_position.y, next_path_position.z)
	if global_position.distance_to(look_target) > 0.1:
		look_at(look_target, Vector3.UP)

	# 4. Aplicar movimiento
	# Si quisieras gravedad, aquí harías: new_velocity.y -= gravedad * _delta
	velocity = new_velocity
	move_and_slide()

# --- FUNCIONES PÚBLICAS (LAS QUE LLAMA LA CÁMARA) ---

# Función para recibir una orden de movimiento
func move_to(target_pos):
	nav_agent.target_position = target_pos

# Función para seleccionarme (ESTA FALTABA)
func select():
	is_selected = true
	if selection_ring:
		selection_ring.visible = true
	# print(name + " seleccionado!")

func deselect():
	is_selected = false
	if selection_ring:
		selection_ring.visible = false
