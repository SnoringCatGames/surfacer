class_name InstructionsActionSource
extends PlayerActionSource

# Array<InstructionsPlayback>
var _all_playback := []

func _init(
        player,
        is_additive: bool) \
        .(
        "CP",
        player,
        is_additive) -> void:
    pass

# Calculates actions for the current frame.
func update(
        actions: PlayerActionState,
        previous_actions: PlayerActionState,
        time_modified_sec: float,
        delta_sec: float,
        navigation_state: PlayerNavigationState) -> void:
    var is_pressed: bool
    var non_pressed_keys := []
    
    for playback in _all_playback:
        # Handle any new key presses up till the current time.
        var new_instructions: Array = playback.update(
                time_modified_sec,
                navigation_state)
        
        non_pressed_keys.clear()
        
        # Handle all previously started keys that are still pressed.
        for input_key in playback.active_key_presses:
            is_pressed = playback.active_key_presses[input_key]
            PlayerActionSource.update_for_key_press(
                    actions,
                    previous_actions,
                    input_key,
                    is_pressed,
                    time_modified_sec,
                    is_additive)
            if !is_pressed:
                non_pressed_keys.push_back(input_key)
        
        # Remove from the active set all keys that are no longer pressed.
        for input_key in non_pressed_keys:
            playback.active_key_presses.erase(input_key)
    
    # Handle instructions that finish.
    var i := 0
    while i < _all_playback.size():
        if _all_playback[i].is_finished:
            _all_playback.remove(i)
            i -= 1
        i += 1

func start_instructions(
        edge: Edge,
        time_modified_sec: float) -> InstructionsPlayback:
    var playback := InstructionsPlayback.new(
            edge,
            is_additive)
    playback.start(time_modified_sec)
    _all_playback.push_back(playback)
    return playback

func cancel_playback(
        playback: InstructionsPlayback,
        time_modified_sec: float) -> bool:
    # Remove the playback.
    var index := _all_playback.find(playback)
    if index < 0:
        return false
    else:
        _all_playback.remove(index)
        return true

func cancel_all_playback() -> void:
    _all_playback.clear()
