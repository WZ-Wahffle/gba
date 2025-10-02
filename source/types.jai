Cpu :: struct {
    memory: Cpu_Mmu;
    gpr: [13]u32;
    gpr_hi_fiq: [5]u32;
    sp: [#run enum_highest_value(Cpu_Mode)+1]u32;
    lr: [#run enum_highest_value(Cpu_Mode)+1]u32;
    pc: u32;
    psr: u32 = 0x13;
    spsr: [#run enum_highest_value(Cpu_Mode)+1]u32;
    state := Cpu_State.ARM;
    mode := Cpu_Mode.SVC;
    privileged := true;
    dma: [4]Dma;
    timer: [4]Timer;

    // IME
    interrupt_master_enable := false;
    // IE
    ie: [#run enum_highest_value(Interrupt_Source)+1]bool;
    // IF
    ifl: [#run enum_highest_value(Interrupt_Source)+1]bool;

    emu_state := Emulation_State.STOPPED;
    remaining_cycles := 0;
    breakpoints: [..]u32;

    Cpu_Mmu :: struct {
        bios: [0x4000]u8;
        ewram: [0x40000]u8;
        iwram: [0x8000]u8;
        rom: [..]u8;
    }

    Dma :: struct {
        src: u32 = 0;
        src_int: u32 = 0;
        dst: u32 = 0;
        dst_int: u32 = 0;
        count: u16 = 0;
        count_int : u16 = 0;
        src_addr_control: Dma_Addr_Control;
        dst_addr_control: Dma_Addr_Control;
        repeat := false;
        large_transfer := false;
        game_pak := false;
        start_timing: Dma_Start_Timing;
        irq := false;
        enable := false;
    }

    Timer :: struct {
        reload : u16 = 0;
        prescaler_selection := 0;
        ignore_prescaler := false;
        irq := false;
        enable := false;
    }
}

Dma_Start_Timing :: enum {
    IMMED;
    VBLANK;
    HBLANK;
    SPECIAL;
}

Dma_Addr_Control :: enum {
    INC;
    DEC;
    FIXED;
    INC_RELOAD;
}

Cpu_State :: enum {
    THUMB;
    ARM;
}

Cpu_Mode :: enum s32 {
    USER :: 0;
    SYSTEM :: 0;
    IRQ :: 1;
    FIQ :: 2;
    SVC :: 3;
    ABT :: 4;
    UND :: 5;
}

Emulation_State :: enum {
    RUNNING;
    STOPPED;
    STEPPED;
}

Interrupt_Source :: enum {
    LCD_VBLANK;
    LCD_HBLANK;
    LCD_VCOUNTER;
    TIM0OVERFLOW;
    TIM1OVERFLOW;
    TIM2OVERFLOW;
    TIM3OVERFLOW;
    SERIAL;
    DMA0;
    DMA1;
    DMA2;
    DMA3;
    KEYPAD;
    GAMEPAK;
}

Ppu :: struct {
    palette_ram: [0x400]u8;
    vram: [0x18000]u8;
    oam: [0x400]u8;

    // DISPCNT
    bg_mode := 0;
    display_frame_select := false;
    hblank_free := false;
    obj_character_vram_mapping_one_dimensional := false;
    forced_blank := false;
    bg: [4]Background_Config;
    obj_enable := false;
    win: [2]Window_Config;
    obj_win: Window_Config;
    outside_win_bg_enable: [4]bool;
    outside_win_obj_enable := false;
    outside_win_special_effect := false;
    // DISPSTAT
    vblank_irq_enable := false;
    hblank_irq_enable := false;
    vcounter_irq_enable := false;
    vcounter := 0;
    // MOSAIC
    bg_mosaic_h := 0;
    bg_mosaic_v := 0;
    obj_mosaic_h := 0;
    obj_mosaic_v := 0;
    // BLDCNT
    bg_first_target_pixel: [4]bool;
    obj_first_target_pixel := false;
    bd_first_target_pixel := false;
    bg_second_target_pixel: [4]bool;
    obj_second_target_pixel := false;
    bd_second_target_pixel := false;
    special_effect := 0;
    // BLDALPHA
    eva := 0;
    evb := 0;
    // BLDY
    evy := 0;
    // KEYINPUT
    keypad_state : u16 = 0;
    // KEYCNT
    keypad_mask : u16 = 0;
    keypad_irq := false;
    keypad_require_all := false;

    draw_x := 0;
    draw_y := 0;
    remaining_cycles := 0;

    Background_Config :: struct {
        enable := false;
        prio := 0;
        char_base_block := 0;
        mosaic := false;
        more_colors := false;
        screen_base_block := 0;
        wraparound := false; // BG2/BG3 only
        size := 0;
        x_off := 0;
        y_off := 0;
        anchor_x := 0; // BG2/BG3 only
        anchor_y := 0; // BG2/BG3 only
        dx := 0; // BG2/BG3 only
        dmx := 0; // BG2/BG3 only
        dy := 0; // BG2/BG3 only
        dmy := 0; // BG2/BG3 only
    }

    Window_Config :: struct {
        enable := false;
        min_x := 0;
        max_x := 0;
        min_y := 0;
        max_y := 0;
        bg_enable: [4]bool;
        obj_enable := false;
        special_effect := false;
    }
}

Status_Bit :: enum {
    N;
    Z;
    C;
    V;
}
