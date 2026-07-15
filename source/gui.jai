show_header := false;
show_iwram := false;
show_ewram := false;
show_vram := false;
show_palette_ram := false;
show_oam := false;
show_dma := false;
show_window := false;
show_blend := false;
show_timer := false;
show_rom := false;
show_disasm := false;
show_keypad := false;
show_save := false;
show_cpu := false;
show_ppu := false;
show_apu := false;

draw_gui :: () {
    context.print_style.default_format_int.base = 16;
    context.print_style.default_format_int.minimum_digits = 8;
    if show_header
        if im.BeginMainMenuBar() {
            if im.BeginMenu("General") {
                if im.MenuItem("cpu", "shift+c") {
                    show_cpu = !show_cpu;
                }
                if im.MenuItem("ppu", "shift+g") {
                    show_ppu = !show_ppu;
                }
                if im.MenuItem("apu", "shift+a") {
                    show_apu = !show_apu;
                }
                if im.MenuItem("keypad", "shift+k") {
                    show_keypad = !show_keypad;
                }
                if im.MenuItem("dma", "shift+m") {
                    show_dma = !show_dma;
                }
                if im.MenuItem("window", "shift+w") {
                    show_window = !show_window;
                }
                if im.MenuItem("blend", "shift+b") {
                    show_blend = !show_blend;
                }
                if im.MenuItem("timer", "shift+t") {
                    show_timer = !show_timer;
                }
                im.EndMenu();
            }
            if im.BeginMenu("Memory") {
                if im.MenuItem("rom", "shift+r") {
                    show_rom = !show_rom;
                }
                if im.MenuItem("iwram", "shift+i") {
                    show_iwram = !show_iwram;
                }
                if im.MenuItem("ewram", "shift+e") {
                    show_ewram = !show_ewram;
                }
                if im.MenuItem("vram", "shift+v") {
                    show_vram = !show_vram;
                }
                if im.MenuItem("palette ram", "shift+p") {
                    show_palette_ram = !show_palette_ram;
                }
                if im.MenuItem("oam", "shift+o") {
                    show_oam = !show_oam;
                }
                if im.MenuItem("save data", "shift+s") {
                    show_save = !show_save;
                }
                im.EndMenu();
            }
            if im.BeginMenu("Disassembly") {
                if im.MenuItem("show", "shift+d") {
                    show_disasm = !show_disasm;
                }
                im.EndMenu();
            }
            im.EndMainMenuBar();
        }

    if show_iwram iwram_window();
    if show_ewram ewram_window();
    if show_vram vram_window();
    if show_palette_ram palette_ram_window();
    if show_oam oam_window();
    if show_dma dma_window();
    if show_window window_window();
    if show_blend blend_window();
    if show_timer timer_window();
    if show_rom rom_window();
    if show_cpu cpu_window();
    if show_ppu ppu_window();
    if show_apu apu_window();
    if show_disasm disasm_window();
    if show_keypad keypad_window();
    if show_save save_window();
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
    im.Begin("cpu");
    im.Text("Frame time: %ms", dt * 1000);
    if im.Button("Start") {
        cpu.emu_state = .STARTED;
    }
    im.SameLine();
    if im.Button("Stop") {
        cpu.emu_state = .STOPPED;
    }
    im.SameLine();
    if im.Button("Step") {
        cpu.emu_state = .STEPPED;
    }
    im.SameLine();
    if im.Button("Step Scanline") {
        cpu.emu_state = .STEPPED_SCANLINE;
    }
    im.SameLine();
    if im.Button("Step Frame") {
        cpu.emu_state = .STEPPED_FRAME;
    }
    im.Checkbox("Logging", *cpu.logging);
    if cpu.mode == .USER && cpu.privileged {
        im.Text("Mode: SYSTEM, %", ifx get_status_bit(.T) then "THUMB" else "ARM");
    } else {
        im.Text("Mode: %, %", cpu.mode, ifx get_status_bit(.T) then "THUMB" else "ARM");
    }
    im.Text("PC : 0x% ", cpu.reg[15]);
    im.SameLine();
    im.Text("LR : 0x% ", cpu.reg[14]);
    im.Text("SP : 0x% ", cpu.reg[13]);
    im.SameLine();
    im.Text("PSR:   %1%2%3%4%5%6%7",
        ifx (cpu.psr & 0x80000000) != 0 then "N" else "-",
        ifx (cpu.psr & 0x40000000) != 0 then "Z" else "-",
        ifx (cpu.psr & 0x20000000) != 0 then "C" else "-",
        ifx (cpu.psr & 0x10000000) != 0 then "V" else "-",
        ifx (cpu.psr & 0x00000080) != 0 then "I" else "-",
        ifx (cpu.psr & 0x00000040) != 0 then "F" else "-",
        ifx (cpu.psr & 0x00000020) != 0 then "T" else "-",
    );
    im.Text("R00: 0x% ", cpu.reg[0]);
    im.SameLine();
    im.Text("R01: 0x% ", cpu.reg[1]);
    im.Text("R02: 0x% ", cpu.reg[2]);
    im.SameLine();
    im.Text("R03: 0x% ", cpu.reg[3]);
    im.Text("R04: 0x% ", cpu.reg[4]);
    im.SameLine();
    im.Text("R05: 0x% ", cpu.reg[5]);
    im.Text("R06: 0x% ", cpu.reg[6]);
    im.SameLine();
    im.Text("R07: 0x% ", cpu.reg[7]);
    im.Text("R08: 0x% ", cpu.reg[8]);
    im.SameLine();
    im.Text("R09: 0x% ", cpu.reg[9]);
    im.Text("R10: 0x% ", cpu.reg[10]);
    im.SameLine();
    im.Text("R11: 0x% ", cpu.reg[11]);
    im.Text("R12: 0x% ", cpu.reg[12]);
    im.NewLine();
    im.Text("Interrupts %abled", ifx cpu.interrupt_master_enable then "en" else "dis");
    for enum_names(Interrupt_Source) {
        im.Text("%: %abled, %triggered", it, ifx (cpu.ie & (1 << it_index)) != 0 then "en" else "dis", ifx (cpu.ie & (1 << it_index)) != 0 then "" else "not ");
    }
    im.End();
}

