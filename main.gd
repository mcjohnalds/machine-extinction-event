class_name Main extends Node

const MUSIC_TRANSITION_TIME = 2.0
const MIN_VOLUME = -80.0
var game_scene := preload("res://game.tscn")
var start_scene := preload("res://start.tscn")
var won_scene := preload("res://won.tscn")
var lost_scene := preload("res://lost.tscn")
var preview_scene := preload("res://preview.tscn")
var shader_precompilation_scene := preload("res://shader_precompilation.tscn")
var button_press_sound := (
	preload("res://menu_select.ogg") as AudioStream
)
var game_music := (
	preload("res://piano_and_flute.ogg") as AudioStream
)
var fight_music := (
	preload("res://epic_orchestra_loop.ogg") as AudioStream
)
var win_music := (
	preload("res://vann_westfold_secundo_tempore_remix.ogg") as AudioStream
)
var lose_music := (
	preload("res://the_dramatic_music.ogg") as AudioStream
)
var game_music_asp := AudioStreamPlayer.new()
var fight_music_asp := AudioStreamPlayer.new()
var win_music_asp := AudioStreamPlayer.new()
var lose_music_asp := AudioStreamPlayer.new()
var game: Game
var preview_spinner: Node3D


func _ready() -> void:
	# Precompile shaders, user can't see this
	var precomp := shader_precompilation_scene.instantiate()
	for particle: GPUParticles3D in (
		precomp.find_children("*", "GPUParticles3D", true, true)
	):
		particle.emitting = true
	add_child(precomp)
	await free_children()

	await get_tree().create_timer(0.1).timeout

	var preview := preview_scene.instantiate()
	preview_spinner = preview.get_node("Spinner")
	add_child(preview)

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

	add_child(win_music_asp)
	win_music_asp.stream = win_music
	win_music_asp.volume_db = MIN_VOLUME
	win_music_asp.play()

	add_child(lose_music_asp)
	lose_music_asp.stream = lose_music
	lose_music_asp.volume_db = MIN_VOLUME
	lose_music_asp.play()


func _process(delta: float) -> void:
	if preview_spinner:
		preview_spinner.rotation.y = (
			0.1 + sin(Util.time() * 0.17) * 0.002 * TAU
		)
		preview_spinner.position.y = (
			0.01 + sin(Util.time() * 0.15) * 0.01
		)
	if game and game.enemies_alive > 0 and not game.is_game_over:
		fade_out_asp(game_music_asp, delta)
		fade_in_from_start_asp(fight_music_asp, delta)
		fade_out_asp(win_music_asp, delta)
		fade_out_asp(lose_music_asp, delta)
	elif game and game.is_game_over and game.is_rocket_taking_off:
		fade_out_asp(game_music_asp, delta)
		fade_out_asp(fight_music_asp, delta)
		fade_in_from_start_asp(win_music_asp, delta)
		fade_out_asp(lose_music_asp, delta)
	elif game and game.is_game_over and not game.is_rocket_taking_off:
		fade_out_asp(game_music_asp, delta)
		fade_out_asp(fight_music_asp, delta)
		fade_out_asp(win_music_asp, delta)
		fade_in_from_start_asp(lose_music_asp, delta)
	else:
		fade_in_asp(game_music_asp, delta)
		fade_out_asp(fight_music_asp, delta)
		fade_out_asp(win_music_asp, delta)
		fade_out_asp(lose_music_asp, delta)


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
	preview_spinner = null
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


func fade_in_from_start_asp(asp: AudioStreamPlayer, delta: float) -> void:
	if asp.volume_db == MIN_VOLUME:
		asp.seek(0.0)
		asp.play()
	fade_in_asp(asp, delta)
