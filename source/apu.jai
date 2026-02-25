step_apu :: () {
    if apu.remaining_cycles > 0 {
        apu.remaining_cycles -= 514.33592;
        advance_timers(512);
        // a_factor := ((apu.total_cycles - xx apu.remaining_cycles) - apu.fifo_a.time_out) / cast(float, apu.fifo_a.time_out - apu.fifo_a.time_prev_out);
        // b_factor := ((apu.total_cycles - xx apu.remaining_cycles) - apu.fifo_b.time_out) / cast(float, apu.fifo_b.time_out - apu.fifo_b.time_prev_out);
        // a_out_raw : int = xx (a_factor * apu.fifo_a.prev_out + (1 - a_factor) * apu.fifo_a.out);
        // b_out_raw : int = xx (b_factor * apu.fifo_b.prev_out + (1 - b_factor) * apu.fifo_b.out);
        // a_out : s8 = ifx is_finite(a_factor) cast(s8, a_out_raw) else 0;
        // b_out : s8 = ifx is_finite(b_factor) cast(s8, b_out_raw) else 0;
        a_out : s8 = apu.fifo_a.out;
        b_out : s8 = apu.fifo_b.out;
        // b_out : s8 = a_out;

        channel_a_l : s16 = a_out * xx apu.chan_a.enable_l * xx ((xx apu.chan_a.volume + 1) / 2.0);
        channel_b_l : s16 = b_out * xx apu.chan_b.enable_l * xx ((xx apu.chan_b.volume + 1) / 2.0);
        result_l := xx apu.master_enable * (channel_a_l * 64 + channel_b_l * 64);
        channel_a_r : s16 = a_out * xx apu.chan_a.enable_r * xx ((xx apu.chan_a.volume + 1) / 2.0);
        channel_b_r : s16 = b_out * xx apu.chan_b.enable_r * xx ((xx apu.chan_b.volume + 1) / 2.0);
        result_r := xx apu.master_enable * (channel_a_r * 64 + channel_b_r * 64);
        SDL_QueueAudio(apu.dev, *result_l, 2);
        SDL_QueueAudio(apu.dev, *result_r, 2);
        apu.played_samples += 1;
    }
}
