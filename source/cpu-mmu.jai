mmu_read :: (addr: u32, execute := false) -> u8 {
    if addr >= 0x08000000 && addr < 0x0e000000 {
        return cpu.memory.rom[addr % cpu.memory.rom.count];
    }

    else if addr < 0x4000 && execute {
        return cpu.memory.bios[addr];
    }

    else if addr >= 0x02000000 && addr < 0x03000000 {
        return cpu.memory.ewram[addr % 0x40000];
    }

    else if addr >= 0x03000000 && addr < 0x04000000 {
        return cpu.memory.iwram[addr % 0x8000];
    }

    else if addr >= 0x04000000 && addr < 0x04000400 {
        if addr - 0x04000000 == {
            case 0x300;
            return 0;
            case;
            assert(false);
        }
    }

    else if addr >= 0x05000000 && addr < 0x06000000 {
        return ppu.palette_ram[addr % 0x400];
    }

    else if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            return ppu.vram[addr % 0x18000];
        } else {
            return ppu.vram[(addr % 0x8000) + 0x10000];
        }
    }

    else if addr >= 0x07000000 && addr < 0x08000000 {
        return ppu.oam[addr % 0x400];
    }

    else {
        print("%\n", addr);
        assert(false);
    }
    return 0;
}

mmu_write :: (addr: u32, val: u8) {
    if addr >= 0x02000000 && addr < 0x03000000 {
        cpu.memory.ewram[addr % 0x40000] = val;
    }

    else if addr >= 0x03000000 && addr < 0x04000000 {
        cpu.memory.iwram[addr % 0x8000] = val;
    }

    else if addr >= 0x04000000 && addr < 0x04000400 {
        if addr - 0x04000000 == {
            case 0x208;
                cpu.interrupt_master_enable = (val & 1) != 0;
            case;
            assert(false);
        }
    }

    else if addr >= 0x05000000 && addr < 0x06000000 {
        ppu.palette_ram[addr % 0x400] = val;
    }

    else if addr >= 0x06000000 && addr < 0x07000000 {
        if addr % 0x20000 < 0x18000 {
            ppu.vram[addr % 0x18000] = val;
        } else {
            ppu.vram[(addr % 0x8000) + 0x10000] = val;
        }
    }

    else if addr >= 0x07000000 && addr < 0x08000000 {
        ppu.oam[addr % 0x400] = val;
    }

    else assert(false);
}
