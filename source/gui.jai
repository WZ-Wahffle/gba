show_iwram := false;
show_ewram := false;
show_vram := false;
show_palette_ram := false;
show_oam := false;
show_disasm := false;
show_cpu := false;
show_ppu := false;

draw_gui :: () {
    context.print_style.default_format_int.base = 16;
    context.print_style.default_format_int.minimum_digits = 8;
    if ImGui.BeginMainMenuBar() {
        if ImGui.BeginMenu("Processors") {
            if ImGui.MenuItem("cpu", "ctrl+c") {
                show_cpu = !show_cpu;
            }
            if ImGui.MenuItem("ppu", "ctrl+g") {
                show_ppu = !show_ppu;
            }
            ImGui.EndMenu();
        }
        if ImGui.BeginMenu("Memory") {
            if ImGui.MenuItem("iwram", "ctrl+i") {
                show_iwram = !show_iwram;
            }
            if ImGui.MenuItem("ewram", "ctrl+e") {
                show_ewram = !show_ewram;
            }
            if ImGui.MenuItem("vram", "ctrl+v") {
                show_vram = !show_vram;
            }
            if ImGui.MenuItem("palette ram", "ctrl+p") {
                show_palette_ram = !show_palette_ram;
            }
            if ImGui.MenuItem("oam", "ctrl+o") {
                show_oam = !show_oam;
            }
            ImGui.EndMenu();
        }
        if ImGui.BeginMenu("Disassembly") {
            if ImGui.MenuItem("show", "ctrl+d") {
                show_disasm = !show_disasm;
            }
            ImGui.EndMenu();
        }
        ImGui.EndMainMenuBar();
    }

    if show_iwram iwram_window();
    if show_ewram ewram_window();
    if show_vram vram_window();
    if show_palette_ram palette_ram_window();
    if show_oam oam_window();
    if show_cpu cpu_window();
    if show_ppu ppu_window();
    if show_disasm disasm_window();
    #if #exists(__Iprof) {
        profiler_window();
    }
    context.print_style.default_format_int.base = 10;
    context.print_style.default_format_int.minimum_digits = 1;
}

#if #exists(__Iprof) {
    report: *__Iprof.Report;
}

