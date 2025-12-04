extends Control

# Variables para controlar el dibujo
var is_visible_box : bool = false
var start_pos : Vector2
var end_pos : Vector2

func update_box(start, end):
	start_pos = start
	end_pos = end
	is_visible_box = true
	queue_redraw() # Obliga a Godot a llamar a _draw()

func hide_box():
	is_visible_box = false
	queue_redraw()

func _draw():
	if is_visible_box:
		# Dibujamos el rectángulo
		var rect = Rect2(start_pos, end_pos - start_pos)
		
		# Borde Verde (Grosor 2)
		draw_rect(rect, Color(0, 1, 0), false, 2.0)
		
		# Relleno Verde transparente
		draw_rect(rect, Color(0, 1, 0, 0.2), true)
