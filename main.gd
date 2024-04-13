class_name Main extends Node

var game_scene := preload("res://game.tscn")
var start_scene := preload("res://start.tscn")
var won_scene := preload("res://won.tscn")
var lost_scene := preload("res://lost.tscn")


func _ready() -> void:
	var start := start_scene.instantiate()
	var button := start.get_node("Button") as Button
	button.pressed.connect(on_start_button_pressed)
	add_child(start)


func on_start_button_pressed() -> void:
	var existing := get_child(0)
	existing.queue_free()
	await existing.tree_exited
	var game := game_scene.instantiate() as Game
	game.won.connect(on_won)
	game.lost.connect(on_lost)
	add_child(game)


func on_won() -> void:
	var existing := get_child(0)
	existing.queue_free()
	await existing.tree_exited
	var won := won_scene.instantiate()
	var button := won.get_node("Button") as Button
	button.pressed.connect(on_start_button_pressed)
	add_child(won)


func on_lost() -> void:
	var existing := get_child(0)
	existing.queue_free()
	await existing.tree_exited
	var lost := lost_scene.instantiate()
	var button := lost.get_node("Button") as Button
	button.pressed.connect(on_start_button_pressed)
	add_child(lost)


func _unhandled_input(event: InputEvent) -> void:
	if event as InputEventKey:
		var e := event as InputEventKey
		if e.pressed and e.keycode == KEY_ESCAPE and OS.has_feature("editor"):
			get_tree().quit()