cpu_window :: () {
    ImGui.Begin("cpu");
    ImGui.Text("Frame time: %ms", dt * 1000);
    if ImGui.Button("Start") {
        cpu.emu_state = .STARTED;
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
    ImGui.Text("PC : 0x% ", cpu.reg[15]);
    ImGui.SameLine();
    ImGui.Text("LR : 0x% ", cpu.reg[14]);
    ImGui.Text("SP : 0x% ", cpu.reg[13]);
    ImGui.SameLine();
    ImGui.Text("PSR:   %1%2%3%4%5%6%7",
        ifx (cpu.psr & 0x80000000) != 0 then "N" else "-",
        ifx (cpu.psr & 0x40000000) != 0 then "Z" else "-",
        ifx (cpu.psr & 0x20000000) != 0 then "C" else "-",
        ifx (cpu.psr & 0x10000000) != 0 then "V" else "-",
        ifx (cpu.psr & 0x00000080) != 0 then "I" else "-",
        ifx (cpu.psr & 0x00000040) != 0 then "F" else "-",
        ifx cpu.state == .THUMB then "T" else "-",
    );
    ImGui.Text("R00: 0x% ", cpu.reg[0]);
    ImGui.SameLine();
    ImGui.Text("R01: 0x% ", cpu.reg[1]);
    ImGui.Text("R02: 0x% ", cpu.reg[2]);
    ImGui.SameLine();
    ImGui.Text("R03: 0x% ", cpu.reg[3]);
    ImGui.Text("R04: 0x% ", cpu.reg[4]);
    ImGui.SameLine();
    ImGui.Text("R05: 0x% ", cpu.reg[5]);
    ImGui.Text("R06: 0x% ", cpu.reg[6]);
    ImGui.SameLine();
    ImGui.Text("R07: 0x% ", cpu.reg[7]);
    ImGui.Text("R08: 0x% ", cpu.reg[8]);
    ImGui.SameLine();
    ImGui.Text("R09: 0x% ", cpu.reg[9]);
    ImGui.Text("R10: 0x% ", cpu.reg[10]);
    ImGui.SameLine();
    ImGui.Text("R11: 0x% ", cpu.reg[11]);
    ImGui.Text("R12: 0x% ", cpu.reg[12]);
    ImGui.NewLine();
    ImGui.Text("Interrupts %abled", ifx cpu.interrupt_master_enable then "en" else "dis");
    for enum_names(Interrupt_Source) {
        ImGui.Text("%: %abled, %triggered", it, ifx cpu.ie[it_index] != 0 then "en" else "dis", ifx cpu.ifl[it_index] != 0 then "" else "not ");
    }
    ImGui.End();
}

ppu_window :: () {
    ImGui.Begin("ppu");
    ImGui.Text("X: %", formatInt(ppu.draw_x, 10, 1));
    ImGui.Text("Y: %", formatInt(ppu.draw_y, 10, 1));
    ImGui.Text("BG Mode: %", formatInt(ppu.bg_mode, 10, 1));
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
    return tprint("R%", formatInt(inst, 10, 1));
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

cond_lut := string.["EQ", "NE", "CS/HS", "CC/LO", "MI", "PL", "VS", "VC", "HI", "LS", "GE", "LT", "GT", "LE", "", ""];
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
            } else if (inst & 0xff000f0) == 0x1200070 {
                // breakpoint
                idx := (inst & 0xf) | ((inst >> 4) & 0xfff0);
                return disassemble_arm_instruction(cpu.breakpoints_arm[idx]);
            } else if (inst & 0xfc000f0) == 0x0000090 {
                // multiply
                flags := (inst & 0x100000) != 0;
                if (inst & 0x200000) != 0 {
                    opcode = ifx flags then "MLAS" else "MLA";
                } else {
                    opcode = ifx flags then "MULS" else "MUL";
                }
                append(*suffix, disassemble_register((inst >> 16) & 0xf));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(inst & 0xf));
                append(*suffix, ", ");
                append(*suffix, disassemble_register((inst >> 8) & 0xf));
                if (inst & 0x200000) != 0 {
                    append(*suffix, ", ");
                    append(*suffix, disassemble_register((inst >> 12) & 0xf));
                }
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
            } else if (inst & 0xe0000f0) == 0x00000b0 {
                // ldrh / strh
                rd_idx : u8 = xx (inst >> 12) & 0xf;
                rn_idx : u8 = xx (inst >> 16) & 0xf;
                p := (inst & 0x1000000) != 0;
                u := (inst & 0x800000) != 0;
                i := (inst & 0x400000) != 0;
                w := (inst & 0x200000) != 0;
                l := (inst & 0x100000) != 0;

                if l {
                    // load
                    opcode = "LDRH";
                } else {
                    // store
                    opcode = "STRH";
                }
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", [");
                append(*suffix, disassemble_register(rn_idx));
                offset := tprint("#%", formatInt((inst & 0x0f) | ((inst >> 4) & 0xf0), 10, 1));
                offset_reg := disassemble_register(xx inst & 0xf);
                if !p {
                    // post indexed
                    append(*suffix, "], ");
                    if u {
                        append(*suffix, tprint("%", ifx i then offset else offset_reg));
                    } else {
                        append(*suffix, tprint("-%", ifx i then offset else offset_reg));
                    }
                } else if !w {
                    // offset addressing
                    append(*suffix, ", ");
                    if u {
                        append(*suffix, tprint("%", ifx i then offset else offset_reg));
                    } else {
                        append(*suffix, tprint("-%", ifx i then offset else offset_reg));
                    }
                    append(*suffix, "]");
                } else {
                    // pre indexed
                    append(*suffix, ", ");
                    if u {
                        append(*suffix, tprint("%", ifx i then offset else offset_reg));
                    } else {
                        append(*suffix, tprint("-%", ifx i then offset else offset_reg));
                    }
                    append(*suffix, "]!");
                }
            } else if (inst & 0xe0000d0) == 0x00000d0 {
                // ldrsb / ldrsh
                rd_idx : u8 = xx (inst >> 12) & 0xf;
                rn_idx : u8 = xx (inst >> 16) & 0xf;
                p := (inst & 0x1000000) != 0;
                u := (inst & 0x800000) != 0;
                i := (inst & 0x400000) != 0;
                w := (inst & 0x200000) != 0;

                if (inst & 0x20) != 0 {
                    // load
                    opcode = "LDRSH";
                } else {
                    // store
                    opcode = "LDRSB";
                }
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", [");
                append(*suffix, disassemble_register(rn_idx));
                offset := tprint("#%", formatInt((inst & 0x0f) | ((inst >> 4) & 0xf0), 10, 1));
                offset_reg := disassemble_register(xx inst & 0xf);
                if !p {
                    // post indexed
                    append(*suffix, "], ");
                    if u {
                        append(*suffix, tprint("%", ifx i then offset else offset_reg));
                    } else {
                        append(*suffix, tprint("-%", ifx i then offset else offset_reg));
                    }
                } else if !w {
                    // offset addressing
                    append(*suffix, ", ");
                    if u {
                        append(*suffix, tprint("%", ifx i then offset else offset_reg));
                    } else {
                        append(*suffix, tprint("-%", ifx i then offset else offset_reg));
                    }
                    append(*suffix, "]");
                } else {
                    // pre indexed
                    append(*suffix, ", ");
                    if u {
                        append(*suffix, tprint("%", ifx i then offset else offset_reg));
                    } else {
                        append(*suffix, tprint("-%", ifx i then offset else offset_reg));
                    }
                    append(*suffix, "]!");
                }
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
                            opcode = ifx flags then "ANDS" else "AND";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b0001;
                            // eor
                            opcode = ifx flags then "EORS" else "EOR";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b0010;
                            // sub
                            opcode = ifx flags then "SUBS" else "SUB";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b0011;
                            // rsb
                            opcode = ifx flags then "RSBS" else "RSB";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b0100;
                            // add
                            opcode = ifx flags then "ADDS" else "ADD";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b0101;
                            // adc
                            opcode = ifx flags then "ADCS" else "ADC";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b0110;
                        // sbc
                        // assert(false);
                        case 0b0111;
                        // rsc
                        // assert(false);
                        case 0b1000;
                            // tst
                            opcode = "TST";
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
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
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b1011;
                        // would be msr, but handled outside
                        // assert(false);
                        case 0b1100;
                        // orr
                            opcode = ifx flags then "ORRS" else "ORR";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b1101;
                            // mov
                            opcode = ifx flags then "MOVS" else "MOV";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
                        case 0b1110;
                            // bic
                            opcode = ifx flags then "BICS" else "BIC";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
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
            rd_idx : u8 = xx (inst >> 12) & 0xf;
            rn_idx : u8 = xx (inst >> 16) & 0xf;
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
                    append(*suffix, tprint("#%", formatInt(offset, 10, 1)));
                } else {
                    append(*suffix, tprint("#-%", formatInt(offset, 10, 1)));
                }
            } else if !w {
                // offset addressing
                append(*suffix, ", ");
                if u {
                    append(*suffix, tprint("#%", formatInt(offset, 10, 1)));
                } else {
                    append(*suffix, tprint("#-%", formatInt(offset, 10, 1)));
                }
                append(*suffix, "]");
            } else {
                // pre indexed
                append(*suffix, ", ");
                if u {
                    append(*suffix, tprint("#%", formatInt(offset, 10, 1)));
                } else {
                    append(*suffix, tprint("#-%", formatInt(offset, 10, 1)));
                }
                append(*suffix, "]!");
            }

        case 0b10;
            if (inst & 0x2000000) == 0 {
                // block data transfer
                p := (inst & 0x1000000) != 0; // full stack? (empty stack)
                u := (inst & 0x800000) != 0; // increment pointer? (decrement)
                s := (inst & 0x400000) != 0; // user mode registers? (current)
                w := (inst & 0x200000) != 0; // write back pointer?
                l := (inst & 0x100000) != 0; // load? (store)
                rn_idx : u8 = xx (inst >> 16) & 0xf;
                regs := inst & 0xffff;
                if l && p && !u opcode = "LDMDB";
                if l && !p && !u opcode = "LDMDA";
                if l && p && u opcode = "LDMIB";
                if l && !p && u opcode = "LDMIA";
                if !l && p && !u opcode = "STMDB";
                if !l && !p && !u opcode = "STMDA";
                if !l && p && u opcode = "STMIB";
                if !l && !p && u opcode = "STMIA";
                append(*suffix, disassemble_register(rn_idx));
                if w append(*suffix, "!");
                append(*suffix, ", {");
                any := false;
                for 0..12 {
                    if (inst & (1 << it)) != 0 {
                        append(*suffix, ifx any then tprint(",R%", formatInt(it, 10, 1)) else tprint("R%", formatInt(it, 10, 1)));
                        any = true;
                    }
                }
                if (inst & 0x2000) != 0 {
                    append(*suffix, ifx any then ",sp" else "sp");
                }
                if (inst & 0x4000) != 0 {
                    append(*suffix, ifx any then ",lr" else "lr");
                }
                if (inst & 0x8000) != 0 {
                    append(*suffix, ifx any then ",pc" else "pc");
                }
                append(*suffix, "}");
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
    out := builder_to_string(*suffix);
    ret := tprint("%1%2 %", opcode, cond, out);
    free(out);
    return ret;
}

