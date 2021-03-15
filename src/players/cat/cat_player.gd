extends Player
class_name CatPlayer

const JUMP_SFX_STREAM := preload("res://assets/sfx/cat_jump.wav")
const LAND_SFX_STREAM := preload("res://assets/sfx/cat_land.wav")
const CONTACT_SFX_STREAM := preload("res://assets/sfx/contact.wav")

# Dictionary<Player, boolean>
var current_colliding_computer_players := {}
var just_collided_with_new_computer_player := false

var jump_sfx_player: AudioStreamPlayer
var land_sfx_player: AudioStreamPlayer
var contact_sfx_player: AudioStreamPlayer

func _init().("cat") -> void:
    _init_sfx_players()

func _init_sfx_players() -> void:
    jump_sfx_player = AudioStreamPlayer.new()
    jump_sfx_player.stream = JUMP_SFX_STREAM
    add_child(jump_sfx_player)
    
    land_sfx_player = AudioStreamPlayer.new()
    land_sfx_player.stream = LAND_SFX_STREAM
    add_child(land_sfx_player)
    
    contact_sfx_player = AudioStreamPlayer.new()
    contact_sfx_player.stream = CONTACT_SFX_STREAM
    add_child(contact_sfx_player)

func _process_sfx() -> void:
    if just_triggered_jump:
        jump_sfx_player.play()
    
    if surface_state.just_left_air:
        land_sfx_player.play()
    
    if just_collided_with_new_computer_player:
        contact_sfx_player.play()

func _update_surface_state(preserves_just_changed_state := false) -> void:
    ._update_surface_state(preserves_just_changed_state)
    _check_for_squirrel_collision()

# TODO: Replace with a more accurate/standard collision/mask-layer setup.
func _check_for_squirrel_collision() -> void:
    var cat_min_half_dimension: float
    var cat_max_half_dimension: float
    var cp_min_half_dimension: float
    var cp_max_half_dimension: float
    
    var collider_half_width_height := movement_params.collider_half_width_height
    if collider_half_width_height.x > collider_half_width_height.y:
        cat_max_half_dimension = collider_half_width_height.x
        cat_min_half_dimension = collider_half_width_height.y
    else:
        cat_max_half_dimension = collider_half_width_height.y
        cat_min_half_dimension = collider_half_width_height.x
    
    # Calculate current computer-player collisions.
    var colliding_computer_players := []
    for computer_player in \
            get_tree().get_nodes_in_group(Utils.GROUP_NAME_COMPUTER_PLAYERS):
        collider_half_width_height = \
                computer_player.movement_params.collider_half_width_height
        if collider_half_width_height.x > collider_half_width_height.y:
            cp_max_half_dimension = collider_half_width_height.x
            cp_min_half_dimension = collider_half_width_height.y
        else:
            cp_max_half_dimension = collider_half_width_height.y
            cp_min_half_dimension = collider_half_width_height.x
        
        var distance_squared_collision_threshold: float
        if cat_max_half_dimension > cp_max_half_dimension:
            distance_squared_collision_threshold = \
                    cat_min_half_dimension * cat_min_half_dimension
        else:
            distance_squared_collision_threshold = \
                    cp_min_half_dimension * cp_min_half_dimension
        
        if position.distance_squared_to(computer_player.position) < \
                distance_squared_collision_threshold:
            colliding_computer_players.push_back(computer_player)
    
    # Record whether there were any new collisions this frame.
    just_collided_with_new_computer_player = false
    for computer_player in colliding_computer_players:
        if !current_colliding_computer_players.has(computer_player):
            just_collided_with_new_computer_player = true
    
    # Update the current collision set.
    current_colliding_computer_players.clear()
    for computer_player in colliding_computer_players:
        current_colliding_computer_players[computer_player] = true
