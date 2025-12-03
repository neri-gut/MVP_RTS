class_name UnitSelector
extends Node

@export_group("Selección")
@export var selection_mask : int = 1 
@export var game_ui : GameUI

var camera : Camera3D
var selected_units : Array = []

# Variables Caja
var drag_start : Vector2
var is_dragging_box : bool = false

func setup(cam: Camera3D, ui: CanvasLayer):
	camera = cam
	game_ui = ui
	print("🔍 [Selector] Recibí la UI: ", game_ui)

# --- RAYCAST (Toque simple) ---
func handle_tap(screen_pos : Vector2):
	var space_state = camera.get_world_3d().direct_space_state
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_end = ray_origin + camera.project_ray_normal(screen_pos) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = selection_mask
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		
		# LOGICA DE EQUIPOS Y ACCIÓN
		if collider.has_method("select"):
			# Chequeo de equipo (Si tiene la propiedad team_id)
			var is_enemy = false
			if "team_id" in collider and collider.team_id != 0:
				is_enemy = true
			
			if is_enemy:
				# Si tocamos enemigo -> Atacar
				_order_attack(collider)
			else:
				# Si es amigo -> Seleccionar
				_select_single(collider)
		else:
			# Es suelo -> Mover o Deseleccionar
			if selected_units.size() > 0:
				_order_move(result.position)
			else:
				deselect_all()
	else:
		deselect_all()

# --- CAJA DE SELECCIÓN ---
func start_box(pos: Vector2):
	is_dragging_box = true
	drag_start = pos

func update_box(current_pos: Vector2):
	if game_ui and game_ui.selection_box:
		game_ui.selection_box.update_box(drag_start, current_pos)

func end_box(end_pos: Vector2):
	is_dragging_box = false
	if game_ui: 
		game_ui.selection_box.hide_box()
		game_ui.turn_off_selection_mode() # Apagamos el botón
	
	_calculate_box_selection(end_pos)

func _calculate_box_selection(drag_end):
	var rect = Rect2(drag_start, drag_end - drag_start).abs()
	
	# Solo limpiamos si no estamos agregando (por ahora limpiamos siempre)
	if rect.size.length() > 10: # Evitar clics accidentales pequeños
		deselect_all()
		
		var all_units = get_tree().get_nodes_in_group("Units")
		for unit in all_units:
			# Solo seleccionamos mis unidades (team_id 0)
			if "team_id" in unit and unit.team_id != 0: continue
			
			var screen_pos = camera.unproject_position(unit.global_position)
			if rect.has_point(screen_pos):
				if not camera.is_position_behind(unit.global_position):
					_add_to_selection(unit)

# --- UTILS INTERNAS ---
func _select_single(unit):
	deselect_all()
	_add_to_selection(unit)

func _add_to_selection(unit):
	unit.select()
	selected_units.append(unit)
	if game_ui: 
		print("✅ [Selector] Llamando a show_selection_menu")
		game_ui.show_selection_menu()
	else:
		print("❌ [Selector] ERROR: game_ui es NULL al intentar mostrar menú")

func deselect_all():
	for unit in selected_units:
		unit.deselect()
	selected_units.clear()
	if game_ui: game_ui.hide_selection_menu()

func _order_move(pos):
	for unit in selected_units:
		if unit.has_method("move_to"): unit.move_to(pos)

func _order_attack(target):
	for unit in selected_units:
		if unit.has_method("set_attack_target"): unit.set_attack_target(target)
