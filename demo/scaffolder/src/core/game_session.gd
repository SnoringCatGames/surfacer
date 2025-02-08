class_name ScaffolderGameSession
extends RefCounted


var start_time: float
var end_time: float

var play_time: float:
    get:
        if start_time > 0:
            if end_time > 0:
                return end_time - start_time
            else:
                return S.time.get_play_time() - start_time
        else:
            return 0


func _init() -> void:
    reset()


func reset() -> void:
    randomize()
    start_time = 0.0
    end_time = 0.0
