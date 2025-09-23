extends Node2D
class_name Note_Container

## The array of note times
var noteDataArray:Array

# The root node of the scene
var rootNode:Timeline
# The scroll container
var scrollContainer:ScrollContainer
# The local position of the mouse in pixels on the timeline
var mouseTimelinePosition:float
# The position of the mouse in beats on the timeline
var mouseBeatPosition:float
## The nearest beat snap, this number DOES NOT indicate correct beat numbers. It counts beats sequentially depending on the snap divisor. [br]For example, with half beats it will count the first whole beat as 0, and the half beat after as 1.
var snappedBeat:float
# The nearest snap point in pixels
var snappedPixel:float
## The song position that is used as a snap point that the mouse is closest to
var snappedSongPosition:float
## The dictionary data of the current note to be added to noteDataArray
var note:Dictionary
## The snap interval to determine beat ticks and snapping
var snapInterval:float
# If the left mouse button is pressed
var LMB_Pressed:bool
# If a note or notes are currently being dragged
var isDragging:bool
# The note currently being dragged 
var currentNote:Timeline_Note = null

func _ready() -> void:
	rootNode = get_parent().get_parent().get_parent()
	scrollContainer = get_parent().get_parent()

func _input(event: InputEvent) -> void:
	if scrollContainer.get_rect().has_point(get_global_mouse_position()):
		if event is InputEventMouseMotion:
			mouseTimelinePosition = scrollContainer.make_input_local(event).position.x + scrollContainer.scroll_horizontal

		# Clicks
		if Input.is_action_just_pressed(rootNode.LMB_ActionName):
			LMB_Pressed = true
			if rootNode.noteTexture and note not in noteDataArray: _place_note()
		if Input.is_action_just_pressed(rootNode.RMB_ActionName):
				_remove_note()

		# Releases
		if Input.is_action_just_released(rootNode.LMB_ActionName):
			LMB_Pressed = false
			isDragging = false
			currentNote = null

func _process(_delta: float) -> void:
	# Stops this function from processing in the editor
	if Engine.is_editor_hint():
		return

	_update_z_indexes()
	_select_notes()
	_dragging()
	note = {"songPosition":snappedSongPosition}
	mouseBeatPosition = (mouseTimelinePosition / rootNode.pixelsPerWholeBeat) 
	_get_snapped_position()

func _place_note():
	var noteSprite = Timeline_Note.new()
	_set_note_values(noteSprite)
	if note not in noteDataArray:
		self.add_child(noteSprite)
		noteDataArray.append(note)
		noteDataArray.sort_custom(func(a, b): return a["songPosition"] < b["songPosition"])

func _remove_note():
	if self.get_child_count() > 0:
		for noteSprite:Timeline_Note in self.get_children():
			if noteSprite.get_rect().has_point(noteSprite.to_local(get_global_mouse_position())):
				self.remove_child(noteSprite)
				noteDataArray.erase(noteSprite.note)
				noteDataArray.sort_custom(func(a, b): return a["songPosition"] < b["songPosition"])

## Assigns the closest snap position to [member snappedPosition] based on the mouse position on the timeline.
func _get_snapped_position():
	snapInterval = 1.0/float(rootNode.snapDivisor)
	snappedBeat = round(mouseBeatPosition / snapInterval) * snapInterval
	snappedPixel = snappedBeat * rootNode.pixelsPerWholeBeat
	snappedSongPosition = snappedBeat * rootNode.secondsPerWholeBeat

func _update_z_indexes():
	if self.get_child_count() > 0:
		var firstNoteSprite:Timeline_Note = self.get_children()[0]
		for noteSprite:Timeline_Note in self.get_children():
			var previousNoteSprite:Timeline_Note = self.get_children()[noteSprite.get_index()-1]
			if noteSprite.songPosition >= previousNoteSprite.songPosition:
				noteSprite.z_index = previousNoteSprite.z_index + 1
			

func _select_notes():
	# Stops this function from running if a note is already selected and being dragged
	if isDragging:
		return

	var leftMax = scrollContainer.scroll_horizontal
	var rightMax = leftMax + scrollContainer.get_rect().size.x
	
	for i in range(len(self.get_children())):
		var noteSprite:Timeline_Note = self.get_child(i)
		if noteSprite.position.x < leftMax or noteSprite.position.x > rightMax:
			continue

		if noteSprite.get_rect().has_point(noteSprite.to_local(get_global_mouse_position())):
			if LMB_Pressed:
				if !noteSprite.selected:
					noteSprite.selected = true
					currentNote = noteSprite
					break
			else:
				if noteSprite.selected:
					noteSprite.selected = false
					break


func _dragging():
	var yCenter = rootNode.get_rect().size.y/2
	if currentNote == null:
		return
	for noteSprite:Timeline_Note in get_tree().get_nodes_in_group("selectedNotes"):
		if noteSprite == currentNote:
			if noteSprite.note != note: 
				isDragging = true
				noteDataArray.erase(noteSprite.note)
				noteDataArray.append(note)
				noteDataArray.sort_custom(func(a, b): return a["songPosition"] < b["songPosition"])
				noteSprite.position.x += (snappedPixel - noteSprite.position.x)
				noteSprite.timelinePosition = snappedPixel
				noteSprite.songPosition = (round(noteSprite.timelinePosition / snapInterval) * snapInterval) * rootNode.secondsPerWholeBeat
				noteSprite.note = note

				# Adjust y position of overlapped notes for visual clarity
				if noteDataArray.count(note) > 1:
					noteSprite.position.y -= noteDataArray.count(note)*3
				else:
					noteSprite.position.y = yCenter


## Sets all appropriate values of the given [member notesprite]. 
func _set_note_values(noteSprite:Timeline_Note):
	noteSprite.scale = Vector2(.25,.25)
	noteSprite.texture = rootNode.noteTexture
	noteSprite.position.y = rootNode.get_rect().size.y/2
	noteSprite.position.x = snappedPixel
	noteSprite.timelinePosition = snappedPixel
	noteSprite.songPosition = (round(noteSprite.timelinePosition / snapInterval) * snapInterval) * rootNode.secondsPerWholeBeat
	noteSprite.note = note
		
