arm_bx :: inline (ins: u32) {
    if (ins & 0xfff00) != 0xfff00 assert(false);
    rm := reg_src(cast(u8) ins & 0xf);
    cpu.state = ifx (rm & 1) != 0 then .THUMB else .ARM;
    set_status_bit(.T, (rm & 1) != 0);
    cpu.reg[15] = rm & 0xfffffffe;
    // cpu.reg[15] += post_inc;
    cpu.psr &= ~cast(u32)0x10;
    cpu.psr |= (rm & 1) << 4;
}

arm_mul_mla :: inline (ins: u32) {
    // verify 12..15 is zero if mul
    rd_idx : u8 = xx (ins >> 16) & 0xf;
    rs := reg_src(xx (ins >> 8) & 0xf);
    rm := reg_src(xx ins & 0xf);
    flags := (ins & 0x100000) != 0;
    result : u32;
    if (ins & 0x200000) != 0 {
        rn := reg_src(xx (ins >> 12) & 0xf);
        result = rm * rs + rn;
    } else {
        assert(((ins >> 12) & 0xf) == 0);
        result = rm * rs;
    }
    reg_dst(rd_idx, result);
    if flags {
        set_status_bit(.N, (result & 0x80000000) != 0);
        set_status_bit(.Z, result == 0);
    }
}

arm_umull_umlal_smull_smlal :: inline (ins: u32) {
    assert(false);
}

arm_swp_swpb :: inline (ins: u32) {
    // verify that bits 8..11 are actually zero
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

    cpu.remaining_cycles -= 2;
    if (ins & 0x20) != 0 {
        // ldrsh
        to_write : u32 = xx read_16(address);
        if (to_write & 0x8000) != 0 then to_write |= 0xffff0000;
        reg_dst(rd_idx, to_write);
    } else {
        // ldrsb
        to_write : u32 = xx read_8(address);
        if (to_write & 0x80) != 0 then to_write |= 0xffffff00;
        reg_dst(rd_idx, to_write);
    }
}

arm_mrs :: inline (ins: u32) {
    if (ins & 0xf0000) != 0xf0000 assert(false);
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
    to_write : u32;
    if (ins & 0x2000000) != 0 {
        to_write = immediate_operand(xx ins & 0xfff);
    } else {
        if (ins & 0xff00) != 0xf000 assert(false);
        to_write = reg_src(xx (ins & 0xf));
    }
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
            set_mode(to_write & 0x1f);
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
            set_mode(to_write & 0x1f);
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
    if (ins & 0xf0000) != 0 assert(false);
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
    if (ins & 0xf0000) != 0 assert(false);
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
                if s && cpu.mode != .USER {
                    if it < 13 {
                        cpu.reg[it] = to_store;
                    } else if it == 13 {
                        cpu.sp[0] = to_store;
                    } else if it == 14 {
                        cpu.lr[0] = to_store;
                    } else {
                        cpu.reg[15] = to_store;
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
                        to_store = cpu.reg[it];
                    } else if it == 13 {
                        to_store = cpu.sp[0];
                    } else if it == 14 {
                        to_store = cpu.lr[0];
                    } else {
                        to_store = cpu.reg[15];
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
    cpu.reg[15] += addr;
    sign := (ins & 0x800000) << 2;
    cpu.reg[15] -= sign;
    cpu.reg[15] += 4;
}

arm_bl :: inline (ins: u32) {
    cpu.remaining_cycles -= 2;
    cpu.reg[14] = cpu.reg[15];
    addr := (ins & 0x7fffff) << 2;
    cpu.reg[15] += addr;
    sign := (ins & 0x800000) << 2;
    cpu.reg[15] -= sign;
    cpu.reg[15] += 4;
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

arm_bkpt :: inline (ins: u32) {
    if cpu.emu_state != .RUNNING {
        idx := (ins & 0xf) | ((ins >> 4) & 0xfff0);
        cpu.reg[15] -= 4;
        addr := cpu.reg[15];
        write_32(addr, cpu.breakpoints_arm[idx], true);
        execute_next();
        write_32(addr, ins, true);
    } else {
        cpu.emu_state = .STOPPED;
        cpu.reg[15] -= 4;
    }
}
