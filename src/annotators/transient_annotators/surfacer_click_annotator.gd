class_name SurfacerClickAnnotator
extends ScaffolderClickAnnotator


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
                Sc.annotators.params.click_inner_duration,
                Sc.annotators.params.click_outer_duration),
                Sc.annotators.params.click_surface_duration)
        ) -> void:
    self.selected_surface = selected_surface
    self.is_surface_navigable = is_surface_navigable
    _update()


func _update() -> void:
    ._update()
    
    surface_progress = \
            (current_time - start_time) / \
            Sc.annotators.params.click_surface_duration
    surface_progress = Sc.utils.ease_by_name(surface_progress, "ease_out")


func _draw() -> void:
    var is_surface_animation_complete := surface_progress >= 1.0
    
    if !is_surface_animation_complete and \
            selected_surface != null:
        var color: Color = \
                Sc.annotators.params.click_valid_surface_color.sample() if \
                is_surface_navigable else \
                Sc.annotators.params.click_invalid_surface_color.sample()
        var alpha := color.a * (1 - surface_progress)
        color.a = alpha
        
        Sc.draw.draw_surface(
                self,
                selected_surface,
                color)
