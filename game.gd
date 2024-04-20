class_name Game extends Node3D

signal won
signal lost
const MAX_URANIUM_SPAWN_DISTANCE := 100
const INVALID_GRID_COORD := Vector2i(1000000, 1000000)
const DURATION_BEFORE_FIRST_WAVE := 30.0
const CONSTANT_ENERGY_GAIN := 2
const SCINECE_GAIN_PER_LAB := 1
const ENERGY_GAIN_PER_MINE := 2
const SCIENCE_REQUIRED_TO_LAUNCH := 5000
const BUILDING_COMPLETION_DURATION := 20.0
const ENEMY_SPAWN_DISTANCE_FROM_PLAYER := 30.0
const ENEMY_SPEED = 1.0
const TURRET_DRAIN_PER_SECOND = 1
const CAMERA_SPEED := 6.0
const TURRET_SHOOT_COOLDOWN := 2.0
const TURRET_RADIUS := 5.0
const GHOST_VALID := Color("5d8fba7f")
const GHOST_INVALID := Color("37546e3e")
enum GameResult {WON, LOST}
enum BuildingType {TURRET, WALL, MINE, LAB}
enum TutorialStep {START, TURRET, WALL, ENERGY, MINE, SCIENCE, LAB, END}
const TUTORIAL_TEXT_FOR_STEP := {
	TutorialStep.START: "",
	TutorialStep.TURRET: "Build a turret to defend your base",
	TutorialStep.WALL: "Build a wall to defend your base",
	TutorialStep.ENERGY: "Be mindful of your energy",
	TutorialStep.MINE: "Build a uranium mine to gain energy",
	TutorialStep.SCIENCE: "Gain enough science to escape earth",
	TutorialStep.LAB: "Build a lab to gain science",
	TutorialStep.END: ""
}
const TUTORIAL_POPUP_Y_FOR_STEP := {
	TutorialStep.START: 0,
	TutorialStep.TURRET: 6,
	TutorialStep.WALL: 106,
	TutorialStep.ENERGY: 433,
	TutorialStep.MINE: 206,
	TutorialStep.SCIENCE: 693,
	TutorialStep.LAB: 306,
	TutorialStep.END: 0
}
const BUILDING_ENERGY_COST := {
	BuildingType.TURRET: 50,
	BuildingType.WALL: 10,
	BuildingType.MINE: 50,
	BuildingType.LAB: 100,
}
const BUILDING_ENERGY_SELL_VALUE := {
	BuildingType.TURRET: 25,
	BuildingType.WALL: 5,
	BuildingType.MINE: 25,
	BuildingType.LAB: 50,
}
var building_destroyed_smoke_scene := (
	preload("res://building_destroyed_smoke.tscn")
)
var enemy_explosion_scene := (
	preload("res://enemy_explosion.tscn")
)
var turret_scene := preload("res://turret.tscn")
var wall_scene := preload("res://wall.tscn")
var lab_scene := preload("res://lab.tscn")
var enemy_scene := preload("res://enemy.tscn")
var tracer_scene := preload("res://tracer.tscn")
var uranium_scene := preload("res://uranium.tscn")
var mine_scene := preload("res://mine.tscn")
var player_transparent := preload("res://player_transparent.tres") as BaseMaterial3D
var player_ghost := preload("res://player_ghost.tres") as BaseMaterial3D
var blank_cursor := preload("res://blank_cursor.png")
var laser_sounds := [
	preload("res://laser_1.ogg"),
	preload("res://laser_2.ogg"),
	preload("res://laser_3.ogg"),
	preload("res://laser_4.ogg"),
	preload("res://laser_5.ogg"),
	preload("res://laser_6.ogg"),
	preload("res://laser_7.ogg"),
	preload("res://laser_8.ogg"),
	preload("res://laser_9.ogg"),
	preload("res://laser_10.ogg"),
] as Array[AudioStream]
var building_placed_sound := (
	preload("res://building_placed.ogg") as AudioStream
)
var building_completed_sound := (
	preload("res://building_completed.ogg") as AudioStream
)
var building_progress_sound := (
	preload("res://forcefield_hum.ogg") as AudioStream
)
var building_destroyed_sound := (
	preload("res://building_collapse_loud.ogg") as AudioStream
)
var enemy_destroyed_sound := (
	preload("res://enemy_destroyed.ogg") as AudioStream
)
var rocket_thrust_sound := (
	preload("res://rocket_thrust.ogg") as AudioStream
)
var explosion_sound := (
	preload("res://explosion.ogg") as AudioStream
)
var warning_sound := (
	preload("res://warning.ogg") as AudioStream
)
var sell_sound := (
	preload("res://pebble_drop_in_cup.ogg") as AudioStream
)
var tick_sound := (
	preload("res://menu_select_tick.ogg") as AudioStream
)
var building_place_failed_sound := (
	preload("res://file_select.ogg") as AudioStream
)
@onready var ground := $Ground as Area3D
@onready var ghost := $Ghost as Node3D
@onready var ghost_turret := $Ghost/Turret as Node3D
@onready var ghost_turret_ring := $Ghost/Turret/Ring as Node3D
@onready var ghost_wall := $Ghost/Wall as Node3D
@onready var ghost_mine := $Ghost/Mine as Node3D
@onready var ghost_lab := $Ghost/Lab as Node3D
@onready var launchpad := $Buildings/Launchpad as Node3D
@onready var enemies := $Enemies as Node
@onready var buildings := $Buildings as Node
@onready var hud := $HUD as CanvasLayer
@onready var hud_background := $HUD/Background as Control
@onready var turret_button := $HUD/TurretButton as Button
@onready var wall_button := $HUD/WallButton as Button
@onready var mine_button := $HUD/MineButton as Button
@onready var lab_button := $HUD/LabButton as Button
@onready var energy_label := $HUD/EnergyLabel as Label
@onready var energy_delta_label := $HUD/EnergyDeltaLabel as Label
@onready var science_label := $HUD/ScienceLabel as Label
@onready var science_required_label := $HUD/ScienceRequiredLabel as Label
@onready var science_delta_label := $HUD/ScienceDeltaLabel as Label
@onready var tooltip := $HUD/Tooltip as Control
@onready var tooltip_label := $HUD/Tooltip/Label as Label
@onready var warning_label := $HUD/WarningLabel as Control
@onready var tutorial_popup := $HUD/TutorialPopup as Control
@onready var tutorial_popup_label := $HUD/TutorialPopup/Label as Label
@onready var tutorial_popup_button := $HUD/TutorialPopup/Button as Button
@onready var cinematic_bars := $CinematicBars as CanvasLayer
@onready var camera := $Camera3D as Camera3D
@onready var fog_of_war := $FogOfWar as Node3D
@onready var launchpad_visibility_ring := $FogOfWar/VisibilityRing as Node3D
@onready var rocket := $Rocket as Node3D
@onready var rocket_shadow := (
	$Buildings/Launchpad/Launchpad/RocketShadow as Sprite3D
)
var tutorial_step := TutorialStep.START
var mouse_position_3d := Vector3.ZERO
var building_type := BuildingType.TURRET
var no_building_type_selected := true
var grid_to_building := {} # Dictionary[Vector2i, Node3D]
var grid_to_building_completion_proportion := {} # Dictionary[Vector2i, float]
var grid_to_uranium := {} # Dictionary[Vector2i, Node3D]
var grid_to_visibility_ring := {} # Dictionary[Vector2i, Node3D]
var grid_to_building_completion_stream_id := {} # Dictionary[Vector2i, int]
# TODO: I don't need to track both AudioStreamPlaybackPolyphonic and
# AudioStreamPlayer3D
var audio_playbacks := {} # Dictionary[Node, AudioStreamPlaybackPolyphonic]
var audio_stream_players := {} # Dictionary[Node, AudioStreamPlayer3D]
var building_fall_direction := {} # Dictionary[Node, Vector2]
var is_alive := {} # Dictionary[Node, bool]
var energy := 150
var science := 0
var camera_offset := Vector3.ZERO
var enemy_spawn_position := Vector3.ZERO
var enemies_alive := 0
var is_game_over := false
var is_rocket_taking_off := false


