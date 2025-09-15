@tool
class_name Timeline
extends Control

# Nodes
var scrollContainer:ScrollContainer
var baseControl:ColorRect

@export_category("Colors")
## The color of the timeline background
@export var backgroundColor:Color
## The color of whole beat ticks
@export var wholeBeatTickColor:Color
## The color of half beat ticks
@export var halfBeatTickColor:Color
## The color of quarter beat ticks
@export var quarterBeatTickColor:Color

@export_category("Values")
## Height of the timeline
@export var timelineHeight:float = 100.0
## Beats Per Minute/Tempo of the song. It is required to calculate [member timelineLengthInPixels].
@export var bpm:float
## If applicable, the length of the song in seconds used to calculate [member timelineLengthInPixels].
@export var songLengthInSeconds:float
## The height of the beat ticks
@export var tickHeight:float
## The width of the beat ticks
@export var tickWidth:float
## Determines the amount of ticks between each whole beat.
@export_range(1,16) var snapDivisor:int
## How many pixels represent one second on the timeline, directly affects timeline length and spacing between ticks
@export var pixelsPerSecond:float = 250

@export_category("Booleans")
## If the tick ends are rounded
@export var roundedTicks:bool = true
## If it is set to true, placement on the timeline via mouse clicks will be enabled
@export var timelinePlacement:bool = true

@export_category("Strings") 
## String name of your Left Mouse Button input action. Required for timeline placement
@export var LMB_ActionName:String
## String name of your Right Mouse Button input action. Required for timeline placement
@export var RMB_ActionName:String

@export_category("Textures")
## Texture of the note that will be placed on the timeline
@export var noteTexture:Texture

# Arrays
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

# Values
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


func _ready() -> void:
	scrollContainer = $ScrollContainer
	baseControl = $ScrollContainer/BaseControl
	_init_timeline()

func _process(_delta: float) -> void:
	baseControl.custom_minimum_size.x = _get_timeline_length_from_song_length()
	baseControl.color = backgroundColor
	wholeBeatsPerSecond = (bpm/60)
	secondsPerWholeBeat = (60/bpm)
	pixelsPerWholeBeat = secondsPerWholeBeat * pixelsPerSecond
	totalWholeBeats = wholeBeatsPerSecond * songLengthInSeconds
	_get_whole_beat_times()
	_get_half_beat_times()
	_get_quarter_beat_times()

func _get_timeline_length_from_song_length() -> float: 
	return songLengthInSeconds * pixelsPerSecond

## Uses [method valueInSeconds] to find the related pixel position on the timeline. [br]Returns [code]0.0[/code] if [method valueInSeconds] is greater than [method songLengthInSeconds].
func _get_timeline_position_from_song_position(valueinSeconds:float) -> float:
	if valueinSeconds <= songLengthInSeconds:
		return valueinSeconds * pixelsPerSecond
	else: 
		return 0.0
	
func _init_timeline():
	self.size = Vector2(get_viewport_rect().size.x, timelineHeight)
	scrollContainer.size = Vector2(get_viewport_rect().size.x, timelineHeight)

func _get_whole_beat_times():
	if !wholeBeatTimesGenerated and wholeBeatsPerSecond:
		for beatNumber in range(totalWholeBeats):
			var beatTime = beatNumber/wholeBeatsPerSecond
			wholeBeatTimes.append(beatTime)
		wholeBeatTimesGenerated = true

func _get_half_beat_times():
	if !halfBeatTimesGenerated and wholeBeatsPerSecond:
		for beatNumber in range(totalWholeBeats*2):
			var beatTime = (beatNumber*.5)/wholeBeatsPerSecond
			halfBeatTimes.append(beatTime)
		halfBeatTimesGenerated = true

func _get_quarter_beat_times():
	if !quarterBeatTimesGenerated and wholeBeatsPerSecond:
		for beatNumber in range(totalWholeBeats*4):
			var beatTime = beatNumber/(wholeBeatsPerSecond*4)
			quarterBeatTimes.append(beatTime)
		quarterBeatTimesGenerated = true

## Returns true if the necessary values to draw ticks are ready.
func _get_if_ticks_are_drawable() -> bool:
	if secondsPerWholeBeat != 0.0 and wholeBeatsPerSecond != 0.0:
		return true
	else: return false
