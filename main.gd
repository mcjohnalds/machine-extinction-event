extends Node3D

enum BuildingType {TURRET, WALL}
var turret_scene := preload("res://turret.tscn")
var wall_scene := preload("res://wall.tscn")
var enemy_scene := preload("res://enemy.tscn")
var player_transparent := preload("res://player_transparent.tres")
@onready var ground := $Ground as Area3D
@onready var ghost := $Ghost as Node3D
@onready var launchpad := $Buildings/Launchpad as Node3D
@onready var turret_ghost := $Ghost/Turret as Node3D
@onready var wall_ghost := $Ghost/Wall as Node3D
@onready var enemies := $Enemies as Node
@onready var buildings := $Buildings as Node
var building_type := BuildingType.TURRET
var grid_to_building := {} # Dictionary[Vector2i, Node3D]


func _ready() -> void:
	grid_to_building[Vector2i(0, 0)] = launchpad

	for mesh: MeshInstance3D in ghost.find_children("*", "MeshInstance3D"):
		mesh.material_override = player_transparent

	ground.input_event.connect(_on_input_event)

	while true:
		var enemy := enemy_scene.instantiate() as Node3D
		enemy.position = Vector3(5.0, 0.0, 5.0)
		enemies.add_child(enemy)
		await get_tree().create_timer(1.0).timeout


func _unhandled_input(event: InputEvent) -> void:
	if event as InputEventKey:
		var e := event as InputEventKey
		if e.pressed:
			match e.keycode:
				KEY_1:
					building_type = BuildingType.TURRET
					turret_ghost.visible = true
					wall_ghost.visible = false
				KEY_2:
					building_type = BuildingType.WALL
					turret_ghost.visible = false
					wall_ghost.visible = true
				KEY_ESCAPE:
					get_tree().quit()


func _on_input_event(
	_camera: Node,
	event: InputEvent,
	event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	var grid_coord := Vector2i(roundi(event_position.x), roundi(event_position.z))
	var grid_pos := Vector3(grid_coord.x, 0.0, grid_coord.y)
	if event is InputEventMouseMotion:
		ghost.position = grid_pos

	ghost.visible = grid_coord not in grid_to_building

	if event.is_pressed():
		if grid_coord in grid_to_building:
			var building: Node3D = grid_to_building[grid_coord]
			building.queue_free()
			grid_to_building.erase(grid_coord)
		else:
			var building_scene := (
				turret_scene if building_type == BuildingType.TURRET
				else wall_scene
			)
			var building := building_scene.instantiate() as Node3D
			building.position = grid_pos
			grid_to_building[grid_coord] = building
			buildings.add_child(building)


func _process(delta: float) -> void:
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


func get_nearest_building(pos: Vector3) -> Vector2i:
	assert(!grid_to_building.is_empty())
	var nearest_grid_coord: Vector2i = grid_to_building.keys()[0]
	for grid_coord: Vector2i in grid_to_building:
		var a: Node3D = grid_to_building[grid_coord]
		var b: Node3D = grid_to_building[nearest_grid_coord]
		if pos.distance_to(a.position) < pos.distance_to(b.position):
			nearest_grid_coord = grid_coord
	return nearest_grid_coord
