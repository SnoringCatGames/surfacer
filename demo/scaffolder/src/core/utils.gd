class_name ScaffolderUtils
extends Node


const MAX_INT := 9223372036854775807

var _focus_releaser: Control

var were_screenshots_taken := false


func _init() -> void:
    S.log.on_global_init(self, "Utils")

    _focus_releaser = Button.new()
    _focus_releaser.modulate.a = 0.0
    _focus_releaser.visible = false
    add_child(_focus_releaser)


func ensure(condition: bool, message := "") -> bool:
    assert(condition, message)
    return condition


static func splice(
        result: Array,
        start: int,
        delete_count: int,
        items_to_insert: Array) -> void:
    var old_count := result.size()
    var items_to_insert_count := items_to_insert.size()

    assert(start >= 0)
    assert(start <= old_count)
    assert(delete_count >= 0)
    assert(delete_count <= old_count)
    assert(start + delete_count <= old_count)

    var new_count := old_count - delete_count + items_to_insert_count
    var is_growing := items_to_insert_count > delete_count
    var is_shrinking := items_to_insert_count < delete_count
    var displacement := items_to_insert_count - delete_count

    if is_shrinking:
        # Shift old items toward the front.
        var i := start + delete_count
        while i < old_count:
            result[i + displacement] = result[i]
            i += 1

    # Resize the result array.
    result.resize(new_count)

    if is_growing:
        # Shift old items toward the back.
        var i := old_count - 1
        while i >= start + delete_count:
            result[i + displacement] = result[i]
            i -= 1

    # Insert the new items.
    var i := 0
    while i < items_to_insert_count:
        result[start + i] = items_to_insert[i]
        i += 1


static func dedup(array: Array) -> Array:
    var set := {}
    for element in array:
        set[element] = true
    var set_values := set.values()
    var deduped_size := set_values.size()
    array.resize(deduped_size)
    for i in deduped_size:
        array[i] = set_values[i]
    return array


static func merge(
        result: Dictionary,
        other: Dictionary,
        overrides_preexisting_properties := true,
        recursive := false) -> Dictionary:
    if recursive:
        if overrides_preexisting_properties:
            for key in other:
                if result.has(key):
                    if result[key] is Dictionary and other[key] is Dictionary:
                        merge(result[key], other[key], true, true)
                    elif result[key] is Array and other[key] is Array:
                        result[key].append_array(other[key])
                    else:
                        result[key] = other[key]
                else:
                    result[key] = other[key]
        else:
            for key in other:
                if result.has(key):
                    if result[key] is Dictionary and other[key] is Dictionary:
                        merge(result[key], other[key], false, true)
                    elif result[key] is Array and other[key] is Array:
                        result[key].append_array(other[key])
                    else:
                        # Do nothing; preserve the original value.
                        pass
                else:
                    result[key] = other[key]
    else:
        if overrides_preexisting_properties:
            for key in other:
                result[key] = other[key]
        else:
            for key in other:
                if !result.has(key):
                    result[key] = other[key]
    return result


static func subtract_nested_arrays(
        result: Dictionary,
        other: Dictionary,
        expects_no_missing_matches := false) -> Dictionary:
    for key in other:
        if result.has(key):
            if result[key] is Dictionary and other[key] is Dictionary:
                subtract_nested_arrays(
                        result[key], other[key], expects_no_missing_matches)
            elif result[key] is Array and other[key] is Array:
                subtract_arrays(
                        result[key], other[key], expects_no_missing_matches)
            elif expects_no_missing_matches:
                S.log.error(
                        ("Utils.subtract_nested_arrays: Wrong-type match: " +
                        "(We currently don't support subtracting properties " +
                        "from a Dictionary. We only support subtracting " +
                        "elements from Arrays.)" +
                        "\n    key=%s,\n    result=%s,\n    other=%s") % \
                        [key, result, other])
        elif expects_no_missing_matches:
            S.log.error(
                    ("Utils.subtract_nested_arrays: Missing match: " +
                    "\n    key=%s,\n    result=%s,\n    other=%s") % \
                    [key, result, other])
    return result