func _ready() -> void:
	science_required_label.text = (
		"%s science required to launch rocket" % SCIENCE_REQUIRED_TO_LAUNCH
	)
	set_science(science)
	set_energy(energy)

	add_audio_stream_player(rocket)

	turret_button.pressed.connect(func() -> void:
		select_building_type(BuildingType.TURRET)
	)
	wall_button.pressed.connect(func() -> void:
		select_building_type(BuildingType.WALL)
	)
	mine_button.pressed.connect(func() -> void:
		select_building_type(BuildingType.MINE)
	)
	lab_button.pressed.connect(func() -> void:
		select_building_type(BuildingType.LAB)
	)

	camera_offset = camera.position
	grid_to_building[Vector2i(0, 0)] = launchpad
	grid_to_building_completion_proportion[Vector2i(0, 0)] = 1.0
	ground.input_event.connect(_on_ground_input_event)
	add_audio_stream_player(launchpad)
	is_alive[launchpad] = true
	building_fall_direction[launchpad] = Vector2(
		randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)
	).normalized()

	ghost_turret_ring.scale.x = TURRET_RADIUS * 2.0
	ghost_turret_ring.scale.z = TURRET_RADIUS * 2.0
	for mesh: MeshInstance3D in (
		ghost.find_children("*", "MeshInstance3D", true, false)
	):
		mesh.material_override = player_ghost
	for shadow: Sprite3D in (
		ghost.find_children("Shadow", "Sprite3D", true, false)
	):
		shadow.visible = false

	start_enemy_spawn_loop()
	start_energy_loop()
	start_science_loop()
	spawn_all_uranium()

	tutorial_popup_button.pressed.connect(func() -> void:
		Util.play_sound(self, tick_sound)

		tutorial_popup.visible = false
		if (
			tutorial_step == TutorialStep.ENERGY
			or tutorial_step == TutorialStep.SCIENCE
		):
			await get_tree().create_timer(3.0).timeout
			go_to_next_tutorial_step()
	)
	go_to_next_tutorial_step()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var e := event as InputEventMouseMotion
		tooltip.position.x = e.position.x
		tooltip.position.y = e.position.y
		# Don't show tooltip until now because we don't want it to appear at a
		# weird location
		tooltip.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		return
	if event as InputEventKey:
		var e := event as InputEventKey
		if e.pressed:
			match e.keycode:
				KEY_1:
					select_building_type(BuildingType.TURRET)
				KEY_2:
					select_building_type(BuildingType.WALL)
				KEY_3:
					select_building_type(BuildingType.MINE)
				KEY_4:
					select_building_type(BuildingType.LAB)


