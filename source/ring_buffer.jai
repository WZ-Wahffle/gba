ring_buffer_write :: (using this: *Ring_Buffer, value: this.type) {
    if cnt < size {
        data[w] = value;
        w += 1;
        cnt += 1;
        w %= size;
    } else {
        overflows += 1;
        // print("aaaa\n");
    }

    // if size == 32 print("Write % %\n", w, cnt);
}

ring_buffer_read :: (using this: *Ring_Buffer) -> this.type {
    ret := data[r];
    if cnt > 0 {
        r += 1;
        cnt -= 1;
        r %= size;
    }
    // if size == 32 print("Read % %\n", r, cnt);

    return ret;
}
