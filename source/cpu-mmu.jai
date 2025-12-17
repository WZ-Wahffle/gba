mmio_read :: (addr: u32) -> u8 {
    if addr - 0x04000000 == {
        case 0x000;
            return xx ppu.bg_mode |
            (ifx ppu.display_frame_select then 16 else 0) |
            (ifx ppu.hblank_free then 32 else 0) |
            (ifx ppu.obj_character_vram_mapping_one_dimensional then 64 else 0) |
            (ifx ppu.forced_blank then 128 else 0);
        case 0x001;
            return xx (ifx ppu.bg[0].enable then 1 else 0) |
            (ifx ppu.bg[1].enable then 2 else 0) |
            (ifx ppu.bg[2].enable then 4 else 0) |
            (ifx ppu.bg[3].enable then 8 else 0) |
            (ifx ppu.obj_enable then 16 else 0) |
            (ifx ppu.win[0].enable then 32 else 0) |
            (ifx ppu.win[1].enable then 64 else 0) |
            (ifx ppu.obj_win.enable then 128 else 0);
        case 0x004;
            return xx (ifx ppu.draw_y >= 160 && ppu.draw_y <= 226 then 1 else 0) |
            (ifx ppu.draw_x < 228 then 2 else 0) |
            (ifx ppu.vcounter == ppu.draw_y then 4 else 0) |
            (ifx ppu.vblank_irq_enable then 8 else 0) |
            (ifx ppu.hblank_irq_enable then 16 else 0) |
            (ifx ppu.vcounter_irq_enable then 32 else 0);
        case 0x005;
            return xx ppu.vcounter;
        case 0x006;
            return xx ppu.draw_y;
        case 0x007;
            return 0;
        case 0x008;
            return ppu.bg[0].config_int[0];
        case 0x009;
            return ppu.bg[0].config_int[1];
        case 0x00a;
            return ppu.bg[1].config_int[0];
        case 0x00b;
            return ppu.bg[1].config_int[1];
        case 0x00c;
            return ppu.bg[2].config_int[0];
        case 0x00d;
            return ppu.bg[2].config_int[1];
        case 0x00e;
            return ppu.bg[3].config_int[0];
        case 0x00f;
            return ppu.bg[3].config_int[1];
        case 0x04c;
            return xx ppu.bg_mosaic_h | (ppu.bg_mosaic_v << 4);
        case 0x04d;
            return xx ppu.obj_mosaic_h | (ppu.obj_mosaic_v << 4);
        case 0x060;
            return xx apu.chan_1.sweep_shift_cnt |
            (ifx apu.chan_1.sweep_freq_decrease then 0x8 else 0) |
            (apu.chan_1.sweep_time << 4);
        case 0x061;
            return 0;
        case 0x062;
            return xx apu.chan_1.sound_length | (apu.chan_1.duty_cycle << 6);
        case 0x063;
            return xx apu.chan_1.envelope_speed |
            (ifx apu.chan_1.envelope_increase then 8 else 0) |
            (apu.chan_1.envelope_initial_volume << 4);
        case 0x068;
            return xx apu.chan_2.sweep_shift_cnt |
            (ifx apu.chan_2.sweep_freq_decrease then 0x8 else 0) |
            (apu.chan_2.sweep_time << 4);
        case 0x069;
            return 0;
        case 0x073;
            return xx (apu.chan_3.volume << 5) |
            (ifx apu.chan_3.force_volume_to_75_percent then 128 else 0);
        case 0x074;
            return xx apu.chan_3.frequency & 0xff;
        case 0x075;
            return xx (apu.chan_3.frequency >> 8) | (apu.chan_3.use_length << 6) | (apu.chan_3.trigger << 7);
        case 0x078;
            return xx apu.chan_4.sound_length;
        case 0x079;
            return xx apu.chan_4.envelope_speed |
            (apu.chan_4.envelope_increase << 3) |
            (apu.chan_4.envelope_initial_volume << 4);
        case 0x07a;
            return 0;
        case 0x07b;
            return 0;
        case 0x07c;
            return xx apu.chan_4.ratio |
            (apu.chan_4.wide << 3) |
            (apu.chan_4.frequency << 4);
        case 0x07d;
            return xx (apu.chan_4.use_length << 6) |
            (apu.chan_4.trigger << 7);
        case 0x07e;
            return 0;
        case 0x07f;
            return 0;
        case 0x080;
            return apu.cgb_enable_int;
        case 0x081;
            return apu.cgb_vol_int;
        case 0x082;
            return 0;
        case 0x083;
            return 0;
        case 0x0b8;
            return xx (cpu.dma[0].count_int >> 0) & 0xff;
        case 0x0b9;
            return xx (cpu.dma[0].count_int >> 8) & 0xff;
        case 0x0ba;
            return xx (cpu.dma[0].control_int >> 0) & 0xff;
        case 0x0bb;
            return xx (cpu.dma[0].control_int >> 8) & 0xff;
        case 0x0c4;
            return xx (cpu.dma[1].count_int >> 0) & 0xff;
        case 0x0c5;
            return xx (cpu.dma[1].count_int >> 8) & 0xff;
        case 0x0c6;
            return xx (cpu.dma[1].control_int >> 0) & 0xff;
        case 0x0c7;
            return xx (cpu.dma[1].control_int >> 8) & 0xff;
        case 0x0d0;
            return xx (cpu.dma[2].count_int >> 0) & 0xff;
        case 0x0d1;
            return xx (cpu.dma[2].count_int >> 8) & 0xff;
        case 0x0d2;
            return xx (cpu.dma[2].control_int >> 0) & 0xff;
        case 0x0d3;
            return xx (cpu.dma[2].control_int >> 8) & 0xff;
        case 0x0dc;
            return xx (cpu.dma[3].count_int >> 0) & 0xff;
        case 0x0dd;
            return xx (cpu.dma[3].count_int >> 8) & 0xff;
        case 0x0de;
            return xx (cpu.dma[3].control_int >> 0) & 0xff;
        case 0x0df;
            return xx (cpu.dma[3].control_int >> 8) & 0xff;
        case 0x088;
            return 0;
        case 0x089;
            return 2;
        case 0x08a;
            return 0;
        case 0x08b;
            return 0;
        case 0x100;
            return xx cpu.timer[0].counter & 0xff;
        case 0x101;
            return xx (cpu.timer[0].counter >> 8) & 0xff;
        case 0x102;
            return xx (cpu.timer[0].prescaler_selection) |
            (ifx cpu.timer[0].ignore_prescaler then 4 else 0) |
            (ifx cpu.timer[0].irq then 0x40 else 0) |
            (ifx cpu.timer[0].enable then 0x80 else 0);
        case 0x103;
            return 0;
        case 0x104;
            return xx cpu.timer[1].counter & 0xff;
        case 0x105;
            return xx (cpu.timer[1].counter >> 8) & 0xff;
        case 0x106;
            return xx (cpu.timer[1].prescaler_selection) |
            (ifx cpu.timer[1].ignore_prescaler then 4 else 0) |
            (ifx cpu.timer[1].irq then 0x40 else 0) |
            (ifx cpu.timer[1].enable then 0x80 else 0);
        case 0x107;
            return 0;
        case 0x108;
            return xx cpu.timer[2].counter & 0xff;
        case 0x109;
            return xx (cpu.timer[2].counter >> 8) & 0xff;
        case 0x10a;
            return xx (cpu.timer[2].prescaler_selection) |
            (ifx cpu.timer[2].ignore_prescaler then 4 else 0) |
            (ifx cpu.timer[2].irq then 0x40 else 0) |
            (ifx cpu.timer[2].enable then 0x80 else 0);
        case 0x10b;
            return 0;
        case 0x10c;
            return xx cpu.timer[3].counter & 0xff;
        case 0x10d;
            return xx (cpu.timer[3].counter >> 8) & 0xff;
        case 0x10e;
            return xx (cpu.timer[3].prescaler_selection) |
            (ifx cpu.timer[3].ignore_prescaler then 4 else 0) |
            (ifx cpu.timer[3].irq then 0x40 else 0) |
            (ifx cpu.timer[3].enable then 0x80 else 0);
        case 0x10f;
            return 0;
        case 0x128;
            return 0;
        case 0x129;
            return 0;
        case 0x130;
            return xx (~ppu.keypad_state) & 0xff;
        case 0x131;
            return xx (~(ppu.keypad_state >> 8)) & 0xff;
        case 0x132;
            return xx ppu.keypad_irq_mask & 0xff;
        case 0x133;
            return xx (ppu.keypad_irq_mask >> 8) |
            (ifx ppu.keypad_irq then 0x40 else 0) |
            (ifx ppu.keypad_irq_require_all then 0x80 else 0);
        case 0x134;
            return 0;
        case 0x135;
            return 0;
        // communication with gamecube not implemented
        case 0x140;
            return 0;
        case 0x141;
            return 0;
        case 0x142;
            return 0;
        case 0x143;
            return 0;
        case 0x150;
            return 0;
        case 0x151;
            return 0;
        case 0x152;
            return 0;
        case 0x153;
            return 0;
        case 0x200;
            return cpu.ie[Interrupt_Source.LCD_VBLANK] |
                cpu.ie[Interrupt_Source.LCD_HBLANK] |
                cpu.ie[Interrupt_Source.LCD_VCOUNTER] |
                cpu.ie[Interrupt_Source.TIM0OVERFLOW] |
                cpu.ie[Interrupt_Source.TIM1OVERFLOW] |
                cpu.ie[Interrupt_Source.TIM2OVERFLOW] |
                cpu.ie[Interrupt_Source.TIM3OVERFLOW] |
                cpu.ie[Interrupt_Source.SERIAL];
        case 0x201;
            return cpu.ie[Interrupt_Source.DMA0] |
                cpu.ie[Interrupt_Source.DMA1] |
                cpu.ie[Interrupt_Source.DMA2] |
                cpu.ie[Interrupt_Source.DMA3] |
                cpu.ie[Interrupt_Source.KEYPAD] |
                cpu.ie[Interrupt_Source.GAMEPAK];
        case 0x202;
            return cpu.ifl[Interrupt_Source.LCD_VBLANK] |
                cpu.ifl[Interrupt_Source.LCD_HBLANK] |
                cpu.ifl[Interrupt_Source.LCD_VCOUNTER] |
                cpu.ifl[Interrupt_Source.TIM0OVERFLOW] |
                cpu.ifl[Interrupt_Source.TIM1OVERFLOW] |
                cpu.ifl[Interrupt_Source.TIM2OVERFLOW] |
                cpu.ifl[Interrupt_Source.TIM3OVERFLOW] |
                cpu.ifl[Interrupt_Source.SERIAL];
        case 0x203;
            return cpu.ifl[Interrupt_Source.DMA0] |
                cpu.ifl[Interrupt_Source.DMA1] |
                cpu.ifl[Interrupt_Source.DMA2] |
                cpu.ifl[Interrupt_Source.DMA3] |
                cpu.ifl[Interrupt_Source.KEYPAD] |
                cpu.ifl[Interrupt_Source.GAMEPAK];
        case 0x204;
            return cpu.waitcnt_lo;
        case 0x205;
            return cpu.waitcnt_hi;
        case 0x208;
            return xx ifx cpu.interrupt_master_enable then 1 else 0;
        case 0x209;
            return 0;
        case 0x20a;
            return 0;
        case 0x20b;
            return 0;
        case 0x20c;
            return 0;
        case 0x20d;
            return 0;
        case 0x20e;
            return 0;
        case 0x20f;
            return 0;
        case 0x300;
            return 0;
        case;
            log_error("Unmapped IO read: 0x%", formatInt(addr, 16));
            assert(false);
            return 0;
    }
}

