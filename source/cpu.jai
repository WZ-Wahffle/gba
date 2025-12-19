// the read and write functions are all very similar in composition,
// however have been split up in order to increase performance

read_8 :: (addr: u32, bios_bypass := false) -> u8 {
    if addr < 0x4000 {
        if bios_bypass return cpu.memory.bios._8[addr];
        return 0;
    }
    if addr >= 0x02000000 && addr < 0x02040000 {
        return cpu.memory.ewram._8[addr % 0x40000];
    }
    if addr >= 0x03000000 && addr < 0x04000000 {
        return cpu.memory.iwram._8[addr % 0x8000];
    }
    if addr >= 0x04000000 && addr < 0x04000400 {
        return mmio_read(addr);
    }
    if addr >= 0x05000000 && addr < 0x06000000 {
        return ppu.memory.palette_ram._8[addr % 0x400];
    }
    if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            return ppu.memory.vram._8[addr % 0x18000];
        } else {
            return ppu.memory.vram._8[(addr % 0x8000) + 0x10000];
        }
    }
    if addr >= 0x07000000 && addr < 0x08000000 {
        return ppu.memory.oam._8[addr % 0x400];
    }
    if addr >= 0x08000000 {
        return rom_read(addr);
    }

    log_warn("Unmapped read: 0x%", formatInt(addr, 16));
    return 0;
}

read_16 :: (addr: u32, bios_bypass := false) -> u16 {
    if addr < 0x4000 {
        if bios_bypass return cpu.memory.bios._16[addr >> 1];
        return 0;
    }
    if addr >= 0x02000000 && addr < 0x02040000 {
        return cpu.memory.ewram._16[(addr >> 1) % 0x20000];
    }
    if addr >= 0x03000000 && addr < 0x04000000 {
        return cpu.memory.iwram._16[(addr >> 1) % 0x4000];
    }
    if addr >= 0x04000000 && addr < 0x04000400 {
        first : u16 = mmio_read((addr & 0xfffffffe));
        second : u16 = mmio_read((addr & 0xfffffffe) + 1);
        return first | (second << 8);
    }
    if addr >= 0x05000000 && addr < 0x06000000 {
        return ppu.memory.palette_ram._16[(addr >> 1) % 0x200];
    }
    if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            return ppu.memory.vram._16[(addr >> 1) % 0xc000];
        } else {
            return ppu.memory.vram._16[((addr >> 1) % 0x4000) + 0x8000];
        }
    }
    if addr >= 0x07000000 && addr < 0x08000000 {
        return ppu.memory.oam._16[(addr >> 1) % 0x200];
    }
    if addr >= 0x08000000 {
        first : u16 = rom_read((addr & 0xfffffffe));
        second : u16 = rom_read((addr & 0xfffffffe) + 1);
        return first | (second << 8);
    }

    log_warn("Unmapped read: 0x%", formatInt(addr, 16));
    return 0;
}

read_32 :: (addr: u32, bios_bypass := false) -> u32 {
    if addr < 0x4000 {
        if bios_bypass return cpu.memory.bios._32[addr >> 2];
        return 0;
    }
    if addr >= 0x02000000 && addr < 0x02040000 {
        return cpu.memory.ewram._32[(addr >> 2) % 0x10000];
    }
    if addr >= 0x03000000 && addr < 0x04000000 {
        return cpu.memory.iwram._32[(addr >> 2) % 0x2000];
    }
    if addr >= 0x04000000 && addr < 0x04000400 {
        first : u32 = mmio_read((addr & 0xfffffffc));
        second : u32 = mmio_read((addr & 0xfffffffc) + 1);
        third : u32 = mmio_read((addr & 0xfffffffc) + 2);
        fourth : u32 = mmio_read((addr & 0xfffffffc) + 3);
        return first | (second << 8) | (third << 16) | (fourth << 24);
    }
    if addr >= 0x05000000 && addr < 0x06000000 {
        return ppu.memory.palette_ram._32[(addr >> 2) % 0x100];
    }
    if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            return ppu.memory.vram._32[(addr >> 2) % 0x6000];
        } else {
            return ppu.memory.vram._32[((addr >> 2) % 0x2000) + 0x4000];
        }
    }
    if addr >= 0x07000000 && addr < 0x08000000 {
        return ppu.memory.oam._32[(addr >> 2) % 0x100];
    }
    if addr >= 0x08000000 && addr < 0x0e000000 {
        first : u32 = rom_read((addr & 0xfffffffc));
        second : u32 = rom_read((addr & 0xfffffffc) + 1);
        third : u32 = rom_read((addr & 0xfffffffc) + 2);
        fourth : u32 = rom_read((addr & 0xfffffffc) + 3);
        return first | (second << 8) | (third << 16) | (fourth << 24);
    }

    log_warn("Unmapped read: 0x%", formatInt(addr, 16));
    return 0;
}

