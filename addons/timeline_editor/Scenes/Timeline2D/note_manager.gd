extends Node2D

var rootNode:Timeline
# The scroll container
var scrollContainer:ScrollContainer
# The note container node
var noteContainer:Node2D
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
## The array of note times stored in a singleton
var noteDataArray:Array
## The song position that is used as a snap point that the mouse is closest to
var snappedSongPosition:float
## The dictionary data of the current note to be added to noteDataArray
var note:Dictionary
## The snap interval to determine beat ticks and snapping
var snapInterval:float

func _ready() -> void:
	rootNode = get_parent().get_parent().get_parent()
	scrollContainer = get_parent().get_parent()
	noteContainer = $NoteContainer

func _input(event: InputEvent) -> void:
	if scrollContainer.get_rect().has_point(get_global_mouse_position()):
		if event is InputEventMouseMotion:
			mouseTimelinePosition = scrollContainer.make_input_local(event).position.x + scrollContainer.scroll_horizontal

		# Clicks
		if Input.is_action_just_pressed(rootNode.LMB_ActionName):
			if rootNode.noteTexture and note not in noteDataArray: _place_note()
		if Input.is_action_just_pressed(rootNode.RMB_ActionName):
				_remove_note()

		# Holds
		if Input.is_action_pressed(rootNode.LMB_ActionName):
			_select_notes(false)
			_dragging()
		if Input.is_action_just_released(rootNode.LMB_ActionName):
			_select_notes(true)

func _enter_tree() -> void:
	if Engine.has_singleton("NoteData"):
		var note_data = Engine.get_singleton("NoteData")
		if note_data and note_data.has("noteData"):
			noteDataArray = note_data.noteData

func _process(_delta: float) -> void:
	# Stops this function from processing in the editor
	if Engine.is_editor_hint():
		return

	note = {"songPosition":snappedSongPosition}
	mouseBeatPosition = (mouseTimelinePosition / rootNode.pixelsPerWholeBeat) 
	_get_snapped_position()

func _place_note():
	var noteSprite = Timeline_Note.new()
	_set_note_values(noteSprite, false)
	if note not in noteDataArray and NoteData:
		noteContainer.add_child(noteSprite)
		noteDataArray.append(note)
		noteDataArray.sort_custom(func(a, b): return a["songPosition"] < b["songPosition"])

func _remove_note():
	if noteContainer.get_child_count() > 0:
		for noteSprite:Timeline_Note in noteContainer.get_children():
			if noteSprite.get_rect().has_point(noteSprite.to_local(get_global_mouse_position())):
				noteContainer.remove_child(noteSprite)
				noteDataArray.erase(noteSprite.note)
				noteDataArray.sort_custom(func(a, b): return a["songPosition"] < b["songPosition"])

## Assigns the closest snap position to [member snappedPosition] based on the mouse position on the timeline.
func _get_snapped_position():
	snapInterval = 1.0/float(rootNode.snapDivisor)
	snappedBeat = round(mouseBeatPosition / snapInterval) * snapInterval
	snappedPixel = snappedBeat * rootNode.pixelsPerWholeBeat
	snappedSongPosition = snappedBeat * rootNode.secondsPerWholeBeat

func _select_notes(isDeselect:bool):
	var leftMax = scrollContainer.scroll_horizontal
	var rightMax = leftMax + scrollContainer.get_rect().size.x
	for i in range(noteContainer.get_child_count() - 1, -1, -1):
		var noteSprite:Timeline_Note = noteContainer.get_child(i)
		if noteSprite.position.x < leftMax or noteSprite.position.x > rightMax:
			continue
		if noteSprite.get_rect().has_point(noteSprite.to_local(get_global_mouse_position())):
			if !isDeselect:
				if !noteSprite.selected:
					noteSprite.selected = true
					break
			if noteSprite.selected:
				noteSprite.selected = false
				break


func _dragging():
	if noteContainer.get_child_count() > 0:
		for noteSprite:Timeline_Note in get_tree().get_nodes_in_group("selectedNotes"):
			if noteSprite.note != note: 
				noteDataArray.erase(noteSprite.note)
				noteDataArray.append(note)
				noteDataArray.sort_custom(func(a, b): return a["songPosition"] < b["songPosition"])
				_set_note_values(noteSprite, true)

## Sets all appropriate values of the given [member notesprite]. If [member isDragging] is true, only the values necessary when dragging will be set.
func _set_note_values(noteSprite:Timeline_Note, isDragging:bool):
	if !isDragging:
		noteSprite.scale = Vector2(.25,.25)
		noteSprite.texture = rootNode.noteTexture
		noteSprite.position.y = rootNode.get_rect().size.y/2
		noteSprite.position.x = snappedPixel
		noteSprite.timelinePosition = snappedPixel
		noteSprite.songPosition = (round(noteSprite.timelinePosition / snapInterval) * snapInterval) * rootNode.secondsPerWholeBeat
		noteSprite.note = note
	else:
		noteSprite.position.x += (snappedPixel - noteSprite.position.x)
		noteSprite.timelinePosition = snappedPixel
		noteSprite.songPosition = (round(noteSprite.timelinePosition / snapInterval) * snapInterval) * rootNode.secondsPerWholeBeat
		noteSprite.note = note