Bg_Control_Lut_Entry :: struct {
    bg_min : s32 = 0;
    bg_max : s32 = 0;
    bg_rs_mode: [4]bool;
}

mode_lut := Bg_Control_Lut_Entry.[
    .{0, 3, .[false, false, false, false]},
    .{0, 2, .[false, false, true, false]},
    .{2, 3, .[false, false, true, true]},
    .{2, 2, .[false, false, true, false]},
    .{2, 2, .[false, false, true, false]}
];
background_selected : s32 = 0;
ppu_window :: () {
    im.Begin("ppu");
    im.Text("Force Blank: %", ppu.forced_blank);
    im.Text("X: %", formatInt(ppu.draw_x, 10, 1));
    im.Text("Y: %", formatInt(ppu.draw_y, 10, 1));
    im.Text("Character Format: %-dimensional", ifx ppu.obj_character_vram_mapping_one_dimensional then "1" else "2");
    im.Text("BG Mode: %", formatInt(ppu.bg_mode, 10, 1));
    im.InputInt("Background", *background_selected, 1, 1, .CharsDecimal);
    if background_selected < mode_lut[ppu.bg_mode].bg_min then background_selected = mode_lut[ppu.bg_mode].bg_min;
    if background_selected > mode_lut[ppu.bg_mode].bg_max then background_selected = mode_lut[ppu.bg_mode].bg_max;

    im.Text("%abled", ifx ppu.bg[background_selected].enable then "en" else "dis");
    im.Text("%", ifx ppu.bg[background_selected].single_palette then "256 colors, 1 palette" else "16 colors, 16 palettes");
    im.Text("Priority: %", ppu.bg[background_selected].prio);
    im.Text("Size: %1%2", ifx ppu.bg[background_selected].tall then "1" else "0", ifx ppu.bg[background_selected].wide then "1" else "0");
    im.Text("Mosaic %abled", ifx ppu.bg[background_selected].mosaic then "en" else "dis");
    im.Text("Screen Offset: 0x%", formatInt(ppu.bg[background_selected].screen_base_block * 2048, 16));
    im.Text("Char Offset: 0x%", formatInt(ppu.bg[background_selected].char_base_block * 16384, 16));

    im.NewLine();
    if mode_lut[ppu.bg_mode].bg_rs_mode[background_selected] {
        im.Text("Scale/Rotate Mode");
        im.Text("X: % (raw: 0x%)", ppu.bg[background_selected].anchor_x, formatInt(ppu.bg[background_selected].anchor_x_raw, 16, 1));
        im.Text("Y: % (raw: 0x%)", ppu.bg[background_selected].anchor_y, formatInt(ppu.bg[background_selected].anchor_y_raw, 16, 1));
        im.Text("Wraparound: %", ppu.bg[background_selected].wraparound);
        im.Text("Transform: % | % | % | %", ppu.bg[background_selected].pa, ppu.bg[background_selected].pb, ppu.bg[background_selected].pc, ppu.bg[background_selected].pd);
        im.Text("Transform (Raw): 0x% | 0x% | 0x% | 0x%", formatInt(ppu.bg[background_selected].dx, 16, 8), formatInt(ppu.bg[background_selected].dmx, 16, 8), formatInt(ppu.bg[background_selected].dy, 16, 8), formatInt(ppu.bg[background_selected].dmy, 16, 8));
    } else {
        im.Text("Text Mode");
        im.Text("X: %", formatInt(ppu.bg[background_selected].x_off, 10, 1));
        im.Text("Y: %", formatInt(ppu.bg[background_selected].y_off, 10, 1));
    }

    im.End();
}

