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

var tex_palm_base = preload("res://assets/palm_base.png")
var tex_back_base = preload("res://assets/back_base.png")
var tex_palm_trace = preload("res://assets/palm_trace.png")
var tex_back_trace = preload("res://assets/back_trace.png")

var money = 0
var page_width = 1024
var is_drawing_mode = false
var current_line: Line2D

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

func _on_undo_pressed():
	var lines = drawing_container.get_children()
	if lines.size() > 0:
		var last_stroke = lines[-1]
		last_stroke.queue_free()

func _on_design_selected(index: int):
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
	if btn.is_in_group("design_buttons"):
		var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15)

func _on_button_unhover(btn: Control):
	btn.modulate = Color(1, 1, 1, 1)
	if btn.is_in_group("design_buttons"):
		var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