cond_lut_lower := string.["eq", "ne", "cs/hs", "cc/lo", "mi", "pl", "vs", "vc", "hi", "ls", "ge", "lt", "gt", "le", "", ""];
disassemble_thumb_instruction :: (ins: u16) -> string  {
    opcode: string;
    suffix: String_Builder;
    if (ins >> 13) == {
        case 0b000;
        rn_idx : u8 = xx (ins >> 3) & 0b111;
        rd_idx : u8 = xx ins & 0b111;
        if (ins >> 9) == {
            case 0b1100;
            // add (3)
            rm_idx : u8 = xx (ins >> 6) & 0b111;
            opcode = "add";
            append(*suffix, disassemble_register(rd_idx));
            append(*suffix, ", ");
            append(*suffix, disassemble_register(rn_idx));
            append(*suffix, ", ");
            append(*suffix, disassemble_register(rm_idx));
            case 0b1101;
            // sub (3)
            rm_idx : u8 = xx (ins >> 6) & 0b111;
            opcode = "sub";
            append(*suffix, disassemble_register(rd_idx));
            append(*suffix, ", ");
            append(*suffix, disassemble_register(rn_idx));
            append(*suffix, ", ");
            append(*suffix, disassemble_register(rm_idx));
            case 0b1110;
            // add (1)
            // mov (2) if immediate is 0
            operand := ((ins >> 6) & 0b111);
            opcode = ifx operand == 0 then "mov" else "add";
            append(*suffix, disassemble_register(rd_idx));
            append(*suffix, ", ");
            append(*suffix, disassemble_register(rn_idx));
            if operand != 0 {
                append(*suffix, ", #");
                append(*suffix, tprint("%", formatInt(operand, 10, 1)));
            }
            case 0b1111;
            // sub (1)
            operand := ((ins >> 6) & 0b111);
            opcode = "sub";
            append(*suffix, disassemble_register(rd_idx));
            append(*suffix, ", ");
            append(*suffix, disassemble_register(rn_idx));
            if operand != 0 {
                append(*suffix, ", #");
                append(*suffix, tprint("%", formatInt(operand, 10, 1)));
            }
            case;
            // shift by immediate
            immed := (ins >> 6) & 0x1f;
            if ((ins >> 11) & 0b11) == {
                case 0b00;
                // lsl (1)
                opcode = "lsl";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", #");
                append(*suffix, tprint("%", formatInt(immed, 10, 1)));
                case 0b01;
                // lsr (1)
                opcode = "lsr";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", #");
                append(*suffix, tprint("%", formatInt(immed, 10, 1)));
                case 0b10;
                // asr (1)
                opcode = "asr";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", #");
                append(*suffix, tprint("%", formatInt(immed, 10, 1)));
                case 0b11;
                // handled elsewhere
            }
        }
        case 0b001;
        // Add/subtract/compare/move immediate
        immed := ins & 0xff;
        reg_idx : u8 = xx (ins >> 8) & 0b111;
        if ((ins >> 11) & 0b11) == {
            case 0b00;
            // mov (1)
            opcode = "mov";
            append(*suffix, disassemble_register(reg_idx));
            append(*suffix, ", #0x");
            append(*suffix, tprint("%", formatInt(immed, 16, 2)));
            case 0b01;
            opcode = "cmp";
            append(*suffix, disassemble_register(reg_idx));
            append(*suffix, ", #0x");
            append(*suffix, tprint("%", formatInt(immed, 16, 2)));
            case 0b10;
            // add (2)
            opcode = "add";
            append(*suffix, disassemble_register(reg_idx));
            append(*suffix, ", #0x");
            append(*suffix, tprint("%", formatInt(immed, 16, 2)));
            case 0b11;
            // sub (2)
            opcode = "sub";
            append(*suffix, disassemble_register(reg_idx));
            append(*suffix, ", #0x");
            append(*suffix, tprint("%", formatInt(immed, 16, 2)));
        }
        case 0b010;
        if (ins & 0x1000) != 0 {
            // Load/store register offset
            rm_idx : u8 = xx (ins >> 6) & 0b111;
            rn_idx : u8 = xx (ins >> 3) & 0b111;
            rd_idx : u8 = xx ins & 0b111;
            if ((ins >> 9) & 0b111) == {
                case 0b000;
                // str (2)
                opcode = "str";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", [");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                append(*suffix, "]");
                case 0b001;
                // strh (2)
                rd_idx : u8 = xx ins & 0b111;
                rn_idx : u8 = xx (ins >> 3) & 0b111;
                rm_idx : u8 = xx (ins >> 6) & 0b111;
                opcode = "strh";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", [");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                append(*suffix, "]");
                case 0b010;
                // strb (2)
                case 0b011;
                // ldrsb
                opcode = "ldrsb";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", [");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                append(*suffix, "]");
                case 0b100;
                // ldr (2)
                opcode = "ldr";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", [");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                append(*suffix, "]");
                case 0b101;
                // ldrh (2)
                rd_idx : u8 = xx ins & 0b111;
                rn_idx : u8 = xx (ins >> 3) & 0b111;
                rm_idx : u8 = xx (ins >> 6) & 0b111;
                opcode = "ldrh";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", [");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                append(*suffix, "]");
                case 0b110;
                // ldrb (2)
                rd_idx : u8 = xx ins & 0b111;
                rn_idx : u8 = xx (ins >> 3) & 0b111;
                rm_idx : u8 = xx (ins >> 6) & 0b111;
                opcode = "ldrb";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", [");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                append(*suffix, "]");
                case 0b111;
                // ldrsh
            }
        } else if (ins & 0x800) != 0 {
            // ldr (3)
            immed := ins & 0xff;
            reg_idx : u8 = xx (ins >> 8) & 0b111;
            opcode = "ldr";
            append(*suffix, disassemble_register(reg_idx));
            append(*suffix, ", [pc, #0x");
            append(*suffix, tprint("%", formatInt(immed * 4, 16, 1)));
            append(*suffix, "]");
        } else if (ins & 0x400) != 0 {
            // special data processing + bx
            if ((ins >> 8) & 0b11) == {
                case 0b00;
                // add (4)
                case 0b01;
                // cmp (3)
                rd_idx : u8 = xx ((ins & 0b111) | ((ins >> 4) & 0b1000));
                rm_idx : u8 = xx ((ins >> 3) & 0xf);
                opcode = "cmp";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b10;
                // mov (3)
                rd_idx : u8 = xx ((ins & 0b111) | ((ins >> 4) & 0b1000));
                rm_idx : u8 = xx ((ins >> 3) & 0xf);
                opcode = "mov";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b11;
                // bx / blx (2)
                reg_idx : u8 = xx (ins >> 3) & 0xf;
                opcode = ifx (ins & 0x80) != 0 then "blx" else "bx";
                append(*suffix, disassemble_register(reg_idx));
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
                opcode = "and";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b0001;
                // eor
                opcode = "eor";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b0010;
                // lsl (2)
                case 0b0011;
                // lsr (2)
                opcode = "lsr";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rs_idx));
                case 0b0100;
                // asr (2)
                case 0b0101;
                // adc
                case 0b0110;
                // sbc
                case 0b0111;
                // ror
                opcode = "ror";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rs_idx));
                case 0b1000;
                // tst
                opcode = "tst";
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b1001;
                // neg
                opcode = "neg";
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b1010;
                // cmp (2)
                opcode = "cmp";
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b1011;
                // cmn
                opcode = "cmn";
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b1100;
                // orr
                opcode = "orr";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b1101;
                // mul
                opcode = "mul";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b1110;
                // bic
                opcode = "bic";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                case 0b1111;
                // mvn
                opcode = "mvn";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
            }
        }
        case 0b011;
        // Load/store word/byte immediate offset
        l := (ins & 0x800) != 0; // load? (store)
        s := (ins & 0x1000) != 0; // byte? (word)
        imm := (ins >> 6) & 0x1f;
        rn_idx : u8 = xx (ins >> 3) & 0b111;
        rd_idx : u8 = xx (ins & 0b111);
        if l {
            opcode = ifx s then "ldrb" else "ldr";
        } else {
            opcode = ifx s then "strb" else "str";
        }
        append(*suffix, disassemble_register(rd_idx));
        append(*suffix, ", [");
        append(*suffix, disassemble_register(rn_idx));
        append(*suffix, ", #0x");
        append(*suffix, tprint("%", formatInt(imm, 16, 1)));
        append(*suffix, "]");
        case 0b100;
        if (ins & 0x1000) != 0 {
            // Load/store to/from stack
            imm := ins & 0xff;
            reg_idx := (ins >> 8) & 0b111;
            addr := cpu.reg[14] + 4 * imm;
            if (ins & 0x800) != 0 {
                // ldr (4)
                opcode = "ldr";
            } else {
                // str (3)
                opcode = "str";
            }
            append(*suffix, disassemble_register(reg_idx));
            append(*suffix, ", [SP, #");
            append(*suffix, tprint("%", formatInt(imm * 4, 10, 1)));
            append(*suffix, "]");
        } else {
            // Load/store halfword immediate offset
            rd_idx : u8 = xx ins & 0b111;
            rn_idx : u8 = xx (ins >> 3) & 0b111;
            immed := (ins >> 6) & 0x1f;
            if (ins & 0x800) != 0 {
                // ldrh (1)
                opcode = "ldrh";
            } else {
                // strh (1)
                opcode = "strh";
            }
            append(*suffix, disassemble_register(rd_idx));
            append(*suffix, ", [");
            append(*suffix, disassemble_register(rn_idx));
            append(*suffix, ", #");
            append(*suffix, tprint("%", formatInt(immed * 2, 10, 1)));
            append(*suffix, "]");
        }
        case 0b101;
        if (ins & 0x1000) != 0 {
            // Miscellaneous
            if (ins & 0x200) != 0 {
                // bkpt
                return disassemble_thumb_instruction(cpu.breakpoints_thumb[ins & 0xff]);
            } else if (ins & 0x400) != 0 {
                // push/pop register list
                opcode = ifx (ins & 0x800) != 0 then "pop" else "push";
                append(*suffix, "{");
                any := false;
                for 0..7 {
                    if (ins & (1 << it)) != 0 {
                        append(*suffix, ifx any then tprint(",R%", formatInt(it, 10, 1)) else tprint("R%", formatInt(it, 10, 1)));
                        any = true;
                    }
                }
                if (ins & 0x100) != 0 {
                    if (ins & 0x800) != 0 {
                        append(*suffix, ifx any then ",PC" else "PC");
                    } else {
                        append(*suffix, ifx any then ",LR" else "LR");
                    }
                }
                append(*suffix, "}");
            } else {
                // adjust stack pointer
                opcode = ifx (ins & 0x80) != 0 then "sub" else "add";
                append(*suffix, "SP, #0x");
                append(*suffix, tprint("%", formatInt((ins & 0x7f) << 2, 16, 1)));
            }
        } else {
            rd_idx : u8 = xx (ins >> 8) & 0b111;
            immed := ins & 0xff;
            opcode = "add";
            append(*suffix, disassemble_register(rd_idx));
            append(*suffix, ", ");
            append(*suffix, ifx (ins & 0x800) != 0 then "SP, #0x" else "PC, #0x");
            append(*suffix, tprint("%", formatInt(immed * 4, 16, 1)));
        }
        case 0b110;
        if (ins & 0x1000) != 0 {
            // B (1)
            opcode = tprint("b%", cond_lut_lower[xx (ins >> 8) & 0xf]);
            immed : s32 = xx (ins & 0xff) << 1;
            if immed > 255 then immed -= 512;
            append(*suffix, "0x");
            append(*suffix, tprint("%", formatInt(immed, 16, 1)));
        } else {
            // Load/store multiple
            regs := ins & 0xff;
            rn_idx : u8 = xx (ins >> 8) & 0b111;
            opcode = ifx (ins & 0x800) != 0 then "ldmia" else "stmia";
            append(*suffix, disassemble_register(rn_idx));
            append(*suffix, "!, {");
            any := false;
            for 0..7 {
                if (ins & (1 << it)) != 0 {
                    append(*suffix, ifx any then tprint(",R%", formatInt(it, 10, 1)) else tprint("R%", formatInt(it, 10, 1)));
                    any = true;
                }
            }
            append(*suffix, "}");
        }
        case 0b111;
        offset := ins & 0x7ff;
        if ((ins >> 11) & 0b11) == {
            case 0b00;
            // B (2)
            opcode = "b";
            append(*suffix, "#0x");
            append(*suffix, tprint("%", formatInt(offset, 16, 1)));
            case 0b01;
            // BL, BLX(1) blx suffix
            opcode = "blx_suf";
            append(*suffix, "#0x");
            append(*suffix, tprint("%", formatInt(offset, 16, 1)));
            case 0b10;
            // BL, BLX(1) prefix
            opcode = "bl_pre";
            append(*suffix, "#0x");
            append(*suffix, tprint("%", formatInt(offset, 16, 1)));
            case 0b11;
            // BL, BLX(1) bl suffix
            opcode = "bl_suf";
            append(*suffix, "#0x");
            append(*suffix, tprint("%", formatInt(offset, 16, 1)));
        }
    }
    out := builder_to_string(*suffix);
    ret := tprint("% %", opcode, out);
    free(out);
    return ret;
}

