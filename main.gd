# TODO: if i restrict the camera position, maybe don't need the camera view box
class_name Main extends Node3D

const ENEMY_SPAWN_DISTANCE_FROM_PLAYER := 20.0
const CAMERA_SPEED := 7.0
const TURRET_RADIUS := 6.0
enum BuildingType {TURRET, WALL, MINE, INVALID}
const BUILDING_ENERGY_COST = {
	BuildingType.TURRET: 10,
	BuildingType.WALL: 2,
	BuildingType.MINE: 10,
}
const BUILDING_ENERGY_SELL_VALUE = {
	BuildingType.TURRET: 5,
	BuildingType.WALL: 1,
	BuildingType.MINE: 5,
}
var turret_scene := preload("res://turret.tscn")
var wall_scene := preload("res://wall.tscn")
var enemy_scene := preload("res://enemy.tscn")
var tracer_scene := preload("res://tracer.tscn")
var uranium_scene := preload("res://uranium.tscn")
var mine_scene := preload("res://mine.tscn")
var player_transparent := preload("res://player_transparent.tres")
@onready var ground := $Ground as Area3D
@onready var ghost := $Ghost as Node3D
@onready var ghost_turret := $Ghost/Turret as Node3D
@onready var ghost_turret_ring := $Ghost/Turret/Ring as Node3D
@onready var ghost_wall := $Ghost/Wall as Node3D
@onready var ghost_mine := $Ghost/Mine as Node3D
@onready var launchpad := $Buildings/Launchpad as Node3D
@onready var enemies := $Enemies as Node
@onready var buildings := $Buildings as Node
@onready var energy_label := $UI/EnergyLabel as Label
@onready var tooltip_label := $UI/TooltipLabel as Label
@onready var warning_label := $UI/WarningLabel as Control
@onready var camera := $Camera3D as Camera3D
@onready var camera_view_box := $Camera3D/Area3D as Area3D
@onready var enemy_spawn_point := $EnemySpawnPoint as Area3D
@onready var fog_of_war := $FogOfWar as Node3D
@onready var launchpad_visibility_ring := $FogOfWar/VisibilityRing as Node3D
var mouse_position_3d := Vector3.ZERO
var building_type := BuildingType.TURRET
var grid_to_building := {} # Dictionary[Vector2i, Node3D]
var grid_to_uranium := {} # Dictionary[Vector2i, Node3D]
var grid_to_visibility_ring := {} # Dictionary[Vector2i, Node3D]
var energy := 30
var camera_offset := Vector3.ZERO


func _ready() -> void:
	camera_offset = camera.position
	grid_to_building[Vector2i(0, 0)] = launchpad
	ground.input_event.connect(_on_ground_input_event)

	ghost_turret_ring.scale.x = TURRET_RADIUS * 2.0
	ghost_turret_ring.scale.z = TURRET_RADIUS * 2.0
	var ghost_meshes := ghost.find_children("*", "MeshInstance3D", true, false)
	for mesh: MeshInstance3D in ghost_meshes:
		mesh.material_override = player_transparent

	start_enemy_spawn_loop()
	start_energy_loop()
	for row in range(-1000, 1000):
		for col in range(-1000, 1000):
			if randf() < 0.03 and (row != 0 or col != 0):
				var uranium := uranium_scene.instantiate() as Node3D
				uranium.position.x = row
				uranium.position.z = col
				add_child(uranium)
				grid_to_uranium[Vector2i(row, col)] = uranium



func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var e := event as InputEventMouseMotion
		tooltip_label.position.x = e.position.x
		tooltip_label.position.y = e.position.y


func _unhandled_input(event: InputEvent) -> void:
	if event as InputEventKey:
		var e := event as InputEventKey
		if e.pressed:
			match e.keycode:
				KEY_1:
					building_type = BuildingType.TURRET
					hide_ghost_children()
					ghost_turret.visible = true
				KEY_2:
					building_type = BuildingType.WALL
					hide_ghost_children()
					ghost_wall.visible = true
				KEY_3:
					building_type = BuildingType.MINE
					hide_ghost_children()
					ghost_mine.visible = true
				KEY_ESCAPE:
					get_tree().quit()


