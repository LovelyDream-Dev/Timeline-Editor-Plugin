extends Sprite2D
class_name Timeline_Note

var selected:bool = false
var songPosition:float
var timelinePosition:float
var spawnBufferExpired:bool

func _input(event: InputEvent) -> void:
	if self.get_rect().has_point(self.to_local(get_global_mouse_position())):
		if event is InputEventMouseButton:
			if event.pressed:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if !selected:
						selected = true
					else:
						selected = false

func _process(_delta: float) -> void:
	if !spawnBufferExpired:
		pass
	else:
		if selected and not self.is_in_group("selectedNotes"): 
			self.modulate.b = 0
			self.add_to_group("selectedNotes")
		elif !selected and self.is_in_group("selectedNotes"): 
			self.modulate.b = 1
			self.remove_from_group("selectedNotes")

func _enter_tree() -> void:
	var spawnBuffer = Timer.new()
	spawnBuffer.autostart = true
	spawnBuffer.one_shot = true
	get_tree().root.add_child(spawnBuffer)
	spawnBuffer.start(0.2)
	spawnBuffer.connect("timeout", _on_spawn_buffer_timeout)

func _on_spawn_buffer_timeout():
	spawnBufferExpired = true
	selected = false
