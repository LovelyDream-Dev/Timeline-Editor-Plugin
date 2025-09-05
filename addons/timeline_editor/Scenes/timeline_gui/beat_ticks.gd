extends Node2D

@export var rootNode:TimelineGUI
## When enabled, "ui_accept" will refresh ticks 
@export var debug:bool 

var initialTicksDrawn:bool

func _input(_event: InputEvent) -> void:
	if debug:
		if Input.is_action_just_pressed("ui_accept") and rootNode._get_if_ticks_are_drawable():
			_refresh_ticks()

func _process(delta: float) -> void:
	if !initialTicksDrawn and rootNode._get_if_ticks_are_drawable():
		queue_redraw()
		initialTicksDrawn = true

func _draw_beat_ticks(wholeBeatTime:float, tickHeight:float, tickWidth:float, tickColor:Color, rounded:bool):
	# Whole beats
	draw_line(Vector2(rootNode._get_timeline_position_from_song_position(wholeBeatTime),rootNode.get_rect().size.y), Vector2(rootNode._get_timeline_position_from_song_position(wholeBeatTime),rootNode.get_rect().size.y-tickHeight), tickColor, tickWidth, true)
	if rootNode.roundedTicks:
		draw_circle(Vector2(rootNode._get_timeline_position_from_song_position(wholeBeatTime),rootNode.get_rect().size.y-tickHeight), tickWidth/2, tickColor, true, -1.0, true)
	# Half Beats
	if rootNode.snapDivisor == 2:
		draw_line(Vector2(rootNode._get_timeline_position_from_song_position(wholeBeatTime + (rootNode.secondsPerWholeBeat/2)),rootNode.get_rect().size.y), Vector2(rootNode._get_timeline_position_from_song_position(wholeBeatTime + (rootNode.secondsPerWholeBeat/2)),rootNode.get_rect().size.y-(tickHeight/2)), tickColor, tickWidth, true)
		if rootNode.roundedTicks:
			draw_circle(Vector2(rootNode._get_timeline_position_from_song_position(wholeBeatTime + (rootNode.secondsPerWholeBeat/2)),rootNode.get_rect().size.y-(tickHeight/2)), tickWidth/2, tickColor, true, -1.0, true)

func _draw() -> void:
	for wholeBeatTime in rootNode.wholeBeatTimes:
		_draw_beat_ticks(wholeBeatTime, rootNode.tickHeight, rootNode.tickWidth, rootNode.tickColor, rootNode.roundedTicks)

## Refreshes beat ticks
func _refresh_ticks():
	queue_redraw()
