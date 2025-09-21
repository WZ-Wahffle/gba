draw_gui :: () {
    context.print_style.default_format_int.base = 16;
    context.print_style.default_format_int.minimum_digits = 8;
    cpu_window();
    disasm_window();
    context.print_style.default_format_int.base = 10;
    context.print_style.default_format_int.minimum_digits = 1;
}
disasm_scroll_state := 0;

#scope_file cpu_window :: () {
    ImGui.Begin("cpu");
    if ImGui.Button("Start") {
        cpu.emu_state = .RUNNING;
    }
    ImGui.SameLine();
    if ImGui.Button("Stop") {
        cpu.emu_state = .STOPPED;
    }
    ImGui.SameLine();
    if ImGui.Button("Step") {
        cpu.emu_state = .STEPPED;
    }
    ImGui.Text("Mode: %, %", cpu.mode, cpu.state);
    ImGui.Text("PC : 0x% ", cpu.pc);
    ImGui.SameLine();
    ImGui.Text("LR : 0x% ", cpu.lr[cpu.mode]);
    ImGui.Text("SP : 0x% ", cpu.sp[cpu.mode]);
    ImGui.SameLine();
    ImGui.Text("R00: 0x% ", cpu.gpr[0]);
    ImGui.Text("R01: 0x% ", cpu.gpr[1]);
    ImGui.SameLine();
    ImGui.Text("R02: 0x% ", cpu.gpr[2]);
    ImGui.Text("R03: 0x% ", cpu.gpr[3]);
    ImGui.SameLine();
    ImGui.Text("R04: 0x% ", cpu.gpr[4]);
    ImGui.Text("R05: 0x% ", cpu.gpr[5]);
    ImGui.SameLine();
    ImGui.Text("R06: 0x% ", cpu.gpr[6]);
    ImGui.Text("R07: 0x% ", cpu.gpr[7]);
    ImGui.SameLine();
    ImGui.Text("R08: 0x% ", ifx cpu.mode == .FIQ then cpu.gpr_hi_fiq[0] else cpu.gpr[8]);
    ImGui.Text("R09: 0x% ", ifx cpu.mode == .FIQ then cpu.gpr_hi_fiq[1] else cpu.gpr[9]);
    ImGui.SameLine();
    ImGui.Text("R10: 0x% ", ifx cpu.mode == .FIQ then cpu.gpr_hi_fiq[2] else cpu.gpr[10]);
    ImGui.Text("R11: 0x% ", ifx cpu.mode == .FIQ then cpu.gpr_hi_fiq[3] else cpu.gpr[11]);
    ImGui.SameLine();
    ImGui.Text("R12: 0x% ", ifx cpu.mode == .FIQ then cpu.gpr_hi_fiq[4] else cpu.gpr[12]);
    ImGui.End();
}

disassemble_immediate :: (val: u32) -> string {
    imm : u32 = val & 0xff;
    rotate : u32 = (val >> 8) * 2;
    #asm {
        rotate === c;
        ror.32 imm, rotate;
    }
    imm2 := imm;
    return tprint("#0x%", formatInt(imm2, 16, 1));
}

disassemble_shifter :: (val: u32) -> string {
    assert(val <= 0xfff);
    if ((val >> 4) & 0b111) == {
        case 0b000;
            if (val >> 7) == 0 then return disassemble_register(val & 0xf);
            return tprint("%, LSL #%", disassemble_register(val & 0xf), formatInt(val >> 7, 10, 1));
        case 0b001;
            return tprint("%, LSL %", disassemble_register(val & 0xf), disassemble_register(val >> 8));
        case 0b010;
            return tprint("%, LSR #%", disassemble_register(val & 0xf), formatInt(val >> 7, 10, 1));
        case 0b011;
            return tprint("%, LSR %", disassemble_register(val & 0xf), disassemble_register(val >> 8));
        case 0b100;
            return tprint("%, ASR #%", disassemble_register(val & 0xf), formatInt(val >> 7, 10, 1));
        case 0b101;
            return tprint("%, ASR %", disassemble_register(val & 0xf), disassemble_register(val >> 8));
        case 0b110;
            return tprint("%, ROR #%", disassemble_register(val & 0xf), formatInt(val >> 7, 10, 1));
        case 0b111;
            return tprint("%, ROR %", disassemble_register(val & 0xf), disassemble_register(val >> 8));
    }
    return "NYI";
}

disassemble_register :: (inst: u32) -> string {
    if inst < 13 {
    return sprint("R%", formatInt(inst, 10, 1));
    } else if inst == 13 {
        return "sp";
    } else if inst == 14 {
        return "lr";
    } else if inst == 15 {
        return "pc";
    } else {
        assert(false);
        return "";
    }
}

