#import "Basic";//()(MEMORY_DEBUGGER=true);
#import "File";
#import "Thread";
#import "String";
#import "Math";

ImGui :: #import "ImGui";
#import "SDL";
#import "Math";
#import "GL";

cpu: Cpu;
ppu: Ppu;
apu: Apu;

main :: () {
    args := get_command_line_arguments();
    if args.count != 2 {
        exit(1);
    }
    cpu.cart_name = args[1];
    for * cpu.breakpoints_arm it.* = 0xffffffff;
    for * cpu.breakpoints_thumb it.* = 0xffff;
    for * cpu.ee it.* = 0xffffffffffffffff;
    for * cpu.flash it.* = 0xff;
    populate_arm_lut();
    populate_thumb_lut();
    context.logger = color_log;
    context.assertion_failed = dump_processor_state;
    rom := read_entire_file(args[1]);
    array_resize(*cpu.memory.rom, rom.count);
    memcpy(cpu.memory.rom.data, rom.data, cpu.memory.rom.count);
    game_title := string.{12, cpu.memory.rom.data + 0xa0};
    game_code := string.{4, cpu.memory.rom.data + 0xac};
    maker_code := string.{2, cpu.memory.rom.data + 0xb0};
    log("Game Title: %", game_title);
    log("Game Code: %", game_code);
    log("Maker Code: %", maker_code);
    log("Scanning for persistent storage...");
    rom_str := string.{rom.count, rom.data};
    if contains(rom_str, "EEPROM_V") {
        log("Identified EEPROM");
        cpu.backup_type = .EEPROM;
    } else if contains(rom_str, "SRAM_V") {
        log("Identified SRAM/FRAM");
        cpu.backup_type = .SRAM;
    } else if contains(rom_str, "FLASH_V") || contains(rom_str, "FLASH512_V") {
        log("Identified Flash Storage, 64KB");
        cpu.backup_type = .FLASH_64K;
    } else if contains(rom_str, "FLASH1M_V") {
        log("Identified Flash Storage, 128KB");
        cpu.backup_type = .FLASH_128K;
    } else {
        log("None identified\n");
    }
    bios, success := read_entire_file("in/gba_bios.bin");
    if !success || bios.count != cpu.memory.bios._8.count {
        log_error("BIOS file not found");
        exit(1);
    }

    memcpy(cpu.memory.bios._8.data, bios.data, cpu.memory.bios._8.count);

    ui();
}

dump_processor_state :: (loc: Source_Code_Location, message: string) -> bool {
    runtime_support_assertion_failed(loc, message);
    print("PC: 0x%\n", formatInt(cpu.reg[15], 16, 8));
    return true;
}

log_warn :: (format_string: string, args: .. Any, loc := #caller_location, flags := Log_Flags.NONE, user_flags: u32 = 0, section: *Log_Section = null) {
    new_flags := flags | .WARNING;
    log(format_string, ..args, loc, new_flags, user_flags, section);
}

#scope_file
color_log :: (message: string, data: *void, info: Log_Info) {
    if !message then return;

    to_standard_error := (info.common_flags & .ERROR) != 0;

    if (info.common_flags & .WARNING) != 0 then write_string("\e[0;33m", to_standard_error = to_standard_error);
    if (info.common_flags & .ERROR) != 0 then write_string("\e[0;31m", to_standard_error = to_standard_error);

    if (info.common_flags & .WARNING) | (info.common_flags & .ERROR) != 0 {
        write_string(info.location.fully_pathed_filename, to_standard_error = to_standard_error);
        write_string(":", to_standard_error = to_standard_error);
        write_string(tprint("%: ", formatInt(info.location.line_number, 10, 1)), to_standard_error = to_standard_error);
    }
    if message[message.count-1] != #char "\n" {
        write_strings(message, "\n", to_standard_error = to_standard_error);
    } else {
        write_string(message, to_standard_error = to_standard_error);
    }

    if to_standard_error {
        write_string("Stack Trace:\n");
        for get_stack_trace_strings() {
            print("%\n", it);
        }
        context.print_style.default_format_int.base = 16;
        context.print_style.default_format_int.minimum_digits = 8;
        print("Registers: %\n", cpu.reg);
        write_string("\e[0;37m");
        exit(1);
    }
}

#load "types.jai";
#load "cpu.jai";
#load "cpu-mmu.jai";
#load "cart.jai";
#load "arm.jai";
#load "thumb.jai";

#load "imgui_sdl_gl.jai";
#load "ui.jai";
#load "gui.jai";

#load "apu.jai";
