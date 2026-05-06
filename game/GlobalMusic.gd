extends Node

var audio_player: AudioStreamPlayer

func _ready():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	var music_path = "res://assets/music/cafe_music.wav"
	audio_player.stream = load(music_path)
	audio_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	audio_player.volume_db = -80 
	audio_player.play()
	
	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", 0.0, 3.0).set_trans(Tween.TRANS_SINE)

func set_volume(value: float):
	audio_player.volume_db = value
