read_8 :: (addr: u32, execute := false) -> u8 {
    return mmu_read(addr, execute);
}

read_16 :: (addr: u32, execute := false) -> u16 {
    lo := cast(u16) read_8(addr, execute);
    hi := cast(u16) read_8(addr+1, execute);
    return lo | (hi << 8);
}

read_32 :: (addr: u32, execute := false) -> u32 {
    lo := cast(u32) read_16(addr, execute);
    hi := cast(u32) read_16(addr+2, execute);
    return  lo | (hi << 16);
}

write_8 :: (addr: u32, val: u8) {
    mmu_write(addr, val);
}

write_16 :: (addr: u32, val: u16) {
    write_8(addr, xx val & 0xff);
    write_8(addr+1, xx val >> 8);
}

write_32 :: (addr: u32, val: u32) {
    write_16(addr, xx val & 0xffff);
    write_16(addr+2, xx val >> 16);
}

next_8 :: (execute := false) -> u8 {
    ret := read_8(cpu.pc, execute);
    cpu.pc += 1;
    return ret;
}

next_16 :: (execute := false) -> u16 {
    ret := read_16(cpu.pc, execute);
    cpu.pc += 2;
    return ret;
}

next_32 :: (execute := false) -> u32 {
    ret := read_32(cpu.pc, execute);
    cpu.pc += 4;
    return ret;
}

get_status_bit :: inline (bit: Status_Bit) -> bool {
    if #complete bit == {
        case .N;
        return (cpu.psr & 0x80000000) != 0;
        case .Z;
        return (cpu.psr & 0x40000000) != 0;
        case .C;
        return (cpu.psr & 0x20000000) != 0;
        case .V;
        return (cpu.psr & 0x10000000) != 0;
    }
}