overflows : s32 = 0;
channel_selected : s32 = 1;
apu_window :: () {
    im.Begin("apu");
    im.Text_CFormat("Overflows: %d", overflows);
    im.Text_CFormat("Bias: %d", apu.bias);
    im.Text_CFormat("Sampling Frequency: %d", apu.sampling_frequency);
    im.Text_CFormat("Played Samples: %d", apu.played_samples);
    im.InputInt("Channel", *channel_selected, 1, 1, .CharsDecimal);
    if channel_selected < 1 then channel_selected = 1;
    if channel_selected > 6 then channel_selected = 6;
    if channel_selected == {
        case 1;
        im.Text_CFormat("Sweep Shift Count: %d", apu.chan_1.sweep_shift_cnt);
        im.Text("Sweep Direction: %crease", ifx apu.chan_1.sweep_freq_decrease then "De" else "In");
        im.Text_CFormat("Sweep Time: %d", apu.chan_1.sweep_time);
        im.Text_CFormat("Envelope Initial Volume: %d", apu.chan_1.envelope_initial_volume);
        im.Text("Envelope Direction: %crease", ifx apu.chan_1.envelope_increase then "De" else "In");
        im.Text_CFormat("Envelope Speed: %d", apu.chan_1.envelope_speed);
        im.Text_CFormat("Duty Cycle: %d", apu.chan_1.duty_cycle);
        im.Text("Use Length: %", apu.chan_1.use_length);
        im.Text_CFormat("Sound Length: %d", apu.chan_1.sound_length);
        im.Text_CFormat("Frequency: %d", apu.chan_1.frequency);
        case 2;
        im.Text_CFormat("Envelope Initial Volume: %d", apu.chan_2.envelope_initial_volume);
        im.Text("Envelope Direction: %crease", ifx apu.chan_2.envelope_increase then "De" else "In");
        im.Text_CFormat("Envelope Speed: %d", apu.chan_2.envelope_speed);
        im.Text_CFormat("Duty Cycle: %d", apu.chan_2.duty_cycle);
        im.Text("Use Length: %", apu.chan_2.use_length);
        im.Text_CFormat("Sound Length: %d", apu.chan_2.sound_length);
        im.Text_CFormat("Frequency: %d", apu.chan_2.frequency);
        case 5;
        im.Text("Enable: %%", ifx apu.chan_a.enable_l then "L" else "-", ifx apu.chan_a.enable_r then "R" else "-");
        im.Text("Volume: %", ifx apu.chan_a.volume then "100%" else "50%");
        im.Text_CFormat("Timer Select: %d", apu.chan_a.timer_select);
        im.Text_CFormat("FIFO R: %d", apu.fifo_a.rb.r & 0x1f);
        im.Text_CFormat("FIFO W: %d", apu.fifo_a.rb.w & 0x1f);
        im.Text_CFormat("FIFO Count: %d", apu.fifo_a.rb.w - apu.fifo_a.rb.r);
        case 6;
        im.Text("Enable: %%", ifx apu.chan_b.enable_l then "L" else "-", ifx apu.chan_b.enable_r then "R" else "-");
        im.Text("Volume: %", ifx apu.chan_b.volume then "100%" else "50%");
        im.Text_CFormat("Timer Select: %d", apu.chan_b.timer_select);
        im.Text_CFormat("FIFO R: %d", apu.fifo_b.rb.r & 0x1f);
        im.Text_CFormat("FIFO W: %d", apu.fifo_b.rb.w & 0x1f);
        im.Text_CFormat("FIFO Count: %d", apu.fifo_b.rb.w - apu.fifo_b.rb.r);
    }
    im.End();
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
                    if (inst & 0x200000) != 0 {
                        opcode = ifx flags then "SMLALS" else "SMLAL";
                    } else {
                        opcode = ifx flags then "SMULLS" else "SMULL";
                    }
                } else {
                    if (inst & 0x200000) != 0 {
                        opcode = ifx flags then "UMLALS" else "UMLAL";
                    } else {
                        opcode = ifx flags then "UMULLS" else "UMULL";
                    }
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
                    opcode = "MSR";
                    c := (inst & 0x10000) != 0;
                    f := (inst & 0x80000) != 0;
                    append(*suffix, ifx (inst & 0x400000) != 0 then "SPSR_" else "CPSR_");
                    if f append(*suffix, #char "f");
                    if c append(*suffix, #char "c");
                    append(*suffix, ", ");
                    append(*suffix, tprint("#0x%", formatInt(inst & 0xfff, 16)));
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
                            opcode = "CMP";
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
                        case 0b1011;
                            // cmn
                            opcode = "CMN";
                            append(*suffix, disassemble_register((inst >> 16) & 0xf));
                            append(*suffix, ", ");
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
                            opcode = ifx flags then "MVNS" else "MVN";
                            append(*suffix, disassemble_register((inst >> 12) & 0xf));
                            append(*suffix, ", ");
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
            i := (inst & 0x2000000) != 0;
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
                if !i append(*suffix, "#");
                if !u append(*suffix, "-");
                if i {
                    append(*suffix, disassemble_shifter(offset));
                } else {
                    append(*suffix, tprint("%", formatInt(offset, 10, 1)));
                }
            } else if !w {
                // offset addressing
                append(*suffix, ", ");
                if !i append(*suffix, "#");
                if !u append(*suffix, "-");
                if i {
                    append(*suffix, disassemble_shifter(offset));
                } else {
                    append(*suffix, tprint("%", formatInt(offset, 10, 1)));
                }
                append(*suffix, "]");
            } else {
                // pre indexed
                append(*suffix, ", ");
                if !i append(*suffix, "#");
                if !u append(*suffix, "-");
                if i {
                    append(*suffix, disassemble_shifter(offset));
                } else {
                    append(*suffix, tprint("%", formatInt(offset, 10, 1)));
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
                if s append(*suffix, "^");
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
                append(*suffix, tprint("0x%", formatInt(addr, 16)));
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
                    opcode = "SWI";
                    append(*suffix, tprint("0x%", formatInt(inst & 0xffffff, 16)));
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
                opcode = "ldrsh";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", [");
                append(*suffix, disassemble_register(rn_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
                append(*suffix, "]");
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
                rd_idx : u8 = xx ((ins & 0b111) | ((ins >> 4) & 0b1000));
                rm_idx : u8 = xx ((ins >> 3) & 0xf);
                opcode = "add";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rm_idx));
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
                opcode = "lsl";
                append(*suffix, disassemble_register(rd_idx));
                append(*suffix, ", ");
                append(*suffix, disassemble_register(rs_idx));
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
        if !s then imm *= 4;
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
            append(*suffix, ", #0x");
            append(*suffix, tprint("%", formatInt(immed * 2, 16, 1)));
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
            cond_idx := (ins >> 8) & 0xf;
            if cond_idx == 0xf {
                opcode = "swi";
                append(*suffix, tprint("0x%", formatInt(ins & 0xff, 16, 1)));
            } else {
                opcode = tprint("b%", cond_lut_lower[cond_idx]);
                immed : s32 = xx (ins & 0xff) << 1;
                if immed > 255 then immed -= 512;
                append(*suffix, tprint("0x%", formatInt(immed, 16, 1)));
            }
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
disasm_mode := false;
disasm_jump_buffer: [8]u8;
disasm_window :: () {
    im.Begin("disasm", null, .NoScrollbar | .NoScrollWithMouse);
    if im.IsWindowHovered() {
        if im.GetIO().MouseWheel < 0 {
            disasm_scroll_state += 1;
        } else if im.GetIO().MouseWheel > 0 {
            disasm_scroll_state -= 1;
            disasm_scroll_state = max(disasm_scroll_state, 0);
        }
    }
    if im.Button("Jump to PC") {
        disasm_scroll_state = cpu.reg[15] / ifx get_status_bit(.T) then 2 else 4;
    }
    im.SameLine();
    if im.Button(tprint("%\0", ifx disasm_mode then "T" else "A").data) {
        if disasm_mode {
            disasm_scroll_state /= 2;
            disasm_mode = false;
        } else {
            disasm_scroll_state *= 2;
            disasm_mode = true;
        }
    }
    im.SameLine();
    im.Text("0x");
    im.SameLine();
    if im.InputText("Jump to...", disasm_jump_buffer.data, 8) {
        str := string.{7, disasm_jump_buffer.data};
        parsed := string_to_int(str, 16);
        disasm_scroll_state = parsed / ifx disasm_mode then 2 else 4;
    }
    for 0..cast(int)im.GetWindowSize().y {
        addr : u32 = xx ((disasm_scroll_state + xx it) * ifx disasm_mode then 2 else 4);
        to_print := ifx !disasm_mode then
            disassemble_arm_instruction(read_32(addr, true, true))
            else disassemble_thumb_instruction(read_16(addr, true, true));
            has_breakpoint := ifx !disasm_mode then ((read_32(addr, true, true) & 0xfff000f0) == 0xe1200070) else ((read_16(addr, true, true) & 0xff00) == 0xbe00);
        in_history, history_idx := array_find(cpu.pc_history, addr);
        if addr == cpu.reg[15] {
            im.TextColored(.{0, 1, 0, 1}, "%\t%", addr, to_print);
        } else if has_breakpoint {
            im.TextColored(.{1, 0, 0, 1}, "%\t%", addr, to_print);
        } else if in_history {
            idx := cpu.pc_history_idx - history_idx - 1;
            if idx < 0 then idx += 64;
            if idx > 63 then idx -= 64;
            im.TextColored(.{(idx * (1.0 / 64.0)), 1, (idx * (1.0 / 64.0)), 1}, "%\t%", addr, to_print);
        } else {
            im.Text("%\t%", addr, to_print);
        }
        if im.IsItemHovered() {
            im.SetTooltip("0x%", ifx !disasm_mode then read_32(addr, true, true) else read_16(addr, true, true));
        }
        if im.IsItemClicked() {
            if !disasm_mode {
                ins := read_32(addr, true, true);
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
                ins := read_16(addr, true, true);
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
    im.End();
}

keypad_window :: () {
    controller_string := #string DONE
       _______________________
  ____/                       \____
 /__/     _________________     \__\
|        |                 |        |
|   ^    |                 |        |
|  < >   |                 |     O  |
|   v  o |                 |  O     |
|      o |                 |        |
 \__     \_________________/     __/
    \___________________________/
DONE
    controller_split := string.["       _______________________",
    "  ___", "_/                       \\_", "___",
    " /", "__/     _________________     \\__", "\\",
    "|        |                 |        |",
    "|   ", "^", "    |                 |        |",
    "|  ", "<", " >", "   |                 |     ", "O", "  |",
    "|   ", "v", "  ", "o", " |                 |  ", "O", "     |",
    "|      ", "o", " |                 |        |",
    " \\__     \\_________________/     __/",
    "    \\___________________________/"];
    off := Vector4.{1.0, 1.0, 1.0, 1.0};
    on := Vector4.{1.0, 0.0, 0.0, 1.0};
    im.Begin("keypad");
    im.PushStyleVar(.ItemSpacing, .{0.0, 0.0});
    im.Text("%", controller_split[0]);
    im.TextColored(ifx (ppu.keypad_state & 0x200) != 0 then on else off, "%", controller_split[1]);
    im.SameLine();
    im.Text("%", controller_split[2]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x100) != 0 then on else off, "%", controller_split[3]);
    im.TextColored(ifx (ppu.keypad_state & 0x200) != 0 then on else off, "%", controller_split[4]);
    im.SameLine();
    im.Text("%", controller_split[5]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x100) != 0 then on else off, "%", controller_split[6]);
    im.Text("%", controller_split[7]);
    im.Text("%", controller_split[8]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x40) != 0 then on else off, "%", controller_split[9]);
    im.SameLine();
    im.Text("%", controller_split[10]);
    im.Text("%", controller_split[11]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x20) != 0 then on else off, "%", controller_split[12]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x10) != 0 then on else off, "%", controller_split[13]);
    im.SameLine();
    im.Text("%", controller_split[14]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x1) != 0 then on else off, "%", controller_split[15]);
    im.SameLine();
    im.Text("%", controller_split[16]);
    im.Text("%", controller_split[17]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x80) != 0 then on else off, "%", controller_split[18]);
    im.SameLine();
    im.Text("%", controller_split[19]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x8) != 0 then on else off, "%", controller_split[20]);
    im.SameLine();
    im.Text("%", controller_split[21]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x2) != 0 then on else off, "%", controller_split[22]);
    im.SameLine();
    im.Text("%", controller_split[23]);
    im.Text("%", controller_split[24]);
    im.SameLine();
    im.TextColored(ifx (ppu.keypad_state & 0x4) != 0 then on else off, "%", controller_split[25]);
    im.SameLine();
    im.Text("%", controller_split[26]);
    im.Text("%", controller_split[27]);
    im.Text("%", controller_split[28]);
    im.PopStyleVar();
    im.End();
}

