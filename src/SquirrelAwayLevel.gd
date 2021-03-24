tool
class_name SquirrelAwayLevel
extends SurfacerLevel

const _WELCOME_PANEL_RESOURCE_PATH := \
        "res://addons/surfacer/src/gui/panels/WelcomePanel.tscn"

export var id: String setget _set_id,_get_id

func _input(event: InputEvent) -> void:
    # Close the welcome panel on any mouse or key click event.
    if is_instance_valid(Surfacer.welcome_panel) and \
            (event is InputEventMouseButton or \
                    event is InputEventScreenTouch or \
                    event is InputEventKey) and \
            Surfacer.is_level_ready:
        Surfacer.welcome_panel.queue_free()
        Surfacer.welcome_panel = null

func start() -> void:
    .start()
    
    var welcome_panel: WelcomePanel = Gs.utils.add_scene( \
            Gs.canvas_layers.layers.hud, \
            _WELCOME_PANEL_RESOURCE_PATH)
    Surfacer.welcome_panel = welcome_panel
    
    # FIXME: Move this player creation (and readiness recording) back into
    #        Level.
    # Add the player after removing the loading screen, since the camera
    # will track the player, which makes the loading screen look offset.
    add_player( \
            Surfacer.player_params[Surfacer.default_player_name] \
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
                Surfacer.player_params["squirrel"].movement_params \
                        .player_resource_path, \
                squirrel_position, \
                false, \
                false)
    
    Surfacer.annotators.on_level_ready()
    
    Gs.audio.play_music("on_a_quest")

func destroy() -> void:
    .destroy()

func quit() -> void:
    .quit()

func _set_id(value: String) -> void:
    level_id = value

func _get_id() -> String:
    return level_id
