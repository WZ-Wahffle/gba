#import "Thread";
#import "String";

SCREEN_WIDTH :: 240;
SCREEN_HEIGHT :: 160;
FONT_SIZE :: 26;
window_width : s32 = SCREEN_WIDTH * 6;
window_height : s32 = SCREEN_HEIGHT * 6;

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
    framebuffer: [SCREEN_WIDTH * SCREEN_HEIGHT]u16;
    surface := SDL_CreateRGBSurfaceFrom(framebuffer.data, SCREEN_WIDTH, SCREEN_HEIGHT, 15, SCREEN_WIDTH * 2, 0x1f, 0x3e0, 0x7c00, 0);
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
            if event.type == SDL_KEYDOWN && event.key.repeat == 0 {
                if event.key.keysym.sym == {
                    case .SDLK_ESCAPE;
                        quit = true;
                    case .SDLK_c;
                        show_cpu = !show_cpu;
                    case .SDLK_d;
                        show_disasm = !show_disasm;
                    case .SDLK_e;
                        show_ewram = !show_ewram;
                    case .SDLK_i;
                        show_iwram = !show_iwram;
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
            cpu.remaining_cycles += -cpu.remaining_cycles + 1;
            while ppu.remaining_cycles > 0 step_ppu();
            while cpu.remaining_cycles > 0 step_cpu();
            cpu.emu_state = .RUNNING;
            #through;
            case .RUNNING;
            for 0..228*308 {
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
        }
        SDL_RenderClear(renderer);
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
    }
}
