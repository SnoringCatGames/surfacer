tool
class_name DefaultAppManifest
extends FrameworkConfig


# ---

# This method is useful for defining parameters that are likely to change
# between builds or between development and production environments.
func _override_configs_for_current_run(manifest: Dictionary) -> void:
    Sc.logger.error(
            "Abstract DefaultAppManifest._override_configs_for_current_run " +
            "is not implemented")

# ---

var _default_fonts_manifest_normal := {
    fonts = {
        main_xs = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_xs.tres"),
        main_xs_bold = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_xs.tres"),
        main_xs_italic = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_xs_italic.tres"),
        main_s = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_s.tres"),
        main_s_bold = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_s.tres"),
        main_s_italic = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_s.tres"),
        main_m = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_m.tres"),
        main_m_bold = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_m_bold.tres"),
        main_m_italic = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_m_italic.tres"),
        main_l = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_l.tres"),
        main_l_bold = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_l.tres"),
        main_l_italic = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_l.tres"),
        main_xl = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_xl.tres"),
        main_xl_bold = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_xl.tres"),
        main_xl_italic = preload( \
                "res://addons/scaffolder/assets/fonts/roboto_font_xl.tres"),
        
        header_s = preload( \
                "res://addons/scaffolder/assets/fonts/nunito_font_s.tres"),
        header_m = preload( \
                "res://addons/scaffolder/assets/fonts/nunito_font_m.tres"),
        header_l = preload( \
                "res://addons/scaffolder/assets/fonts/nunito_font_l.tres"),
        header_xl = preload( \
                "res://addons/scaffolder/assets/fonts/nunito_font_xl.tres"),
    },
    sizes = {
        pc = {
            main_xs = 15,
            main_s = 18,
            main_m = 30,
            main_l = 42,
            main_xl = 48,
#            _bold = ,
#            _italic = ,
#            header_s = ,
#            header_m = ,
#            header_l = ,
#            header_xl = ,
        },
        mobile = {
            main_xs = 16,
            main_s = 18,
            main_m = 28,
            main_l = 32,
            main_xl = 36,
        },
    },
}

var _default_fonts_manifest_pixel := {
    fonts = {
        main_xs = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_xs.tres"),
        main_xs_bold = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_xs.tres"),
        main_xs_italic = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_xs.tres"),
        main_s = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_s.tres"),
        main_s_bold = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_s.tres"),
        main_s_italic = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_s.tres"),
        main_m = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_m.tres"),
        main_m_bold = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_m.tres"),
        main_m_italic = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_m.tres"),
        main_l = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_l.tres"),
        main_l_bold = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_l.tres"),
        main_l_italic = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_l.tres"),
        main_xl = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_xl.tres"),
        main_xl_bold = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_xl.tres"),
        main_xl_italic = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_xl.tres"),
        
        header_s = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_s.tres"),
        header_m = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_m.tres"),
        header_l = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_l.tres"),
        header_xl = preload( \
                "res://addons/scaffolder/assets/fonts/pxlzr_font_xl.tres"),
    },
    sizes = {
        pc = {
            main_xs = 15,
            main_s = 18,
            main_m = 30,
            main_l = 42,
            main_xl = 48,
#            _bold = ,
#            _italic = ,
#            header_s = ,
#            header_m = ,
#            header_l = ,
#            header_xl = ,
        },
        mobile = {
            main_xs = 16,
            main_s = 18,
            main_m = 28,
            main_l = 32,
            main_xl = 36,
        },
    },
}