cond_lut := string.["EQ", "NE", "CS/HS", "CC/LO", "MI", "PL", "VS", "VC", "HI", "LS", "GE", "LT", "GT", "LE", ""];
disassemble_arm_instruction :: (inst: u32) -> string {
    cond := cond_lut[inst >> 28];
    opcode: string;
    suffix: String_Builder;
    if ((inst >> 26) & 0b11) == {
        case 0b00;
            if (inst & 0xffffff0) == 0x12fff10 {
                // branch & exchange
                opcode = "BX";
                append(*suffix, disassemble_register(inst & 0xf));
            } else if (inst & 0xfc000f0) == 0x0000090 {
                // multiply
                flags := (inst & 0x100000) != 0;
                if (inst & 0x200000) != 0 {
                    opcode = ifx flags then "MULS" else "MUL";
                } else {
                    opcode = ifx flags then "MLAS" else "MLA";
                }
                append(*suffix, disassemble_register((inst >> 16) & 0xf));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(inst & 0xf));
                append(*suffix, ", ");
                append(*suffix, disassemble_register((inst >> 8) & 0xf));
            } else if (inst & 0xf8000f0) == 0x0800090 {
                // multiply long
                flags := (inst & 0x100000) != 0;
                if (inst & 0x400000) != 0 {
                    opcode = ifx flags then "SMULLS" else "SMULL";
                } else {
                    opcode = ifx flags then "UMULLS" else "UMULL";
                }
                append(*suffix, disassemble_register((inst >> 12) & 0xf));
                append(*suffix, ", ");
                append(*suffix, disassemble_register((inst >> 16) & 0xf));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(inst & 0xf));
                append(*suffix, ", ");
                append(*suffix, disassemble_register((inst >> 8) & 0xf));
            } else if (inst & 0xfb00ff0) == 0x1000090 {
                // single data swap
                if (inst & 0x400000) != 0 {
                    opcode = "SWPB";
                } else {
                    opcode = "SWP";
                }
                append(*suffix, disassemble_register((inst >> 12) & 0xf));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(inst & 0xf));
                append(*suffix, ", [");
                append(*suffix, disassemble_register((inst >> 16) & 0xf));
                append(*suffix, "]");
            } else if (inst & 0xe400ff0) == 0x0000090 {
                // halfword data transfer reg
                // assert(false);
            } else if (inst & 0xe4000f0) == 0x0400090 {
                // halfword data transfer imm
                // assert(false);
            } else if (inst & 0xe0000d0) == 0x00000d0 {
                // signed data transfer
                // assert(false);
            } else {
                rn_idx := cast(u8)((inst >> 16) & 0xf);
                rd_idx := cast(u8)((inst >> 12) & 0xf);
                // data processing and fsr
                if (inst & 0xfb00000) == 0x1000000 {
                    // mrs
                    opcode = "MRS";
                    append(*suffix, disassemble_register((inst >> 12) & 0xf));
                    append(*suffix, ", ");
                    append(*suffix, ifx (inst & 0x400000) != 0 then "SPSR" else "CPSR");
                } else if (inst & 0xfb00000) == 0x3200000 {
                    // msr immediate
                    // assert(false);
                } else if (inst & 0xfb000f0) == 0x1200000 {
                    // msr reg
                    opcode = "MSR";
                    c := (inst & 0x10000) != 0;
                    f := (inst & 0x80000) != 0;
                    append(*suffix, ifx (inst & 0x400000) != 0 then "SPSR_" else "CPSR_");
                    if f append(*suffix, #char "f");
                    if c append(*suffix, #char "c");
                    append(*suffix, ", ");
                    append(*suffix, disassemble_register(inst & 0xf));
                } else {
                    flags := (inst & 0x100000) != 0;
                    if ((inst >> 21) & 0xf) == {
                        case 0b0000;
                        // and
                        // assert(false);
                        case 0b0001;
                        // eor
                        // assert(false);
                        case 0b0010;
                            // sub
                            opcode = ifx flags then "SUBS" else "SUB";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b0011;
                        // rsb
                        // assert(false);
                        case 0b0100;
                            // add
                            opcode = ifx flags then "ADDS" else "ADD";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b0101;
                        // adc
                        // assert(false);
                        case 0b0110;
                        // sbc
                        // assert(false);
                        case 0b0111;
                        // rsc
                        // assert(false);
                        case 0b1000;
                        // tst
                        // assert(false);
                        case 0b1001;
                            // teq
                            opcode = "TEQ";
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b1010;
                            // cmp
                            // technically has a flags and a destination field,
                            // but this is never relevant so who cares
                            opcode = "CMP";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                        case 0b1011;
                        // would be msr, but handled outside
                        // assert(false);
                        case 0b1100;
                        // orr
                        // assert(false);
                        case 0b1101;
                            // mov
                            opcode = ifx flags then "MOVS" else "MOV";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                        case 0b1110;
                        // bic
                        // assert(false);
                        case 0b1111;
                        // mvn
                        // assert(false);
                    }
                    if (inst & 0x2000000) {
                        append(*suffix, disassemble_immediate(inst & 0xfff));
                    } else {
                        append(*suffix, disassemble_shifter(inst & 0xfff));
                    }
                }
            }
        case 0b01;
            // LDR / STR / LDRB / STRB
            rd_idx := cast(u8)((inst >> 12) & 0xf);
            rn_idx := cast(u8)((inst >> 16) & 0xf);
            p := (inst & 0x1000000) != 0;
            u := (inst & 0x800000) != 0;
            b := (inst & 0x400000) != 0;
            w := (inst & 0x200000) != 0;
            l := (inst & 0x100000) != 0;
            offset := inst & 0xfff;
            if l {
                // load
                if b {
                    opcode = "LDRB";
                } else {
                    opcode = "LDR";
                }
            } else {
                // store
                if b {
                    opcode = "STRB";
                } else {
                    opcode = "STR";
                }
            }
            append(*suffix, disassemble_register(rd_idx));
            append(*suffix, ", [");
            append(*suffix, disassemble_register(rn_idx));
            if !p {
                // post indexed
                append(*suffix, "], ");
                if u {
                    append(*suffix, tprint("#%", offset));
                } else {
                    append(*suffix, tprint("#-%", offset));
                }
            } else if !w {
                // offset addressing
                append(*suffix, ", ");
                if u {
                    append(*suffix, tprint("#%", offset));
                } else {
                    append(*suffix, tprint("#-%", offset));
                }
                append(*suffix, "]");
            } else {
                // pre indexed
                append(*suffix, ", ");
                if u {
                    append(*suffix, tprint("#%", offset));
                } else {
                    append(*suffix, tprint("#-%", offset));
                }
                append(*suffix, "]!");
            }

        case 0b10;
            if (inst & 0x2000000) == 0 {
                // block data transfer
                // assert(false);
            } else {
                // branch
                if (inst & 0x1000000) == 0 {
                    // B
                    opcode = "B";
                } else {
                    // BL
                    opcode = "BL";
                }
                addr : s32 = (cast(s32)(inst & 0x7fffff) << 2) - (cast(s32)(inst & 0x800000) << 2);
                append(*suffix, tprint("0x%", addr));
            }
        case 0b11;
            if (inst & 0x2000000) == 0 {
                // coprocessor data transfer
                // assert(false);
            } else {
                if (inst & 0x1000000) == 0 {
                    if (inst & 0x10) == 0 {
                        // coprocessor data operation
                        // assert(false);
                    } else {
                        // coprocessor register transfer
                        // assert(false);
                    }
                } else {
                    // software interrupt
                    // assert(false);
                }
            }
    }
    return tprint("%1%2 %", opcode, cond, builder_to_string(*suffix));
}

