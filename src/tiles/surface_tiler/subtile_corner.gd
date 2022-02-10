class_name SubtileCorner
extends Reference


enum {
    UNKNOWN,
    
    # It's useful to render a high-contrast error subtile in order to alert the
    # level author when the subtile configuration they are trying to use isn't
    # defined.
    ERROR,
    
    # Air or space beyond the collision boundary.
    EMPTY,
    
    # Space both inside the collision boundary, and after transitioning to the
    # more-faded interior (the darkest grey color in the template).
    FULLY_INTERIOR,
    
    ### 90-degree.
    
    EXT_90H,
    EXT_90V,
    EXT_90_90_CONVEX,
    EXT_90_90_CONCAVE,
    
    EXT_INT_90H,
    EXT_INT_90V,
    EXT_INT_90_90_CONVEX,
    EXT_INT_90_90_CONCAVE,
    
    INT_90H,
    INT_90V,
    INT_90_90_CONVEX,
    INT_90_90_CONCAVE,
    
    ### 45-degree.
    
    EXT_45_FLOOR,
    EXT_45_CEILING,
    EXT_EXT_45_CLIPPED,
    
    EXT_INT_45_FLOOR,
    EXT_INT_45_CEILING,
    EXT_INT_45_CLIPPED,
    
    INT_EXT_45_CLIPPED,
    
    INT_45_FLOOR,
    INT_45_CEILING,
    INT_INT_45_CLIPPED,
    
    ### 90-to-45-degree.
    
    EXT_90H_45_CONVEX_ACUTE,
    EXT_90V_45_CONVEX_ACUTE,
    
    EXT_90H_45_CONVEX,
    EXT_90V_45_CONVEX,
    
    EXT_90H_45_CONCAVE,
    EXT_90V_45_CONCAVE,
    
    EXT_INT_90H_45_CONVEX,
    EXT_INT_90V_45_CONVEX,
    
    EXT_INT_90H_45_CONCAVE,
    EXT_INT_90V_45_CONCAVE,
    
    INT_EXT_90H_45_CONCAVE,
    INT_EXT_90V_45_CONCAVE,
    
    INT_INT_90H_45_CONCAVE,
    INT_INT_90V_45_CONCAVE,
    
    ### Complex 90-45-degree combinations.
    
    EXT_INT_45_FLOOR_45_CEILING,
    
    INT_45_FLOOR_45_CEILING,
    
    EXT_INT_90H_45_CONVEX_ACUTE,
    EXT_INT_90V_45_CONVEX_ACUTE,
    
    INT_90H_EXT_INT_45_CONVEX_ACUTE,
    INT_90V_EXT_INT_45_CONVEX_ACUTE,
    
    INT_90H_EXT_INT_90H_45_CONCAVE,
    INT_90V_EXT_INT_90V_45_CONCAVE,
    
    
    INT_90H_INT_EXT_45_CLIPPED,
    INT_90V_INT_EXT_45_CLIPPED,
    INT_90_90_CONVEX_INT_EXT_45_CLIPPED,
    
    INT_INT_90H_45_CONCAVE_90V_45_CONCAVE,
    INT_INT_90H_45_CONCAVE_INT_45_CEILING,
    INT_INT_90V_45_CONCAVE_INT_45_FLOOR,
    
    INT_90H_INT_INT_90V_45_CONCAVE,
    INT_90V_INT_INT_90H_45_CONCAVE,
    
    INT_90_90_CONCAVE_INT_45_FLOOR,
    INT_90_90_CONCAVE_INT_45_CEILING,
    INT_90_90_CONCAVE_INT_45_FLOOR_45_CEILING,
    
    INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE,
    INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE,
    
    INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE,
    
    INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_CEILING,
    INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_FLOOR,
    
    ### 27-degree.
    
    # FIXME: LEFT OFF HERE: ------------------
    
#    EXT_27_SHALLOW_CLIPPED,
#    EXT_27_STEEP_CLIPPED,
#
#    EXT_27_FLOOR_SHALLOW_CLOSE,
#    EXT_27_FLOOR_SHALLOW_FAR,
#    EXT_27_FLOOR_STEEP_CLOSE,
#    EXT_27_FLOOR_STEEP_FAR,
#
#    EXT_27_CEILING_SHALLOW_CLOSE,
#    EXT_27_CEILING_SHALLOW_FAR,
#    EXT_27_CEILING_STEEP_CLOSE,
#    EXT_27_CEILING_STEEP_FAR,
#
#
#    INT_27_INT_CORNER_SHALLOW,
#    INT_27_INT_CORNER_STEEP,
    
    
    ### 90-to-27-degree.
    
    # FIXME: LEFT OFF HERE: ------------------
    
    ### 45-to-27-degree.
    
    # FIXME: LEFT OFF HERE: ------------------
}
