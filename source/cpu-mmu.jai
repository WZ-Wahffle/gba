mmu_read :: (addr: u32) -> u8 {
    if addr >= 0x08000000 && addr < 0x0e000000 {
        return cpu.memory.rom[addr % cpu.memory.rom.count];
    }

    else if addr < 0x4000 {
        return cpu.memory.bios[addr];
    }

    else if addr >= 0x02000000 && addr < 0x03000000 {
        return cpu.memory.ewram[addr % 0x40000];
    }

    else if addr >= 0x03000000 && addr < 0x04000000 {
        return cpu.memory.iwram[addr % 0x8000];
    }

    else if addr >= 0x04000000 && addr < 0x04000400 {
        if addr - 0x04000000 == {
            case 0x130;
            return xx ppu.keypad_state & 0xff;
            case 0x131;
            return xx ppu.keypad_state >> 8;
            case 0x300;
            return 0;
            case;
            log_warn("Unmapped IO read: 0x%", formatInt(addr, 16));
            return 0;
            // assert(false);
        }
    }

    else if addr >= 0x05000000 && addr < 0x06000000 {
        return ppu.palette_ram[addr % 0x400];
    }

    else if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            return ppu.vram[addr % 0x18000];
        } else {
            return ppu.vram[(addr % 0x8000) + 0x10000];
        }
    }

    else if addr >= 0x07000000 && addr < 0x08000000 {
        return ppu.oam[addr % 0x400];
    }

    else {
        print("0x%: 0x%\n", formatInt(cpu.pc, 16), formatInt(addr, 16));
        assert(false);
    }
    return 0;
}

