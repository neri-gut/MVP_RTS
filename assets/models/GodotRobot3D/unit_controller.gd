extends CharacterBody3D

@export_group("Identidad")
@export var team_id : int = 1  # 0 = Jugador, 1 = Enemigo, 2 = Aliado Neutro
@export var unit_name : String = "Enemies"

@onready var movement_comp = $Components/MovementComponent
@onready var selection_comp = $Components/SelectionComponent

enum State {IDLE, MOVING}
var current_state : State = State.IDLE

func _ready():
	movement_comp.destination_reached.connect(_on_destination_reached)
	selection_comp.on_selected.connect(_on_selected)

func _physics_process(delta):
		match current_state:
				State.IDLE:
					pass
				State.MOVING:
					movement_comp.handle_movement(delta)

func _on_destination_reached():
		change_state(State.IDLE)

func _on_selected():
	pass

func select():
	selection_comp.select()

func deselect():
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