func _on_ground_input_event(
	_camera: Camera3D,
	event: InputEvent,
	event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	mouse_position_3d = Vector3(event_position.x, 0.0, event_position.z)
	var grid_coord := Vector2i(
		roundi(mouse_position_3d.x),
		roundi(mouse_position_3d.z)
	)

	if event.is_pressed():
		if can_place_building():
				var building_cost: int = BUILDING_ENERGY_COST[building_type]
				set_energy(energy - building_cost)
				var building_scene := (
					turret_scene if building_type == BuildingType.TURRET
					else wall_scene if building_type == BuildingType.WALL
					else mine_scene
				)
				var building := building_scene.instantiate() as Node3D
				building.position = Vector3(
					roundi(mouse_position_3d.x),
					0.0,
					roundi(mouse_position_3d.z)
				)
				grid_to_building[grid_coord] = building
				buildings.add_child(building)

				var visibility_ring := (
					launchpad_visibility_ring.duplicate() as Node3D
				)
				visibility_ring.position = building.position
				fog_of_war.add_child(visibility_ring)
				grid_to_visibility_ring[grid_coord] = visibility_ring
		elif can_sell_building():
				set_energy(energy + get_sell_value())
				erase_building(grid_coord)


func _process(delta: float) -> void:
	process_tooltip()
	process_ghost()
	process_camera(delta)
	process_warning_label()
	for enemy: Node3D in enemies.get_children():
		if grid_to_building.is_empty():
			continue
		var grid_coord := get_nearest_building(enemy.position)
		var nearest_building: Node3D = grid_to_building[grid_coord]
		enemy.look_at(nearest_building.position, Vector3.UP, true)
		enemy.position += enemy.basis.z * delta * 1.0
		if enemy.position.distance_to(nearest_building.position) < 1.0:
			enemy.queue_free()
			erase_building(grid_coord)
	for grid_coord: Vector2i in grid_to_building:
		var building: Node3D = grid_to_building[grid_coord]
		if building is Turret:
			var turret := building as Turret
			if enemies.get_children().is_empty():
				continue
			var nearest_enemy: Node3D = null
			for enemy: Node3D in enemies.get_children():
				if (
					not nearest_enemy
					or turret.position.distance_to(enemy.position)
						< turret.position.distance_to(nearest_enemy.position)
				):
					nearest_enemy = enemy
			if (
				get_time() - turret.last_fired_at > 2.0
				and (
					nearest_enemy.position.distance_to(turret.position)
					< TURRET_RADIUS
				)
			):
				turret.last_fired_at = get_time()
				add_tracer(turret, nearest_enemy)
				nearest_enemy.queue_free()
				var gun := turret.find_child("Gun") as Node3D
				gun.look_at(nearest_enemy.position, Vector3.UP, true)


func add_tracer(turret: Node3D, enemy: Node3D) -> void:
	var tracer := tracer_scene.instantiate() as Node3D
	add_child(tracer)
	tracer.position = turret.position
	tracer.look_at(enemy.position, Vector3.UP, true)
	tracer.scale.z = tracer.position.distance_to(enemy.position)
	get_tree().create_timer(0.1).timeout.connect(func() -> void:
		tracer.queue_free()
	)


func get_nearest_building(pos: Vector3) -> Vector2i:
	assert(!grid_to_building.is_empty())
	var nearest_grid_coord: Vector2i = grid_to_building.keys()[0]
	for grid_coord: Vector2i in grid_to_building:
		var a: Node3D = grid_to_building[grid_coord]
		var b: Node3D = grid_to_building[nearest_grid_coord]
		if pos.distance_to(a.position) < pos.distance_to(b.position):
			nearest_grid_coord = grid_coord
	return nearest_grid_coord


func get_time() -> float:
	return Time.get_ticks_msec() / 1000.0


func start_enemy_spawn_loop() -> void:
	await get_tree().create_timer(2.0).timeout
	var enemies_per_wave := 1.0
	while true:
		enemy_spawn_point.position = get_random_enemy_cluster_position()

		warning_label.visible = true
		get_tree().create_timer(5.0).timeout.connect(func() -> void:
			warning_label.visible = false
		)

		for i in floori(enemies_per_wave):
			var enemy := enemy_scene.instantiate() as Node3D
			enemy.position = Vector3(
				enemy_spawn_point.position.x + randf_range(-3.0, 3.0),
				0.0,
				enemy_spawn_point.position.z + randf_range(-3.0, 3.0),
			)
			enemies.add_child(enemy)
		enemies_per_wave *= 2

		await get_tree().create_timer(10.0).timeout


func start_energy_loop() -> void:
	while true:
		set_energy(energy + 1)
		for building in buildings.get_children():
			if building is Mine:
				set_energy(energy + 1)
		await get_tree().create_timer(1.0).timeout


func set_energy(new_energy: int) -> void:
	energy = new_energy
	energy_label.text = "Energy: %s" % energy


func process_tooltip() -> void:
	if can_place_building():
		var building_cost: int = BUILDING_ENERGY_COST[building_type]
		tooltip_label.text = "Build for -%s energy" % building_cost
		tooltip_label.visible = true
	elif can_sell_building():
		tooltip_label.text = "Sell for +%s energy" % get_sell_value()
		tooltip_label.visible = true
	else:
		tooltip_label.visible = false


func process_ghost() -> void:
	ghost.position = Vector3(
		roundi(mouse_position_3d.x),
		0.0,
		roundi(mouse_position_3d.z)
	)
	ghost.visible = can_place_building()


func can_place_building() -> bool:
	var grid_coord := Vector2i(
		roundi(mouse_position_3d.x),
		roundi(mouse_position_3d.z)
	)
	var building_cost: int = BUILDING_ENERGY_COST[building_type]
	return (
		(
			building_type == BuildingType.MINE and grid_coord in grid_to_uranium
			or (
				building_type != BuildingType.MINE
				and grid_coord not in grid_to_building
				and grid_coord not in grid_to_uranium
			)
		)
		and energy >= building_cost
	)


func can_sell_building() -> bool:
	var grid_coord := Vector2i(
		roundi(mouse_position_3d.x),
		roundi(mouse_position_3d.z)
	)
	return (
		grid_coord in grid_to_building and grid_coord != Vector2i(0, 0)
	)


func get_sell_value() -> int:
	var grid_coord := Vector2i(
		roundi(mouse_position_3d.x),
		roundi(mouse_position_3d.z)
	)
	var building_under_mouse_type := (
		BuildingType.TURRET if grid_to_building[grid_coord] is Turret
		else BuildingType.WALL if grid_to_building[grid_coord] is Wall
		else BuildingType.MINE if grid_to_building[grid_coord] is Mine
		else BuildingType.INVALID
	)
	assert(building_under_mouse_type != BuildingType.INVALID)
	return BUILDING_ENERGY_SELL_VALUE[building_under_mouse_type]


func process_camera(delta: float) -> void:
	if Input.is_key_pressed(KEY_A):
		camera.position -= camera.basis.x * delta * CAMERA_SPEED
	if Input.is_key_pressed(KEY_D):
		camera.position += camera.basis.x * delta * CAMERA_SPEED
	var up_direction := -Vector3(
		camera.basis.z.x,
		0,
		camera.basis.z.z
	).normalized()
	if Input.is_key_pressed(KEY_W):
		camera.position += up_direction * delta * CAMERA_SPEED
	if Input.is_key_pressed(KEY_S):
		camera.position -= up_direction * delta * CAMERA_SPEED


func get_random_enemy_cluster_position() -> Vector3:
	var min_x := 0.0
	var max_x := 0.0
	var min_z := 0.0
	var max_z := 0.0
	for building: Node3D in buildings.get_children():
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
	warning_label.modulate.a = fmod(get_time(), 1.0)

	var camera_focal_point := camera.position - camera_offset
	var dir := camera_focal_point.direction_to(enemy_spawn_point.position)
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

	if enemy_spawn_point.get_overlapping_areas().has(camera_view_box):
		warning_label.visible = false


func erase_building(grid_coord: Vector2i) -> void:
	var building: Node3D = grid_to_building[grid_coord]
	building.queue_free()
	grid_to_building.erase(grid_coord)
	grid_to_visibility_ring.erase(grid_coord)


func hide_ghost_children() -> void:
	for child: Node3D in ghost.get_children():
		child.visible = false
