class_name SurfacerClickAnnotator
extends ScaffolderClickAnnotator


var VALID_SURFACE_COLOR: Color = Sc.colors.surface_click_selection
var INVALID_SURFACE_COLOR: Color = Sc.colors.opacify(
        Sc.colors.invalid, ScaffolderColors.ALPHA_SOLID)

const SURFACE_DURATION := 0.4

var selected_surface: Surface
var is_surface_navigable: bool

var surface_progress: float


func _init(
        click_position: Vector2,
        selected_surface: Surface,
        is_surface_navigable: bool
        ).(
        click_position,
        max(max(
                CLICK_INNER_DURATION,
                CLICK_OUTER_DURATION),
                SURFACE_DURATION)
        ) -> void:
    self.selected_surface = selected_surface
    self.is_surface_navigable = is_surface_navigable
    _update()


func _update() -> void:
    ._update()
    
    surface_progress = (current_time - start_time) / SURFACE_DURATION
    surface_progress = Sc.utils.ease_by_name(surface_progress, "ease_out")


func _draw() -> void:
    var is_surface_animation_complete := surface_progress >= 1.0
    
    if !is_surface_animation_complete and \
            selected_surface != null:
        var color := \
                VALID_SURFACE_COLOR if \
                is_surface_navigable else \
                VALID_SURFACE_COLOR
        var alpha := color.a * (1 - surface_progress)
        color.a = alpha
        
        Sc.draw.draw_surface(
                self,
                selected_surface,
                color)
