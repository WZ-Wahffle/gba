#import "Window_Creation";
#import "Simp";
#import "Thread";
#import "Basic";
#import "Input";
#import "Gamepad";

SCREEN_WIDTH :: 240;
SCREEN_HEIGHT :: 160;
window_width := SCREEN_WIDTH * 4;
window_height := SCREEN_HEIGHT * 4;

ui :: (t: *Thread) -> s64 {
    win := create_window(window_width, window_height, "gba");
    set_render_target(win);
    framebuffer: Bitmap;
    bitmap_alloc(*framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, .RGBA8);
    defer deinit(*framebuffer);
    texture: Texture;
    defer texture_destroy(*texture);
    quit := false;
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
        swap_buffers(win);
    }
    return 0;
}
