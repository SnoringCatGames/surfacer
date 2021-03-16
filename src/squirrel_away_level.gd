extends SurfacerLevel
class_name SquirrelAwayLevel

const _UTILITY_PANEL_RESOURCE_PATH := \
        "res://addons/surfacer/gui/panels/utility_panel.tscn"
const _WELCOME_PANEL_RESOURCE_PATH := \
        "res://addons/surfacer/gui/panels/welcome_panel.tscn"

var annotators: Annotators

func start() -> void:
    ScaffoldConfig.level = self
    
    annotators = Annotators.new()
    add_child(annotators)
    
    var utility_panel: UtilityPanel = ScaffoldUtils.add_scene( \
            ScaffoldConfig.canvas_layers.layers.hud, \
            _UTILITY_PANEL_RESOURCE_PATH)
    Global.utility_panel = utility_panel
    
    var welcome_panel: WelcomePanel = ScaffoldUtils.add_scene( \
            ScaffoldConfig.canvas_layers.layers.hud, \
            _WELCOME_PANEL_RESOURCE_PATH)
    Global.welcome_panel = welcome_panel
    
    # FIXME: Move this player creation (and readiness recording) back into
    #        Level.
    # Add the player after removing the loading screen, since the camera
    # will track the player, which makes the loading screen look offset.
    add_player( \
            Global.player_params[SurfacerConfig.DEFAULT_PLAYER_NAME] \
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
                Global.player_params["squirrel"].movement_params \
                        .player_resource_path, \
                squirrel_position, \
                false, \
                false)
    annotators.on_level_ready()

func destroy() -> void:
    pass
