SCREEN_WIDTH :: 240;
SCREEN_HEIGHT :: 160;
FONT_SIZE :: 26;
window_width : s32 = SCREEN_WIDTH * 6;
window_height : s32 = SCREEN_HEIGHT * 6;
framebuffer: [SCREEN_WIDTH * SCREEN_HEIGHT]u16;
line_priority_buffer: [SCREEN_WIDTH]u8;
obj_line_buffer: [SCREEN_WIDTH]u16;
obj_prio_buffer: [SCREEN_WIDTH]u8;
obj_win_buffer: [SCREEN_WIDTH]bool;

// priorities: (the lower, the higher)
// backdrop: 8
// OBJ: priority * 2 + 1
// BGx: x * 2

draw_bg :: (y: u32, bg: u32, rotation_mode: bool) {
    if !ppu.bg[bg].enable then return;
    if rotation_mode {
        line_size_px := 128 * (ifx ppu.bg[bg].wide then 2 else 1) * (ifx ppu.bg[bg].tall then 4 else 1);
        y_pos : int = xx (y + ppu.bg[bg].anchor_y);
        while y_pos < 0 {
            y_pos += line_size_px;
        }
        line_size_tiles := line_size_px / 8;
        base_addr := ppu.bg[bg].screen_base_block * 2048;
        base_addr += (y_pos / 8) * (line_size_tiles);
        tile_address_buffer: [128]u16;
        for 0..line_size_tiles-1 {
            tile_address_buffer[it] = ppu.memory.vram._8[base_addr + it];
        }
        pixel_buffer: [1024]u16;
        for tile_idx: 0..line_size_tiles-1 {
            tile_base_addr := ppu.bg[bg].char_base_block * 16384 + tile_address_buffer[tile_idx] * 64;
            tile_base_addr += 8 * (y_pos % 8);
            for pixel_idx: 0..7 {
                pixel_buffer[8 * tile_idx + pixel_idx] = ppu.memory.palette_ram._16[ppu.memory.vram._8[tile_base_addr + pixel_idx]];
            }
        }

        win_1_in_y := ppu.win[0].min_y <= y && ppu.win[0].max_y >= y;
        win_2_in_y := ppu.win[1].min_y <= y && ppu.win[1].max_y >= y;
        for 0..239 {
            if bg * 2 >= line_priority_buffer[it] continue;
            win_1_in := win_1_in_y && ppu.win[0].min_x <= it && ppu.win[0].max_x >= it;
            win_2_in := win_2_in_y && ppu.win[1].min_x <= it && ppu.win[1].max_x >= it;

            if ppu.win[0].enable {
                if win_1_in && !ppu.win[0].bg_enable[bg] {
                    continue;
                }
            }
            if ppu.win[1].enable {
                if win_2_in && !ppu.win[1].bg_enable[bg] {
                    continue;
                }
            }
            if !win_1_in && !win_2_in && !ppu.outside_win_bg_enable[bg] {
                continue;
            }
            if ppu.obj_win.enable {
                if obj_win_buffer[it] && !ppu.obj_win.bg_enable[bg] {
                    continue;
                }
            }

            x_pos : int = xx (it + ppu.bg[bg].anchor_x);
            while x_pos < 0 {
                x_pos += line_size_px;
            }
            framebuffer[y * SCREEN_WIDTH + it] = pixel_buffer[x_pos];
            line_priority_buffer[it] = xx (ppu.bg[bg].prio * 2);
        }
    } else {
        // TODO
        assert(false);
    }
}

