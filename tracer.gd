class_name Tracer extends Node3D


@onready var cylinder := $Offset/Cylinder as MeshInstance3D
@onready var plane_1 := $Offset/Plane1 as MeshInstance3D
@onready var plane_2 := $Offset/Plane2 as MeshInstance3D
var spawned_at: float


func _ready() -> void:
	spawned_at = Util.time()


func _process(_delta: float) -> void:
	var now := Util.time()

	var a := clampf(1.0 - (now - spawned_at - 0.1) / 0.2, 0.0, 1.0)
	var m1 := cylinder.get_surface_override_material(0) as ShaderMaterial
	m1.set_shader_parameter("alpha", a)
	var m2 := plane_1.get_surface_override_material(0) as StandardMaterial3D
	m2.albedo_color.a = a
	var m3 := plane_2.get_surface_override_material(0) as StandardMaterial3D
	m3.albedo_color.a = a

	var s := lerpf(1.0, 0.9, (now - spawned_at) / 0.3)
	plane_1.scale.y = s
	plane_1.scale.z = s
	plane_2.scale.y = s
	plane_2.scale.z = s
