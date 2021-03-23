extends Node
class_name Utils

signal display_resized

var _throttled_size_changed: FuncRef

var _ios_model_names
var _ios_resolutions

func _init() -> void:
    self.print("Utils._init")
    
    _ios_model_names = IosModelNames.new()
    _ios_resolutions = IosResolutions.new()

func _enter_tree() -> void:
    _update_game_area_region_and_gui_scale()

func on_time_ready() -> void:
    _throttled_size_changed = Gs.time.throttle( \
            funcref(self, "_on_throttled_size_changed"), \
            Gs.display_resize_throttle_interval_sec)
    get_viewport().connect( \
            "size_changed", \
            self, \
            "_on_size_changed")

func _on_size_changed() -> void:
    _throttled_size_changed.call_func()

func _on_throttled_size_changed() -> void:
    _update_game_area_region_and_gui_scale()
    emit_signal("display_resized")

func _update_game_area_region_and_gui_scale() -> void:
    var viewport_size := get_viewport().size
    var aspect_ratio := viewport_size.x / viewport_size.y
    var game_area_position := Vector2.INF
    var game_area_size := Vector2.INF
    
    if !Gs.is_app_configured:
        game_area_size = viewport_size
        game_area_position = Vector2.ZERO
    if aspect_ratio < Gs.aspect_ratio_min:
        # Show vertical margin around game area.
        game_area_size = Vector2( \
                viewport_size.x, \
                viewport_size.x / Gs.aspect_ratio_min)
        game_area_position = Vector2( \
                0.0, \
                (viewport_size.y - game_area_size.y) * 0.5)
    elif aspect_ratio > Gs.aspect_ratio_max:
        # Show horizontal margin around game area.
        game_area_size = Vector2( \
                viewport_size.y * Gs.aspect_ratio_max, \
                viewport_size.y)
        game_area_position = Vector2( \
                (viewport_size.x - game_area_size.x) * 0.5, \
                0.0)
    else:
        # Show no margins around game area.
        game_area_size = viewport_size
        game_area_position = Vector2.ZERO
    
    Gs.game_area_region = Rect2(game_area_position, game_area_size)
    
    if Gs.is_app_configured:
        var default_aspect_ratio: float = \
                Gs.default_game_area_size.x / \
                Gs.default_game_area_size.y
        Gs.gui_scale = \
                viewport_size.x / Gs.default_game_area_size.x if \
                aspect_ratio < default_aspect_ratio else \
                viewport_size.y / Gs.default_game_area_size.y
        Gs.gui_scale = \
                max(Gs.gui_scale, Gs.MIN_GUI_SCALE)
    
    for gui in Gs.guis_to_scale:
        _scale_gui_for_current_screen_size(gui)

# Automatically resize the gui to adapt to different screen sizes.
func _scale_gui_for_current_screen_size(gui: Control) -> void:
    if !is_instance_valid(gui):
        error()
        return
    
    var old_gui_scale: float = Gs.guis_to_scale[gui]
    
    var new_gui_scale: float = Gs.gui_scale
    new_gui_scale = Gs.geometry.snap_float_to_integer(new_gui_scale, 0.001)
    
    if old_gui_scale != new_gui_scale:
        var relative_scale := new_gui_scale / old_gui_scale
        Gs.guis_to_scale[gui] = new_gui_scale
        _scale_gui_recursively( \
                gui, \
                relative_scale)

func print(message: String) -> void:
    if is_instance_valid(Gs.debug_panel):
        Gs.debug_panel.add_message(message)
    else:
        print("Utils.print (DebugPanel not ready yet): " + message)

func get_is_paused() -> bool:
    return get_tree().paused

func pause() -> void:
    get_tree().paused = true

func unpause() -> void:
    get_tree().paused = false

func error( \
        message := "An error occurred", \
        should_assert := true) -> void:
    push_error("ERROR: %s" % message)
    Gs.utils.print("**ERROR**: %s" % message)
    if should_assert:
         assert(false)

static func static_error( \
        message := "An error occurred", \
        should_assert := true) -> void:
    push_error("ERROR: %s" % message)
    if should_assert:
         assert(false)

func warning(message := "An warning occurred") -> void:
    push_warning("WARNING: %s" % message)
    Gs.utils.print("**WARNING**: %s" % message)

# TODO: Replace this with any built-in feature whenever it exists
#       (https://github.com/godotengine/godot/issues/4715).
static func subarray( \
        array: Array, \
        start: int, \
        length := -1) -> Array:
    if length < 0:
        length = array.size() - start
    var result := []
    result.resize(length)
    for i in range(length):
        result[i] = array[start + i]
    return result

