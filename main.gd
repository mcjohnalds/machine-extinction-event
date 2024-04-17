class_name Main extends Node

const MUSIC_TRANSITION_TIME = 2.0
const MIN_VOLUME = -80.0
var game_scene := preload("res://game.tscn")
var start_scene := preload("res://start.tscn")
var won_scene := preload("res://won.tscn")
var lost_scene := preload("res://lost.tscn")
var button_press_sound := (
	preload("res://menu_select.ogg") as AudioStream
)
var game_music := (
	preload("res://piano_and_flute.ogg") as AudioStream
)
var fight_music := (
	preload("res://epic_orchestra_loop.ogg") as AudioStream
)
var game_music_asp := AudioStreamPlayer.new()
var fight_music_asp := AudioStreamPlayer.new()
var game: Game


func _ready() -> void:
	var start := start_scene.instantiate()
	var button := start.get_node("Button") as Button
	button.pressed.connect(on_start_button_pressed)
	add_child(start)

	add_child(game_music_asp)
	game_music_asp.stream = game_music
	game_music_asp.play()

	add_child(fight_music_asp)
	fight_music_asp.stream = fight_music
	fight_music_asp.volume_db = MIN_VOLUME
	fight_music_asp.play()


func _process(delta: float) -> void:
	if game and game.enemies_alive > 0:
		fade_out_asp(game_music_asp, delta)
		if fight_music_asp.volume_db == MIN_VOLUME:
			fight_music_asp.seek(0.0)
		fade_in_asp(fight_music_asp, delta)
	else:
		fade_in_asp(game_music_asp, delta)
		fade_out_asp(fight_music_asp, delta)


func on_start_button_pressed() -> void:
	Util.play_sound(self, button_press_sound)
	await free_children()
	game = game_scene.instantiate() as Game
	game.won.connect(on_won)
	game.lost.connect(on_lost)
	add_child(game)


func on_won() -> void:
	var won := won_scene.instantiate()
	var button := won.get_node("Button") as Button
	button.pressed.connect(on_start_button_pressed)
	add_child(won)


func on_lost() -> void:
	var lost := lost_scene.instantiate()
	var button := lost.get_node("Button") as Button
	button.pressed.connect(on_start_button_pressed)
	add_child(lost)


func free_children() -> void:
	for c in get_children():
		if not c is AudioStreamPlayer:
			c.queue_free()
			await c.tree_exited


func _unhandled_input(event: InputEvent) -> void:
	if event as InputEventKey:
		var e := event as InputEventKey
		if e.pressed and e.keycode == KEY_ESCAPE and OS.has_feature("editor"):
			get_tree().quit()


func fade_out_asp(asp: AudioStreamPlayer, delta: float) -> void:
	var dv := MIN_VOLUME / MUSIC_TRANSITION_TIME * delta
	asp.volume_db = maxf(asp.volume_db + dv, MIN_VOLUME)


func fade_in_asp(asp: AudioStreamPlayer, delta: float) -> void:
	var dv := MIN_VOLUME / MUSIC_TRANSITION_TIME * delta
	asp.volume_db = minf(asp.volume_db - dv, 0.0)