disasm_scroll_state := 0;
disasm_mode := Cpu_State.ARM;
disasm_jump_buffer: [5]u8;
disasm_window :: () {
    ImGui.Begin("disasm", null, .NoScrollbar | .NoScrollWithMouse);
    if ImGui.IsWindowHovered() {
        if ImGui.GetIO().MouseWheel < 0 {
            disasm_scroll_state += 1;
        } else if ImGui.GetIO().MouseWheel > 0 {
            disasm_scroll_state -= 1;
            disasm_scroll_state = max(disasm_scroll_state, 0);
        }
    }
    if ImGui.Button("Jump to PC") {
        disasm_scroll_state = cpu.reg[15] / ifx cpu.state == .ARM then 4 else 2;
    }
    ImGui.SameLine();
    if ImGui.Button(tprint("%\0", ifx disasm_mode == .THUMB then "T" else "A").data) {
        if disasm_mode == .THUMB {
            disasm_scroll_state /= 2;
            disasm_mode = .ARM;
        } else {
            disasm_scroll_state *= 2;
            disasm_mode = .THUMB;
        }
    }
    ImGui.SameLine();
    ImGui.Text("0x");
    ImGui.SameLine();
    if ImGui.InputText("Jump to...", disasm_jump_buffer.data, 5) {
        str := string.{4, disasm_jump_buffer.data};
        parsed := string_to_int(str, 16);
        disasm_scroll_state = parsed / ifx disasm_mode == .ARM then 4 else 2;
    }
    for 0..cast(int)ImGui.GetWindowSize().y {
        addr : u32 = xx ((disasm_scroll_state + xx it) * ifx disasm_mode == .ARM then 4 else 2);
        to_print := ifx disasm_mode == .ARM then
            disassemble_arm_instruction(read_32(addr))
        else disassemble_thumb_instruction(read_16(addr));
        has_breakpoint := ifx disasm_mode == .ARM then ((read_32(addr) & 0xfff000f0) == 0xe1200070) else ((read_16(addr) & 0xff00) == 0xbe00);
        if addr == cpu.reg[15] {
            ImGui.TextColored(.{0, 255, 0, 255}, "%\t%", addr, to_print);
        } else if has_breakpoint {
            ImGui.TextColored(.{255, 0, 0, 255}, "%\t%", addr, to_print);
        } else {
            ImGui.Text("%\t%", addr, to_print);
        }
        if ImGui.IsItemHovered() {
            ImGui.SetTooltip("0x%", ifx disasm_mode == .ARM then read_32(addr) else read_16(addr));
        }
        if ImGui.IsItemClicked() {
            if disasm_mode == .ARM {
                ins := read_32(addr);
                if has_breakpoint {
                    idx := (ins & 0xf) | ((ins >> 8) & 0xfff);
                    write_32(addr, cpu.breakpoints_arm[idx], true);
                    cpu.breakpoints_arm[idx] = 0xffffffff;
                } else {
                    idx : u32 = 0;
                    for cpu.breakpoints_arm if it == 0xffffffff {
                        idx = xx it_index;
                        break;
                    }
                    cpu.breakpoints_arm[idx] = ins;
                    write_32(addr, 0xe1200070 | (idx & 0xf) | ((idx & 0xfff0) << 4), true);
                }
            } else {
                ins := read_16(addr);
                if has_breakpoint {
                    idx := ins & 0xff;
                    write_16(addr, cpu.breakpoints_thumb[idx], true);
                    cpu.breakpoints_thumb[idx] = 0xffff;
                } else {
                    idx : u16 = 0;
                    for cpu.breakpoints_thumb if it == 0xffff {
                        idx = xx it_index;
                        break;
                    }
                    cpu.breakpoints_thumb[idx] = ins;
                    write_16(addr, 0xbe00 | idx, true);
                }
            }
        }
    }
    ImGui.End();
}

