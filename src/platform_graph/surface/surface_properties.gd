class_name SurfaceProperties
extends Reference


# FIXME: LEFT OFF HERE: -----------------------
# - Add a can-grab flag.
# - Add friction.
# - Add a max-speed modifier.
# - Add some way of checking fall-through/walk-through state.
#   - And add a way to validate that this matches the normal TileSet encoding.
# - Update config in SquirrelAway.

const KEYS := [
    "can_grab",
    "friction_multiplier",
]

var name: String

var can_grab := true

var friction_multiplier := 1.0
