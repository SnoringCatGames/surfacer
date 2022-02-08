class_name TileSetImageParser
extends Reference


static func parse_corner_type_annotation_key(
        corner_type_annotation_key_path: String,
        quadrant_size: int) -> Dictionary:
    # FIXME: LEFT OFF HERE: ----------------------------
    # - Load image.
    # - Calculate row and column count.
    # - Assert that no pixels are present except the top-left 4x4 in each quadrant.
    # - Assert that all pixels in a quadrant are the same color.
    # - Assert that the number of quadrants in the key are equal to the number
    #   of SubtileCorner enum values (or 1 greater).
    # - Store annotation pixels in a flat 16-sized array.
    # - Return mapping from corner-type to annotation shape.
    return {}


static func parse_tile_set_corner_type_annotations(
        tile_set_corner_type_annotations_path: String,
        quadrant_size: int) -> void:
    # FIXME: LEFT OFF HERE: ----------------------------
    # - Load image.
    # - Calculate subtile row and column count.
    # - Map corner (tl|tr|bl|br) to corner-type to horizontal-opposite-corner-type to vertical-opposite-corner-type to subtile position.
    #   - Actually, do this a bit more efficiently:
    #     - Calculate a single int that represents the three relevant corner types:
    #       - self + h-opp << 10 + v-opp << 20
    #     - Then map corner to this int to subtile position.
    pass
