Cpu :: struct {
    memory: Cpu_Mmu;
    gpr: [13]u32;
    sp: u32;
    lr: u32;
    pc: u32;
    psr: u32;
    spsr: [#run enum_highest_value(Cpu_Mode)]u32;
    state := Cpu_State.ARM;
    mode := Cpu_Mode.USER;
    emu_state := Emulation_State.STOPPED;
    remaining_cycles := 0;

    Cpu_State :: enum {
        THUMB;
        ARM;
    }

    Cpu_Mode :: enum {
        USER;
        SYSTEM;
        IRQ;
        FIQ;
        SVC;
        ABT;
        UND;
    }

    Emulation_State :: enum {
        RUNNING;
        STOPPED;
    }
}

Cpu_Mmu :: struct {
    bios: [0x4000]u8;
    ewram: [0x40000]u8;
    iwram: [0x8000]u8;
    rom: [..]u8;
}

Ppu :: struct {
    palette_ram: [0x400]u8;
    vram: [0x18000]u8;
    oam: [0x400]u8;

    draw_x := 0;
    draw_y := 0;
}

Status_Bit :: enum {
    N;
    Z;
    C;
    V;
}
