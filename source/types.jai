Cpu :: struct {
    memory: Cpu_Mmu;
    reg: [16]u32;
    reg_hi_fiq: [5]u32;
    sp: [#run enum_highest_value(Cpu_Mode)+1]u32;
    lr: [#run enum_highest_value(Cpu_Mode)+1]u32;
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
    breakpoints_arm: [0x10000]u32;
    breakpoints_thumb: [0x100]u16;

    Cpu_Mmu :: struct {
        Bios_Union :: union {
            _8: [0x4000]u8;
            _16: [0x2000]u16;
            _32: [0x1000]u32;
        }
        bios: Bios_Union;
        Ewram_Union :: union {
            _8: [0x40000]u8;
            _16: [0x20000]u16;
            _32: [0x10000]u32;
        }
        ewram: Ewram_Union;
        Iwram_Union :: union {
            _8: [0x8000]u8;
            _16: [0x4000]u16;
            _32: [0x2000]u32;
        }
        iwram: Iwram_Union;
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

Status_Bit :: enum {
    N :: 0x80000000;
    Z :: 0x40000000;
    C :: 0x20000000;
    V :: 0x10000000;
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
    STARTED;
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
    memory: Ppu_Mmu;
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
    draw_y : u8 = 0;
    remaining_cycles := 0;

    Ppu_Mmu :: struct {
        Palette_Ram_Union :: union {
            _8: [0x400]u8;
            _16: [0x200]u16;
            _32: [0x100]u32;
        }
        palette_ram: Palette_Ram_Union;
        Vram_Union :: union {
            _8: [0x18000]u8;
            _16: [0xc000]u16;
            _32: [0x6000]u32;
        }
        vram: Vram_Union;
        Oam_Union :: union {
            _8: [0x400]u8;
            _16: [0x200]u16;
            _32: [0x100]u32;
        }
        oam: Oam_Union;
    }

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

Decoder_Unit_Arm :: struct {
    mask: u32;
    result: u32;
    function: (ins: u32);
}

Decoder_Unit_Thumb :: struct {
    mask: u16;
    result: u16;
    function: (ins: u16);
}