confirm_save := false;
confirm_load := false;
save_window :: () {
    im.Begin("save data", null);
    im.Text("Save Data Type: %", cpu.backup_type);
    if cpu.backup_type == {
        case .EEPROM;
        im.Text("Size: %", cpu.eeprom_size);
    }

    if im.Button(ifx confirm_save then "Confirm Save##save".data else "Save##save".data) {
        if confirm_save {
            file_name := tprint("%.gbasav", cpu.cart_name);
            f := file_open(file_name, true, false);
            file_write(*f, *cpu.backup_type, size_of(Backup_Type));
            if cpu.backup_type == {
                case .SRAM;
                file_write(*f, cpu.sram.data, cpu.sram.count);
                case .EEPROM;
                file_write(*f, *cpu.eeprom_size, size_of(Eeprom_Size));
                file_write(*f, cpu.ee.data, ifx cpu.eeprom_size == .EEPROM_512B then 512 else 8192);
                case .FLASH_64K; #through;
                case .FLASH_128K;
                file_write(*f, cpu.flash.data, cpu.flash.count);
            }
            file_close(*f);
            confirm_save = false;
        } else {
            confirm_save = true;
        }
    }
    im.SameLine();
    if im.Button(ifx confirm_load then "Confirm Load##load".data else "Load##load".data) {
        if confirm_load {
            file_name := tprint("%.gbasav", cpu.cart_name);
            f := file_open(file_name, false);
            file_read(f, *cpu.backup_type, size_of(Backup_Type));
            if cpu.backup_type == {
                case .SRAM;
                file_read(f, cpu.sram.data, cpu.sram.count);
                case .EEPROM;
                file_read(f, *cpu.eeprom_size, size_of(Eeprom_Size));
                file_read(f, cpu.ee.data, ifx cpu.eeprom_size == .EEPROM_512B then 512 else 8192);
                case .FLASH_64K; #through;
                case .FLASH_128K;
                file_read(f, cpu.flash.data, cpu.flash.count);
            }
            file_close(*f);
            confirm_load = false;
        } else {
            confirm_load = true;
        }
    }

    im.End();
}

