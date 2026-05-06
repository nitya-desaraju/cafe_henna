extends Control

@onready var scroll_container = $ScrollContainer
@onready var money_label = $money/moneyLabel
@onready var fader = $fader
@onready var right_button = $ScrollContainer/HBoxContainer/designsPage/right
@onready var left_button = $ScrollContainer/HBoxContainer/libraryPage/left
@onready var home_button = $home

@onready var drawing_layer = $DrawingLayer
@onready var hand_image = $DrawingLayer/HandImage
@onready var trace_image = $DrawingLayer/TraceImage
@onready var drawing_container = $DrawingLayer/DrawingContainer
@onready var undo_button = $DrawingLayer/undo
@onready var finish_button = $DrawingLayer/FinishButton

@onready var library_grid = $ScrollContainer/HBoxContainer/libraryPage/GridContainer
@onready var library_empty_label = $ScrollContainer/HBoxContainer/libraryPage/empty
@onready var designs_grid = $ScrollContainer/HBoxContainer/designsPage/GridContainer

var tex_palm_base = preload("res://assets/palm_base.png")
var tex_back_base = preload("res://assets/back_base.png")
var tex_palm_trace = preload("res://assets/palm_trace.png")
var tex_back_trace = preload("res://assets/back_trace.png")

var money = 0
var page_width = 1024
var is_drawing_mode = false
var current_line: Line2D
var current_design_index = 0
var is_viewing_full_image = false

func _ready():
	fader.visible = true
	fader.modulate.a = 1.0
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var fade_in = create_tween()
	fade_in.tween_property(fader, "modulate:a", 0.0, 1.0)
	fade_in.finished.connect(func(): fader.mouse_filter = Control.MOUSE_FILTER_IGNORE)
	
	var buttons = get_tree().get_nodes_in_group("design_buttons")
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.pivot_offset = btn.custom_minimum_size / 2
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
		btn.pressed.connect(_on_design_selected.bind(i))

	right_button.pressed.connect(_on_right_pressed)
	left_button.pressed.connect(_on_left_pressed)
	home_button.pressed.connect(_on_home_pressed)
	undo_button.pressed.connect(_on_undo_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	
	home_button.mouse_entered.connect(_on_button_hover.bind(home_button))
	home_button.mouse_exited.connect(_on_button_unhover.bind(home_button))
	
	update_money_display()

func _process(_delta):
	if is_drawing_mode and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var pos = drawing_container.get_local_mouse_position()
		if current_line:
			current_line.add_point(pos)

func _input(event):
	if is_drawing_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				current_line = Line2D.new()
				current_line.default_color = Color("#800000")
				current_line.width = 2.5
				
				current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
				current_line.antialiased = true
				drawing_container.add_child(current_line)
			else:
				current_line = null
				
	if is_viewing_full_image and event is InputEventMouseButton and event.pressed:
		_close_full_view()

func _on_undo_pressed():
	var lines = drawing_container.get_children()
	if lines.size() >= 2:
		lines[-1].queue_free()
		lines[-2].queue_free()

	elif lines.size() == 1:
		lines[0].queue_free()

func _on_design_selected(index: int):
	current_design_index = index
	match index:
		0:
			hand_image.texture = tex_palm_base
			trace_image.texture = tex_palm_trace
			trace_image.visible = true
		1:
			hand_image.texture = tex_back_base
			trace_image.texture = tex_back_trace
			trace_image.visible = true
		2:
			hand_image.texture = tex_palm_base
			trace_image.visible = false
		3:
			hand_image.texture = tex_back_base
			trace_image.visible = false
	
	for child in drawing_container.get_children():
		child.queue_free()
		
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	var slide = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	slide.tween_property(drawing_layer, "position:y", 0, 0.6) 
	await slide.finished
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_drawing_mode = true

func _on_finish_pressed():
	is_drawing_mode = false

	var prices = [15, 15, 20, 20]
	money += prices[current_design_index]
	update_money_display()
	
	var screenshot = await take_screenshot()

	library_empty_label.visible = false
	library_grid.visible = true
	
	var original_vbox = designs_grid.get_child(current_design_index)
	var new_vbox = original_vbox.duplicate()
	var btn = new_vbox.get_node("TextureButton")
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color("#472759")
	style_box.set_corner_radius_all(15)
	style_box.expand_margin_left = 6
	style_box.expand_margin_top = 6
	style_box.expand_margin_right = 6
	style_box.expand_margin_bottom = 6
	
	var border_container = PanelContainer.new()
	border_container.add_theme_stylebox_override("panel", style_box)
	border_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	btn.get_parent().remove_child(btn)
	border_container.add_child(btn)
	new_vbox.add_child_at(border_container, 0)
	
	var tex = ImageTexture.create_from_image(screenshot)
	btn.texture_normal = tex

	btn.mouse_entered.connect(_on_button_hover.bind(btn))
	btn.mouse_exited.connect(_on_button_unhover.bind(btn))
	btn.pressed.connect(_show_full_view.bind(tex))
	
	library_grid.add_child(new_vbox)
	
	var slide_up = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	slide_up.tween_property(drawing_layer, "position:y", -576, 0.4)
	await slide_up.finished
	scroll_to_page(1024)

func take_screenshot():
	undo_button.visible = false
	finish_button.visible = false
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()

	var x_offset = (1024 - 576) / 2
	var rect = Rect2i(x_offset, 0, 576, 576)
	var cropped_img = img.get_region(rect)

	undo_button.visible = true
	finish_button.visible = true

	return cropped_img

func _show_full_view(tex: Texture2D):
	var expanded_container = PanelContainer.new()
	expanded_container.name = "FullViewOverlay"
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color("#472759")
	style_box.set_corner_radius_all(20)
	style_box.expand_margin_left = 10
	style_box.expand_margin_top = 10
	style_box.expand_margin_right = 10
	style_box.expand_margin_bottom = 10
	expanded_container.add_theme_stylebox_override("panel", style_box)

	var expanded_image = TextureRect.new()
	expanded_image.texture = tex
	expanded_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	expanded_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	expanded_container.add_child(expanded_image)
	
	expanded_container.size = Vector2(100, 100)
	expanded_container.position = get_global_mouse_position() - Vector2(50, 50)
	expanded_container.z_index = 100
	
	add_child(expanded_container)
	
	var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	t.tween_property(expanded_container, "size", Vector2(1024, 576), 0.5)
	t.tween_property(expanded_container, "position", Vector2(0, 0), 0.5)
	
	await t.finished
	is_viewing_full_image = true

func _close_full_view():
	var overlay = get_node_or_null("FullViewOverlay")
	if overlay:
		var t = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		t.tween_property(overlay, "modulate:a", 0.0, 0.3)
		await t.finished
		overlay.queue_free()
	is_viewing_full_image = false

func _on_home_pressed():
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_out = create_tween()
	fade_out.tween_property(fader, "modulate:a", 1.0, 0.8)
	await fade_out.finished
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_right_pressed():
	scroll_to_page(1024)

func _on_left_pressed():
	scroll_to_page(0)

func scroll_to_page(target_x: int):
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(scroll_container, "scroll_horizontal", target_x, 0.5)
	await tween.finished
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_money_display():
	money_label.text = "$%d" % money

func _on_button_hover(btn: Control):
	btn.modulate = Color(0.7, 0.7, 0.7, 1)
	btn.pivot_offset = btn.size / 2
	var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15)

func _on_button_unhover(btn: Control):
	btn.modulate = Color(1, 1, 1, 1)
	var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
