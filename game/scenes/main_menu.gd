extends Node2D

@onready var start_button = $startButton
@onready var how_to_button = $howtoplayButton
@onready var overlay = $overlay
@onready var popup = $popup
@onready var close_popup_button = $popup/closeButton
@onready var fader = $fader

var velocity = 0.0
var gravity = 1500.0
var bounce = -0.4
var is_active = false
var is_closing = false

var start_y = -500.0 
var target_y = 300.0

func _ready():
	fader.color = Color(0, 0, 0, 1)
	fader.modulate.a = 1.0
	fader.visible = true
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.position.y = start_y
	
	start_button.mouse_entered.connect(_on_button_hovered.bind(start_button))
	start_button.mouse_exited.connect(_on_button_unhovered.bind(start_button))
	how_to_button.mouse_entered.connect(_on_button_hovered.bind(how_to_button))
	how_to_button.mouse_exited.connect(_on_button_unhovered.bind(how_to_button))
	
	start_button.pressed.connect(_on_start_button_pressed)
	how_to_button.pressed.connect(_on_how_to_play_button_pressed)
	close_popup_button.pressed.connect(_on_close_popup_button_pressed)
	
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(fader, "modulate:a", 0.0, 1.0)
	await fade_in_tween.finished
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta):
	if is_active:
		velocity += gravity * delta
		popup.position.y += velocity * delta
		
		if popup.position.y > target_y:
			popup.position.y = target_y
			velocity *= bounce
			
			if abs(velocity) < 50:
				velocity = 0
				is_active = false

	elif is_closing:
		velocity -= gravity * delta
		popup.position.y += velocity * delta
		
		if popup.position.y < start_y:
			popup.position.y = start_y
			is_closing = false
			overlay.visible = false

func _on_button_hovered(button: TextureButton):
	button.modulate = Color(0.7, 0.7, 0.7, 1)

func _on_button_unhovered(button: TextureButton):
	button.modulate = Color(1, 1, 1, 1)

func _on_how_to_play_button_pressed():
	pass 
	# overlay.visible = true
	# overlay.modulate.a = 0.6
	# velocity = 0
	# is_active = true
	# is_closing = false

func _on_close_popup_button_pressed():
	pass
	velocity = -200 
	is_active = false
	is_closing = true
	overlay.modulate.a = 0

func _on_start_button_pressed():
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(fader, "modulate:a", 1.0, 1.0)
	await fade_tween.finished
	get_tree().change_scene_to_file("res://scenes/game.tscn")