var _default_styles_manifest_normal := {
    focus_border_corner_radius = 5,
    focus_border_corner_detail = 3,
    focus_border_shadow_size = 0,
    focus_border_border_width = 1,
    focus_border_expand_margin_left = 2.0,
    focus_border_expand_margin_top = 2.0,
    focus_border_expand_margin_right = 2.0,
    focus_border_expand_margin_bottom = 2.0,
    
    button_content_margin_left = 16.0,
    button_content_margin_top = 8.0,
    button_content_margin_right = 16.0,
    button_content_margin_bottom = 8.0,
    
    button_shine_margin_left = 0.0,
    button_shine_margin_top = 0.0,
    button_shine_margin_right = 0.0,
    button_shine_margin_bottom = 0.0,
    
    button_corner_radius = 4,
    button_corner_detail = 3,
    button_shadow_size = 3,
    button_border_width = 0,
    
    dropdown_corner_radius = 4,
    dropdown_corner_detail = 3,
    dropdown_shadow_size = 0,
    dropdown_border_width = 0,
    
    scroll_corner_radius = 6,
    scroll_corner_detail = 3,
    # Width of the scrollbar.
    scroll_content_margin_left = 7,
    scroll_content_margin_top = 7,
    scroll_content_margin_right = 7,
    scroll_content_margin_bottom = 7,
    
    scroll_grabber_corner_radius = 8,
    scroll_grabber_corner_detail = 3,
    
    slider_corner_radius = 6,
    slider_corner_detail = 3,
    slider_content_margin_left = 5,
    slider_content_margin_top = 5,
    slider_content_margin_right = 5,
    slider_content_margin_bottom = 5,
    
    overlay_panel_border_width = 2,
    
    overlay_panel_corner_radius = 4,
    overlay_panel_corner_detail = 3,
    overlay_panel_content_margin_left = 0.0,
    overlay_panel_content_margin_top = 0.0,
    overlay_panel_content_margin_right = 0.0,
    overlay_panel_content_margin_bottom = 0.0,
    overlay_panel_shadow_size = 8,
    overlay_panel_shadow_offset = Vector2(-4.0, 4.0),
    
    header_panel_content_margin_left = 0.0,
    header_panel_content_margin_top = 0.0,
    header_panel_content_margin_right = 0.0,
    header_panel_content_margin_bottom = 0.0,
    
    hud_panel_nine_patch = \
            preload("res://addons/scaffolder/assets/images/gui/overlay_panel.png"),
    hud_panel_nine_patch_margin_left = 3.5,
    hud_panel_nine_patch_margin_top = 3.5,
    hud_panel_nine_patch_margin_right = 3.5,
    hud_panel_nine_patch_margin_bottom = 3.5,
    hud_panel_nine_patch_scale = 3.0,
    hud_panel_content_margin_left = 8.0,
    hud_panel_content_margin_top = 2.0,
    hud_panel_content_margin_right = 8.0,
    hud_panel_content_margin_bottom = 2.0,
    
    screen_shadow_size = 8,
    screen_shadow_offset = Vector2(-4.0, 4.0),
    screen_border_width = 0,
}