set_status_bit :: inline (bit: Status_Bit, state: bool) {
    if state {
        if #complete bit == {
            case .N;
            cpu.psr |= 0x80000000;
            case .Z;
            cpu.psr |= 0x40000000;
            case .C;
            cpu.psr |= 0x20000000;
            case .V;
            cpu.psr |= 0x10000000;
        }
    } else {
        if #complete bit == {
            case .N;
            cpu.psr &= ~cast(u32)0x80000000;
            case .Z;
            cpu.psr &= ~cast(u32)0x40000000;
            case .C;
            cpu.psr &= ~cast(u32)0x20000000;
            case .V;
            cpu.psr &= ~cast(u32)0x10000000;
        }
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
        ins := next_32(true);
        cpu.remaining_cycles -= 1;
        if !cond(xx (ins >> 28)) {
            return;
        }
        if ((ins >> 26) & 0b11) == {
            case 0b00;
                if (ins & 0xffffff0) == 0x12fff10 {
                    // branch & exchange
                    rm := reg_src(cast(u8) ins & 0xf);
                    cpu.state = ifx (rm & 1) != 0 then .THUMB else .ARM;
                    cpu.pc = rm & 0xfffffffe;
                    // cpu.pc += post_inc;
                    cpu.psr &= ~cast(u32)0x10;
                    cpu.psr |= (rm & 1) << 4;
                } else if (ins & 0xfc000f0) == 0x0000090 {
                    // multiply
                    assert(false);
                } else if (ins & 0xf8000f0) == 0x0800090 {
                    // multiply long
                    assert(false);
                } else if (ins & 0xfb00ff0) == 0x1000090 {
                    // single data swap
                    assert(false);
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
                        if (ins & 0x400000) != 0 {
                            // spsr
                            reg_dst(rd_idx, cpu.spsr[cpu.mode]);
                        } else {
                            // cpsr
                            reg_dst(rd_idx, cpu.psr);
                        }
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
                                result := rn - operand;
                                reg_dst(rd_idx, result);
                                if flags {
                                    set_status_bit(.N, (result & 0x80000000) != 0);
                                    set_status_bit(.Z, result == 0);
                                    set_status_bit(.C, rn >= operand);
                                    set_status_bit(.V, (rn & 0x80000000) != (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
                                }
                            case 0b0011;
                            // rsb
                            assert(false);
                            case 0b0100;
                                // add
                                result := rn + operand;
                                reg_dst(rd_idx, result);
                                if flags {
                                    set_status_bit(.N, (result & 0x80000000) != 0);
                                    set_status_bit(.Z, result == 0);
                                    set_status_bit(.C, cast(u64)(rn) + cast(u64)(operand) > 0xffffffff);
                                    set_status_bit(.V, (rn & 0x80000000) == (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
                                }
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
                                result := rn & operand;
                                if flags {
                                    set_status_bit(.N, (result & 0x80000000) != 0);
                                    set_status_bit(.Z, result == 0);
                                    if should_carry set_status_bit(.C, carry_out);
                                }
                            case 0b1001;
                                // teq
                                result := rn ^ operand;
                                if flags {
                                    set_status_bit(.N, (result & 0x80000000) != 0);
                                    set_status_bit(.Z, result == 0);
                                    if should_carry set_status_bit(.C, carry_out);
                                }
                            case 0b1010;
                                // cmp
                                result := rn - operand;
                                if flags {
                                    set_status_bit(.N, (result & 0x80000000) != 0);
                                    set_status_bit(.Z, result == 0);
                                    set_status_bit(.C, rn >= operand);
                                    set_status_bit(.V, (rn & 0x80000000) != (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
                                }
                            case 0b1011;
                            // would be msr, but handled outside
                            assert(false);
                            case 0b1100;
                            // orr
                            assert(false);
                            case 0b1101;
                                // mov
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
                            case 0b1110;
                                // bic
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
                            case 0b1111;
                            // mvn
                            assert(false);
                        }
                    }
                }
            case 0b01;
                // immediate offset/index load/store
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
            case 0b10;
                if (ins & 0x2000000) == 0 {
                    // block data transfer
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
                } else {
                    // branch
                    cpu.remaining_cycles -= 2;
                    if (ins & 0x1000000) == 0 {
                        // B
                        addr := (ins & 0x7fffff) << 2;
                        cpu.pc += addr;
                        sign := (ins & 0x800000) << 2;
                        cpu.pc -= sign;
                        cpu.pc += 4;
                    } else {
                        // BL
                        cpu.lr[cpu.mode] = cpu.pc;
                        addr := (ins & 0x7fffff) << 2;
                        cpu.pc += addr;
                        sign := (ins & 0x800000) << 2;
                        cpu.pc -= sign;
                        cpu.pc += 4;
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
            rn := reg_src(xx ((ins >> 3) & 0b111));
            rd_idx : u8 = xx ins & 0b111;
            if (ins >> 9) == {
                case 0b1100;
                // add (3)
                rm := reg_src(xx ((ins >> 6) & 0b111));
                result := rn + rm;
                set_status_bit(.N, (result & 0x80000000) != 0);
                set_status_bit(.Z, result == 0);
                set_status_bit(.C, cast(u64)(rn) + cast(u64)(rm) > 0xffffffff);
                set_status_bit(.V, (rn & 0x80000000) == (rm & 0x80000000) && (rn & 0x80000000) != (result & 0x80000000));
                reg_dst(rd_idx, result);
                case 0b1101;
                // sub (3)
                assert(false);
                case 0b1110;
                // add (1)
                // mov (2) if immediate is 0
                immed := (ins >> 6) & 0x7;
                result := rn + immed;
                set_status_bit(.N, (result & 0x80000000) != 0);
                set_status_bit(.Z, result == 0);
                set_status_bit(.C, cast(u64)(rn) + cast(u64)(immed) > 0xffffffff);
                set_status_bit(.V, (rn & 0x80000000) == (immed & 0x80000000) && (rn & 0x80000000) != (result & 0x80000000));
                reg_dst(rd_idx, result);
                case 0b1111;
                // sub (1)
                immed := (ins >> 6) & 0x7;
                result := rn - immed;
                set_status_bit(.N, (result & 0x80000000) != 0);
                set_status_bit(.Z, result == 0);
                set_status_bit(.C, rn >= immed);
                set_status_bit(.V, (rn & 0x80000000) != (immed & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
                reg_dst(rd_idx, result);
                case;
                // shift by immediate
                immed := (ins >> 6) & 0x1f;
                if ((ins >> 11) & 0b11) == {
                    case 0b00;
                    // lsl (1)
                    result := rn << immed;
                    if immed != 0 {
                        set_status_bit(.C, (rn & (1 << (32 - immed))) != 0);
                    }
                    reg_dst(rd_idx, result);
                    set_status_bit(.N, (result & 0x80000000) != 0);
                    set_status_bit(.Z, result == 0);
                    case 0b01;
                    // lsr (1)
                    result := rn >> immed;
                    if immed == 0 {
                        set_status_bit(.C, (reg_src(rd_idx) & 0x80000000) != 0);
                        result = 0;
                    } else {
                        set_status_bit(.C, (reg_src(rd_idx) & (1 << (immed - 1))) != 0);
                    }
                    reg_dst(rd_idx, result);
                    set_status_bit(.N, (result & 0x80000000) != 0);
                    set_status_bit(.Z, result == 0);
                    case 0b10;
                    // asr (1)
                    assert(false);
                    case 0b11;
                    // handled elsewhere
                    assert(false);
                }
            }
            case 0b001;
            // Add/subtract/compare/move immediate
            immed := ins & 0xff;
            reg_idx : u8 = xx (ins >> 8) & 0b111;
            reg := reg_src(reg_idx);
            if ((ins >> 11) & 0b11) == {
                case 0b00;
                // mov (1)
                reg_dst(reg_idx, immed);
                set_status_bit(.N, false);
                set_status_bit(.Z, immed == 0);
                case 0b01;
                // cmp (1)
                result := reg - immed;
                set_status_bit(.N, (result & 0x80000000) != 0);
                set_status_bit(.Z, result == 0);
                set_status_bit(.C, reg >= immed);
                set_status_bit(.V, (reg & 0x80000000) != (immed & 0x80000000) && (result & 0x80000000) != (reg & 0x80000000));
                case 0b10;
                // add (2)
                result := reg + immed;
                reg_dst(reg_idx, result);
                set_status_bit(.N, (result & 0x80000000) != 0);
                set_status_bit(.Z, result == 0);
                set_status_bit(.C, cast(u64)(reg) + cast(u64)(immed) > 0xffffffff);
                set_status_bit(.V, (reg & 0x80000000) == (immed & 0x80000000) && (reg & 0x80000000) != (result & 0x80000000));
                case 0b11;
                // sub (2)
                result := reg - immed;
                reg_dst(reg_idx, result);
                set_status_bit(.N, (result & 0x80000000) != 0);
                set_status_bit(.Z, result == 0);
                set_status_bit(.C, reg >= immed);
                set_status_bit(.V, (reg & 0x80000000) != (immed & 0x80000000) && (result & 0x80000000) != (reg & 0x80000000));
            }
            case 0b010;
            if (ins & 0x1000) != 0 {
                // Load/store register offset
                rm := reg_src(xx ((ins >> 6) & 0b111));
                rn := reg_src(xx ((ins >> 3) & 0b111));
                rd_idx : u8 = xx ins & 0b111;
                if ((ins >> 9) & 0b111) == {
                    case 0b000;
                    // str (2)
                    write_32(rm + rn, reg_src(rd_idx));
                    case 0b001;
                    // strh (2)
                    assert(false);
                    case 0b010;
                    // strb (2)
                    assert(false);
                    case 0b011;
                    // ldrsb
                    assert(false);
                    case 0b100;
                    // ldr (2)
                    assert(false);
                    case 0b101;
                    // ldrh (2)
                    assert(false);
                    case 0b110;
                    // ldrb (2)
                    assert(false);
                    case 0b111;
                    // ldrsh
                    assert(false);
                    case;
                    assert(false);
                }
            } else if (ins & 0x800) != 0 {
                // ldr (3)
                cpu.remaining_cycles -= 2;
                immed := ins & 0xff;
                reg_idx : u8 = xx (ins >> 8) & 0b111;
                reg_dst(reg_idx, read_32(((cpu.pc + 2) & 0xfffffffc) + immed * 4));
            } else if (ins & 0x400) != 0 {
                // special data processing + bx
                if ((ins >> 8) & 0b11) == {
                    case 0b00;
                    // add (4)
                    assert(false);
                    case 0b01;
                    // cmp (3)
                    rn := reg_src(xx (ins & 0b111) | ((ins >> 4) & 0b1000));
                    rm := reg_src(xx ((ins >> 3) & 0xf));
                    result := rn - rm;
                    set_status_bit(.N, (result & 0x80000000) != 0);
                    set_status_bit(.Z, result == 0);
                    set_status_bit(.C, rn >= rm);
                    set_status_bit(.V, (rn & 0x80000000) != (rm & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
                    case 0b10;
                    // mov (3)
                    rd_idx : u8 = xx ((ins & 0b111) | ((ins >> 4) & 0b1000));
                    rm := reg_src(xx ((ins >> 3) & 0xf));
                    reg_dst(rd_idx, rm);
                    case 0b11;
                    // bx / blx (2)
                    addr := reg_src(xx (ins >> 3) & 0xf);
                    if (ins & 0x80) != 0 then cpu.lr[cpu.mode] = (cpu.pc) | 1;
                    cpu.state = ifx (addr & 1) != 0 then .THUMB else .ARM;
                    cpu.psr &= ~cast(u32)0x10;
                    cpu.psr |= (addr & 1) << 4;
                    cpu.pc = addr & 0xfffffffe;
                }
            } else {
                // data processing register
                rm_idx : u8 = xx (ins >> 3) & 0b111;
                rs_idx : u8 = rm_idx;
                rd_idx : u8 = xx ins & 0b111;
                rn_idx : u8 = rd_idx;
                if ((ins >> 6) & 0xf) == {
                    case 0b0000;
                    // and
                    assert(false);
                    case 0b0001;
                    // eor
                    assert(false);
                    case 0b0010;
                    // lsl (2)
                    assert(false);
                    case 0b0011;
                    // lsr (2)
                    assert(false);
                    case 0b0100;
                    // asr (2)
                    assert(false);
                    case 0b0101;
                    // adc
                    assert(false);
                    case 0b0110;
                    // sbc
                    assert(false);
                    case 0b0111;
                    // ror
                    assert(false);
                    case 0b1000;
                    // tst
                    result := reg_src(rn_idx) & reg_src(rm_idx);
                    set_status_bit(.N, (result & 0x80000000) != 0);
                    set_status_bit(.Z, result == 0);
                    case 0b1001;
                    // neg
                    assert(false);
                    case 0b1010;
                    // cmp (2)
                    assert(false);
                    case 0b1011;
                    // cmn
                    assert(false);
                    case 0b1100;
                    // orr
                    result := reg_src(rm_idx) | reg_src(rd_idx);
                    reg_dst(rd_idx, result);
                    set_status_bit(.N, (result & 0x80000000) != 0);
                    set_status_bit(.Z, result == 0);
                    case 0b1101;
                    // mul
                    assert(false);
                    case 0b1110;
                    // bic
                    assert(false);
                    case 0b1111;
                    // mvn
                    result := ~reg_src(rm_idx);
                    reg_dst(rd_idx, result);
                    set_status_bit(.N, (result & 0x80000000) != 0);
                    set_status_bit(.Z, result == 0);
                }
            }
            case 0b011;
            // Load/store word/byte immediate offset
            l := (ins & 0x800) != 0; // load? (store)
            s := (ins & 0x1000) != 0; // byte? (word)
            imm := (ins >> 6) & 0x1f;
            rn := reg_src(xx (ins >> 3) & 0b111);
            rd_idx : u8 = xx (ins & 0b111);
            if l {
                cpu.remaining_cycles -= 2;
                if s {
                    reg_dst(rd_idx, xx read_8(rn + imm));
                } else {
                    reg_dst(rd_idx, read_32(rn + imm * 4));
                }
            } else {
                cpu.remaining_cycles -= 1;
                if s {
                    write_8(rn + imm, xx (reg_src(rd_idx) & 0xff));
                } else {
                    write_32(rn + imm * 4, reg_src(rd_idx));
                }
            }
            case 0b100;
            if (ins & 0x1000) != 0 {
                // Load/store to/from stack
                imm := ins & 0xff;
                reg_idx : u8 = xx (ins >> 8) & 0b111;
                addr := cpu.sp[cpu.mode] + 4 * imm;
                if (ins & 0x800) != 0 {
                    // ldr (4)
                    cpu.remaining_cycles -= 2;
                    reg_dst(reg_idx, read_32(addr));
                } else {
                    // str (3)
                    cpu.remaining_cycles -= 1;
                    write_32(addr, reg_src(reg_idx));
                }
            } else {
                // Load/store halfword immediate offset
                rd_idx : u8 = xx ins & 0b111;
                rn_idx : u8 = xx (ins >> 3) & 0b111;
                immed := (ins >> 6) & 0x1f;
                if (ins & 0x800) != 0 {
                    // ldrh (1)
                    cpu.remaining_cycles -= 2;
                    reg_dst(rd_idx, read_16(reg_src(rn_idx) + immed * 2));
                } else {
                    // strh (1)
                    cpu.remaining_cycles -= 1;
                    write_16(reg_src(rn_idx) + immed * 2, xx (reg_src(rd_idx) & 0xffff));
                }
            }
            case 0b101;
            if (ins & 0x1000) != 0 {
                // Miscellaneous
                if (ins & 0x200) != 0 {
                    // software breakpoint?
                    assert(false);
                } else if (ins & 0x400) != 0 {
                    // push/pop register list
                    if (ins & 0x800) != 0 {
                        // pop
                        for 0..7 {
                            if (ins & (1 << it)) != 0 {
                                cpu.remaining_cycles -= 1;
                                cpu.gpr[it] = read_32(cpu.sp[cpu.mode]);
                                cpu.sp[cpu.mode] += 4;
                            }
                        }
                        if (ins & 0x100) != 0 {
                            cpu.remaining_cycles -= 1;
                            cpu.pc = read_32(cpu.sp[cpu.mode]);
                            cpu.state = ifx (cpu.pc & 1) != 0 then .THUMB else .ARM;
                            cpu.psr &= ~cast(u32)0x10;
                            cpu.psr |= (cpu.pc & 1) << 4;
                            cpu.pc &= 0xfffffffe;
                        }
                    } else {
                        // push
                        if (ins & 0x100) != 0 {
                            cpu.remaining_cycles -= 1;
                            cpu.sp[cpu.mode] -= 4;
                            write_32(cpu.sp[cpu.mode], cpu.lr[cpu.mode]);
                        }
                        for #v2 < 0..7 {
                            if (ins & (1 << it)) != 0 {
                                cpu.remaining_cycles -= 1;
                                cpu.sp[cpu.mode] -= 4;
                                write_32(cpu.sp[cpu.mode], cpu.gpr[it]);
                            }
                        }
                    }
                } else {
                    // add (7), sub (4)
                    op := (ins & 0x80) != 0;
                    if op {
                        cpu.sp[cpu.mode] -= (ins & 0x7f) << 2;
                    } else {
                        cpu.sp[cpu.mode] += (ins & 0x7f) << 2;
                    }
                }
            } else {
                // Add to SP or PC
                assert(false);
            }
            case 0b110;
            if (ins & 0x1000) != 0 {
                // B (1)
                if cond(xx (ins >> 8) & 0xf) {
                    immed := (ins & 0xff) << 1;
                    cpu.pc += immed & 0xff;
                    cpu.pc -= immed & 0x100;
                    cpu.pc += 2;
                }
            } else {
                // Load/store multiple
                assert(false);
            }
            case 0b111;
            offset := ins & 0x7ff;
            if ((ins >> 11) & 0b11) == {
                case 0b00;
                // B (2)
                offset <<= 1;
                cpu.pc += offset;
                if (offset & 0x800) != 0 {
                    cpu.pc -= 0x1000;
                }
                cpu.pc += 2;
                case 0b01;
                // BL, BLX(1) blx suffix
                assert(false);
                case 0b10;
                // BL, BLX(1) prefix
                offset_adj : u32 = xx offset;
                if (offset_adj & 0x400) != 0 {
                     cpu.lr[cpu.mode] = cpu.pc + ((offset_adj << 12) | 0xff800000) + 2;
                } else {
                     cpu.lr[cpu.mode] = cpu.pc + (offset_adj << 12) + 2;
                }
                case 0b11;
                // BL, BLX(1) bl suffix
                next := cpu.pc;
                cpu.pc = cpu.lr[cpu.mode] + (offset << 1);
                cpu.lr[cpu.mode] = next | 1;
            }
        }
    }
}
