extends Node

func is_action_pressed(name: String) -> bool:
    return is_focus_for_actions() and \
            Input.is_action_pressed(name)

func is_action_released(name: String) -> bool:
    return is_focus_for_actions() and \
            Input.is_action_released(name)

func is_action_just_pressed(name: String) -> bool:
    return is_focus_for_actions() and \
            Input.is_action_just_pressed(name)

func is_action_just_released(name: String) -> bool:
    return is_focus_for_actions() and \
            Input.is_action_just_released(name)

func is_key_pressed(code: int) -> bool:
    return is_focus_for_actions() and \
            Input.is_key_pressed(code)

func is_focus_for_actions() -> bool:
    return !is_instance_valid(SurfacerConfig.platform_graph_inspector) or \
            !SurfacerConfig.platform_graph_inspector.has_focus
