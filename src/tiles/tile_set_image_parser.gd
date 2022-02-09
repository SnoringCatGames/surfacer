class_name TileSetImageParser
extends Reference


const ANNOTATION_SIZE := Vector2(4,4)

# This is the first 10 bits set.
const _CORNER_TYPE_BIT_MASK := 1 << 11 - 1


# -   Returns a mapping from pixel-color to pixel-bit-flag to corner-type.
# Dictionary<int, Dictionary<int, int>>
static func parse_corner_type_annotation_key(
        corner_type_annotation_key_path: String,
        quadrant_size: int) -> Dictionary:
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
    
    var corner_type_annotation_key := {}
    
    image.lock()
    
    for quadrant_row_index in quadrant_row_count:
        for quadrant_column_index in quadrant_column_count:
            var quadrant_position := \
                    Vector2(quadrant_row_index, quadrant_column_index) * \
                    quadrant_size
            # This int corresponds to the SubtileCorner enum value.
            var corner_type := int(
                    quadrant_row_index * quadrant_column_count + \
                    quadrant_column_index)
            var annotation := _get_quadrant_annotation(
                    quadrant_position,
                    quadrant_size,
                    image,
                    corner_type_annotation_key_path,
                    true,
                    true,
                    false,
                    false)
            var color: int = annotation.color
            var bits: int = annotation.bits
            assert(bits != 0,
                    "Corner-type annotations cannot be empty: " +
                    "image=%s, quadrant=%s" % [
                        corner_type_annotation_key_path,
                        Sc.utils.get_vector_string(quadrant_position, 0),
                    ])
            _check_for_empty_quadrant_non_annotation_pixels(
                    quadrant_position,
                    quadrant_size,
                    image,
                    corner_type_annotation_key_path,
                    true,
                    true)
            if !corner_type_annotation_key.has(color):
                corner_type_annotation_key[color] = {}
            assert(!corner_type_annotation_key[color].has(bits),
                    "Multiple corner-type annotations have the same shape " +
                    "and color: quadrant=%s" % \
                    Sc.utils.get_vector_string(quadrant_position, 0))
            corner_type_annotation_key[color][bits] = corner_type
    
    image.unlock()
    
    return corner_type_annotation_key