var _default_styles_manifest_pixel := {
    button_content_margin_left = 16.0,
    button_content_margin_top = 8.0,
    button_content_margin_right = 16.0,
    button_content_margin_bottom = 8.0,
    
    button_shine_margin_left = 6.0,
    button_shine_margin_top = 6.0,
    button_shine_margin_right = 6.0,
    button_shine_margin_bottom = 6.0,
    
    focus_border_nine_patch = \
            preload("res://addons/scaffolder/assets/images/gui/focus_border.png"),
    focus_border_nine_patch_margin_left = 3.5,
    focus_border_nine_patch_margin_top = 3.5,
    focus_border_nine_patch_margin_right = 3.5,
    focus_border_nine_patch_margin_bottom = 3.5,
    focus_border_nine_patch_scale = 3.0,
    focus_border_expand_margin_left = 3.0,
    focus_border_expand_margin_top = 3.0,
    focus_border_expand_margin_right = 3.0,
    focus_border_expand_margin_bottom = 3.0,
    
    button_active_nine_patch = \
            preload("res://assets/images/button_active.png"),
    button_disabled_nine_patch = \
            preload("res://assets/images/button_hover.png"),
    button_hover_nine_patch = \
            preload("res://assets/images/button_hover.png"),
    button_normal_nine_patch = \
            preload("res://assets/images/button_normal.png"),
    button_nine_patch_margin_left = 3.5,
    button_nine_patch_margin_top = 3.5,
    button_nine_patch_margin_right = 3.5,
    button_nine_patch_margin_bottom = 3.5,
    button_nine_patch_scale = 3.0,
    
    dropdown_active_nine_patch = \
            preload("res://assets/images/dropdown_active.png"),
    dropdown_disabled_nine_patch = \
            preload("res://assets/images/dropdown_hover.png"),
    dropdown_hover_nine_patch = \
            preload("res://assets/images/dropdown_hover.png"),
    dropdown_normal_nine_patch = \
            preload("res://assets/images/dropdown_normal.png"),
    dropdown_nine_patch_margin_left = 3.5,
    dropdown_nine_patch_margin_top = 3.5,
    dropdown_nine_patch_margin_right = 3.5,
    dropdown_nine_patch_margin_bottom = 3.5,
    dropdown_nine_patch_scale = 3.0,
    
    scroll_track_nine_patch = \
            preload("res://assets/images/scroll_track.png"),
    scroll_track_nine_patch_margin_left = 3.5,
    scroll_track_nine_patch_margin_top = 3.5,
    scroll_track_nine_patch_margin_right = 3.5,
    scroll_track_nine_patch_margin_bottom = 3.5,
    scroll_track_nine_patch_scale = 3.0,
    
    scroll_grabber_active_nine_patch = \
            preload("res://assets/images/scroll_grabber_active.png"),
    scroll_grabber_hover_nine_patch = \
            preload("res://assets/images/scroll_grabber_hover.png"),
    scroll_grabber_normal_nine_patch = \
            preload("res://assets/images/scroll_grabber_normal.png"),
    scroll_grabber_nine_patch_margin_left = 3.5,
    scroll_grabber_nine_patch_margin_top = 3.5,
    scroll_grabber_nine_patch_margin_right = 3.5,
    scroll_grabber_nine_patch_margin_bottom = 3.5,
    scroll_grabber_nine_patch_scale = 3.0,
    
    slider_track_nine_patch = \
            preload("res://addons/scaffolder/assets/images/gui/slider_track.png"),
    slider_track_nine_patch_margin_left = 1.5,
    slider_track_nine_patch_margin_top = 1.5,
    slider_track_nine_patch_margin_right = 1.5,
    slider_track_nine_patch_margin_bottom = 1.5,
    slider_track_nine_patch_scale = 3.0,
    
    overlay_panel_border_width = 2,
    
    overlay_panel_nine_patch = \
            preload("res://addons/scaffolder/assets/images/gui/overlay_panel.png"),
    overlay_panel_nine_patch_margin_left = 3.5,
    overlay_panel_nine_patch_margin_top = 3.5,
    overlay_panel_nine_patch_margin_right = 3.5,
    overlay_panel_nine_patch_margin_bottom = 3.5,
    overlay_panel_nine_patch_scale = 3.0,
    overlay_panel_content_margin_left = 3.0,
    overlay_panel_content_margin_top = 3.0,
    overlay_panel_content_margin_right = 3.0,
    overlay_panel_content_margin_bottom = 3.0,
    
    header_panel_content_margin_left = 0.0,
    header_panel_content_margin_top = 0.0,
    header_panel_content_margin_right = 0.0,
    header_panel_content_margin_bottom = 0.0,
    
    hud_panel_nine_patch = \
            preload("res://addons/scaffolder/assets/images/gui/overlay_panel.png"),
    hud_panel_nine_patch_margin_left = 3.5,
    hud_panel_nine_patch_margin_top = 3.5,
    hud_panel_nine_patch_margin_right = 3.5,
    hud_panel_nine_patch_margin_bottom = 3.5,
    hud_panel_nine_patch_scale = 3.0,
    hud_panel_content_margin_left = 8.0,
    hud_panel_content_margin_top = 2.0,
    hud_panel_content_margin_right = 8.0,
    hud_panel_content_margin_bottom = 2.0,
    
    screen_shadow_size = 0,
    screen_shadow_offset = Vector2.ZERO,
    screen_border_width = 0,
}