func _on_ground_input_event(
	_camera: Camera3D,
	event: InputEvent,
	event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if is_game_over:
		return
	mouse_position_3d = Vector3(event_position.x, 0.0, event_position.z)
	var grid_coord := Vector2i(
		roundi(mouse_position_3d.x),
		roundi(mouse_position_3d.z)
	)

	var me := event as InputEventMouseButton
	if me and me.is_pressed() and me.button_index == MOUSE_BUTTON_LEFT:
		if can_place_building():
			var building_cost: int = BUILDING_ENERGY_COST[building_type]
			set_energy(energy - building_cost)
			var building_scene := (
				turret_scene if building_type == BuildingType.TURRET
				else wall_scene if building_type == BuildingType.WALL
				else lab_scene if building_type == BuildingType.LAB
				else mine_scene
			)

			var building := building_scene.instantiate() as Node3D
			building.position = Vector3(
				roundi(mouse_position_3d.x),
				0.0,
				roundi(mouse_position_3d.z)
			)

			building_fall_direction[building] = Vector2(
				randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)
			).normalized()

			grid_to_building[grid_coord] = building

			is_alive[building] = true

			grid_to_building_completion_proportion[grid_coord] = 0.0
			for mesh: MeshInstance3D in (
				building.find_children("*", "MeshInstance3D", true, false)
			):
				mesh.material_override = player_transparent
			buildings.add_child(building)

			add_audio_stream_player(building)
			var player: AudioStreamPlayer3D = audio_stream_players[building]
			player.bus = "BuildingProgress"
			var asp: AudioStreamPlaybackPolyphonic = audio_playbacks[building]
			asp.play_stream(building_placed_sound)
			grid_to_building_completion_stream_id[grid_coord] = (
				asp.play_stream(building_progress_sound)
			)

			match building_type:
				BuildingType.TURRET:
					var visibility_ring := (
						launchpad_visibility_ring.duplicate() as Node3D
					)
					visibility_ring.position = building.position
					fog_of_war.add_child(visibility_ring)
					grid_to_visibility_ring[grid_coord] = visibility_ring

					if tutorial_step == TutorialStep.TURRET:
						go_to_next_tutorial_step()
				BuildingType.WALL:
					if tutorial_step == TutorialStep.WALL:
						go_to_next_tutorial_step()
				BuildingType.MINE:
					if tutorial_step == TutorialStep.MINE:
						go_to_next_tutorial_step()
				BuildingType.LAB:
					if tutorial_step == TutorialStep.LAB:
						go_to_next_tutorial_step()
		elif can_sell_building():
				Util.play_sound(self, sell_sound)
				set_energy(energy + get_sell_value())
				erase_building(grid_coord)
		else:
			Util.play_sound(self, building_place_failed_sound)


