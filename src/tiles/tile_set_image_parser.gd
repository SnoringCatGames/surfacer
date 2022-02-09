class_name TileSetImageParser
extends Reference


const ANNOTATION_SIZE := Vector2(4,4)


# -   Returns a mapping from pixel-color to pixel-bit-flag to corner-type.
# Dictionary<int, Dictionary<int, int>>
static func parse_corner_type_annotation_key(
        corner_type_annotation_key_path: String,
        quadrant_size: int) -> Dictionary:
    # FIXME: LEFT OFF HERE: ----------------------------
    # -   Flip annotation-key x and y to match non-top-left corners.
    # -   Assert that no pixels are present except the top-left 4x4 in each quadrant.
    # -   Handle annotations for matching inbound neighbor corner-types!
    
    assert(quadrant_size >= ANNOTATION_SIZE.x * 2)
    assert(quadrant_size >= ANNOTATION_SIZE.y * 2)
    
    var texture: Texture = load(corner_type_annotation_key_path)
    var image: Image = texture.get_data()
    
    var size := image.get_size()
    assert(int(size.x) % quadrant_size == 0)
    assert(int(size.y) % quadrant_size == 0)
    
    var quadrant_row_count := int(size.y) / quadrant_size
    var quadrant_column_count := int(size.x) / quadrant_size
    
    var quadrant_count := quadrant_row_count * quadrant_column_count
    var corner_type_count := SubtileCorner.get_script_constant_map().size()
    assert(quadrant_count >= corner_type_count or \
            quadrant_count <= corner_type_count + quadrant_row_count - 1,
            "The corner-type annotation key must have an entry for each " +
            "corner-type enum and no extras.")
    
    var corner_type_annotations := {}
    
    image.lock()
    
    for quadrant_row_index in quadrant_row_count:
        for quadrant_column_index in quadrant_column_count:
            var quadrant_position := \
                    Vector2(quadrant_row_index, quadrant_column_index) * \
                    quadrant_size
            # This int corresponds to the SubtileCorner enum value.
            var corner_type: int = \
                    quadrant_row_index * quadrant_column_count + \
                    quadrant_column_index
            var annotation := _get_quadrant_annotation(
                    quadrant_position,
                    image,
                    corner_type_annotation_key_path,
                    true,
                    true)
            var color: int = annotation.color
            var bits: int = annotation.bits
            assert(bits != 0,
                    "Corner-type annotations cannot be empty: " +
                    "image=%s, quadrant=%s" % [
                        corner_type_annotation_key_path,
                        Sc.utils.get_vector_string(quadrant_position, 0),
                    ])
            if !corner_type_annotations.has(color):
                corner_type_annotations[color] = {}
            assert(!corner_type_annotations[color].has(bits),
                    "Multiple corner-type annotations have the same shape " +
                    "and color: quadrant=%s" % \
                    Sc.utils.get_vector_string(quadrant_position, 0))
            corner_type_annotations[color][bits] = corner_type
    
    image.unlock()
    
    return corner_type_annotations