iwram_scroll_state := 0;
iwram_jump_buffer: [5]u8;
iwram_window :: () {
    ImGui.Begin("iwram", null, .NoScrollbar | .NoScrollWithMouse);
    ImGui.Text("0x");
    ImGui.SameLine();
    if ImGui.IsWindowHovered() {
        if ImGui.GetIO().MouseWheel < 0 {
            iwram_scroll_state += 1;
        } else if ImGui.GetIO().MouseWheel > 0 {
            iwram_scroll_state -= 1;
            iwram_scroll_state = max(iwram_scroll_state, 0);
        }
    }
    if ImGui.InputText("Jump to...", iwram_jump_buffer.data, 5) {
        str := string.{4, iwram_jump_buffer.data};
        parsed := string_to_int(str, 16);
        iwram_scroll_state = parsed / 16;
    }
    ImGui.BeginTable("##iwram", 17, .Borders | .RowBg | .SizingFixedFit);
    ImGui.TableNextRow();
    for 0..cast(int)ImGui.GetWindowSize().y {
        if (it + iwram_scroll_state + 1) * 16 > 0x8000 {
            iwram_scroll_state = (0x8000 - 16 * it) / 16;
            break;
        }
        ImGui.TableNextColumn();
        ImGui.Text_CFormat("0x%04x", (it + iwram_scroll_state) * 16);
        for it2 : 0..15 {
            ImGui.TableNextColumn();
            ImGui.Text_CFormat("%02x", cpu.memory.iwram._8[(it + iwram_scroll_state) * 16 + it2]);
            if ImGui.IsItemHovered() {
                ImGui.SetTooltip("0x%", 0x03000000 + (it + iwram_scroll_state) * 16 + it2);
            }
        }
    }
    ImGui.EndTable();
    ImGui.End();
}

