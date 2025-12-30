SCREEN_WIDTH :: 240;
SCREEN_HEIGHT :: 160;
FONT_SIZE :: 26;
BLANK_COLOR :: 0x8000;

SAMPLE_RATE :: 32768;
CALLBACK_SIZE :: 512;
window_width : s32 = SCREEN_WIDTH * 6;
window_height : s32 = SCREEN_HEIGHT * 6;
framebuffer: [SCREEN_WIDTH * SCREEN_HEIGHT]u16;

bg_line_buffer: [4][SCREEN_WIDTH]u16;

obj_line_buffer: [SCREEN_WIDTH]u16;
obj_prio_buffer: [SCREEN_WIDTH]u8;
obj_win_buffer: [SCREEN_WIDTH]bool;
obj_use_alpha_buffer: [SCREEN_WIDTH]bool;

// priorities: (the lower, the higher)
// backdrop: 8
// OBJ: priority * 2
// BG: priority * 2 + 1

draw_bg :: (y: int, bg: u32, rotation_mode: bool) {
    if !ppu.bg[bg].enable then return;
    if rotation_mode {
        line_size_px := 128 * (ifx ppu.bg[bg].wide then 2 else 1) * (ifx ppu.bg[bg].tall then 4 else 1);

        pixel_buffer: [240]u16;
        a := ppu.bg[bg].pa;
        b := ppu.bg[bg].pb;
        c := ppu.bg[bg].pc;
        d := ppu.bg[bg].pd;
        line_size_tiles := line_size_px / 8;
        base_addr := ppu.bg[bg].screen_base_block * 2048;

        ppu.bg[bg].transform_x = ppu.bg[bg].anchor_x_l;
        ppu.bg[bg].transform_y = ppu.bg[bg].anchor_y_l;
        ppu.bg[bg].anchor_x_l += b;
        ppu.bg[bg].anchor_y_l += d;

        for x: 0..239 {
            x_1: int = xx ppu.bg[bg].transform_x;
            y_1: int = xx ppu.bg[bg].transform_y;
            pixel_buffer[x] = BLANK_COLOR;

            ppu.bg[bg].transform_x += a;
            ppu.bg[bg].transform_y += c;

            if ppu.bg[bg].wraparound {
                while x_1 < 0 x_1 += line_size_px;
                while y_1 < 0 y_1 += line_size_px;
                while x_1 >= line_size_px x_1 -= line_size_px;
                while y_1 >= line_size_px y_1 -= line_size_px;
            } else if x_1 < 0 || x_1 >= line_size_px || y_1 < 0 || y_1 >= line_size_px {
                continue;
            }

            if ppu.bg[bg].mosaic {
                x_1 -= x_1 % (ppu.bg_mosaic_h + 1);
                y_1 -= y_1 % (ppu.bg_mosaic_v + 1);
            }
            tile_idx_idx := base_addr + (y_1 / 8) * line_size_tiles + (x_1 / 8);

            tile_idx : int = ppu.memory.vram._8[tile_idx_idx];
            pixel_idx := (y_1 % 8) * 8 + (x_1 % 8);
            pixel_palette_idx := ppu.memory.vram._8[ppu.bg[bg].char_base_block * 16384 + tile_idx * 64 + pixel_idx];
            if pixel_palette_idx != 0 {
                pixel_buffer[x] = ppu.memory.palette_ram._16[pixel_palette_idx] & 0x7fff;
            } else {
                pixel_buffer[x] = BLANK_COLOR;
            }
        }

        for 0..239 {
            if pixel_buffer[it] != BLANK_COLOR {
                bg_line_buffer[bg][it] = pixel_buffer[it];
            }
        }
    } else {
        line_size_px := 256 * ifx ppu.bg[bg].wide then 2 else 1;
        y_pos : int = xx ppu.bg[bg].y_off + y;
        y_pos %= 256 * ifx ppu.bg[bg].tall then 2 else 1;
        if ppu.bg[bg].mosaic {
            y_pos -= y_pos % (ppu.bg_mosaic_v + 1);
        }
        line_size_tiles := line_size_px / 8;
        base_addr := ppu.bg[bg].screen_base_block * 2048;
        if ppu.bg[bg].wide then base_addr += ((y_pos / 8) / 32) * 0x800;
        base_addr += ((y_pos / 8)) * 64;
        Text_Tile_Attr :: struct {
            idx := 0;
            flip_h := false;
            flip_v := false;
            palette := 0;
        }
        tile_address_buffer: [64]Text_Tile_Attr;
        for 0..line_size_tiles-1 {
            val := ppu.memory.vram._16[(base_addr >> 1) + (it / 32) * 0x400 + (it % 32)];
            tile_address_buffer[it].idx = val & 0x3ff;
            tile_address_buffer[it].flip_h = val & 0x400 != 0;
            tile_address_buffer[it].flip_v = val & 0x800 != 0;
            tile_address_buffer[it].palette = val >> 12;
        }
        pixel_buffer: [512]u16;
        if ppu.bg[bg].single_palette {
            for tile_idx: 0..line_size_tiles-1 {
                tile_base_addr := ppu.bg[bg].char_base_block * 16384 + tile_address_buffer[tile_idx].idx * 64;
                y_pos_src := ifx tile_address_buffer[tile_idx].flip_v then (7 - (y_pos % 8)) else y_pos % 8;
                tile_base_addr += 8 * y_pos_src;
                for pixel_idx: 0..7 {
                    pixel_idx_src := ifx tile_address_buffer[tile_idx].flip_h then (7 - pixel_idx) else pixel_idx;
                    palette_idx := ppu.memory.vram._8[tile_base_addr + pixel_idx_src];
                    if palette_idx == 0 {
                        pixel_buffer[8 * tile_idx + pixel_idx] = BLANK_COLOR;
                    } else {
                        pixel_buffer[8 * tile_idx + pixel_idx] = ppu.memory.palette_ram._16[palette_idx] & 0x7fff;
                    }
                }
            }
        } else {
            for tile_idx: 0..line_size_tiles-1 {
                tile_base_addr := ppu.bg[bg].char_base_block * 16384 + tile_address_buffer[tile_idx].idx * 32;
                y_pos_src := ifx tile_address_buffer[tile_idx].flip_v then (7 - (y_pos % 8)) else y_pos % 8;
                tile_base_addr += 4 * y_pos_src;
                for pixel_idx: 0..7 {
                    pixel_idx_src := ifx tile_address_buffer[tile_idx].flip_h then (7 - pixel_idx) else pixel_idx;
                    palette_idx := ppu.memory.vram._8[tile_base_addr + (pixel_idx_src >> 1)];
                    palette_idx = ifx (pixel_idx_src & 1) == 0 then palette_idx & 0xf else palette_idx >> 4;
                    if palette_idx == 0 {
                        pixel_buffer[8 * tile_idx + pixel_idx] = BLANK_COLOR;
                    } else {
                        pixel_buffer[8 * tile_idx + pixel_idx] = ppu.memory.palette_ram._16[16 * tile_address_buffer[tile_idx].palette + palette_idx] & 0x7fff;
                    }
                }
            }
        }

        for 0..239 {
            x_pos : int = xx (it + ppu.bg[bg].x_off);
            x_pos %= 256 * ifx ppu.bg[bg].wide then 2 else 1;
            x_pos_src := x_pos;
            if ppu.bg[bg].mosaic {
                x_pos_src -= x_pos_src % (ppu.bg_mosaic_h + 1);
            }
            if pixel_buffer[x_pos] != BLANK_COLOR {
                bg_line_buffer[bg][it] = pixel_buffer[x_pos_src];
            }
        }
    }
}

