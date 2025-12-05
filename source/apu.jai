apu_callback :: (_: *void, buffer: *u8, size: s32) #c_call {
    if cpu.emu_state != .RUNNING return;
    // TODO: GB audio channels
    push_context {
        for 0..size-1 {
            advance_timers(512);
            channel_a : s8 = cast,no_check(s8)apu.fifo_a.buffer[apu.fifo_a.r];
            channel_b : s8 = cast,no_check(s8)apu.fifo_b.buffer[apu.fifo_b.r];
            // buffer[it] = cast,no_check(u8)((channel_a / 8) + (channel_b / 8));
        }
    }
}