iwram_scroll_state := 0;
iwram_jump_buffer: [5]u8;
iwram_window :: () {
    im.Begin("iwram", null, .NoScrollbar | .NoScrollWithMouse);
    im.Text("0x");
    im.SameLine();
    if im.IsWindowHovered() {
        if im.GetIO().MouseWheel < 0 {
            iwram_scroll_state += 1;
        } else if im.GetIO().MouseWheel > 0 {
            iwram_scroll_state -= 1;
            iwram_scroll_state = max(iwram_scroll_state, 0);
        }
    }
    if im.InputText("Jump to...", iwram_jump_buffer.data, 5) {
        str := string.{4, iwram_jump_buffer.data};
        parsed := string_to_int(str, 16);
        iwram_scroll_state = parsed / 16;
    }
    im.BeginTable("##iwram", 17, .Borders | .RowBg | .SizingFixedFit);
    im.TableNextRow();
    for 0..cast(int)im.GetWindowSize().y {
        if (it + iwram_scroll_state + 1) * 16 > 0x8000 {
            iwram_scroll_state = (0x8000 - 16 * it) / 16;
            break;
        }
        im.TableNextColumn();
        im.Text_CFormat("0x%04x", (it + iwram_scroll_state) * 16);
        for it2 : 0..15 {
            im.TableNextColumn();
            im.Text_CFormat("%02x", cpu.memory.iwram._8[(it + iwram_scroll_state) * 16 + it2]);
            if im.IsItemHovered() {
                im.SetTooltip("0x%", 0x03000000 + (it + iwram_scroll_state) * 16 + it2);
            }
        }
    }
    im.EndTable();
    im.End();
}

ewram_scroll_state := 0;
ewram_jump_buffer: [6]u8;
ewram_window :: () {
    im.Begin("ewram", null, .NoScrollbar | .NoScrollWithMouse);
    im.Text("0x");
    im.SameLine();
    if im.IsWindowHovered() {
        if im.GetIO().MouseWheel < 0 {
            ewram_scroll_state += 1;
        } else if im.GetIO().MouseWheel > 0 {
            ewram_scroll_state -= 1;
            ewram_scroll_state = max(ewram_scroll_state, 0);
        }
    }
    if im.InputText("Jump to...", ewram_jump_buffer.data, 6) {
        str := string.{5, ewram_jump_buffer.data};
        parsed := string_to_int(str, 16);
        ewram_scroll_state = parsed / 16;
    }
    im.BeginTable("##ewram", 17, .Borders | .RowBg | .SizingFixedFit);
    im.TableNextRow();
    for 0..cast(int)im.GetWindowSize().y {
        if (it + ewram_scroll_state + 1) * 16 > 0x40000 {
            ewram_scroll_state = (0x40000 - 16 * it) / 16;
            break;
        }
        im.TableNextColumn();
        im.Text_CFormat("0x%05x", (it + ewram_scroll_state) * 16);
        for it2 : 0..15 {
            im.TableNextColumn();
            im.Text_CFormat("%02x", cpu.memory.ewram._8[(it + ewram_scroll_state) * 16 + it2]);
            if im.IsItemHovered() {
                im.SetTooltip("0x%", 0x02000000 + (it + ewram_scroll_state) * 16 + it2);
            }
        }
    }
    im.EndTable();
    im.End();
}

vram_scroll_state := 0;
vram_jump_buffer: [6]u8;
vram_window :: () {
    im.Begin("vram", null, .NoScrollbar | .NoScrollWithMouse);
    im.Text("0x");
    im.SameLine();
    if im.IsWindowHovered() {
        if im.GetIO().MouseWheel < 0 {
            vram_scroll_state += 1;
        } else if im.GetIO().MouseWheel > 0 {
            vram_scroll_state -= 1;
            vram_scroll_state = max(vram_scroll_state, 0);
        }
    }
    if im.InputText("Jump to...", vram_jump_buffer.data, 6) {
        str := string.{5, vram_jump_buffer.data};
        parsed := string_to_int(str, 16);
        vram_scroll_state = parsed / 16;
    }
    im.BeginTable("##vram", 17, .Borders | .RowBg | .SizingFixedFit);
    im.TableNextRow();
    for 0..cast(int)im.GetWindowSize().y {
        if (it + vram_scroll_state + 1) * 16 > 0x18000 {
        vram_scroll_state = (0x18000 - 16 * it) / 16;
            break;
        }
        im.TableNextColumn();
        im.Text_CFormat("0x%05x", (it + vram_scroll_state) * 16);
        for it2 : 0..15 {
            im.TableNextColumn();
            im.Text_CFormat("%02x", ppu.memory.vram._8[(it + vram_scroll_state) * 16 + it2]);
            if im.IsItemHovered() {
                im.SetTooltip("0x%", 0x06000000 + (it + vram_scroll_state) * 16 + it2);
            }
        }
    }
    im.EndTable();
    im.End();
}