draw_bitmap :: (y: u32) {
    if !ppu.bg[2].enable then return;
    line_width_px := 240;
    line_height_px := 160;

    pixel_buffer: [240]u16;
    a := ppu.bg[2].pa;
    b := ppu.bg[2].pb;
    c := ppu.bg[2].pc;
    d := ppu.bg[2].pd;
    base_addr := ifx ppu.display_frame_select then 0xa000 else 0;

    ppu.bg[2].transform_x = ppu.bg[2].anchor_x_l;
    ppu.bg[2].transform_y = ppu.bg[2].anchor_y_l;
    ppu.bg[2].anchor_x_l += b;
    ppu.bg[2].anchor_y_l += d;

    for x: 0..239 {
        x_1: int = xx ppu.bg[2].transform_x;
        y_1: int = xx ppu.bg[2].transform_y;
        pixel_buffer[x] = BLANK_COLOR;

        ppu.bg[2].transform_x += a;
        ppu.bg[2].transform_y += c;

        if ppu.bg[2].wraparound {
            while x_1 < 0 x_1 += line_width_px;
            while y_1 < 0 y_1 += line_height_px;
            while x_1 >= line_width_px x_1 -= line_width_px;
            while y_1 >= line_height_px y_1 -= line_height_px;
        } else if x_1 < 0 || x_1 >= line_width_px || y_1 < 0 || y_1 >= line_height_px {
            continue;
        }

        if ppu.bg[2].mosaic {
            x_1 -= x_1 % (ppu.bg_mosaic_h + 1);
            y_1 -= y_1 % (ppu.bg_mosaic_v + 1);
        }

        color := ppu.memory.vram._8[base_addr + 0xf0 * y_1 + x_1];
        if color != 0 {
            pixel_buffer[x] = ppu.memory.palette_ram._16[color] & 0x7fff;
        } else {
            pixel_buffer[x] = BLANK_COLOR;
        }
    }

    for 0..239 {
        if pixel_buffer[it] != BLANK_COLOR {
            bg_line_buffer[2][it] = pixel_buffer[it];
        }
    }
}

