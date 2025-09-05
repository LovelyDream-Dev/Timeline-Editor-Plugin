class_name TimelineGUI
extends Control

# Nodes
var scrollContainer:ScrollContainer
var baseControl:Control

## If applicable, the length of the song in seconds used to calculate [member timelineLengthInPixels].
@export var songLengthInSeconds:float
## Beats Per Minute/Tempo of the song. It is required to calculate [member timelineLengthInPixels].
@export var bpm:float
## The height of the beat ticks
@export var tickHeight:float
## The width of the beat ticks
@export var tickWidth:float
## The color of the beat ticks
@export var tickColor:Color
## If the tick ends are rounded
@export var roundedTicks:bool
## Determines the amount of ticks between each whole beat.
@export_range(1,16) var snapDivisor:int = 1



# Values
## Length of the timeline in pixels
var timelineLengthInPixels:float
## If applicable, the current position of the song.
var songPosition:float
## If applicable, the total amount of whole beats in the song.
var totalWholeBeats:int
## Array of the times in seconds of all whole beats within the song
var wholeBeatTimes:Array = []
## Tracks if whole beat times have already been generated
var wholeBeatTimesGenerated:bool
## How many seconds a whole beat lasts
var secondsPerWholeBeat:float
## How many whole beats are in a second
var wholeBeatsPerSecond:float


func _ready() -> void:
	scrollContainer = $ScrollContainer
	baseControl = $ScrollContainer/BaseControl
	_init_timeline()

func _process(delta: float) -> void:
	baseControl.custom_minimum_size.x = _get_timeline_length_from_song_length()
	wholeBeatsPerSecond = bpm/60
	secondsPerWholeBeat = 60/bpm
	totalWholeBeats = wholeBeatsPerSecond * songLengthInSeconds
	_get_whole_beat_times()

func _get_timeline_length_from_song_length() -> float: 
	return songLengthInSeconds * bpm

## Uses [method valueInSeconds] to find the related pixel position on the timeline. [br]Returns [code]0.0[/code] if [method valueInSeconds] is greater than [method songLengthInSeconds].
func _get_timeline_position_from_song_position(valueinSeconds:float) -> float:
	if valueinSeconds <= songLengthInSeconds:
		return valueinSeconds * bpm
	else: 
		return 0.0
	
func _init_timeline():
	self.size = Vector2(get_viewport_rect().size.x, 50)
	scrollContainer.size = Vector2(get_viewport_rect().size.x, 50)

func _get_whole_beat_times():
	if !wholeBeatTimesGenerated and wholeBeatsPerSecond:
		for beatNumber in range(totalWholeBeats):
			var beatTime = beatNumber/wholeBeatsPerSecond
			wholeBeatTimes.append(beatTime)
			wholeBeatTimesGenerated = true

## Returns true if the necessary values to draw ticks are ready.
func _get_if_ticks_are_drawable() -> bool:
	if secondsPerWholeBeat != 0.0 and wholeBeatsPerSecond != 0.0:
		return true
	else: return false