# TODO: Replace this with any built-in feature whenever it exists
#       (https://github.com/godotengine/godot/issues/4715).
static func sub_pool_vector2_array( \
        array: PoolVector2Array, \
        start: int, \
        length := -1) -> PoolVector2Array:
    if length < 0:
        length = array.size() - start
    var result := PoolVector2Array()
    result.resize(length)
    for i in range(length):
        result[i] = array[start + i]
    return result

# TODO: Replace this with any built-in feature whenever it exists
#       (https://github.com/godotengine/godot/issues/4715).
static func concat( \
        result: Array, \
        other: Array) -> void:
    var old_result_size := result.size()
    var other_size := other.size()
    result.resize(old_result_size + other_size)
    for i in range(other_size):
        result[old_result_size + i] = other[i]

static func array_to_set(array: Array) -> Dictionary:
    var set := {}
    for element in array:
        set[element] = element
    return set

static func translate_polyline( \
        vertices: PoolVector2Array, \
        translation: Vector2) \
        -> PoolVector2Array:
    var result := PoolVector2Array()
    result.resize(vertices.size())
    for i in range(vertices.size()):
        result[i] = vertices[i] + translation
    return result

static func get_children_by_type( \
        parent: Node, \
        type, \
        recursive := false) -> Array:
    var result = []
    for child in parent.get_children():
        if child is type:
            result.push_back(child)
        if recursive:
            get_children_by_type( \
                    child, \
                    type, \
                    recursive)
    return result

static func get_which_wall_collided_for_body(body: KinematicBody2D) -> int:
    if body.is_on_wall():
        for i in range(body.get_slide_count()):
            var collision := body.get_slide_collision(i)
            var side := get_which_surface_side_collided(collision)
            if side == SurfaceSide.LEFT_WALL or side == SurfaceSide.RIGHT_WALL:
                return side
    return SurfaceSide.NONE

static func get_which_surface_side_collided( \
        collision: KinematicCollision2D) -> int:
    if abs(collision.normal.angle_to(Gs.geometry.UP)) <= \
            Gs.geometry.FLOOR_MAX_ANGLE:
        return SurfaceSide.FLOOR
    elif abs(collision.normal.angle_to(Gs.geometry.DOWN)) <= \
            Gs.geometry.FLOOR_MAX_ANGLE:
        return SurfaceSide.CEILING
    elif collision.normal.x > 0:
        return SurfaceSide.LEFT_WALL
    else:
        return SurfaceSide.RIGHT_WALL

static func get_floor_friction_multiplier(body: KinematicBody2D) -> float:
    var collision := _get_floor_collision(body)
    # Collision friction is a property of the TileMap node.
    if collision != null and collision.collider.collision_friction != null:
        return collision.collider.collision_friction
    return 0.0

static func _get_floor_collision( \
        body: KinematicBody2D) -> KinematicCollision2D:
    if body.is_on_floor():
        for i in range(body.get_slide_count()):
            var collision := body.get_slide_collision(i)
            if abs(collision.normal.angle_to(Gs.geometry.UP)) <= \
                    Gs.geometry.FLOOR_MAX_ANGLE:
                return collision
    return null

func add_scene( \
        parent: Node, \
        resource_path: String, \
        is_attached := true, \
        is_visible := true) -> Node:
    var scene := load(resource_path)
    var node: Node = scene.instance()
    if node is CanvasItem:
        node.visible = is_visible
    if is_attached:
        parent.add_child(node)
    
    var name := resource_path
    if name.find_last("/") >= 0:
        name = name.substr(name.find_last("/") + 1)
    assert(resource_path.ends_with(".tscn"))
    name = name.substr(0, name.length() - 5)
    node.name = name
    
    return node

static func get_global_touch_position(input_event: InputEvent) -> Vector2:
    return Gs.level.make_input_local(input_event).position

func add_overlay_to_current_scene(node: Node) -> void:
    get_tree().get_current_scene().add_child(node)

func vibrate() -> void:
    if Gs.is_giving_haptic_feedback:
        Input.vibrate_handheld( \
                Gs.input_vibrate_duration_sec * 1000)

func give_button_press_feedback(is_fancy := false) -> void:
    vibrate()
    if is_fancy:
        Gs.audio.play_sound("menu_select_fancy")
    else:
        Gs.audio.play_sound("menu_select")

static func ease_name_to_param(name: String) -> float:
    match name:
        "linear":
            return 1.0
        "ease_in":
            return 2.4
        "ease_in_strong":
            return 4.8
        "ease_in_weak":
            return 1.6
        "ease_out":
            return 0.4
        "ease_out_strong":
            return 0.2
        "ease_out_weak":
            return 0.6
        "ease_in_out":
            return -2.4
        "ease_in_out_strong":
            return -4.8
        "ease_in_out_weak":
            return -1.8
        _:
            static_error()
            return INF

