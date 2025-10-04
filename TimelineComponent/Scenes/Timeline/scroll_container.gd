extends ScrollContainer

signal SCROLL_CHANGED

var rootNode:Timeline
var lastScrollX:float = 0

func _ready() -> void:
	rootNode = get_parent()

func _process(_delta: float) -> void:
	self.custom_minimum_size = rootNode.get_rect().size
	get_if_scroll_changed()

func get_if_scroll_changed():
	if lastScrollX != scroll_horizontal:
		lastScrollX = scroll_horizontal
		SCROLL_CHANGED.emit()
