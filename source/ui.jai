#import "Window_Creation";
#import "Simp";
#import "Thread";
#import "Basic";
#import "Input";
#import "Gamepad";
#import "GetRect_LeftHanded";

SCREEN_WIDTH :: 240;
SCREEN_HEIGHT :: 160;
FONT_HEIGHT :: 24;
window_width := SCREEN_WIDTH * 4;
window_height := SCREEN_HEIGHT * 4;
font: *Dynamic_Font;

subwindow_cpu: Subwindow_Info;

step_ppu :: () {
    ppu.draw_x += 1;
    if ppu.draw_x == 308 {
        ppu.draw_x = 0;
        ppu.draw_y += 1;
        if ppu.draw_y == 228 {
            ppu.draw_y = 0;
        }
    }
}

ui :: () {
    win := create_window(window_width, window_height, "gba");
    set_render_target(win, .LEFT_HANDED);
    framebuffer: Bitmap;
    bitmap_alloc(*framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, .RGBA8);
    defer deinit(*framebuffer);
    texture: Texture;
    defer texture_destroy(*texture);
    quit := false;
    subwindows_initted := false;
    font = get_font_at_size("/usr/share/fonts/TTF", "JetBrainsMono-Thin.ttf", FONT_HEIGHT);
    assert(font != null);
    ui_init();
    set_default_theme(theme_catppuccin());
    time := seconds_since_init();
    dt : float64;
    while !quit {
        new_time := seconds_since_init();
        dt = new_time - time;
        time = new_time;
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

        // processing
        if cpu.emu_state == {
            case .RUNNING;
            for 0..228*308 {
                step_ppu();
                cpu.remaining_cycles += 4;
                while cpu.remaining_cycles > 0 step_cpu();
            }
            case .STOPPED;
            // this page intentionally left blank
        }

        // render
        clear_render_target(0., 0., 0., 1.);
        texture_load_from_bitmap(*texture, *framebuffer);
        immediate_begin();
        set_shader_for_images(*texture);
        immediate_quad(0., 0., xx window_width, xx window_height, .{1, 1, 1, 1});
        immediate_flush();

        // GUI
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
}

cpu_window_scroll := 0.;
#scope_file
cpu_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    label_theme: Label_Theme;
    label_theme.alignment = .Left;
    label_theme.font = font;
    cursor := r;
    cursor.h = FONT_HEIGHT;
    cursor.y += 10;
    context.print_style.default_format_int.base = 16;
    context.print_style.default_format_int.minimum_digits = 8;
    defer context.print_style.default_format_int.base = 10;
    defer context.print_style.default_format_int.minimum_digits = 1;

    imm_button :: (cursor: *Rect, text: string, in_line: bool) -> (was_just_pressed: bool, state: *Button_State, was_just_released: bool) {
        cursor.*.w = xx prepare_text(font, text);
        ret1, ret2, ret3 := button(cursor.*, text, identifier=xx (cursor.*.x * cursor.*.y));
        if in_line {
            cursor.*.x += cursor.*.w + 5;
        } else {
            cursor.*.x = 0;
            cursor.*.y += cursor.*.h + 5;
        }
        return ret1, ret2, ret3;
    }

    imm_label :: (cursor: *Rect, text: string, theme: *Label_Theme, in_line: bool) {
        cursor.*.w = xx prepare_text(font, text);
        label(cursor.*, text, theme);
        if in_line {
            cursor.*.x += cursor.*.w + 5;
        } else {
            cursor.*.x = 0;
            cursor.*.y += cursor.*.h + 5;
        }
    }

    region, inside := begin_scrollable_region(r);
    cursor.y -= cpu_window_scroll;
    cursor.x = 10;
    if imm_button(*cursor, "Start", true) {
        cpu.emu_state = .RUNNING;
    }
    if imm_button(*cursor, "Stop", true) {
        cpu.emu_state = .STOPPED;
    }
    if imm_button(*cursor, "Step", false) {
        cpu.emu_state = .STOPPED;
        cpu.remaining_cycles = 1;
        step_cpu();
    }
    imm_label(*cursor, tprint("PC : 0x%", formatInt(cpu.pc, 16, 8)), *label_theme, false);
    imm_label(*cursor, tprint("LR : 0x%", formatInt(cpu.lr, 16, 8)), *label_theme, false);
    imm_label(*cursor, tprint("SP : 0x%", formatInt(cpu.sp, 16, 8)), *label_theme, false);
    imm_label(*cursor, tprint("PSR: 0x%", formatInt(cpu.psr, 16, 8)), *label_theme, false);
    imm_label(*cursor, "", *label_theme, false);
    imm_label(*cursor, tprint("R00: 0x% ", formatInt(cpu.gpr[0], 16, 8)), *label_theme, true);
    imm_label(*cursor, tprint("R01: 0x%", formatInt(cpu.gpr[1], 16, 8)), *label_theme, false);
    imm_label(*cursor, tprint("R02: 0x% ", formatInt(cpu.gpr[2], 16, 8)), *label_theme, true);
    imm_label(*cursor, tprint("R03: 0x%", formatInt(cpu.gpr[3], 16, 8)), *label_theme, false);
    imm_label(*cursor, tprint("R04: 0x% ", formatInt(cpu.gpr[4], 16, 8)), *label_theme, true);
    imm_label(*cursor, tprint("R05: 0x%", formatInt(cpu.gpr[5], 16, 8)), *label_theme, false);
    imm_label(*cursor, tprint("R06: 0x% ", formatInt(cpu.gpr[6], 16, 8)), *label_theme, true);
    imm_label(*cursor, tprint("R07: 0x%", formatInt(cpu.gpr[7], 16, 8)), *label_theme, false);
    imm_label(*cursor, tprint("R08: 0x% ", formatInt(cpu.gpr[8], 16, 8)), *label_theme, true);
    imm_label(*cursor, tprint("R09: 0x%", formatInt(cpu.gpr[9], 16, 8)), *label_theme, false);
    imm_label(*cursor, tprint("R10: 0x% ", formatInt(cpu.gpr[10], 16, 8)), *label_theme, true);
    imm_label(*cursor, tprint("R11: 0x%", formatInt(cpu.gpr[11], 16, 8)), *label_theme, false);
    imm_label(*cursor, tprint("R12: 0x% ", formatInt(cpu.gpr[12], 16, 8)), *label_theme, true);
    end_scrollable_region(region, r.w, cursor.y + cursor.h, *cpu_window_scroll);
}