static func ease_by_name( \
        progress: float, \
        ease_name: String) -> float:
    return ease(progress, ease_name_to_param(ease_name))

static func get_is_android_device() -> bool:
    return OS.get_name() == "Android"

static func get_is_ios_device() -> bool:
    return OS.get_name() == "iOS"

static func get_is_browser() -> bool:
    return OS.get_name() == "HTML5"

static func get_is_windows_device() -> bool:
    return OS.get_name() == "Windows"

static func get_is_mac_device() -> bool:
    return OS.get_name() == "OSX"

static func get_is_mobile_device() -> bool:
    return get_is_android_device() or get_is_ios_device()

static func get_model_name() -> String:
    return IosModelNames.get_model_name() if \
        get_is_ios_device() else \
        OS.get_model_name()

func get_screen_scale() -> float:
    # NOTE: OS.get_screen_scale() is only implemented for MacOS, so it's
    #       useless.
    if get_is_mobile_device():
        if OS.window_size.x < OS.window_size.y:
            return OS.window_size.x / get_viewport().size.x
        else:
            return OS.window_size.y / get_viewport().size.y
    elif get_is_mac_device():
        return OS.get_screen_scale()
    else:
        return 1.0

# This does not take into account the screen scale. Node.get_viewport().size
# likely returns a smaller number than OS.window_size, because of screen scale.
func get_screen_ppi() -> int:
    if get_is_ios_device():
        return _get_ios_screen_ppi()
    else:
        return OS.get_screen_dpi()

func _get_ios_screen_ppi() -> int:
    return _ios_resolutions.get_screen_ppi(_ios_model_names)

# This takes into account the screen scale, and should enable accurate
# conversion of event positions from pixels to inches.
# 
# NOTE: This assumes that the viewport takes up the entire screen, which will
#       likely be true only for mobile devices, and is not even guaranteed for
#       them.
func get_viewport_ppi() -> float:
    return get_screen_ppi() / get_screen_scale()

func get_viewport_size_inches() -> Vector2:
    return get_viewport().size / get_viewport_ppi()

func get_viewport_diagonal_inches() -> float:
    return get_viewport_size_inches().length()

func get_viewport_safe_area() -> Rect2:
    var os_safe_area := OS.get_window_safe_area()
    return Rect2( \
            os_safe_area.position / get_screen_scale(), \
            os_safe_area.size / get_screen_scale())

func get_safe_area_margin_top() -> float:
    return get_viewport_safe_area().position.y

func get_safe_area_margin_bottom() -> float:
    return get_viewport().size.y - get_viewport_safe_area().end.y

func get_safe_area_margin_left() -> float:
    return get_viewport_safe_area().position.x

func get_safe_area_margin_right() -> float:
    return get_viewport().size.x - OS.get_window_safe_area().end.x

static func floor_vector(v: Vector2) -> Vector2:
    return Vector2(floor(v.x), floor(v.y))

static func mix( \
        values: Array, \
        weights: Array):
    assert(values.size() == weights.size())
    assert(!values.empty())
    
    var count := values.size()
    
    var weight_sum := 0.0
    for weight in weights:
        weight_sum += weight
    
    var weighted_average
    if values[0] is float or values[0] is int:
        weighted_average = 0.0
    elif values[0] is Vector2:
        weighted_average = Vector2.ZERO
    elif values[0] is Vector3:
        weighted_average = Vector3.ZERO
    else:
        static_error()
    
    for i in range(count):
        var value = values[i]
        var weight: float = weights[i]
        var normalized_weight := \
                weight / weight_sum if \
                weight_sum > 0.0 else \
                1.0 / count
        weighted_average += value * normalized_weight
    
    return weighted_average

static func mix_colors( \
        colors: Array, \
        weights: Array) -> Color:
    assert(colors.size() == weights.size())
    assert(!colors.empty())
    
    var count := colors.size()
    
    var weight_sum := 0.0
    for weight in weights:
        weight_sum += weight
    
    var h := 0.0
    var s := 0.0
    var v := 0.0
    for i in range(count):
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

func get_datetime_string() -> String:
    var datetime := OS.get_datetime()
    return "%s-%s-%s-%s-%s-%s" % [
        datetime.year,
        datetime.month,
        datetime.day,
        datetime.hour,
        datetime.minute,
        datetime.second,
    ]

