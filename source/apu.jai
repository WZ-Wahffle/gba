apu_callback :: (_: *void, buffer: *u8, size: s32) #c_call {
    // TODO: GB audio channels
    for 0..size-1 {
        buffer[it] = apu.fifo_b.buffer._8[apu.fifo_b.r];
    }
}
