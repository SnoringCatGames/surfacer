extends Node

const HEADERS := ["Content-Type: application/json"]

func _init() -> void:
    ScaffoldUtils.print("Log._init")

func record_recent_gestures() -> void:
    var recent_top_level_events_raw_str := ""
    
    if is_instance_valid(ScaffoldConfig.gesture_record):
        var events: Array = ScaffoldConfig.gesture_record \
                .recent_gesture_events_for_debugging
        for event in events:
            recent_top_level_events_raw_str += event.to_string()
    
    var url: String = ScaffoldUtils.get_log_gestures_url()
    
    var body_object := {
        recent_top_level_gesture_events = recent_top_level_events_raw_str,
    }
    var body_str := JSON.print(body_object)
    
    ScaffoldUtils.print("Log.record_recent_gestures: %s" % url)
    
    if !ScaffoldConfig.agreed_to_terms:
        # User hasn't agreed to data collection.
        ScaffoldUtils.error()
        return
    
    var request := HTTPRequest.new()
    request.use_threads = true
    request.connect( \
            "request_completed", \
            self, \
            "_on_record_recent_gestures_request_completed", \
            [request])
    add_child(request)
    
    var status: int = request.request( \
            url, \
            HEADERS, \
            true, \
            HTTPClient.METHOD_POST, \
            body_str)
    
    if status != OK:
        ScaffoldUtils.error( \
                "Log.record_recent_gestures failed: status=%d" % status, \
                false)

func _on_record_recent_gestures_request_completed( \
        result: int, \
        response_code: int, \
        headers: PoolStringArray, \
        body: PoolByteArray, \
        request: HTTPRequest) -> void:
    ScaffoldUtils.print( \
            ("Log._on_record_recent_gestures_request_completed: " + \
            "result=%d, code=%d") % \
            [result, response_code])
    if result != HTTPRequest.RESULT_SUCCESS or \
            response_code < 200 or \
            response_code >= 300:
        ScaffoldUtils.print("  Body:\n    " + body.get_string_from_utf8())
        ScaffoldUtils.print( \
                "  Headers:\n    " + ScaffoldUtils.join(headers, ",\n    "))
    request.queue_free()
