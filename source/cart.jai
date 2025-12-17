rom_read :: (addr: u32) -> u8 {
    if cpu.backup_type == {
        case .FLASH_64K; #through;
        case .FLASH_128K;
            if addr < 0x0e000000 {
                return cpu.memory.rom[addr % cpu.memory.rom.count];
            } else {
                if cpu.flash_op_mode == .ID {
                    if addr == 0x0e000000 return 0x62;
                    if addr == 0x0e000001 return 0x13;
                } else
                return cpu.flash[cpu.flash_bank * 0x10000 + (addr & 0xffff)];
            }
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
        case .FLASH_64K;
        case .FLASH_128K;
        if addr >= 0x0e000000 {
            if cpu.flash_state == {
                case .NONE;
                    if cpu.flash_op_mode == .WRITE {
                        cpu.flash[cpu.flash_bank * 0x10000 + addr & 0xffff] = val;
                        cpu.flash_op_mode = .READ;
                    } else if cpu.flash_op_mode == .SWITCH_BANK && addr == 0x0e000000 {
                        cpu.flash_bank = val & 1;
                    } else
                    if addr == 0x0e005555 && val == 0xaa cpu.flash_state = .FIRST_CMD_BYTE_READ;
                case .FIRST_CMD_BYTE_READ;
                    if addr == 0x0e002aaa && val == 0x55 cpu.flash_state = .SECOND_CMD_BYTE_READ;
                case .SECOND_CMD_BYTE_READ;
                    if val == {
                        case 0x10;
                        if addr == 0x0e005555 && cpu.flash_op_mode == .ERASE {
                            for 0..0xffff {
                                cpu.flash[cpu.flash_bank * 0x10000 + it] = 0xff;
                            }
                            cpu.flash_op_mode = .READ;
                        }
                        case 0x30;
                        if addr & 0xffff0fff == 0x0e000000 && cpu.flash_op_mode == .ERASE {
                            sector := (addr >> 12) & 0xf;
                            for 0..0xfff {
                                cpu.flash[cpu.flash_bank * 0x10000 + sector * 0x1000 + it] = 0xff;
                            }
                        }
                        case 0x80;
                        if addr == 0x0e005555 then cpu.flash_op_mode = .ERASE;
                        case 0x90;
                        if addr == 0x0e005555 then cpu.flash_op_mode = .ID;
                        case 0xa0;
                        if addr == 0x0e005555 then cpu.flash_op_mode = .WRITE;
                        case 0xb0;
                        if addr == 0x0e005555 then cpu.flash_op_mode = .SWITCH_BANK;
                        case 0xf0;
                        if addr == 0x0e005555 && cpu.flash_op_mode == .ID then cpu.flash_op_mode = .READ;
                    }
                    cpu.flash_state = .NONE;
            }
        }
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
                    if cpu.ee_block_idx == ifx cpu.eeprom_size == .EEPROM_512B then 6 else 14 {
                        cpu.ee_state = .FINISHED;
                        cpu.ee_read = cpu.ee[cpu.ee_block];
                        cpu.ee_read_idx = 0;
                    }
                case .WRITING;
                    cpu.ee_block <<= 1;
                    cpu.ee_block |= xx to_write;
                    cpu.ee_block_idx += 1;
                    if cpu.ee_block_idx == ifx cpu.eeprom_size == .EEPROM_512B then 6 else 14 {
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
                    }
                case .FINISHED;
                    cpu.ee_state = .NONE;
            }
        }
    }
}
