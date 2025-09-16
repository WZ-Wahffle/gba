theme_catppuccin :: () -> Overall_Theme {
    result: Overall_Theme;

    result.background_color = .{0.07, 0.07, 0.11, 1.0}; // crust
    result.background_color_bright = .{0.09, 0.09, 0.15, 1.0}; // mantle
    result.text_color = .{0.80, 0.84, 0.96, 1.0}; // text
    result.title_bar_color = .{0.19, 0.20, 0.27, 1.0}; // surface 0
    result.title_bar_color_hilit = .{0.27, 0.28, 0.35, 1.0}; // surface 1
    {
        using result.button_theme;
        rectangle_shape.roundedness_type = .RELATIVE_TO_HEIGHT;
        rectangle_shape.roundedness = 0.05;
        rectangle_shape.frame_thickness_type = .RELATIVE_TO_HEIGHT;
        rectangle_shape.frame_thickness = 0.02;
        surface_color = .{0.09, 0.09, 0.15, 1.0}; // mantle
        surface_color_over = .{0.12, 0.12, 0.18, 1.0}; // base
        surface_color_down = .{0.15, 0.15, 0.21, 1.0}; // base + 1
        surface_color_flash = .{0.58, 0.89, 0.84, 1.0}; // teal

        frame_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        frame_color_over = .{0.54, 0.86, 0.92, 1.0}; // sky
        frame_color_down = .{0.58, 0.60, 0.70, 1.0}; // overlay 2
        frame_color_flash = .{0.54, 0.86, 0.92, 1.0}; // sky

        text_color = .{0.80, 0.84, 0.96, 1.0}; // text
        text_color_over = .{0.80, 0.84, 0.96, 1.0}; // text
        text_color_pressed = .{0.80, 0.84, 0.96, 1.0}; // text
    }
    {
        using result.checkbox_theme;
        surface_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        surface_color_over = .{0.98, 0.70, 0.53, 1.0}; // peach
        surface_color_down = .{0.58, 0.60, 0.70, 1.0}; // overlay 2
        surface_color_flash = .{0.98, 0.70, 0.53, 1.0}; // peach

        frame_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        frame_color_over = .{0.50, 0.52, 0.61, 1.0}; // overlay 1
        frame_color_down = .{0.58, 0.60, 0.70, 1.0}; // overlay 2
        frame_color_flash = .{0.98, 0.89, 0.69, 1.0}; // yellow

        text_color = .{0.80, 0.84, 0.96, 1.0}; // text
        text_color_over = .{0.98, 0.70, 0.53, 1.0}; // peach
        text_color_pressed = .{0.98, 0.89, 0.69, 1.0}; // yellow

        text_color_selected = .{0.98, 0.89, 0.69, 1.0}; // yellow
        button_color_selected = .{0.98, 0.89, 0.69, 1.0}; // yellow
    }
    {
        using result.label_theme;
        text_color = .{0.80, 0.84, 0.96, 1.0}; // text
    }
    {
        using result.text_input_theme;

        surface_color = .{0.09, 0.09, 0.15, 1.0}; // mantle
        surface_color_over = .{0.12, 0.12, 0.18, 1.0}; // base
        surface_color_down = .{0.15, 0.15, 0.21, 1.0}; // base + 1
        surface_color_flash = .{0.95, 0.55, 0.66, 1.0}; // red

        frame_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        frame_color_over = .{0.50, 0.52, 0.61, 1.0}; // overlay 1
        frame_color_down = .{0.58, 0.60, 0.70, 1.0}; // overlay 2
        frame_color_flash = .{0.92, 0.63, 0.67, 1.0}; // maroon

        text_color = .{0.80, 0.84, 0.96, 1.0}; // text
        text_color_over = .{0.80, 0.84, 0.96, 1.0}; // text
        text_color_pressed = .{0.80, 0.84, 0.96, 1.0}; // text

        text_color_autocomplete = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        text_color_autocomplete_failed = .{0.92, 0.63, 0.67, 1.0}; // maroon

        selection_color = .{0.95, 0.55, 0.66, 1.0}; // red
        cursor_color = .{0.27, 0.28, 0.35, 1.0}; // surface 1
    }
    {
        using result.color_picker_theme;
        background.color = .{0.09, 0.09, 0.15, 1.0}; // mantle
        background.frame_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        background.shape.roundedness_type = .ABSOLUTE_FROM_THEME_FIELD;
        background.shape.roundedness = 0.05;
        background.shape.frame_thickness_type = .ABSOLUTE_FROM_THEME_FIELD;
        background.shape.frame_thickness = 0.02;
        apply_and_revert_button_theme = result.button_theme;
        stash_button_theme = result.button_theme;
        mode_switch_button_theme = result.button_theme;
        type_ins_label_theme = result.label_theme;

        type_ins_input_theme.surface_color = result.text_input_theme.surface_color;
        type_ins_input_theme.surface_color_over = result.text_input_theme.surface_color_over;
        type_ins_input_theme.surface_color_down = result.text_input_theme.surface_color_down;
        type_ins_input_theme.surface_color_flash = result.text_input_theme.surface_color_flash;

        type_ins_input_theme.frame_color = result.text_input_theme.frame_color;
        type_ins_input_theme.frame_color_over = result.text_input_theme.frame_color_over;
        type_ins_input_theme.frame_color_down = result.text_input_theme.frame_color_down;
        type_ins_input_theme.frame_color_flash = result.text_input_theme.frame_color_flash;

        type_ins_input_theme.text_color = result.text_input_theme.text_color;
        type_ins_input_theme.text_color_over = result.text_input_theme.text_color_over;
        type_ins_input_theme.text_color_pressed = result.text_input_theme.text_color_pressed;

        type_ins_input_theme.text_color_autocomplete = result.text_input_theme.text_color_autocomplete;
        type_ins_input_theme.text_color_autocomplete_failed = result.text_input_theme.text_color_autocomplete_failed;

        type_ins_input_theme.selection_color = result.text_input_theme.selection_color;
        type_ins_input_theme.cursor_color = result.text_input_theme.cursor_color;
    }
    {
        using result.dropdown_theme;
        theme_for_current_value = result.button_theme;
        theme_for_current_value.surface_color_flash = .{0.65, 0.89, 0.63, 1.0}; // green
        theme_for_current_value.frame_color_over = .{0.53, 0.76, 0.57, 1.0}; // custom lime
        theme_for_current_value.frame_color_flash = .{0.53, 0.76, 0.57, 1.0}; // custom lime
        theme_for_each_choice = theme_for_current_value;
        theme_for_current_choice = theme_for_current_value;
        theme_for_current_choice.frame_color = .{0.53, 0.76, 0.57, 1}; // custom lime
        theme_for_current_choice.text_color = .{0.53, 0.76, 0.57, 1}; // custom lime
        theme_for_current_choice.text_color_over = .{0.53, 0.76, 0.57, 1}; // custom lime
    }
    {
        using result.scrollable_region_theme;
        scrollbar_nib_theme = result.button_theme;
        scrollbar_nib_theme.frame_color_flash = .{0.71, 0.75, 1.00, 1.0}; // lavender
        scrollbar_nib_theme.frame_color_over = .{0.71, 0.75, 1.00, 1.0}; // lavender
        scrollbar_nib_theme.surface_color = scrollbar_nib_theme.frame_color;
        scrollbar_nib_theme.surface_color_flash = scrollbar_nib_theme.frame_color_flash;
        scrollbar_nib_theme.surface_color_over = scrollbar_nib_theme.frame_color_over;
        scrollbar_nib_theme.surface_color_down = scrollbar_nib_theme.frame_color_down;
        region_background.color = .{0.09, 0.09, 0.15, 1.0}; // mantle
        region_background.frame_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        scrollbar_background.color = .{0.09, 0.09, 0.15, 1.0}; // mantle
        scrollbar_background.frame_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        region_background.shape.roundedness_type = .ABSOLUTE_FROM_THEME_FIELD;
        region_background.shape.roundedness = 0.05;
        region_background.shape.frame_thickness_type = .ABSOLUTE_FROM_THEME_FIELD;
        region_background.shape.frame_thickness = 0.02;
        scrollbar_background.shape.roundedness_type = .ABSOLUTE_FROM_THEME_FIELD;
        scrollbar_background.shape.roundedness = 0.05;
        scrollbar_background.shape.frame_thickness_type = .ABSOLUTE_FROM_THEME_FIELD;
        scrollbar_background.shape.frame_thickness = 0.02;
        scrollbar_nib_theme.rectangle_shape.roundedness_type = .ABSOLUTE_FROM_THEME_FIELD;
        scrollbar_nib_theme.rectangle_shape.roundedness = 0.05;
        scrollbar_nib_theme.rectangle_shape.frame_thickness_type = .ABSOLUTE_FROM_THEME_FIELD;
        scrollbar_nib_theme.rectangle_shape.frame_thickness = 0.02;
    }
    {
        using result.slidable_region_theme;
        divider_theme = result.button_theme;
        first_background.color = .{0.09, 0.09, 0.15, 1.0}; // mantle
        first_background.frame_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        second_background.color = .{0.09, 0.09, 0.15, 1.0}; // mantle
        second_background.frame_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
    }
    {
        using result.slider_theme;
        foreground = result.button_theme;
        background = result.button_theme;
        spinbox_theme = result.button_theme;
    }
    {
        using result.subwindow_theme;
        title_bar = result.button_theme;
        close_button = result.button_theme;
        region_background.color = .{0.09, 0.09, 0.15, 1.0}; // mantle
        region_background.frame_color = .{0.42, 0.44, 0.53, 1.0}; // overlay 0
        region_background.shape.roundedness_type = .ABSOLUTE_FROM_THEME_FIELD;
        region_background.shape.roundedness = 0.05;
        region_background.shape.frame_thickness_type = .ABSOLUTE_FROM_THEME_FIELD;
        region_background.shape.frame_thickness = 0.02;
    }

    return result;
}
