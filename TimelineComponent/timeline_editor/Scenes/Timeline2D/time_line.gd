class_name Timeline
extends Control

signal SNAP_DIVISOR_CHANGED

# Nodes
@onready var scrollContainer:ScrollContainer = $ScrollContainer
@onready var baseControl:ColorRect = $ScrollContainer/BaseControl

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

func _on_snap_divisor_changed():
	SNAP_DIVISOR_CHANGED.emit()

func _ready() -> void:
	wholeBeatsPerSecond = (bpm/60)
	secondsPerWholeBeat = (60/bpm)
	pixelsPerWholeBeat = secondsPerWholeBeat * pixelsPerSecond
	totalWholeBeats = floori(wholeBeatsPerSecond * songLengthInSeconds)
	place_timeline_note(1)
	place_timeline_note(2)
	place_timeline_note(3)
	place_timeline_note(4)
	_init_timeline_size()

func _input(event: InputEvent) -> void:
		# Get the timeline mouse position if the mouse is moving within the timeline
	if scrollContainer.get_rect().has_point(get_global_mouse_position()):
		if event is InputEventMouseMotion:
			mouseTimelinePosition = scrollContainer.make_input_local(event).position.x + scrollContainer.scroll_horizontal

func _process(_delta: float) -> void:
	# Stops this function from running in the editor
	if Engine.is_editor_hint():
		return

	mouseBeatPosition = (mouseTimelinePosition / pixelsPerWholeBeat) 
	get_snapped_position()
	_set_timeline_height()
	if hideScrollBar and scrollContainer.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_SHOW_NEVER:
		scrollContainer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	elif !hideScrollBar and scrollContainer.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER:
		scrollContainer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		
	baseControl.custom_minimum_size.x = _get_timeline_length_from_song_length()
	baseControl.color = backgroundColor
	
	_get_whole_beat_times()
	_get_half_beat_times()
	_get_quarter_beat_times()
	_get_eighth_beat_times()
	_get_sixteenth_beat_times()

# --- CUSTOM FUNCTIONS ---

func on_bpm_changed(value):
	wholeBeatsPerSecond = value/60
	secondsPerWholeBeat = 60/value
	pixelsPerWholeBeat = secondsPerWholeBeat * pixelsPerSecond
	totalWholeBeats = floori(wholeBeatsPerSecond * songLengthInSeconds)

func select_and_drag_notes(selectedNotes:Array):
	if Input.is_action_pressed(lmbActionName):
		for note:Sprite2D in selectedNotes:
			note.position.x += (mouseBeatPosition - snappedBeat)

func get_timeline_position_from_beat(beat:float) -> Vector2:
	var posx = beat * pixelsPerWholeBeat
	var posy = self.get_rect().size.y/2
	return Vector2(posx, posy)

func place_timeline_note(beat:float):
	var pos = get_timeline_position_from_beat(beat)
	var hitNoteSprite:Sprite2D = Sprite2D.new()
	hitNoteSprite.position = pos
	hitNoteSprite.texture = load("res://icon.svg")
	hitNoteSprite.scale = Vector2(0.5, 0.5)
	self.add_child(hitNoteSprite)

## Assigns the closest snap position to [member snappedPosition] based on the mouse position on the timeline.
func get_snapped_position():
	snapInterval = 1.0/float(snapDivisor)
	snappedBeat = round(mouseBeatPosition / snapInterval) * snapInterval
	snappedPixel = snappedBeat * pixelsPerWholeBeat
	snappedSongPosition = snappedBeat * secondsPerWholeBeat

func _get_timeline_length_from_song_length() -> float: 
	return songLengthInSeconds * pixelsPerSecond

## Uses [method valueInSeconds] to find the related pixel position on the timeline. [br]Returns [code]0.0[/code] if [method valueInSeconds] is greater than [method songLengthInSeconds].
func _get_timeline_position_from_song_position(valueinSeconds:float) -> float:
	if valueinSeconds <= songLengthInSeconds:
		return valueinSeconds * pixelsPerSecond
	else: 
		return 0.0
	
func _init_timeline_size():
	self.size = Vector2(get_viewport_rect().size.x, timelineHeight)
	scrollContainer.size = Vector2(get_viewport_rect().size.x, timelineHeight)
	baseControl.size = Vector2(get_viewport_rect().size.x, timelineHeight)

func _set_timeline_height():
	if self.size.y != timelineHeight: 
		self.custom_minimum_size.y = timelineHeight
		self.size.y = timelineHeight
	if scrollContainer.size.y != timelineHeight: 
		scrollContainer.size.y = timelineHeight
		scrollContainer.size.y = timelineHeight
	if baseControl.size.y != timelineHeight:
		baseControl.custom_minimum_size.y = timelineHeight
		baseControl.size.y = timelineHeight

func _get_whole_beat_times():
	if !wholeBeatTimesGenerated and wholeBeatsPerSecond:
		wholeBeatTimes.clear()
		for beatIndex in range(totalWholeBeats):
			var beatTime = float(beatIndex)/wholeBeatsPerSecond
			wholeBeatTimes.append(beatTime)
		wholeBeatTimesGenerated = true

func _get_half_beat_times():
	if !halfBeatTimesGenerated and wholeBeatsPerSecond:
		halfBeatTimes.clear()
		for beatIndex in range(totalWholeBeats*2):
			var beatTime = float(beatIndex*.5)/wholeBeatsPerSecond
			halfBeatTimes.append(beatTime)
		halfBeatTimesGenerated = true

func _get_quarter_beat_times():
	if !quarterBeatTimesGenerated and wholeBeatsPerSecond:
		quarterBeatTimes.clear()
		for beatIndex in range(totalWholeBeats*4):
			var beatTime = float(beatIndex)/(wholeBeatsPerSecond*4)
			quarterBeatTimes.append(beatTime)
		quarterBeatTimesGenerated = true

func _get_eighth_beat_times():
	if !eighthBeatTimesGenerated and wholeBeatsPerSecond:
		eighthBeatTimes.clear()
		for beatIndex in range(totalWholeBeats*8):
			var beatTime = float(beatIndex)/(wholeBeatsPerSecond*8)
			eighthBeatTimes.append(beatTime)
		eighthBeatTimesGenerated = true

func _get_sixteenth_beat_times():
	if !sixteenthBeatTimesGenerated and wholeBeatsPerSecond:
		sixteenthBeatTimes.clear()
		for beatIndex in range(totalWholeBeats*16):
			var beatTime = float(beatIndex)/(wholeBeatsPerSecond*16)
			sixteenthBeatTimes.append(beatTime)
		sixteenthBeatTimesGenerated = true

## Returns true if the necessary values to draw ticks are ready.
func _get_if_ticks_are_drawable() -> bool:
	if secondsPerWholeBeat != 0.0 and wholeBeatsPerSecond != 0.0:
		return true
	else: return false