ewram_scroll_state := 0;
ewram_jump_buffer: [6]u8;
ewram_window :: () {
    ImGui.Begin("ewram", null, .NoScrollbar | .NoScrollWithMouse);
    ImGui.Text("0x");
    ImGui.SameLine();
    if ImGui.IsWindowHovered() {
        if ImGui.GetIO().MouseWheel < 0 {
            ewram_scroll_state += 1;
        } else if ImGui.GetIO().MouseWheel > 0 {
            ewram_scroll_state -= 1;
            ewram_scroll_state = max(ewram_scroll_state, 0);
        }
    }
    if ImGui.InputText("Jump to...", ewram_jump_buffer.data, 6) {
        str := string.{5, ewram_jump_buffer.data};
        parsed := string_to_int(str, 16);
        ewram_scroll_state = parsed / 16;
    }
    ImGui.BeginTable("##ewram", 17, .Borders | .RowBg | .SizingFixedFit);
    ImGui.TableNextRow();
    for 0..cast(int)ImGui.GetWindowSize().y {
        if (it + ewram_scroll_state + 1) * 16 > 0x40000 {
            ewram_scroll_state = (0x40000 - 16 * it) / 16;
            break;
        }
        ImGui.TableNextColumn();
        ImGui.Text_CFormat("0x%05x", (it + ewram_scroll_state) * 16);
        for it2 : 0..15 {
            ImGui.TableNextColumn();
            ImGui.Text_CFormat("%02x", cpu.memory.ewram._8[(it + ewram_scroll_state) * 16 + it2]);
            if ImGui.IsItemHovered() {
                ImGui.SetTooltip("0x%", 0x02000000 + (it + ewram_scroll_state) * 16 + it2);
            }
        }
    }
    ImGui.EndTable();
    ImGui.End();
}

