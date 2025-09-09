@tool
extends Node2D

var rootNode:Timeline
# The scroll container
var scrollContainer:ScrollContainer
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
# Whether a note is currently being dragged
var isDragging:bool
# The currently selected note
var currentNote:Sprite2D = null

func _ready() -> void:
	rootNode = get_parent().get_parent().get_parent()
	scrollContainer = get_parent().get_parent()

func _input(_event: InputEvent) -> void:
	if mousePosition and rootNode.get_rect().has_point(mousePosition):
		if rootNode.LMB_ActionName:
			_select_note()
			if Input.is_action_just_pressed(rootNode.LMB_ActionName) and rootNode.noteTexture:
				_place_note()
		if rootNode.RMB_ActionName:
			if Input.is_action_just_pressed(rootNode.RMB_ActionName) and rootNode.noteTexture:
				_remove_note()

func _process(_delta: float) -> void:
	mousePosition = get_global_mouse_position()
	if scrollContainer:
		# __ NEEDS DEBUGGING __
		mouseTimelinePosition = rootNode.get_local_mouse_position().x + scrollContainer.scroll_horizontal
	mouseBeatPosition = (mouseTimelinePosition / rootNode.bpm) 
	if rootNode.snapping:
		_get_snapped_position()
	_dragging()

## Assigns the closest snap position to [member snappedPosition] based on the mouse position on the timeline.
func _get_snapped_position():
	var snapInterval = 1.0/float(rootNode.snapDivisor)
	snappedBeat = round(mouseBeatPosition / snapInterval) * snapInterval
	snappedPixel = snappedBeat * rootNode.pixelsPerBeat

## Returns the x position of the mouse on the timeline if the mouse is on the timeline
func _get_mouse_position_on_timeline(): 
	if rootNode.get_rect().has_point(mousePosition):
		mouseTimelinePosition = to_local(mousePosition).x

func _place_note():
	var snappedSongPosition = snappedBeat * rootNode.secondsPerWholeBeat
	var noteSprite = Sprite2D.new()
	noteSprite.scale = Vector2(.25,.25)
	noteSprite.texture = rootNode.noteTexture
	noteSprite.position.y = rootNode.get_rect().size.y/2
	if rootNode.snapping:
		noteSprite.position.x = snappedPixel
		noteSprite.set_meta("songPosition", snappedSongPosition)
		if snappedSongPosition not in $NoteContainer.noteTimes.values():
			$NoteContainer.add_child(noteSprite)
			$NoteContainer.noteTimes[$NoteContainer.get_child_count() - 1] = snappedSongPosition
	else:
		var unsnappedSongPosition: = (mouseTimelinePosition / rootNode.pixelsPerBeat) * rootNode.secondsPerWholeBeat
		noteSprite.position.x = mouseTimelinePosition
		noteSprite.set_meta("songPosition", unsnappedSongPosition)
		if unsnappedSongPosition not in $NoteContainer.noteTimes.values():
			$NoteContainer.add_child(noteSprite)
			$NoteContainer.noteTimes[$NoteContainer.get_child_count() - 1] = unsnappedSongPosition

func _remove_note():
	if $NoteContainer.get_child_count() > 0:
		for note:Sprite2D in $NoteContainer.get_children():
			if note.get_rect().has_point(note.to_local(mousePosition)):
				var d:Dictionary = $NoteContainer.noteTimes
				$NoteContainer.noteTimes.erase(note.get_index())
				note.queue_free()

func _select_note():
	if $NoteContainer.get_child_count() > 0:
		for note:Sprite2D in $NoteContainer.get_children():
			if note.get_rect().has_point(note.to_local(mousePosition)) and rootNode.LMB_ActionName:
				if Input.is_action_pressed(rootNode.LMB_ActionName) and currentNote == null:
					currentNote = note
				if !Input.is_action_pressed(rootNode.LMB_ActionName) and currentNote != null:
					currentNote = null
	

func _dragging():
	if currentNote:
		if rootNode.snapping:
			var snappedSongPosition = snappedBeat * rootNode.secondsPerWholeBeat
			currentNote.position.x = snappedPixel
			currentNote.set_meta("songPosition", snappedSongPosition)
			$NoteContainer.noteTimes[currentNote.get_index()] = snappedSongPosition
		else:
			var unsnappedSongPosition: = (mouseTimelinePosition / rootNode.pixelsPerBeat) * rootNode.secondsPerWholeBeat
			currentNote.position.x = mouseTimelinePosition
			currentNote.set_meta("songPosition", unsnappedSongPosition)
			$NoteContainer.noteTimes[currentNote.get_index()] = unsnappedSongPosition
			
