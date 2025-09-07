@tool
extends Node2D

var rootNode:Timeline
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
	draw_line(Vector2(rootNode._get_timeline_position_from_song_position(BeatTime), (rootNode.get_rect().size.y/2) + (tickHeight/2)), Vector2(rootNode._get_timeline_position_from_song_position(BeatTime), (rootNode.get_rect().size.y/2) - (tickHeight/2)), tickColor, tickWidth, true)
	if rootNode.roundedTicks:
		draw_circle(Vector2(rootNode._get_timeline_position_from_song_position(BeatTime), (rootNode.get_rect().size.y/2) + (tickHeight/2)), tickWidth/2, tickColor, true, -1.0, true)
		draw_circle(Vector2(rootNode._get_timeline_position_from_song_position(BeatTime), (rootNode.get_rect().size.y/2) - (tickHeight/2)), tickWidth/2, tickColor, true, -1.0, true)

## Checks if the given tick time is overlapped with another tick time of a different type (1: Whole tick 2: half tick 4: quarter tick, etc...), allowing said time to be excluded if it is a member of a smaller snap divisor. [br]Whole ticks are never excluded, tick type of 1 will have no effect.
func _get_if_tick_time_overlaps(tickTime:float, tickType:int):
	if tickType == 2: # half ticks
		if tickTime in rootNode.wholeBeatTimes:
			return true
	elif tickType == 4: # quarter ticks
		if tickTime in rootNode.halfBeatTimes:
			return true

func _draw() -> void:
	for wholeBeatTime in rootNode.wholeBeatTimes: # Draw whole ticks (always drawn)
		_draw_beat_ticks(wholeBeatTime, rootNode.tickHeight, rootNode.tickWidth, rootNode.wholeBeatTickColor, rootNode.roundedTicks)
	
	if rootNode.snapDivisor == 2: # Draw half ticks
		for halfBeatTime in rootNode.halfBeatTimes:
			if !_get_if_tick_time_overlaps(halfBeatTime, 2):
				_draw_beat_ticks(halfBeatTime, rootNode.tickHeight/2, rootNode.tickWidth, rootNode.halfBeatTickColor, rootNode.roundedTicks)

	elif rootNode.snapDivisor == 4: # Draw quarter ticks and subsequent ticks
		for quarterBeatTime in rootNode.quarterBeatTimes: # Quarter
			if !_get_if_tick_time_overlaps(quarterBeatTime, 4):
				_draw_beat_ticks(quarterBeatTime, rootNode.tickHeight/2.5, rootNode.tickWidth, rootNode.quarterBeatTickColor, rootNode.roundedTicks)
		for halfBeatTime in rootNode.halfBeatTimes: # Half
			if !_get_if_tick_time_overlaps(halfBeatTime, 2):
				_draw_beat_ticks(halfBeatTime, rootNode.tickHeight/2, rootNode.tickWidth, rootNode.halfBeatTickColor, rootNode.roundedTicks)

## Refreshes beat ticks
func _refresh_ticks():
	queue_redraw()
