tool
extends Screen
class_name DeveloperSplashScreen

const NAME := "developer_splash"
const LAYER_NAME := "menu_screen"
const INCLUDES_STANDARD_HIERARCHY := false
const INCLUDES_NAV_BAR := false
const INCLUDES_CENTER_CONTAINER := false

const SPLASH_IMAGE_SIZE_DEFAULT := Vector2(900, 835)

func _init().( \
        NAME, \
        LAYER_NAME, \
        INCLUDES_STANDARD_HIERARCHY, \
        INCLUDES_NAV_BAR, \
        INCLUDES_CENTER_CONTAINER \
        ) -> void:
    pass

func _enter_tree() -> void:
    if Engine.editor_hint:
        var viewport_size := Vector2(480, 480)
        var scale := viewport_size / SPLASH_IMAGE_SIZE_DEFAULT
        if scale.x > scale.y:
            scale.x = scale.y
        else:
            scale.y = scale.x
        var position := -SPLASH_IMAGE_SIZE_DEFAULT / 2
        $FullScreenPanel/Control/TextureRect.rect_scale = scale
        $FullScreenPanel/Control/TextureRect.rect_position = position
    else:
        ScaffoldUtils.connect( \
                "display_resized", \
                self, \
                "_handle_display_resized")
        _handle_display_resized()
    $FullScreenPanel/Control/TextureRect.texture = \
            ScaffoldConfig.developer_splash

func _handle_display_resized() -> void:
    var viewport_size := get_viewport().size
    var scale := viewport_size / SPLASH_IMAGE_SIZE_DEFAULT
    if scale.x > scale.y:
        scale.x = scale.y
    else:
        scale.y = scale.x
    var position := -(SPLASH_IMAGE_SIZE_DEFAULT * scale) / 2
    $FullScreenPanel/Control/TextureRect.rect_scale = scale
    $FullScreenPanel/Control/TextureRect.rect_position = position