write_8 :: (addr: u32, val: u8) {
    if addr >= 0x02000000 && addr < 0x02040000 {
        cpu.memory.ewram._8[addr % 0x40000] = val;
    }
    else if addr >= 0x03000000 && addr < 0x04000000 {
        cpu.memory.iwram._8[addr % 0x8000] = val;
    }
    else if addr >= 0x04000000 && addr < 0x04000400 {
        mmio_write(addr, val);
    }
    else if addr >= 0x05000000 && addr < 0x06000000 {
        ppu.memory.palette_ram._8[addr % 0x400] = val;
    }
    else if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            ppu.memory.vram._8[addr % 0x18000] = val;
        } else {
            ppu.memory.vram._8[(addr % 0x8000) + 0x10000] = val;
        }
    }
    else if addr >= 0x07000000 && addr < 0x08000000 {
        ppu.memory.oam._8[addr % 0x400] = val;
        oam_update(addr);
    } else if addr >= 0x08000000 {
        rom_write(addr, val);
    }
}

write_16 :: (addr: u32, val: u16, write_override := false) {
    if addr >= 0x02000000 && addr < 0x02040000 {
        cpu.memory.ewram._16[(addr >> 1) % 0x20000] = val;
    }
    else if addr >= 0x03000000 && addr < 0x04000000 {
        cpu.memory.iwram._16[(addr >> 1) % 0x4000] = val;
    }
    else if addr >= 0x04000000 && addr < 0x04000400 {
        mmio_write((addr & 0xfffffffe), xx (val >> 0) & 0xff);
        mmio_write((addr & 0xfffffffe) + 1, xx (val >> 8) & 0xff);
    }
    else if addr >= 0x05000000 && addr < 0x06000000 {
        ppu.memory.palette_ram._16[(addr >> 1) % 0x200] = val;
    }
    else if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            ppu.memory.vram._16[(addr >> 1) % 0xc000] = val;
        } else {
            ppu.memory.vram._16[((addr >> 1) % 0x4000) + 0x8000] = val;
        }
    }
    else if addr >= 0x07000000 && addr < 0x08000000 {
        ppu.memory.oam._16[(addr >> 1) % 0x200] = val;
        oam_update(addr);
        oam_update(addr + 1);
    } else if write_override && addr < 0x4000 {
        cpu.memory.bios._16[addr >> 1] = val;
    } else if write_override && addr >= 0x08000000 && addr < 0x0e000000 {
        cpu.memory.rom[(addr & 0xfffffffe) % cpu.memory.rom.count] = xx (val >> 0) & 0xff;
        cpu.memory.rom[((addr & 0xfffffffe) + 1) % cpu.memory.rom.count] = xx (val >> 8) & 0xff;
    } else if addr >= 0x08000000 {
        rom_write((addr & 0xfffffffe), xx val & 0xff);
        rom_write((addr & 0xfffffffe) + 1, xx val >> 8);
    }
}

