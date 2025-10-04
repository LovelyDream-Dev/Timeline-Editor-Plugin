extends Node2D
class_name TimelineNote

var hitNoteSprite := Sprite2D.new() 
var hitNoteOutlineSprite := Sprite2D.new()  

var hitNoteTexture:Texture = null
var hitNoteOutlineTexture:Texture = null

var leftColor:Color = Color("924CF4")
var rightColor = Color("F44C4F")
var highlightColor = Color("F6FF00")

var currentPositionX:float
var startBeat:float
var endBeat:float
var side:int

var hasMouse:bool
var isSelected:bool:
	set(value):
		isSelected = value
		on_if_selected_changed(value)

func _enter_tree() -> void:
	if hitNoteTexture != null:
		hitNoteSprite.texture = hitNoteTexture
		hitNoteSprite.scale = Vector2(0.25, 0.25)
		self.add_child(hitNoteSprite)
		hitNoteTexture = null
	if hitNoteOutlineTexture != null:
		hitNoteOutlineSprite.texture = hitNoteOutlineTexture
		hitNoteOutlineSprite.scale = Vector2(0.25, 0.25)
		self.add_child(hitNoteOutlineSprite)
		hitNoteOutlineSprite = null

	if side == -1:
		hitNoteSprite.modulate = leftColor
	elif side == 1:
		hitNoteSprite.modulate = rightColor

# --- CUSTOM FUNCTIONS ---
func on_if_selected_changed(value):
	if value == true:
		self.add_to_group("selectedNotes")
		self.modulate = highlightColor
	else:
		self.remove_from_group("selectedNotes")
		self.modulate = Color(1, 1, 1, 1)