mmio_write :: (addr: u32, val: u8) {
    if addr - 0x04000000 == {
        case 0x000;
            ppu.bg_mode = val & 0b111;
            if (val & 0x8) != 0 {
                assert(false);
            }
            ppu.display_frame_select = (val & 0x10) != 0;
            ppu.hblank_free = (val & 0x20) != 0;
            ppu.obj_character_vram_mapping_one_dimensional = (val & 0x40) != 0;
            ppu.forced_blank = (val & 0x80) != 0;
        case 0x001;
            ppu.bg[0].enable = (val & 0x1) != 0;
            ppu.bg[1].enable = (val & 0x2) != 0;
            ppu.bg[2].enable = (val & 0x4) != 0;
            ppu.bg[3].enable = (val & 0x8) != 0;
            ppu.obj_enable = (val & 0x10) != 0;
            ppu.win[0].enable = (val & 0x20) != 0;
            ppu.win[1].enable = (val & 0x40) != 0;
            ppu.obj_win.enable = (val & 0x80) != 0;
        case 0x004;
            ppu.vblank_irq_enable = (val & 0x8) != 0;
            ppu.hblank_irq_enable = (val & 0x10) != 0;
            ppu.vcounter_irq_enable = (val & 0x20) != 0;
        case 0x005;
            ppu.vcounter = val;
        case 0x008;
            ppu.bg[0].prio = val & 0b11;
            ppu.bg[0].char_base_block = (val >> 2) & 0b11;
            ppu.bg[0].mosaic = (val & 0x40) != 0;
            ppu.bg[0].single_palette = (val & 0x80) != 0;
            ppu.bg[0].config_int[0] = val;
        case 0x009;
            ppu.bg[0].screen_base_block = val & 0x1f;
            ppu.bg[0].wraparound = (val & 0x20) != 0;
            ppu.bg[0].wide = (val & 0x40) != 0;
            ppu.bg[0].tall = (val & 0x80) != 0;
            ppu.bg[0].config_int[1] = val;
        case 0x00a;
            ppu.bg[1].prio = val & 0b11;
            ppu.bg[1].char_base_block = (val >> 2) & 0b11;
            ppu.bg[1].mosaic = (val & 0x40) != 0;
            ppu.bg[1].single_palette = (val & 0x80) != 0;
            ppu.bg[1].config_int[0] = val;
        case 0x00b;
            ppu.bg[1].screen_base_block = val & 0x1f;
            ppu.bg[1].wraparound = (val & 0x20) != 0;
            ppu.bg[1].wide = (val & 0x40) != 0;
            ppu.bg[1].tall = (val & 0x80) != 0;
            ppu.bg[1].config_int[1] = val;
        case 0x00c;
            ppu.bg[2].prio = val & 0b11;
            ppu.bg[2].char_base_block = (val >> 2) & 0b11;
            ppu.bg[2].mosaic = (val & 0x40) != 0;
            ppu.bg[2].single_palette = (val & 0x80) != 0;
            ppu.bg[2].config_int[0] = val;
        case 0x00d;
            ppu.bg[2].screen_base_block = val & 0x1f;
            ppu.bg[2].wraparound = (val & 0x20) != 0;
            ppu.bg[2].wide = (val & 0x40) != 0;
            ppu.bg[2].tall = (val & 0x80) != 0;
            ppu.bg[2].config_int[1] = val;
        case 0x00e;
            ppu.bg[3].prio = val & 0b11;
            ppu.bg[3].char_base_block = (val >> 2) & 0b11;
            ppu.bg[3].mosaic = (val & 0x40) != 0;
            ppu.bg[3].single_palette = (val & 0x80) != 0;
            ppu.bg[3].config_int[0] = val;
        case 0x00f;
            ppu.bg[3].screen_base_block = val & 0x1f;
            ppu.bg[3].wraparound = (val & 0x20) != 0;
            ppu.bg[3].wide = (val & 0x40) != 0;
            ppu.bg[3].tall = (val & 0x80) != 0;
            ppu.bg[3].config_int[1] = val;
        case 0x010;
            ppu.bg[0].x_off &= 0x100;
            ppu.bg[0].x_off |= val;
        case 0x011;
            ppu.bg[0].x_off &= 0xff;
            ppu.bg[0].x_off |= (cast(u16)val & 1) << 8;
        case 0x012;
            ppu.bg[0].y_off &= 0x100;
            ppu.bg[0].y_off |= val;
        case 0x013;
            ppu.bg[0].y_off &= 0xff;
            ppu.bg[0].y_off |= (cast(u16)val & 1) << 8;
        case 0x014;
            ppu.bg[1].x_off &= 0x100;
            ppu.bg[1].x_off |= val;
        case 0x015;
            ppu.bg[1].x_off &= 0xff;
            ppu.bg[1].x_off |= (cast(u16)val & 1) << 8;
        case 0x016;
            ppu.bg[1].y_off &= 0x100;
            ppu.bg[1].y_off |= val;
        case 0x017;
            ppu.bg[1].y_off &= 0xff;
            ppu.bg[1].y_off |= (cast(u16)val & 1) << 8;
        case 0x018;
            ppu.bg[2].x_off &= 0x100;
            ppu.bg[2].x_off |= val;
        case 0x019;
            ppu.bg[2].x_off &= 0xff;
            ppu.bg[2].x_off |= (cast(u16)val & 1) << 8;
        case 0x01a;
            ppu.bg[2].y_off &= 0x100;
            ppu.bg[2].y_off |= val;
        case 0x01b;
            ppu.bg[2].y_off &= 0xff;
            ppu.bg[2].y_off |= (cast(u16)val & 1) << 8;
        case 0x01c;
            ppu.bg[3].x_off &= 0x100;
            ppu.bg[3].x_off |= val;
        case 0x01d;
            ppu.bg[3].x_off &= 0xff;
            ppu.bg[3].x_off |= (cast(u16)val & 1) << 8;
        case 0x01e;
            ppu.bg[3].y_off &= 0x100;
            ppu.bg[3].y_off |= val;
        case 0x01f;
            ppu.bg[3].y_off &= 0xff;
            ppu.bg[3].y_off |= (cast(u16)val & 1) << 8;
        case 0x020;
            ppu.bg[2].dx &= 0xff00;
            ppu.bg[2].dx |= val;
            ppu.bg[2].pa = (cast,no_check(s16)ppu.bg[2].dx) / 256.0;
        case 0x021;
            ppu.bg[2].dx &= 0x00ff;
            ppu.bg[2].dx |= (cast(u16)val) << 8;
            ppu.bg[2].pa = (cast,no_check(s16)ppu.bg[2].dx) / 256.0;
        case 0x022;
            ppu.bg[2].dmx &= 0xff00;
            ppu.bg[2].dmx |= val;
            ppu.bg[2].pb = (cast,no_check(s16)ppu.bg[2].dmx) / 256.0;
        case 0x023;
            ppu.bg[2].dmx &= 0x00ff;
            ppu.bg[2].dmx |= (cast(u16)val) << 8;
            ppu.bg[2].pb = (cast,no_check(s16)ppu.bg[2].dmx) / 256.0;
        case 0x024;
            ppu.bg[2].dy &= 0xff00;
            ppu.bg[2].dy |= val;
            ppu.bg[2].pc = (cast,no_check(s16)ppu.bg[2].dy) / 256.0;
        case 0x025;
            ppu.bg[2].dy &= 0x00ff;
            ppu.bg[2].dy |= (cast(u16)val) << 8;
            ppu.bg[2].pc = (cast,no_check(s16)ppu.bg[2].dy) / 256.0;
        case 0x026;
            ppu.bg[2].dmy &= 0xff00;
            ppu.bg[2].dmy |= val;
            ppu.bg[2].pd = (cast,no_check(s16)ppu.bg[2].dmy) / 256.0;
        case 0x027;
            ppu.bg[2].dmy &= 0x00ff;
            ppu.bg[2].dmy |= (cast(u16)val) << 8;
            ppu.bg[2].pd = (cast,no_check(s16)ppu.bg[2].dmy) / 256.0;
        case 0x028;
            ppu.bg[2].anchor_x_raw &= 0x0fffff00;
            ppu.bg[2].anchor_x_raw |= val;
            ppu.bg[2].anchor_x = (cast,no_check(s32)(ppu.bg[2].anchor_x_raw << 4)) / 4096.0;
        case 0x029;
            ppu.bg[2].anchor_x_raw &= 0x0fff00ff;
            ppu.bg[2].anchor_x_raw |= (cast(u32)val) << 8;
            ppu.bg[2].anchor_x = (cast,no_check(s32)(ppu.bg[2].anchor_x_raw << 4)) / 4096.0;
        case 0x02a;
            ppu.bg[2].anchor_x_raw &= 0x0f00ffff;
            ppu.bg[2].anchor_x_raw |= (cast(u32)val) << 16;
            ppu.bg[2].anchor_x = (cast,no_check(s32)(ppu.bg[2].anchor_x_raw << 4)) / 4096.0;
        case 0x02b;
            ppu.bg[2].anchor_x_raw &= 0x00ffffff;
            ppu.bg[2].anchor_x_raw |= (cast(u32)val & 0xf) << 24;
            ppu.bg[2].anchor_x = (cast,no_check(s32)(ppu.bg[2].anchor_x_raw << 4)) / 4096.0;
        case 0x02c;
            ppu.bg[2].anchor_y_raw &= 0x0fffff00;
            ppu.bg[2].anchor_y_raw |= val;
            ppu.bg[2].anchor_y = (cast,no_check(s32)(ppu.bg[2].anchor_y_raw << 4)) / 4096.0;
        case 0x02d;
            ppu.bg[2].anchor_y_raw &= 0x0fff00ff;
            ppu.bg[2].anchor_y_raw |= (cast(u32)val) << 8;
            ppu.bg[2].anchor_y = (cast,no_check(s32)(ppu.bg[2].anchor_y_raw << 4)) / 4096.0;
        case 0x02e;
            ppu.bg[2].anchor_y_raw &= 0x0f00ffff;
            ppu.bg[2].anchor_y_raw |= (cast(u32)val) << 16;
            ppu.bg[2].anchor_y = (cast,no_check(s32)(ppu.bg[2].anchor_y_raw << 4)) / 4096.0;
        case 0x02f;
            ppu.bg[2].anchor_y_raw &= 0x00ffffff;
            ppu.bg[2].anchor_y_raw |= (cast(u32)val & 0xf) << 24;
            ppu.bg[2].anchor_y = (cast,no_check(s32)(ppu.bg[2].anchor_y_raw << 4)) / 4096.0;
        case 0x030;
            ppu.bg[3].dx &= 0xff00;
            ppu.bg[3].dx |= val;
            ppu.bg[3].pa = (cast,no_check(s16)ppu.bg[3].dx) / 256.0;
        case 0x031;
            ppu.bg[3].dx &= 0x00ff;
            ppu.bg[3].dx |= (cast(u16)val) << 8;
            ppu.bg[3].pa = (cast,no_check(s16)ppu.bg[3].dx) / 256.0;
        case 0x032;
            ppu.bg[3].dmx &= 0xff00;
            ppu.bg[3].dmx |= val;
            ppu.bg[3].pb = (cast,no_check(s16)ppu.bg[3].dmx) / 256.0;
        case 0x033;
            ppu.bg[3].dmx &= 0x00ff;
            ppu.bg[3].dmx |= (cast(u16)val) << 8;
            ppu.bg[3].pb = (cast,no_check(s16)ppu.bg[3].dmx) / 256.0;
        case 0x034;
            ppu.bg[3].dy &= 0xff00;
            ppu.bg[3].dy |= val;
            ppu.bg[3].pc = (cast,no_check(s16)ppu.bg[3].dy) / 256.0;
        case 0x035;
            ppu.bg[3].dy &= 0x00ff;
            ppu.bg[3].dy |= (cast(u16)val) << 8;
            ppu.bg[3].pc = (cast,no_check(s16)ppu.bg[3].dy) / 256.0;
        case 0x036;
            ppu.bg[3].dmy &= 0xff00;
            ppu.bg[3].dmy |= val;
            ppu.bg[3].pd = (cast,no_check(s16)ppu.bg[3].dmy) / 256.0;
        case 0x037;
            ppu.bg[3].dmy &= 0x00ff;
            ppu.bg[3].dmy |= (cast(u16)val) << 8;
            ppu.bg[3].pd = (cast,no_check(s16)ppu.bg[3].dmy) / 256.0;
        case 0x038;
            ppu.bg[3].anchor_x_raw &= 0x0fffff00;
            ppu.bg[3].anchor_x_raw |= val;
            ppu.bg[3].anchor_x = (cast,no_check(s32)(ppu.bg[3].anchor_x_raw << 4)) / 4096.0;
        case 0x039;
            ppu.bg[3].anchor_x_raw &= 0x0fff00ff;
            ppu.bg[3].anchor_x_raw |= (cast(u32)val) << 8;
            ppu.bg[3].anchor_x = (cast,no_check(s32)(ppu.bg[3].anchor_x_raw << 4)) / 4096.0;
        case 0x03a;
            ppu.bg[3].anchor_x_raw &= 0x0f00ffff;
            ppu.bg[3].anchor_x_raw |= (cast(u32)val) << 16;
            ppu.bg[3].anchor_x = (cast,no_check(s32)(ppu.bg[3].anchor_x_raw << 4)) / 4096.0;
        case 0x03b;
            ppu.bg[3].anchor_x_raw &= 0x00ffffff;
            ppu.bg[3].anchor_x_raw |= (cast(u32)val & 0xf) << 24;
            ppu.bg[3].anchor_x = (cast,no_check(s32)(ppu.bg[3].anchor_x_raw << 4)) / 4096.0;
        case 0x03c;
            ppu.bg[3].anchor_y_raw &= 0x0fffff00;
            ppu.bg[3].anchor_y_raw |= val;
            ppu.bg[3].anchor_y = (cast,no_check(s32)(ppu.bg[3].anchor_y_raw << 4)) / 4096.0;
        case 0x03d;
            ppu.bg[3].anchor_y_raw &= 0x0fff00ff;
            ppu.bg[3].anchor_y_raw |= (cast(u32)val) << 8;
            ppu.bg[3].anchor_y = (cast,no_check(s32)(ppu.bg[3].anchor_y_raw << 4)) / 4096.0;
        case 0x03e;
            ppu.bg[3].anchor_y_raw &= 0x0f00ffff;
            ppu.bg[3].anchor_y_raw |= (cast(u32)val) << 16;
            ppu.bg[3].anchor_y = (cast,no_check(s32)(ppu.bg[3].anchor_y_raw << 4)) / 4096.0;
        case 0x03f;
            ppu.bg[3].anchor_y_raw &= 0x00ffffff;
            ppu.bg[3].anchor_y_raw |= (cast(u32)val & 0xf) << 24;
            ppu.bg[3].anchor_y = (cast,no_check(s32)(ppu.bg[3].anchor_y_raw << 4)) / 4096.0;
        case 0x040;
            ppu.win[0].max_x = val;
        case 0x041;
            ppu.win[0].min_x = val;
        case 0x042;
            ppu.win[1].max_x = val;
        case 0x043;
            ppu.win[1].min_x = val;
        case 0x044;
            ppu.win[0].max_y = val;
        case 0x045;
            ppu.win[0].min_y = val;
        case 0x046;
            ppu.win[1].max_y = val;
        case 0x047;
            ppu.win[1].min_y = val;
        case 0x048;
            ppu.win[0].bg_enable[0] = (val & 0x1) != 0;
            ppu.win[0].bg_enable[1] = (val & 0x2) != 0;
            ppu.win[0].bg_enable[2] = (val & 0x4) != 0;
            ppu.win[0].bg_enable[3] = (val & 0x8) != 0;
            ppu.win[0].obj_enable = (val & 0x10) != 0;
            ppu.win[0].special_effect = (val & 0x20) != 0;
        case 0x049;
            ppu.win[1].bg_enable[0] = (val & 0x1) != 0;
            ppu.win[1].bg_enable[1] = (val & 0x2) != 0;
            ppu.win[1].bg_enable[2] = (val & 0x4) != 0;
            ppu.win[1].bg_enable[3] = (val & 0x8) != 0;
            ppu.win[1].obj_enable = (val & 0x10) != 0;
            ppu.win[1].special_effect = (val & 0x20) != 0;
        case 0x04a;
            ppu.outside_win_bg_enable[0] = (val & 0x1) != 0;
            ppu.outside_win_bg_enable[1] = (val & 0x2) != 0;
            ppu.outside_win_bg_enable[2] = (val & 0x4) != 0;
            ppu.outside_win_bg_enable[3] = (val & 0x8) != 0;
            ppu.outside_win_obj_enable = (val & 0x10) != 0;
            ppu.outside_win_special_effect = (val & 0x20) != 0;
        case 0x04b;
            ppu.obj_win.bg_enable[0] = (val & 0x1) != 0;
            ppu.obj_win.bg_enable[1] = (val & 0x2) != 0;
            ppu.obj_win.bg_enable[2] = (val & 0x4) != 0;
            ppu.obj_win.bg_enable[3] = (val & 0x8) != 0;
            ppu.obj_win.obj_enable = (val & 0x10) != 0;
            ppu.obj_win.special_effect = (val & 0x20) != 0;
        case 0x04c;
            ppu.bg_mosaic_h = val & 0xf;
            ppu.bg_mosaic_v = (val >> 4) & 0xf;
        case 0x04d;
            ppu.obj_mosaic_h = val & 0xf;
            ppu.obj_mosaic_v = (val >> 4) & 0xf;
        case 0x04e; // not used
        case 0x04f; // not used
        case 0x050;
            ppu.bg_first_target_pixel[0] = (val & 0x1) != 0;
            ppu.bg_first_target_pixel[1] = (val & 0x2) != 0;
            ppu.bg_first_target_pixel[2] = (val & 0x4) != 0;
            ppu.bg_first_target_pixel[3] = (val & 0x8) != 0;
            ppu.obj_first_target_pixel = (val & 0x10) != 0;
            ppu.bd_first_target_pixel = (val & 0x20) != 0;
            ppu.special_effect = (val >> 6);
        case 0x051;
            ppu.bg_second_target_pixel[0] = (val & 0x1) != 0;
            ppu.bg_second_target_pixel[1] = (val & 0x2) != 0;
            ppu.bg_second_target_pixel[2] = (val & 0x4) != 0;
            ppu.bg_second_target_pixel[3] = (val & 0x8) != 0;
            ppu.obj_second_target_pixel = (val & 0x10) != 0;
            ppu.bd_second_target_pixel = (val & 0x20) != 0;
        case 0x052;
            ppu.eva = val & 0x1f;
        case 0x053;
            ppu.evb = val & 0x1f;
        case 0x054;
            ppu.evy = val & 0x1f;
        case 0x055; // not used
        case 0x056; // not used
        case 0x057; // not used
        case 0x060;
            apu.chan_1.sweep_shift_cnt = val & 0b111;
            apu.chan_1.sweep_freq_decrease = (val & 0x08) != 0;
            apu.chan_1.sweep_time = (val >> 4) & 0b111;
        case 0x061;
        case 0x062;
            apu.chan_1.sound_length = val & 0x3f;
            apu.chan_1.duty_cycle = val >> 6;
        case 0x063;
            apu.chan_1.envelope_speed = val & 0b111;
            apu.chan_1.envelope_increase = (val & 0x08) != 0;
            apu.chan_1.envelope_initial_volume = val >> 4;
        case 0x064;
            apu.chan_1.frequency &= 0x700;
            apu.chan_1.frequency |= val;
        case 0x065;
            apu.chan_1.frequency &= 0x0ff;
            apu.chan_1.frequency |= (cast(u16)val & 0b111) << 8;
            apu.chan_1.use_length = (val & 0x40) != 0;
            apu.chan_1.trigger = (val & 0x80) != 0;
        case 0x068;
            apu.chan_2.sound_length = val & 0x3f;
            apu.chan_2.duty_cycle = val >> 6;
        case 0x069;
            apu.chan_2.envelope_speed = val & 0b111;
            apu.chan_2.envelope_increase = (val & 0x08) != 0;
            apu.chan_2.envelope_initial_volume = val >> 4;
        case 0x06c;
            apu.chan_2.frequency &= 0x700;
            apu.chan_2.frequency |= val;
        case 0x06d;
            apu.chan_2.frequency &= 0x0ff;
            apu.chan_2.frequency |= (cast(u16)val & 0b111) << 8;
            apu.chan_2.use_length = (val & 0x40) != 0;
            apu.chan_2.trigger = (val & 0x80) != 0;
        case 0x070;
            apu.chan_3.play_all = (val & 0x20) != 0;
            apu.chan_3.use_upper_bank = (val & 0x40) != 0;
            apu.chan_3.enable = (val & 0x80) != 0;
        case 0x072;
            apu.chan_3.sound_length = val;
        case 0x073;
            apu.chan_3.volume = (val >> 5) & 0b11;
            apu.chan_3.force_volume_to_75_percent = (val & 0x80) != 0;
        case 0x074;
            apu.chan_3.frequency &= 0x700;
            apu.chan_3.frequency |= val;
        case 0x075;
            apu.chan_3.frequency &= 0xff;
            apu.chan_3.frequency |= (cast(u16)val & 0b111) << 8;
            apu.chan_3.use_length = (val >> 6) & 1;
            apu.chan_3.trigger = (val >> 7) & 1;
        case 0x080;
            apu.cgb_enable_r[0] = (val & 0x1) != 0;
            apu.cgb_enable_r[1] = (val & 0x2) != 0;
            apu.cgb_enable_r[2] = (val & 0x4) != 0;
            apu.cgb_enable_r[3] = (val & 0x8) != 0;
            apu.cgb_enable_l[0] = (val & 0x10) != 0;
            apu.cgb_enable_l[1] = (val & 0x20) != 0;
            apu.cgb_enable_l[2] = (val & 0x40) != 0;
            apu.cgb_enable_l[3] = (val & 0x80) != 0;
            apu.cgb_enable_int = val;
        case 0x081;
            apu.cgb_vol_r = val & 0b111;
            apu.cgb_vol_l = (val >> 4) & 0b111;
            apu.cgb_vol_int = val;
        case 0x088;
            apu.bias &= 0x300;
            apu.bias |= val;
        case 0x089;
            apu.bias &= 0xff;
            apu.bias |= (cast(u16)val & 0b11) << 8;
            apu.sampling_frequency = val >> 6;
        case 0x0a0; #through;
        case 0x0a1; #through;
        case 0x0a2; #through;
        case 0x0a3;
            apu.fifo_a.buffer[apu.fifo_a.w & 0x1f] = val;
            apu.fifo_a.w += 1;
            apu.fifo_a.w %= 32;
            // print("Writing to %\n", apu.fifo_a.w);
            if apu.fifo_a.cnt < 32 {
                apu.fifo_a.cnt += 1;
            }
        case 0x0a4; #through;
        case 0x0a5; #through;
        case 0x0a6; #through;
        case 0x0a7;
            apu.fifo_b.buffer[apu.fifo_b.w & 0x1f] = val;
            apu.fifo_b.w += 1;
            apu.fifo_b.w %= 32;
            if apu.fifo_b.cnt < 32 {
                apu.fifo_b.cnt += 1;
            }
        case 0x0b0;
            cpu.dma[0].src &= 0x0fffff00;
            cpu.dma[0].src |= val;
        case 0x0b1;
            cpu.dma[0].src &= 0x0fff00ff;
            cpu.dma[0].src |= (cast(u32)val) << 8;
        case 0x0b2;
            cpu.dma[0].src &= 0x0f00ffff;
            cpu.dma[0].src |= (cast(u32)val) << 16;
        case 0x0b3;
            cpu.dma[0].src &= 0x00ffffff;
            cpu.dma[0].src |= (cast(u32)val) << 24;
        case 0x0b4;
            cpu.dma[0].dst &= 0x0fffff00;
            cpu.dma[0].dst |= val;
        case 0x0b5;
            cpu.dma[0].dst &= 0x0fff00ff;
            cpu.dma[0].dst |= (cast(u32)val) << 8;
        case 0x0b6;
            cpu.dma[0].dst &= 0x0f00ffff;
            cpu.dma[0].dst |= (cast(u32)val) << 16;
        case 0x0b7;
            cpu.dma[0].dst &= 0x00ffffff;
            cpu.dma[0].dst |= (cast(u32)val) << 24;
        case 0x0b8;
            cpu.dma[0].count &= 0xff00;
            cpu.dma[0].count |= val;
        case 0x0b9;
            cpu.dma[0].count &= 0x00ff;
            cpu.dma[0].count |= (cast(u16)val) << 8;
        case 0x0ba;
            cpu.dma[0].dst_addr_control = xx (val >> 5) & 0b11;
            cpu.dma[0].src_addr_control &= 0b10;
            cpu.dma[0].src_addr_control |= xx (val >> 7) & 0b1;
            cpu.dma[0].control_int &= 0xff00;
            cpu.dma[0].control_int |= val;
        case 0x0bb;
            if !cpu.dma[0].enable && (val & 0x80) != 0 {
                cpu.dma[0].src_int = cpu.dma[0].src;
                cpu.dma[0].dst_int = cpu.dma[0].dst;
                cpu.dma[0].count_int = ifx cpu.dma[0].count == 0 then 0x4000 else cpu.dma[0].count;
            }

            cpu.dma[0].src_addr_control &= 0b01;
            cpu.dma[0].src_addr_control |= xx (val & 0b1) << 1;
            cpu.dma[0].repeat = (val & 0x2) != 0;
            cpu.dma[0].large_transfer = (val & 0x4) != 0;
            cpu.dma[0].game_pak = (val & 0x8) != 0;
            cpu.dma[0].start_timing = xx (val >> 4) & 0b11;
            cpu.dma[0].irq = (val & 0x40) != 0;
            cpu.dma[0].enable = (val & 0x80) != 0;
            cpu.dma[0].control_int &= 0xff;
            cpu.dma[0].control_int |= (cast(u16)val) << 8;

            if cpu.dma[0].enable && cpu.dma[0].start_timing == .IMMED {
                while cpu.dma[0].enable transfer(0);
                cpu.dma[0].control_int &= 0x7fff;
            }
        case 0x0bc;
            cpu.dma[1].src &= 0x0fffff00;
            cpu.dma[1].src |= val;
            cpu.dma[1].src_int = cpu.dma[1].src;
        case 0x0bd;
            cpu.dma[1].src &= 0x0fff00ff;
            cpu.dma[1].src |= (cast(u32)val) << 8;
            cpu.dma[1].src_int = cpu.dma[1].src;
        case 0x0be;
            cpu.dma[1].src &= 0x0f00ffff;
            cpu.dma[1].src |= (cast(u32)val) << 16;
            cpu.dma[1].src_int = cpu.dma[1].src;
        case 0x0bf;
            cpu.dma[1].src &= 0x00ffffff;
            cpu.dma[1].src |= (cast(u32)val) << 24;
            cpu.dma[1].src_int = cpu.dma[1].src;
        case 0x0c0;
            cpu.dma[1].dst &= 0x0fffff00;
            cpu.dma[1].dst |= val;
            cpu.dma[1].dst_int = cpu.dma[1].dst;
        case 0x0c1;
            cpu.dma[1].dst &= 0x0fff00ff;
            cpu.dma[1].dst |= (cast(u32)val) << 8;
            cpu.dma[1].dst_int = cpu.dma[1].dst;
        case 0x0c2;
            cpu.dma[1].dst &= 0x0f00ffff;
            cpu.dma[1].dst |= (cast(u32)val) << 16;
            cpu.dma[1].dst_int = cpu.dma[1].dst;
        case 0x0c3;
            cpu.dma[1].dst &= 0x00ffffff;
            cpu.dma[1].dst |= (cast(u32)val) << 24;
            cpu.dma[1].dst_int = cpu.dma[1].dst;
        case 0x0c4;
            cpu.dma[1].count &= 0xff00;
            cpu.dma[1].count |= val;
            cpu.dma[1].count_int = ifx cpu.dma[1].count == 0 then 0x4000 else cpu.dma[1].count;
        case 0x0c5;
            cpu.dma[1].count &= 0x00ff;
            cpu.dma[1].count |= (cast(u16)val) << 8;
            cpu.dma[1].count_int = ifx cpu.dma[1].count == 0 then 0x4000 else cpu.dma[1].count;
        case 0x0c6;
            cpu.dma[1].dst_addr_control = xx (val >> 5) & 0b11;
            cpu.dma[1].src_addr_control &= 0b10;
            cpu.dma[1].src_addr_control |= xx (val >> 7) & 0b1;
            cpu.dma[1].control_int &= 0xff00;
            cpu.dma[1].control_int |= val;
        case 0x0c7;
            if !cpu.dma[1].enable && (val & 0x80) != 0 {
                cpu.dma[1].src_int = cpu.dma[1].src;
                cpu.dma[1].dst_int = cpu.dma[1].dst;
                cpu.dma[1].count_int = ifx cpu.dma[1].count == 0 then 0x4000 else cpu.dma[1].count;
            }

            cpu.dma[1].src_addr_control &= 0b01;
            cpu.dma[1].src_addr_control |= xx (val & 0b1) << 1;
            cpu.dma[1].repeat = (val & 0x2) != 0;
            cpu.dma[1].large_transfer = (val & 0x4) != 0;
            cpu.dma[1].game_pak = (val & 0x8) != 0;
            cpu.dma[1].start_timing = xx (val >> 4) & 0b11;
            cpu.dma[1].irq = (val & 0x40) != 0;
            cpu.dma[1].enable = (val & 0x80) != 0;
            cpu.dma[1].control_int &= 0xff;
            cpu.dma[1].control_int |= (cast(u16)val) << 8;

            if cpu.dma[1].enable && cpu.dma[1].start_timing == .IMMED {
                while cpu.dma[1].enable transfer(1);
                cpu.dma[1].control_int &= 0x7fff;
            }
        case 0x0c8;
            cpu.dma[2].src &= 0x0fffff00;
            cpu.dma[2].src |= val;
            cpu.dma[2].src_int = cpu.dma[2].src;
        case 0x0c9;
            cpu.dma[2].src &= 0x0fff00ff;
            cpu.dma[2].src |= (cast(u32)val) << 8;
            cpu.dma[2].src_int = cpu.dma[2].src;
        case 0x0ca;
            cpu.dma[2].src &= 0x0f00ffff;
            cpu.dma[2].src |= (cast(u32)val) << 16;
            cpu.dma[2].src_int = cpu.dma[2].src;
        case 0x0cb;
            cpu.dma[2].src &= 0x00ffffff;
            cpu.dma[2].src |= (cast(u32)val) << 24;
            cpu.dma[2].src_int = cpu.dma[2].src;
        case 0x0cc;
            cpu.dma[2].dst &= 0x0fffff00;
            cpu.dma[2].dst |= val;
            cpu.dma[2].dst_int = cpu.dma[2].dst;
        case 0x0cd;
            cpu.dma[2].dst &= 0x0fff00ff;
            cpu.dma[2].dst |= (cast(u32)val) << 8;
            cpu.dma[2].dst_int = cpu.dma[2].dst;
        case 0x0ce;
            cpu.dma[2].dst &= 0x0f00ffff;
            cpu.dma[2].dst |= (cast(u32)val) << 16;
            cpu.dma[2].dst_int = cpu.dma[2].dst;
        case 0x0cf;
            cpu.dma[2].dst &= 0x00ffffff;
            cpu.dma[2].dst |= (cast(u32)val) << 24;
            cpu.dma[2].dst_int = cpu.dma[2].dst;
        case 0x0d0;
            cpu.dma[2].count &= 0xff00;
            cpu.dma[2].count |= val;
            cpu.dma[2].count_int = ifx cpu.dma[2].count == 0 then 0x4000 else cpu.dma[2].count;
        case 0x0d1;
            cpu.dma[2].count &= 0x00ff;
            cpu.dma[2].count |= (cast(u16)val) << 8;
            cpu.dma[2].count_int = ifx cpu.dma[2].count == 0 then 0x4000 else cpu.dma[2].count;
        case 0x0d2;
            cpu.dma[2].dst_addr_control = xx (val >> 5) & 0b11;
            cpu.dma[2].src_addr_control &= 0b10;
            cpu.dma[2].src_addr_control |= xx (val >> 7) & 0b1;
            cpu.dma[2].control_int &= 0xff00;
            cpu.dma[2].control_int |= val;
        case 0x0d3;
            if !cpu.dma[2].enable && (val & 0x80) != 0 {
                cpu.dma[2].src_int = cpu.dma[2].src;
                cpu.dma[2].dst_int = cpu.dma[2].dst;
                cpu.dma[2].count_int = ifx cpu.dma[2].count == 0 then 0x4000 else cpu.dma[2].count;
            }

            cpu.dma[2].src_addr_control &= 0b01;
            cpu.dma[2].src_addr_control |= xx (val & 0b1) << 1;
            cpu.dma[2].repeat = (val & 0x2) != 0;
            cpu.dma[2].large_transfer = (val & 0x4) != 0;
            cpu.dma[2].game_pak = (val & 0x8) != 0;
            cpu.dma[2].start_timing = xx (val >> 4) & 0b11;
            cpu.dma[2].irq = (val & 0x40) != 0;
            cpu.dma[2].enable = (val & 0x80) != 0;
            cpu.dma[2].control_int &= 0xff;
            cpu.dma[2].control_int |= (cast(u16)val) << 8;

            if cpu.dma[2].enable && cpu.dma[2].start_timing == .IMMED {
                while cpu.dma[2].enable transfer(2);
                cpu.dma[2].control_int &= 0x7fff;
            }
        case 0x0d4;
            cpu.dma[3].src &= 0x0fffff00;
            cpu.dma[3].src |= val;
            cpu.dma[3].src_int = cpu.dma[3].src;
        case 0x0d5;
            cpu.dma[3].src &= 0x0fff00ff;
            cpu.dma[3].src |= (cast(u32)val) << 8;
            cpu.dma[3].src_int = cpu.dma[3].src;
        case 0x0d6;
            cpu.dma[3].src &= 0x0f00ffff;
            cpu.dma[3].src |= (cast(u32)val) << 16;
            cpu.dma[3].src_int = cpu.dma[3].src;
        case 0x0d7;
            cpu.dma[3].src &= 0x00ffffff;
            cpu.dma[3].src |= (cast(u32)val) << 24;
            cpu.dma[3].src_int = cpu.dma[3].src;
        case 0x0d8;
            cpu.dma[3].dst &= 0x0fffff00;
            cpu.dma[3].dst |= val;
            cpu.dma[3].dst_int = cpu.dma[3].dst;
        case 0x0d9;
            cpu.dma[3].dst &= 0x0fff00ff;
            cpu.dma[3].dst |= (cast(u32)val) << 8;
            cpu.dma[3].dst_int = cpu.dma[3].dst;
        case 0x0da;
            cpu.dma[3].dst &= 0x0f00ffff;
            cpu.dma[3].dst |= (cast(u32)val) << 16;
            cpu.dma[3].dst_int = cpu.dma[3].dst;
        case 0x0db;
            cpu.dma[3].dst &= 0x00ffffff;
            cpu.dma[3].dst |= (cast(u32)val) << 24;
            cpu.dma[3].dst_int = cpu.dma[3].dst;
        case 0x0dc;
            cpu.dma[3].count &= 0xff00;
            cpu.dma[3].count |= val;
            cpu.dma[3].count_int = ifx cpu.dma[3].count == 0 then 0x4000 else cpu.dma[3].count;
        case 0x0dd;
            cpu.dma[3].count &= 0x00ff;
            cpu.dma[3].count |= (cast(u16)val) << 8;
            cpu.dma[3].count_int = ifx cpu.dma[3].count == 0 then 0x4000 else cpu.dma[3].count;
        case 0x0de;
            cpu.dma[3].dst_addr_control = xx (val >> 5) & 0b11;
            cpu.dma[3].src_addr_control &= 0b10;
            cpu.dma[3].src_addr_control |= xx (val >> 7) & 0b1;
            cpu.dma[3].control_int &= 0xff00;
            cpu.dma[3].control_int |= val;
        case 0x0df;
            if !cpu.dma[3].enable && (val & 0x80) != 0 {
                cpu.dma[3].src_int = cpu.dma[3].src;
                cpu.dma[3].dst_int = cpu.dma[3].dst;
                cpu.dma[3].count_int = ifx cpu.dma[3].count == 0 then 0x4000 else cpu.dma[3].count;
            }

            cpu.dma[3].src_addr_control &= 0b01;
            cpu.dma[3].src_addr_control |= xx (val & 0b1) << 1;
            cpu.dma[3].repeat = (val & 0x2) != 0;
            cpu.dma[3].large_transfer = (val & 0x4) != 0;
            cpu.dma[3].game_pak = (val & 0x8) != 0;
            cpu.dma[3].start_timing = xx (val >> 4) & 0b11;
            cpu.dma[3].irq = (val & 0x40) != 0;
            cpu.dma[3].enable = (val & 0x80) != 0;
            cpu.dma[3].control_int &= 0xff;
            cpu.dma[3].control_int |= (cast(u16)val) << 8;

            if cpu.dma[3].enable && cpu.dma[3].start_timing == .IMMED {
                while cpu.dma[3].enable transfer(3);
                cpu.dma[3].control_int &= 0x7fff;
            }
        case 0x100;
            cpu.timer[0].reload &= 0xff00;
            cpu.timer[0].reload |= val;
        case 0x101;
            cpu.timer[0].reload &= 0x00ff;
            cpu.timer[0].reload |= (cast(u16)val) << 8;
        case 0x102;
            cpu.timer[0].prescaler_selection = val & 0b11;
            cpu.timer[0].ignore_prescaler = (val & 0x4) != 0;
            cpu.timer[0].irq = (val & 0x40) != 0;
            old_enable := cpu.timer[0].enable;
            cpu.timer[0].enable = (val & 0x80) != 0;
            if old_enable != cpu.timer[0].enable {
                cpu.timer[0].counter = cpu.timer[0].reload;
            }
        case 0x103; // not used
        case 0x104;
            cpu.timer[1].reload &= 0xff00;
            cpu.timer[1].reload |= val;
        case 0x105;
            cpu.timer[1].reload &= 0x00ff;
            cpu.timer[1].reload |= (cast(u16)val) << 8;
        case 0x106;
            cpu.timer[1].prescaler_selection = val & 0b11;
            cpu.timer[1].ignore_prescaler = (val & 0x4) != 0;
            cpu.timer[1].irq = (val & 0x40) != 0;
            old_enable := cpu.timer[1].enable;
            cpu.timer[1].enable = (val & 0x80) != 0;
            if old_enable != cpu.timer[1].enable {
                cpu.timer[1].counter = cpu.timer[1].reload;
            }
        case 0x107; // not used
        case 0x108;
            cpu.timer[2].reload &= 0xff00;
            cpu.timer[2].reload |= val;
        case 0x109;
            cpu.timer[2].reload &= 0x00ff;
            cpu.timer[2].reload |= (cast(u16)val) << 8;
        case 0x10a;
            cpu.timer[2].prescaler_selection = val & 0b11;
            cpu.timer[2].ignore_prescaler = (val & 0x4) != 0;
            cpu.timer[2].irq = (val & 0x40) != 0;
            old_enable := cpu.timer[2].enable;
            cpu.timer[2].enable = (val & 0x80) != 0;
            if old_enable != cpu.timer[2].enable {
                cpu.timer[2].counter = cpu.timer[2].reload;
            }
        case 0x10b; // not used
        case 0x10c;
            cpu.timer[3].reload &= 0xff00;
            cpu.timer[3].reload |= val;
        case 0x10d;
            cpu.timer[3].reload &= 0x00ff;
            cpu.timer[3].reload |= (cast(u16)val) << 8;
        case 0x10e;
            cpu.timer[3].prescaler_selection = val & 0b11;
            cpu.timer[3].ignore_prescaler = (val & 0x4) != 0;
            cpu.timer[3].irq = (val & 0x40) != 0;
            old_enable := cpu.timer[3].enable;
            cpu.timer[3].enable = (val & 0x80) != 0;
            if old_enable != cpu.timer[3].enable {
                cpu.timer[3].counter = cpu.timer[3].reload;
            }
        case 0x10f; // not used
        case 0x132;
            ppu.keypad_irq_mask &= 0x300;
            ppu.keypad_irq_mask |= val;
        case 0x133;
            ppu.keypad_irq_mask &= 0x0ff;
            ppu.keypad_irq_mask |= (cast(u16)(val & 0b11)) << 8;
            ppu.keypad_irq = (val & 0x40) != 0;
            ppu.keypad_irq_require_all = (val & 0x80) != 0;
        case 0x200;
            cpu.ie[Interrupt_Source.LCD_VBLANK] = (val & 0x01);
            cpu.ie[Interrupt_Source.LCD_HBLANK] = (val & 0x02);
            cpu.ie[Interrupt_Source.LCD_VCOUNTER] = (val & 0x04);
            cpu.ie[Interrupt_Source.TIM0OVERFLOW] = (val & 0x08);
            cpu.ie[Interrupt_Source.TIM1OVERFLOW] = (val & 0x10);
            cpu.ie[Interrupt_Source.TIM2OVERFLOW] = (val & 0x20);
            cpu.ie[Interrupt_Source.TIM3OVERFLOW] = (val & 0x40);
            cpu.ie[Interrupt_Source.SERIAL] = (val & 0x80);
        case 0x201;
            cpu.ie[Interrupt_Source.DMA0] = (val & 0x01);
            cpu.ie[Interrupt_Source.DMA1] = (val & 0x02);
            cpu.ie[Interrupt_Source.DMA2] = (val & 0x04);
            cpu.ie[Interrupt_Source.DMA3] = (val & 0x08);
            cpu.ie[Interrupt_Source.KEYPAD] = (val & 0x10);
            cpu.ie[Interrupt_Source.GAMEPAK] = (val & 0x20);
        case 0x202;
            if (val & 0x01) != 0 then cpu.ifl[Interrupt_Source.LCD_VBLANK] = 0;
            if (val & 0x02) != 0 then cpu.ifl[Interrupt_Source.LCD_HBLANK] = 0;
            if (val & 0x04) != 0 then cpu.ifl[Interrupt_Source.LCD_VCOUNTER] = 0;
            if (val & 0x08) != 0 then cpu.ifl[Interrupt_Source.TIM0OVERFLOW] = 0;
            if (val & 0x10) != 0 then cpu.ifl[Interrupt_Source.TIM1OVERFLOW] = 0;
            if (val & 0x20) != 0 then cpu.ifl[Interrupt_Source.TIM2OVERFLOW] = 0;
            if (val & 0x40) != 0 then cpu.ifl[Interrupt_Source.TIM3OVERFLOW] = 0;
            if (val & 0x80) != 0 then cpu.ifl[Interrupt_Source.SERIAL] = 0;
        case 0x203;
            if (val & 0x01) != 0 then cpu.ifl[Interrupt_Source.DMA0] = 0;
            if (val & 0x02) != 0 then cpu.ifl[Interrupt_Source.DMA1] = 0;
            if (val & 0x04) != 0 then cpu.ifl[Interrupt_Source.DMA2] = 0;
            if (val & 0x08) != 0 then cpu.ifl[Interrupt_Source.DMA3] = 0;
            if (val & 0x10) != 0 then cpu.ifl[Interrupt_Source.KEYPAD] = 0;
            if (val & 0x20) != 0 then cpu.ifl[Interrupt_Source.GAMEPAK] = 0;
        case 0x204;
            cpu.waitcnt_lo = val;
        case 0x205;
            cpu.waitcnt_hi = val;
        case 0x206;
        case 0x207;
        // WAITCNT
        // not really all that important
        case 0x208;
            cpu.interrupt_master_enable = (val & 1) != 0;
        case 0x209;
        case 0x20a;
        case 0x20b;
        case 0x301;
            cpu.halted = (val & 0x80) == 0;
            cpu.stopped = (val & 0x80) != 0;
        case;
        log_warn("Unmapped IO write: 0x%, 0x%", formatInt(addr, 16), formatInt(val, 16));
    }
}