write_32 :: (addr: u32, val: u32, write_override := false) {
    if addr >= 0x02000000 && addr < 0x02040000 {
        cpu.memory.ewram._32[(addr >> 2) % 0x10000] = val;
    }
    else if addr >= 0x03000000 && addr < 0x04000000 {
        cpu.memory.iwram._32[(addr >> 2) % 0x2000] = val;
    }
    else if addr >= 0x04000000 && addr < 0x04000400 {
        mmio_write((addr & 0xfffffffc), xx (val >> 0) & 0xff);
        mmio_write((addr & 0xfffffffc) + 1, xx (val >> 8) & 0xff);
        mmio_write((addr & 0xfffffffc) + 2, xx (val >> 16) & 0xff);
        mmio_write((addr & 0xfffffffc) + 3, xx (val >> 24) & 0xff);
    }
    else if addr >= 0x05000000 && addr < 0x06000000 {
        ppu.memory.palette_ram._32[(addr >> 2) % 0x100] = val;
    }
    else if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            ppu.memory.vram._32[(addr >> 2) % 0x6000] = val;
        } else {
            ppu.memory.vram._32[((addr >> 2) % 0x2000) + 0x4000] = val;
        }
    }
    else if addr >= 0x07000000 && addr < 0x08000000 {
        ppu.memory.oam._32[(addr >> 2) % 0x100] = val;
        oam_update(addr);
        oam_update(addr + 1);
        oam_update(addr + 2);
        oam_update(addr + 3);
    } else if write_override && addr < 0x4000 {
        cpu.memory.bios._32[addr >> 2] = val;
    } else if write_override && addr >= 0x08000000 && addr < 0x0e000000 {
        cpu.memory.rom[(addr & 0xfffffffc) % cpu.memory.rom.count] = xx (val >> 0) & 0xff;
        cpu.memory.rom[((addr & 0xfffffffc) + 1) % cpu.memory.rom.count] = xx (val >> 8) & 0xff;
        cpu.memory.rom[((addr & 0xfffffffc) + 2) % cpu.memory.rom.count] = xx (val >> 16) & 0xff;
        cpu.memory.rom[((addr & 0xfffffffc) + 3) % cpu.memory.rom.count] = xx (val >> 24) & 0xff;
    } else if addr >= 0x08000000 {
        rom_write((addr & 0xfffffffc), xx (val >> 0) & 0xff);
        rom_write((addr & 0xfffffffc) + 1, xx (val >> 8) & 0xff);
        rom_write((addr & 0xfffffffc) + 2, xx (val >> 16) & 0xff);
        rom_write((addr & 0xfffffffc) + 3, xx (val >> 24) & 0xff);
    }
}

// these do not use the generic read_* or write_* functions,
// since these two functions are almost exclusively used in execution
// and thus will mostly be reading from the ROM or BIOS
next_16 :: () -> u16 {
    ret: u16;
    idx := cpu.reg[15] & 0xfffffffe;
    if idx >= 0x08000000 && idx < 0x0e000000 {
        first : u16 = cpu.memory.rom[idx % cpu.memory.rom.count];
        second : u16 = cpu.memory.rom[(idx + 1) % cpu.memory.rom.count];
        ret = first | (second << 8);
        if idx < 0xa000000 {
            cpu.remaining_cycles -= cpu.waitcnt_0;
        } else if idx < 0xc000000 {
            cpu.remaining_cycles -= cpu.waitcnt_1;
        } else {
            cpu.remaining_cycles -= cpu.waitcnt_2;
        }
    }
    else if idx < 0x4000 {
        ret = cpu.memory.bios._16[idx >> 1];
    }
    else if idx >= 0x02000000 && idx < 0x02040000 {
        ret = cpu.memory.ewram._16[(idx >> 1) % 0x20000];
    }
    else if idx >= 0x03000000 && idx < 0x04000000 {
        ret = cpu.memory.iwram._16[(idx >> 1) % 0x4000];
    } else {
        log_warn("Unmapped execution read: 0x%", formatInt(idx, 16));
    }
    cpu.reg[15] += 2;
    return ret;
}

next_32 :: () -> u32 {
    ret: u32;
    idx := cpu.reg[15] & 0xfffffffc;
    if idx >= 0x08000000 && idx < 0x0e000000 {
        first : u32 = cpu.memory.rom[idx % cpu.memory.rom.count];
        second : u32 = cpu.memory.rom[(idx + 1) % cpu.memory.rom.count];
        third : u32 = cpu.memory.rom[(idx + 2) % cpu.memory.rom.count];
        fourth : u32 = cpu.memory.rom[(idx + 3) % cpu.memory.rom.count];
        ret = first | (second << 8) | (third << 16) | (fourth << 24);
        if idx < 0xa000000 {
            cpu.remaining_cycles -= cpu.waitcnt_0;
        } else if idx < 0xc000000 {
            cpu.remaining_cycles -= cpu.waitcnt_1;
        } else {
            cpu.remaining_cycles -= cpu.waitcnt_2;
        }
    }
    else if idx < 0x4000 {
        ret = cpu.memory.bios._32[idx >> 2];
    }
    else if idx >= 0x02000000 && idx < 0x02040000 {
        ret = cpu.memory.ewram._32[(idx >> 2) % 0x10000];
    }
    else if idx >= 0x03000000 && idx < 0x04000000 {
        ret = cpu.memory.iwram._32[(idx >> 2) % 0x2000];
    } else {
        log_error("Unmapped execution read: 0x%", formatInt(idx, 16));
    }
    cpu.reg[15] += 4;
    return ret;
}

get_status_bit :: inline (bit: Status_Bit) -> bool {
    return (cpu.psr & xx bit) != 0;
}

