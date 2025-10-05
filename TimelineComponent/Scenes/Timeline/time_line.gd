extends Control
class_name Timeline

signal SNAP_DIVISOR_CHANGED

# Nodes
@onready var scrollContainer:ScrollContainer = $ScrollContainer
@onready var baseControl:ColorRect = $ScrollContainer/BaseControl
@onready var noteContainer:Node2D = $ScrollContainer/BaseControl/NoteContainer
@onready var camera = get_viewport().get_camera_2d()

@export_category("Colors")
## The color of the timeline background
@export var backgroundColor:Color
## The color of whole beat ticks
@export var wholeBeatTickColor:Color
## The color of half beat ticks
@export var halfBeatTickColor:Color
## The color of quarter beat ticks
@export var quarterBeatTickColor:Color
## The color of eighth beat ticks
@export var eighthBeatTickColor:Color
## The color of sixteenth beat ticks
@export var sixteenthBeatTickColor:Color

@export_category("Values")
## Height of the timeline
@export var timelineHeight:float = 100.0
## Beats Per Minute/Tempo of the song. It is required to calculate [member timelineLengthInPixels].
@export var bpm:float:
	set(value):
		bpm = value
		on_bpm_changed(value)
## If applicable, the length of the song in seconds used to calculate [member timelineLengthInPixels].
@export var songLengthInSeconds:float
## The height of the beat ticks
@export var tickHeight:float
## The width of the beat ticks
@export var tickWidth:float
## If it is true, the rectanlge that is used for tick and timeline note culling will be drawn.
@export var showCullingRect:bool
## Determines margin around the culling rectangle that ticks and timeline notes will actually cull at.
@export var cullingMargin:float = 100.0
## Determines the amount of ticks between each whole beat.
@export_range(1,16) var snapDivisor:int:
	set(value):
		snapDivisor = value
		_on_snap_divisor_changed()
## How many pixels represent one second on the timeline, directly affects timeline length and spacing between ticks
@export var pixelsPerSecond:float = 250

@export_category("Booleans")
## If the tick ends are rounded
@export var roundedTicks:bool = true
## If it is set to true, placement on the timeline via mouse clicks will be enabled
@export var timelinePlacement:bool = true
## If it is set to true, the scroll bar will be hidden
@export var hideScrollBar:bool

@export_category("Strings") 
## String name of your Left Mouse Button input action. Required for timeline placement
@export var lmbActionName:String
## String name of your Right Mouse Button input action. Required for timeline placement
@export var rmbActionName:String

@export_category("Textures")
## Texture of the note that will be placed on the timeline
@export var noteTexture:Texture

# --- ARRAYS ---
## Array of the times in seconds of all whole beats within the song
var wholeBeatTimes:Array = []
## Tracks if whole beat times have already been generated
var wholeBeatTimesGenerated:bool
## Array of the times in seconds of all half beats within the song
var halfBeatTimes:Array = []
## Tracks if half beat times have already been generated
var halfBeatTimesGenerated:bool
## Array of the times in seconds of all quarter beats within the song
var quarterBeatTimes:Array = []
## Tracks if quarter beat times have already been generated
var quarterBeatTimesGenerated:bool
## Array of the times in seconds of all eighth beats within the song
var eighthBeatTimes:Array = []
## Tracks if eighth beat times have already been generated
var eighthBeatTimesGenerated:bool
## Array of the times in seconds of all sixteenth beats within the song
var sixteenthBeatTimes:Array = []
## Tracks if sixteenth beat times have already been generated
var sixteenthBeatTimesGenerated:bool

# --- VALUES ---
## Length of the timeline in pixels
var timelineLengthInPixels:float
## If applicable, the current position of the song.
var songPosition:float
## If applicable, the total amount of whole beats in the song.
var totalWholeBeats:int
## How many seconds a whole beat lasts
var secondsPerWholeBeat:float
## How many whole beats are in a second
var wholeBeatsPerSecond:float
## How many pixels are in a whole beat on the timeline
var pixelsPerWholeBeat 

