# Information for how to move from surface to surface to get from the given origin to the given
# destination.
# 
# We do not use separate data structures to represent movement along a surface from an earlier
# landing position to a later jump position. Instead, the navigator automatically handles this by
# simply moving up/down/left/right along the surface in the direction of the next jump position.
# 
# There are one fewer edges than surface nodes. The navigator has special logic for moving within
# the last surface node from the landing position of the last edge to the destination position
# within the surface.
extends Reference
class_name PlatformGraphPath

var surface_origin: PositionAlongSurface
var surface_destination: PositionAlongSurface

# Each PlatformGraphEdge contains a reference to its source and destination Surface nodes, so 
# we don't need to store them separately.
# Array<PlatformGraphEdge>
var edges: Array

# Optional, movement from the origin to the start of the first edge.
# Array<PlayerInstruction>
var start_instructions: Array
var start_instructions_origin: Vector2
var has_start_instructions: bool

# Optional, movement from the end of the last edge to the destination.
# Array<PlayerInstruction>
var end_instructions: Array
var end_instructions_destination: Vector2
var has_end_instructions: bool

func _init(surface_origin: PositionAlongSurface, surface_destination: PositionAlongSurface, \
        edges: Array, start_instructions := [], start_instructions_origin := Vector2.INF, \
        end_instructions := [], end_instructions_destination := Vector2.INF) -> void:
    self.surface_origin = surface_origin
    self.surface_destination = surface_destination
    self.edges = edges
    
    self.has_start_instructions = !start_instructions.empty()
    self.start_instructions = start_instructions
    self.start_instructions_origin = start_instructions_origin
    
    self.has_end_instructions = !end_instructions.empty()
    self.end_instructions = end_instructions
    self.end_instructions_destination = end_instructions_destination
