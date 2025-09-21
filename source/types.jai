Cpu :: struct {
    memory: Cpu_Mmu;
    gpr: [13]u32;
    gpr_hi_fiq: [5]u32;
    sp: [#run enum_highest_value(Cpu_Mode)+1]u32;
    lr: [#run enum_highest_value(Cpu_Mode)+1]u32;
    pc: u32;
    psr: u32 = 0xb3;
    spsr: [#run enum_highest_value(Cpu_Mode)+1]u32;
    state := Cpu_State.ARM;
    mode := Cpu_Mode.SVC;
    privileged := true;

    interrupt_master_enable := false;

    emu_state := Emulation_State.STOPPED;
    remaining_cycles := 0;
    breakpoints: [..]u32;

    Cpu_State :: enum {
        THUMB;
        ARM;
    }

    Cpu_Mode :: enum s32 {
        USER :: 0;
        SYSTEM :: 0;
        IRQ :: 1;
        FIQ :: 2;
        SVC :: 3;
        ABT :: 4;
        UND :: 5;
    }

    Emulation_State :: enum {
        RUNNING;
        STOPPED;
        STEPPED;
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

    remaining_cycles := 0;
}

Status_Bit :: enum {
    N;
    Z;
    C;
    V;
}