vram_scroll_state := 0;
vram_jump_buffer: [6]u8;
vram_window :: () {
    ImGui.Begin("vram", null, .NoScrollbar | .NoScrollWithMouse);
    ImGui.Text("0x");
    ImGui.SameLine();
    if ImGui.IsWindowHovered() {
        if ImGui.GetIO().MouseWheel < 0 {
            vram_scroll_state += 1;
        } else if ImGui.GetIO().MouseWheel > 0 {
            vram_scroll_state -= 1;
            vram_scroll_state = max(vram_scroll_state, 0);
        }
    }
    if ImGui.InputText("Jump to...", vram_jump_buffer.data, 6) {
        str := string.{5, vram_jump_buffer.data};
        parsed := string_to_int(str, 16);
        vram_scroll_state = parsed / 16;
    }
    ImGui.BeginTable("##vram", 17, .Borders | .RowBg | .SizingFixedFit);
    ImGui.TableNextRow();
    for 0..cast(int)ImGui.GetWindowSize().y {
        if (it + vram_scroll_state + 1) * 16 > 0x18000 {
        vram_scroll_state = (0x18000 - 16 * it) / 16;
            break;
        }
        ImGui.TableNextColumn();
        ImGui.Text_CFormat("0x%05x", (it + vram_scroll_state) * 16);
        for it2 : 0..15 {
            ImGui.TableNextColumn();
            ImGui.Text_CFormat("%02x", ppu.memory.vram._8[(it + vram_scroll_state) * 16 + it2]);
            if ImGui.IsItemHovered() {
                ImGui.SetTooltip("0x%", 0x06000000 + (it + vram_scroll_state) * 16 + it2);
            }
        }
    }
    ImGui.EndTable();
    ImGui.End();
}

