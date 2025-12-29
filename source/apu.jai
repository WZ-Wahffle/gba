step_apu :: () {
    if apu.remaining_cycles > 0 {
        apu.remaining_cycles -= 514.33592;
        advance_timers(512);
        channel_a : s16 = apu.fifo_a.out;
        result := channel_a * 128;
        apu.prev_3 = apu.prev_2;
        apu.prev_2 = apu.prev;
        apu.prev = channel_a;
        SDL_QueueAudio(apu.dev, *result, 2);
        apu.played_samples += 1;
    }
}
