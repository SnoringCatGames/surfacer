class_name SubtileCorner
extends Reference


enum {
    UNKNOWN,
    
    # Air or space beyond the collision boundary.
    EMPTY,
    # Space inside the collision boundary, but before transitioning to the
    # more-faded interior (green, purple, yellow, or light-grey in the
    # template).
    EXTERIOR,
    # Space both inside the collision boundary, and after transitioning to the
    # more-faded interior (the darker grey colors in the template).
    INTERIOR,
    
    EXT_90H,
    EXT_90V,
    EXT_90_90_CONVEX,
    
    EXT_45_FLOOR,
    EXT_45_CEILING,
    
    EXT_CLIPPED_90_90,
    EXT_CLIPPED_45_45,
    EXT_CLIPPED_90H_45,
    EXT_CLIPPED_90V_45,
    
    EXT_90H_TO_45_CONVEX,
    EXT_90V_TO_45_CONVEX,
    EXT_90H_TO_45_CONVEX_ACUTE,
    EXT_90V_TO_45_CONVEX_ACUTE,

    EXT_45_FLOOR_TO_90,
    EXT_45_FLOOR_TO_45_CONVEX,
    EXT_45_CEILING_TO_90,
    EXT_45_CEILING_TO_45_CONVEX,
    
    
    EXT_CLIPPED_27_SHALLOW,
    EXT_CLIPPED_27_STEEP,
    
    EXT_27_FLOOR_SHALLOW_CLOSE,
    EXT_27_FLOOR_SHALLOW_FAR,
    EXT_27_FLOOR_STEEP_CLOSE,
    EXT_27_FLOOR_STEEP_FAR,
    
    EXT_27_CEILING_SHALLOW_CLOSE,
    EXT_27_CEILING_SHALLOW_FAR,
    EXT_27_CEILING_STEEP_CLOSE,
    EXT_27_CEILING_STEEP_FAR,
    
    
    
    
    
    INT_90H,
    INT_90V,
    INT_90_90_CONCAVE,
    INT_90_90_CONVEX,
    INT_90H_TO_45,
    INT_90V_TO_45,
    INT_90H_TO_27_SHALLOW,
    INT_90H_TO_27_STEEP_SHORT,
    INT_90H_TO_27_STEEP_LONG,
    INT_90V_TO_27_SHALLOW_SHORT,
    INT_90V_TO_27_SHALLOW_LONG,
    INT_90V_TO_27_STEEP,
    
    INT_45_EXT_CORNER,
    INT_45_EXT_CORNER_TO_90H,
    INT_45_EXT_CORNER_TO_90V,
    INT_45_EXT_CORNER_TO_90H_AND_90V,
    
    INT_45_INT_CORNER,
    INT_45_INT_CORNER_WITH_90_90_CONCAVE,
    INT_45_INT_CORNER_WITH_90_90_CONVEX,
    INT_45_INT_CORNER_WITH_90H,
    INT_45_INT_CORNER_WITH_90V,
    INT_45_INT_CORNER_NARROW,
    INT_45_MID_NOTCH_H,
    INT_45_MID_NOTCH_V,
    
    INT_27_INT_CORNER_SHALLOW,
    INT_27_INT_CORNER_STEEP,
}