static func subtract_arrays(
        result: Array,
        other: Array,
        expects_no_missing_matches := false) -> Array:
    for element in other:
        var result_index := result.find(element)
        if result_index >= 0:
            result.remove_at(result_index)
        else:
            S.log.error(
                    ("Utils.subtract_arrays: Missing match: " +
                    "\n    element=%s,\n    result=%s,\n    other=%s") % \
                    [element, result, other])
    return result


static func join(
        array: Variant,
        delimiter := ",") -> String:
    assert(array is Array or array is PackedStringArray)
    var count: int = array.size()
    var result := ""
    for index in array.size() - 1:
        result += str(array[index]) + delimiter
    if count > 0:
        result += str(array[count - 1])
    return result


static func array_to_set(array: Array) -> Dictionary:
    var set := {}
    for element in array:
        set[element] = element
    return set


func cascade_sort(arr: Array) -> Array:
    arr.sort()
    return arr


static func translate_polyline(
        vertices: PackedVector2Array,
        translation: Vector2) \
        -> PackedVector2Array:
    var result := PackedVector2Array()
    result.resize(vertices.size())
    for i in vertices.size():
        result[i] = vertices[i] + translation
    return result


func clear_children(node: Node) -> void:
    for child in node.get_children():
        child.queue_free()


static func get_level_position_for_screen_event(input_event: InputEvent) -> Vector2:
    return transform_screen_position_to_level_position(input_event.position)


static func transform_screen_position_to_level_position(
        screen_position: Vector2) -> Vector2:
    var top_screen := S.screens.get_top_screen()
    if not is_instance_valid(top_screen):
        return Vector2.ZERO
    return (S.level.get_canvas_transform() * \
            S.level.get_global_transform()) \
        .affine_inverse() * \
        (screen_position - S.screens.get_top_screen().screen.rect_position)


static func get_screen_position_of_node_in_level(node: CanvasItem) -> Vector2:
    var top_screen := S.screens.get_top_screen()
    if not is_instance_valid(top_screen):
        return Vector2.ZERO
    return node.get_global_transform_with_canvas().origin + \
        top_screen.screen.rect_position


func add_overlay_to_current_scene(node: Node) -> void:
    get_tree().get_current_scene().add_child(node)


# TODO: Replace this with better built-in EaseType/TransType easing support
#       when it's ready
#       (https://github.com/godotengine/godot-proposals/issues/36).
static func ease_name_to_param(name: String) -> float:
    match name:
        "linear":
            return 1.0

        "ease_in":
            return 2.4
        "ease_in_strong":
            return 4.8
        "ease_in_very_strong":
            return 9.6
        "ease_in_weak":
            return 1.6

        "ease_out":
            return 0.4
        "ease_out_strong":
            return 0.2
        "ease_out_very_strong":
            return 0.1
        "ease_out_weak":
            return 0.6

        "ease_in_out":
            return -2.4
        "ease_in_out_strong":
            return -4.8
        "ease_in_out_very_strong":
            return -9.6
        "ease_in_out_weak":
            return -1.8

        _:
            ScaffolderLog.static_error(".ease_name_to_param")
            return INF


static func ease_by_name(
        progress: float,
        ease_name: String) -> float:
    return ease(progress, ease_name_to_param(ease_name))


static func is_num(v) -> bool:
    return v is int or v is float


static func floor_vector(v: Vector2) -> Vector2:
    return Vector2(floor(v.x), floor(v.y))


static func ceil_vector(v: Vector2) -> Vector2:
    return Vector2(ceil(v.x), ceil(v.y))


static func round_vector(v: Vector2) -> Vector2:
    return Vector2(round(v.x), round(v.y))


static func mix(
        values: Array,
        weights: Array):
    assert(values.size() == weights.size())
    assert(!values.is_empty())

    var count := values.size()

    var weight_sum := 0.0
    for weight in weights:
        weight_sum += weight

    var weighted_average
    if S.utils.is_num(values[0] is float):
        weighted_average = 0.0
    elif values[0] is Vector2:
        weighted_average = Vector2.ZERO
    elif values[0] is Vector3:
        weighted_average = Vector3.ZERO
    else:
        ScaffolderLog.static_error(".mix")

    for i in count:
        var value = values[i]
        var weight: float = weights[i]
        var normalized_weight := \
                weight / weight_sum if \
                weight_sum > 0.0 else \
                1.0 / count
        weighted_average += value * normalized_weight

    return weighted_average