palette_ram_scroll_state := 0;
palette_ram_jump_buffer: [4]u8;
palette_ram_window :: () {
    im.Begin("palette_ram", null, .NoScrollbar | .NoScrollWithMouse);
    im.Text("0x");
    im.SameLine();
    if im.IsWindowHovered() {
        if im.GetIO().MouseWheel < 0 {
            palette_ram_scroll_state += 1;
        } else if im.GetIO().MouseWheel > 0 {
            palette_ram_scroll_state -= 1;
            palette_ram_scroll_state = max(palette_ram_scroll_state, 0);
        }
    }
    if im.InputText("Jump to...", palette_ram_jump_buffer.data, 4) {
        str := string.{3, palette_ram_jump_buffer.data};
        parsed := string_to_int(str, 16);
        palette_ram_scroll_state = parsed / 16;
    }
    im.BeginTable("##palette_ram", 17, .Borders | .RowBg | .SizingFixedFit);
    im.TableNextRow();
    for 0..cast(int)im.GetWindowSize().y {
        if (it + palette_ram_scroll_state + 1) * 16 > 0x400 {
        palette_ram_scroll_state = (0x400 - 16 * it) / 16;
            break;
        }
        im.TableNextColumn();
        im.Text_CFormat("0x%03x", (it + palette_ram_scroll_state) * 16);
        for it2 : 0..15 {
            im.TableNextColumn();
            im.Text_CFormat("%02x", ppu.memory.palette_ram._8[(it + palette_ram_scroll_state) * 16 + it2]);
            if im.IsItemHovered() {
                im.SetTooltip("0x%", 0x05000000 + (it + palette_ram_scroll_state) * 16 + it2);
            }
        }
    }
    im.EndTable();
    im.End();
}

oam_scroll_state := 0;
oam_jump_buffer: [4]u8;
oam_window :: () {
    oam_sizing_lut :: []string.[
        .["8x8", "16x16", "32x32", "64x64"],
        .["16x8", "32x8", "32x16", "64x32"],
        .["0x16", "8x32", "16x32", "32x64"]
    ];
    im.Begin("oam", null, .NoScrollbar | .NoScrollWithMouse);
    im.Text("0x");
    im.SameLine();
    if im.IsWindowHovered() {
        if im.GetIO().MouseWheel < 0 {
            oam_scroll_state += 1;
        } else if im.GetIO().MouseWheel > 0 {
            oam_scroll_state -= 1;
            oam_scroll_state = max(oam_scroll_state, 0);
        }
    }
    if im.InputText("Jump to...", oam_jump_buffer.data, 4) {
        str := string.{3, oam_jump_buffer.data};
        parsed := string_to_int(str, 16);
        oam_scroll_state = parsed;
    }
    im.BeginTable("##oam", 15, .Borders | .RowBg | .SizingFixedFit | .ScrollX);
    im.TableSetupColumn("Idx");
    im.TableSetupColumn("X");
    im.TableSetupColumn("Y");
    im.TableSetupColumn("TileIdx");
    im.TableSetupColumn("Size");
    im.TableSetupColumn("FlipH");
    im.TableSetupColumn("FlipV");
    im.TableSetupColumn("R&S");
    im.TableSetupColumn("R&SDoubleSize");
    im.TableSetupColumn("R&SParamIdx");
    im.TableSetupColumn("Mode");
    im.TableSetupColumn("Mosaic");
    im.TableSetupColumn("SinglePalette");
    im.TableSetupColumn("Prio");
    im.TableSetupColumn("Palette");
    im.TableHeadersRow();
    for 0..cast(int)im.GetWindowSize().y {
        if (it + oam_scroll_state + 1) > 128 {
            oam_scroll_state = (128 - it);
            break;
        }
        im.TableNextColumn();
        im.Text_CFormat("%03d", it + oam_scroll_state);
        if im.IsItemHovered() {
            im.SetTooltip("% | % | % | %", ppu.oam_param[ppu.oam[it + oam_scroll_state].rotate_scale_param_idx].pa, ppu.oam_param[ppu.oam[it + oam_scroll_state].rotate_scale_param_idx].pb,  ppu.oam_param[ppu.oam[it + oam_scroll_state].rotate_scale_param_idx].pc, ppu.oam_param[ppu.oam[it + oam_scroll_state].rotate_scale_param_idx].pd);
        }
        im.TableNextColumn();
        im.Text_CFormat("%d", ppu.oam[it + oam_scroll_state].x);
        if im.IsItemHovered() {
            im.SetTooltip("Sprite: %-%, Bound: %-%", formatInt(ppu.oam[it + oam_scroll_state].min_x, 10, 1), formatInt(ppu.oam[it + oam_scroll_state].max_x, 10, 1), formatInt(ppu.oam[it + oam_scroll_state].bounding_box_min_x, 10, 1), formatInt(ppu.oam[it + oam_scroll_state].bounding_box_max_x, 10, 1));
        }
        im.TableNextColumn();
        im.Text_CFormat("%d", ppu.oam[it + oam_scroll_state].y);
        if im.IsItemHovered() {
            im.SetTooltip("Sprite: %-%, Bound: %-%", formatInt(ppu.oam[it + oam_scroll_state].min_y, 10, 1), formatInt(ppu.oam[it + oam_scroll_state].max_y, 10, 1), formatInt(ppu.oam[it + oam_scroll_state].bounding_box_min_y, 10, 1), formatInt(ppu.oam[it + oam_scroll_state].bounding_box_max_y, 10, 1));
        }
        im.TableNextColumn();
        im.Text_CFormat("%d", ppu.oam[it + oam_scroll_state].tile_idx);
        im.TableNextColumn();
        im.Text_CFormat("%s", oam_sizing_lut[ppu.oam[it + oam_scroll_state].shape][ppu.oam[it + oam_scroll_state].size].data);
        im.TableNextColumn();
        im.Text("%", ppu.oam[it + oam_scroll_state].flip_h);
        im.TableNextColumn();
        im.Text("%", ppu.oam[it + oam_scroll_state].flip_v);
        im.TableNextColumn();
        im.Text("%", ppu.oam[it + oam_scroll_state].rotate_scale);
        im.TableNextColumn();
        im.Text("%", ppu.oam[it + oam_scroll_state].rotate_scale_double_size);
        im.TableNextColumn();
        im.Text_CFormat("%d", ppu.oam[it + oam_scroll_state].rotate_scale_param_idx);
        im.TableNextColumn();
        im.Text_CFormat("%d", ppu.oam[it + oam_scroll_state].mode);
        im.TableNextColumn();
        im.Text("%", ppu.oam[it + oam_scroll_state].mosaic);
        im.TableNextColumn();
        im.Text("%", ppu.oam[it + oam_scroll_state].single_palette);
        im.TableNextColumn();
        im.Text_CFormat("%d", ppu.oam[it + oam_scroll_state].prio);
        im.TableNextColumn();
        im.Text_CFormat("%d", ppu.oam[it + oam_scroll_state].palette);
        im.TableNextRow();
    }
    im.EndTable();
    im.End();
}