var _default_icons_manifest_normal := {
    checkbox_path_prefix = \
            ScaffolderIcons.DEFAULT_CHECKBOX_NORMAL_PATH_PREFIX,
    default_checkbox_size = \
            ScaffolderIcons.DEFAULT_CHECKBOX_NORMAL_SIZE,
    checkbox_sizes = \
            ScaffolderIcons.DEFAULT_CHECKBOX_NORMAL_SIZES,
    
    radio_button_path_prefix = \
            ScaffolderIcons.DEFAULT_RADIO_BUTTON_NORMAL_PATH_PREFIX,
    default_radio_button_size = \
            ScaffolderIcons.DEFAULT_RADIO_BUTTON_NORMAL_SIZE,
    radio_button_sizes = \
            ScaffolderIcons.DEFAULT_RADIO_BUTTON_NORMAL_SIZES,
    
    tree_arrow_path_prefix = \
            ScaffolderIcons.DEFAULT_TREE_ARROW_NORMAL_PATH_PREFIX,
    default_tree_arrow_size = \
            ScaffolderIcons.DEFAULT_TREE_ARROW_NORMAL_SIZE,
    tree_arrow_sizes = \
            ScaffolderIcons.DEFAULT_TREE_ARROW_NORMAL_SIZES,
    
    dropdown_arrow_path_prefix = \
            ScaffolderIcons.DEFAULT_DROPDOWN_ARROW_NORMAL_PATH_PREFIX,
    default_dropdown_arrow_size = \
            ScaffolderIcons.DEFAULT_DROPDOWN_ARROW_NORMAL_SIZE,
    dropdown_arrow_sizes = \
            ScaffolderIcons.DEFAULT_DROPDOWN_ARROW_NORMAL_SIZES,
    
    slider_grabber_path_prefix = \
            ScaffolderIcons.DEFAULT_SLIDER_GRABBER_NORMAL_PATH_PREFIX,
    default_slider_grabber_size = \
            ScaffolderIcons.DEFAULT_SLIDER_GRABBER_NORMAL_SIZE,
    slider_grabber_sizes = \
            ScaffolderIcons.DEFAULT_SLIDER_GRABBER_NORMAL_SIZES,
    
    slider_tick_path_prefix = \
            ScaffolderIcons.DEFAULT_SLIDER_TICK_NORMAL_PATH_PREFIX,
    default_slider_tick_size = \
            ScaffolderIcons.DEFAULT_SLIDER_TICK_NORMAL_SIZE,
    slider_tick_sizes = \
            ScaffolderIcons.DEFAULT_SLIDER_TICK_NORMAL_SIZES,
    
    go_normal = preload("res://assets/images/go_icon.png"),
    go_scale = 1.5,
    
    about_circle_active = \
            preload("res://addons/scaffolder/assets/images/gui/about_circle_active.png"),
    about_circle_hover = \
            preload("res://addons/scaffolder/assets/images/gui/about_circle_hover.png"),
    about_circle_normal = \
            preload("res://addons/scaffolder/assets/images/gui/about_circle_normal.png"),
    
    alert_normal = \
            preload("res://addons/scaffolder/assets/images/gui/alert_normal.png"),
    
    close_active = \
            preload("res://addons/scaffolder/assets/images/gui/close_active.png"),
    close_hover = \
            preload("res://addons/scaffolder/assets/images/gui/close_hover.png"),
    close_normal = \
            preload("res://addons/scaffolder/assets/images/gui/close_normal.png"),
    
    gear_circle_active = \
            preload("res://addons/scaffolder/assets/images/gui/gear_circle_active.png"),
    gear_circle_hover = \
            preload("res://addons/scaffolder/assets/images/gui/gear_circle_hover.png"),
    gear_circle_normal = \
            preload("res://addons/scaffolder/assets/images/gui/gear_circle_normal.png"),
    
    home_normal = \
            preload("res://addons/scaffolder/assets/images/gui/home_normal.png"),
    
    left_caret_active = \
            preload("res://addons/scaffolder/assets/images/gui/left_caret_active.png"),
    left_caret_hover = \
            preload("res://addons/scaffolder/assets/images/gui/left_caret_hover.png"),
    left_caret_normal = \
            preload("res://addons/scaffolder/assets/images/gui/left_caret_normal.png"),
    
    pause_circle_active = \
            preload("res://addons/scaffolder/assets/images/gui/pause_circle_active.png"),
    pause_circle_hover = \
            preload("res://addons/scaffolder/assets/images/gui/pause_circle_hover.png"),
    pause_circle_normal = \
            preload("res://addons/scaffolder/assets/images/gui/pause_circle_normal.png"),
    
    pause_normal = \
            preload("res://addons/scaffolder/assets/images/gui/pause_normal.png"),
    play_normal = \
            preload("res://addons/scaffolder/assets/images/gui/play_normal.png"),
    retry_normal = \
            preload("res://addons/scaffolder/assets/images/gui/retry_normal.png"),
    stop_normal = \
            preload("res://addons/scaffolder/assets/images/gui/stop_normal.png"),
}

