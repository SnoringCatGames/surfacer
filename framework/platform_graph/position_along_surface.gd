# A reference to the actual surface node, and a specification for position along that node.
# 
# FIXME: ACTUALLY, should the following be true? Not extending past might be both slightly more realistic as well as better for handling the offset I wanted to add before jumping landing near the edge anyway...
# Note: A position along a surface could actually extend past the edges of the surface. This is
# because a player's bounding box has non-zero width and height.
# 
# The position always indicates the center of the player's bounding box.
extends Reference
class_name PositionAlongSurface

func _init():
    pass

# TODO
# - A reference to the actual surface/Node
# - Specification for position along that node.
# - Node type