palette_ram_scroll_state := 0;
palette_ram_jump_buffer: [4]u8;
palette_ram_window :: () {
    ImGui.Begin("palette_ram", null, .NoScrollbar | .NoScrollWithMouse);
    ImGui.Text("0x");
    ImGui.SameLine();
    if ImGui.IsWindowHovered() {
        if ImGui.GetIO().MouseWheel < 0 {
            palette_ram_scroll_state += 1;
        } else if ImGui.GetIO().MouseWheel > 0 {
            palette_ram_scroll_state -= 1;
            palette_ram_scroll_state = max(palette_ram_scroll_state, 0);
        }
    }
    if ImGui.InputText("Jump to...", palette_ram_jump_buffer.data, 4) {
        str := string.{3, palette_ram_jump_buffer.data};
        parsed := string_to_int(str, 16);
        palette_ram_scroll_state = parsed / 16;
    }
    ImGui.BeginTable("##ewram", 17, .Borders | .RowBg | .SizingFixedFit);
    ImGui.TableNextRow();
    for 0..cast(int)ImGui.GetWindowSize().y {
        if (it + palette_ram_scroll_state + 1) * 16 > 0x400 {
        palette_ram_scroll_state = (0x400 - 16 * it) / 16;
            break;
        }
        ImGui.TableNextColumn();
        ImGui.Text_CFormat("0x%03x", (it + palette_ram_scroll_state) * 16);
        for it2 : 0..15 {
            ImGui.TableNextColumn();
            ImGui.Text_CFormat("%02x", ppu.memory.palette_ram._8[(it + palette_ram_scroll_state) * 16 + it2]);
            if ImGui.IsItemHovered() {
                ImGui.SetTooltip("0x%", 0x05000000 + (it + palette_ram_scroll_state) * 16 + it2);
            }
        }
    }
    ImGui.EndTable();
    ImGui.End();
}

oam_scroll_state := 0;
oam_jump_buffer: [4]u8;
oam_window :: () {
    ImGui.Begin("oam", null, .NoScrollbar | .NoScrollWithMouse);
    ImGui.Text("0x");
    ImGui.SameLine();
    if ImGui.IsWindowHovered() {
        if ImGui.GetIO().MouseWheel < 0 {
            oam_scroll_state += 1;
        } else if ImGui.GetIO().MouseWheel > 0 {
            oam_scroll_state -= 1;
            oam_scroll_state = max(oam_scroll_state, 0);
        }
    }
    if ImGui.InputText("Jump to...", oam_jump_buffer.data, 4) {
        str := string.{3, oam_jump_buffer.data};
        parsed := string_to_int(str, 16);
        oam_scroll_state = parsed / 16;
    }
    ImGui.BeginTable("##ewram", 17, .Borders | .RowBg | .SizingFixedFit);
    ImGui.TableNextRow();
    for 0..cast(int)ImGui.GetWindowSize().y {
        if (it + oam_scroll_state + 1) * 16 > 0x400 {
        oam_scroll_state = (0x400 - 16 * it) / 16;
            break;
        }
        ImGui.TableNextColumn();
        ImGui.Text_CFormat("0x%03x", (it + oam_scroll_state) * 16);
        for it2 : 0..15 {
            ImGui.TableNextColumn();
            ImGui.Text_CFormat("%02x", ppu.memory.oam._8[(it + oam_scroll_state) * 16 + it2]);
            if ImGui.IsItemHovered() {
                ImGui.SetTooltip("0x%", 0x07000000 + (it + oam_scroll_state) * 16 + it2);
            }
        }
    }
    ImGui.EndTable();
    ImGui.End();
}

#if #exists(__Iprof) {
    profiler_filter_selected : s32 = 0;
    profiler_window :: () {
        ImGui.Begin("profiler");
        ImGui.RadioButton("Filter None".data, *profiler_filter_selected, 0);
        ImGui.RadioButton("Filter ARM Instructions".data, *profiler_filter_selected, 1);
        ImGui.RadioButton("Filter THUMB Instructions".data, *profiler_filter_selected, 2);
        if report {
            if ImGui.BeginTable("##reports", 5, .Borders | .RowBg | .SizingFixedFit) {
                ImGui.TableSetupColumn(report.header[0].data);
                ImGui.TableSetupColumn(report.header[1].data);
                ImGui.TableSetupColumn(report.header[2].data);
                ImGui.TableSetupColumn(report.header[3].data);
                ImGui.TableSetupColumn("per iteration");
                ImGui.TableHeadersRow();
                for report.*.records {
                    if profiler_filter_selected == 1 {
                        if !starts_with(it.name, "arm_") continue;
                    }
                    if profiler_filter_selected == 2 {
                        if !starts_with(it.name, "thumb_") continue;
                    }
                    if it.self_time < 0.00001 continue;
                    ImGui.TableNextColumn();
                    ImGui.Text("%", it.name);
                    ImGui.TableNextColumn();
                    ImGui.Text("%", it.self_time);
                    ImGui.TableNextColumn();
                    ImGui.Text("%", it.hier_time);
                    ImGui.TableNextColumn();
                    ImGui.Text("%", it.calls);
                    ImGui.TableNextColumn();
                    ImGui.Text("%", it.self_time / it.calls);
                    ImGui.TableNextRow();
                }
                ImGui.EndTable();
            }
        }
        ImGui.End();
    }
}