var _default_icons_manifest_pixel := {
    checkbox_path_prefix = \
            ScaffolderIcons.DEFAULT_CHECKBOX_PIXEL_PATH_PREFIX,
    default_checkbox_size = \
            ScaffolderIcons.DEFAULT_CHECKBOX_PIXEL_SIZE,
    checkbox_sizes = \
            ScaffolderIcons.DEFAULT_CHECKBOX_PIXEL_SIZES,
    
    radio_button_path_prefix = \
            ScaffolderIcons.DEFAULT_RADIO_BUTTON_PIXEL_PATH_PREFIX,
    default_radio_button_size = \
            ScaffolderIcons.DEFAULT_RADIO_BUTTON_PIXEL_SIZE,
    radio_button_sizes = \
            ScaffolderIcons.DEFAULT_RADIO_BUTTON_PIXEL_SIZES,
    
    tree_arrow_path_prefix = \
            ScaffolderIcons.DEFAULT_TREE_ARROW_PIXEL_PATH_PREFIX,
    default_tree_arrow_size = \
            ScaffolderIcons.DEFAULT_TREE_ARROW_PIXEL_SIZE,
    tree_arrow_sizes = \
            ScaffolderIcons.DEFAULT_TREE_ARROW_PIXEL_SIZES,
    
    dropdown_arrow_path_prefix = \
            ScaffolderIcons.DEFAULT_DROPDOWN_ARROW_PIXEL_PATH_PREFIX,
    default_dropdown_arrow_size = \
            ScaffolderIcons.DEFAULT_DROPDOWN_ARROW_PIXEL_SIZE,
    dropdown_arrow_sizes = \
            ScaffolderIcons.DEFAULT_DROPDOWN_ARROW_PIXEL_SIZES,
    
    slider_grabber_path_prefix = \
            ScaffolderIcons.DEFAULT_SLIDER_GRABBER_PIXEL_PATH_PREFIX,
    default_slider_grabber_size = \
            ScaffolderIcons.DEFAULT_SLIDER_GRABBER_PIXEL_SIZE,
    slider_grabber_sizes = \
            ScaffolderIcons.DEFAULT_SLIDER_GRABBER_PIXEL_SIZES,
    
    slider_tick_path_prefix = \
            ScaffolderIcons.DEFAULT_SLIDER_TICK_PIXEL_PATH_PREFIX,
    default_slider_tick_size = \
            ScaffolderIcons.DEFAULT_SLIDER_TICK_PIXEL_SIZE,
    slider_tick_sizes = \
            ScaffolderIcons.DEFAULT_SLIDER_TICK_PIXEL_SIZES,
    
    go_normal = preload("res://assets/images/go_icon.png"),
    go_scale = 1.5,
    
    about_circle_active = \
            preload("res://addons/scaffolder/assets/images/gui/about_circle_active.png"),
    about_circle_hover = \
            preload("res://addons/scaffolder/assets/images/gui/about_circle_hover.png"),
    about_circle_normal = \
            preload("res://addons/scaffolder/assets/images/gui/about_circle_normal.png"),
    
    alert_normal = \
            preload("res://addons/scaffolder/assets/images/gui/alert_normal.png"),
    
    close_active = \
            preload("res://addons/scaffolder/assets/images/gui/close_active.png"),
    close_hover = \
            preload("res://addons/scaffolder/assets/images/gui/close_hover.png"),
    close_normal = \
            preload("res://addons/scaffolder/assets/images/gui/close_normal.png"),
    
    gear_circle_active = \
            preload("res://addons/scaffolder/assets/images/gui/gear_circle_active.png"),
    gear_circle_hover = \
            preload("res://addons/scaffolder/assets/images/gui/gear_circle_hover.png"),
    gear_circle_normal = \
            preload("res://addons/scaffolder/assets/images/gui/gear_circle_normal.png"),
    
    home_normal = \
            preload("res://addons/scaffolder/assets/images/gui/home_normal.png"),
    
    left_caret_active = \
            preload("res://addons/scaffolder/assets/images/gui/left_caret_active.png"),
    left_caret_hover = \
            preload("res://addons/scaffolder/assets/images/gui/left_caret_hover.png"),
    left_caret_normal = \
            preload("res://addons/scaffolder/assets/images/gui/left_caret_normal.png"),
    
    pause_circle_active = \
            preload("res://addons/scaffolder/assets/images/gui/pause_circle_active.png"),
    pause_circle_hover = \
            preload("res://addons/scaffolder/assets/images/gui/pause_circle_hover.png"),
    pause_circle_normal = \
            preload("res://addons/scaffolder/assets/images/gui/pause_circle_normal.png"),
    
    pause_normal = \
            preload("res://addons/scaffolder/assets/images/gui/pause_normal.png"),
    play_normal = \
            preload("res://addons/scaffolder/assets/images/gui/play_normal.png"),
    retry_normal = \
            preload("res://addons/scaffolder/assets/images/gui/retry_normal.png"),
    stop_normal = \
            preload("res://addons/scaffolder/assets/images/gui/stop_normal.png"),
}

