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

get_status_bit :: (bit: Status_Bit) -> bool {
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

set_status_bit :: (bit: Status_Bit, state: bool) {
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
        return cpu.gpr[val];
    } else if val == 13 {
        return cpu.sp;
    } else if val == 14 {
        return cpu.lr;
    } else if val == 15 {
        return cpu.pc;
    } else {
        assert(false);
        return 0;
    }
}

reg_dst :: (val: u8, to_write: u32) {
    if val < 13 {
        cpu.gpr[val] = to_write;
    } else if val == 13 {
        cpu.sp = to_write;
    } else if val == 14 {
        cpu.lr = to_write;
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
            return xx val, false, false;
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
            shift_cnt := (val >> 7) + 1;
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
            shift_cnt := (val >> 7) + 1;
            carry := (ret & (1 << (shift_cnt-1))) != 0;
            if ret & 0x80000000 {
                sign_bit_fill := cast(u32)0xffffffff << (32 - shift_cnt);
                return (ret >> shift_cnt) | sign_bit_fill, true, carry;
            }
            return ret >> shift_cnt, true, carry;
        case 0b101;
            // register operand + logical shift right reg
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
            // register operand + logical shift right imm
            ret : u32 = reg_src(xx (val & 0xf));
            rotate_cnt : u32 = (val >> 7) + 1;
            if rotate_cnt == 1 {
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
        print("%: %\n", formatInt(cpu.pc, 16, 8), formatInt(ins, 16, 8));
        if !cond(xx (ins >> 28)) {
            return;
        }
        if ((ins >> 26) & 0b11) == {
            case 0b00;
                if (ins & 0xffffff0) == 0x12fff10 {
                    // branch & exchange
                    assert(false);
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
                    if (ins & 0xfb00000) == 0x3200000 {
                        // msr immediate
                        assert(false);
                    } else if (ins & 0xfb000f0) == 0x1200000 {
                        // msr reg
                        to_write := reg_src(xx (ins & 0xf));
                        c := (ins & 0x10000) != 0;
                        f := (ins & 0x80000) != 0;
                        if (ins & 0x400000) != 0 {
                            // spsr
                            if f {
                                cpu.spsr[cpu.mode] &= 0x00ffffff;
                                cpu.spsr[cpu.mode] |= to_write & 0xff000000;
                            }
                            if c && cpu.mode != .USER && cpu.mode != .SYSTEM {
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
                            if c && cpu.mode != .USER {
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
                                    set_status_bit(.V, (rn & 0x80000000) == (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
                                }
                            case 0b0011;
                            // rsb
                            assert(false);
                            case 0b0100;
                            // add
                            assert(false);
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
                            assert(false);
                            case 0b1001;
                                // teq
                                result := rn ^ operand;
                                set_status_bit(.N, (result & 0x80000000) != 0);
                                set_status_bit(.Z, result == 0);
                                if should_carry set_status_bit(.C, carry_out);
                            case 0b1010;
                                // cmp
                                result := rn - operand;
                                if flags {
                                    set_status_bit(.N, (result & 0x80000000) != 0);
                                    set_status_bit(.Z, result == 0);
                                    set_status_bit(.C, rn >= operand);
                                    set_status_bit(.V, (rn & 0x80000000) == (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
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
                            assert(false);
                            case 0b1111;
                            // mvn
                            assert(false);
                        }
                    }
                }
            case 0b01;
                // immediate offset/index load/store
                rn_idx := cast(u8)((ins >> 12) & 0xf);
                rn := reg_src(rn_idx);
                rd_idx := cast(u8)((ins >> 16) & 0xf);
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
                    if b {
                        reg_dst(rd_idx, read_8(address));
                    } else {
                        reg_dst(rd_idx, read_32(address));
                    }
                } else {
                    // store
                    if b {
                        write_8(address, xx (reg_src(rd_idx) & 0xff));
                    } else {
                        write_32(address, reg_src(rd_idx));
                    }
                }
            case 0b10;
                if (ins & 0x2000000) == 0 {
                    // block data transfer
                    assert(false);
                } else {
                    // branch
                    if (ins & 0x1000000) == 0 {
                        // B
                        addr := (ins & 0x7fffff) << 2;
                        cpu.pc += addr;
                        sign := (ins & 0x800000) << 2;
                        cpu.pc -= sign;
                        cpu.pc += 4;
                    } else {
                        // BL
                        cpu.lr = cpu.pc;
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
        assert(false);
        ins := next_16();
    }
}
