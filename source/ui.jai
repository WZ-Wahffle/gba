#import "Window_Creation";
#import "Simp";
#import "Thread";
#import "Basic";
#import "Input";
#import "Gamepad";
#import "GetRect_LeftHanded";

SCREEN_WIDTH :: 240;
SCREEN_HEIGHT :: 160;
FONT_HEIGHT :: 28;
window_width := SCREEN_WIDTH * 4;
window_height := SCREEN_HEIGHT * 4;
font: *Dynamic_Font;

subwindow_cpu: Subwindow_Info;

ui :: (t: *Thread) -> s64 {
    win := create_window(window_width, window_height, "gba");
    set_render_target(win, .LEFT_HANDED);
    framebuffer: Bitmap;
    bitmap_alloc(*framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, .RGBA8);
    defer deinit(*framebuffer);
    texture: Texture;
    defer texture_destroy(*texture);
    quit := false;
    subwindows_initted := false;
    font = get_font_at_size("/usr/share/fonts/TTF", "JetBrainsMono-Regular.ttf", FONT_HEIGHT);
    assert(font != null);
    ui_init();

    while !quit {
        update_window_events();
        for get_window_resizes() {
            update_window(win);
            if it.window == win {
                window_width = it.width;
                window_height = it.height;
            }
        }
        for events_this_frame {
            if it.type == .QUIT then quit = true;
            if it.type == {
                case .KEYBOARD;
                if it.key_pressed && it.key_code == .ESCAPE {
                    quit = true;
                }
            }
        }
        clear_render_target(0., 0., 0., 1.);
        texture_load_from_bitmap(*texture, *framebuffer);
        immediate_begin();
        set_shader_for_images(*texture);
        immediate_quad(0., 0., xx window_width, xx window_height, .{1, 1, 1, 1});
        immediate_flush();

        set_default_theme(theme_catppuccin());

        ui_per_frame_update(win, xx window_width, xx window_height, seconds_since_init());
        if !subwindows_initted {
            subwindow_cpu.rect = get_rect(10, 10, xx window_width / 2., xx window_height / 2.);
            subwindow_cpu.title_text = "cpu";
            subwindow_cpu.draw = cpu_window;
            subwindow_cpu.open = true;
            subwindows_initted = true;
        }

        add_subwindow(*subwindow_cpu);
        draw_popups();

        swap_buffers(win);
    }
    return 0;
}

cpu_window_scroll := 0.;
#scope_file
cpu_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    label_theme: Label_Theme;
    label_theme.alignment = .Left;
    label_theme.font = font;
    label_theme.text_color = .{1., 0.95, 0.8, 1.};
    cursor := r;
    cursor.h = FONT_HEIGHT;
    cursor.y += 10;
    context.print_style.default_format_int.base = 16;
    context.print_style.default_format_int.minimum_digits = 8;
    defer context.print_style.default_format_int.base = 10;
    defer context.print_style.default_format_int.minimum_digits = 1;

    region, inside := begin_scrollable_region(r);
    cursor.y -= cpu_window_scroll;
    label(cursor, tprint("PC: 0x%", cpu.pc), *label_theme);
    cursor.y += FONT_HEIGHT;
    label(cursor, tprint("LR: 0x%", cpu.lr), *label_theme);
    cursor.y += FONT_HEIGHT;
    label(cursor, tprint("SP: 0x%", cpu.sp), *label_theme);
    cursor.y += FONT_HEIGHT;
    end_scrollable_region(region, r.w, cursor.y, *cpu_window_scroll);
}