var _default_settings_item_manifest := {
    groups = {
        main = {
            label = "",
            is_collapsible = false,
            item_classes = [
                MusicSettingsLabeledControlItem,
                SoundEffectsSettingsLabeledControlItem,
                HapticFeedbackSettingsLabeledControlItem,
            ],
        },
        annotations = {
            label = "Rendering",
            is_collapsible = true,
            item_classes = [
                RulerAnnotatorSettingsLabeledControlItem,
                PreselectionTrajectoryAnnotatorSettingsLabeledControlItem,
                ActiveTrajectoryAnnotatorSettingsLabeledControlItem,
                PreviousTrajectoryAnnotatorSettingsLabeledControlItem,
                NavigationDestinationAnnotatorSettingsLabeledControlItem,
                RecentMovementAnnotatorSettingsLabeledControlItem,
                SurfacesAnnotatorSettingsLabeledControlItem,
                PlayerPositionAnnotatorSettingsLabeledControlItem,
                PlayerAnnotatorSettingsLabeledControlItem,
                LevelAnnotatorSettingsLabeledControlItem,
            ],
        },
        hud = {
            label = "HUD",
            is_collapsible = true,
            item_classes = [
                InspectorEnabledSettingsLabeledControlItem,
                DebugPanelSettingsLabeledControlItem,
            ],
        },
        miscellaneous = {
            label = "Miscellaneous",
            is_collapsible = true,
            item_classes = [
                ButtonControlsSettingsLabeledControlItem,
                WelcomePanelSettingsLabeledControlItem,
                IntroChoreographySettingsLabeledControlItem,
                CameraZoomSettingsLabeledControlItem,
                TimeScaleSettingsLabeledControlItem,
                MetronomeSettingsLabeledControlItem,
                LogSurfacerEventsSettingsLabeledControlItem,
            ],
        },
    },
}

var _default_pause_item_manifest := [
    LevelLabeledControlItem,
    TimeLabeledControlItem,
]

var _default_game_over_item_manifest := [
    LevelLabeledControlItem,
    TimeLabeledControlItem,
]

var _default_level_select_item_manifest := [
    TotalPlaysLabeledControlItem,
]