# -   Returns a mapping from tl/tr/bl/br to a combined-corner-types-int to quadrant position.
# -   The combined-corner-types-int is calculated as follows:
#     self-corner + h-opp-corner << 10 + v-opp-corner << 20
# Dictionary<("tl"|"tr"|"bl"|"br"), Dictionary<int, Vector2>>
static func parse_tile_set_corner_type_annotations(
        corner_type_annotation_key: Dictionary,
        tile_set_corner_type_annotations_path: String,
        quadrant_size: int) -> Dictionary:
    var subtile_size := quadrant_size * 2
    
    var texture: Texture = load(tile_set_corner_type_annotations_path)
    var image: Image = texture.get_data()
    
    var size := image.get_size()
    assert(int(size.x) % subtile_size == 0)
    assert(int(size.y) % subtile_size == 0)
    
    var subtile_row_count := int(size.y) / subtile_size
    var subtile_column_count := int(size.x) / subtile_size
    
    var subtile_corner_types := {
        tl = {},
        tr = {},
        bl = {},
        br = {},
    }
    
    image.lock()
    
    for subtile_row_index in subtile_row_count:
        for subtile_column_index in subtile_column_count:
            var subtile_position := \
                    Vector2(subtile_column_index, subtile_row_index)
            var tl_quadrant_position := subtile_position * 2 + Vector2(0,0)
            var tr_quadrant_position := subtile_position * 2 + Vector2(1,0)
            var bl_quadrant_position := subtile_position * 2 + Vector2(0,1)
            var br_quadrant_position := subtile_position * 2 + Vector2(1,1)
            
            var tl_corner_annotation := _get_quadrant_annotation(
                    tl_quadrant_position,
                    image,
                    tile_set_corner_type_annotations_path,
                    true,
                    true)
            var tr_corner_annotation := _get_quadrant_annotation(
                    tr_quadrant_position,
                    image,
                    tile_set_corner_type_annotations_path,
                    true,
                    false)
            var bl_corner_annotation := _get_quadrant_annotation(
                    bl_quadrant_position,
                    image,
                    tile_set_corner_type_annotations_path,
                    false,
                    true)
            var br_corner_annotation := _get_quadrant_annotation(
                    br_quadrant_position,
                    image,
                    tile_set_corner_type_annotations_path,
                    false,
                    false)
            
            _validate_tileset_annotation(
                    tl_corner_annotation,
                    corner_type_annotation_key,
                    tl_quadrant_position,
                    true,
                    true,
                    tile_set_corner_type_annotations_path)
            _validate_tileset_annotation(
                    tr_corner_annotation,
                    corner_type_annotation_key,
                    tr_quadrant_position,
                    true,
                    false,
                    tile_set_corner_type_annotations_path)
            _validate_tileset_annotation(
                    bl_corner_annotation,
                    corner_type_annotation_key,
                    bl_quadrant_position,
                    false,
                    true,
                    tile_set_corner_type_annotations_path)
            _validate_tileset_annotation(
                    br_corner_annotation,
                    corner_type_annotation_key,
                    br_quadrant_position,
                    false,
                    false,
                    tile_set_corner_type_annotations_path)
            
            var tl_corner_type: int = corner_type_annotation_key \
                    [tl_corner_annotation.color][tl_corner_annotation.bits]
            var tr_corner_type: int = corner_type_annotation_key \
                    [tr_corner_annotation.color][tr_corner_annotation.bits]
            var bl_corner_type: int = corner_type_annotation_key \
                    [bl_corner_annotation.color][bl_corner_annotation.bits]
            var br_corner_type: int = corner_type_annotation_key \
                    [br_corner_annotation.color][br_corner_annotation.bits]
            
            var tl_corner_types_flag := \
                    tl_corner_type + \
                    tr_corner_type << 10 + \
                    bl_corner_type << 20
            var tr_corner_types_flag := \
                    tr_corner_type + \
                    tl_corner_type << 10 + \
                    br_corner_type << 20
            var bl_corner_types_flag := \
                    bl_corner_type + \
                    br_corner_type << 10 + \
                    tl_corner_type << 20
            var br_corner_types_flag := \
                    br_corner_type + \
                    bl_corner_type << 10 + \
                    tr_corner_type << 20
            
            # FIXME: Remove these warnings? Are they useful? Or just noise?
            if subtile_corner_types.tl.has(tl_corner_types_flag):
                var previous_subtile_position := \
                        floor(subtile_corner_types.tl[tl_corner_types_flag] / 2)
                Sc.logger.warning(
                        ("Multiple subtiles have the same relative corner " +
                        "configuration: top-left, " +
                        "subtile_1=%s, subtile_2=%s") % [
                            previous_subtile_position,
                            subtile_position,
                        ])
            if subtile_corner_types.tr.has(tr_corner_types_flag):
                var previous_subtile_position := \
                        floor(subtile_corner_types.tr[tr_corner_types_flag] / 2)
                Sc.logger.warning(
                        ("Multiple subtiles have the same relative corner " +
                        "configuration: top-right, " +
                        "subtile_1=%s, subtile_2=%s") % [
                            previous_subtile_position,
                            subtile_position,
                        ])
            if subtile_corner_types.bl.has(bl_corner_types_flag):
                var previous_subtile_position := \
                        floor(subtile_corner_types.bl[bl_corner_types_flag] / 2)
                Sc.logger.warning(
                        ("Multiple subtiles have the same relative corner " +
                        "configuration: bottom-left, " +
                        "subtile_1=%s, subtile_2=%s") % [
                            previous_subtile_position,
                            subtile_position,
                        ])
            if subtile_corner_types.br.has(br_corner_types_flag):
                var previous_subtile_position := \
                        floor(subtile_corner_types.br[br_corner_types_flag] / 2)
                Sc.logger.warning(
                        ("Multiple subtiles have the same relative corner " +
                        "configuration: bottom-right, " +
                        "subtile_1=%s, subtile_2=%s") % [
                            previous_subtile_position,
                            subtile_position,
                        ])
            
            subtile_corner_types.tl[tl_corner_types_flag] = tl_quadrant_position
            subtile_corner_types.tr[tr_corner_types_flag] = tr_quadrant_position
            subtile_corner_types.bl[bl_corner_types_flag] = bl_quadrant_position
            subtile_corner_types.br[br_corner_types_flag] = br_quadrant_position
    
    image.unlock()
    
    return subtile_corner_types


