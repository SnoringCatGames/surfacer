class_name ScaffolderScreenHandler
extends Node


# FIXME: Redo screen handling.


var _screen_stack: Array[ActiveScreen] = []


func _init() -> void:
    S.log.on_global_init(self, "ScreenHandler")


func open(screen_name: String) -> void:
    if S.utils.is_running_in_isolated_scene_mode():
        S.log.warning("Screens not opened in isolated-scene mode: %s" % screen_name)
        return

    if !S.manifest.has_screen_scene(screen_name):
        push_error("Invalid screen_name: %s" % screen_name)
        return

    var previous_screen := get_top_screen()

    if is_instance_valid(previous_screen) and previous_screen.name == screen_name:
        S.log.print("Screen already open: %s" % screen_name)
        return

    if is_instance_valid(_get_active_screen_by_name(screen_name)):
        S.log.warning(
            "Moving preexisting screen to the top, rather than creating a new instance: " %
            screen_name)
        _move_screen_to_top(screen_name)
        return

    S.log.print("Opening screen: %s" % screen_name)

    var scene: PackedScene = S.manifest.get_screen_scene(screen_name)
    var screen: ScaffolderScreen = scene.instantiate()
    var stack_entry := ActiveScreen.new(screen_name, screen)

    # Update the screen-state of the old screen.
    if previous_screen:
        previous_screen.screen.screen_state = ScaffolderScreen.ScreenState.OPEN

    # Open the new screen.
    S.shell.add_to_canvas_layer(screen.canvas_layer, screen)
    _screen_stack.push_back(stack_entry)
    screen.screen_state = ScaffolderScreen.ScreenState.TOP

    if _is_a_pausing_screen_above_level() and is_instance_valid(S.level):
        # Pause the level when a screen is opened above it.
        S.level.pause()


func close_screens_above(screen_name: String) -> void:
    var target_screen := _get_active_screen_by_name(screen_name)
    if not S.utils.ensure(
            is_instance_valid(target_screen),
            "close_screens_above called for a screen that isn't actually open: %s" %
                screen_name):
        return

    var top_screen := get_top_screen()
    while is_instance_valid(top_screen) and top_screen.name != screen_name:
        close(top_screen.name)
        top_screen = get_top_screen()


func _move_screen_to_top(screen_name: String) -> void:
    var previous_screen := get_top_screen()
    if not S.utils.ensure(is_instance_valid(previous_screen)):
        return
    previous_screen.screen.screen_state = ScaffolderScreen.ScreenState.OPEN

    var next_screen := _get_active_screen_by_name(screen_name)
    _screen_stack.erase(next_screen)
    _screen_stack.push_back(next_screen)

    next_screen.screen.screen_state = ScaffolderScreen.ScreenState.TOP


func close(screen_node_or_name) -> bool:
    var display_text := S.utils.get_display_name(screen_node_or_name)
    S.log.print("ScreenHandler.close( %s )" % display_text)

    var screen_entry: ActiveScreen
    if screen_node_or_name is String:
        screen_entry = _get_active_screen_by_name(screen_node_or_name)
    else:
        screen_entry = _get_active_screen_by_node(screen_node_or_name)

    if is_instance_valid(screen_entry):
        var was_top := screen_entry.screen.screen_state == ScaffolderScreen.ScreenState.TOP

        # Remove the old screen.
        _screen_stack.erase(screen_entry)
        screen_entry.screen.queue_free()

        # Update the screen-state of the new top screen.
        var top_screen := get_top_screen()
        if (is_instance_valid(top_screen) and
                top_screen.screen.screen_state != ScaffolderScreen.ScreenState.TOP):
            top_screen.screen.screen_state = ScaffolderScreen.ScreenState.TOP

        if (not _is_a_pausing_screen_above_level()
                and is_instance_valid(S.level)
                and screen_entry.name != "game"):
            # Unpause the level when the screens above it are closed.
            S.level.unpause()

        return true

    S.log.print("Screen not open: %s" % display_text)

    return false


func get_top_screen() -> ActiveScreen:
    if _screen_stack.is_empty():
        return null
    return _screen_stack.back()


func is_top_screen(screen_name: String) -> bool:
    var top_screen := get_top_screen()
    return is_instance_valid(top_screen) and top_screen.name == screen_name


func _get_active_screen_by_name(name: String) -> ActiveScreen:
    if !S.manifest.has_screen_scene(name):
        push_error("Invalid screen_name: %s" % name)
        return null

    var index := _screen_stack.find_custom(
        func(entry: ActiveScreen): return entry.name == name)
    if index < 0:
        return null
    return _screen_stack[index]


func _get_active_screen_by_node(screen: ScaffolderScreen) -> ActiveScreen:
    var index := _screen_stack.find_custom(
        func(entry: ActiveScreen): return entry.screen == screen)
    if index < 0:
        return null
    return _screen_stack[index]


func _is_a_pausing_screen_above_level() -> bool:
    var game_screen := _get_active_screen_by_name("game")

    if not is_instance_valid(game_screen):
        return false

    var game_screen_index := _screen_stack.find(game_screen)
    var index := game_screen_index + 1
    while _screen_stack.size() > index:
        if _screen_stack[index].screen.pauses_game_when_open:
            return true
        index += 1

    return false


class ActiveScreen extends RefCounted:
    var name: String
    var screen: ScaffolderScreen

    func _init(name: String, screen: ScaffolderScreen) -> void:
        self.name = name
        self.screen = screen
