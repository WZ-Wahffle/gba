arm_bx :: inline (ins: u32) {
    rm := reg_src(cast(u8) ins & 0xf);
    cpu.state = ifx (rm & 1) != 0 then .THUMB else .ARM;
    cpu.pc = rm & 0xfffffffe;
    // cpu.pc += post_inc;
    cpu.psr &= ~cast(u32)0x10;
    cpu.psr |= (rm & 1) << 4;
}

arm_mul_mla :: inline (ins: u32) {
    assert(false);
}

arm_umull_umlal_smull_smlal :: inline (ins: u32) {
    assert(false);
}

arm_swp_swpb :: inline (ins: u32) {
    assert(false);
}

arm_ldrh_strh :: inline (ins: u32) {
    rn_idx : u8 = xx (ins >> 16) & 0xf;
    rn := reg_src(rn_idx);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    p := (ins & 0x1000000);
    u := (ins & 0x800000);
    w := (ins & 0x200000);
    l := (ins & 0x100000);
    address := rn;
    offset: u32;
    if (ins & 0x400000) != 0 {
        offset = (ins & 0x0f) | ((ins >> 4) & 0xf0);
    } else {
        offset = reg_src(xx ins & 0xf);
    }

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
        reg_dst(rd_idx, read_16(address));
    } else {
        // store
        cpu.remaining_cycles -= 1;
        write_16(address, xx (reg_src(rd_idx) & 0xffff));
    }
}

arm_ldrsb_ldrsh :: inline (ins: u32) {
    assert(false);
}

arm_mrs :: inline (ins: u32) {
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    if (ins & 0x400000) != 0 {
        // spsr
        reg_dst(rd_idx, cpu.spsr[cpu.mode]);
    } else {
        // cpsr
        reg_dst(rd_idx, cpu.psr);
    }
}

arm_msr :: inline (ins: u32) {
    to_write := ifx (ins & 0x2000000) != 0 then immediate_operand(xx ins & 0xfff) else reg_src(xx (ins & 0xf));
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
}

