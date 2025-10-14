thumb_add_3 :: inline (ins: u16) {
    rn := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    rm := reg_src(xx ((ins >> 6) & 0b111));
    result := rn + rm;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, cast(u64)(rn) + cast(u64)(rm) > 0xffffffff);
    set_status_bit(.V, (rn & 0x80000000) == (rm & 0x80000000) && (rn & 0x80000000) != (result & 0x80000000));
    reg_dst(rd_idx, result);
}

thumb_sub_3 :: inline (ins: u16) {
    rn := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    rm := reg_src(xx ((ins >> 6) & 0b111));
    result := rn - rm;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, rn >= rm);
    set_status_bit(.V, (rn & 0x80000000) != (rm & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
    reg_dst(rd_idx, result);
}

thumb_add_1 :: inline (ins: u16) {
    rn := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    immed := (ins >> 6) & 0x7;
    result := rn + immed;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, cast(u64)(rn) + cast(u64)(immed) > 0xffffffff);
    set_status_bit(.V, (rn & 0x80000000) == (immed & 0x80000000) && (rn & 0x80000000) != (result & 0x80000000));
    reg_dst(rd_idx, result);
}

thumb_sub_1 :: inline (ins: u16) {
    rn := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    immed := (ins >> 6) & 0x7;
    result := rn - immed;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, rn >= immed);
    set_status_bit(.V, (rn & 0x80000000) != (immed & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
    reg_dst(rd_idx, result);
}

thumb_lsl_1 :: inline (ins: u16) {
    rn := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    immed := (ins >> 6) & 0x1f;
    result := rn << immed;
    if immed != 0 {
        set_status_bit(.C, (rn & (1 << (32 - immed))) != 0);
    }
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_lsr_1 :: inline (ins: u16) {
    rn := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    immed := (ins >> 6) & 0x1f;
    result := rn >> immed;
    if immed == 0 {
        set_status_bit(.C, (rn & 0x80000000) != 0);
        result = 0;
    } else {
        set_status_bit(.C, (rn & (1 << (immed - 1))) != 0);
    }
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_asr_1 :: inline (ins: u16) {
    rm := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    immed := (ins >> 6) & 0x1f;
    result := rm;
    #asm {
        immed === c;
        sar.32 result, immed;
    }
    if immed == 0 {
        set_status_bit(.C, (rm & 0x80000000) != 0);
        if (rm & 0x80000000) != 0 {
            result = 0xffffffff;
        } else {
            result = 0;
        }
    } else {
        set_status_bit(.C, (rm & (1 << (immed - 1))) != 0);
    }
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_mov_1 :: inline (ins: u16) {
    immed := ins & 0xff;
    reg_idx : u8 = xx (ins >> 8) & 0b111;
    reg := reg_src(reg_idx);
    reg_dst(reg_idx, immed);
    set_status_bit(.N, false);
    set_status_bit(.Z, immed == 0);
}

thumb_cmp_1 :: inline (ins: u16) {
    immed := ins & 0xff;
    reg_idx : u8 = xx (ins >> 8) & 0b111;
    reg := reg_src(reg_idx);
    result := reg - immed;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, reg >= immed);
    set_status_bit(.V, (reg & 0x80000000) != (immed & 0x80000000) && (result & 0x80000000) != (reg & 0x80000000));
}

thumb_add_2 :: inline (ins: u16) {
    immed := ins & 0xff;
    reg_idx : u8 = xx (ins >> 8) & 0b111;
    reg := reg_src(reg_idx);
    result := reg + immed;
    reg_dst(reg_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, cast(u64)(reg) + cast(u64)(immed) > 0xffffffff);
    set_status_bit(.V, (reg & 0x80000000) == (immed & 0x80000000) && (reg & 0x80000000) != (result & 0x80000000));
}

thumb_sub_2 :: inline (ins: u16) {
    immed := ins & 0xff;
    reg_idx : u8 = xx (ins >> 8) & 0b111;
    reg := reg_src(reg_idx);
    result := reg - immed;
    reg_dst(reg_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, reg >= immed);
    set_status_bit(.V, (reg & 0x80000000) != (immed & 0x80000000) && (result & 0x80000000) != (reg & 0x80000000));
}

thumb_str_2 :: inline (ins: u16) {
    rm := reg_src(xx ((ins >> 6) & 0b111));
    rn := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    write_32(rm + rn, reg_src(rd_idx));
}

thumb_strh_2 :: inline (ins: u16) {
    rd_idx : u8 = xx ins & 0b111;
    rn := reg_src(xx (ins >> 3) & 0b111);
    rm := reg_src(xx (ins >> 6) & 0b111);
    write_16(rn + rm, xx reg_src(rd_idx));
}

thumb_strb_2 :: inline (ins: u16) {
    assert(false);
}

thumb_ldrsb :: inline (ins: u16) {
    rm := reg_src(xx ((ins >> 6) & 0b111));
    rn := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    to_write : u32 = read_8(rm + rn);
    if (to_write & 0x80) != 0 then to_write |= 0xffffff00;
    reg_dst(rd_idx, to_write);
}

thumb_ldr_2 :: inline (ins: u16) {
    rm := reg_src(xx ((ins >> 6) & 0b111));
    rn := reg_src(xx ((ins >> 3) & 0b111));
    rd_idx : u8 = xx ins & 0b111;
    reg_dst(rd_idx, read_32(rm + rn));
}

thumb_ldrh_2 :: inline (ins: u16) {
    rd_idx : u8 = xx ins & 0b111;
    rn := reg_src(xx (ins >> 3) & 0b111);
    rm := reg_src(xx (ins >> 6) & 0b111);
    reg_dst(rd_idx, read_16(rn + rm));
}

thumb_ldrb_2 :: inline (ins: u16) {
    rd_idx : u8 = xx ins & 0b111;
    rn := reg_src(xx (ins >> 3) & 0b111);
    rm := reg_src(xx (ins >> 6) & 0b111);
    reg_dst(rd_idx, read_8(rn + rm));
}

thumb_ldrsh :: inline (ins: u16) {
    assert(false);
}

thumb_ldr_3 :: inline (ins: u16) {
    cpu.remaining_cycles -= 2;
    immed := ins & 0xff;
    reg_idx : u8 = xx (ins >> 8) & 0b111;
    reg_dst(reg_idx, read_32(((cpu.reg[15] + 2) & 0xfffffffc) + immed * 4));
}

thumb_add_4 :: inline (ins: u16) {
    assert(false);
}

thumb_cmp_3 :: inline (ins: u16) {
    rn := reg_src(xx (ins & 0b111) | ((ins >> 4) & 0b1000));
    rm := reg_src(xx ((ins >> 3) & 0xf));
    result := rn - rm;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, rn >= rm);
    set_status_bit(.V, (rn & 0x80000000) != (rm & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
}

thumb_mov_3 :: inline (ins: u16) {
    rd_idx : u8 = xx ((ins & 0b111) | ((ins >> 4) & 0b1000));
    rm := reg_src(xx ((ins >> 3) & 0xf));
    reg_dst(rd_idx, rm);
}

thumb_bx_blx_2 :: inline (ins: u16) {
    addr := reg_src(xx (ins >> 3) & 0xf);
    if (ins & 0x80) != 0 then cpu.reg[14] = (cpu.reg[15]) | 1;
    cpu.state = ifx (addr & 1) != 0 then .THUMB else .ARM;
    set_status_bit(.T, (addr & 1) != 0);
    cpu.psr &= ~cast(u32)0x10;
    cpu.psr |= (addr & 1) << 4;
    cpu.reg[15] = addr & 0xfffffffe;
}

thumb_and :: inline (ins: u16) {
    rm_idx : u8 = xx (ins >> 3) & 0b111;
    rd_idx : u8 = xx ins & 0b111;
    result := reg_src(rm_idx) & reg_src(rd_idx);
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_eor :: inline (ins: u16) {
    rm_idx : u8 = xx (ins >> 3) & 0b111;
    rd_idx : u8 = xx ins & 0b111;
    result := reg_src(rm_idx) ^ reg_src(rd_idx);
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_lsl_2 :: inline (ins: u16) {
    assert(false);
}

thumb_lsr_2 :: inline (ins: u16) {
    rs := reg_src(xx ((ins >> 3) & 0b111)) & 0xff;
    rd_idx : u8 = xx ins & 0b111;
    result := reg_src(rd_idx) >> rs;
    if rs == 0 {
        // this page intentionally left blank
    } else if rs == 32 {
        set_status_bit(.C, (reg_src(rd_idx) & 0x80000000) != 0);
    } else if rs > 32 {
        set_status_bit(.C, false);
    } else {
        set_status_bit(.C, (reg_src(rd_idx) & (1 << (rs - 1))) != 0);
    }
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_asr_2 :: inline (ins: u16) {
    assert(false);
}

thumb_adc :: inline (ins: u16) {
    assert(false);
}

thumb_sbc :: inline (ins: u16) {
    assert(false);
}

thumb_ror :: inline (ins: u16) {
    rd_idx : u8 = xx ins & 0b111;
    rs := reg_src(xx (ins >> 3) & 0b111) & 0xff;
    rd := reg_src(rd_idx);
    if rs == 0 {
        // nothing happens
    } else if (rs & 0x1f) == 0 {
        set_status_bit(.C, (rd & 0x80000000) != 0);
    } else {
        set_status_bit(.C, (rd & (1 << ((rs & 0x1f) - 1))) != 0);
        #asm {
            rs === c;
            ror.32 rd, rs;
        }
    }
    reg_dst(rd_idx, rd);
    set_status_bit(.Z, rd == 0);
    set_status_bit(.N, (rd & 0x80000000) != 0);
}

thumb_tst :: inline (ins: u16) {
    rm_idx : u8 = xx (ins >> 3) & 0b111;
    rn_idx : u8 = xx ins & 0b111;
    result := reg_src(rn_idx) & reg_src(rm_idx);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_neg :: inline (ins: u16) {
    rm_idx : u8 = xx (ins >> 3) & 0b111;
    rm := reg_src(rm_idx);
    rd_idx : u8 = xx ins & 0b111;
    result := 0 - rm;
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    // technically would be set if 0 were greater, but... yeah
    set_status_bit(.C, false);
    // I suspect this can only happen if result == 0x80000000?
    set_status_bit(.V, (rm & 0x80000000) != 0 && (result & 0x80000000) != 0);
}

thumb_cmp_2 :: inline (ins: u16) {
    rm := reg_src(xx (ins >> 3) & 0b111);
    rn := reg_src(xx ins & 0b111);
    result := rn - rm;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, rn >= rm);
    set_status_bit(.V, (rn & 0x80000000) != (rm & 0x80000000) && (result & 0x80000000) != (rn & 0x80000000));
}

thumb_cmn :: inline (ins: u16) {
    rm := reg_src(xx (ins >> 3) & 0b111);
    rn := reg_src(xx ins & 0b111);
    result := rn + rm;
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
    set_status_bit(.C, cast(u64)(rn) + cast(u64)(rm) > 0xffffffff);
    set_status_bit(.V, (rn & 0x80000000) == (rm & 0x80000000) && (rn & 0x80000000) != (result & 0x80000000));
}

thumb_orr :: inline (ins: u16) {
    rm_idx : u8 = xx (ins >> 3) & 0b111;
    rd_idx : u8 = xx ins & 0b111;
    result := reg_src(rm_idx) | reg_src(rd_idx);
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_mul :: inline (ins: u16) {
    rm_idx : u8 = xx (ins >> 3) & 0b111;
    rd_idx : u8 = xx ins & 0b111;
    result : u32 = reg_src(rm_idx) * reg_src(rd_idx);
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_bic :: inline (ins: u16) {
    rm_idx : u8 = xx (ins >> 3) & 0b111;
    rd_idx : u8 = xx ins & 0b111;
    result := ~reg_src(rm_idx) & reg_src(rd_idx);
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_mvn :: inline (ins: u16) {
    rm_idx : u8 = xx (ins >> 3) & 0b111;
    rd_idx : u8 = xx ins & 0b111;
    result := ~reg_src(rm_idx);
    reg_dst(rd_idx, result);
    set_status_bit(.N, (result & 0x80000000) != 0);
    set_status_bit(.Z, result == 0);
}

thumb_ldr_str_ldrb_strb_1 :: inline (ins: u16) {
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
}

thumb_ldr_4 :: inline (ins: u16) {
    imm := ins & 0xff;
    reg_idx : u8 = xx (ins >> 8) & 0b111;
    addr := cpu.reg[13] + 4 * imm;
    cpu.remaining_cycles -= 2;
    reg_dst(reg_idx, read_32(addr));
}

thumb_str_3 :: inline (ins: u16) {
    imm := ins & 0xff;
    reg_idx : u8 = xx (ins >> 8) & 0b111;
    addr := cpu.reg[13] + 4 * imm;
    cpu.remaining_cycles -= 1;
    write_32(addr, reg_src(reg_idx));
}

thumb_ldrh_1 :: inline (ins: u16) {
    rd_idx : u8 = xx ins & 0b111;
    rn_idx : u8 = xx (ins >> 3) & 0b111;
    immed := (ins >> 6) & 0x1f;
    cpu.remaining_cycles -= 2;
    reg_dst(rd_idx, read_16(reg_src(rn_idx) + immed * 2));
}

thumb_strh_1 :: inline (ins: u16) {
    rd_idx : u8 = xx ins & 0b111;
    rn_idx : u8 = xx (ins >> 3) & 0b111;
    immed := (ins >> 6) & 0x1f;
    cpu.remaining_cycles -= 1;
    write_16(reg_src(rn_idx) + immed * 2, xx (reg_src(rd_idx) & 0xffff));
}

thumb_bkpt :: inline (ins: u16) {
    if cpu.emu_state != .RUNNING {
        idx := ins & 0xff;
        cpu.reg[15] -= 2;
        addr := cpu.reg[15];
        write_16(addr, cpu.breakpoints_thumb[idx], true);
        execute_next();
        write_16(addr, ins, true);
    } else {
        cpu.emu_state = .STOPPED;
        cpu.reg[15] -= 2;
    }
}

thumb_pop :: inline (ins: u16) {
    for 0..7 {
        if (ins & (1 << it)) != 0 {
            cpu.remaining_cycles -= 1;
            cpu.reg[it] = read_32(cpu.reg[13]);
            cpu.reg[13] += 4;
        }
    }
    if (ins & 0x100) != 0 {
        cpu.remaining_cycles -= 1;
        cpu.reg[15] = read_32(cpu.reg[13]);
        cpu.state = ifx (cpu.reg[15] & 1) != 0 then .THUMB else .ARM;
        set_status_bit(.T, (cpu.reg[15] & 1) != 0);
        cpu.psr &= ~cast(u32)0x10;
        cpu.psr |= (cpu.reg[15] & 1) << 4;
        cpu.reg[15] &= 0xfffffffe;
        cpu.reg[13] += 4;
    }
}

thumb_push :: inline (ins: u16) {
    if (ins & 0x100) != 0 {
        cpu.remaining_cycles -= 1;
        cpu.reg[13] -= 4;
        write_32(cpu.reg[13], cpu.reg[14]);
    }
    for #v2 < 0..7 {
        if (ins & (1 << it)) != 0 {
            cpu.remaining_cycles -= 1;
            cpu.reg[13] -= 4;
            write_32(cpu.reg[13], cpu.reg[it]);
        }
    }
}

thumb_add_7_sub_4 :: inline (ins: u16) {
    op := (ins & 0x80) != 0;
    if op {
        cpu.reg[13] -= (ins & 0x7f) << 2;
    } else {
        cpu.reg[13] += (ins & 0x7f) << 2;
    }
}

thumb_add_5_add_6 :: inline (ins: u16) {
    rd_idx : u8 = xx (ins >> 8) & 0b111;
    immed := ins & 0xff;
    reg_dst(rd_idx, (ifx (ins & 0x800) != 0 then cpu.reg[13] else (cpu.reg[15] & 0xfffffffc)) + immed * 4);
}

thumb_swi_b_1 :: inline (ins: u16) {
    cond_idx : u8 = xx (ins >> 8) & 0xf;
    if cond_idx == 0xf {
        assert(false);
    } else {
        if cond(cond_idx) {
            immed := (ins & 0xff) << 1;
            cpu.reg[15] += immed & 0xff;
            cpu.reg[15] -= immed & 0x100;
            cpu.reg[15] += 2;
        }
    }
}

thumb_ldmia_stmia :: inline (ins: u16) {
    regs := ins & 0xff;
    rn_idx : u8 = xx (ins >> 8) & 0b111;
    pointer := reg_src(rn_idx);
    if (ins & 0x800) != 0 {
        // ldm
        cpu.remaining_cycles -= 1;
        for 0..7 {
            if regs & (1 << it) != 0 {
                cpu.remaining_cycles -= 1;
                reg_dst(xx it, read_32(pointer));
                pointer += 4;
            }
        }
        reg_dst(rn_idx, pointer);
    } else {
        // stm
        for 0..7 {
            if regs & (1 << it) != 0 {
                cpu.remaining_cycles -= 1;
                write_32(pointer, reg_src(xx it));
                pointer += 4;
            }
        }
        reg_dst(rn_idx, pointer);
    }
}

thumb_b_2 :: inline (ins: u16) {
    offset := ins & 0x7ff;
    offset <<= 1;
    cpu.reg[15] += offset;
    if (offset & 0x800) != 0 {
        cpu.reg[15] -= 0x1000;
    }
    cpu.reg[15] += 2;
}

thumb_bl_blx_1_blx_suffix :: inline (ins: u16) {
    assert(false);
}

thumb_bl_blx_1_prefix :: inline (ins: u16) {
    offset := ins & 0x7ff;
    offset_adj : u32 = xx offset;
    if (offset_adj & 0x400) != 0 {
        cpu.reg[14] = cpu.reg[15] + ((offset_adj << 12) | 0xff800000) + 2;
    } else {
        cpu.reg[14] = cpu.reg[15] + (offset_adj << 12) + 2;
    }
}

thumb_bl_blx_1_bl_suffix :: inline (ins: u16) {
    offset := ins & 0x7ff;
    next := cpu.reg[15];
    cpu.reg[15] = cpu.reg[14] + (offset << 1);
    cpu.reg[14] = next | 1;
}