draw_obj :: (y: u32) {
    if ppu.obj_enable {
        pixel_buffer: [240]u16;
        base_addr := 0x10000;
        packed := ppu.obj_character_vram_mapping_one_dimensional;
        for ppu.oam {
            if it.bounding_box_min_y <= y && it.bounding_box_max_y > y {
                if it.rotate_scale {
                    if it.single_palette {
                        a := 1.0 / ppu.oam_param[it.rotate_scale_param_idx].pa;
                        b := -ppu.oam_param[it.rotate_scale_param_idx].pb;
                        c := -ppu.oam_param[it.rotate_scale_param_idx].pc;
                        d := 1.0 / ppu.oam_param[it.rotate_scale_param_idx].pd;
                        if isinf(a) then a = 0;
                        if isinf(b) then b = 0;
                        if isinf(c) then c = 0;
                        if isinf(d) then d = 0;
                        if a == 0 && b == 0 && c == 0 && d == 0 then continue;
                        w := it.max_x - it.min_x;
                        h := it.max_y - it.min_y;
                        x_0 := (it.min_x + it.max_x) / 2;
                        y_0 := (it.min_y + it.max_y) / 2;
                        y_2 : int = y;
                        if it.rotate_scale_double_size {
                            y_2 -= xx (h / 2);
                        }
                        obj_base := base_addr + it.tile_idx * 32;
                        for x: 0..239 {
                            x_2 := x;
                            if it.rotate_scale_double_size {
                                x_2 -= xx (w / 2);
                            }
                            x_1: int;
                            y_1: int;
                            if a == 0 && b == 0 {
                                x_1 = x_2;
                                y_1 = xx (((y_2 + c * x_0 + d * y_0 - y_0 - c * x_1) / d) + 0.5);
                                x_1 = x_0;
                                assert(false); // maybe find something other than the awful workaround below
                            } else if c == 0 && d == 0 {
                                y_1 = y_2 - 2;
                                x_1 = xx (((x_2 + a * x_0 + b * y_0 - x_0 - b * y_1) / a) + 0.5);
                                y_1 = y_0;
                            } else {
                                x_1 = xx (((d * (x_2 + a * x_0 + b * y_0 - x_0) - b * (y_2 + c * x_0 + d * y_0 - y_0)) / (a * d - b * c)) + 0.5);
                                y_1 = xx (((y_2 + c * x_0 + d * y_0 - y_0 - c * x_1) / d) + 0.5);
                            }
                            if x_1 < it.min_x || x_1 >= it.max_x || y_1 < it.min_y || y_1 >= it.max_y then continue;
                            if x < it.bounding_box_min_x || x >= it.bounding_box_max_x || y < it.bounding_box_min_y || y >= it.bounding_box_max_y then continue;
                            tile_line_base := obj_base + ((y_1 - it.min_y) / 8) * ifx packed then (32 * (w / 8)) else (32 * 32);
                            tile_base := tile_line_base + ((x_1 - it.min_x) / 8) * 64;
                            line_base := tile_base + ((y_1 - it.min_y) % 8) * 8;
                            color_idx := ppu.memory.vram._8[line_base + ((x_1 - it.min_x) % 8)];
                            pixel_buffer[x] = ppu.memory.palette_ram._16[0x100 + color_idx];
                        }
                        objwin := it.mode == 0b10;
                        for x_dst: 0..239 {
                            if pixel_buffer[x_dst] != 0 {
                                if objwin {
                                    obj_win_buffer[x_dst] = true;
                                } else {
                                    if obj_prio_buffer[x_dst] > it.prio * 2 + 1 {
                                        obj_prio_buffer[x_dst] = xx (it.prio * 2 + 1);
                                        obj_line_buffer[x_dst] = pixel_buffer[x_dst];
                                    }
                                }
                            }
                        }
                    } else {
                        // TODO
                    }
                } else {
                    if it.rotate_scale_double_size then continue;
                    obj_base := base_addr + it.tile_idx * 32;
                    if it.single_palette {
                        w := it.max_x - it.min_x;
                        // single palette, so tiles are 64 bytes each
                        // thus, a single line sliver of a tile is 8 bytes, or one u64
                        y_obj := y - it.min_y;
                        obj_base += (y_obj / 8) * ifx packed then (32 * (w / 8)) else (32 * 32);
                        vertical_offset_into_tile := (y_obj % 8);
                        x := it.min_x;
                        prio := it.prio;
                        objwin := it.mode == 0b10;
                        for coarse_x: 0..(w / 8)-1 { // 8 pixels equates to 16 bytes of info
                            pixel_line : u64 = ppu.memory.vram._64[(obj_base >> 3) + vertical_offset_into_tile];
                            for finer_x: 0..7 {
                                if ((pixel_line >> (8 * xx finer_x)) & 0xff) != 0 {
                                    if objwin {
                                        obj_win_buffer[x + coarse_x * 8 + finer_x] = true;
                                    } else {
                                        if obj_prio_buffer[x + coarse_x * 8 + finer_x] > prio * 2 + 1 {
                                            obj_line_buffer[x + coarse_x * 8 + finer_x] = ppu.memory.palette_ram._16[0x100 + ((pixel_line >> (8 * xx finer_x)) & 0xff)];
                                            obj_prio_buffer[x + coarse_x * 8 + finer_x] = xx (prio * 2 + 1);
                                        }
                                    }
                                }
                            }
                            obj_base += 64;
                        }
                    } else {
                        // TODO
                    }
                }
            }
        }
    }
}

