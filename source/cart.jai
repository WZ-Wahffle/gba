rom_read :: (addr: u32) -> u8 {
    if cpu.backup_type == {
        case .NONE;
        if addr < 0x0e000000 {
            return cpu.memory.rom[addr % cpu.memory.rom.count];
        }
        case .EEPROM;
            if addr >= 0x0d000000 && addr < 0x0e000000 {
                if addr % 2 == 1 then return 0;
                cpu.ee_read_idx += 1;
                if cpu.ee_read_idx > 4 && cpu.ee_read_idx <= 68 {
                    ret : u8 = xx (cpu.ee_read >> 63);
                    cpu.ee_read <<= 1;
                    return ret;
                } else {
                    return 1;
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
            to_write := (val & 1) != 0;
            if cpu.eeprom_size == .EEPROM_512B {
                log("write % 0x%\n", ifx to_write then 1 else 0, formatInt(cpu.reg[15], 16));
                if cpu.ee_state == {
                    case .NONE;
                        if to_write cpu.ee_state = .FIRST_BIT_READ;
                    case .FIRST_BIT_READ;
                        cpu.ee_state = ifx to_write then .READING else .WRITING;
                        cpu.ee_block_idx = 0;
                        cpu.ee_block = 0;
                    case .READING;
                        cpu.ee_block <<= 1;
                        cpu.ee_block |= xx to_write;
                        cpu.ee_block_idx += 1;
                        if cpu.ee_block_idx == 6 {
                            cpu.ee_state = .FINISHED;
                            cpu.ee_read = cpu.ee[cpu.ee_block];
                            cpu.ee_read_idx = 0;
                            log("Reading 0x% from 0x%\n", formatInt(cpu.ee_read, 16), formatInt(cpu.ee_block, 16));
                        }
                    case .WRITING;
                        cpu.ee_block <<= 1;
                        cpu.ee_block |= xx to_write;
                        cpu.ee_block_idx += 1;
                        if cpu.ee_block_idx == 6 {
                            cpu.ee_state = .WRITING_DATA;
                            cpu.ee_write = 0;
                            cpu.ee_write_idx = 0;
                        }
                    case .WRITING_DATA;
                        cpu.ee_write <<= 1;
                        cpu.ee_write |= xx to_write;
                        cpu.ee_write_idx += 1;
                        if cpu.ee_write_idx == 64 {
                            cpu.ee_state = .FINISHED;
                            cpu.ee[cpu.ee_block] = cpu.ee_write;
                            log("Writing 0x% to 0x%\n", formatInt(cpu.ee_write, 16), formatInt(cpu.ee_block, 16));
                        }
                    case .FINISHED;
                        cpu.ee_state = .NONE;
                }
            }
        }
    }
}