static func mix_colors(
        colors: Array,
        weights: Array) -> Color:
    assert(colors.size() == weights.size())
    assert(!colors.is_empty())

    var count := colors.size()

    var weight_sum := 0.0
    for weight in weights:
        weight_sum += weight

    var h := 0.0
    var s := 0.0
    var v := 0.0
    for i in count:
        var color: Color = colors[i]
        var weight: float = weights[i]
        var normalized_weight := \
                weight / weight_sum if \
                weight_sum > 0.0 else \
                1.0 / count
        h += color.h * normalized_weight
        s += color.s * normalized_weight
        v += color.v * normalized_weight

    return Color.from_hsv(h, s, v, 1.0)


static func get_datetime_string() -> String:
    var datetime := Time.get_datetime_dict_from_system()
    return "%s-%s-%s_%s.%s.%s" % [
        datetime.year,
        datetime.month,
        datetime.day,
        datetime.hour,
        datetime.minute,
        datetime.second,
    ]


static func get_time_string_from_seconds(
        time: float,
        includes_ms := false,
        includes_empty_hours := true,
        includes_empty_minutes := true) -> String:
    var is_undefined := is_inf(time)
    var time_str := ""

    # Hours.
    var hours := int(time / 3600.0)
    time = fmod(time, 3600.0)
    if hours != 0 or \
            includes_empty_hours:
        if !is_undefined:
            time_str = "%s%02d:" % [
                time_str,
                hours,
            ]
        else:
            time_str = "--:"

    # Minutes.
    var minutes := int(time / 60.0)
    time = fmod(time, 60.0)
    if minutes != 0 or \
            includes_empty_minutes:
        if !is_undefined:
            time_str = "%s%02d:" % [
                time_str,
                minutes,
            ]
        else:
            time_str += "--:"

    # Seconds.
    var seconds := int(time)
    if !is_undefined:
        time_str = "%s%02d" % [
            time_str,
            seconds,
        ]
    else:
        time_str += "--"

    if includes_ms:
        # Milliseconds.
        var milliseconds := \
                int(fmod((time - seconds) * 1000.0, 1000.0))
        if !is_undefined:
            time_str = "%s.%03d" % [
                time_str,
                milliseconds,
            ]
        else:
            time_str += ".---"

    return time_str


func get_vector_string(
        vector: Vector2,
        decimal_place_count := 2) -> String:
    return "(%.*f,%.*f)" % [
        decimal_place_count,
        vector.x,
        decimal_place_count,
        vector.y,
    ]


func get_spaces(count: int) -> String:
    assert(count <= 60)
    return "                                                            " \
            .substr(0, count)


func pad_string(
        string: String,
        length: int,
        pads_on_right := true,
        allows_longer_strings := false) -> String:
    assert(allows_longer_strings or string.length() <= length)
    var spaces_count := length - string.length()
    if spaces_count <= 0:
        return string
    else:
        var padding := get_spaces(spaces_count)
        if pads_on_right:
            return "%s%s" % [string, padding]
        else:
            return "%s%s" % [padding, string]


func resize_string(
        string: String,
        length: int,
        pads_on_right := true) -> String:
    if string.length() > length:
        return string.substr(0, length)
    elif string.length() < length:
        return pad_string(string, length, pads_on_right)
    else:
        return string


func take_screenshot() -> void:
    var result := DirAccess.make_dir_recursive_absolute("user://screenshots")
    if result != OK:
        return

    var image := get_viewport().get_texture().get_image()
    var path := "user://screenshots/screenshot-%s.png" % get_datetime_string()
    var status := image.save_png(path)
    if status != OK:
        S.log.error("Utils.take_screenshot")
    else:
        S.log.print("Took a screenshot: %s" % path)
        were_screenshots_taken = true


func open_screenshot_folder() -> void:
    var path := OS.get_user_data_dir() + "/screenshots"
    S.log.print("Opening screenshot folder: " + path)
    OS.shell_open(path)


func set_mouse_filter_recursively(
        node: Node,
        mouse_filter: int) -> void:
    for child in node.get_children():
        if child is Control:
            if !(child is Button or \
                    child is Slider):
                child.mouse_filter = mouse_filter
        set_mouse_filter_recursively(child, mouse_filter)


