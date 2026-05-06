extends Node

var audio_player: AudioStreamPlayer

func _ready():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	var music_path = "res://assets/music/cafe_music.mp3"
	var stream = load(music_path)
	audio_player.stream = stream
	audio_player.stream.loop = true
	
	audio_player.volume_db = -80 
	audio_player.play()
	
	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", 0.0, 3.0).set_trans(Tween.TRANS_SINE)

func set_volume(value: float):
	audio_player.volume_db = value
