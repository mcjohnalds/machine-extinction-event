class_name Util extends RefCounted


static func play_sound(node: Node, stream: AudioStream) -> void:
	var asp := AudioStreamPlayer.new()
	node.add_child(asp)
	asp.stream = stream
	asp.play()
	asp.finished.connect(func() -> void:
		asp.queue_free()
	)


static func time() -> float:
	return Time.get_ticks_msec() / 1000.0