# -   Returns a mapping from tl/tr/bl/br to a combined-corner-types-int to
#     quadrant position.
# -   The combined-corner-types-int is calculated as follows:
#         self-corner | h-opp-corner << 10 | v-opp-corner << 20 | \
#             h-inbound-corner << 30 | v-inbound-corner << 40
# Dictionary<("tl"|"tr"|"bl"|"br"), Dictionary<int, Vector2>>
static func parse_tile_set_corner_type_annotations(
        corner_type_annotation_key: Dictionary,
        corner_types_to_swap_for_bottom_quadrants: Dictionary,
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
            _parse_corner_type_annotation(
                    subtile_corner_types,
                    corner_type_annotation_key,
                    corner_types_to_swap_for_bottom_quadrants,
                    subtile_position,
                    quadrant_size,
                    image,
                    tile_set_corner_type_annotations_path)
    
    image.unlock()
    
    return subtile_corner_types


static func _parse_corner_type_annotation(
        subtile_corner_types: Dictionary,
        corner_type_annotation_key: Dictionary,
        corner_types_to_swap_for_bottom_quadrants: Dictionary,
        subtile_position: Vector2,
        quadrant_size: int,
        image: Image,
        tile_set_corner_type_annotations_path: String) -> void:
    var tl_quadrant_position := subtile_position * 2 + Vector2(0,0)
    var tr_quadrant_position := subtile_position * 2 + Vector2(1,0)
    var bl_quadrant_position := subtile_position * 2 + Vector2(0,1)
    var br_quadrant_position := subtile_position * 2 + Vector2(1,1)
    
    _check_for_empty_quadrant_non_annotation_pixels(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            true,
            true)
    _check_for_empty_quadrant_non_annotation_pixels(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            true,
            false)
    _check_for_empty_quadrant_non_annotation_pixels(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            false,
            true)
    _check_for_empty_quadrant_non_annotation_pixels(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            false,
            false)
    
    # Parse the corner-type annotations.
    var tl_corner_annotation := _get_quadrant_annotation(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            true,
            true,
            false,
            false)
    var tr_corner_annotation := _get_quadrant_annotation(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            true,
            false,
            false,
            false)
    var bl_corner_annotation := _get_quadrant_annotation(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            false,
            true,
            false,
            false)
    var br_corner_annotation := _get_quadrant_annotation(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            false,
            false,
            false,
            false)
    
    # Also parse the eight possible inbound corner-type annotations.
    var tl_h_inbound_corner_annotation := _get_quadrant_annotation(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            true,
            true,
            true,
            false)
    var tl_v_inbound_corner_annotation := _get_quadrant_annotation(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            true,
            true,
            false,
            true)
    var tr_h_inbound_corner_annotation := _get_quadrant_annotation(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            true,
            false,
            true,
            false)
    var tr_v_inbound_corner_annotation := _get_quadrant_annotation(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            true,
            false,
            false,
            true)
    var bl_h_inbound_corner_annotation := _get_quadrant_annotation(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            false,
            true,
            true,
            false)
    var bl_v_inbound_corner_annotation := _get_quadrant_annotation(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            false,
            true,
            false,
            true)
    var br_h_inbound_corner_annotation := _get_quadrant_annotation(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            false,
            false,
            true,
            false)
    var br_v_inbound_corner_annotation := _get_quadrant_annotation(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            false,
            false,
            false,
            true)
    
    # Validate the corner-type annotations.
    _validate_tileset_annotation(
            tl_corner_annotation,
            corner_type_annotation_key,
            tl_quadrant_position,
            true,
            true,
            false,
            false,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            tr_corner_annotation,
            corner_type_annotation_key,
            tr_quadrant_position,
            true,
            false,
            false,
            false,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            bl_corner_annotation,
            corner_type_annotation_key,
            bl_quadrant_position,
            false,
            true,
            false,
            false,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            br_corner_annotation,
            corner_type_annotation_key,
            br_quadrant_position,
            false,
            false,
            false,
            false,
            tile_set_corner_type_annotations_path)
    
    # Also validate the eight possible inbound corner-type annotations.
    _validate_tileset_annotation(
            tl_h_inbound_corner_annotation,
            corner_type_annotation_key,
            tl_quadrant_position,
            true,
            true,
            true,
            false,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            tl_v_inbound_corner_annotation,
            corner_type_annotation_key,
            tl_quadrant_position,
            true,
            true,
            false,
            true,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            tr_h_inbound_corner_annotation,
            corner_type_annotation_key,
            tr_quadrant_position,
            true,
            false,
            true,
            false,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            tr_v_inbound_corner_annotation,
            corner_type_annotation_key,
            tr_quadrant_position,
            true,
            false,
            false,
            true,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            bl_h_inbound_corner_annotation,
            corner_type_annotation_key,
            bl_quadrant_position,
            false,
            true,
            true,
            false,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            bl_v_inbound_corner_annotation,
            corner_type_annotation_key,
            bl_quadrant_position,
            false,
            true,
            false,
            true,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            br_h_inbound_corner_annotation,
            corner_type_annotation_key,
            br_quadrant_position,
            false,
            false,
            true,
            false,
            tile_set_corner_type_annotations_path)
    _validate_tileset_annotation(
            br_v_inbound_corner_annotation,
            corner_type_annotation_key,
            br_quadrant_position,
            false,
            false,
            false,
            true,
            tile_set_corner_type_annotations_path)
    
    # Map annotations to their corner-types.
    var tl_corner_type := _get_corner_type_from_annotation(
            tl_corner_annotation,
            corner_type_annotation_key,
            corner_types_to_swap_for_bottom_quadrants,
            true,
            false)
    var tr_corner_type := _get_corner_type_from_annotation(
            tr_corner_annotation,
            corner_type_annotation_key,
            corner_types_to_swap_for_bottom_quadrants,
            true,
            false)
    var bl_corner_type := _get_corner_type_from_annotation(
            bl_corner_annotation,
            corner_type_annotation_key,
            corner_types_to_swap_for_bottom_quadrants,
            false,
            false)
    var br_corner_type := _get_corner_type_from_annotation(
            br_corner_annotation,
            corner_type_annotation_key,
            corner_types_to_swap_for_bottom_quadrants,
            false,
            false)
    
    # Also map inbound annotations to their corner-types.
    var tl_h_inbound_corner_type := \
            _get_corner_type_from_annotation(
                    tl_h_inbound_corner_annotation,
                    corner_type_annotation_key,
                    corner_types_to_swap_for_bottom_quadrants,
                    false,
                    true)
    var tl_v_inbound_corner_type := \
            _get_corner_type_from_annotation(
                    tl_v_inbound_corner_annotation,
                    corner_type_annotation_key,
                    corner_types_to_swap_for_bottom_quadrants,
                    false,
                    true)
    var tr_h_inbound_corner_type := \
            _get_corner_type_from_annotation(
                    tr_h_inbound_corner_annotation,
                    corner_type_annotation_key,
                    corner_types_to_swap_for_bottom_quadrants,
                    false,
                    true)
    var tr_v_inbound_corner_type := \
            _get_corner_type_from_annotation(
                    tr_v_inbound_corner_annotation,
                    corner_type_annotation_key,
                    corner_types_to_swap_for_bottom_quadrants,
                    false,
                    true)
    var bl_h_inbound_corner_type := \
            _get_corner_type_from_annotation(
                    bl_h_inbound_corner_annotation,
                    corner_type_annotation_key,
                    corner_types_to_swap_for_bottom_quadrants,
                    true,
                    true)
    var bl_v_inbound_corner_type := \
            _get_corner_type_from_annotation(
                    bl_v_inbound_corner_annotation,
                    corner_type_annotation_key,
                    corner_types_to_swap_for_bottom_quadrants,
                    true,
                    true)
    var br_h_inbound_corner_type := \
            _get_corner_type_from_annotation(
                    br_h_inbound_corner_annotation,
                    corner_type_annotation_key,
                    corner_types_to_swap_for_bottom_quadrants,
                    true,
                    true)
    var br_v_inbound_corner_type := \
            _get_corner_type_from_annotation(
                    br_v_inbound_corner_annotation,
                    corner_type_annotation_key,
                    corner_types_to_swap_for_bottom_quadrants,
                    true,
                    true)
    
    var tl_corner_types_flag := get_flag_from_corner_types(
            tl_corner_type,
            tr_corner_type,
            bl_corner_type,
            tl_h_inbound_corner_type,
            tl_v_inbound_corner_type)
    var tr_corner_types_flag := get_flag_from_corner_types(
            tr_corner_type,
            tl_corner_type,
            br_corner_type,
            tr_h_inbound_corner_type,
            tr_v_inbound_corner_type)
    var bl_corner_types_flag := get_flag_from_corner_types(
            bl_corner_type,
            br_corner_type,
            tl_corner_type,
            bl_h_inbound_corner_type,
            bl_v_inbound_corner_type)
    var br_corner_types_flag := get_flag_from_corner_types(
            br_corner_type,
            bl_corner_type,
            tr_corner_type,
            br_h_inbound_corner_type,
            br_v_inbound_corner_type)
    
    subtile_corner_types.tl[tl_corner_types_flag] = tl_quadrant_position
    subtile_corner_types.tr[tr_corner_types_flag] = tr_quadrant_position
    subtile_corner_types.bl[bl_corner_types_flag] = bl_quadrant_position
    subtile_corner_types.br[br_corner_types_flag] = br_quadrant_position


static func get_flag_from_corner_types(
        self_corner_type: int,
        h_opp_corner_type: int,
        v_opp_corner_type: int,
        h_inbound_corner_type: int,
        v_inbound_corner_type: int) -> int:
    return self_corner_type | \
            h_opp_corner_type << 10 | \
            v_opp_corner_type << 20 | \
            h_inbound_corner_type << 30 | \
            v_inbound_corner_type << 40


static func get_corner_types_from_flag(corner_types_flag: int) -> Dictionary:
    return {
        self_corner_type = corner_types_flag & _CORNER_TYPE_BIT_MASK,
        h_opp_corner_type = corner_types_flag >> 10 & _CORNER_TYPE_BIT_MASK,
        v_opp_corner_type = corner_types_flag >> 20 & _CORNER_TYPE_BIT_MASK,
        h_inbound_corner_type = corner_types_flag >> 30 & _CORNER_TYPE_BIT_MASK,
        v_inbound_corner_type = corner_types_flag >> 40 & _CORNER_TYPE_BIT_MASK,
    }


static func _get_corner_type_from_annotation(
        annotation: Dictionary,
        corner_type_annotation_key: Dictionary,
        corner_types_to_swap_for_bottom_quadrants: Dictionary,
        is_top: bool,
        is_inbound: bool) -> int:
    if is_inbound and annotation.bits == 0:
        return SubtileCorner.UNKNOWN
    var corner_type: int = \
            corner_type_annotation_key[annotation.color][annotation.bits]
    if !is_top and \
            corner_types_to_swap_for_bottom_quadrants.has(corner_type):
        return corner_types_to_swap_for_bottom_quadrants[corner_type]
    else:
        return corner_type


static func _validate_tileset_annotation(
        annotation: Dictionary,
        corner_type_annotation_key: Dictionary,
        quadrant_position: Vector2,
        is_top: bool,
        is_left: bool,
        is_horizontal_inbound: bool,
        is_vertical_inbound: bool,
        image_path: String) -> void:
    var bits: int = annotation.bits
    var color: int = annotation.color
    
    if (is_horizontal_inbound or is_vertical_inbound) and \
            bits == 0:
        return
    
    var corner_label := "%s-%s" % [
            "top" if is_top else "bottom",
            "left" if is_left else "right",
        ]
    if is_horizontal_inbound:
        corner_label += "-horizontal-inbound"
    if is_vertical_inbound:
        corner_label += "-vertical-inbound"
    
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


static func _check_for_empty_quadrant_non_annotation_pixels(
        quadrant_position: Vector2,
        quadrant_size: int,
        image: Image,
        path: String,
        is_top: bool,
        is_left: bool) -> void:
    for quadrant_y in quadrant_size:
        for quadrant_x in quadrant_size:
            var is_pixel_along_top: bool = quadrant_y < ANNOTATION_SIZE.y
            var is_pixel_along_bottom: bool = \
                    quadrant_y >= quadrant_size - ANNOTATION_SIZE.y
            var is_pixel_along_left: bool = quadrant_x < ANNOTATION_SIZE.x
            var is_pixel_along_right: bool = \
                    quadrant_x >= quadrant_size - ANNOTATION_SIZE.x
            var is_pixel_in_a_corner := \
                    (is_pixel_along_top or is_pixel_along_bottom) and \
                    (is_pixel_along_left or is_pixel_along_right)
            var is_pixel_along_correct_horizontal_side := \
                    is_left and is_pixel_along_left or \
                    !is_left and is_pixel_along_right
            var is_pixel_along_correct_vertical_side := \
                    is_top and is_pixel_along_top or \
                    !is_top and is_pixel_along_bottom
            
            if is_pixel_in_a_corner and \
                    (is_pixel_along_correct_horizontal_side or \
                    is_pixel_along_correct_vertical_side):
                # Ignore pixels that would belong to an annotation.
                continue
            
            var color := image.get_pixel(
                    quadrant_position.x + quadrant_x,
                    quadrant_position.y + quadrant_y)
            assert(color == Color.transparent)


static func _get_quadrant_annotation(
        quadrant_position: Vector2,
        quadrant_size: int,
        image: Image,
        path: String,
        is_top: bool,
        is_left: bool,
        is_horizontal_inbound: bool,
        is_vertical_inbound: bool) -> Dictionary:
    assert(!is_horizontal_inbound or !is_vertical_inbound)
    
    if is_horizontal_inbound:
        return _get_quadrant_annotation(
                quadrant_position,
                quadrant_size,
                image,
                path,
                is_top,
                !is_left,
                false,
                false)
    if is_vertical_inbound:
        return _get_quadrant_annotation(
                quadrant_position,
                quadrant_size,
                image,
                path,
                !is_top,
                is_left,
                false,
                false)
    
    var annotation_bits := 0
    var annotation_color := Color.transparent
    
    for annotation_row_index in ANNOTATION_SIZE.y:
        for annotation_column_index in ANNOTATION_SIZE.x:
            var x := int(quadrant_position.x + (
                    annotation_column_index if \
                    is_left else \
                    quadrant_size - 1 - annotation_column_index))
            var y := int(quadrant_position.y + (
                    annotation_row_index if \
                    is_top else \
                    quadrant_size - 1 - annotation_row_index))
            
            var color := image.get_pixel(x, y)
            if color == Color.transparent:
                # Ignore empty pixels.
                continue
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
            
            var bit_index_horizontal_component := int(
                    annotation_column_index if \
                    is_left else \
                    ANNOTATION_SIZE.x - 1 - annotation_column_index)
            var bit_index_vertical_component := int(
                    annotation_row_index if \
                    is_top else \
                    ANNOTATION_SIZE.y - 1 - annotation_row_index)
            var bit_index := int(
                    bit_index_vertical_component * ANNOTATION_SIZE.x + \
                    bit_index_horizontal_component)
            
            annotation_color = color
            annotation_bits |= 1 << bit_index
    
    return {
        bits = annotation_bits,
        color = annotation_color.to_rgba64(),
    }