func _process(delta: float) -> void:
	process_tooltip()
	process_ghost()
	process_camera_wasd(delta)
	process_warning_label()
	process_rocket(delta)
	energy_delta_label.text = "%+d energy" % get_energy_gain()
	science_delta_label.text = "%+d science" % get_science_gain()
	for enemy: Node3D in enemies.get_children():
		process_enemy(enemy, delta)
	for grid_coord: Vector2i in grid_to_building:
		process_building(grid_coord, delta)


func add_tracer(turret: Node3D, enemy: Node3D) -> void:
	var tracer := tracer_scene.instantiate() as Node3D
	add_child(tracer)
	tracer.position = turret.position
	tracer.position.y += 0.855
	tracer.look_at(enemy.position, Vector3.UP, true)
	tracer.scale.z = tracer.position.distance_to(enemy.position)
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		tracer.queue_free()
	)


func get_time() -> float:
	return Time.get_ticks_msec() / 1000.0


func start_enemy_spawn_loop() -> void:
	await get_tree().create_timer(DURATION_BEFORE_FIRST_WAVE).timeout
	var wave_index := 0
	while true:
		enemy_spawn_position = random_enemy_spawn_position()
		warning_label.visible = true
		if not is_game_over:
			Util.play_sound(self, warning_sound)

		var enemy_count := roundi(0.6 * pow(wave_index, 1.5) + 2.0)
		for i in enemy_count:
			var enemy := enemy_scene.instantiate() as Node3D
			enemy.position = Vector3(
				enemy_spawn_position.x + randf_range(-4.0, 4.0),
				0.0,
				enemy_spawn_position.z + randf_range(-4.0, 3.0),
			)
			enemies.add_child(enemy)
			enemies_alive += 1
		wave_index += 1

		await get_tree().create_timer(60.0).timeout


func start_energy_loop() -> void:
	while true:
		if is_game_over:
			return
		set_energy(energy + get_energy_gain())
		await get_tree().create_timer(1.0).timeout


func get_energy_gain() -> int:
	var delta_energy := CONSTANT_ENERGY_GAIN
	for grid_coord: Vector2i in grid_to_building:
		if (
			grid_to_building_completion_proportion[grid_coord] == 1.0
			and is_alive[grid_to_building[grid_coord]]
		):
			if (
				grid_to_building[grid_coord] is Mine
			):
				delta_energy += ENERGY_GAIN_PER_MINE
			elif (
				grid_to_building[grid_coord] is Turret
			):
				delta_energy -= TURRET_DRAIN_PER_SECOND
	return delta_energy


func start_science_loop() -> void:
	while true:
		if is_game_over:
			return
		set_science(science + get_science_gain())
		await get_tree().create_timer(1.0).timeout


func get_science_gain() -> int:
	var gain := 0
	for grid_coord: Vector2i in grid_to_building:
		if (
			grid_to_building[grid_coord] is Lab
			and grid_to_building_completion_proportion[grid_coord] == 1.0
			and is_alive[grid_to_building[grid_coord]]
		):
			gain += 1
	return gain


func set_energy(new_energy: int) -> void:
	energy = new_energy
	energy_label.text = "Energy: %s" % energy


func set_science(new_science: int) -> void:
	science = new_science
	science_label.text = "Science: %s" % science
	var remaining := maxi(0, SCIENCE_REQUIRED_TO_LAUNCH - new_science)
	if remaining == 0:
		play_game_over_sequence(GameResult.WON)


func process_tooltip() -> void:
	if is_game_over:
		return
	if turret_button.is_hovered():
		tooltip_label.text = get_label_text_for_building(BuildingType.TURRET)
	elif wall_button.is_hovered():
		tooltip_label.text = get_label_text_for_building(BuildingType.WALL)
	elif mine_button.is_hovered():
		tooltip_label.text = get_label_text_for_building(BuildingType.MINE)
	elif lab_button.is_hovered():
		tooltip_label.text = get_label_text_for_building(BuildingType.LAB)
	elif no_building_type_selected:
		tooltip_label.text = ""
	elif can_place_building():
		tooltip_label.text = get_label_text_for_building(building_type)
	elif can_sell_building():
		tooltip_label.text = "Sell for +%s energy" % get_sell_value()
	else:
		tooltip_label.text = "%s" % get_invalid_building_placement_reason()