dma_selected : s32 = 0;
dma_window :: () {
    im.Begin("dma", null, .NoScrollbar | .NoScrollWithMouse);
    im.InputInt("Channel", *dma_selected, 1, 1, .CharsDecimal);
    if dma_selected < 0 then dma_selected = 0;
    if dma_selected > 3 then dma_selected = 3;
    im.Text("%abled", ifx cpu.dma[dma_selected].enable then "en" else "dis");
    im.Text("Source: 0x% (0x%)", formatInt(cpu.dma[dma_selected].src, 16, 1), formatInt(cpu.dma[dma_selected].src_int, 16, 1));
    im.Text("Destination: 0x% (0x%)", formatInt(cpu.dma[dma_selected].dst, 16, 1), formatInt(cpu.dma[dma_selected].dst_int, 16, 1));
    im.Text("Size: 0x%", formatInt(cpu.dma[dma_selected].count_int, 16, 1));
    im.Text("Enable: %", cpu.dma[dma_selected].enable);
    im.Text("IRQ on complete: %", cpu.dma[dma_selected].irq);
    im.Text("Repeat: %", cpu.dma[dma_selected].repeat);
    im.Text("Transfer Size: %-bit", ifx cpu.dma[dma_selected].large_transfer then "32" else "16");
    im.Text("Source Address Control: %", cpu.dma[dma_selected].src_addr_control);
    im.Text("Destination Address Control: %", cpu.dma[dma_selected].dst_addr_control);
    im.Text("Start Timing: %", cpu.dma[dma_selected].start_timing);
    im.End();
}

window_window :: ()  {
    im.Begin("window");
    im.Text("Window 1:");
    im.Text("%abled, %2%3%4%5%6", ifx ppu.win[0].enable then "En" else "Dis",
        ifx ppu.win[0].bg_enable[0] then "1" else "-",
        ifx ppu.win[0].bg_enable[1] then "2" else "-",
        ifx ppu.win[0].bg_enable[2] then "3" else "-",
        ifx ppu.win[0].bg_enable[3] then "4" else "-",
        ifx ppu.win[0].obj_enable then "O" else "-",
    );
    im.Text("Special effects %abled", ifx ppu.win[0].special_effect then "en" else "dis");
    im.Text("Min X: %", formatInt(ppu.win[0].min_x, 10, 1));
    im.Text("Max X: %", formatInt(ppu.win[0].max_x, 10, 1));
    im.Text("Min Y: %", formatInt(ppu.win[0].min_y, 10, 1));
    im.Text("Max Y: %", formatInt(ppu.win[0].max_y, 10, 1));
    im.NewLine();
    im.Text("Window 2:");
    im.Text("%abled, %2%3%4%5%6", ifx ppu.win[1].enable then "En" else "Dis",
        ifx ppu.win[1].bg_enable[0] then "1" else "-",
        ifx ppu.win[1].bg_enable[1] then "2" else "-",
        ifx ppu.win[1].bg_enable[2] then "3" else "-",
        ifx ppu.win[1].bg_enable[3] then "4" else "-",
        ifx ppu.win[1].obj_enable then "O" else "-",
    );
    im.Text("Special effects %abled", ifx ppu.win[1].special_effect then "en" else "dis");
    im.Text("Min X: %", formatInt(ppu.win[1].min_x, 10, 1));
    im.Text("Max X: %", formatInt(ppu.win[1].max_x, 10, 1));
    im.Text("Min Y: %", formatInt(ppu.win[1].min_y, 10, 1));
    im.Text("Max Y: %", formatInt(ppu.win[1].max_y, 10, 1));
    im.NewLine();
    im.Text("Outside Windows:");
    im.Text("%1%2%3%4%5",
        ifx ppu.outside_win_bg_enable[0] then "1" else "-",
        ifx ppu.outside_win_bg_enable[1] then "2" else "-",
        ifx ppu.outside_win_bg_enable[2] then "3" else "-",
        ifx ppu.outside_win_bg_enable[3] then "4" else "-",
        ifx ppu.outside_win_obj_enable then "O" else "-",
    );
    im.NewLine();
    im.Text("OBJ Window:");
    im.Text("%abled, %2%3%4%5%6", ifx ppu.obj_win.enable then "En" else "Dis",
        ifx ppu.obj_win.bg_enable[0] then "1" else "-",
        ifx ppu.obj_win.bg_enable[1] then "2" else "-",
        ifx ppu.obj_win.bg_enable[2] then "3" else "-",
        ifx ppu.obj_win.bg_enable[3] then "4" else "-",
        ifx ppu.obj_win.obj_enable then "O" else "-",
    );
    im.Text("Special effects %abled", ifx ppu.obj_win.special_effect then "en" else "dis");
    im.End();
}