func get_time_string_from_seconds(time_sec: float) -> String:
    var time_str := ""
    
    # Hours.
    var hours := int(time_sec / 3600.0)
    time_sec = fmod(time_sec, 3600.0)
    time_str = "%s%02d:" % [
        time_str,
        hours,
    ]
    
    # Minutes.
    var minutes := int(time_sec / 60.0)
    time_sec = fmod(time_sec, 60.0)
    time_str = "%s%02d:" % [
        time_str,
        minutes,
    ]
    
    # Seconds.
    time_str = "%s%02d" % [
        time_str,
        time_sec,
    ]
    
    return time_str

func take_screenshot() -> void:
    var directory := Directory.new()
    if !directory.dir_exists("user://screenshots"):
        var status := directory.open("user://")
        if status != OK:
            error()
            return
        directory.make_dir("screenshots")
    
    var image := get_viewport().get_texture().get_data()
    image.flip_y()
    var path := "user://screenshots/screenshot-%s.png" % get_datetime_string()
    var status := image.save_png(path)
    if status != OK:
        error()

func clear_directory( \
        path: String, \
        also_deletes_directory := false) -> void:
    # Open directory.
    var directory := Directory.new()
    var status := directory.open(path)
    if status != OK:
        error()
        return
    
    # Delete children.
    directory.list_dir_begin(true)
    var file_name := directory.get_next()
    while file_name != "":
        if directory.current_is_dir():
            var child_path := \
                    path + file_name if \
                    path.ends_with("/") else \
                    path + "/" + file_name
            clear_directory(child_path, true)
        else:
            status = directory.remove(file_name)
            if status != OK:
                error("Failed to delete file", false)
        file_name = directory.get_next()
    
    # Delete directory.
    if also_deletes_directory:
        status = directory.remove(path)
        if status != OK:
            error("Failed to delete directory", false)

func set_mouse_filter_recursively( \
        node: Node, \
        mouse_filter: int) -> void:
    for child in node.get_children():
        if child is Control:
            if !(child is Button):
                child.mouse_filter = mouse_filter
        set_mouse_filter_recursively(child, mouse_filter)

func _scale_gui_recursively( \
        control: Control, \
        gui_scale: float) -> void:
    var snap_epsilon := 0.001
    
    var is_gui_container := \
            control is Container
    var is_gui_texture_based := \
            control is TextureButton or \
            control is ShinyButton or \
            control is TextureRect
    
    control.rect_min_size *= gui_scale
    control.rect_min_size = Gs.geometry.snap_vector2_to_integers( \
            control.rect_min_size, snap_epsilon)
    
    if is_gui_container:
        control.rect_size *= gui_scale
        control.rect_size = Gs.geometry.snap_vector2_to_integers( \
                control.rect_size, snap_epsilon)
        if control is VBoxContainer or \
                control is HBoxContainer:
            var separation := control.get_constant("separation") * gui_scale
            control.add_constant_override("separation", separation)
    elif is_gui_texture_based:
        # Only scale texture-based GUIs, since we scale fonts separately.
        control.rect_scale *= gui_scale
        control.rect_scale = Gs.geometry.snap_vector2_to_integers( \
                control.rect_scale, snap_epsilon)
        if control is ShinyButton:
            control.texture_scale *= gui_scale
            control.texture_scale = Gs.geometry.snap_vector2_to_integers( \
                    control.texture_scale, snap_epsilon)
    
#    control.rect_position /= gui_scale
#    control.rect_position = Gs.geometry.snap_vector2_to_integers( \
#            control.rect_position, snap_epsilon)
#    control.rect_pivot_offset *= gui_scale
#    control.rect_pivot_offset = Gs.geometry.snap_vector2_to_integers( \
#            control.rect_pivot_offset, snap_epsilon)
    
    for child in control.get_children():
        if child is Control:
            _scale_gui_recursively(child, gui_scale)

func get_node_vscroll_position( \
        scroll_container: ScrollContainer, \
        control: Control) -> int:
    var scroll_container_global_position := \
            scroll_container.rect_global_position
    var control_global_position := control.rect_global_position
    var vscroll_position: int = \
            control_global_position.y - \
            scroll_container_global_position.y + \
            scroll_container.scroll_vertical
    var max_vscroll_position := scroll_container.get_v_scrollbar().max_value
    return vscroll_position

func get_support_url() -> String:
    var params := "?source=" + OS.get_name()
    params += "&app=inner-tube-climber"
    return Gs.support_url_base + params

func get_log_gestures_url() -> String:
    var params := "?source=" + OS.get_name()
    params += "&app=inner-tube-climber"
    return Gs.log_gestures_url + params
