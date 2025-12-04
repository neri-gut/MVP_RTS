class_name MovementComponent
extends Node3D

signal destination_reached

@export var speed : float = 5.0
@export var rotation_speed : float = 10.0

@onready var nav_agent = $NavigationAgent3D

var actor : CharacterBody3D

func _ready():
	actor = get_parent().get_parent() as CharacterBody3D
	
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5

func set_target(target_pos : Vector3):
	nav_agent.target_position = target_pos

func handle_movement(delta):
	if nav_agent.is_navigation_finished():
		return
	
	var current_pos = actor.global_position
	var next_pos = nav_agent.get_next_path_position()
	
	var direction = (next_pos - current_pos).normalized()
	var new_velocity = direction * speed
	
	var look_target = Vector3(next_pos.x, actor.global_position.y, next_pos.z)
	if actor.global_position.distance_to(look_target) > 0.1:
		var target_rotation = Transform3D(Basis.looking_at(direction, Vector3.UP), actor.global_position).basis.get_euler().y
		actor.rotation.y = lerp_angle(actor.rotation.y, target_rotation, rotation_speed * delta)
	
	actor.velocity = new_velocity
	actor.move_and_slide()
	
	if  nav_agent.is_navigation_finished():
		destination_reached.emit()