set_status_bit :: inline (bit: Status_Bit, state: bool) {
    if state {
        cpu.psr |= xx bit;
    } else {
        cpu.psr &= xx (~bit) & 0xffffffff;
    }
}

step_cpu :: () {
    if cpu.remaining_cycles > 0 {
        cpu.remaining_cycles -= 1;
        if !cpu.halted && !cpu.stopped {
            execute_next();
            cpu.pc_history[cpu.pc_history_idx] = cpu.reg[15];
            cpu.pc_history_idx += 1;
            cpu.pc_history_idx &= 63;
        }
    }
}

set_mode :: (mode: u32) {
    new_mode: Cpu_Mode;
    if (mode & 0x1f) == {
        case 0b10000;
            new_mode = .USER;
        case 0b10001;
            new_mode = .FIQ;
        case 0b10010;
            new_mode = .IRQ;
        case 0b10011;
            new_mode = .SVC;
        case 0b10111;
            new_mode = .ABT;
        case 0b11011;
            new_mode = .UND;
        case 0b11111;
            new_mode = .SYSTEM;
    }
    if cpu.logging print("Set Mode %\n", new_mode);
    cpu.sp[cpu.mode] = cpu.reg[13];
    cpu.lr[cpu.mode] = cpu.reg[14];
    cpu.reg[13] = cpu.sp[new_mode];
    cpu.reg[14] = cpu.lr[new_mode];
    cpu.mode = new_mode;
    cpu.psr &= ~cast(u32)0x1f;
    cpu.psr |= mode & 0x1f;
}

interrupt :: (mode: Cpu_Mode) {
    assert(mode == Cpu_Mode.IRQ || mode == Cpu_Mode.FIQ || mode == Cpu_Mode.SVC);
    if cpu.mode == mode return;
    cpu.spsr[mode] = cpu.psr;
    if mode == {
        case .SVC;
        set_mode(0b10011);
        cpu.reg[14] = cpu.reg[15];
        cpu.reg[15] = 0x08;
        case .IRQ;
        set_mode(0b10010);
        cpu.reg[14] = cpu.reg[15] + 4;
        cpu.reg[15] = 0x18;
        case .FIQ;
        set_mode(0b10001);
        cpu.reg[14] = cpu.reg[15] + 4;
        cpu.reg[15] = 0x1c;
        set_status_bit(.F, true);
    }
    if cpu.logging print("Interrupt %\n", mode);
    set_status_bit(.I, true);
    set_status_bit(.T, false);
    cpu.halted = false;
    cpu.stopped = false;
}

advance_timers :: (cycles: int) {
    prescaler_values := u16.[1, 64, 256, 1024];
    for * cpu.timer {
        if !it.enable then continue;
        if !it.ignore_prescaler {
            it.prescaler_counter += cycles;
            inc_count : int = it.prescaler_counter / prescaler_values[it.prescaler_selection];
            it.counter += inc_count;
            it.prescaler_counter -= inc_count * prescaler_values[it.prescaler_selection];
            if it.counter > 0xffff {
                timer_overflow(it_index);
            }
        }
    }
}