step_ppu :: () {
    if ppu.remaining_cycles > 0 {
        ppu.remaining_cycles -= 4;
        ppu.draw_x += 1;
        // 240 visible + 68 hblank
        if ppu.draw_x == 308 {
            ppu.draw_x = 0;
            ppu.draw_y += 1;
            // 160 visible + 68 vblank
            if ppu.draw_y == 228 {
                ppu.draw_y = 0;
            }
        }

        if !get_status_bit(.I) && cpu.interrupt_master_enable {
            if ppu.draw_x == 240 && ppu.draw_y < 160 && cpu.ie[Interrupt_Source.LCD_HBLANK] != 0 {
                cpu.ifl[Interrupt_Source.LCD_HBLANK] = 0x02;
                interrupt(.IRQ);
            }
            if ppu.draw_x == 240 && ppu.draw_y == 160 && cpu.ie[Interrupt_Source.LCD_VBLANK] != 0 {
                cpu.ifl[Interrupt_Source.LCD_VBLANK] = 0x01;
                interrupt(.IRQ);
            }
        }

        if ppu.draw_x == 0 {
            cpu.ifl[Interrupt_Source.LCD_HBLANK] = 0;
        }

        if ppu.draw_y == 0 {
            cpu.ifl[Interrupt_Source.LCD_VBLANK] = 0;
        }

        if ppu.draw_x == 240 && ppu.draw_y < 160 {
            for 0..SCREEN_WIDTH-1 {
                line_priority_buffer[it] = 8;
                obj_line_buffer[it] = 0;
                obj_prio_buffer[it] = 8;
                obj_win_buffer[it] = false;
                // black and grey checkerboard to more easily gauge pixel distances
                // framebuffer[ppu.draw_y * SCREEN_WIDTH + it] = xx ((((it + ppu.draw_y) & 1)) * 0x421);
                framebuffer[ppu.draw_y * SCREEN_WIDTH + it] = ppu.memory.palette_ram._16[0];
            }

            if ppu.bg_mode == {
                case 0;
                case 1;
                case 2;
                    draw_obj(ppu.draw_y);
                    win_1_in_y := ppu.win[0].min_y <= ppu.draw_y && ppu.win[0].max_y >= ppu.draw_y;
                    win_2_in_y := ppu.win[1].min_y <= ppu.draw_y && ppu.win[1].max_y >= ppu.draw_y;
                    for x: 0..239 {
                        if obj_prio_buffer[x] >= line_priority_buffer[x] continue;
                        win_1_in := win_1_in_y && ppu.win[0].min_x <= x && ppu.win[0].max_x >= x;
                        win_2_in := win_2_in_y && ppu.win[1].min_x <= x && ppu.win[1].max_x >= x;
                        if ppu.win[0].enable && win_1_in && !ppu.win[0].obj_enable {
                            continue;
                        }
                        if ppu.win[1].enable && win_2_in && !ppu.win[1].obj_enable {
                            continue;
                        }
                        // TODO probably not right? I'm guessing it should be checking every
                        // window/inside combination individually
                        if (ppu.win[0].enable || ppu.win[1].enable || ppu.obj_win.enable) && !win_1_in && !win_2_in && !obj_win_buffer[x] && !ppu.outside_win_obj_enable {
                            continue;
                        }
                        if ppu.obj_win.enable && obj_win_buffer[x] && !ppu.obj_win.obj_enable {
                            continue;
                        }
                        if obj_line_buffer[x] != 0 {
                            framebuffer[ppu.draw_y * SCREEN_WIDTH + x] = obj_line_buffer[x];
                            line_priority_buffer[x] = obj_prio_buffer[x];
                        }
                    }
                    draw_bg(ppu.draw_y, 2, true);
                    draw_bg(ppu.draw_y, 3, true);
                case 3;
                case 4;
                case 5;
            }
        }
    }
}

