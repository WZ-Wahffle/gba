rom_read :: (addr: u32) -> u8 {
    if cpu.backup_type == {
        case .NONE;
        if addr < 0x0e000000 {
            return cpu.memory.rom[addr % cpu.memory.rom.count];
        }
        case .EEPROM;
            if addr >= 0x0d000000 && addr < 0x0e000000 {
                if cpu.ee_read_idx < 4 || cpu.ee_read_idx > 67 then return 1;
                else {
                    ret := cpu.ee[cpu.ee_block_idx] >> (cpu.ee_read_idx - 4);
                    cpu.ee_read_idx += 1;
                    return xx ret & 1;
                }
            } else if addr < 0x0e000000 {
                return cpu.memory.rom[addr % cpu.memory.rom.count];
            }
    }

    log_warn("Unmapped ROM read: 0x%", formatInt(addr, 16));
    return 0;
}

rom_write :: (addr: u32, val: u8) {
    if cpu.backup_type == {
        case .NONE;
        log_warn("Unmapped ROM write: 0x%, 0x%", formatInt(addr, 16), formatInt(val, 16));
        case .EEPROM;
        // TODO: Possibly different location for very large games?
        if addr >= 0x0d000000 && addr < 0x0e000000 && addr % 2 == 0 {
            if cpu.eeprom_size == .UNDECIDED {
                if cpu.dma[3].count == 9 {
                    cpu.eeprom_size = .EEPROM_512B;
                } else if cpu.dma[3].count == 17 {
                    cpu.eeprom_size = .EEPROM_8K;
                } else {
                    log_error("FIXME: Could not determine size of EEPROM!");
                }
            }
            cpu.ee_buffer[cpu.ee_buffer_idx] = (val & 1) != 0;
            cpu.ee_buffer_idx += 1;
            if cpu.eeprom_size == .EEPROM_512B {
                first_idx : u8 = cpu.ee_buffer_idx - 9;
                second_idx : u8 = cpu.ee_buffer_idx - 8;
                last_idx : u8 = cpu.ee_buffer_idx - 1;
                if cpu.ee_buffer[first_idx] && cpu.ee_buffer[second_idx] && !cpu.ee_buffer[last_idx] {
                    // read
                    ee_addr: u32 = 0;
                    for 0..5 {
                        ee_addr |= xx ifx cpu.ee_buffer[(second_idx + 1 + it) & 0xff] then 1 << (5 - it) else 0;
                    }
                    cpu.ee_block_idx = ee_addr;
                    cpu.ee_read_idx = 0;
                    for 0..9 cpu.ee_buffer[(first_idx + it) & 0xff] = false;
                }
            }
        }
    }
}
