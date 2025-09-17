Cpu :: struct {
    memory: Cpu_Mmu;
    gpr: [13]u32;
    sp: u32;
    lr: u32;
    pc: u32;
    psr: u32 = 0xb3;
    spsr: [#run enum_highest_value(Cpu_Mode)+1]u32;
    state := Cpu_State.ARM;
    mode := Cpu_Mode.SVC;

    interrupt_master_enable := false;

    emu_state := Emulation_State.STOPPED;
    remaining_cycles := 0;

    Cpu_State :: enum {
        THUMB;
        ARM;
    }

    Cpu_Mode :: enum s32 {
        USER :: -2;
        SYSTEM :: -1;
        IRQ :: 0;
        FIQ :: 1;
        SVC :: 2;
        ABT :: 3;
        UND :: 4;
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
