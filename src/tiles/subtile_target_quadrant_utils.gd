class_name SubtileTargetQuadrantUtils
extends Reference


const _TARGET_CORNERS_WITH_TARGET_QUADRANTS := [
#    [{
#        a = 90,
#        tl = EXT_90_90_CONVEX,
#        tr = EXT_90_90_CONVEX,
#        bl = EXT_90V,
#        br = EXT_90V,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90_90_CONVEX,
#        tr = EXT_90H,
#        bl = EXT_90V,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90H,
#        tr = EXT_90H,
#        bl = EXT_CLIPPED_90_90,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90H,
#        tr = EXT_90_90_CONVEX,
#        bl = EXT_CLIPPED_90_90,
#        br = EXT_90V,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXT_CLIPPED_90_90,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90H,
#        tr = EXT_90H,
#        bl = EXT_CLIPPED_90_90,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90H,
#        tr = EXT_90H,
#        bl = EXTERIOR,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXTERIOR,
#        bl = EXT_CLIPPED_90_90,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90_90_CONVEX,
#        tr = EXT_90H,
#        bl = EXT_90V,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXTERIOR,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90H,
#        tr = EXT_90H,
#        bl = EXTERIOR,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90H,
#        tr = EXT_90_90_CONVEX,
#        bl = EXTERIOR,
#        br = EXT_90V,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = [90,45,27],
#        tl = EXT_90V,
#        tr = EXT_90V,
#        bl = EXT_90V,
#        br = EXT_90V,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90V,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXT_90V,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXT_CLIPPED_90_90,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXT_90V,
#        bl = EXT_CLIPPED_90_90,
#        br = EXT_90V,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90V,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXT_90V,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXTERIOR,
#        bl = EXTERIOR,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXTERIOR,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXT_90V,
#        bl = EXTERIOR,
#        br = EXT_90V,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90V,
#        tr = EXTERIOR,
#        bl = EXT_90V,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXTERIOR,
#        bl = EXTERIOR,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
##        {
##            p = Vector2(10,1),
##            a = 90,
##            tl = UNKNOWN,
##            tr = UNKNOWN,
##            bl = UNKNOWN,
##            br = UNKNOWN,
##        },
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXTERIOR,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90V,
#        tr = EXT_90V,
#        bl = EXT_90_90_CONVEX,
#        br = EXT_90_90_CONVEX,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90V,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXT_90_90_CONVEX,
#        br = EXT_90H,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXT_90H,
#        br = EXT_90H,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXT_90V,
#        bl = EXT_90H,
#        br = EXT_90_90_CONVEX,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90V,
#        tr = EXTERIOR,
#        bl = EXT_90V,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXTERIOR,
#        bl = EXT_CLIPPED_90_90,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXTERIOR,
#        bl = EXTERIOR,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXT_90V,
#        bl = EXT_CLIPPED_90_90,
#        br = EXT_90V,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXTERIOR,
#        bl = EXT_CLIPPED_90_90,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
##        {
##            p = Vector2(9,2),
##            a = 90,
##            tl = EXTERIOR,
##            tr = EXTERIOR,
##            bl = EXTERIOR,
##            br = EXTERIOR,
##        },
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXT_CLIPPED_90_90,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXT_90V,
#        bl = EXTERIOR,
#        br = EXT_90V,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90_90_CONVEX,
#        tr = EXT_90_90_CONVEX,
#        bl = EXT_90_90_CONVEX,
#        br = EXT_90_90_CONVEX,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90_90_CONVEX,
#        tr = EXT_90H,
#        bl = EXT_90_90_CONVEX,
#        br = EXT_90H,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = [90,45,27],
#        tl = EXT_90H,
#        tr = EXT_90H,
#        bl = EXT_90H,
#        br = EXT_90H,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90H,
#        tr = EXT_90_90_CONVEX,
#        bl = EXT_90H,
#        br = EXT_90_90_CONVEX,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXTERIOR,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXTERIOR,
#        bl = EXT_90H,
#        br = EXT_90H,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXT_90H,
#        br = EXT_90H,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_CLIPPED_90_90,
#        tr = EXT_CLIPPED_90_90,
#        bl = EXT_CLIPPED_90_90,
#        br = EXTERIOR,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXT_90V,
#        tr = EXTERIOR,
#        bl = EXT_90_90_CONVEX,
#        br = EXT_90H,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXTERIOR,
#        bl = EXT_90H,
#        br = EXT_90H,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXTERIOR,
#        bl = EXT_CLIPPED_90_90,
#        br = EXT_CLIPPED_90_90,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
#    [{
#        a = 90,
#        tl = EXTERIOR,
#        tr = EXT_90V,
#        bl = EXT_90H,
#        br = EXT_90_90_CONVEX,
#    }, {
#        tl = SubtileQuadrant.,
#        tr = SubtileQuadrant.,
#        bl = SubtileQuadrant.,
#        br = SubtileQuadrant.,
#    }],
]


























# Dictionary<
#   int, # Angle type
#   Dictionary<
#     int, # Top-left
#     Dictionary<
#       int, # Top-right
#       Dictionary<
#         int, # Bottom-left
#         Dictionary<
#           int, # Bottom-right
#           [int, int, int, int] # Quadrants: tl, tr, bl, br
#         >>>>>
const _CORNERS_TO_QUADRANTS_MAP := {}


static func _get_target_quadrants(proximity: CellProximity) -> Array:
    # FIXME: LEFT OFF HERE: ------------------------------
    return []
