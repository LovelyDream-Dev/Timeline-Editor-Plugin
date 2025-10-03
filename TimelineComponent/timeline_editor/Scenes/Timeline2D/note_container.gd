extends Node2D
class_name Note_Container

# The root node of the scene
var rootNode:Timeline
# The scroll container
var scrollContainer:ScrollContainer
# The local position of the mouse in pixels on the timeline
var mouseTimelinePosition:float

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


func _ready() -> void:
	place_timeline_note(1)
	place_timeline_note(2)
	place_timeline_note(3)
	place_timeline_note(4)
	rootNode = get_parent().get_parent().get_parent()
	scrollContainer = get_parent().get_parent()

func _input(event: InputEvent) -> void:
	# Get the timeline mouse position if the mouse is moving within the timeline
	if scrollContainer.get_rect().has_point(get_global_mouse_position()):
		if event is InputEventMouseMotion:
			mouseTimelinePosition = scrollContainer.make_input_local(event).position.x + scrollContainer.scroll_horizontal

func _process(_delta: float) -> void:
	# Stops this function from processing in the editor
	if Engine.is_editor_hint():
		return

	mouseBeatPosition = (mouseTimelinePosition / rootNode.pixelsPerWholeBeat) 
	get_snapped_position()

# --- CUSTOM FUNCTIONS ---

func select_and_drag_notes(selectedNotes:Array):
	if Input.is_action_pressed(rootNode.LMB_ActionName):
		for note:Sprite2D in selectedNotes:
			note.position.x += (mouseBeatPosition - snappedBeat)

func get_timeline_position_from_beat(beat:float) -> Vector2:
	var posx = beat * rootNode.pixelsPerWholeBeat
	var posy = rootNode.get_rect().size.y/2
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
	snapInterval = 1.0/float(rootNode.snapDivisor)
	snappedBeat = round(mouseBeatPosition / snapInterval) * snapInterval
	snappedPixel = snappedBeat * rootNode.pixelsPerWholeBeat
	snappedSongPosition = snappedBeat * rootNode.secondsPerWholeBeat