# --- SNAPPING VARIABLES ---
# The position of the mouse in beats on the timeline
var mouseBeatPosition:float
## The nearest beat snap, this number DOES NOT indicate overral beat numbers. It counts beats sequentially depending on the snap divisor. [br]For example, with half beats it will count the first whole beat as 0, and the half beat after as 1.
var snappedBeat:float
# The nearest snap point in pixels
var snappedPixel:float
## The song position that is used as a snap point that the mouse is closest to
var snappedSongPosition:float
## The snap interval to determine beat ticks and snapping
var snapInterval:float

# The local position of the mouse in pixels on the timeline
var mouseTimelinePosition:float

# --- DRAGGING VARIABLES ---

var dragSelectStartPosition:Vector2
var dragSelectStarted:bool = false
var dragSelectionRect:Rect2
var dragNoteStartPosX:float


func _on_snap_divisor_changed():
	SNAP_DIVISOR_CHANGED.emit()

func _ready() -> void:
	wholeBeatsPerSecond = (bpm/60)
	secondsPerWholeBeat = (60/bpm)
	pixelsPerWholeBeat = secondsPerWholeBeat * pixelsPerSecond
	totalWholeBeats = floori(wholeBeatsPerSecond * songLengthInSeconds)
	place_timeline_note(1,1)
	place_timeline_note(2,2)
	place_timeline_note(3,3)
	place_timeline_note(4,5)
	init_timeline_size()
	cull_notes()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			select_notes_by_click(event)
			if get_if_clicked_outside_of_selected_note() == true:
				deselect_notes(null)

	if Input.is_action_just_pressed(lmbActionName):
		start_note_drag()

	if Input.is_action_pressed(lmbActionName):
		drag_notes()
		if get_tree().get_node_count_in_group("selectedNotes") == 0:
			if !dragSelectStarted:
				dragSelectStarted = true
				dragSelectStartPosition = get_global_mouse_position()
		else:
			if dragSelectStarted:
				deselect_notes(null)

	if Input.is_action_just_released(lmbActionName):
		end_note_drag()
		dragSelectStarted = false

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			deselect_notes(null)

		# Get the timeline mouse position if the mouse is moving within the timeline
	if scrollContainer.get_rect().has_point(scrollContainer.get_local_mouse_position()):
		if event is InputEventMouseMotion:
			mouseTimelinePosition = scrollContainer.make_input_local(event).position.x + scrollContainer.scroll_horizontal

func _process(_delta: float) -> void:
	queue_redraw()
	select_notes_by_drag()

	mouseBeatPosition = (mouseTimelinePosition / pixelsPerWholeBeat) 
	get_snapped_position()
	set_timeline_height()
	if hideScrollBar and scrollContainer.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_SHOW_NEVER:
		scrollContainer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	elif !hideScrollBar and scrollContainer.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER:
		scrollContainer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		
	baseControl.custom_minimum_size.x = get_timeline_length_from_song_length()
	baseControl.color = backgroundColor
	
	get_whole_beat_times()
	get_half_beat_times()
	get_quarter_beat_times()
	get_eighth_beat_times()
	get_sixteenth_beat_times()

func _draw() -> void:
	if dragSelectStarted:
		draw_selection_rectangle(dragSelectStartPosition)


# --- CUSTOM FUNCTIONS ---

func on_bpm_changed(value):
	wholeBeatsPerSecond = value/60
	secondsPerWholeBeat = 60/value
	pixelsPerWholeBeat = secondsPerWholeBeat * pixelsPerSecond
	totalWholeBeats = floori(wholeBeatsPerSecond * songLengthInSeconds)


# ----- DRAWING FUNCTIONS -----


## Draws the rectangle for multi note selection
func draw_selection_rectangle(pos:Vector2):
	var mousePos = get_local_mouse_position()
	var movingCorner = Vector2(mousePos.x - pos.x, mousePos.y - pos.y)
	dragSelectionRect = Rect2(pos, movingCorner)
	draw_rect(dragSelectionRect, Color(1, 1, 1, 0.5), true)
	draw_rect(dragSelectionRect, Color(1, 1, 1, 1), false)


# ----- TIMELINE _NOTE FUNCTIONS -----

## Selects timeline notes on mouse click. Can only select individual notes if none are already selected.
func select_notes_by_click(event:InputEvent):
	if get_tree().get_node_count_in_group("selectedNotes") > 0:
		return

	var nodesUnderEvent:Array = get_timeline_note_from_list_at_point(event.position, noteContainer.get_children())
	if !nodesUnderEvent.is_empty():
		var topNote:TimelineNote = nodesUnderEvent.back()
		topNote.isSelected = true