arm_and :: inline (ins: u32) {
    operand: u32;
    should_carry: bool;
    carry_out: bool;
    if (ins & 0x2000000) {
        operand, should_carry, carry_out = immediate_operand(xx ins & 0xfff);
    } else {
        operand, should_carry, carry_out = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    flags := (ins & 0x100000) != 0;
    result := rn & operand;
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

arm_eor :: inline (ins: u32) {
    operand: u32;
    should_carry: bool;
    carry_out: bool;
    if (ins & 0x2000000) {
        operand, should_carry, carry_out = immediate_operand(xx ins & 0xfff);
    } else {
        operand, should_carry, carry_out = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    flags := (ins & 0x100000) != 0;
    result := rn ^ operand;
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

arm_sub :: inline (ins: u32) {
    operand: u32;
    if (ins & 0x2000000) {
        operand = immediate_operand(xx ins & 0xfff);
    } else {
        operand = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    flags := (ins & 0x100000) != 0;
    result := rn - operand;
    reg_dst(rd_idx, result);
    if flags {
        if rd_idx == 15 {
            cpu.psr = cpu.spsr[cpu.mode];
        } else {
            set_status_bit(.N, (result & 0x80000000) != 0);
            set_status_bit(.Z, result == 0);
            set_status_bit(.C, rn >= operand);
            set_status_bit(.V, (rn & 0x80000000) != (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
        }
    }
}

arm_rsb :: inline (ins: u32) {
    operand: u32;
    if (ins & 0x2000000) {
        operand = immediate_operand(xx ins & 0xfff);
    } else {
        operand = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    flags := (ins & 0x100000) != 0;
    result := operand - rn;
    reg_dst(rd_idx, result);
    if flags {
        if rd_idx == 15 {
            cpu.psr = cpu.spsr[cpu.mode];
        } else {
            set_status_bit(.N, (result & 0x80000000) != 0);
            set_status_bit(.Z, result == 0);
            set_status_bit(.C, operand >= rn);
            set_status_bit(.V, (operand & 0x80000000) != (rn & 0x80000000) && (result & 0x80000000) != (operand & 0x80000000));
        }
    }
}

arm_add :: inline (ins: u32) {
    operand: u32;
    if (ins & 0x2000000) {
        operand = immediate_operand(xx ins & 0xfff);
    } else {
        operand = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    flags := (ins & 0x100000) != 0;
    result := rn + operand;
    reg_dst(rd_idx, result);
    if flags {
        if rd_idx == 15 {
            cpu.psr = cpu.spsr[cpu.mode];
        } else {
            set_status_bit(.N, (result & 0x80000000) != 0);
            set_status_bit(.Z, result == 0);
            set_status_bit(.C, cast(u64)(rn) + cast(u64)(operand) > 0xffffffff);
            set_status_bit(.V, (rn & 0x80000000) == (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
        }
    }
}

arm_adc :: inline (ins: u32) {
    operand: u32;
    if (ins & 0x2000000) {
        operand = immediate_operand(xx ins & 0xfff);
    } else {
        operand = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    flags := (ins & 0x100000) != 0;
    operand += xx ifx get_status_bit(.C) then 1 else 0;
    result := rn + operand;
    reg_dst(rd_idx, result);
    if flags {
        if rd_idx == 15 {
            cpu.psr = cpu.spsr[cpu.mode];
        } else {
            set_status_bit(.N, (result & 0x80000000) != 0);
            set_status_bit(.Z, result == 0);
            set_status_bit(.C, cast(u64)(rn) + cast(u64)(operand) > 0xffffffff);
            set_status_bit(.V, (rn & 0x80000000) == (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
        }
    }
}

arm_sbc :: inline (ins: u32) {
    assert(false);
}

arm_rsc :: inline (ins: u32) {
    assert(false);
}

arm_tst :: inline (ins: u32) {
    operand: u32;
    should_carry: bool;
    carry_out: bool;
    if (ins & 0x2000000) {
        operand, should_carry, carry_out = immediate_operand(xx ins & 0xfff);
    } else {
        operand, should_carry, carry_out = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    result := rn & operand;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    if should_carry set_status_bit(.C, carry_out);
}

arm_teq :: inline (ins: u32) {
    operand: u32;
    should_carry: bool;
    carry_out: bool;
    if (ins & 0x2000000) {
        operand, should_carry, carry_out = immediate_operand(xx ins & 0xfff);
    } else {
        operand, should_carry, carry_out = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    result := rn ^ operand;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    if should_carry set_status_bit(.C, carry_out);

}

arm_cmp :: inline (ins: u32) {
    operand: u32;
    should_carry: bool;
    carry_out: bool;
    if (ins & 0x2000000) {
        operand, should_carry, carry_out = immediate_operand(xx ins & 0xfff);
    } else {
        operand, should_carry, carry_out = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    result := rn - operand;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, rn >= operand);
    set_status_bit(.V, (rn & 0x80000000) != (operand & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
}

arm_orr :: inline (ins: u32) {
    operand: u32;
    should_carry: bool;
    carry_out: bool;
    if (ins & 0x2000000) {
        operand, should_carry, carry_out = immediate_operand(xx ins & 0xfff);
    } else {
        operand, should_carry, carry_out = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    flags := (ins & 0x100000) != 0;
    result := rn | operand;
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

arm_mov :: inline (ins: u32) {
    operand: u32;
    should_carry: bool;
    carry_out: bool;
    if (ins & 0x2000000) {
        operand, should_carry, carry_out = immediate_operand(xx ins & 0xfff);
    } else {
        operand, should_carry, carry_out = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    flags := (ins & 0x100000) != 0;
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

arm_bic :: inline (ins: u32) {
    operand: u32;
    should_carry: bool;
    carry_out: bool;
    if (ins & 0x2000000) {
        operand, should_carry, carry_out = immediate_operand(xx ins & 0xfff);
    } else {
        operand, should_carry, carry_out = shifter_operand(xx ins & 0xfff);
        cpu.remaining_cycles -= 1;
    }
    rn := reg_src(xx (ins >> 16) & 0xf);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
    flags := (ins & 0x100000) != 0;
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

arm_mvn :: inline (ins: u32) {
    assert(false);
}

arm_ldr_str_ldrb_strb :: inline (ins: u32) {
    rn_idx : u8 = xx (ins >> 16) & 0xf;
    rn := reg_src(rn_idx);
    rd_idx : u8 = xx (ins >> 12) & 0xf;
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
        }
        if w then reg_dst(rn_idx, pointer);
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
        }
        if w then reg_dst(rn_idx, pointer);
    }
}

arm_b :: inline (ins: u32) {
    cpu.remaining_cycles -= 2;
    addr := (ins & 0x7fffff) << 2;
    cpu.pc += addr;
    sign := (ins & 0x800000) << 2;
    cpu.pc -= sign;
    cpu.pc += 4;
}

arm_bl :: inline (ins: u32) {
    cpu.remaining_cycles -= 2;
    cpu.lr[cpu.mode] = cpu.pc;
    addr := (ins & 0x7fffff) << 2;
    cpu.pc += addr;
    sign := (ins & 0x800000) << 2;
    cpu.pc -= sign;
    cpu.pc += 4;
}

arm_ldc_stc :: inline (ins: u32) {
    assert(false);
}

arm_cdp :: inline (ins: u32) {
    assert(false);
}

arm_mcr_mrc :: inline (ins: u32) {
    assert(false);
}

arm_swi :: inline (ins: u32) {
    assert(false);
}
