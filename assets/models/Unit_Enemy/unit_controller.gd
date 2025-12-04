extends CharacterBody3D

@export_group("Identidad")
@export var team_id : int = 1  # 0 = Jugador, 1 = Enemigo, 2 = Aliado Neutro
@export var unit_name : String = "Enemies"

@onready var movement_comp = $Components/MovementComponent

enum State {IDLE, MOVING, CHASING, ATTACKING}

var selection_comp : SelectionComponent = null
var current_state : State = State.IDLE
var current_target : Node3D = null
var attack_range : float = 2.0

func _ready():
	movement_comp.destination_reached.connect(_on_destination_reached)
	if has_node("Components/SelectionComponent"):
		selection_comp = $Components/SelectionComponent
		selection_comp.on_selected.connect(_on_selected)
	else:
		# Si es un enemigo, es normal no tener esto.
		# print("Nota: Esta unidad no tiene componente de selección (¿Es enemigo?)")
		pass

func _physics_process(delta):
		match current_state:
				State.IDLE:
					pass
				State.MOVING:
					movement_comp.handle_movement(delta)
				State.CHASING:
					_process_chasing(delta)
				State.ATTACKING:
					_process_attacking(delta)

func _on_destination_reached():
		change_state(State.IDLE)

func _on_selected():
	pass

func select():
	if selection_comp:  # <--- SI EXISTE, EJECUTA
		selection_comp.select()

func deselect():
	if selection_comp:  # <--- SI EXISTE, EJECUTA
		selection_comp.deselect()

func move_to(target_pos):
	movement_comp.set_target(target_pos)
	change_state(State.MOVING)

func change_state(new_state):
	current_state = new_state
	
	if new_state == State.MOVING:
		pass
	else:
		pass

func _process_chasing(delta):
	if current_target == null:
		change_state(State.IDLE)
		return
		
	var dist = global_position.distance_to(current_target.global_position)
	
	if dist <= attack_range:
		change_state(State.ATTACKING)
	else:
		movement_comp.set_target(current_target.global_position)
		movement_comp.handle_movement(delta)

func _process_attacking(_delta):
	if current_target == null:
		change_state(State.IDLE)
		return
		
	var dist = global_position.distance_to(current_target.global_position)
	if dist > attack_range + 0.5:
		change_state(State.CHASING)
		return
		
	# AQUÍ IRÍA LA ANIMACIÓN DE DISPARO/GOLPE
	# print("¡PUM! Golpeando al enemigo")
	# Debemos girar para mirarlo siempre
	look_at(current_target.global_position, Vector3.UP)

func set_attack_target(target):
	current_target = target
	change_state(State.CHASING)
