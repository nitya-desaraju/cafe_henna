extends Control

@onready var scroll_container = $ScrollContainer
@onready var money_label = $money/moneyLabel
@onready var fader = $fader
@onready var right_button = $ScrollContainer/HBoxContainer/designsPage/right
@onready var left_button = $ScrollContainer/HBoxContainer/libraryPage/left
@onready var home_button = $home

var money = 0
var page_width = 1024

var item_data = [
	{"name": "Palm 1", "price": 15},
	{"name": "Back 1", "price": 15},
	{"name": "Custom Palm", "price": 20},
	{"name": "Custom Back", "price": 20}
]

func _ready():
	fader.visible = true
	fader.modulate.a = 1.0
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(fader, "modulate:a", 0.0, 1.0)
	fade_in_tween.finished.connect(func(): fader.mouse_filter = Control.MOUSE_FILTER_IGNORE)
	
	var buttons = get_tree().get_nodes_in_group("design_buttons")
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.pivot_offset = btn.custom_minimum_size / 2
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
	
	right_button.pressed.connect(_on_right_pressed)
	left_button.pressed.connect(_on_left_pressed)
	home_button.pressed.connect(_on_home_pressed)
	
	home_button.mouse_entered.connect(_on_button_hover.bind(home_button))
	home_button.mouse_exited.connect(_on_button_unhover.bind(home_button))
	
	update_money_display()

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
