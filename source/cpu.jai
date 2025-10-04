// the read and write functions are all very similar in composition,
// however have been split up in order to increase performance

read_8 :: (addr: u32) -> u8 {
    if addr < 0x4000 {
        return cpu.memory.bios._8[addr];
    }
    if addr >= 0x02000000 && addr < 0x02040000 {
        return cpu.memory.ewram._8[addr % 0x40000];
    }
    if addr >= 0x03000000 && addr < 0x03008000 {
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
    if addr >= 0x08000000 && addr < 0x0e000000 {
        return cpu.memory.rom[addr % cpu.memory.rom.count];
    }

    log_warn("Unmapped read: 0x%", formatInt(addr, 16));
    return 0;
}

read_16 :: (addr: u32) -> u16 {
    if addr < 0x4000 {
        return cpu.memory.bios._16[addr >> 1];
    }
    if addr >= 0x02000000 && addr < 0x02040000 {
        return cpu.memory.ewram._16[(addr >> 1) % 0x20000];
    }
    if addr >= 0x03000000 && addr < 0x03008000 {
        return cpu.memory.iwram._16[(addr >> 1) % 0x4000];
    }
    if addr >= 0x04000000 && addr < 0x04000400 {
        first : u16 = mmio_read(addr);
        second : u16 = mmio_read(addr + 1);
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
    if addr >= 0x08000000 && addr < 0x0e000000 {
        first : u16 = cpu.memory.rom[addr % cpu.memory.rom.count];
        second : u16 = cpu.memory.rom[(addr + 1) % cpu.memory.rom.count];
        return first | (second << 8);
    }

    log_warn("Unmapped read: 0x%", formatInt(addr, 16));
    return 0;
}

read_32 :: (addr: u32) -> u32 {
    if addr < 0x4000 {
        return cpu.memory.bios._32[addr >> 2];
    }
    if addr >= 0x02000000 && addr < 0x02040000 {
        return cpu.memory.ewram._32[(addr >> 2) % 0x10000];
    }
    if addr >= 0x03000000 && addr < 0x03008000 {
        return cpu.memory.iwram._32[(addr >> 2) % 0x2000];
    }
    if addr >= 0x04000000 && addr < 0x04000400 {
        first : u32 = mmio_read(addr);
        second : u32 = mmio_read(addr + 1);
        third : u32 = mmio_read(addr + 2);
        fourth : u32 = mmio_read(addr + 3);
        return first | (second << 8) | (third << 16) | (fourth << 24);
    }
    if addr >= 0x05000000 && addr < 0x06000000 {
        return ppu.memory.palette_ram._32[(addr >> 2) % 0x200];
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
        first : u32 = cpu.memory.rom[addr % cpu.memory.rom.count];
        second : u32 = cpu.memory.rom[(addr + 1) % cpu.memory.rom.count];
        third : u32 = cpu.memory.rom[(addr + 2) % cpu.memory.rom.count];
        fourth : u32 = cpu.memory.rom[(addr + 3) % cpu.memory.rom.count];
        return first | (second << 8) | (third << 16) | (fourth << 24);
    }

    log_warn("Unmapped read: 0x%", formatInt(addr, 16));
    return 0;
}

write_8 :: (addr: u32, val: u8) {
    if addr >= 0x02000000 && addr < 0x02040000 {
        cpu.memory.ewram._8[addr % 0x40000] = val;
    }
    else if addr >= 0x03000000 && addr < 0x03008000 {
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
    } else {
        log_warn("Unmapped write: 0x%", formatInt(addr, 16));
    }
}

write_16 :: (addr: u32, val: u16) {
    if addr >= 0x02000000 && addr < 0x02040000 {
        cpu.memory.ewram._16[(addr >> 1) % 0x20000] = val;
    }
    else if addr >= 0x03000000 && addr < 0x03008000 {
        cpu.memory.iwram._16[(addr >> 1) % 0x4000] = val;
    }
    else if addr >= 0x04000000 && addr < 0x04000400 {
        mmio_write(addr, xx (val >> 0) & 0xff);
        mmio_write(addr + 1, xx (val >> 8) & 0xff);
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
    } else {
        log_warn("Unmapped write: 0x%", formatInt(addr, 16));
    }
}

write_32 :: (addr: u32, val: u32) {
    if addr >= 0x02000000 && addr < 0x02040000 {
        cpu.memory.ewram._32[(addr >> 2) % 0x10000] = val;
    }
    else if addr >= 0x03000000 && addr < 0x03008000 {
        cpu.memory.iwram._32[(addr >> 2) % 0x2000] = val;
    }
    else if addr >= 0x04000000 && addr < 0x04000400 {
        mmio_write(addr, xx (val >> 0) & 0xff);
        mmio_write(addr + 1, xx (val >> 8) & 0xff);
        mmio_write(addr + 2, xx (val >> 16) & 0xff);
        mmio_write(addr + 3, xx (val >> 24) & 0xff);
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
    } else {
        log_warn("Unmapped write: 0x%", formatInt(addr, 16));
    }
}

// these do not use the generic read_* or write_* functions,
// since these two functions are almost exclusively used in execution
// and thus will mostly be reading from the ROM or BIOS
next_16 :: () -> u16 {
    ret: u16;
    if cpu.pc >= 0x08000000 && cpu.pc < 0x0e000000 {
        first : u16 = cpu.memory.rom[cpu.pc % cpu.memory.rom.count];
        second : u16 = cpu.memory.rom[(cpu.pc + 1) % cpu.memory.rom.count];
        ret = first | (second << 8);
    }
    else if cpu.pc < 0x4000 {
        ret = cpu.memory.bios._16[cpu.pc >> 1];
    }
    else if cpu.pc >= 0x02000000 && cpu.pc < 0x02040000 {
        ret = cpu.memory.ewram._16[(cpu.pc >> 1) % 0x20000];
    }
    else if cpu.pc >= 0x03000000 && cpu.pc < 0x03008000 {
        ret = cpu.memory.iwram._16[(cpu.pc >> 1) % 0x4000];
    } else {
        log_warn("Unmapped execution read: 0x%", formatInt(cpu.pc, 16));
    }
    cpu.pc += 2;
    return ret;
}

next_32 :: () -> u32 {
    ret: u32;
    if cpu.pc >= 0x08000000 && cpu.pc < 0x0e000000 {
        first : u32 = cpu.memory.rom[cpu.pc % cpu.memory.rom.count];
        second : u32 = cpu.memory.rom[(cpu.pc + 1) % cpu.memory.rom.count];
        third : u32 = cpu.memory.rom[(cpu.pc + 2) % cpu.memory.rom.count];
        fourth : u32 = cpu.memory.rom[(cpu.pc + 3) % cpu.memory.rom.count];
        ret = first | (second << 8) | (third << 16) | (fourth << 24);
    }
    else if cpu.pc < 0x4000 {
        ret = cpu.memory.bios._32[cpu.pc >> 2];
    }
    else if cpu.pc >= 0x02000000 && cpu.pc < 0x02040000 {
        ret = cpu.memory.ewram._32[(cpu.pc >> 2) % 0x10000];
    }
    else if cpu.pc >= 0x03000000 && cpu.pc < 0x03008000 {
        ret = cpu.memory.iwram._32[(cpu.pc >> 2) % 0x2000];
    } else {
        log_warn("Unmapped execution read: 0x%", formatInt(cpu.pc, 16));
    }
    cpu.pc += 4;
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
        execute_next();
        disasm_scroll_state = cpu.pc / ifx cpu.state == .ARM then 4 else 2;
        for cpu.breakpoints {
            if it == cpu.pc then cpu.emu_state = .STOPPED;
        }
    }
}

cond :: (val: u8) -> bool {
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

reg_src :: (val: u8) -> u32 {
    if val < 13 {
        if cpu.mode == .FIQ && val > 7 then return cpu.gpr_hi_fiq[val - 8];
        return cpu.gpr[val];
    } else if val == 13 {
        return cpu.sp[cpu.mode];
    } else if val == 14 {
        return cpu.lr[cpu.mode];
    } else if val == 15 {
        return cpu.pc + xx ifx cpu.state == .ARM then 4 else 2;
    } else {
        assert(false);
        return 0;
    }
}

reg_dst :: (val: u8, to_write: u32) {
    if val < 13 {
        if cpu.mode == .FIQ && val > 7 then cpu.gpr_hi_fiq[val - 8] = to_write;
        else cpu.gpr[val] = to_write;
    } else if val == 13 {
        cpu.sp[cpu.mode] = to_write;
    } else if val == 14 {
        cpu.lr[cpu.mode] = to_write;
    } else if val == 15 {
        cpu.pc = to_write;
    } else {
        assert(false);
    }
}

shifter_operand :: (val: u16) -> (u32, bool, bool) {
    assert(val <= 0xfff);
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
                sign_bit_fill := cast(u32)0xffffffff << (32 - shift_cnt);
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
                assert(false); // verify this shit works sometime
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
            assert(false); // verify this shit works sometime
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

execute_next :: () {
    if cpu.state == .ARM {
        ins := next_32();
        cpu.remaining_cycles -= 1;
        if !cond(xx (ins >> 28)) {
            return;
        }
        if ((ins >> 26) & 0b11) == {
            case 0b00;
                if (ins & 0xffffff0) == 0x12fff10 {
                    // branch & exchange
                    arm_bx :: inline (ins: u32) {
                        rm := reg_src(cast(u8) ins & 0xf);
                        cpu.state = ifx (rm & 1) != 0 then .THUMB else .ARM;
                        cpu.pc = rm & 0xfffffffe;
                        // cpu.pc += post_inc;
                        cpu.psr &= ~cast(u32)0x10;
                        cpu.psr |= (rm & 1) << 4;
                    }
                    arm_bx(ins);
                } else if (ins & 0xfc000f0) == 0x0000090 {
                    // multiply
                    arm_mul_mla :: (ins: u32) {
                        assert(false);
                    }
                    arm_mul_mla(ins);
                } else if (ins & 0xf8000f0) == 0x0800090 {
                    // multiply long
                    arm_umull_umlal_smull_smlal :: (ins: u32) {
                        assert(false);
                    }
                    arm_umull_umlal_smull_smlal(ins);
                } else if (ins & 0xfb00ff0) == 0x1000090 {
                    // single data swap
                    arm_swp_swpb :: (ins: u32) {
                        assert(false);
                    }
                    arm_swp_swpb(ins);
                } else if (ins & 0xe400ff0) == 0x0000090 {
                    // halfword data transfer reg
                    assert(false);
                } else if (ins & 0xe4000f0) == 0x0400090 {
                    // halfword data transfer imm
                    assert(false);
                } else if (ins & 0xe0000d0) == 0x00000d0 {
                    // signed data transfer
                    assert(false);
                } else {
                    rn := reg_src(cast(u8)((ins >> 16) & 0xf));
                    rd_idx := cast(u8)((ins >> 12) & 0xf);
                    // data processing and fsr
                    if (ins & 0xfb00000) == 0x1000000 {
                        // mrs
                        arm_mrs :: inline (ins: u32, rd_idx: u8) {
                            if (ins & 0x400000) != 0 {
                                // spsr
                                reg_dst(rd_idx, cpu.spsr[cpu.mode]);
                            } else {
                                // cpsr
                                reg_dst(rd_idx, cpu.psr);
                            }
                        }
                        arm_mrs(ins, rd_idx);
                    } else if (ins & 0xfb00000) == 0x3200000 {
                        // msr immediate
                        assert(false);
                    } else if (ins & 0xfb000f0) == 0x1200000 {
                        // msr reg
                        to_write := reg_src(xx (ins & 0xf));
                        c := (ins & 0x10000) != 0;
                        f := (ins & 0x80000) != 0;
                        if (ins & 0x400000) != 0 {
                            // spsr
                            if f && cpu.mode != 0 {
                                cpu.spsr[cpu.mode] &= 0x00ffffff;
                                cpu.spsr[cpu.mode] |= to_write & 0xff000000;
                            }
                            if c && cpu.mode != 0 {
                                cpu.spsr[cpu.mode] &= 0xffffff00;
                                cpu.spsr[cpu.mode] |= to_write & 0x000000ff;
                                if (to_write & 0x1f) == {
                                    case 0b10000;
                                        cpu.mode = .USER;
                                    case 0b10001;
                                        cpu.mode = .FIQ;
                                    case 0b10010;
                                        cpu.mode = .IRQ;
                                    case 0b10011;
                                        cpu.mode = .SVC;
                                    case 0b10111;
                                        cpu.mode = .ABT;
                                    case 0b11011;
                                        cpu.mode = .UND;
                                    case 0b11111;
                                        cpu.mode = .SYSTEM;
                                }
                            }
                        } else {
                            // cpsr
                            if f {
                                cpu.psr &= 0x00ffffff;
                                cpu.psr |= to_write & 0xff000000;
                            }
                            if c && cpu.privileged {
                                cpu.psr &= 0xffffff00;
                                cpu.psr |= to_write & 0x000000ff;
                                if (to_write & 0x1f) == {
                                    case 0b10000;
                                        cpu.mode = .USER;
                                    case 0b10001;
                                        cpu.mode = .FIQ;
                                    case 0b10010;
                                        cpu.mode = .IRQ;
                                    case 0b10011;
                                        cpu.mode = .SVC;
                                    case 0b10111;
                                        cpu.mode = .ABT;
                                    case 0b11011;
                                        cpu.mode = .UND;
                                    case 0b11111;
                                        cpu.mode = .SYSTEM;
                                }
                            }
                        }
                    } else {
                        operand: u32;
                        should_carry: bool;
                        carry_out: bool;
                        if (ins & 0x2000000) {
                            operand, should_carry, carry_out = immediate_operand(xx (ins & 0xfff));
                        } else {
                            operand, should_carry, carry_out = shifter_operand(xx (ins & 0xfff));
                            cpu.remaining_cycles -= 1;
                        }
                        flags := (ins & 0x100000) != 0;
                        if ((ins >> 21) & 0xf) == {
                            case 0b0000;
                            // and
                            assert(false);
                            case 0b0001;
                            // eor
                            assert(false);
                            case 0b0010;
                                // sub
                                arm_sub :: inline (rn: u32, rd_idx: u8, operand: u32, flags: bool) {
                                    result := rn - operand;
                                    reg_dst(rd_idx, result);
                                    if flags {
                                        set_status_bit(.N, (result & 0x80000000) != 0);
                                        set_status_bit(.Z, result == 0);
                                        set_status_bit(.C, rn >= operand);
                                        set_status_bit(.V, (rn & 0x80000000) != (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
                                    }
                                }
                                arm_sub(rn, rd_idx, operand, flags);
                            case 0b0011;
                            // rsb
                            assert(false);
                            case 0b0100;
                                // add
                                arm_add :: inline (rn: u32, rd_idx: u8, operand: u32, flags: bool) {
                                    result := rn + operand;
                                    reg_dst(rd_idx, result);
                                    if flags {
                                        set_status_bit(.N, (result & 0x80000000) != 0);
                                        set_status_bit(.Z, result == 0);
                                        set_status_bit(.C, cast(u64)(rn) + cast(u64)(operand) > 0xffffffff);
                                        set_status_bit(.V, (rn & 0x80000000) == (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
                                    }
                                }
                                arm_add(rn, rd_idx, operand, flags);
                            case 0b0101;
                            // adc
                            assert(false);
                            case 0b0110;
                            // sbc
                            assert(false);
                            case 0b0111;
                            // rsc
                            assert(false);
                            case 0b1000;
                                // tst
                                arm_tst :: inline (rn: u32, operand: u32, flags: bool, should_carry: bool, carry_out: bool) {
                                    result := rn & operand;
                                    if flags {
                                        set_status_bit(.N, (result & 0x80000000) != 0);
                                        set_status_bit(.Z, result == 0);
                                        if should_carry set_status_bit(.C, carry_out);
                                    }
                                }
                                arm_tst(rn, operand, flags, should_carry, carry_out);
                            case 0b1001;
                                // teq
                                arm_teq :: inline (rn: u32, operand: u32, flags: bool, should_carry: bool, carry_out: bool) {
                                    result := rn ^ operand;
                                    if flags {
                                        set_status_bit(.N, (result & 0x80000000) != 0);
                                        set_status_bit(.Z, result == 0);
                                        if should_carry set_status_bit(.C, carry_out);
                                    }
                                }
                                arm_teq(rn, operand, flags, should_carry, carry_out);
                            case 0b1010;
                                // cmp
                                arm_cmp :: inline (rn: u32, operand: u32, flags: bool) {
                                    result := rn - operand;
                                    if flags {
                                        set_status_bit(.N, (result & 0x80000000) != 0);
                                        set_status_bit(.Z, result == 0);
                                        set_status_bit(.C, rn >= operand);
                                        set_status_bit(.V, (rn & 0x80000000) != (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
                                    }
                                }
                                arm_cmp(rn, operand, flags);
                            case 0b1011;
                            // would be msr, but handled outside
                            assert(false);
                            case 0b1100;
                            // orr
                            assert(false);
                            case 0b1101;
                                // mov
                                arm_mov :: inline (rd_idx: u8, operand: u32, flags: bool, should_carry: bool, carry_out: bool) {
                                    reg_dst(rd_idx, operand);
                                    if flags {
                                        if rd_idx == 15 {
                                            cpu.psr = cpu.spsr[cpu.mode];
                                        } else {
                                            set_status_bit(.N, (operand & 0x80000000) != 0);
                                            set_status_bit(.Z, operand == 0);
                                            if should_carry set_status_bit(.C, carry_out);
                                        }
                                    }
                                }
                                arm_mov(rd_idx, operand, flags, should_carry, carry_out);
                            case 0b1110;
                                // bic
                                arm_bic :: inline (rn: u32, rd_idx: u8, operand: u32, flags: bool, should_carry: bool, carry_out: bool) {
                                    result := rn & ~operand;
                                    reg_dst(rd_idx, result);
                                    if flags {
                                        if rd_idx == 15 {
                                            cpu.psr = cpu.spsr[cpu.mode];
                                        } else {
                                            set_status_bit(.N, (result & 0x80000000) != 0);
                                            set_status_bit(.Z, result == 0);
                                            if should_carry set_status_bit(.C, carry_out);
                                        }
                                    }
                                }
                                arm_bic(rn, rd_idx, operand, flags, should_carry, carry_out);
                            case 0b1111;
                            // mvn
                            assert(false);
                        }
                    }
                }
            case 0b01;
                // immediate offset/index load/store
                arm_ldr_str_ldrb_strb :: inline (ins: u32) {
                    rn_idx := cast(u8)((ins >> 16) & 0xf);
                    rn := reg_src(rn_idx);
                    rd_idx := cast(u8)((ins >> 12) & 0xf);
                    p := (ins & 0x1000000) != 0;
                    u := (ins & 0x800000) != 0;
                    b := (ins & 0x400000) != 0;
                    w := (ins & 0x200000) != 0;
                    l := (ins & 0x100000) != 0;
                    offset := ins & 0xfff;
                    address := rn;
                    if !p {
                        // post indexed
                        if u {
                            rn += offset;
                        } else {
                            rn -= offset;
                        }
                        reg_dst(rn_idx, rn);
                    } else if !w {
                        // offset addressing
                        if u {
                            address += offset;
                        } else {
                            address -= offset;
                        }
                    } else {
                        // pre indexed
                        if u {
                            address += offset;
                        } else {
                            address -= offset;
                        }
                        reg_dst(rn_idx, address);
                    }

                    if l {
                        // load
                        cpu.remaining_cycles -= 2;
                        if b {
                            reg_dst(rd_idx, read_8(address));
                        } else {
                            reg_dst(rd_idx, read_32(address));
                        }
                    } else {
                        // store
                        cpu.remaining_cycles -= 1;
                        if b {
                            write_8(address, xx (reg_src(rd_idx) & 0xff));
                        } else {
                            write_32(address, reg_src(rd_idx));
                        }
                    }
                }
                arm_ldr_str_ldrb_strb(ins);
            case 0b10;
                if (ins & 0x2000000) == 0 {
                    // block data transfer
                    arm_ldm_stm :: inline (ins: u32) {
                        p := (ins & 0x1000000) != 0; // full stack? (empty stack)
                        u := (ins & 0x800000) != 0; // increment pointer? (decrement)
                        s := (ins & 0x400000) != 0; // user mode registers? (current)
                        w := (ins & 0x200000) != 0; // write back pointer?
                        l := (ins & 0x100000) != 0; // load? (store)
                        rn_idx : u8 = xx (ins >> 16) & 0xf;
                        pointer := reg_src(rn_idx);
                        regs := ins & 0xffff;
                        if l {
                            cpu.remaining_cycles -= 1;
                            for 0..15 {
                                if (regs & (1 << it)) != 0 {
                                    cpu.remaining_cycles -= 1;
                                    if p {
                                        if u then pointer += 4; else pointer -= 4;
                                    }
                                    to_store := read_32(pointer);
                                    if s {
                                        if it < 13 {
                                            cpu.gpr[it] = to_store;
                                        } else if it == 13 {
                                            cpu.sp[0] = to_store;
                                        } else if it == 14 {
                                            cpu.lr[0] = to_store;
                                        } else {
                                            cpu.pc = to_store;
                                        }
                                    } else {
                                        reg_dst(xx it, to_store);
                                    }
                                    if !p {
                                        if u then pointer += 4; else pointer -= 4;
                                    }
                                }
                                if w then reg_dst(rn_idx, pointer);
                            }
                        } else {
                            for #v2 < 0..15 {
                                if (regs & (1 << it)) != 0 {
                                    cpu.remaining_cycles -= 1;
                                    if p {
                                        if u then pointer += 4; else pointer -= 4;
                                    }
                                    to_store : u32;
                                    if s {
                                        if it < 13 {
                                            to_store = cpu.gpr[it];
                                        } else if it == 13 {
                                            to_store = cpu.sp[0];
                                        } else if it == 14 {
                                            to_store = cpu.lr[0];
                                        } else {
                                            to_store = cpu.pc;
                                        }
                                    } else {
                                        to_store = reg_src(xx it);
                                    }
                                    write_32(pointer, to_store);
                                    if !p {
                                        if u then pointer += 4; else pointer -= 4;
                                    }
                                }
                                if w then reg_dst(rn_idx, pointer);
                            }
                        }
                    }
                    arm_ldm_stm(ins);
                } else {
                    // branch
                    cpu.remaining_cycles -= 2;
                    if (ins & 0x1000000) == 0 {
                        // b
                        arm_b :: inline (ins: u32) {
                            addr := (ins & 0x7fffff) << 2;
                            cpu.pc += addr;
                            sign := (ins & 0x800000) << 2;
                            cpu.pc -= sign;
                            cpu.pc += 4;
                        }
                        arm_b(ins);
                    } else {
                        // bl
                        arm_bl :: inline (ins: u32) {
                            cpu.lr[cpu.mode] = cpu.pc;
                            addr := (ins & 0x7fffff) << 2;
                            cpu.pc += addr;
                            sign := (ins & 0x800000) << 2;
                            cpu.pc -= sign;
                            cpu.pc += 4;
                        }
                        arm_bl(ins);
                    }
                }
            case 0b11;
                if (ins & 0x2000000) == 0 {
                    // coprocessor data transfer
                    assert(false);
                } else {
                    if (ins & 0x1000000) == 0 {
                        if (ins & 0x10) == 0 {
                            // coprocessor data operation
                            assert(false);
                        } else {
                            // coprocessor register transfer
                            assert(false);
                        }
                    } else {
                        // software interrupt
                        assert(false);
                    }
                }
        }

    } else {
        ins := next_16();
        cpu.remaining_cycles -= 1;
        if (ins >> 13) == {
            case 0b000;
            if (ins >> 9) == {
                case 0b1100;
                // add (3)
                thumb_add_3(ins);
                case 0b1101;
                // sub (3)
                thumb_sub_3(ins);
                case 0b1110;
                // add (1)
                // mov (2) if immediate is 0
                thumb_add_1(ins);
                case 0b1111;
                // sub (1)
                thumb_sub_1(ins);
                case;
                // shift by immediate
                if ((ins >> 11) & 0b11) == {
                    case 0b00;
                    // lsl (1)
                    thumb_lsl_1(ins);
                    case 0b01;
                    // lsr (1)
                    thumb_lsr_1(ins);
                    case 0b10;
                    // asr (1)
                    thumb_asr_1(ins);
                    case 0b11;
                    // handled elsewhere
                    assert(false);
                }
            }
            case 0b001;
            // Add/subtract/compare/move immediate
            if ((ins >> 11) & 0b11) == {
                case 0b00;
                // mov (1)
                thumb_mov_1(ins);
                case 0b01;
                // cmp (1)
                thumb_cmp_1(ins);
                case 0b10;
                // add (2)
                thumb_add_2(ins);
                case 0b11;
                // sub (2)
                thumb_sub_2(ins);
            }
            case 0b010;
            if (ins & 0x1000) != 0 {
                // Load/store register offset
                if ((ins >> 9) & 0b111) == {
                    case 0b000;
                    // str (2)
                    thumb_str_2(ins);
                    case 0b001;
                    // strh (2)
                    thumb_strh_2(ins);
                    case 0b010;
                    // strb (2)
                    thumb_strb_2(ins);
                    case 0b011;
                    // ldrsb
                    thumb_ldrsb(ins);
                    case 0b100;
                    // ldr (2)
                    thumb_ldr_2(ins);
                    case 0b101;
                    // ldrh (2)
                    thumb_ldrh_2(ins);
                    case 0b110;
                    // ldrb (2)
                    thumb_ldrb_2(ins);
                    case 0b111;
                    // ldrsh
                    thumb_ldrsh(ins);
                    case;
                    assert(false);
                }
            } else if (ins & 0x800) != 0 {
                // ldr (3)
                thumb_ldr_3(ins);
            } else if (ins & 0x400) != 0 {
                // special data processing + bx
                if ((ins >> 8) & 0b11) == {
                    case 0b00;
                    // add (4)
                    thumb_add_4(ins);
                    case 0b01;
                    // cmp (3)
                    thumb_cmp_3(ins);
                    case 0b10;
                    // mov (3)
                    thumb_mov_3(ins);
                    case 0b11;
                    // bx / blx (2)
                    thumb_bx_blx_2(ins);
                }
            } else {
                // data processing register
                if ((ins >> 6) & 0xf) == {
                    case 0b0000;
                    // and
                    thumb_and(ins);
                    case 0b0001;
                    // eor
                    thumb_eor(ins);
                    case 0b0010;
                    // lsl (2)
                    thumb_lsl_2(ins);
                    case 0b0011;
                    // lsr (2)
                    thumb_lsr_2(ins);
                    case 0b0100;
                    // asr (2)
                    thumb_asr_2(ins);
                    case 0b0101;
                    // adc
                    thumb_adc(ins);
                    case 0b0110;
                    // sbc
                    thumb_sbc(ins);
                    case 0b0111;
                    // ror
                    thumb_ror(ins);
                    case 0b1000;
                    // tst
                    thumb_tst(ins);
                    case 0b1001;
                    // neg
                    thumb_neg(ins);
                    case 0b1010;
                    // cmp (2)
                    thumb_cmp_2(ins);
                    case 0b1011;
                    // cmn
                    thumb_cmn(ins);
                    case 0b1100;
                    // orr
                    thumb_orr(ins);
                    case 0b1101;
                    // mul
                    thumb_mul(ins);
                    case 0b1110;
                    // bic
                    thumb_bic(ins);
                    case 0b1111;
                    // mvn
                    thumb_mvn(ins);
                }
            }
            case 0b011;
            // Load/store word/byte immediate offset
            thumb_ldr_str_ldrb_strb_1(ins);
            case 0b100;
            if (ins & 0x1000) != 0 {
                // Load/store to/from stack
                if (ins & 0x800) != 0 {
                    // ldr (4)
                    thumb_ldr_4(ins);
                } else {
                    // str (3)
                    thumb_str_3(ins);
                }
            } else {
                // Load/store halfword immediate offset
                if (ins & 0x800) != 0 {
                    // ldrh (1)
                    thumb_ldrh_1(ins);
                } else {
                    // strh (1)
                    thumb_strh_1(ins);
                }
            }
            case 0b101;
            if (ins & 0x1000) != 0 {
                // Miscellaneous
                if (ins & 0x200) != 0 {
                    // software breakpoint?
                    thumb_bkpt(ins);
                } else if (ins & 0x400) != 0 {
                    // push/pop register list
                    if (ins & 0x800) != 0 {
                        // pop
                        thumb_pop(ins);
                    } else {
                        // push
                        thumb_push(ins);
                    }
                } else {
                    // add (7), sub (4)
                    thumb_add_7_sub_4(ins);
                }
            } else {
                // add (5), add (6)
                thumb_add_5_add_6(ins);
            }
            case 0b110;
            if (ins & 0x1000) != 0 {
                // b (1)
                thumb_b_1(ins);
            } else {
                // ldmia, stmia
                thumb_ldmia_stmia(ins);
            }
            case 0b111;
            if ((ins >> 11) & 0b11) == {
                case 0b00;
                // b (2)
                thumb_b_2(ins);
                case 0b01;
                // bl, blx(1) blx suffix
                thumb_bl_blx_1_blx_suffix(ins);
                case 0b10;
                // bl, blx(1) prefix
                thumb_bl_blx_1_prefix(ins);
                case 0b11;
                // bl, blx(1) bl suffix
                thumb_bl_blx_1_bl_suffix(ins);
            }
        }
    }
}
