# Information for how to move from a start position on one surface to an end position on another
# surface.
extends Reference
class_name EdgeInstructions

var is_possible = true

func _init(is_possible = true):
    self.is_possible = is_possible

# TODO
# - start_node_start_pos: PositionAlongSurface
# - end_node_end_pos: PositionAlongSurface
# - end_node_start_pos: PositionAlongSurface
# - end_node_end_pos: PositionAlongSurface
# - instruction set to move from start to end node
# - instruction set to move within start node
# - instruction set to move within end node
