apu_callback :: (_: *void, buffer: *u8, size: s32) #c_call {
    buf : *s16 = xx buffer;
    sz := size / 2;
    first_buffer: [CALLBACK_SIZE]s16;

    if cpu.emu_state != .RUNNING {
        for 0..sz-1 {
            buf[it] = 0;
        }
        return;
    }
    // TODO: GB audio channels

    push_context {
        assert(sz == CALLBACK_SIZE);
        for 0..sz-1 {
            advance_timers(512);
            // print("%/%: playing % at index %, buffer: %\n", it, size, apu.fifo_a.buffer[apu.fifo_a.r & 0x1f], apu.fifo_a.r & 0x1f, apu.fifo_a.buffer);
            channel_a : s16 = apu.fifo_a.out;
            result := channel_a * 256;
            // buf[it] = result;
        }
    }
}
