@tool
extends Node2D

var rootNode:TimelineGUI
## When enabled, "ui_accept" will refresh ticks 
@export var debug:bool 

var initialTicksDrawn:bool

func _ready() -> void:
	rootNode = get_parent().get_parent().get_parent()

func _input(_event: InputEvent) -> void:
	if debug:
		if Input.is_action_just_pressed("ui_accept") and rootNode._get_if_ticks_are_drawable():
			_refresh_ticks()

func _process(delta: float) -> void:
	if !initialTicksDrawn and rootNode._get_if_ticks_are_drawable():
		queue_redraw()
		initialTicksDrawn = true

func _draw_beat_ticks(BeatTime:float, tickHeight:float, tickWidth:float, tickColor:Color, rounded:bool):
	draw_line(Vector2(rootNode._get_timeline_position_from_song_position(BeatTime),rootNode.get_rect().size.y), Vector2(rootNode._get_timeline_position_from_song_position(BeatTime),rootNode.get_rect().size.y-tickHeight), tickColor, tickWidth, true)
	if rootNode.roundedTicks:
		draw_circle(Vector2(rootNode._get_timeline_position_from_song_position(BeatTime),rootNode.get_rect().size.y-tickHeight), tickWidth/2, tickColor, true, -1.0, true)

func _draw() -> void:
	for wholeBeatTime in rootNode.wholeBeatTimes:
		_draw_beat_ticks(wholeBeatTime, rootNode.tickHeight, rootNode.tickWidth, rootNode.tickColor, rootNode.roundedTicks)
	if rootNode.snapDivisor == 2:
		for halfBeatTime in rootNode.halfBeatTimes:
			_draw_beat_ticks(halfBeatTime, rootNode.tickHeight/2, rootNode.tickWidth, rootNode.tickColor, rootNode.roundedTicks)
	elif rootNode.snapDivisor == 4:
		for quarterBeatTime in rootNode.quarterBeatTimes:
			_draw_beat_ticks(quarterBeatTime, (rootNode.tickHeight/2), rootNode.tickWidth, rootNode.tickColor, rootNode.roundedTicks)
			

## Refreshes beat ticks
func _refresh_ticks():
	queue_redraw()