func get_label_text_for_building(t: BuildingType) -> String:
	var cost: String = "Build for -%s energy" % BUILDING_ENERGY_COST[t]
	var turret_energy := (
		"Drains -%s energy per second" % TURRET_DRAIN_PER_SECOND
	)
	var mine_energy := (
		"Gains %s energy per second" % ENERGY_GAIN_PER_MINE
	)
	var lab_science := (
		"Gains %s science per second" % SCINECE_GAIN_PER_LAB
	)
	match t:
		BuildingType.TURRET:
			return "Shoots enemies\n%s\n%s" % [cost, turret_energy]
		BuildingType.WALL:
			return cost
		BuildingType.MINE:
			return "%s\n%s" % [cost, mine_energy]
		BuildingType.LAB:
			return "%s\n%s" % [cost, lab_science]
	return ""


func process_ghost() -> void:
	if is_game_over:
		return
	ghost.position = Vector3(
		roundi(mouse_position_3d.x),
		0.0,
		roundi(mouse_position_3d.z)
	)
	ghost_turret_ring.visible = can_place_building()
	player_ghost.albedo_color = (
		GHOST_VALID if can_place_building() else GHOST_INVALID
	)
	var min_s := 0.1
	var max_s := GHOST_VALID.s
	# t varies between 0 and 1 over time
	var t := (0.5 + 0.5 * sin(4.0 * get_time()))
	player_ghost.albedo_color.s = min_s + t * (max_s - min_s)


func can_place_building() -> bool:
	return get_invalid_building_placement_reason() == ""


func get_invalid_building_placement_reason() -> String:
	var grid_coord := Vector2i(
		roundi(mouse_position_3d.x),
		roundi(mouse_position_3d.z)
	)
	var building_cost: int = BUILDING_ENERGY_COST[building_type]
	var has_nearby_building := false
	for v: Vector2i in [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1)
	]:
		var c := v + grid_coord
		if (
			c in grid_to_building
			and grid_to_building_completion_proportion[c] == 1.0
			and is_alive[grid_to_building[c]]
		):
			has_nearby_building = true
			break
	if building_type == BuildingType.MINE and not grid_coord in grid_to_uranium:
		return "can only place mine on uranium"
	if building_type != BuildingType.MINE and grid_coord in grid_to_uranium:
		return "can't place this building on uranium"
	if energy < building_cost:
		return "not enough energy to afford this"
	if not has_nearby_building:
		return "can only place building near another building"
	if grid_coord in grid_to_building:
		return "can't place building on top of another building"
	if no_building_type_selected:
		return "select building"
	# Placement must be valid
	return ""


func can_sell_building() -> bool:
	var grid_coord := Vector2i(
		roundi(mouse_position_3d.x),
		roundi(mouse_position_3d.z)
	)
	return (
		grid_coord in grid_to_building
		and grid_coord != Vector2i(0, 0)
		and grid_to_building_completion_proportion[grid_coord] == 1.0
		and is_alive[grid_to_building[grid_coord]]
	)


# Errors if can_sell_building() is false
func get_sell_value() -> int:
	assert(can_sell_building())
	var grid_coord := Vector2i(
		roundi(mouse_position_3d.x),
		roundi(mouse_position_3d.z)
	)
	if grid_to_building[grid_coord] is Turret:
		return BUILDING_ENERGY_SELL_VALUE[BuildingType.TURRET]
	if grid_to_building[grid_coord] is Wall:
		return BUILDING_ENERGY_SELL_VALUE[BuildingType.WALL]
	if grid_to_building[grid_coord] is Mine:
		return BUILDING_ENERGY_SELL_VALUE[BuildingType.MINE]
	if grid_to_building[grid_coord] is Lab:
		return BUILDING_ENERGY_SELL_VALUE[BuildingType.LAB]
	push_error("Invalid state")
	return 0


func process_camera_wasd(delta: float) -> void:
	if is_game_over:
		return
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		camera.position -= camera.basis.x * delta * CAMERA_SPEED
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		camera.position += camera.basis.x * delta * CAMERA_SPEED
	var up_direction := -Vector3(
		camera.basis.z.x,
		0,
		camera.basis.z.z
	).normalized()
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		camera.position += up_direction * delta * CAMERA_SPEED
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		camera.position -= up_direction * delta * CAMERA_SPEED