mmu_write :: (addr: u32, val: u8) {
    if addr >= 0x02000000 && addr < 0x03000000 {
        cpu.memory.ewram[addr % 0x40000] = val;
    }

    else if addr >= 0x03000000 && addr < 0x04000000 {
        cpu.memory.iwram[addr % 0x8000] = val;
    }

    else if addr >= 0x04000000 && addr < 0x04000400 {
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
                ppu.bg[0].more_colors = (val & 0x80) != 0;
            case 0x009;
                ppu.bg[0].screen_base_block = val & 0x1f;
                ppu.bg[0].wraparound = (val & 0x20) != 0;
                ppu.bg[0].size = (val >> 6) & 0b11;
            case 0x00a;
                ppu.bg[1].prio = val & 0b11;
                ppu.bg[1].char_base_block = (val >> 2) & 0b11;
                ppu.bg[1].mosaic = (val & 0x40) != 0;
                ppu.bg[1].more_colors = (val & 0x80) != 0;
            case 0x00b;
                ppu.bg[1].screen_base_block = val & 0x1f;
                ppu.bg[1].wraparound = (val & 0x20) != 0;
                ppu.bg[1].size = (val >> 6) & 0b11;
            case 0x00c;
                ppu.bg[2].prio = val & 0b11;
                ppu.bg[2].char_base_block = (val >> 2) & 0b11;
                ppu.bg[2].mosaic = (val & 0x40) != 0;
                ppu.bg[2].more_colors = (val & 0x80) != 0;
            case 0x00d;
                ppu.bg[2].screen_base_block = val & 0x1f;
                ppu.bg[2].wraparound = (val & 0x20) != 0;
                ppu.bg[2].size = (val >> 6) & 0b11;
            case 0x00e;
                ppu.bg[3].prio = val & 0b11;
                ppu.bg[3].char_base_block = (val >> 2) & 0b11;
                ppu.bg[3].mosaic = (val & 0x40) != 0;
                ppu.bg[3].more_colors = (val & 0x80) != 0;
            case 0x00f;
                ppu.bg[3].screen_base_block = val & 0x1f;
                ppu.bg[3].wraparound = (val & 0x20) != 0;
                ppu.bg[3].size = (val >> 6) & 0b11;
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
            case 0x021;
                ppu.bg[2].dx &= 0x00ff;
                ppu.bg[2].dx |= (cast(u16)val) << 8;
            case 0x022;
                ppu.bg[2].dmx &= 0xff00;
                ppu.bg[2].dmx |= val;
            case 0x023;
                ppu.bg[2].dmx &= 0x00ff;
                ppu.bg[2].dmx |= (cast(u16)val) << 8;
            case 0x024;
                ppu.bg[2].dy &= 0xff00;
                ppu.bg[2].dy |= val;
            case 0x025;
                ppu.bg[2].dy &= 0x00ff;
                ppu.bg[2].dy |= (cast(u16)val) << 8;
            case 0x026;
                ppu.bg[2].dmy &= 0xff00;
                ppu.bg[2].dmy |= val;
            case 0x027;
                ppu.bg[2].dmy &= 0x00ff;
                ppu.bg[2].dmy |= (cast(u16)val) << 8;
            case 0x028;
                ppu.bg[2].anchor_x &= 0x0fffff00;
                ppu.bg[2].anchor_x |= val;
            case 0x029;
                ppu.bg[2].anchor_x &= 0x0fff00ff;
                ppu.bg[2].anchor_x |= (cast(u32)val) << 8;
            case 0x02a;
                ppu.bg[2].anchor_x &= 0x0f00ffff;
                ppu.bg[2].anchor_x |= (cast(u32)val) << 16;
            case 0x02b;
                ppu.bg[2].anchor_x &= 0x00ffffff;
                ppu.bg[2].anchor_x |= (cast(u32)val & 0xf) << 24;
            case 0x02c;
                ppu.bg[2].anchor_y &= 0x0fffff00;
                ppu.bg[2].anchor_y |= val;
            case 0x02d;
                ppu.bg[2].anchor_y &= 0x0fff00ff;
                ppu.bg[2].anchor_y |= (cast(u32)val) << 8;
            case 0x02e;
                ppu.bg[2].anchor_y &= 0x0f00ffff;
                ppu.bg[2].anchor_y |= (cast(u32)val) << 16;
            case 0x02f;
                ppu.bg[2].anchor_y &= 0x00ffffff;
                ppu.bg[2].anchor_y |= (cast(u32)val & 0xf) << 24;
            case 0x030;
                ppu.bg[3].dx &= 0xff00;
                ppu.bg[3].dx |= val;
            case 0x031;
                ppu.bg[3].dx &= 0x00ff;
                ppu.bg[3].dx |= (cast(u16)val) << 8;
            case 0x032;
                ppu.bg[3].dmx &= 0xff00;
                ppu.bg[3].dmx |= val;
            case 0x033;
                ppu.bg[3].dmx &= 0x00ff;
                ppu.bg[3].dmx |= (cast(u16)val) << 8;
            case 0x034;
                ppu.bg[3].dy &= 0xff00;
                ppu.bg[3].dy |= val;
            case 0x035;
                ppu.bg[3].dy &= 0x00ff;
                ppu.bg[3].dy |= (cast(u16)val) << 8;
            case 0x036;
                ppu.bg[3].dmy &= 0xff00;
                ppu.bg[3].dmy |= val;
            case 0x037;
                ppu.bg[3].dmy &= 0x00ff;
                ppu.bg[3].dmy |= (cast(u16)val) << 8;
            case 0x038;
                ppu.bg[3].anchor_x &= 0x0fffff00;
                ppu.bg[3].anchor_x |= val;
            case 0x039;
                ppu.bg[3].anchor_x &= 0x0fff00ff;
                ppu.bg[3].anchor_x |= (cast(u32)val) << 8;
            case 0x03a;
                ppu.bg[3].anchor_x &= 0x0f00ffff;
                ppu.bg[3].anchor_x |= (cast(u32)val) << 16;
            case 0x03b;
                ppu.bg[3].anchor_x &= 0x00ffffff;
                ppu.bg[3].anchor_x |= (cast(u32)val & 0xf) << 24;
            case 0x03c;
                ppu.bg[3].anchor_y &= 0x0fffff00;
                ppu.bg[3].anchor_y |= val;
            case 0x03d;
                ppu.bg[3].anchor_y &= 0x0fff00ff;
                ppu.bg[3].anchor_y |= (cast(u32)val) << 8;
            case 0x03e;
                ppu.bg[3].anchor_y &= 0x0f00ffff;
                ppu.bg[3].anchor_y |= (cast(u32)val) << 16;
            case 0x03f;
                ppu.bg[3].anchor_y &= 0x00ffffff;
                ppu.bg[3].anchor_y |= (cast(u32)val & 0xf) << 24;
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
            case 0x0bb;
                cpu.dma[0].src_addr_control &= 0b01;
                cpu.dma[0].src_addr_control |= xx (val & 0b1) << 1;
                cpu.dma[0].repeat = (val & 0x2) != 0;
                cpu.dma[0].large_transfer = (val & 0x4) != 0;
                cpu.dma[0].game_pak = (val & 0x8) != 0;
                cpu.dma[0].start_timing = xx (val >> 4) & 0b11;
                cpu.dma[0].irq = (val & 0x40) != 0;
                cpu.dma[0].enable = (val & 0x80) != 0;
            case 0x0bc;
                cpu.dma[1].src &= 0x0fffff00;
                cpu.dma[1].src |= val;
            case 0x0bd;
                cpu.dma[1].src &= 0x0fff00ff;
                cpu.dma[1].src |= (cast(u32)val) << 8;
            case 0x0be;
                cpu.dma[1].src &= 0x0f00ffff;
                cpu.dma[1].src |= (cast(u32)val) << 16;
            case 0x0bf;
                cpu.dma[1].src &= 0x00ffffff;
                cpu.dma[1].src |= (cast(u32)val) << 24;
            case 0x0c0;
                cpu.dma[1].dst &= 0x0fffff00;
                cpu.dma[1].dst |= val;
            case 0x0c1;
                cpu.dma[1].dst &= 0x0fff00ff;
                cpu.dma[1].dst |= (cast(u32)val) << 8;
            case 0x0c2;
                cpu.dma[1].dst &= 0x0f00ffff;
                cpu.dma[1].dst |= (cast(u32)val) << 16;
            case 0x0c3;
                cpu.dma[1].dst &= 0x00ffffff;
                cpu.dma[1].dst |= (cast(u32)val) << 24;
            case 0x0c4;
                cpu.dma[1].count &= 0xff00;
                cpu.dma[1].count |= val;
            case 0x0c5;
                cpu.dma[1].count &= 0x00ff;
                cpu.dma[1].count |= (cast(u16)val) << 8;
            case 0x0c6;
                cpu.dma[1].dst_addr_control = xx (val >> 5) & 0b11;
                cpu.dma[1].src_addr_control &= 0b10;
                cpu.dma[1].src_addr_control |= xx (val >> 7) & 0b1;
            case 0x0c7;
                cpu.dma[1].src_addr_control &= 0b01;
                cpu.dma[1].src_addr_control |= xx (val & 0b1) << 1;
                cpu.dma[1].repeat = (val & 0x2) != 0;
                cpu.dma[1].large_transfer = (val & 0x4) != 0;
                cpu.dma[1].game_pak = (val & 0x8) != 0;
                cpu.dma[1].start_timing = xx (val >> 4) & 0b11;
                cpu.dma[1].irq = (val & 0x40) != 0;
                cpu.dma[1].enable = (val & 0x80) != 0;
            case 0x0c8;
                cpu.dma[2].src &= 0x0fffff00;
                cpu.dma[2].src |= val;
            case 0x0c9;
                cpu.dma[2].src &= 0x0fff00ff;
                cpu.dma[2].src |= (cast(u32)val) << 8;
            case 0x0ca;
                cpu.dma[2].src &= 0x0f00ffff;
                cpu.dma[2].src |= (cast(u32)val) << 16;
            case 0x0cb;
                cpu.dma[2].src &= 0x00ffffff;
                cpu.dma[2].src |= (cast(u32)val) << 24;
            case 0x0cc;
                cpu.dma[2].dst &= 0x0fffff00;
                cpu.dma[2].dst |= val;
            case 0x0cd;
                cpu.dma[2].dst &= 0x0fff00ff;
                cpu.dma[2].dst |= (cast(u32)val) << 8;
            case 0x0ce;
                cpu.dma[2].dst &= 0x0f00ffff;
                cpu.dma[2].dst |= (cast(u32)val) << 16;
            case 0x0cf;
                cpu.dma[2].dst &= 0x00ffffff;
                cpu.dma[2].dst |= (cast(u32)val) << 24;
            case 0x0d0;
                cpu.dma[2].count &= 0xff00;
                cpu.dma[2].count |= val;
            case 0x0d1;
                cpu.dma[2].count &= 0x00ff;
                cpu.dma[2].count |= (cast(u16)val) << 8;
            case 0x0d2;
                cpu.dma[2].dst_addr_control = xx (val >> 5) & 0b11;
                cpu.dma[2].src_addr_control &= 0b10;
                cpu.dma[2].src_addr_control |= xx (val >> 7) & 0b1;
            case 0x0d3;
                cpu.dma[2].src_addr_control &= 0b01;
                cpu.dma[2].src_addr_control |= xx (val & 0b1) << 1;
                cpu.dma[2].repeat = (val & 0x2) != 0;
                cpu.dma[2].large_transfer = (val & 0x4) != 0;
                cpu.dma[2].game_pak = (val & 0x8) != 0;
                cpu.dma[2].start_timing = xx (val >> 4) & 0b11;
                cpu.dma[2].irq = (val & 0x40) != 0;
                cpu.dma[2].enable = (val & 0x80) != 0;
            case 0x0d4;
                cpu.dma[3].src &= 0x0fffff00;
                cpu.dma[3].src |= val;
            case 0x0d5;
                cpu.dma[3].src &= 0x0fff00ff;
                cpu.dma[3].src |= (cast(u32)val) << 8;
            case 0x0d6;
                cpu.dma[3].src &= 0x0f00ffff;
                cpu.dma[3].src |= (cast(u32)val) << 16;
            case 0x0d7;
                cpu.dma[3].src &= 0x00ffffff;
                cpu.dma[3].src |= (cast(u32)val) << 24;
            case 0x0d8;
                cpu.dma[3].dst &= 0x0fffff00;
                cpu.dma[3].dst |= val;
            case 0x0d9;
                cpu.dma[3].dst &= 0x0fff00ff;
                cpu.dma[3].dst |= (cast(u32)val) << 8;
            case 0x0da;
                cpu.dma[3].dst &= 0x0f00ffff;
                cpu.dma[3].dst |= (cast(u32)val) << 16;
            case 0x0db;
                cpu.dma[3].dst &= 0x00ffffff;
                cpu.dma[3].dst |= (cast(u32)val) << 24;
            case 0x0dc;
                cpu.dma[3].count &= 0xff00;
                cpu.dma[3].count |= val;
            case 0x0dd;
                cpu.dma[3].count &= 0x00ff;
                cpu.dma[3].count |= (cast(u16)val) << 8;
            case 0x0de;
                cpu.dma[3].dst_addr_control = xx (val >> 5) & 0b11;
                cpu.dma[3].src_addr_control &= 0b10;
                cpu.dma[3].src_addr_control |= xx (val >> 7) & 0b1;
            case 0x0df;
                cpu.dma[3].src_addr_control &= 0b01;
                cpu.dma[3].src_addr_control |= xx (val & 0b1) << 1;
                cpu.dma[3].repeat = (val & 0x2) != 0;
                cpu.dma[3].large_transfer = (val & 0x4) != 0;
                cpu.dma[3].game_pak = (val & 0x8) != 0;
                cpu.dma[3].start_timing = xx (val >> 4) & 0b11;
                cpu.dma[3].irq = (val & 0x40) != 0;
                cpu.dma[3].enable = (val & 0x80) != 0;
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
                cpu.timer[0].enable = (val & 0x80) != 0;
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
                cpu.timer[1].enable = (val & 0x80) != 0;
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
                cpu.timer[2].enable = (val & 0x80) != 0;
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
                cpu.timer[3].enable = (val & 0x80) != 0;
            case 0x10f; // not used
            case 0x200;
                cpu.ie[Interrupt_Source.LCD_VBLANK] = (val & 0x01) != 0;
                cpu.ie[Interrupt_Source.LCD_HBLANK] = (val & 0x02) != 0;
                cpu.ie[Interrupt_Source.LCD_VCOUNTER] = (val & 0x04) != 0;
                cpu.ie[Interrupt_Source.TIM0OVERFLOW] = (val & 0x08) != 0;
                cpu.ie[Interrupt_Source.TIM1OVERFLOW] = (val & 0x10) != 0;
                cpu.ie[Interrupt_Source.TIM2OVERFLOW] = (val & 0x20) != 0;
                cpu.ie[Interrupt_Source.TIM3OVERFLOW] = (val & 0x40) != 0;
                cpu.ie[Interrupt_Source.SERIAL] = (val & 0x80) != 0;
            case 0x201;
                cpu.ie[Interrupt_Source.DMA0] = (val & 0x01) != 0;
                cpu.ie[Interrupt_Source.DMA1] = (val & 0x02) != 0;
                cpu.ie[Interrupt_Source.DMA2] = (val & 0x04) != 0;
                cpu.ie[Interrupt_Source.DMA3] = (val & 0x08) != 0;
                cpu.ie[Interrupt_Source.KEYPAD] = (val & 0x10) != 0;
                cpu.ie[Interrupt_Source.GAMEPAK] = (val & 0x20) != 0;
            case 0x202;
                if (val & 0x01) != 0 then cpu.ifl[Interrupt_Source.LCD_VBLANK] = false;
                if (val & 0x02) != 0 then cpu.ifl[Interrupt_Source.LCD_HBLANK] = false;
                if (val & 0x04) != 0 then cpu.ifl[Interrupt_Source.LCD_VCOUNTER] = false;
                if (val & 0x08) != 0 then cpu.ifl[Interrupt_Source.TIM0OVERFLOW] = false;
                if (val & 0x10) != 0 then cpu.ifl[Interrupt_Source.TIM1OVERFLOW] = false;
                if (val & 0x20) != 0 then cpu.ifl[Interrupt_Source.TIM2OVERFLOW] = false;
                if (val & 0x40) != 0 then cpu.ifl[Interrupt_Source.TIM3OVERFLOW] = false;
                if (val & 0x80) != 0 then cpu.ifl[Interrupt_Source.SERIAL] = false;
            case 0x203;
                if (val & 0x01) != 0 then cpu.ifl[Interrupt_Source.DMA0] = false;
                if (val & 0x02) != 0 then cpu.ifl[Interrupt_Source.DMA1] = false;
                if (val & 0x04) != 0 then cpu.ifl[Interrupt_Source.DMA2] = false;
                if (val & 0x08) != 0 then cpu.ifl[Interrupt_Source.DMA3] = false;
                if (val & 0x10) != 0 then cpu.ifl[Interrupt_Source.KEYPAD] = false;
                if (val & 0x20) != 0 then cpu.ifl[Interrupt_Source.GAMEPAK] = false;
            case 0x204;
            case 0x205;
            case 0x206;
            case 0x207;
            // WAITCNT
            // not really all that important
            case 0x208;
                cpu.interrupt_master_enable = (val & 1) != 0;
            case 0x209;
            case 0x20a;
            case 0x20b;
            case;
            log_warn("Unmapped IO write: 0x%", formatInt(addr, 16));
        }
    }

    else if addr >= 0x05000000 && addr < 0x06000000 {
        ppu.palette_ram[addr % 0x400] = val;
    }

    else if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            ppu.vram[addr % 0x18000] = val;
        } else {
            ppu.vram[(addr % 0x8000) + 0x10000] = val;
        }
    }

    else if addr >= 0x07000000 && addr < 0x08000000 {
        ppu.oam[addr % 0x400] = val;
    }

    else {
        log_warn("Unmapped write: 0x%", formatInt(addr, 16));
    }
}