func select_notes_by_drag():
	if !dragSelectStarted:
		if get_tree().get_node_count_in_group("selectedNotes") > 0:
			return
	else:
		for timelineNote:TimelineNote in noteContainer.get_children():
			if dragSelectionRect.abs().has_point(noteContainer.to_local(timelineNote.global_position)):
				timelineNote.isSelected = true

## De-selects [member note] if it is not [code]null[/code]. Otherwise it de-selects all notes in group [member selectedNotes].
func deselect_notes(note:TimelineNote):
	if note == null:
		for timelineNote:TimelineNote in get_tree().get_nodes_in_group("selectedNotes"):
			timelineNote.isSelected = false
	else:
		note.isSelected = false

## Returns [member true] if a mouse click is detected outside of any node within group [member selectedNotes].
func get_if_clicked_outside_of_selected_note() -> bool:
	for timelineNote:TimelineNote in get_tree().get_nodes_in_group("selectedNotes"):
		if !timelineNote.hitNoteSprite.get_rect().has_point(timelineNote.hitNoteSprite.get_local_mouse_position()):
			return true
		else: 
			return false
	return true

func start_note_drag():
	dragNoteStartPosX = snappedPixel

func drag_notes():
	if !dragSelectStarted:
		for timelineNote:TimelineNote in get_tree().get_nodes_in_group("selectedNotes"):
			var dragDistance = (snappedPixel - dragNoteStartPosX)
			timelineNote.position.x = timelineNote.currentPositionX + dragDistance
			

func end_note_drag():
	for timelineNote:TimelineNote in get_tree().get_nodes_in_group("selectedNotes"):
		timelineNote.currentPositionX = timelineNote.position.x
	dragNoteStartPosX = 0.0

## Returns an [member Array] of all [member Node2D]'s within [member list] that are located at [member point].
func get_timeline_note_from_list_at_point(point:Vector2, list:Array) -> Array:
	var pointArray:Array 
	for timelineNote:TimelineNote in list:
		if timelineNote.hitNoteSprite.get_rect().has_point(timelineNote.to_local(point)):
			pointArray.append(timelineNote)
	return pointArray

## Returns the [member Node2D] with the highest [member z-index] from [member list].
func get_highest_timeline_note_z_index(list:Array) -> Node2D:
	if list.is_empty():
		return null

	var highest:TimelineNote = list[0]
	for timelineNote:TimelineNote in list:
		if timelineNote.z_index > highest.z_index:
				highest = timelineNote
	return highest


## Places notes on the timeline at the correct position using [member beat].
func place_timeline_note(startBeat:float, endBeat:float):
	var startPos = get_timeline_position_from_beat(startBeat)
	var endPos = get_timeline_position_from_beat(endBeat)
	var timelineNote:TimelineNote = TimelineNote.new()
	timelineNote.startBeat = startBeat
	timelineNote.endBeat = endBeat
	timelineNote.startPos = startPos
	timelineNote.endPos = endPos
	timelineNote.currentPositionX = startPos.x
	timelineNote.position = startPos
	timelineNote.hitNoteTexture = load("res://icon.svg")
	noteContainer.add_child(timelineNote)


# ----- TIMELINE POSITION FUNCTIONS -----


func cull_notes():
	var scrollContainerRect:Rect2 = scrollContainer.get_rect()
	var cullingRect = Rect2(scrollContainerRect.position - Vector2(cullingMargin, cullingMargin), scrollContainerRect.size + Vector2(cullingMargin * 2.0, cullingMargin * 2.0))
	cullingRect.position.x += scrollContainer.scroll_horizontal
	# cull
	for timelineNote:TimelineNote in noteContainer.get_children():
		if !cullingRect.has_point(timelineNote.position):
			if !timelineNote.is_in_group("culledTimelineNotes"): 
				timelineNote.add_to_group("culledTimelineNotes")
			timelineNote.hide()
			timelineNote.process_mode = Node.PROCESS_MODE_DISABLED
	# revive
	for timelineNote:TimelineNote in get_tree().get_nodes_in_group("culledTimelineNotes"):
		if cullingRect.has_point(timelineNote.position):
			timelineNote.remove_from_group("culledTimelineNotes")
			timelineNote.show()
			timelineNote.process_mode = Node.PROCESS_MODE_INHERIT