timer_overflow :: (idx: int) {
    cpu.timer[idx].counter -= 0xffff;
    cpu.timer[idx].counter += cpu.timer[idx].reload;
    interrupts := Interrupt_Source.[.TIM0OVERFLOW, .TIM1OVERFLOW, .TIM2OVERFLOW, .TIM3OVERFLOW];
    if cpu.timer[idx].irq && !get_status_bit(.I) && cpu.interrupt_master_enable && cpu.ie[interrupts[idx]] {
        cpu.ifl[interrupts[idx]] = xx 1 << interrupts[idx];
        interrupt(.IRQ);
    }
    if idx < 3 && cpu.timer[idx+1].ignore_prescaler {
        cpu.timer[idx+1].counter += 1;
        if cpu.timer[idx+1].counter > 0xffff {
            timer_overflow(idx+1);
        }
    }
    if idx < 2 {
        if apu.chan_a.timer_select == idx {
            if cpu.dma[1].dst == 0x40000a0 && cpu.dma[1].repeat {
                cpu.dma[1].dst_addr_control = .FIXED;
                apu.fifo_a.r += 1;
                apu.fifo_a.r %= 32;
                apu.fifo_a.out = cast,no_check(s8)apu.fifo_a.buffer[apu.fifo_a.r];
                // print("Advancing read to %\n", apu.fifo_a.r & 0x1f);
                apu.fifo_a.cnt -= 1;
                if apu.fifo_a.cnt < 16 {
                    // print("Overflow, re-reading\n");
                    transfer(1);
                    transfer(1);
                    transfer(1);
                    transfer(1);
                }
            }
            if cpu.dma[2].dst == 0x40000a0 && cpu.dma[2].repeat {
                cpu.dma[2].dst_addr_control = .FIXED;
                apu.fifo_a.r += 1;
                apu.fifo_a.r %= 32;
                apu.fifo_a.out = cast,no_check(s8)apu.fifo_a.buffer[apu.fifo_a.r];
                apu.fifo_a.cnt -= 1;
                if apu.fifo_a.cnt < 16 {
                    transfer(2);
                    transfer(2);
                    transfer(2);
                    transfer(2);
                }
            }
        }
        if apu.chan_b.timer_select == idx {
            if cpu.dma[1].dst == 0x40000a4 && cpu.dma[1].repeat {
                cpu.dma[1].dst_addr_control = .FIXED;
                apu.fifo_b.r += 1;
                apu.fifo_b.r %= 32;
                apu.fifo_b.cnt -= 1;
                if apu.fifo_b.cnt < 16 {
                    transfer(1);
                    transfer(1);
                    transfer(1);
                    transfer(1);
                }
            }
            if cpu.dma[2].dst == 0x40000a4 && cpu.dma[2].repeat {
                cpu.dma[2].dst_addr_control = .FIXED;
                apu.fifo_b.r += 1;
                apu.fifo_b.r %= 32;
                apu.fifo_b.cnt -= 1;
                if apu.fifo_b.cnt < 16 {
                    transfer(2);
                    transfer(2);
                    transfer(2);
                    transfer(2);
                }
            }
        }
    }
}

transfer :: (idx: int) {
    if cpu.dma[idx].enable {
        if cpu.dma[idx].large_transfer {
            write_32(cpu.dma[idx].dst_int & 0xfffffffc, read_32(cpu.dma[idx].src_int & 0xfffffffc));
            if cpu.dma[idx].src_addr_control == {
                case .INC;
                    cpu.dma[idx].src_int += 4;
                case .DEC;
                    cpu.dma[idx].src_int -= 4;
            }
            if cpu.dma[idx].dst_addr_control == {
                case .INC_RELOAD; #through;
                case .INC;
                    cpu.dma[idx].dst_int += 4;
                case .DEC;
                    cpu.dma[idx].dst_int -= 4;
            }
        } else {
            write_16(cpu.dma[idx].dst_int & 0xfffffffe, read_16(cpu.dma[idx].src_int & 0xfffffffe));
            if cpu.dma[idx].src_addr_control == {
                case .INC;
                    cpu.dma[idx].src_int += 2;
                case .DEC;
                    cpu.dma[idx].src_int -= 2;
            }
            if cpu.dma[idx].dst_addr_control == {
                case .INC_RELOAD; #through;
                case .INC;
                    cpu.dma[idx].dst_int += 2;
                case .DEC;
                    cpu.dma[idx].dst_int -= 2;
            }
        }
        cpu.dma[idx].count_int -= 1;
        if cpu.dma[idx].count_int == 0 {
            interrupts := Interrupt_Source.[.DMA0, .DMA1, .DMA2, .DMA3];
            if cpu.dma[idx].irq && !get_status_bit(.I) && cpu.interrupt_master_enable && cpu.ie[interrupts[idx]] {
                cpu.ifl[interrupts[idx]] = xx 1 << interrupts[idx];
                interrupt(.IRQ);
            }
            if cpu.dma[idx].repeat {
                cpu.dma[idx].count_int = ifx cpu.dma[idx].count == 0 then 0x4000 else cpu.dma[idx].count;
                if cpu.dma[idx].dst_addr_control == .INC_RELOAD {
                    cpu.dma[idx].dst_int = cpu.dma[idx].dst;
                }
            } else {
                cpu.dma[idx].enable = false;
            }
        }
    }
    cpu.remaining_cycles -= 2;
}