func notify_on_screen_visible_recursively(node: CanvasItem) -> void:
    if node.has_method("_on_screen_visible"):
        node._on_screen_visible()

    for child in node.get_children():
        if child is CanvasItem:
            notify_on_screen_visible_recursively(child)


func get_node_vscroll_position(
        scroll_container: ScrollContainer,
        control: Control,
        offset := 0) -> int:
    var scroll_container_global_position := \
            scroll_container.global_position
    var control_global_position := control.global_position
    var vscroll_position: int = \
            control_global_position.y - \
            scroll_container_global_position.y + \
            scroll_container.scroll_vertical + \
            offset
    var max_vscroll_position := scroll_container.get_v_scroll_bar().max_value
    return int(min(vscroll_position, max_vscroll_position))


func get_instance_id_or_not(object: Object) -> int:
    return object.get_instance_id() if \
            object != null else \
            -1


func get_all_nodes_in_group(group_name: String) -> Array:
    return get_tree().get_nodes_in_group(group_name)


func get_node_in_group(group_name: String) -> Node:
    var nodes := get_tree().get_nodes_in_group(group_name)
    assert(nodes.size() == 1)
    return nodes[0]


func get_property_value_from_scene_state_node(
        state: SceneState,
        node_index: int,
        property_name: String,
        expects_a_result := false):
    for property_index in state.get_node_property_count(node_index):
        if state.get_node_property_name(node_index, property_index) == \
                property_name:
            return state.get_node_property_value(node_index, property_index)
    assert(!expects_a_result)


func check_whether_sub_classes_are_tools(object: Object) -> bool:
    var script: Script = object.get_script()
    while script != null:
        if !script.is_tool():
            return false
        script = script.get_base_script()
    return true


func is_running_in_isolated_scene_mode() -> bool:
    var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
    var root_scene := get_tree().get_current_scene().scene_file_path
    return root_scene != main_scene


static func get_type_string(type: int) -> String:
    match type:
        TYPE_NIL:
            return "TYPE_NIL"
        TYPE_BOOL:
            return "TYPE_BOOL"
        TYPE_INT:
            return "TYPE_INT"
        TYPE_FLOAT:
            return "TYPE_FLOAT"
        TYPE_STRING:
            return "TYPE_STRING"
        TYPE_VECTOR2:
            return "TYPE_VECTOR2"
        TYPE_RECT2:
            return "TYPE_RECT2"
        TYPE_VECTOR3:
            return "TYPE_VECTOR3"
        TYPE_TRANSFORM2D:
            return "TYPE_TRANSFORM2D"
        TYPE_PLANE:
            return "TYPE_PLANE"
        TYPE_QUATERNION:
            return "TYPE_QUATERNION"
        TYPE_AABB:
            return "TYPE_AABB"
        TYPE_BASIS:
            return "TYPE_BASIS"
        TYPE_TRANSFORM3D:
            return "TYPE_TRANSFORM3D"
        TYPE_COLOR:
            return "TYPE_COLOR"
        TYPE_NODE_PATH:
            return "TYPE_NODE_PATH"
        TYPE_RID:
            return "TYPE_RID"
        TYPE_OBJECT:
            return "TYPE_OBJECT"
        TYPE_DICTIONARY:
            return "TYPE_DICTIONARY"
        TYPE_ARRAY:
            return "TYPE_ARRAY"
        TYPE_MAX:
            return "TYPE_MAX"
        _:
            S.log.error("Utils.get_type_string: %d" % type)
            return ""


func get_display_name(object: Variant) -> String:
    var path: String
    if object is String:
        path = object
    elif object is Object:
        if "scene_file_path" in object and object.scene_file_path != "":
            path = object.scene_file_path
        elif "resource_path" in object and object.resource_path != "":
            path = object.resource_path
        elif object is Node:
            path = object.name

    if path.is_empty():
        return "%s" % object

    var regex := RegEx.new()
    regex.compile(r'([a-zA-Z0-9_ \-]*)\.[a-zA-Z0-9_]*$')
    var result := regex.search(path)

    if result == null:
        return path

    return result.get_string(1)
