class_name CloudLog
extends Node

const HEADERS := ["Content-Type: application/json"]

func _init() -> void:
    print("CloudLog._init")

func record_recent_gestures() -> void:
    assert(Gs.is_gesture_logging_supported)
    
    var recent_top_level_events_raw_str := ""
    
    if is_instance_valid(Gs.gesture_record):
        var events: Array = Gs.gesture_record \
                .recent_gesture_events_for_debugging
        for event in events:
            recent_top_level_events_raw_str += event.to_string()
    
    var url: String = Gs.utils.get_log_gestures_url()
    
    var body_object := {
        recent_top_level_gesture_events = recent_top_level_events_raw_str,
    }
    var body_str := JSON.print(body_object)
    
    Gs.utils.print("CloudLog.record_recent_gestures: %s" % url)
    
    if !Gs.agreed_to_terms or \
            !Gs.is_data_tracked:
        # User hasn't agreed to data collection.
        Gs.utils.error()
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
        Gs.utils.error( \
                "CloudLog.record_recent_gestures failed: status=%d" % status, \
                false)

func _on_record_recent_gestures_request_completed( \
        result: int, \
        response_code: int, \
        headers: PoolStringArray, \
        body: PoolByteArray, \
        request: HTTPRequest) -> void:
    Gs.utils.print( \
            ("CloudLog._on_record_recent_gestures_request_completed: " + \
            "result=%d, code=%d") % \
            [result, response_code])
    if result != HTTPRequest.RESULT_SUCCESS or \
            response_code < 200 or \
            response_code >= 300:
        Gs.utils.print("  Body:\n    " + body.get_string_from_utf8())
        Gs.utils.print( \
                "  Headers:\n    " + Gs.utils.join(headers, ",\n    "))
    request.queue_free()
