class_name ScaffolderLog
extends Node


const MAX_LOG_COUNT := 200

var logs_early_bootstrap_events := false

var _print_queue := CircularBuffer.new(MAX_LOG_COUNT)


func _ready() -> void:
    _print_front_matter()
    self.on_global_init(self, "ScaffolderLog")


func print(message = "", print_to_console := true) -> void:
    if not message is String:
        message = str(message)

    message = prepend_time(message)

    _print_queue.push(message)

    if is_instance_valid(G) and is_instance_valid(G.super_hud):
        G.super_hud.add_log(message, MAX_LOG_COUNT)

    if print_to_console:
        print(message)


# -   Using this function instead of `push_error` directly enables us to render
#     the console output in environments like a mobile device.
# -   This requires an explicit error message in order to disambiguate where
#     the error actually happened.
#     -   This is needed because stack traces are not available on non-main
#         threads.
func error(
        message: String,
        should_assert := true) -> void:
    var play_time: float = \
            S.time.get_play_time() if \
            is_instance_valid(S.time) else \
            -1.0
    message = prepend_time(message)
    push_error("ERROR:%8.3f; %s" % [play_time, message])
    self.print("**ERROR**:%8.3f; %s" % [play_time, message], false)
    if should_assert:
         assert(false)


# -   Using this function instead of `push_error` directly enables us to render
#     the console output in environments like a mobile device.
# -   This requires an explicit error message in order to disambiguate where
#     the error actually happened.
#     -   This is needed because stack traces are not available on non-main
#         threads.
static func static_error(
        message: String,
        should_assert := true) -> void:
    message = prepend_time(message)
    push_error("ERROR: %s" % message)
    if should_assert:
         assert(false)


# -   Using this function instead of `push_error` directly enables us to render
#     the console output in environments like a mobile device.
# -   This requires an explicit error message in order to disambiguate where
#     the error actually happened.
#     -   This is needed because stack traces are not available on non-main
#         threads.
func warning(message: String) -> void:
    message = prepend_time(message)
    push_warning("WARNING: %s" % message)
    self.print("**WARNING**: %s" % message, false)


func on_global_init(
        global: Node,
        name: String,
        expect_is_tool := true) -> void:
    global.name = name

    if logs_early_bootstrap_events:
        self.print("%s._init" % name)

    if Engine.is_editor_hint() and \
            expect_is_tool and \
            is_instance_valid(S.utils):
        assert(S.utils.check_whether_sub_classes_are_tools(global))


func _print_front_matter() -> void:
    self.print(get_datetime_string())
    self.print((
        "%s " +
        "%s " +
        "(%4d,%4d) " +
        ""
    ) % [
        OS.get_name(),
        OS.get_model_name(),
        get_viewport().size.x,
        get_viewport().size.y,
    ])
    if logs_early_bootstrap_events:
        self.print("")


# NOTE: Keep this in-sync with the duplicate function in Utils.
static func get_datetime_string() -> String:
    var datetime := Time.get_datetime_dict_from_system()
    return "%02d-%02d-%02d_%02d.%02d.%02d" % [
        datetime.year,
        datetime.month,
        datetime.day,
        datetime.hour,
        datetime.minute,
        datetime.second,
    ]


static func get_time_string() -> String:
    var datetime := Time.get_datetime_dict_from_system()
    return "%02d.%02d.%02d" % [
        datetime.hour,
        datetime.minute,
        datetime.second,
    ]


static func prepend_time(message: String) -> String:
    return "[%s] %s" % [get_time_string(), message]
