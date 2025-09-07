@tool
extends Node2D

var rootNode:Timeline
# The global mouse position
var mousePosition:Vector2
# The local position of the mouse in pixels on the timeline
var mouseTimelinePosition:float
# The position of the mouse in beats on the timeline
var mouseBeatPosition:float
## The nearest beat snap, this number DOES NOT indicate correct beat numbers. It counts beats sequentially depending on the snap divisor. [br]For example, with half beats it will count the first whole beat as 0, and the half beat after as 1.
var snappedBeat:float
# The nearest snap point in pixels
var snappedPixel:float


func _ready() -> void:
	rootNode = get_parent().get_parent().get_parent()

func _input(_event: InputEvent) -> void:
	if mousePosition and rootNode.get_rect().has_point(mousePosition):
		if rootNode.LMB_ActionName:
			if Input.is_action_just_pressed(rootNode.LMB_ActionName) and rootNode.noteTexture:
				_place_note()
		if rootNode.RMB_ActionName:
			if Input.is_action_just_pressed(rootNode.RMB_ActionName) and rootNode.noteTexture:
				_remove_note()

func _process(_delta: float) -> void:
	mousePosition = get_global_mouse_position()
	mouseTimelinePosition = rootNode.get_local_mouse_position().x
	mouseBeatPosition = (mouseTimelinePosition / rootNode.bpm) 
	_get_snapped_position()

## Assigns the closest snap position to [member snappedPosition] based on the mouse position on the timeline.
func _get_snapped_position():
	if rootNode.snapping:
		var snapInterval = 1.0/float(rootNode.snapDivisor)
		snappedBeat = round(mouseBeatPosition / snapInterval) * snapInterval
		snappedPixel = snappedBeat * rootNode.pixelsPerBeat

## Returns the x position of the mouse on the timeline if the mouse is on the timeline
func _get_mouse_position_on_timeline(): 
	if rootNode.get_rect().has_point(mousePosition):
		mouseTimelinePosition = to_local(mousePosition).x

func _place_note():
	var songPosition = snappedBeat * rootNode.secondsPerWholeBeat
	var noteSprite = Sprite2D.new()
	noteSprite.scale = Vector2(.25,.25)
	noteSprite.texture = rootNode.noteTexture
	noteSprite.position.x = snappedPixel
	noteSprite.position.y = rootNode.get_rect().size.y/2
	noteSprite.set_meta("xPosition", snappedPixel)
	noteSprite.set_meta("beatPosition", snappedBeat)
	noteSprite.set_meta("songPosition", songPosition)
	if songPosition not in $NoteContainer.noteTimes:
		$NoteContainer.add_child(noteSprite)
		$NoteContainer.noteTimes[songPosition] = true

func _remove_note():
	if $NoteContainer.get_child_count() > 0:
		for note:Sprite2D in $NoteContainer.get_children():
			if note.get_rect().has_point(note.to_local(mousePosition)):
				$NoteContainer.noteTimes.erase(note.get_meta("songPosition"))
				note.queue_free()
