Cpu :: struct {
    memory: Cpu_Mmu;
    reg: [16]u32;
    reg_hi_fiq: [5]u32;
    sp: [#run enum_highest_value(Cpu_Mode)+1]u32;
    lr: [#run enum_highest_value(Cpu_Mode)+1]u32;
    psr: u32 = 0xd3;
    spsr: [#run enum_highest_value(Cpu_Mode)+1]u32;
    mode := Cpu_Mode.SVC;
    backup_type := Backup_Type.NONE;

    // eeprom
    eeprom_size := Eeprom_Size.UNDECIDED;
    ee: [0x400]u64;
    ee_buffer: [256]bool;
    ee_buffer_idx : u8 = 0;
    ee_block : u32 = 0;
    ee_block_idx := 0;
    ee_read : u64 = 0;
    ee_read_idx := 0;
    ee_write : u64 = 0;
    ee_write_idx := 0;
    ee_state := Eeprom_State.NONE;

    // flash
    flash: [0x20000]u8;
    flash_bank := 0;
    flash_state := Flash_State.NONE;
    flash_op_mode := Flash_Operation_Mode.READ;

    // sram/fram
    sram: [0x8000]u8;

    privileged := true;
    dma: [4]Dma;
    timer: [4]Timer;
    halted := false;
    stopped := false;

    // IME
    interrupt_master_enable := false;
    // IE
    ie: u16;
    // IF
    ifl: u16;
    // WAITCNT
    waitcnt_lo : u8 = 0;
    waitcnt_hi : u8 = 0;
    waitcnt_sram := 0;
    waitcnt_0 := 0;
    waitcnt_1 := 0;
    waitcnt_2 := 0;

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
        control_int : u16 = 0;
    }

    Timer :: struct {
        prescaler_counter := 0;
        counter := 0;
        reload := 0;
        prescaler_selection := 0;
        ignore_prescaler := false;
        irq := false;
        enable := false;
    }

    cart_name: string;
    emu_state := Emulation_State.STOPPED;
    remaining_cycles := 0;
    breakpoints_arm: [0x10000]u32;
    breakpoints_thumb: [0x100]u16;
    pc_history: [64]u32;
    pc_history_idx : u32 = 0;
    logging := false;
    schedule_irq := false; // used by parallel irqs
    scheduled_irq : Interrupt_Source = 0;
    open_bus_bios_instruction : u32 = 0;
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
    oam: [128]Oam_Config;
    oam_param: [32]Oam_Transformation_Parameter_Config;
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
    keypad_irq_mask : u16 = 0;
    keypad_irq := false;
    keypad_irq_require_all := false;

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
            _64: [0x3000]u64;
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
        single_palette := false;
        screen_base_block := 0;
        wraparound := false; // BG2/BG3 only
        wide := false;
        tall := false;
        x_off := 0;
        y_off := 0;
        anchor_x_raw : u32 = 0; // BG2/BG3 only
        anchor_y_raw : u32 = 0; // BG2/BG3 only
        anchor_x : float; // BG2/BG3 only
        anchor_y : float; // BG2/BG3 only
        anchor_x_l : float; // BG2/BG3 only
        anchor_y_l : float; // BG2/BG3 only
        transform_x : float; // BG2/BG3 only
        transform_y : float; // BG2/BG3 only
        dx := 0; // BG2/BG3 only
        dmx := 0; // BG2/BG3 only
        dy := 0; // BG2/BG3 only
        dmy := 0; // BG2/BG3 only
        pa : float; // BG2/BG3 only
        pb : float; // BG2/BG3 only
        pc : float; // BG2/BG3 only
        pd : float; // BG2/BG3 only
        config_int: [2]u8;
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

    Oam_Config :: struct {
        x := 0;
        y := 0;
        tile_idx := 0;
        shape := 0;
        size := 0;
        flip_h := false;
        flip_v := false;
        rotate_scale := false;
        rotate_scale_param_idx := 0;
        rotate_scale_double_size := false;
        mode := 0;
        mosaic := false;
        single_palette := false;
        prio := 0;
        palette := 0;
        min_x := 0;
        max_x := 0;
        min_y := 0;
        max_y := 0;
        bounding_box_min_x := 0;
        bounding_box_max_x := 0;
        bounding_box_min_y := 0;
        bounding_box_max_y := 0;
        width := 0;
        height := 0;
    }

    Oam_Transformation_Parameter_Config :: struct {
        pa: float;
        pb: float;
        pc: float;
        pd: float;
    }

    draw_x := 0;
    draw_y : u32 = 0;
    remaining_cycles := 0;
}

Apu :: struct {
    dev: SDL_AudioDeviceID;

    chan_1: Pulse_Channel;
    chan_2: Pulse_Channel;
    chan_3: Wave_Channel;
    chan_4: Noise_Channel;
    chan_a: Direct_Channel;
    chan_b: Direct_Channel;
    fifo_a: Fifo;
    fifo_b: Fifo;

    master_enable := false;
    cgb_enable_l: [4]bool;
    cgb_enable_r: [4]bool;
    cgb_enable_int: u8;
    cgb_vol_l := 0;
    cgb_vol_r := 0;
    cgb_vol_int: u8;
    agb_cgb_volume := 0;
    soundcnt_h_int: [2]u8;
    bias := 0x200;
    sampling_frequency := 0;

    Pulse_Channel :: struct {
        sweep_shift_cnt := 0;
        sweep_freq_decrease := false;
        sweep_time := 0;

        envelope_speed := 0;
        envelope_increase := false;
        envelope_initial_volume := 0;

        use_length := false;
        sound_length := 0;

        duty_cycle := 0;
        frequency := 0;
        trigger := false;
    }

    Wave_Channel :: struct {
        enable := false;
        use_upper_bank := false;
        play_all := false;
        force_volume_to_75_percent := false;

        use_length := 0;
        sound_length := 0;

        volume := 0;
        frequency := 0;
        trigger := 0;
    }

    Noise_Channel :: struct {
        ratio := 0;
        wide := 0;
        frequency := 0;

        envelope_speed := 0;
        envelope_increase := 0;
        envelope_initial_volume := 0;

        use_length := 0;
        sound_length := 0;

        trigger := 0;
    }

    Direct_Channel :: struct {
        volume := false;
        enable_l := false;
        enable_r := false;
        timer_select := 0;
    }

    Fifo :: struct {
        buffer: [32]u8;
        r : u8 = 0;
        w : u8 = 0;
        cnt := 0;
        out : s8 = 0;
    }

    remaining_cycles := 0.0;
    played_samples := 0;
    prev : s16 = 0;
    prev_2 : s16 = 0;
    prev_3 : s16 = 0;
}

Backup_Type :: enum {
    NONE;
    EEPROM;
    SRAM;
    FLASH_64K;
    FLASH_128K;
}

Eeprom_Size :: enum {
    UNDECIDED;
    EEPROM_512B;
    EEPROM_8K;
}

Eeprom_State :: enum {
    NONE;
    FIRST_BIT_READ;
    READING;
    WRITING;
    WRITING_DATA;
    FINISHED;
}

Flash_State :: enum {
    NONE;
    FIRST_CMD_BYTE_READ;
    SECOND_CMD_BYTE_READ;
}

Flash_Operation_Mode :: enum {
    READ;
    ID;
    ERASE;
    WRITE;
    SWITCH_BANK;
}

Status_Bit :: enum {
    N :: 0x80000000;
    Z :: 0x40000000;
    C :: 0x20000000;
    V :: 0x10000000;
    I :: 0x00000080;
    F :: 0x00000040;
    T :: 0x00000020;
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

Cpu_Mode :: enum s32 {
    USER :: 0;
    SYSTEM :: 0;
    IRQ :: 1;
    FIQ :: 2;
    SVC :: 3;
    ABT :: 4;
    UND :: 5;
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


Emulation_State :: enum {
    STARTED;
    RUNNING;
    STOPPED;
    STEPPED;
    STEPPED_SCANLINE;
    STEPPED_FRAME;
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
