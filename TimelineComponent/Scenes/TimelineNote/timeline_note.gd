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
var endBeat:float:
	set(value):
		endBeat = value
		on_slider_length_change()

var startPos:Vector2
var endPos:Vector2
var side:int

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

func _ready() -> void:
	queue_redraw()

func _input(_event: InputEvent) -> void:
	pass

func _draw() -> void:
	draw_slider()

# --- CUSTOM FUNCTIONS ---
func on_if_selected_changed(value):
	if value == true:
		self.add_to_group("selectedNotes")
		self.modulate = highlightColor
	else:
		self.remove_from_group("selectedNotes")
		self.modulate = Color(1, 1, 1, 1)

func on_slider_length_change():
	queue_redraw()

func draw_slider():
	# Don't intialize slider if the end beat is the same or less than the start beat
	if endBeat <= startBeat:
		return

	var sliderStartPos = self.to_local(self.position)
	var sliderEndPos = self.to_local(endPos)
	draw_line(sliderStartPos, sliderEndPos, Color("C6AB40"), 8.0)
	draw_circle(sliderEndPos, 4.0, Color("C6AB40"), -1.0, true)
