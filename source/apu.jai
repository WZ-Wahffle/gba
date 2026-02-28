
voltbl := float.[0.5, 1.0];

step_apu :: () {
    if apu.remaining_cycles > 0 {
        apu.remaining_cycles -= 514.33593;

        a_out : s8 = apu.fifo_a.out;
        b_out : s8 = apu.fifo_b.out;

        channel_a_l := xx (a_out * (xx apu.chan_a.enable_l * voltbl[xx apu.chan_a.volume])) / 127.0;
        channel_b_l := xx (b_out * (xx apu.chan_b.enable_l * voltbl[xx apu.chan_b.volume])) / 127.0;
        result_l := xx apu.master_enable * (channel_a_l / 2.0 + channel_b_l / 2.0);
        channel_a_r := xx (a_out * (xx apu.chan_a.enable_r * voltbl[xx apu.chan_a.volume])) / 127.0;
        channel_b_r := xx (b_out * (xx apu.chan_b.enable_r * voltbl[xx apu.chan_b.volume])) / 127.0;
        result_r := xx apu.master_enable * (channel_a_r / 2.0 + channel_b_r / 2.0);

        SDL_QueueAudio(apu.dev, *result_l, 4);
        SDL_QueueAudio(apu.dev, *result_r, 4);
        apu.played_samples += 1;
    }
}