oam_update :: (addr: u32) {
    offset := addr % 0x400;
    if (offset % 8 > 5) {
        lower : u16 = xx ppu.memory.oam._8[(offset & 0x3f8) + 6];
        upper : u16 = xx ppu.memory.oam._8[(offset & 0x3f8) + 7];
        if offset % 32 == {
            case 6;
            #through;
            case 7;
            ppu.oam_param[offset / 32].pa = xx cast,force(s8)upper;
            ppu.oam_param[offset / 32].pa += xx lower / 256.0;
            case 14;
            #through;
            case 15;
            ppu.oam_param[offset / 32].pb = xx cast,force(s8)upper;
            ppu.oam_param[offset / 32].pb += xx lower / 256.0;
            case 22;
            #through;
            case 23;
            ppu.oam_param[offset / 32].pc = xx cast,force(s8)upper;
            ppu.oam_param[offset / 32].pc += xx lower / 256.0;
            case 30;
            #through;
            case 31;
            ppu.oam_param[offset / 32].pd = xx cast,force(s8)upper;
            ppu.oam_param[offset / 32].pd += xx lower / 256.0;
            case;
            assert(false);
        }
    } else {
        val := ppu.memory.oam._8[offset];
        if offset % 8 == {
            case 0;
            ppu.oam[offset / 8].y = val;
            case 1;
            ppu.oam[offset / 8].rotate_scale = (val & 0x1) != 0;
            ppu.oam[offset / 8].rotate_scale_double_size = (val & 0x2) != 0;
            ppu.oam[offset / 8].mode = (val >> 2) & 0b11;
            ppu.oam[offset / 8].mosaic = (val & 0x10) != 0;
            ppu.oam[offset / 8].single_palette = (val & 0x20) != 0;
            ppu.oam[offset / 8].shape = (val >> 6) & 0b11;
            case 2;
            ppu.oam[offset / 8].x &= 0x100;
            ppu.oam[offset / 8].x |= val;
            case 3;
            ppu.oam[offset / 8].x &= 0xff;
            if (val & 0x1) != 0 then ppu.oam[offset / 8].x |= 0x100;
            ppu.oam[offset / 8].rotate_scale_param_idx = (val >> 1) & 0x1f;
            ppu.oam[offset / 8].flip_h = (val & 0x10) != 0;
            ppu.oam[offset / 8].flip_v = (val & 0x20) != 0;
            ppu.oam[offset / 8].size = (val >> 6) & 0b11;
            case 4;
            ppu.oam[offset / 8].tile_idx &= 0x300;
            ppu.oam[offset / 8].tile_idx |= val;
            case 5;
            ppu.oam[offset / 8].tile_idx &= 0xff;
            ppu.oam[offset / 8].tile_idx |= ((cast(u16)val & 0x3) << 8);
            ppu.oam[offset / 8].prio = (val >> 2) & 0b11;
            ppu.oam[offset / 8].palette = (val >> 4) & 0xf;
        }
    }

    for 0..127 oam_update_bounding_box(xx it);
}

