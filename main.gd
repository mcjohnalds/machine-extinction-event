class_name Main extends Node3D

const ENEMY_SPAWN_DISTANCE_FROM_PLAYER := 15.0
const CAMERA_SPEED = 7.0
const TURRET_RADIUS = 7.0
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
@onready var launchpad := $Buildings/Launchpad as Node3D
@onready var enemies := $Enemies as Node
@onready var buildings := $Buildings as Node
@onready var energy_label := %EnergyLabel as Label
@onready var tooltip_label := %TooltipLabel as Label
@onready var camera := $Camera3D as Camera3D
var mouse_position_3d := Vector3.ZERO
var building_type := BuildingType.TURRET
var grid_to_building := {} # Dictionary[Vector2i, Node3D]
var grid_to_uranium := {} # Dictionary[Vector2i, Node3D]
var energy := 30


func _ready() -> void:
	grid_to_building[Vector2i(0, 0)] = launchpad
	ground.input_event.connect(_on_ground_input_event)
	ghost.add_child(turret_scene.instantiate())
	make_ghost_transparent()
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
					ghost.get_child(0).queue_free()
					ghost.add_child(turret_scene.instantiate())
				KEY_2:
					building_type = BuildingType.WALL
					ghost.get_child(0).queue_free()
					ghost.add_child(wall_scene.instantiate())
				KEY_3:
					building_type = BuildingType.MINE
					ghost.get_child(0).queue_free()
					ghost.add_child(mine_scene.instantiate())
				KEY_ESCAPE:
					get_tree().quit()
			make_ghost_transparent()


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
		elif can_sell_building():
				set_energy(energy + get_sell_value())
				var building: Node3D = grid_to_building[grid_coord]
				building.queue_free()
				grid_to_building.erase(grid_coord)


func _process(delta: float) -> void:
	update_tooltip()
	update_ghost()
	update_camera(delta)
	for enemy: Node3D in enemies.get_children():
		if grid_to_building.is_empty():
			continue
		var grid_coord := get_nearest_building(enemy.position)
		var nearest_building: Node3D = grid_to_building[grid_coord]
		enemy.look_at(nearest_building.position, Vector3.UP, true)
		enemy.position += enemy.basis.z * delta * 1.0
		if enemy.position.distance_to(nearest_building.position) < 1.0:
			nearest_building.queue_free()
			enemy.queue_free()
			grid_to_building.erase(grid_coord)
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


func make_ghost_transparent() -> void:
	var meshes := ghost.find_children("*", "MeshInstance3D", true, false)
	for mesh: MeshInstance3D in meshes:
		mesh.material_override = player_transparent


func start_enemy_spawn_loop() -> void:
	var enemies_per_wave := 1.0
	while true:
		var min_x := 0.0
		var max_x := 0.0
		var min_z := 0.0
		var max_z := 0.0
		for building: Node3D in buildings.get_children():
			min_x = minf(min_x, building.position.x)
			max_x = maxf(min_x, building.position.x)
			min_z = minf(min_z, building.position.z)
			max_z = maxf(min_z, building.position.z)
		var cluster_position := Vector3.ZERO
		match randi_range(0, 2):
			0: # Top
				cluster_position = Vector3(
					randf_range(min_x, max_x),
					0.0,
					min_z - ENEMY_SPAWN_DISTANCE_FROM_PLAYER
				)
			1: # Left
				cluster_position = Vector3(
					min_x - ENEMY_SPAWN_DISTANCE_FROM_PLAYER,
					0.0,
					randf_range(min_z, max_z)
				)
			2: # Right
				cluster_position = Vector3(
					max_x + ENEMY_SPAWN_DISTANCE_FROM_PLAYER,
					0.0,
					randf_range(min_z, max_z)
				)

		for i in floori(enemies_per_wave):
			var enemy := enemy_scene.instantiate() as Node3D
			enemy.position = Vector3(
				cluster_position.x + randf_range(-3.0, 3.0),
				0.0,
				cluster_position.z + randf_range(-3.0, 3.0),
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


func update_tooltip() -> void:
	if can_place_building():
		var building_cost: int = BUILDING_ENERGY_COST[building_type]
		tooltip_label.text = "Build for -%s energy" % building_cost
		tooltip_label.visible = true
	elif can_sell_building():
		tooltip_label.text = "Sell for +%s energy" % get_sell_value()
		tooltip_label.visible = true
	else:
		tooltip_label.visible = false


func update_ghost() -> void:
	ghost.position = Vector3(roundi(mouse_position_3d.x), 0.0, roundi(mouse_position_3d.z))
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


func update_camera(delta: float) -> void:
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
