class_name ScaffoldLevel
extends Node2D

var level_id: String
var level_start_time: float
var score := 0.0

func _ready() -> void:
    Gs.utils.connect( \
            "display_resized", \
            self, \
            "_on_resized")
    _on_resized()

func _on_resized() -> void:
    pass

func start() -> void:
    Gs.level = self
    Gs.audio.play_music(_get_music_name())
    level_start_time = Gs.time.elapsed_play_time_actual_sec
    Gs.save_state.set_level_total_plays( \
            level_id, \
            Gs.save_state.get_level_total_plays(level_id) + 1)
    Gs.analytics.event( \
            "level", \
            "start", \
            Gs.level_config.get_level_version_string(level_id))

func destroy() -> void:
    Gs.level = null

func quit() -> void:
    Gs.audio.stop_music()
    Gs.audio.get_sound_player(Gs.level_end_sound) \
            .connect("finished", self, "_on_level_quit_sound_finished")
    Gs.audio.play_sound(Gs.level_end_sound)
    _record_level_results()
    destroy()

func _record_level_results() -> void:
    var game_over_screen = Gs.nav.screens["game_over"]
    game_over_screen.level_id = level_id
    game_over_screen.time = Gs.utils.get_time_string_from_seconds( \
            Gs.time.elapsed_play_time_actual_sec - \
            level_start_time)
    
    if Gs.uses_level_scores:
        Gs.analytics.event( \
                "score", \
                "v" + Gs.score_version, \
                Gs.level_config.get_level_version_string(level_id), \
                int(score))
        
        var previous_high_score: int = Gs.save_state.get_level_high_score(level_id)
        if score > previous_high_score:
            Gs.save_state.set_level_high_score( \
                    level_id, \
                    int(score))
            game_over_screen.reached_new_high_score = true
        
        var all_scores: Array = Gs.save_state.get_level_all_scores(level_id)
        all_scores.push_back(score)
        Gs.save_state.set_level_all_scores(level_id, all_scores)
        
        game_over_screen.score = str(int(score))
        game_over_screen.high_score = \
                str(Gs.save_state.get_level_high_score(level_id))
    
    var old_unlocked_levels: Array = Gs.level_config.get_old_unlocked_levels()
    var new_unlocked_levels: Array = Gs.level_config.get_new_unlocked_levels()
    Gs.save_state.set_new_unlocked_levels(new_unlocked_levels)
    for other_level_id in new_unlocked_levels:
        Gs.save_state.set_level_is_unlocked(other_level_id, true)
        Gs.analytics.event( \
                "level", \
                "unlocked", \
                Gs.level_config.get_level_version_string(other_level_id), \
                Gs.level_config.get_level_config(other_level_id).number)
    game_over_screen.new_unlocked_levels = new_unlocked_levels

func _on_level_quit_sound_finished() -> void:
    Gs.audio.get_sound_player(Gs.level_end_sound) \
            .disconnect("finished", self, "_on_level_quit_sound_finished")
    var is_rate_app_screen_next: bool = \
            Gs.is_rate_app_shown and \
            _get_is_rate_app_screen_next()
    var next_screen := \
            "rate_app" if \
            is_rate_app_screen_next else \
            "game_over"
    Gs.nav.open(next_screen, true)
    Gs.nav.screens["game"].destroy_level()

func _get_music_name() -> String:
    return "on_a_quest"

func _get_is_rate_app_screen_next() -> bool:
    Gs.utils.error( \
            "Abstract ScaffoldLevel._get_is_rate_app_screen_next " + \
            "is not implemented")
    return false
