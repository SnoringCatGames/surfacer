extends SurfacerLevel
class_name SquirrelAwayLevel

const _WELCOME_PANEL_RESOURCE_PATH := \
        "res://addons/surfacer/src/gui/panels/welcome_panel.tscn"

func start() -> void:
    .start()
    
    var welcome_panel: WelcomePanel = ScaffoldUtils.add_scene( \
            ScaffoldConfig.canvas_layers.layers.hud, \
            _WELCOME_PANEL_RESOURCE_PATH)
    SurfacerConfig.welcome_panel = welcome_panel
    
    # FIXME: Move this player creation (and readiness recording) back into
    #        Level.
    # Add the player after removing the loading screen, since the camera
    # will track the player, which makes the loading screen look offset.
    add_player( \
            SurfacerConfig.player_params[SurfacerConfig.default_player_name] \
                    .movement_params.player_resource_path, \
            Vector2.ZERO, \
            true, \
            false)
    var starting_squirrel_positions := [
        Vector2(192.0, -192.0),
#        Vector2(-192.0, 192.0),
    ]
    for squirrel_position in starting_squirrel_positions:
        add_player( \
                SurfacerConfig.player_params["squirrel"].movement_params \
                        .player_resource_path, \
                squirrel_position, \
                false, \
                false)
    
    SurfacerConfig.annotators.on_level_ready()
    
    Audio.play_music("on_a_quest")

func destroy() -> void:
    pass