func random_enemy_spawn_position() -> Vector3:
	var min_x := 0.0
	var max_x := 0.0
	var min_z := 0.0
	var max_z := 0.0
	for grid_coord: Vector2i in grid_to_building:
		var building: Node3D = grid_to_building[grid_coord]
		min_x = minf(min_x, building.position.x)
		max_x = maxf(min_x, building.position.x)
		min_z = minf(min_z, building.position.z)
		max_z = maxf(min_z, building.position.z)
	match randi_range(0, 2):
		0: # Top
			return Vector3(
				randf_range(min_x, max_x),
				0.0,
				min_z - ENEMY_SPAWN_DISTANCE_FROM_PLAYER
			)
		1: # Left
			return Vector3(
				min_x - ENEMY_SPAWN_DISTANCE_FROM_PLAYER,
				0.0,
				randf_range(min_z, max_z)
			)
		2: # Right
			return Vector3(
				max_x + ENEMY_SPAWN_DISTANCE_FROM_PLAYER,
				0.0,
				randf_range(min_z, max_z)
			)
	push_error("Impossible state")
	return Vector3.ZERO


func process_warning_label() -> void:
	if is_game_over:
		return
	warning_label.modulate.a = fmod(get_time(), 1.0)

	var camera_focal_point := camera.position - camera_offset
	var dir := camera_focal_point.direction_to(enemy_spawn_position)
	var viewport_center := get_viewport().get_visible_rect().get_center()
	warning_label.position = viewport_center + 10000.0 * Vector2(dir.x, dir.z)
	var viewport_size := get_viewport().get_visible_rect().size
	if warning_label.position.x < 0.0:
		warning_label.position.x = 0.0
	if warning_label.position.x + warning_label.size.x > viewport_size.x:
		warning_label.position.x = viewport_size.x - warning_label.size.x
	if warning_label.position.y < 0.0:
		warning_label.position.y = 0.0
	if warning_label.position.y > viewport_size.y:
		warning_label.position.y = viewport_size.y - warning_label.size.y
	# GUI sits on left of screen so don't want to overlap it
	warning_label.position.x = maxf(
		hud_background.size.x, warning_label.position.x
	)

	if enemies_alive == 0:
		warning_label.visible = false


func erase_building(grid_coord: Vector2i) -> void:
	var building: Node3D = grid_to_building[grid_coord]
	building.queue_free()
	grid_to_building.erase(grid_coord)
	building_fall_direction.erase(grid_coord)

	is_alive.erase(building)

	audio_playbacks.erase(building)

	if grid_coord in grid_to_visibility_ring:
		var visibility_ring: Node3D = grid_to_visibility_ring[grid_coord]
		visibility_ring.queue_free()
		grid_to_visibility_ring.erase(grid_coord)

	grid_to_building_completion_proportion.erase(grid_coord)

	if grid_coord in grid_to_building_completion_stream_id:
		grid_to_building_completion_stream_id.erase(grid_coord)
	
	if grid_coord == Vector2i(0, 0) and not is_rocket_taking_off:
			rocket.queue_free()
			audio_playbacks.erase(rocket)


func hide_ghost_children() -> void:
	for child: Node3D in ghost.get_children():
		child.visible = false


