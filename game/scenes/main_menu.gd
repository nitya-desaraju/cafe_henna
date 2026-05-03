extends Node2D

@onready var music = $music
@onready var start_button = $startButton
@onready var how_to_button = $howtoplayButton
@onready var overlay = $Overlay
@onready var popup = $popup
@onready var close_popup_button = $howtoplayPopup/closeButton
@onready var fader = $fader

var velocity = 0.0
var gravity = 1500.0
var bounce = -0.4
var is_active = false
var is_closing = false

var start_y = -500.0 
var target_y = 300.0

func _ready():
	music.play()
	popup.position.y = start_y
	overlay.modulate.a = 0

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

func _on_how_to_play_button_pressed():
	overlay.visible = true
	overlay.modulate.a = 0.6
	velocity = 0
	is_active = true
	is_closing = false

func _on_close_popup_button_pressed():
	velocity = -200 
	is_active = false
	is_closing = true
	overlay.modulate.a = 0

func _on_start_button_pressed():
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(fader, "modulate:a", 1.0, 1.0)
	fade_tween.tween_property(music, "volume_db", -80.0, 1.0)
	await fade_tween.finished
	get_tree().change_scene_to_file("res://scenes/game.tscn")