func get_timeline_position_from_beat(beat:float) -> Vector2:
	var posx = beat * pixelsPerWholeBeat
	var posy = self.get_rect().size.y/2
	return Vector2(posx, posy)

## Assigns the closest snap position to [member snappedPosition] based on the mouse position on the timeline.
func get_snapped_position():
	snapInterval = 1.0/float(snapDivisor)
	snappedBeat = round(mouseBeatPosition / snapInterval) * snapInterval
	snappedPixel = snappedBeat * pixelsPerWholeBeat
	snappedSongPosition = snappedBeat * secondsPerWholeBeat

func get_timeline_length_from_song_length() -> float: 
	return songLengthInSeconds * pixelsPerSecond

## Uses [method valueInSeconds] to find the related pixel position on the timeline. [br]Returns [code]0.0[/code] if [method valueInSeconds] is greater than [method songLengthInSeconds].
func get_timeline_position_x_from_song_position(valueinSeconds:float) -> float:
	if valueinSeconds <= songLengthInSeconds:
		return valueinSeconds * pixelsPerSecond
	else: 
		return 0.0
	
func init_timeline_size():
	self.size = Vector2(get_viewport_rect().size.x, timelineHeight)
	scrollContainer.size = Vector2(get_viewport_rect().size.x, timelineHeight)
	baseControl.size = Vector2(get_viewport_rect().size.x, timelineHeight)

func set_timeline_height():
	if self.size.y != timelineHeight: 
		self.custom_minimum_size.y = timelineHeight
		self.size.y = timelineHeight
	if scrollContainer.size.y != timelineHeight: 
		scrollContainer.size.y = timelineHeight
		scrollContainer.size.y = timelineHeight
	if baseControl.size.y != timelineHeight:
		baseControl.custom_minimum_size.y = timelineHeight
		baseControl.size.y = timelineHeight


# ----- BEAT TIME FUNCTIONS -----

func get_whole_beat_times():
	if !wholeBeatTimesGenerated and wholeBeatsPerSecond:
		wholeBeatTimes.clear()
		for beatIndex in range(totalWholeBeats):
			var beatTime = float(beatIndex)/wholeBeatsPerSecond
			wholeBeatTimes.append(beatTime)
		wholeBeatTimesGenerated = true

func get_half_beat_times():
	if !halfBeatTimesGenerated and wholeBeatsPerSecond:
		halfBeatTimes.clear()
		for beatIndex in range(totalWholeBeats*2):
			var beatTime = float(beatIndex*.5)/wholeBeatsPerSecond
			halfBeatTimes.append(beatTime)
		halfBeatTimesGenerated = true

func get_quarter_beat_times():
	if !quarterBeatTimesGenerated and wholeBeatsPerSecond:
		quarterBeatTimes.clear()
		for beatIndex in range(totalWholeBeats*4):
			var beatTime = float(beatIndex)/(wholeBeatsPerSecond*4)
			quarterBeatTimes.append(beatTime)
		quarterBeatTimesGenerated = true

func get_eighth_beat_times():
	if !eighthBeatTimesGenerated and wholeBeatsPerSecond:
		eighthBeatTimes.clear()
		for beatIndex in range(totalWholeBeats*8):
			var beatTime = float(beatIndex)/(wholeBeatsPerSecond*8)
			eighthBeatTimes.append(beatTime)
		eighthBeatTimesGenerated = true

func get_sixteenth_beat_times():
	if !sixteenthBeatTimesGenerated and wholeBeatsPerSecond:
		sixteenthBeatTimes.clear()
		for beatIndex in range(totalWholeBeats*16):
			var beatTime = float(beatIndex)/(wholeBeatsPerSecond*16)
			sixteenthBeatTimes.append(beatTime)
		sixteenthBeatTimesGenerated = true

## Returns true if the necessary values to draw ticks are ready.
func get_if_ticks_are_drawable() -> bool:
	if secondsPerWholeBeat != 0.0 and wholeBeatsPerSecond != 0.0:
		return true
	else: return false


# ----- SIGNAL FUNCTIONS -----


func _on_scroll_container_scroll_changed() -> void:
	cull_notes()