cond :: (val: u32) -> bool {
    if val == {
        case 0;
        return get_status_bit(.Z);
        case 1;
        return !get_status_bit(.Z);
        case 2;
        return get_status_bit(.C);
        case 3;
        return !get_status_bit(.C);
        case 4;
        return get_status_bit(.N);
        case 5;
        return !get_status_bit(.N);
        case 6;
        return get_status_bit(.V);
        case 7;
        return !get_status_bit(.V);
        case 8;
        return get_status_bit(.C) && !get_status_bit(.Z);
        case 9;
        return !get_status_bit(.C) || get_status_bit(.Z);
        case 10;
        return get_status_bit(.N) == get_status_bit(.V);
        case 11;
        return get_status_bit(.N) != get_status_bit(.V);
        case 12;
        return get_status_bit(.N) == get_status_bit(.V) && !get_status_bit(.Z);
        case 13;
        return get_status_bit(.N) != get_status_bit(.V) || get_status_bit(.Z);
        case 14;
        return true;
        case;
        assert(false);
        return false;
    }
}

reg_src :: inline (val: u8) -> u32 {
    if val == 15 {
        cpu.remaining_cycles -= 2;
        return cpu.reg[15] + xx ifx get_status_bit(.T) then 2 else 4;
    }
    return cpu.reg[val];
}

reg_dst :: inline (val: u8, to_write: u32) {
    if val == 15 {
        if get_status_bit(.T) {
            cpu.reg[15] = to_write & 0xfffffffe;
        } else {
            cpu.reg[15] = to_write & 0xfffffffc;
        }
    } else {
        cpu.reg[val] = to_write;
    }
}

shifter_operand :: (val: u16) -> (u32, bool, bool) {
    assert(val <= 0xfff);
    cpu.remaining_cycles -= 1;
    if ((val >> 4) & 0b111) == {
        case 0b000;
            // register operand + logical shift left imm
            ret := reg_src(xx (val & 0xf));
            shift_cnt := val >> 7;
            if shift_cnt != 0 {
                carry := (ret & (1 << (32 - shift_cnt))) != 0;
                return ret << shift_cnt, true, carry;
            }
            return xx ret, false, false;
        case 0b001;
            // register operand + logical shift left reg
            ret := reg_src(xx (val & 0xf));
            reg_shift := reg_src(xx ((val >> 8) & 0xf));
            if reg_shift != 0 {
                carry: bool;
                if reg_shift > 32 then carry = false;
                else carry = (ret & (1 << (32 - reg_shift))) != 0;
                return ret << reg_shift, true, carry;
            }
            return ret << reg_shift, false, false;
        case 0b010;
            // register operand + logical shift right imm
            ret := reg_src(xx (val & 0xf));
            shift_cnt := val >> 7;
            if shift_cnt == 0 then shift_cnt = 32;
            carry := (ret & (1 << (shift_cnt-1))) != 0;
            return ret >> shift_cnt, true, carry;
        case 0b011;
            // register operand + logical shift right reg
            ret := reg_src(xx (val & 0xf));
            reg_shift := reg_src(xx ((val >> 8) & 0xf));
            if reg_shift != 0 {
                carry: bool;
                if reg_shift > 32 then carry = false;
                else carry = (ret & (1 << (reg_shift-1))) != 0;
                return ret >> reg_shift, true, carry;
            }
            return ret >> reg_shift, false, false;
        case 0b100;
            // register operand + arithmetic shift right imm
            ret := reg_src(xx (val & 0xf));
            shift_cnt := val >> 7;
            if shift_cnt == 0 then shift_cnt = 32;
            carry := (ret & (1 << (shift_cnt-1))) != 0;
            if ret & 0x80000000 {
                sign_bit_fill : u32 = cast(u32)((0xffffffff << (32 - shift_cnt)) & 0xffffffff);
                return (ret >> shift_cnt) | sign_bit_fill, true, carry;
            }
            return ret >> shift_cnt, true, carry;
        case 0b101;
            // register operand + arithmetic shift right reg
            ret := reg_src(xx (val & 0xf));
            reg_shift := reg_src(xx ((val >> 8) & 0xf));
            carry := false;
            should_carry := false;
            if reg_shift != 0 {
                should_carry = true;
                if reg_shift > 32 then carry = false;
                else carry = (ret & (1 << (reg_shift-1))) != 0;
            }
            if ret & 0x80000000 {
                sign_bit_fill := cast(u32)0xffffffff << (32 - min(32, reg_shift));
                return (ret >> reg_shift) | sign_bit_fill, should_carry, carry;
            }
            return ret >> reg_shift, should_carry, carry;
        case 0b110;
            // register operand + rotate right imm
            ret : u32 = reg_src(xx (val & 0xf));
            rotate_cnt : u32 = val >> 7;
            if rotate_cnt == 0 {
                msb := get_status_bit(.C);
                carry := (ret & 1) != 0;
                ret >>= 1;
                return ret, true, carry;
            } else {
                carry := (ret & (1 << (rotate_cnt-1))) != 0;
                #asm {
                    rotate_cnt === c;
                    ror.32 ret, rotate_cnt;
                }
                return ret, true, carry;
            }
        case 0b111;
            // register operand + rotate right reg
            ret : u32 = reg_src(xx (val & 0xf));
            reg_rotate : u32 = reg_src(xx ((val >> 8) & 0xf));
            carry := false;
            should_carry := false;
            if reg_rotate != 0 {
                should_carry = true;
                if reg_rotate > 32 then carry = false;
                else carry = (ret & (1 << (reg_rotate-1))) != 0;
            }
            #asm {
                reg_rotate === c;
                ror.32 ret, reg_rotate;
            }
            return ret, should_carry, carry;
    }
    assert(false);
    return 0, false, false;
}