func process_building(grid_coord: Vector2i, delta: float) -> void:
	var building: Node3D = grid_to_building[grid_coord]
	if not is_alive[building]:
		building.position.y -= delta * 0.5
		building.rotation.x -= (
			building_fall_direction[building].x * delta * 0.2
		)
		building.rotation.z -= (
			building_fall_direction[building].y * delta * 0.2
		)
		return
	var asp: AudioStreamPlaybackPolyphonic = audio_playbacks[building]
	var gcp := grid_to_building_completion_proportion
	if gcp[grid_coord] < 1.0:
		gcp[grid_coord] += delta / BUILDING_COMPLETION_DURATION
		if gcp[grid_coord] >= 1.0:
			gcp[grid_coord] = 1.0
			asp.play_stream(building_completed_sound)
			var stream_id: int = (
				grid_to_building_completion_stream_id[grid_coord]
			)
			asp.stop_stream(stream_id)
			for mesh: MeshInstance3D in (
				building.find_children("*", "MeshInstance3D", true, false)
			):
				mesh.material_override = null
	building.position.y = -0.4 + gcp[grid_coord] * 0.4
	if building is Turret and gcp[grid_coord] == 1.0:
		var turret := building as Turret
		if enemies.get_children().is_empty():
			return
		var nearest_enemy: Node3D = null
		for enemy: Node3D in enemies.get_children():
			if (
				not nearest_enemy
				or turret.position.distance_to(enemy.position)
					< turret.position.distance_to(nearest_enemy.position)
			):
				nearest_enemy = enemy
		if (
			get_time() - turret.last_fired_at > TURRET_SHOOT_COOLDOWN
			and (
				nearest_enemy.position.distance_to(turret.position)
				< TURRET_RADIUS
			)
		):
			turret.last_fired_at = get_time()

			add_tracer(turret, nearest_enemy)

			kill_enemy(nearest_enemy)

			var gun := turret.find_child("Gun") as Node3D
			gun.look_at(nearest_enemy.position, Vector3.UP, true)

			var stream: AudioStream = laser_sounds.pick_random()
			asp.play_stream(stream)


func process_rocket(delta: float) -> void:
	if is_rocket_taking_off:
		rocket.position.y += delta * (rocket.position.y + 1.0) / 10.0
		camera.look_at(rocket.position)


func process_enemy(enemy: Node3D, delta: float) -> void:
	var valid_targets := [] as Array[Vector2i]
	for grid_coord: Vector2i in grid_to_building:
		if (
			grid_to_building_completion_proportion[grid_coord] == 1.0
			and is_alive[grid_to_building[grid_coord]]
		):
			valid_targets.append(grid_coord)

	if valid_targets.is_empty():
		return

	var nearest_grid_coord := valid_targets[0]
	for grid_coord: Vector2i in valid_targets:
		var a: Node3D = grid_to_building[grid_coord]
		var b: Node3D = grid_to_building[nearest_grid_coord]
		if (
			enemy.position.distance_to(a.position)
			<= enemy.position.distance_to(b.position)
		):
			nearest_grid_coord = grid_coord
	var target: Node3D = grid_to_building[nearest_grid_coord]

	enemy.look_at(target.position, Vector3.UP, true)
	enemy.position += enemy.basis.z * delta * ENEMY_SPEED
	if enemy.position.distance_to(target.position) < 1.0:
		kill_enemy(enemy)

		is_alive[target] = false

		if nearest_grid_coord == Vector2i(0, 0) and not is_rocket_taking_off:
			rocket.reparent(launchpad)
			play_game_over_sequence(GameResult.LOST)

		var smoke := (
			building_destroyed_smoke_scene.instantiate() as GPUParticles3D
		)
		smoke.position = target.position
		add_child(smoke)
		smoke.emitting = true
		get_tree().create_timer(smoke.lifetime) \
			.timeout.connect(smoke.queue_free.bind())

		var ap: AudioStreamPlaybackPolyphonic = (
			audio_playbacks[target]
		)
		ap.play_stream(building_destroyed_sound)
		(
			get_tree().create_timer(building_destroyed_sound.get_length())
		).timeout.connect(func() -> void:
			erase_building(nearest_grid_coord)
		)


func play_game_over_sequence(game_result: GameResult) -> void:
	var w := game_result == GameResult.WON
	if w:
		is_rocket_taking_off = true
		rocket_shadow.visible = false
		var ap: AudioStreamPlaybackPolyphonic = audio_playbacks[rocket]
		ap.play_stream(rocket_thrust_sound)

		var rocket_effects := rocket.find_child("Effects", true, false) as Node3D
		rocket_effects.visible = true
		for effect: Node3D in rocket_effects.get_children():
			if effect is GPUParticles3D:
				var g := effect as GPUParticles3D
				g.emitting = true
	else:
		Util.play_sound(self, explosion_sound)
	is_game_over = true
	hud.visible = false
	cinematic_bars.visible = true
	ghost.visible = false
	camera.position = camera_offset
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	Input.set_custom_mouse_cursor(blank_cursor)

	await get_tree().create_timer(30.0 if w else 3.0).timeout

	Input.set_custom_mouse_cursor(null)
	if w:
		won.emit()
	else:
		lost.emit()


func add_uranium(grid_coord: Vector2i) -> void:
	var uranium := uranium_scene.instantiate() as Node3D
	uranium.position.x = grid_coord.x
	uranium.position.z = grid_coord.y
	uranium.rotation.y = randf() * TAU
	add_child(uranium)
	grid_to_uranium[grid_coord] = uranium