font :: #run read_entire_file("in/ProggyClean.ttf");
controller: *SDL_GameController;
dt : float64;

ui :: () {
    quit := false;
    SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER);
    win := SDL_CreateWindow("gba", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, window_width, window_height, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    gl_context := SDL_GL_CreateContext(win);
    gl_load(*gl, SDL_GL_GetProcAddress);
    renderer := SDL_CreateRenderer(win, -1, .ACCELERATED | .TARGETTEXTURE);
    ImGui.CreateContext();
    ImGui_ImplSdl_Init(win);
    ImGui.StyleColorsDark();
    ImGui.GetIO().Fonts.AddFontFromMemoryTTF(ImGui.GetIO().Fonts, font.data, font.count, FONT_SIZE);

    time := seconds_since_init();
    while !quit {
        new_time := seconds_since_init();
        dt = new_time - time;
        time = new_time;
        event: SDL_Event;
        while SDL_PollEvent(*event) {
            ImGui_ImplSdl_ProcessEvent(*event);
            if event.type == SDL_QUIT quit = true;
            if event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(win) {
                quit = true;
            }
            if event.type == SDL_KEYDOWN {
                if event.key.keysym.sym == {
                    case .SDLK_F9;
                        cpu.emu_state = .STOPPED;
                    case .SDLK_F10;
                        cpu.emu_state = .STARTED;
                    case .SDLK_F11;
                        cpu.emu_state = .STEPPED;
                }
            }
            if event.type == SDL_KEYDOWN && event.key.repeat == 0 && (event.key.keysym.mod & .KMOD_SHIFT) != 0 {
                if event.key.keysym.sym == {
                    case .SDLK_ESCAPE;
                        quit = true;
                    case .SDLK_TAB;
                        show_header = !show_header;
                    case .SDLK_c;
                        show_cpu = !show_cpu;
                    case .SDLK_d;
                        show_disasm = !show_disasm;
                    case .SDLK_e;
                        show_ewram = !show_ewram;
                    case .SDLK_g;
                        show_ppu = !show_ppu;
                    case .SDLK_i;
                        show_iwram = !show_iwram;
                    case .SDLK_o;
                        show_oam = !show_oam;
                    case .SDLK_p;
                        show_palette_ram = !show_palette_ram;
                    case .SDLK_r;
                        show_rom = !show_rom;
                    case .SDLK_t;
                        show_dma = !show_dma;
                    case .SDLK_v;
                        show_vram = !show_vram;
                    case .SDLK_w;
                        show_window = !show_window;
                }
            }
            if event.type == SDL_CONTROLLERDEVICEADDED {
                if controller == null
                    controller = SDL_GameControllerOpen(event.cdevice.which);
            }
            if event.type == SDL_CONTROLLERDEVICEREMOVED {
                if controller
                    SDL_GameControllerClose(controller);
            }
        }

        // inputs
        ppu.keypad_state =
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_A) << 0) |
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_B) << 1) |
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_BACK) << 2) |
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_START) << 3) |
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_RIGHT) << 4) |
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_LEFT) << 5) |
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_UP) << 6) |
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_DOWN) << 7) |
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_RIGHTSHOULDER) << 8) |
            (SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_LEFTSHOULDER) << 9);

        // processing
        if cpu.emu_state == {
            case .STARTED;
            ppu.remaining_cycles += -cpu.remaining_cycles + 1;
            cpu.remaining_cycles = 1;
            step_cpu();
            cpu.emu_state = .RUNNING;
            while ppu.remaining_cycles > 0 step_ppu();
            #through;
            case .RUNNING;
            for 0..228*308 {
                if cpu.emu_state == .STOPPED break;
                cpu.remaining_cycles += 4;
                ppu.remaining_cycles += 4;
                step_ppu();
                while cpu.remaining_cycles > 0 && cpu.emu_state != .STOPPED step_cpu();
            }
            disasm_scroll_state = cpu.reg[15] / ifx cpu.state == .ARM then 4 else 2;
            disasm_mode = cpu.state;
            case .STOPPED;
            // this page intentionally left blank
            case .STEPPED;
            cpu.emu_state = .STOPPED;
            ppu.remaining_cycles += -cpu.remaining_cycles + 1;
            cpu.remaining_cycles += -cpu.remaining_cycles + 1;
            while ppu.remaining_cycles > 0 step_ppu();
            while cpu.remaining_cycles > 0 step_cpu();
            disasm_scroll_state = cpu.reg[15] / ifx cpu.state == .ARM then 4 else 2;
            disasm_mode = cpu.state;
        }
        // for ppu.oam {
        //     if !it.rotate_scale && it.rotate_scale_double_size then continue;
        //     min_x := it.min_x % 512;
        //     max_x := it.max_x % 512;
        //     min_y := it.min_y % 256;
        //     max_y := it.max_y % 256;
        //     for min_x..max_x {
        //         if min_y * SCREEN_WIDTH + it < 38400 then framebuffer[min_y * SCREEN_WIDTH + it] = 0xf800;
        //         if max_y * SCREEN_WIDTH + it < 38400 then framebuffer[max_y * SCREEN_WIDTH + it] = 0xf800;
        //     }
        //     for min_y..max_y {
        //         if it * SCREEN_WIDTH + min_x < 38400 then framebuffer[it * SCREEN_WIDTH + min_x] = 0xf800;
        //         if it * SCREEN_WIDTH + max_x < 38400 then framebuffer[it * SCREEN_WIDTH + max_x] = 0xf800;
        //     }
        // }
        SDL_RenderClear(renderer);
        surface := SDL_CreateRGBSurfaceFrom(framebuffer.data, SCREEN_WIDTH, SCREEN_HEIGHT, 15, SCREEN_WIDTH * 2, 0x1f, 0x3e0, 0x7c00, 0);
        defer SDL_FreeSurface(surface);
        tex := SDL_CreateTextureFromSurface(renderer, surface);
        defer SDL_DestroyTexture(tex);
        SDL_RenderCopy(renderer, tex, null, null);
        // GUI
        SDL_GL_MakeCurrent(win, gl_context);
        ImGui_ImplSdl_NewFrame(win);
        ImGui.NewFrame();
        draw_gui();
        ImGui.Render();
        ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
        SDL_GL_SwapWindow(win);
        reset_temporary_storage();
        #if #exists(__Iprof) {
            __Iprof.update(true);
            report = __Iprof.create_report();
        }
        end_time := seconds_since_init();
        // TODO: should probably make this refresh rate dependent
        sleep_milliseconds(xx (16.6 - ((end_time - time) * 1000)));
    }
}
