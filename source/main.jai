#import "Basic";
#import "File";
#import "Thread";

cpu: Cpu;
ppu: Ppu;

main :: () {
    bios, success := read_entire_file("in/gba_bios.bin");
    if !success || bios.count != cpu.memory.bios.count {
        log_error("BIOS file not found\n");
        exit(1);
    }

    memcpy(cpu.memory.bios.data, bios.data, cpu.memory.bios.count);

    ui();
}