static func _validate_tileset_annotation(
        annotation: Dictionary,
        corner_type_annotation_key: Dictionary,
        quadrant_position: Vector2,
        is_top: bool,
        is_left: bool,
        image_path: String) -> void:
    var bits: int = annotation.bits
    var color: int = annotation.color
    var corner_label := "%s-%s" % [
                "top" if is_top else "bottom",
                "left" if is_left else "right",
            ]
    
    assert(bits != 0,
            ("Corner-type annotations cannot be empty: " +
            "image=%s, quadrant=%s, %s") % [
                image_path,
                Sc.utils.get_vector_string(quadrant_position, 0),
                corner_label,
            ])
    
    assert(corner_type_annotation_key.has(color),
            ("Corner-type-annotation color doesn't match the " +
            "annotation key: %s") % Color(color).to_html())
    
    if !corner_type_annotation_key[color].has(bits):
        var shape_string := ""
        for column_index in ANNOTATION_SIZE.x:
            shape_string += "\n"
            for row_index in ANNOTATION_SIZE.y:
                var bit_index := \
                        int(row_index * ANNOTATION_SIZE.x + column_index)
                var pixel_flag := 1 << bit_index
                var is_pixel_present := (bits & pixel_flag) != 0
                shape_string += "*" if is_pixel_present else "."
        Sc.logger.error(
                ("Corner-type-annotation shape doesn't match the " +
                "annotation key: %s") % shape_string)


static func _get_quadrant_annotation(
        quadrant_position: Vector2,
        image: Image,
        path: String,
        is_top: bool,
        is_left: bool) -> Dictionary:
    # FIXME: LEFT OFF HERE: ----------------------------
    # - Handle is_top ind is_left.
    var annotation_bits := 0
    var annotation_color := Color.transparent
    for annotation_row_index in ANNOTATION_SIZE.y:
        for annotation_column_index in ANNOTATION_SIZE.x:
            var bit_index := \
                    int(annotation_row_index * ANNOTATION_SIZE.x + \
                    annotation_column_index)
            var color := image.get_pixel(
                    quadrant_position.x + annotation_column_index,
                    quadrant_position.y + annotation_row_index)
            assert(color == Color.transparent or \
                    color == annotation_color or \
                    annotation_color == Color.transparent,
                    "Each corner-type annotation should use only a " +
                    "single color: " +
                    "image=%s, quadrant=%s, is_top=%s, is_left=%s" % [
                        path,
                        Sc.utils.get_vector_string(quadrant_position, 0),
                        is_top,
                        is_left,
                    ])
            annotation_color = color
            annotation_bits |= 1 << bit_index
    return {
        bits = annotation_bits,
        color = annotation_color.to_rgba64(),
    }
