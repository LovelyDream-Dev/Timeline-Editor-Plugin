@tool
extends ScrollContainer

var rootNode:Timeline

func _ready() -> void:
	rootNode = get_parent()

func _process(_delta: float) -> void:
	self.custom_minimum_size = rootNode.get_rect().size