var _default_hud_manifest := {
    hud_class = SurfacerHud,
    hud_key_value_box_size = \
            ScaffolderGuiConfig.HUD_KEY_VALUE_BOX_DEFAULT_SIZE,
    hud_key_value_box_scene = \
            preload("res://addons/scaffolder/src/gui/hud/hud_key_value_box.tscn"),
    hud_key_value_list_scene = \
            preload("res://addons/scaffolder/src/gui/hud/hud_key_value_list.tscn"),
    hud_key_value_list_item_manifest = [
        {
            item_class = TimeLabeledControlItem,
            settings_enablement_label = "Time",
            enabled_by_default = true,
            settings_group_key = "hud",
        },
    ],
    is_inspector_enabled_default = false,
    inspector_panel_starts_open = false,
}

var _default_welcome_panel_manifest := {
    items = [
        ["*Auto nav*", "click"],
        ["Walk/Climb", "arrow key / wasd"],
        ["Jump", "space / x"],
    ],
    header_color = [
    ],
    body_color = [
    ],
}

var _default_screen_manifest := {
    exclusions = [
        preload("res://addons/scaffolder/src/gui/screens/rate_app_screen.tscn"),
    ],
    inclusions = [
    ],
    overlay_mask_transition_fade_in_texture = \
            preload("res://addons/scaffolder/assets/images/transition_masks/radial_mask_transition_in.png"),
    overlay_mask_transition_fade_out_texture = \
            preload("res://addons/scaffolder/assets/images/transition_masks/radial_mask_transition_in.png"),
    screen_mask_transition_fade_texture = \
            preload("res://addons/scaffolder/assets/images/transition_masks/checkers_mask_transition.png"),
    overlay_mask_transition_class = OverlayMaskTransition,
    screen_mask_transition_class = ScreenMaskTransition,
    slide_transition_duration = 0.3,
    fade_transition_duration = 0.3,
    overlay_mask_transition_duration = 1.2,
    screen_mask_transition_duration = 1.2,
    slide_transition_easing = "ease_in_out",
    fade_transition_easing = "ease_in_out",
    overlay_mask_transition_fade_in_easing = "ease_out",
    overlay_mask_transition_fade_out_easing = "ease_in",
    screen_mask_transition_easing = "ease_in",
    default_transition_type = ScreenTransition.FADE,
    fancy_transition_type = ScreenTransition.SCREEN_MASK,
    overlay_mask_transition_color = Color("#111111"),
    overlay_mask_transition_uses_pixel_snap = false,
    overlay_mask_transition_smooth_size = 0.02,
    screen_mask_transition_uses_pixel_snap = true,
    screen_mask_transition_smooth_size = 0.0,
}

var _default_slow_motion_manifest := {
    time_scale = 0.5,
    tick_tock_tempo_multiplier = 1,
    saturation = 0.5,
}

var _default_input_map = ScaffolderProjectSettings.DEFAULT_INPUT_MAP

var _default_is_using_pixel_style := true

# ---


func _init(is_using_pixel_style: bool) -> void:
    self._default_is_using_pixel_style = is_using_pixel_style


func _ready() -> void:
    assert(is_instance_valid(Sc) and \
            is_instance_valid(Su),
            ("The Sc (Scaffolder) and Su (Surfacer) AutoLoads must be " +
            "declared first."))
    
    Sc.logger.on_global_init(self, "App")
    Sc.register_framework_config(self)


func _amend_app_manifest(manifest: Dictionary) -> void:
    _override_configs_for_is_using_pixel_style(manifest)
    _override_configs_for_current_run(manifest)


func _override_configs_for_is_using_pixel_style(manifest: Dictionary) -> void:
    if _default_is_using_pixel_style:
        manifest.fonts_manifest = _default_fonts_manifest_pixel
        manifest.styles_manifest = _default_styles_manifest_pixel
        manifest.icons_manifest = _default_icons_manifest_pixel
    else:
        manifest.fonts_manifest = _default_fonts_manifest_normal
        manifest.styles_manifest = _default_styles_manifest_normal
        manifest.icons_manifest = _default_icons_manifest_normal
