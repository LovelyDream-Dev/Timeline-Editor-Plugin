extends Node2D

@onready var camera = get_viewport().get_camera_2d()

var rootNode:Timeline
var scrollContainer:ScrollContainer

var initialTicksDrawn:bool

# The last scroll position of the scrollContainer. Used to determine if the scroll container has scrolled.
var lastScrollX:float = 0

var cullingMargin:float
var showCullingRect:bool

func _ready() -> void:
	rootNode = get_parent().get_parent().get_parent()
	scrollContainer = get_parent().get_parent()

func _process(_delta: float) -> void:
	cullingMargin = rootNode.cullingMargin
	showCullingRect = rootNode.showCullingRect

	if !initialTicksDrawn and rootNode.get_if_ticks_are_drawable():
		queue_redraw()
		initialTicksDrawn = true

	# Determine if the scroll container has scrolled
	var currentScrollX = scrollContainer.scroll_horizontal
	if lastScrollX != currentScrollX:
		lastScrollX = currentScrollX
		on_scroll_changed()

func draw_beat_ticks(BeatTime:float, tickHeight:float, tickWidth:float, tickColor:Color, rounded:bool):
	var xPosition = rootNode.get_timeline_position_x_from_song_position(BeatTime)
	var yCenter = rootNode.get_rect().size.y/2
	
	#  \/ --- BEAT TICK CULLING WITH MARGIN --- \/

	# Get the visible rect of the scrollcontainer
	var scrollContainerRect:Rect2 = scrollContainer.get_rect()
	var cullingRect = Rect2(scrollContainerRect.position - Vector2(cullingMargin, cullingMargin), scrollContainerRect.size + Vector2(cullingMargin * 2.0, cullingMargin * 2.0))
	cullingRect.position.x += scrollContainer.scroll_horizontal
	var tickPos = Vector2(xPosition, yCenter)
	if !cullingRect.has_point(tickPos):
		return
	if showCullingRect:
		var visualDefaultRect:Rect2 = scrollContainerRect
		visualDefaultRect.position.x += scrollContainer.scroll_horizontal
		draw_rect(cullingRect, Color.YELLOW, false)
		draw_rect(visualDefaultRect, Color.RED, false)
	
	# /\ --- BEAT TICK CULLING WITH MARGIN --- /\

	draw_line(Vector2(xPosition, yCenter + (tickHeight/2)), Vector2(xPosition, yCenter - (tickHeight/2)), tickColor, tickWidth, true)
	if rounded:
		draw_circle(Vector2(xPosition, yCenter + (tickHeight/2)), tickWidth/2, tickColor, true, -1.0, true)
		draw_circle(Vector2(xPosition, yCenter - (tickHeight/2)), tickWidth/2, tickColor, true, -1.0, true)

## Checks if the given tick time is overlapped with another tick time of a different type (1: Whole tick 2: half tick 4: quarter tick, etc...), allowing said time to be excluded if it is a member of a smaller snap divisor. [br]Whole ticks are never excluded, tick type of 1 will have no effect.
func get_if_tick_time_overlaps(tickTime:float, tickType:int):
	if tickType == 2: # half ticks
		if tickTime in rootNode.wholeBeatTimes:
			return true
	elif tickType == 4: # quarter ticks
		if tickTime in rootNode.halfBeatTimes:
			return true
	elif tickType == 8: # eighth ticks
		if tickTime in rootNode.quarterBeatTimes:
			return true
	elif tickType == 16: # sixteenth ticks
		if tickTime in rootNode.eighthBeatTimes:
			return true

func _draw() -> void:
	# Draw whole ticks (always drawn)
	for i in range(len(rootNode.wholeBeatTimes)):
		var wholeBeatTime = rootNode.wholeBeatTimes[i]
		var isFourth = (i % 4 == 0)
		var tickwidth = rootNode.tickWidth if isFourth else rootNode.tickWidth * 0.7
		var fourthTickHeight:float = rootNode.get_rect().size.y-10
		var tickHeight = fourthTickHeight if isFourth else rootNode.tickHeight * 0.95
		draw_beat_ticks(wholeBeatTime, tickHeight, tickwidth, rootNode.wholeBeatTickColor, rootNode.roundedTicks)

	# Draw half ticks
	if rootNode.snapDivisor >= 2: 
		for halfBeatTime in rootNode.halfBeatTimes:
			if !get_if_tick_time_overlaps(halfBeatTime, 2):
				var tickHeight = rootNode.tickHeight * 0.85
				var tickwidth = rootNode.tickWidth * 0.65
				draw_beat_ticks(halfBeatTime, tickHeight, tickwidth, rootNode.halfBeatTickColor, rootNode.roundedTicks)

	# Draw quarter ticks
	if rootNode.snapDivisor >= 4: 
		for quarterBeatTime in rootNode.quarterBeatTimes: 
			if !get_if_tick_time_overlaps(quarterBeatTime, 4):
				var tickHeight = rootNode.tickHeight * 0.75
				var tickwidth = rootNode.tickWidth * 0.6
				draw_beat_ticks(quarterBeatTime, tickHeight, tickwidth, rootNode.quarterBeatTickColor, rootNode.roundedTicks)

	# Draw eighth ticks
	if rootNode.snapDivisor >= 8: 
		for eighthBeatTime in rootNode.eighthBeatTimes: 
			if !get_if_tick_time_overlaps(eighthBeatTime, 8):
				var tickHeight = rootNode.tickHeight * 0.65
				var tickwidth = rootNode.tickWidth * 0.55
				draw_beat_ticks(eighthBeatTime, tickHeight, tickwidth, rootNode.eighthBeatTickColor, rootNode.roundedTicks)

	# Draw sixteenth ticks
	if rootNode.snapDivisor >= 16: 
		for sixteenthBeatTime in rootNode.sixteenthBeatTimes: 
			if !get_if_tick_time_overlaps(sixteenthBeatTime, 16):
				var tickHeight = rootNode.tickHeight * 0.55
				var tickwidth = rootNode.tickWidth * 0.5
				draw_beat_ticks(sixteenthBeatTime, tickHeight, tickwidth, rootNode.sixteenthBeatTickColor, rootNode.roundedTicks)

## Refreshes beat ticks
func refresh_ticks():
	queue_redraw()

func on_scroll_changed():
	refresh_ticks()

func on_timeline_2d_snap_divisor_changed() -> void:
	refresh_ticks()
