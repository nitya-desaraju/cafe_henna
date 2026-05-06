extends Control

@onready var scroll_container = $ScrollContainer
@onready var money_label = $money/moneyLabel
@onready var fader = $fader
@onready var right_button = $ScrollContainer/HBoxContainer/designsPage/right
@onready var left_button = $ScrollContainer/HBoxContainer/libraryPage/left

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
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var fade_tween = create_tween()
	fade_tween.tween_property(fader, "modulate:a", 0.0, 1.0)
	
	var buttons = get_tree().get_nodes_in_group("design_buttons")
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.pivot_offset = btn.custom_minimum_size / 2
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
	
	right_button.pressed.connect(_on_right_pressed)
	left_button.pressed.connect(_on_left_pressed)
	
	for nav_btn in [right_button, left_button]:
		nav_btn.mouse_entered.connect(_on_button_hover.bind(nav_btn))
		nav_btn.mouse_exited.connect(_on_button_unhover.bind(nav_btn))

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

func _on_button_hover(btn: Control):
	btn.modulate = Color(0.7, 0.7, 0.7, 1)
	if btn.is_in_group("design_buttons"):
		create_tween().tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)

func _on_button_unhover(btn: Control):
	btn.modulate = Color(1, 1, 1, 1)
	if btn.is_in_group("design_buttons"):
		create_tween().tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