func spawn_all_uranium() -> void:
	var next_to_launchpad: Vector2i = [
		Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
	].pick_random()
	add_uranium(next_to_launchpad)
	for i in 3:
		var arr: Array[int] = [-5, -4, -3, -2, 2, 3, 4, 5]
		var row: int = arr.pick_random()
		var col: int = arr.pick_random()
		add_uranium(Vector2i(row, col))
	for row in (
		range(-MAX_URANIUM_SPAWN_DISTANCE, MAX_URANIUM_SPAWN_DISTANCE)
	):
		for col in (
			range(-MAX_URANIUM_SPAWN_DISTANCE, MAX_URANIUM_SPAWN_DISTANCE)
		):
			var close_to_launchpad := (
				row > -7 and row < 7 and col > -7 and col < 7
			)
			if randf() < 0.03 and not close_to_launchpad:
				add_uranium(Vector2i(row, col))


func select_building_type(t: BuildingType) -> void:
	Util.play_sound(self, tick_sound)

	ghost.visible = true
	no_building_type_selected = false
	building_type = t
	hide_ghost_children()
	turret_button.disabled = false
	wall_button.disabled = false
	mine_button.disabled = false
	lab_button.disabled = false
	match t:
		BuildingType.TURRET:
			ghost_turret.visible = true
			turret_button.disabled = true
		BuildingType.WALL:
			ghost_wall.visible = true
			wall_button.disabled = true
		BuildingType.MINE:
			ghost_mine.visible = true
			mine_button.disabled = true
		BuildingType.LAB:
			ghost_lab.visible = true
			lab_button.disabled = true


func go_to_next_tutorial_step() -> void:
	tutorial_popup.visible = false
	await get_tree().create_timer(2.0).timeout
	tutorial_step = mini(tutorial_step + 1, TutorialStep.END) as TutorialStep
	if tutorial_step == TutorialStep.END:
		return

	# Can happen if the player builds things in an order that does not match the
	# tutorial build order
	if (
		(
			tutorial_step == TutorialStep.TURRET
			and building_exists(BuildingType.TURRET)
		)
		or (
			tutorial_step == TutorialStep.WALL
			and building_exists(BuildingType.WALL)
		)
		or (
			tutorial_step == TutorialStep.MINE
			and building_exists(BuildingType.MINE)
		)
		or (
			tutorial_step == TutorialStep.LAB
			and building_exists(BuildingType.LAB)
		)
	):
		go_to_next_tutorial_step()
		return

	tutorial_popup_label.text = TUTORIAL_TEXT_FOR_STEP[tutorial_step]
	tutorial_popup.position.y = TUTORIAL_POPUP_Y_FOR_STEP[tutorial_step]
	tutorial_popup.visible = true


func building_exists(t: BuildingType) -> bool:
	for grid_coord: Vector2i in grid_to_building:
		var b: Node3D = grid_to_building[grid_coord]
		if (
			b is Turret and t == BuildingType.TURRET
			or b is Wall and t == BuildingType.WALL
			or b is Mine and t == BuildingType.MINE
			or b is Lab and t == BuildingType.LAB
		):
			return true
	return false


func add_audio_stream_player(node: Node3D) -> void:
	var asp := AudioStreamPlayer3D.new() 
	var stream := AudioStreamPolyphonic.new() 
	asp.stream = stream
	node.add_child(asp)
	asp.play()
	audio_playbacks[node] = asp.get_stream_playback()
	audio_stream_players[node] = asp


func kill_enemy(enemy: Node3D) -> void:
	enemy.queue_free()
	enemies_alive -= 1

	var asp := AudioStreamPlayer3D.new()
	asp.position = enemy.position
	add_child(asp)

	asp.stream = enemy_destroyed_sound
	asp.play()
	asp.finished.connect(func() -> void:
		asp.queue_free()
	)

	var explosion := enemy_explosion_scene.instantiate() as Node3D
	explosion.position = enemy.position
	var max_lifetime := 0.0
	for child: GPUParticles3D in explosion.get_children():
		max_lifetime = maxf(max_lifetime, child.lifetime)
		child.emitting = true

	get_tree().create_timer(max_lifetime * 2.0).timeout.connect(
		func() -> void: explosion.queue_free()
	)
	add_child(explosion)
