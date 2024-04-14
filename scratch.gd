@tool
extends EditorScript

func _run() -> void:
	for wave_index in 10:
		var enemy_count := roundi(0.6 * pow(wave_index, 1.5) + 2.0)
		print("%s: %s" % [wave_index + 1, enemy_count])