draw_obj :: (y: u32) {
    if ppu.obj_enable {
        base_addr := 0x10000;
        packed := ppu.obj_character_vram_mapping_one_dimensional;
        for ppu.oam {
            if it.bounding_box_min_y <= y && it.bounding_box_max_y > y {
                if it.rotate_scale {
                    pixel_buffer: [240]u16;
                    a := ppu.oam_param[it.rotate_scale_param_idx].pa;
                    b := ppu.oam_param[it.rotate_scale_param_idx].pb;
                    c := ppu.oam_param[it.rotate_scale_param_idx].pc;
                    d := ppu.oam_param[it.rotate_scale_param_idx].pd;
                    w := it.max_x - it.min_x;
                    h := it.max_y - it.min_y;
                    x_0 := (it.min_x + it.max_x) / 2;
                    y_0 := (it.min_y + it.max_y) / 2;
                    sprite_x : float = xx x_0;
                    sprite_y : float = xx y_0;
                    sprite_x -= x_0 * a;
                    sprite_x += (y - y_0) * b;
                    sprite_y -= x_0 * c;
                    sprite_y += (y - y_0) * d;
                    if it.rotate_scale_double_size {
                        sprite_x -= a * (w / 2);
                        sprite_x -= b * (h / 2);
                        sprite_y -= c * (w / 2);
                        sprite_y -= d * (h / 2);
                    }
                    obj_base := base_addr + it.tile_idx * 32;
                    for x: 0..239 {
                        x_1: int = xx sprite_x;
                        y_1: int = xx sprite_y;
                        pixel_buffer[x] = BLANK_COLOR;
                        if it.mosaic {
                            x_1 -= x_1 % (ppu.obj_mosaic_h + 1);
                            y_1 -= y_1 % (ppu.obj_mosaic_v + 1);
                        }

                        sprite_x += a;
                        sprite_y += c;
                        if x_1 < it.min_x || x_1 >= it.max_x || y_1 < it.min_y || y_1 >= it.max_y then continue;
                        if x < it.bounding_box_min_x || x >= it.bounding_box_max_x || y < it.bounding_box_min_y || y >= it.bounding_box_max_y then continue;

                        if it.single_palette {
                            tile_line_base := obj_base + ((y_1 - it.min_y) / 8) * ifx packed then (64 * (w / 8)) else (32 * 32);
                            tile_base := tile_line_base + ((x_1 - it.min_x) / 8) * 64;
                            line_base := tile_base + ((y_1 - it.min_y) % 8) * 8;
                            color_idx := ppu.memory.vram._8[line_base + ((x_1 - it.min_x) % 8)];
                            if color_idx == 0 {
                                pixel_buffer[x] = BLANK_COLOR;
                            } else {
                                pixel_buffer[x] = ppu.memory.palette_ram._16[0x100 + color_idx] & 0x7fff;
                            }
                        } else {
                            tile_line_base := obj_base + ((y_1 - it.min_y) / 8) * ifx packed then (32 * (w / 8)) else (32 * 32);
                            tile_base := tile_line_base + ((x_1 - it.min_x) / 8) * 32;
                            line_base := tile_base + ((y_1 - it.min_y) % 8) * 4;
                            color_idx := ppu.memory.vram._8[line_base + ((x_1 - it.min_x) % 8) / 2];
                            if ((x_1 - it.min_x) % 2) == 0 {
                                color_idx &= 0xf;
                            } else {
                                color_idx >>= 4;
                            }
                            if color_idx == 0 {
                                pixel_buffer[x] = BLANK_COLOR;
                            } else {
                                pixel_buffer[x] = ppu.memory.palette_ram._16[0x100 + it.palette * 0x10 + color_idx] & 0x7fff;
                            }
                        }
                    }
                    objwin := it.mode == 0b10;
                    objalpha := it.mode == 0b01;
                    for x_dst: 0..239 {
                        if pixel_buffer[x_dst] != BLANK_COLOR {
                            if objwin {
                                obj_win_buffer[x_dst] = true;
                            } else {
                                if obj_prio_buffer[x_dst] > it.prio * 2 {
                                    obj_prio_buffer[x_dst] = xx (it.prio * 2);
                                    obj_line_buffer[x_dst] = pixel_buffer[x_dst];
                                    obj_use_alpha_buffer[x_dst] = objalpha;
                                }
                            }
                        }
                    }
                } else {
                    if it.rotate_scale_double_size then continue;
                    obj_base := base_addr + it.tile_idx * 32;
                    w := it.max_x - it.min_x;
                    h := it.max_y - it.min_y;
                    y_obj := y - it.min_y;
                    if it.flip_v then y_obj = h - y_obj - 1;
                    if it.mosaic {
                        y_obj -= xx (y_obj % (ppu.obj_mosaic_v + 1));
                    }
                    vertical_offset_into_tile := (y_obj % 8);
                    x := it.min_x;
                    prio := it.prio;
                    objwin := it.mode == 0b10;
                    objalpha := it.mode == 0b01;
                    if it.single_palette {
                        obj_base += (y_obj / 8) * ifx packed then (64 * (w / 8)) else (32 * 32);
                        // single palette, so tiles are 64 bytes each
                        // thus, a single line sliver of a tile is 8 bytes, or one u64
                        pixel_buffer: [8]u64;
                        for coarse_x: 0..(w / 8)-1 {
                            pixel_buffer[coarse_x] = ppu.memory.vram._64[(obj_base >> 3) + 8 * coarse_x + vertical_offset_into_tile];
                        }
                        for obj_x: 0..w-1 {
                            obj_x_adj := obj_x;
                            if it.flip_h then obj_x_adj = w - obj_x_adj - 1;
                            if it.mosaic {
                                obj_x_adj -= obj_x_adj % (ppu.obj_mosaic_h + 1);
                            }
                            pixel_color := (pixel_buffer[obj_x_adj / 8] >> (8 * (obj_x_adj % 8))) & 0xff;
                            if pixel_color != 0 {
                                if objwin {
                                    obj_win_buffer[x + obj_x] = true;
                                } else {
                                    if obj_prio_buffer[x + obj_x] > prio * 2 {
                                        obj_line_buffer[x + obj_x] = ppu.memory.palette_ram._16[0x100 + pixel_color] & 0x7fff;
                                        obj_prio_buffer[x + obj_x] = xx (prio * 2);
                                        obj_use_alpha_buffer[x + obj_x] = objalpha;
                                    }
                                }
                            }
                        }
                    } else {
                        obj_base += (y_obj / 8) * ifx packed then (32 * (w / 8)) else (32 * 32);
                        pixel_buffer: [8]u32;
                        for coarse_x: 0..(w / 8)-1 {
                            pixel_buffer[coarse_x] = ppu.memory.vram._32[(obj_base >> 2) + 8 * coarse_x + vertical_offset_into_tile];
                        }
                        for obj_x: 0..w-1 {
                            if x + obj_x < 0 then continue;
                            if x + obj_x > SCREEN_WIDTH-1 then break;
                            obj_x_adj := obj_x;
                            if it.flip_h then obj_x_adj = w - obj_x_adj - 1;
                            if it.mosaic {
                                obj_x_adj -= obj_x_adj % (ppu.obj_mosaic_h + 1);
                            }
                            pixel_color := (pixel_buffer[obj_x_adj / 8] >> (4 * (obj_x_adj % 8))) & 0xf;
                            if pixel_color != 0 {
                                if objwin {
                                    obj_win_buffer[x + obj_x] = true;
                                } else {
                                    if obj_prio_buffer[x + obj_x] > prio * 2 {
                                        obj_line_buffer[x + obj_x] = ppu.memory.palette_ram._16[0x100 + it.palette * 16 + pixel_color] & 0x7fff;
                                        obj_prio_buffer[x + obj_x] = xx (prio * 2);
                                        obj_use_alpha_buffer[x + obj_x] = objalpha;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

merge_and_blend :: () {
    win_1_in_y := ppu.win[0].min_y <= ppu.draw_y && ppu.win[0].max_y > ppu.draw_y;
    win_2_in_y := ppu.win[1].min_y <= ppu.draw_y && ppu.win[1].max_y > ppu.draw_y;
    for x: 0..239 {
        win_1_in := win_1_in_y && ppu.win[0].min_x <= x && ppu.win[0].max_x > x;
        win_2_in := win_2_in_y && ppu.win[1].min_x <= x && ppu.win[1].max_x > x;
        win_obj_in := obj_win_buffer[x];
        out_pixels := u16.[BLANK_COLOR, BLANK_COLOR];
        out_pixel_prios := int.[9, 9];
        out_indices := int.[-1, -1];
        out_use_special := bool.[false, false];
        backdrop := ppu.memory.palette_ram._16[0];
        for out_pixel_idx: 0..1 {
            for bg_idx : 0..3 {
                if ppu.bg[bg_idx].enable && ppu.bg[bg_idx].prio * 2 + 1 < out_pixel_prios[out_pixel_idx] && bg_line_buffer[bg_idx][x] != BLANK_COLOR {
                    if ppu.win[0].enable && win_1_in {
                        if ppu.win[0].bg_enable[bg_idx] {
                            out_pixels[out_pixel_idx] = bg_line_buffer[bg_idx][x];
                            out_pixel_prios[out_pixel_idx] = ppu.bg[bg_idx].prio * 2 + 1;
                            out_indices[out_pixel_idx] = bg_idx;
                            out_use_special[out_pixel_idx] = ppu.win[0].special_effect;
                        }
                    } else if ppu.win[1].enable && win_2_in {
                        if ppu.win[1].bg_enable[bg_idx] {
                            out_pixels[out_pixel_idx] = bg_line_buffer[bg_idx][x];
                            out_pixel_prios[out_pixel_idx] = ppu.bg[bg_idx].prio * 2 + 1;
                            out_indices[out_pixel_idx] = bg_idx;
                            out_use_special[out_pixel_idx] = ppu.win[1].special_effect;
                        }
                    } else if ppu.obj_win.enable && win_obj_in {
                        if ppu.obj_win.bg_enable[bg_idx] {
                            out_pixels[out_pixel_idx] = bg_line_buffer[bg_idx][x];
                            out_pixel_prios[out_pixel_idx] = ppu.bg[bg_idx].prio * 2 + 1;
                            out_indices[out_pixel_idx] = bg_idx;
                            out_use_special[out_pixel_idx] = ppu.obj_win.special_effect;
                        }
                    } else if ppu.win[0].enable || ppu.win[1].enable || ppu.obj_win.enable {
                        if ppu.outside_win_bg_enable[bg_idx] {
                            out_pixels[out_pixel_idx] = bg_line_buffer[bg_idx][x];
                            out_pixel_prios[out_pixel_idx] = ppu.bg[bg_idx].prio * 2 + 1;
                            out_indices[out_pixel_idx] = bg_idx;
                            out_use_special[out_pixel_idx] = ppu.outside_win_special_effect;
                        }
                    } else {
                        out_pixels[out_pixel_idx] = bg_line_buffer[bg_idx][x];
                        out_pixel_prios[out_pixel_idx] = ppu.bg[bg_idx].prio * 2 + 1;
                        out_indices[out_pixel_idx] = bg_idx;
                        out_use_special[out_pixel_idx] = ppu.special_effect != 0;
                    }
                }
            }

            if ppu.obj_enable && obj_prio_buffer[x] < out_pixel_prios[out_pixel_idx] && obj_line_buffer[x] != BLANK_COLOR {
                if ppu.win[0].enable && win_1_in {
                    if ppu.win[0].obj_enable {
                        out_pixels[out_pixel_idx] = obj_line_buffer[x];
                        out_pixel_prios[out_pixel_idx] = obj_prio_buffer[x];
                        out_indices[out_pixel_idx] = 4;
                        out_use_special[out_pixel_idx] = ppu.win[0].special_effect;
                    }
                } else if ppu.win[1].enable && win_2_in {
                    if ppu.win[1].obj_enable {
                        out_pixels[out_pixel_idx] = obj_line_buffer[x];
                        out_pixel_prios[out_pixel_idx] = obj_prio_buffer[x];
                        out_indices[out_pixel_idx] = 4;
                        out_use_special[out_pixel_idx] = ppu.win[1].special_effect;
                    }
                } else if ppu.obj_win.enable && win_obj_in {
                    if ppu.obj_win.obj_enable {
                        out_pixels[out_pixel_idx] = obj_line_buffer[x];
                        out_pixel_prios[out_pixel_idx] = obj_prio_buffer[x];
                        out_indices[out_pixel_idx] = 4;
                        out_use_special[out_pixel_idx] = ppu.obj_win.special_effect;
                    }
                } else if ppu.win[0].enable || ppu.win[1].enable || ppu.obj_win.enable {
                    if ppu.outside_win_obj_enable {
                        out_pixels[out_pixel_idx] = obj_line_buffer[x];
                        out_pixel_prios[out_pixel_idx] = obj_prio_buffer[x];
                        out_indices[out_pixel_idx] = 4;
                        out_use_special[out_pixel_idx] = ppu.outside_win_special_effect;
                    }
                } else {
                    out_pixels[out_pixel_idx] = obj_line_buffer[x];
                    out_pixel_prios[out_pixel_idx] = obj_prio_buffer[x];
                    out_indices[out_pixel_idx] = 4;
                    out_use_special[out_pixel_idx] = ppu.special_effect != 0 || obj_use_alpha_buffer[x];
                }
            }

            if out_pixel_prios[out_pixel_idx] > 8 {
                out_pixels[out_pixel_idx] = backdrop;
                out_pixel_prios[out_pixel_idx] = 8;
                out_indices[out_pixel_idx] = 5;
                // assumption: backdrop is always enabled for both windows
                if ppu.win[0].enable && win_1_in {
                    out_use_special[out_pixel_idx] = ppu.win[0].special_effect;
                } else if ppu.win[1].enable && win_2_in {
                    out_use_special[out_pixel_idx] = ppu.win[1].special_effect;
                } else if ppu.obj_win.enable && obj_win_buffer[x] {
                    out_use_special[out_pixel_idx] = ppu.obj_win.special_effect;
                } else if ppu.win[0].enable || ppu.win[1].enable || ppu.obj_win.enable {
                    out_use_special[out_pixel_idx] = ppu.outside_win_special_effect;
                }
            }

            if out_indices[0] == {
                case 0;
                bg_line_buffer[0][x] = BLANK_COLOR;
                case 1;
                bg_line_buffer[1][x] = BLANK_COLOR;
                case 2;
                bg_line_buffer[2][x] = BLANK_COLOR;
                case 3;
                bg_line_buffer[3][x] = BLANK_COLOR;
                case 4;
                obj_line_buffer[x] = BLANK_COLOR;
            }
        }

        use_alpha := false;
        if out_indices[0] == {
            case 0;
            out_use_special[0] &= ppu.bg_first_target_pixel[0];
            case 1;
            out_use_special[0] &= ppu.bg_first_target_pixel[1];
            case 2;
            out_use_special[0] &= ppu.bg_first_target_pixel[2];
            case 3;
            out_use_special[0] &= ppu.bg_first_target_pixel[3];
            case 4;
            out_use_special[0] &= ppu.obj_first_target_pixel || obj_use_alpha_buffer[x];
            use_alpha = obj_use_alpha_buffer[x];
            case 5;
            out_use_special[0] &= ppu.bd_first_target_pixel;
        }

        if out_indices[1] == {
            case 0;
            out_use_special[1] &= ppu.bg_second_target_pixel[0];
            case 1;
            out_use_special[1] &= ppu.bg_second_target_pixel[1];
            case 2;
            out_use_special[1] &= ppu.bg_second_target_pixel[2];
            case 3;
            out_use_special[1] &= ppu.bg_second_target_pixel[3];
            case 4;
            out_use_special[1] &= ppu.obj_second_target_pixel;
            case 5;
            if out_indices[0] != 5 then out_use_special[1] &= ppu.bd_second_target_pixel;
        }

        if out_use_special[0] {
            if (use_alpha || ppu.special_effect == 1) && out_use_special[1] {
                r : u16 = xx (((out_pixels[0] >> 0) & 0x1f) * (min(ppu.eva, 16) / 16.0) + ((out_pixels[1] >> 0) & 0x1f) * (min(ppu.evb, 16) / 16.0));
                g : u16 = xx (((out_pixels[0] >> 5) & 0x1f) * (min(ppu.eva, 16) / 16.0) + ((out_pixels[1] >> 5) & 0x1f) * (min(ppu.evb, 16) / 16.0));
                b : u16 = xx (((out_pixels[0] >> 10) & 0x1f) * (min(ppu.eva, 16) / 16.0) + ((out_pixels[1] >> 10) & 0x1f) * (min(ppu.evb, 16) / 16.0));
                r = xx min(0x1f, r);
                g = xx min(0x1f, g);
                b = xx min(0x1f, b);
                framebuffer[ppu.draw_y * SCREEN_WIDTH + x] = r | (g << 5) | (b << 10);
            } else if ppu.special_effect == 2 {
                r : u16 = xx (((out_pixels[0] >> 0) & 0x1f) + (31 - ((out_pixels[0] >> 0) & 0x1f)) * (min(ppu.evy, 16) / 16.0));
                g : u16 = xx (((out_pixels[0] >> 5) & 0x1f) + (63 - ((out_pixels[0] >> 5) & 0x1f)) * (min(ppu.evy, 16) / 16.0));
                b : u16 = xx (((out_pixels[0] >> 10) & 0x1f) + (31 - ((out_pixels[0] >> 10) & 0x1f)) * (min(ppu.evy, 16) / 16.0));
                r = xx min(0x1f, r);
                g = xx min(0x1f, g);
                b = xx min(0x1f, b);
                framebuffer[ppu.draw_y * SCREEN_WIDTH + x] = r | (g << 5) | (b << 10);
            } else if ppu.special_effect == 3 {
                r : u16 = xx (((out_pixels[0] >> 0) & 0x1f) - ((out_pixels[0] >> 0) & 0x1f) * (min(ppu.evy, 16) / 16.0));
                g : u16 = xx (((out_pixels[0] >> 5) & 0x1f) - ((out_pixels[0] >> 5) & 0x1f) * (min(ppu.evy, 16) / 16.0));
                b : u16 = xx (((out_pixels[0] >> 10) & 0x1f) - ((out_pixels[0] >> 10) & 0x1f) * (min(ppu.evy, 16) / 16.0));
                framebuffer[ppu.draw_y * SCREEN_WIDTH + x] = r | (g << 5) | (b << 10);
            } else {
                framebuffer[ppu.draw_y * SCREEN_WIDTH + x] = out_pixels[0];
            }
        } else {
            framebuffer[ppu.draw_y * SCREEN_WIDTH + x] = out_pixels[0];
        }
    }
}

vblank_happened := false;
hblank_happened := false;
step_ppu :: () {
    if ppu.remaining_cycles > 0 {
        ppu.remaining_cycles -= 4;
        ppu.draw_x += 1;
        // 240 visible + 68 hblank
        if ppu.draw_x == 308 {
            ppu.draw_x = 0;
            hblank_happened = false;
            ppu.draw_y += 1;
            // 160 visible + 68 vblank
            if ppu.draw_y == 228 {
                ppu.draw_y = 0;
                vblank_happened = false;
                ppu.bg[2].anchor_x_l = ppu.bg[2].anchor_x;
                ppu.bg[2].anchor_y_l = ppu.bg[2].anchor_y;
                ppu.bg[3].anchor_x_l = ppu.bg[3].anchor_x;
                ppu.bg[3].anchor_y_l = ppu.bg[3].anchor_y;
            }
        }

        if cpu.interrupt_master_enable && !get_status_bit(.I) {
            if ppu.vblank_irq_enable && (cpu.ie & (1 << Interrupt_Source.LCD_VBLANK)) != 0 && ppu.draw_y >= 160 && !vblank_happened {
                vblank_happened = true;
                cpu.ifl |= 1 << Interrupt_Source.LCD_VBLANK;
                interrupt(.IRQ);
            } else if ppu.hblank_irq_enable && (cpu.ie & (1 << Interrupt_Source.LCD_HBLANK)) != 0 && ppu.draw_x >= 240 && !hblank_happened {
                hblank_happened = true;
                cpu.ifl |= 1 << Interrupt_Source.LCD_HBLANK;
                interrupt(.IRQ);
            } else if ppu.vcounter_irq_enable && (cpu.ie & (1 << Interrupt_Source.LCD_VCOUNTER)) != 0 && ppu.draw_y == ppu.vcounter {
                cpu.ifl |= 1 << Interrupt_Source.LCD_VCOUNTER;
                interrupt(.IRQ);
            } else if cpu.schedule_irq {
                cpu.ifl |= xx (1 << cpu.scheduled_irq);
                cpu.scheduled_irq = 0;
                cpu.schedule_irq = false;
                interrupt(.IRQ);
            }
        }

        if ppu.draw_x == 0 {
            cpu.ifl &= ~(1 << Interrupt_Source.LCD_HBLANK) & 0xffff;
        }

        if ppu.draw_y == 0 {
            cpu.ifl &= ~(1 << Interrupt_Source.LCD_VBLANK) & 0xffff;
        }

        if ppu.draw_x == 240 && ppu.draw_y < 160 {
            for 0..SCREEN_WIDTH-1 {
                bg_line_buffer[0][it] = BLANK_COLOR;
                bg_line_buffer[1][it] = BLANK_COLOR;
                bg_line_buffer[2][it] = BLANK_COLOR;
                bg_line_buffer[3][it] = BLANK_COLOR;
                obj_line_buffer[it] = BLANK_COLOR;
                obj_prio_buffer[it] = 8;
                obj_win_buffer[it] = false;
                obj_use_alpha_buffer[it] = false;
                framebuffer[ppu.draw_y * SCREEN_WIDTH + it] = ppu.memory.palette_ram._16[0];
            }

            if ppu.forced_blank then for 0..SCREEN_WIDTH-1 framebuffer[ppu.draw_y * SCREEN_WIDTH + it] = 0;

            if ppu.bg_mode == {
                case 0;
                    draw_obj(ppu.draw_y);
                    draw_bg(ppu.draw_y, 0, false);
                    draw_bg(ppu.draw_y, 1, false);
                    draw_bg(ppu.draw_y, 2, false);
                    draw_bg(ppu.draw_y, 3, false);
                    merge_and_blend();
                case 1;
                    draw_obj(ppu.draw_y);
                    draw_bg(ppu.draw_y, 0, false);
                    draw_bg(ppu.draw_y, 1, false);
                    draw_bg(ppu.draw_y, 2, true);
                    merge_and_blend();
                case 2;
                    draw_obj(ppu.draw_y);
                    draw_bg(ppu.draw_y, 2, true);
                    draw_bg(ppu.draw_y, 3, true);
                    merge_and_blend();
                case 3;
                case 4;
                    draw_obj(ppu.draw_y);
                    draw_bitmap(ppu.draw_y);
                    merge_and_blend();
                case 5;
            }
        }

        if ppu.draw_x == 240 && ppu.draw_y < 160 {
            for 0..3 {
                if cpu.dma[it].start_timing == .HBLANK && cpu.dma[it].enable {
                    cnt := cpu.dma[it].count;
                    for _: 0..cnt-1 transfer(it);
                }
            }
        }

        if ppu.draw_x == 240 && ppu.draw_y == 160 {
            for 0..3 {
                if cpu.dma[it].start_timing == .VBLANK && cpu.dma[it].enable {
                    cnt := cpu.dma[it].count;
                    for _: 0..cnt-1 transfer(it);
                }
            }
        }
    }
}

font :: #run read_entire_file("in/ProggyClean.ttf");
controller: *SDL_GameController;
dt : float64;

ui :: () {
    quit := false;
    SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER);

    spec: SDL_AudioSpec;
    spec.channels = 1;
    spec.format = AUDIO_S16;
    spec.freq = SAMPLE_RATE;
    spec.samples = CALLBACK_SIZE;
    apu.dev = SDL_OpenAudioDevice(null, 0, *spec, null, 0);
    if apu.dev == 0 {
        str: string;
        str.data = SDL_GetError();
        str.count = c_style_strlen(str.data);
        print("Failed to initialize audio context: %\n", str);
        exit(1);
    }
    SDL_PauseAudioDevice(apu.dev, 0);

    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "opengl");
    win := SDL_CreateWindow("gba", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, window_width, window_height, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    gl_context := SDL_GL_CreateContext(win);
    gl_load(*gl, SDL_GL_GetProcAddress);
    renderer := SDL_CreateRenderer(win, -1, .ACCELERATED | .TARGETTEXTURE);
    ImGui.CreateContext();
    ImGui_ImplSdl_Init(win);
    ImGui.StyleColorsDark();
    ImGui.GetIO().Fonts.AddFontFromMemoryTTF(ImGui.GetIO().Fonts, font.data, font.count, FONT_SIZE);

    time := seconds_since_init();
    keystate := SDL_GetKeyboardState(null);
    while !quit {
        new_time := seconds_since_init();
        dt = new_time - time;
        time = new_time;
        event: SDL_Event;
        while SDL_PollEvent(*event) {
            ImGui_ImplSdl_ProcessEvent(*event);
            if event.type == SDL_QUIT quit = true;
            if event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(win) {
                quit = true;
            }
            if event.type == SDL_KEYDOWN {
                if event.key.keysym.sym == {
                    case .SDLK_F9;
                        cpu.emu_state = .STOPPED;
                    case .SDLK_F10;
                        cpu.emu_state = .STARTED;
                    case .SDLK_F11;
                        cpu.emu_state = .STEPPED;
                }
            }
            if event.type == SDL_KEYDOWN && event.key.repeat == 0 && (event.key.keysym.mod & .KMOD_SHIFT) != 0 {
                if event.key.keysym.sym == {
                    case .SDLK_ESCAPE;
                        quit = true;
                    case .SDLK_TAB;
                        show_header = !show_header;
                    case .SDLK_a;
                        show_apu = !show_apu;
                    case .SDLK_b;
                        show_blend = !show_blend;
                    case .SDLK_c;
                        show_cpu = !show_cpu;
                    case .SDLK_d;
                        show_disasm = !show_disasm;
                    case .SDLK_e;
                        show_ewram = !show_ewram;
                    case .SDLK_g;
                        show_ppu = !show_ppu;
                    case .SDLK_i;
                        show_iwram = !show_iwram;
                    case .SDLK_k;
                        show_keypad = !show_keypad;
                    case .SDLK_m;
                        show_dma = !show_dma;
                    case .SDLK_o;
                        show_oam = !show_oam;
                    case .SDLK_p;
                        show_palette_ram = !show_palette_ram;
                    case .SDLK_r;
                        show_rom = !show_rom;
                    case .SDLK_s;
                        show_save = !show_save;
                    case .SDLK_t;
                        show_timer = !show_timer;
                    case .SDLK_v;
                        show_vram = !show_vram;
                    case .SDLK_w;
                        show_window = !show_window;
                }
            }
            if event.type == SDL_CONTROLLERDEVICEADDED {
                if controller == null
                    controller = SDL_GameControllerOpen(event.cdevice.which);
            }
            if event.type == SDL_CONTROLLERDEVICEREMOVED {
                if controller
                    SDL_GameControllerClose(controller);
            }
        }

        // inputs
        ppu.keypad_state =
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_B)) << 0) | // perhaps swap B and A on a less messed up controller
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_A)) << 1) |
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_BACK)) << 2) |
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_START)) << 3) |
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_RIGHT)) << 4) |
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_LEFT)) << 5) |
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_UP)) << 6) |
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_DOWN)) << 7) |
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_RIGHTSHOULDER)) << 8) |
            ((cast(u16)SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_LEFTSHOULDER)) << 9);

        if SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTX) < -16384 {
            ppu.keypad_state |= 0x20;
        }
        if SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTX) > 16384 {
            ppu.keypad_state |= 0x10;
        }
        if SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTY) < -16384 {
            ppu.keypad_state |= 0x40;
        }
        if SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTY) > 16384 {
            ppu.keypad_state |= 0x80;
        }
        SDL_PumpEvents();
        if !keystate[SDL_SCANCODE_LSHIFT] && !keystate[SDL_SCANCODE_RSHIFT] then
            ppu.keypad_state |=
                (cast(u16, keystate[SDL_SCANCODE_A]) << 0) |
                (cast(u16, keystate[SDL_SCANCODE_B]) << 1) |
                (cast(u16, keystate[SDL_SCANCODE_TAB]) << 2) |
                (cast(u16, keystate[SDL_SCANCODE_RETURN]) << 3) |
                (cast(u16, keystate[SDL_SCANCODE_RIGHT]) << 4) |
                (cast(u16, keystate[SDL_SCANCODE_LEFT]) << 5) |
                (cast(u16, keystate[SDL_SCANCODE_UP]) << 6) |
                (cast(u16, keystate[SDL_SCANCODE_DOWN]) << 7) |
                (cast(u16, keystate[SDL_SCANCODE_R]) << 8) |
                (cast(u16, keystate[SDL_SCANCODE_L]) << 9);

        step_all :: (cycle_count: int) {
            cpu.remaining_cycles += cycle_count;
            ppu.remaining_cycles += cycle_count;
            apu.remaining_cycles += cycle_count;
            while cpu.emu_state != .STOPPED &&
            (cpu.remaining_cycles > 0 || ppu.remaining_cycles > 0 || apu.remaining_cycles > 0.0) {
                step_cpu();
                step_ppu();
                step_apu();
            }
        }

        // processing
        if cpu.emu_state == {
            case .STARTED;
                step_all(-cpu.remaining_cycles + 1);
                cpu.emu_state = .RUNNING;
                #through;
            case .RUNNING;
                for 0..228-1 {
                    if cpu.emu_state == .STOPPED break;
                    for 0..308-1 {
                        if cpu.emu_state == .STOPPED break;
                        step_all(4);
                    }
                }
                disasm_scroll_state = cpu.reg[15] / ifx get_status_bit(.T) then 2 else 4;
                disasm_mode = get_status_bit(.T);
            case .STOPPED;
                // this page intentionally left blank
            case .STEPPED;
                step_all(-cpu.remaining_cycles + 1);
                cpu.emu_state = .STOPPED;
                disasm_scroll_state = cpu.reg[15] / ifx get_status_bit(.T) then 2 else 4;
                disasm_mode = get_status_bit(.T);
            case .STEPPED_SCANLINE;
                step_all(308 * 4);
                cpu.emu_state = .STOPPED;
                disasm_scroll_state = cpu.reg[15] / ifx get_status_bit(.T) then 2 else 4;
                disasm_mode = get_status_bit(.T);
            case .STEPPED_FRAME;
                step_all(308 * 228 * 4);
                cpu.emu_state = .STOPPED;
                disasm_scroll_state = cpu.reg[15] / ifx get_status_bit(.T) then 2 else 4;
                disasm_mode = get_status_bit(.T);
        }

        SDL_RenderClear(renderer);
        surface := SDL_CreateRGBSurfaceFrom(framebuffer.data, SCREEN_WIDTH, SCREEN_HEIGHT, 15, SCREEN_WIDTH * 2, 0x1f, 0x3e0, 0x7c00, 0);
        defer SDL_FreeSurface(surface);
        tex := SDL_CreateTextureFromSurface(renderer, surface);
        defer SDL_DestroyTexture(tex);
        SDL_RenderCopy(renderer, tex, null, null);
        // GUI
        SDL_GL_MakeCurrent(win, gl_context);
        ImGui_ImplSdl_NewFrame(win);
        ImGui.NewFrame();
        draw_gui();
        ImGui.Render();
        ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
        SDL_GL_SwapWindow(win);
        reset_temporary_storage();
        #if #exists(__Iprof) {
            __Iprof.update(true);
            report = __Iprof.create_report();
        }
        end_time := seconds_since_init();
        // TODO: should probably make this refresh rate dependent
        sleep_milliseconds(xx (16.6 - ((end_time - time) * 1000)));
    }
}