oam_update_bounding_box :: (idx: u32) {
    if ppu.oam[idx].shape == {
        case 0;
            size_lut :: int.[8, 16, 32, 64];
            ppu.oam[idx].width = size_lut[ppu.oam[idx].size];
            ppu.oam[idx].height = size_lut[ppu.oam[idx].size];
        case 1;
            width_lut :: int.[16, 32, 32, 64];
            height_lut :: int.[8, 8, 16, 32];
            ppu.oam[idx].width = width_lut[ppu.oam[idx].size];
            ppu.oam[idx].height = height_lut[ppu.oam[idx].size];
        case 2;
            width_lut :: int.[8, 8, 16, 32];
            height_lut :: int.[16, 32, 32, 64];
            ppu.oam[idx].width = width_lut[ppu.oam[idx].size];
            ppu.oam[idx].height = height_lut[ppu.oam[idx].size];
        case;
            ppu.oam[idx].width = 0;
            ppu.oam[idx].height = 0;
    }

    ppu.oam[idx].min_x = ppu.oam[idx].x;
    ppu.oam[idx].max_x = ppu.oam[idx].x + ppu.oam[idx].width;
    ppu.oam[idx].min_y = ppu.oam[idx].y;
    ppu.oam[idx].max_y = ppu.oam[idx].y + ppu.oam[idx].height;
    while ppu.oam[idx].max_y >= 256 {
        ppu.oam[idx].min_y -= 256;
        ppu.oam[idx].max_y -= 256;
    }
    while ppu.oam[idx].max_x >= 512 {
        ppu.oam[idx].min_x -= 512;
        ppu.oam[idx].max_x -= 512;
    }
    if ppu.oam[idx].rotate_scale && ppu.oam[idx].rotate_scale_double_size {
        ppu.oam[idx].bounding_box_min_x = ppu.oam[idx].min_x;
        ppu.oam[idx].bounding_box_max_x = xx (ppu.oam[idx].min_x + ppu.oam[idx].width * 2);
        ppu.oam[idx].bounding_box_min_y = ppu.oam[idx].min_y;
        ppu.oam[idx].bounding_box_max_y = xx (ppu.oam[idx].min_y + ppu.oam[idx].height * 2);
    } else {
        ppu.oam[idx].bounding_box_min_x = ppu.oam[idx].min_x;
        ppu.oam[idx].bounding_box_max_x = ppu.oam[idx].max_x;
        ppu.oam[idx].bounding_box_min_y = ppu.oam[idx].min_y;
        ppu.oam[idx].bounding_box_max_y = ppu.oam[idx].max_y;
    }
}