blend_window :: () {
    im.Begin("blend");
    im.Text("Mode: %", ppu.special_effect);
    im.Text_CFormat("Coefficient A: %d", ppu.eva);
    im.Text_CFormat("Coefficient B: %d", ppu.evb);
    im.Text_CFormat("Coefficient Y: %d", ppu.evy);
    im.Text("First: %1%2%3%4%5%6",
        ifx ppu.bg_first_target_pixel[0] then "1" else "-",
        ifx ppu.bg_first_target_pixel[1] then "2" else "-",
        ifx ppu.bg_first_target_pixel[2] then "3" else "-",
        ifx ppu.bg_first_target_pixel[3] then "4" else "-",
        ifx ppu.obj_first_target_pixel then "O" else "-",
        ifx ppu.bd_first_target_pixel then "B" else "-"
    );
    im.Text("Second: %1%2%3%4%5%6",
        ifx ppu.bg_second_target_pixel[0] then "1" else "-",
        ifx ppu.bg_second_target_pixel[1] then "2" else "-",
        ifx ppu.bg_second_target_pixel[2] then "3" else "-",
        ifx ppu.bg_second_target_pixel[3] then "4" else "-",
        ifx ppu.obj_second_target_pixel then "O" else "-",
        ifx ppu.bd_second_target_pixel then "B" else "-"
    );
    im.End();
}

timer_selected : s32 = 0;
timer_window :: () {
    im.Begin("timer");
    im.InputInt("Channel", *timer_selected, 1, 1, .CharsDecimal);
    if timer_selected < 0 timer_selected = 0;
    if timer_selected > 3 timer_selected = 3;
    im.Text("Enabled: %", cpu.timer[timer_selected].enable);
    im.Text("IRQ: %", cpu.timer[timer_selected].irq);
    im.Text("Count-Up Mode: %", cpu.timer[timer_selected].ignore_prescaler);
    im.Text_CFormat("Counter: 0x%04x", cpu.timer[timer_selected].counter);
    im.Text_CFormat("Reload: 0x%04x", cpu.timer[timer_selected].reload);
    im.Text_CFormat("Prescaler: %d", int.[1, 64, 256, 1024][cpu.timer[timer_selected].prescaler_selection]);
    im.End();
}

rom_scroll_state := 0;
rom_jump_buffer: [8]u8;
rom_window :: () {
    im.Begin("rom", null, .NoScrollbar | .NoScrollWithMouse);
    im.Text("0x");
    im.SameLine();
    if im.IsWindowHovered() {
        if im.GetIO().MouseWheel < 0 {
            rom_scroll_state += 1;
        } else if im.GetIO().MouseWheel > 0 {
            rom_scroll_state -= 1;
            rom_scroll_state = max(rom_scroll_state, 0);
        }
    }
    if im.InputText("Jump to...", rom_jump_buffer.data, 8) {
        str := string.{7, rom_jump_buffer.data};
        parsed := string_to_int(str, 16);
        rom_scroll_state = parsed / 16;
    }
    im.BeginTable("##rom", 17, .Borders | .RowBg | .SizingFixedFit);
    im.TableNextRow();
    for 0..cast(int)im.GetWindowSize().y {
        if (it + rom_scroll_state + 1) * 16 > cpu.memory.rom.count {
        oam_scroll_state = (cpu.memory.rom.count - 16 * it) / 16;
            break;
        }
        im.TableNextColumn();
        im.Text_CFormat("0x%07x", (it + rom_scroll_state) * 16);
        for it2 : 0..15 {
            im.TableNextColumn();
            im.Text_CFormat("%02x", cpu.memory.rom[(it + rom_scroll_state) * 16 + it2]);
            if im.IsItemHovered() {
                im.SetTooltip("0x%", 0x08000000 + (it + rom_scroll_state) * 16 + it2);
            }
        }
    }
    im.EndTable();
    im.End();
}

#if #exists(__Iprof) {
    profiler_filter_selected : s32 = 0;
    profiler_window :: () {
        im.Begin("profiler");
        im.RadioButton("Filter None".data, *profiler_filter_selected, 0);
        im.RadioButton("Filter ARM Instructions".data, *profiler_filter_selected, 1);
        im.RadioButton("Filter THUMB Instructions".data, *profiler_filter_selected, 2);
        if report {
            if im.BeginTable("##reports", 5, .Borders | .RowBg | .SizingFixedFit) {
                im.TableSetupColumn(report.header[0].data);
                im.TableSetupColumn(report.header[1].data);
                im.TableSetupColumn(report.header[2].data);
                im.TableSetupColumn(report.header[3].data);
                im.TableSetupColumn("per iteration");
                im.TableHeadersRow();
                for report.*.records {
                    if profiler_filter_selected == 1 {
                        if !starts_with(it.name, "arm_") continue;
                    }
                    if profiler_filter_selected == 2 {
                        if !starts_with(it.name, "thumb_") continue;
                    }
                    if it.self_time < 0.00001 continue;
                    im.TableNextColumn();
                    im.Text("%", it.name);
                    im.TableNextColumn();
                    im.Text("%", it.self_time);
                    im.TableNextColumn();
                    im.Text("%", it.hier_time);
                    im.TableNextColumn();
                    im.Text("%", it.calls);
                    im.TableNextColumn();
                    im.Text("%", it.self_time / it.calls);
                    im.TableNextRow();
                }
                im.EndTable();
            }
        }
        im.End();
    }
}
