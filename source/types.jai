Cpu :: struct {
    memory: Cpu_Mmu;
    gpr: [13]u32;
    sp: u32;
    lr: u32;
    pc: u32;
    psr: u32;
    state: Cpu_State;

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
}

Cpu_Mmu :: struct {
    bios: [0x4000]u8;
    ewram: [0x40000]u8;
    iwram: [0x8000]u8;
    rom: [..]u8;
}