immediate_operand :: (val: u16) -> (u32, bool, bool) {
    imm : u32 = val & 0xff;
    rotate : u32 = (val >> 8) * 2;
    #asm {
        rotate === c;
        ror.32 imm, rotate;
    }
    return imm, rotate != 0, (imm & 0x80000000) != 0;
}

arm_decoder_table :: Decoder_Unit_Arm.[
    .{0xf8000f0, 0x0800090, arm_umull_umlal_smull_smlal},
    .{0xfc000f0, 0x0000090, arm_mul_mla},

    .{0xe0000f0, 0x00000b0, arm_ldrh_strh},
    .{0xe0000d0, 0x00000d0, arm_ldrsb_ldrsh},
    .{0xe000000, 0x8000000, arm_ldm_stm},
    .{0xe000000, 0xc000000, arm_ldc_stc},
    .{0xc000000, 0x4000000, arm_ldr_str_ldrb_strb},

    .{0xde00000, 0x0000000, arm_and},
    .{0xde00000, 0x0200000, arm_eor},
    .{0xde00000, 0x0400000, arm_sub},
    .{0xde00000, 0x0600000, arm_rsb},
    .{0xde00000, 0x0800000, arm_add},
    .{0xde00000, 0x0a00000, arm_adc},
    .{0xde00000, 0x0c00000, arm_sbc},
    .{0xde00000, 0x0e00000, arm_rsc},
    .{0xde00000, 0x1800000, arm_orr},
    .{0xdef0000, 0x1a00000, arm_mov},
    .{0xde00000, 0x1c00000, arm_bic},
    .{0xdef0000, 0x1e00000, arm_mvn},

    .{0xdf0f000, 0x1100000, arm_tst},
    .{0xdf0f000, 0x1300000, arm_teq},
    .{0xdf0f000, 0x1500000, arm_cmp},

    .{0xdb000f0, 0x1200000, arm_msr},
    .{0xfb00000, 0x1000000, arm_mrs},
    .{0xfb00ff0, 0x1000090, arm_swp_swpb},
    .{0xffffff0, 0x12fff10, arm_bx},
    .{0xf000000, 0xa000000, arm_b},
    .{0xf000000, 0xb000000, arm_bl},
    .{0xf000010, 0xe000000, arm_cdp},
    .{0xf000010, 0xe000010, arm_mcr_mrc},
    .{0xf000000, 0xf000000, arm_swi},
    .{0xff000f0, 0x1200070, arm_bkpt},
    .{0x0000000, 0x0000000, null}
];