disassemble_thumb_instruction :: (inst: u16) -> string  {
    return "NYI";
}

disasm_window :: () {
    ImGui.Begin("disasm", null, .NoScrollbar);
    for 0..cast(u32)(ImGui.GetWindowSize().y / FONT_SIZE - 1) {
        addr : u32 = xx (disasm_scroll_state + xx it * ifx cpu.state == .ARM then 4 else 2);
        to_print := ifx cpu.state == .ARM then
            disassemble_arm_instruction(read_32(addr, true))
        else disassemble_thumb_instruction(read_16(addr, true));
        contains := array_find(cpu.breakpoints, addr);

        if addr == cpu.pc {
            ImGui.TextColored(.{255, 255, 0, 255}, "%\t%", addr, to_print);
        } else if contains {
            ImGui.TextColored(.{255, 0, 0, 255}, "%\t%", addr, to_print);
        } else {
            ImGui.Text("%\t%", addr, to_print);
        }
        if ImGui.IsItemHovered() {
            ImGui.SetTooltip("0x%", read_32(addr, true));
        }
        if ImGui.IsItemClicked() {
            if contains {
                array_unordered_remove_by_value(*cpu.breakpoints, addr);
            } else {
                array_add(*cpu.breakpoints, addr);
            }
        }
    }
    ImGui.End();
}
