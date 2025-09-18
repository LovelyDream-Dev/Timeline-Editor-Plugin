@tool
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
var noteDataDictionary:Dictionary

func _ready() -> void:
	rootNode = get_parent().get_parent().get_parent()
	scrollContainer = get_parent().get_parent()
	noteContainer = $NoteContainer

func _input(event: InputEvent) -> void:
	if scrollContainer.get_rect().has_point(get_global_mouse_position()):
		mouseTimelinePosition = scrollContainer.make_input_local(event).position.x + scrollContainer.scroll_horizontal
		if rootNode.LMB_ActionName:
			_select_notes()
			if Input.is_action_just_pressed(rootNode.LMB_ActionName) and rootNode.noteTexture:
				_place_note()
		if rootNode.RMB_ActionName:
			if Input.is_action_just_pressed(rootNode.RMB_ActionName) and rootNode.noteTexture:
				_remove_note()

func _enter_tree() -> void:
	if Engine.has_singleton("NoteData"):
		var note_data = Engine.get_singleton("NoteData")
		if note_data and note_data.has("noteData"):
			noteDataDictionary = note_data.noteData

func _process(_delta: float) -> void:
	if !Engine.is_editor_hint():
		print(noteDataDictionary)
		mouseBeatPosition = (mouseTimelinePosition / rootNode.pixelsPerWholeBeat) 
		_get_snapped_position()
		#_dragging()

## Assigns the closest snap position to [member snappedPosition] based on the mouse position on the timeline.
func _get_snapped_position():
	if !Engine.is_editor_hint():
		var snapInterval = 1.0/float(rootNode.snapDivisor)
		snappedBeat = round(mouseBeatPosition / snapInterval) * snapInterval
		snappedPixel = snappedBeat * rootNode.pixelsPerWholeBeat

func _place_note():
	if !Engine.is_editor_hint():
		var snappedSongPosition = snappedBeat * rootNode.secondsPerWholeBeat
		var noteSprite = Sprite2D.new()
		noteSprite.scale = Vector2(.25,.25)
		noteSprite.texture = rootNode.noteTexture
		noteSprite.position.y = rootNode.get_rect().size.y/2
		noteSprite.position.x = snappedPixel
		noteSprite.set_meta("songPosition", snappedSongPosition)
		if snappedSongPosition not in noteDataDictionary.values() and NoteData:
			noteContainer.add_child(noteSprite)
			noteDataDictionary[noteSprite.get_index()] = snappedSongPosition

func _remove_note():
	if !Engine.is_editor_hint():
		if noteContainer.get_child_count() > 0:
			for noteSprite:Sprite2D in noteContainer.get_children():
				if noteSprite.get_rect().has_point(noteSprite.to_local(get_global_mouse_position())):
					noteContainer.remove_child(noteSprite)
					_refresh_note_dictionary()
					
func _refresh_note_dictionary():
	if !Engine.is_editor_hint():
		noteDataDictionary.clear()
		if noteContainer and noteContainer.get_child_count() > 0:
			for noteSprite:Sprite2D in noteContainer.get_children():
				noteDataDictionary[noteSprite.get_index()] = noteSprite.get_meta("songPosition")
				

func _select_notes():
	if !Engine.is_editor_hint():
		if noteContainer.get_child_count() > 0:
			for noteSprite:Sprite2D in noteContainer.get_children():
				if noteSprite.get_rect().has_point(noteSprite.to_local(get_global_mouse_position())) and rootNode.LMB_ActionName and Input.is_action_just_pressed(rootNode.LMB_ActionName):
					if noteSprite.is_in_group("selectedNotes"):
						noteSprite.modulate.b = 0
						noteSprite.set_meta("selected", true)
						noteSprite.remove_from_group("selectedNotes")
					else: 
						noteSprite.add_to_group("selectedNotes")
						noteSprite.modulate.b = 1
						noteSprite.set_meta("selected", false)

func _dragging():
	if !Engine.is_editor_hint():
		if noteContainer.get_child_count() > 0:
			for note:Sprite2D in noteContainer.get_children():
				if note.get_meta("selected") == true:
					var snappedSongPosition = snappedBeat * rootNode.secondsPerWholeBeat
					note.position.x = snappedPixel
					note.set_meta("songPosition", snappedSongPosition)
					noteDataDictionary[note.get_index()] = snappedSongPosition
			