thumb_decoder_table :: Decoder_Unit_Thumb.[
    .{0xf800, 0x0000, thumb_lsl_1},
    .{0xf800, 0x0800, thumb_lsr_1},
    .{0xf800, 0x1000, thumb_asr_1},
    .{0xfe00, 0x1800, thumb_add_3},
    .{0xfe00, 0x1a00, thumb_sub_3},
    .{0xfe00, 0x1c00, thumb_add_1},
    .{0xfe00, 0x1e00, thumb_sub_1},
    .{0xf800, 0x2000, thumb_mov_1},
    .{0xf800, 0x2800, thumb_cmp_1},
    .{0xf800, 0x3000, thumb_add_2},
    .{0xf800, 0x3800, thumb_sub_2},
    .{0xffc0, 0x4000, thumb_and},
    .{0xffc0, 0x4040, thumb_eor},
    .{0xffc0, 0x4080, thumb_lsl_2},
    .{0xffc0, 0x40c0, thumb_lsr_2},
    .{0xffc0, 0x4100, thumb_asr_2},
    .{0xffc0, 0x4140, thumb_adc},
    .{0xffc0, 0x4180, thumb_sbc},
    .{0xffc0, 0x41c0, thumb_ror},
    .{0xffc0, 0x4200, thumb_tst},
    .{0xffc0, 0x4240, thumb_neg},
    .{0xffc0, 0x4280, thumb_cmp_2},
    .{0xffc0, 0x42c0, thumb_cmn},
    .{0xffc0, 0x4300, thumb_orr},
    .{0xffc0, 0x4340, thumb_mul},
    .{0xffc0, 0x4380, thumb_bic},
    .{0xffc0, 0x43c0, thumb_mvn},
    .{0xff00, 0x4400, thumb_add_4},
    .{0xff00, 0x4500, thumb_cmp_3},
    .{0xff00, 0x4600, thumb_mov_3},
    .{0xff00, 0x4700, thumb_bx_blx_2},
    .{0xf800, 0x4800, thumb_ldr_3},
    .{0xfe00, 0x5000, thumb_str_2},
    .{0xfe00, 0x5200, thumb_strh_2},
    .{0xfe00, 0x5400, thumb_strb_2},
    .{0xfe00, 0x5600, thumb_ldrsb},
    .{0xfe00, 0x5800, thumb_ldr_2},
    .{0xfe00, 0x5a00, thumb_ldrh_2},
    .{0xfe00, 0x5c00, thumb_ldrb_2},
    .{0xfe00, 0x5e00, thumb_ldrsh},
    .{0xe000, 0x6000, thumb_ldr_str_ldrb_strb_1},
    .{0xf800, 0x8000, thumb_strh_1},
    .{0xf800, 0x8800, thumb_ldrh_1},
    .{0xf800, 0x9000, thumb_str_3},
    .{0xf800, 0x9800, thumb_ldr_4},
    .{0xf000, 0xa000, thumb_add_5_add_6},
    .{0xff00, 0xb000, thumb_add_7_sub_4},
    .{0xfe00, 0xb400, thumb_push},
    .{0xfe00, 0xbc00, thumb_pop},
    .{0xff00, 0xbe00, thumb_bkpt},
    .{0xf000, 0xc000, thumb_ldmia_stmia},
    .{0xf000, 0xd000, thumb_swi_b_1},
    .{0xf800, 0xe000, thumb_b_2},
    .{0xf800, 0xe800, thumb_bl_blx_1_blx_suffix},
    .{0xf800, 0xf000, thumb_bl_blx_1_prefix},
    .{0xf800, 0xf800, thumb_bl_blx_1_bl_suffix},
    .{0x0000, 0x0000, null}
];

arm_reduced_lut : [4096](ins: u32);
thumb_reduced_lut : [1024](ins: u16);

populate_arm_lut :: () {
    for upper: 0..255 {
        for lower: 0..16 {
            ins : u32 = xx (lower << 4) | (upper << 20);
            for arm_decoder_table {
                if ins & it.mask == it.result {
                    arm_reduced_lut[lower | (upper << 4)] = it.function;
                    break;
                }
            }
        }
    }
    arm_reduced_lut[0x121] = arm_bx;
}


populate_thumb_lut :: () {
    for ins: 0..1023 {
        for thumb_decoder_table {
            if (ins << 6) & it.mask == it.result {
                thumb_reduced_lut[ins] = it.function;
                break;
            }
        }
    }
}

execute_next :: () {
    if !get_status_bit(.T) {
        ins := next_32();
        ins_c := ins;
        if cpu.logging print("0x% PC: 0x% LR: 0x% SP: 0x% PSR: 0x%\n", formatInt(ins_c, 16, 8), formatInt(cpu.reg[15], 16, 8), formatInt(cpu.reg[14], 16, 8), formatInt(cpu.reg[13], 16, 8), formatInt(cpu.psr, 16, 8));
        if !cond(ins >> 28) {
            return;
        }
        mask : u32 = 0x0ff000f0;
        ins_masked : u32;
        #asm {
            pext.32 ins_masked, ins, mask;
        }
        arm_reduced_lut[ins_masked](ins);
    } else {
        ins := next_16();
        if cpu.logging print("0x% PC: 0x% LR: 0x% SP: 0x% PSR: 0x%\n", formatInt(ins, 16, 4), formatInt(cpu.reg[15], 16, 8), formatInt(cpu.reg[14], 16, 8), formatInt(cpu.reg[13], 16, 8), formatInt(cpu.psr, 16, 8));
        thumb_reduced_lut[ins >> 6](ins);
    }
}
