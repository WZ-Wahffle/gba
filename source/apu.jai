step_apu :: () {
    if apu.remaining_cycles > 0 {
        apu.remaining_cycles -= 514.33592;
        advance_timers(512);
        channel_a_l : s16 = apu.fifo_a.out * xx apu.chan_a.enable_l * xx ((xx apu.chan_a.volume + 1) / 2.0);
        channel_b_l : s16 = apu.fifo_b.out * xx apu.chan_b.enable_l * xx ((xx apu.chan_b.volume + 1) / 2.0);
        result_l := xx apu.master_enable * channel_a_l * 64 + channel_b_l * 64;
        channel_a_r : s16 = apu.fifo_a.out * xx apu.chan_a.enable_r * xx ((xx apu.chan_a.volume + 1) / 2.0);
        channel_b_r : s16 = apu.fifo_b.out * xx apu.chan_b.enable_r * xx ((xx apu.chan_b.volume + 1) / 2.0);
        result_r := xx apu.master_enable * channel_a_r * 64 + channel_b_r * 64;
        // SDL_QueueAudio(apu.dev, *result_l, 2);
        // SDL_QueueAudio(apu.dev, *result_r, 2);
        apu.played_samples += 1;
    }
}
