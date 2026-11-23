/// @desc UI theme: palette, fonts, animated widgets and procedural vector icons

// -----------------------------------------------------------------------------
// PALETTE
// -----------------------------------------------------------------------------
#macro C_BG0      make_color_rgb(7, 10, 17)
#macro C_BG1      make_color_rgb(12, 16, 26)
#macro C_PANEL    make_color_rgb(16, 21, 33)
#macro C_RAISED   make_color_rgb(23, 30, 46)
#macro C_HOVER    make_color_rgb(32, 43, 64)
#macro C_LINE     make_color_rgb(42, 56, 80)
#macro C_LINE_HI  make_color_rgb(72, 96, 134)
#macro C_TEXT     make_color_rgb(228, 236, 247)
#macro C_DIM      make_color_rgb(146, 162, 188)
#macro C_FAINT    make_color_rgb(92, 107, 132)
#macro C_ACCENT   make_color_rgb(0, 210, 255)
#macro C_ACCENT_D make_color_rgb(0, 86, 118)
#macro C_AMBER    make_color_rgb(255, 186, 58)
#macro C_GOOD     make_color_rgb(70, 222, 140)
#macro C_GOOD_D   make_color_rgb(20, 92, 58)
#macro C_BAD      make_color_rgb(255, 84, 84)
#macro C_BAD_D    make_color_rgb(104, 26, 34)
#macro C_WARN     make_color_rgb(255, 160, 64)
#macro C_ENERGY   make_color_rgb(255, 214, 64)
#macro C_GOLD     make_color_rgb(255, 204, 64)
#macro C_ALIEN    make_color_rgb(196, 110, 255)
#macro C_TOWER    make_color_rgb(64, 160, 255)
#macro C_WEAPON   make_color_rgb(255, 112, 96)

global.ui_anim_state = {};
global.ui_hover_key = "";
global.ui_hover_prev_key = "";

/// @desc Called at the start of every GUI frame
function ui_begin_frame() {
    draw_set_font(fnt_body);
    draw_set_circle_precision(48);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    gpu_set_blendmode(bm_normal);
    // Hover-enter detection for a soft UI tick
    if (global.ui_hover_key != "" && global.ui_hover_key != global.ui_hover_prev_key) {
        game_play_sfx("hover", 0.35);
    }
    global.ui_hover_prev_key = global.ui_hover_key;
    global.ui_hover_key = "";
}

/// @desc Smoothly animates a named value toward a target (frame-rate independent enough for 60fps)
function ui_anim(key, target, rate = 0.25) {
    var cur = global.ui_anim_state[$ key];
    if (is_undefined(cur)) cur = target;
    cur = lerp(cur, target, rate);
    if (abs(cur - target) < 0.002) cur = target;
    global.ui_anim_state[$ key] = cur;
    return cur;
}

function ui_col_mix(c1, c2, t) {
    return merge_color(c1, c2, clamp(t, 0, 1));
}

// -----------------------------------------------------------------------------
// TEXT
// -----------------------------------------------------------------------------
/// @desc Draws text at a visual scale using the closest crisp font instead of stretching the bitmap
function ui_text_scaled(tx, ty, str, scale) {
    var prev = draw_get_font();
    var want = 15 * scale;
    var f = fnt_body; var fpx = 15;
    if (want >= 80) { f = fnt_title; fpx = 96; }
    else if (want >= 31) { f = fnt_h1; fpx = 38; }
    else if (want >= 22) { f = fnt_h2; fpx = 25; }
    else if (want >= 17.5) { f = fnt_h3; fpx = 19; }
    else if (want >= 15.5) { f = fnt_bold; fpx = 15; }
    else if (want < 14) { f = fnt_small; fpx = 13; }
    draw_set_font(f);
    var s = want / fpx;
    if (abs(s - 1) < 0.18) {
        draw_text(round(tx), round(ty), str);
    } else {
        draw_text_transformed(tx, ty, str, s, s, 0);
    }
    draw_set_font(prev);
}

/// @desc draw_text_ext that never lets lines overlap regardless of the active font
function ui_text_ext(tx, ty, str, sep, w) {
    var lh = string_height("Ag");
    draw_text_ext(round(tx), round(ty), str, max(sep, lh - 1), w);
}

function ui_text_shadow(tx, ty, str, col, shadow_alpha = 0.7) {
    var a = draw_get_alpha();
    draw_set_color(c_black);
    draw_set_alpha(a * shadow_alpha);
    draw_text(tx + 1, ty + 2, str);
    draw_set_alpha(a);
    draw_set_color(col);
    draw_text(tx, ty, str);
}

function ui_text_outline(tx, ty, str, col, out_col = c_black) {
    var a = draw_get_alpha();
    draw_set_color(out_col);
    draw_set_alpha(a * 0.85);
    draw_text(tx - 1, ty, str); draw_text(tx + 1, ty, str);
    draw_text(tx, ty - 1, str); draw_text(tx, ty + 1, str);
    draw_text(tx + 1, ty + 2, str);
    draw_set_alpha(a);
    draw_set_color(col);
    draw_text(tx, ty, str);
}

/// @desc Truncates a string with an ellipsis so it fits within max_w pixels in the current font
function ui_fit_text(str, max_w) {
    if (string_width(str) <= max_w) return str;
    var s = str;
    while (string_length(s) > 1 && string_width(s + "...") > max_w) {
        s = string_copy(s, 1, string_length(s) - 1);
    }
    return s + "...";
}

// -----------------------------------------------------------------------------
// SHAPES & PANELS
// -----------------------------------------------------------------------------
/// @desc Filled rounded box with border and a soft top sheen
function ui_box(x1, y1, x2, y2, fill, border = undefined, r = 8, alpha = 1) {
    var a0 = draw_get_alpha();
    draw_set_alpha(a0 * alpha);
    draw_set_color(fill);
    draw_roundrect_ext(x1, y1, x2, y2, r, r, false);
    // Top sheen
    if (y2 - y1 > 14) {
        draw_set_alpha(a0 * alpha * 0.06);
        draw_set_color(c_white);
        draw_roundrect_ext(x1 + 1, y1 + 1, x2 - 1, y1 + min(18, (y2 - y1) * 0.5), r, r, false);
    }
    if (!is_undefined(border)) {
        draw_set_alpha(a0 * alpha);
        draw_set_color(border);
        draw_roundrect_ext(x1, y1, x2, y2, r, r, true);
    }
    draw_set_alpha(a0);
}

/// @desc Soft drop shadow beneath a rectangle
function ui_shadow(x1, y1, x2, y2, r = 10, strength = 0.45) {
    var a0 = draw_get_alpha();
    draw_set_color(c_black);
    for (var i = 3; i >= 1; i--) {
        draw_set_alpha(a0 * strength * 0.22);
        draw_roundrect_ext(x1 - i * 2, y1 - i + 4, x2 + i * 2, y2 + i * 3 + 4, r + i * 2, r + i * 2, false);
    }
    draw_set_alpha(a0);
}

function ui_corner_brackets(x1, y1, x2, y2, len, col, thick = 2) {
    draw_set_color(col);
    draw_line_width(x1, y1, x1 + len, y1, thick); draw_line_width(x1, y1, x1, y1 + len, thick);
    draw_line_width(x2, y1, x2 - len, y1, thick); draw_line_width(x2, y1, x2, y1 + len, thick);
    draw_line_width(x1, y2, x1 + len, y2, thick); draw_line_width(x1, y2, x1, y2 - len, thick);
    draw_line_width(x2, y2, x2 - len, y2, thick); draw_line_width(x2, y2, x2, y2 - len, thick);
}

/// @desc Standard framed panel with an optional header title
function ui_panel(px, py, pw, ph, title = "", accent = C_ACCENT, subtitle = "") {
    ui_shadow(px, py, px + pw, py + ph, 12, 0.5);
    ui_box(px, py, px + pw, py + ph, C_PANEL, C_LINE, 12);
    if (title != "") {
        draw_set_color(accent);
        draw_roundrect_ext(px + 12, py + 13, px + 15, py + 29, 2, 2, false);
        draw_set_font(fnt_h3);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(C_TEXT);
        draw_text(px + 24, py + 21, title);
        if (subtitle != "") {
            var tw = string_width(title);
            draw_set_font(fnt_small);
            draw_set_color(C_FAINT);
            draw_text(px + 34 + tw, py + 22, subtitle);
        }
        draw_set_font(fnt_body);
        draw_set_color(C_LINE);
        draw_line(px + 12, py + 40, px + pw - 12, py + 40);
    }
}

/// @desc Section header label with accent tick (for inside panels)
function ui_section_label(lx, ly, str, col = C_DIM) {
    draw_set_font(fnt_small);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(col);
    draw_text(lx, ly, string_upper(str));
    draw_set_font(fnt_body);
}

/// @desc Horizontal progress bar with optional segment ticks
function ui_bar(bx, by, bw, bh, ratio, col, segments = 0, bg = C_BG1) {
    ratio = clamp(ratio, 0, 1);
    draw_set_color(bg);
    draw_roundrect_ext(bx, by, bx + bw, by + bh, bh * 0.5, bh * 0.5, false);
    if (ratio > 0) {
        draw_set_color(col);
        draw_roundrect_ext(bx, by, bx + max(bh, bw * ratio), by + bh, bh * 0.5, bh * 0.5, false);
        draw_set_alpha(draw_get_alpha() * 0.35);
        draw_set_color(c_white);
        draw_roundrect_ext(bx + 1, by + 1, bx + max(bh, bw * ratio) - 1, by + bh * 0.45, bh * 0.4, bh * 0.4, false);
        draw_set_alpha(1);
    }
    if (segments > 1) {
        draw_set_color(bg);
        for (var s = 1; s < segments; s++) {
            var sx = bx + bw * s / segments;
            draw_line_width(sx, by, sx, by + bh, 2);
        }
    }
}

/// @desc Small keyboard key hint, returns its width
function ui_keycap(kx, ky, label, align_center = false) {
    var pf = draw_get_font();
    var ph = draw_get_halign();
    var pv = draw_get_valign();
    draw_set_font(fnt_small);
    var w = max(18, string_width(label) + 10);
    var h = 18;
    var x0 = align_center ? kx - w * 0.5 : kx;
    draw_set_color(C_BG0);
    draw_roundrect_ext(x0, ky - h * 0.5 + 1, x0 + w, ky + h * 0.5 + 1, 4, 4, false);
    draw_set_color(C_RAISED);
    draw_roundrect_ext(x0, ky - h * 0.5, x0 + w, ky + h * 0.5 - 1, 4, 4, false);
    draw_set_color(C_LINE_HI);
    draw_roundrect_ext(x0, ky - h * 0.5, x0 + w, ky + h * 0.5 - 1, 4, 4, true);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(C_DIM);
    draw_text(x0 + w * 0.5, ky - 1, label);
    draw_set_font(pf);
    draw_set_halign(ph);
    draw_set_valign(pv);
    return w;
}

/// @desc Pill/badge with text. Returns width.
function ui_pill(px, py, label, fill, text_col, border = undefined, h = 22) {
    var pf = draw_get_font();
    draw_set_font(fnt_small);
    var w = string_width(label) + 16;
    ui_box(px, py, px + w, py + h, fill, border, h * 0.5);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(text_col);
    draw_text(px + w * 0.5, py + h * 0.5, label);
    draw_set_font(pf);
    return w;
}

/// @desc Smooth additive radial glow (vertex-coloured triangle fan: bright centre fading to nothing)
function ui_glow(gx, gy, r, col, alpha = 0.35) {
    gpu_set_blendmode(bm_add);
    var a = draw_get_alpha() * alpha;
    var segs = 40;
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_color(gx, gy, col, a);
    for (var i = 0; i <= segs; i++) {
        var ang = i * 360 / segs;
        draw_vertex_color(gx + lengthdir_x(r, ang), gy + lengthdir_y(r, ang), col, 0);
    }
    draw_primitive_end();
    gpu_set_blendmode(bm_normal);
}

function ui_hexagon(cx, cy, r, filled, rot = 30) {
    if (filled) {
        draw_primitive_begin(pr_trianglefan);
        draw_vertex(cx, cy);
        for (var i = 0; i <= 6; i++) draw_vertex(cx + lengthdir_x(r, rot + i * 60), cy + lengthdir_y(r, rot + i * 60));
        draw_primitive_end();
    } else {
        for (var i = 0; i < 6; i++) {
            draw_line_width(cx + lengthdir_x(r, rot + i * 60), cy + lengthdir_y(r, rot + i * 60), cx + lengthdir_x(r, rot + (i + 1) * 60), cy + lengthdir_y(r, rot + (i + 1) * 60), 2);
        }
    }
}

// -----------------------------------------------------------------------------
// BUTTONS
// -----------------------------------------------------------------------------
/// @desc Animated button. style: "default" | "primary" | "success" | "danger" | "ghost"
/// Signature kept compatible with the original ui_draw_button(rx, ry, rw, rh, text, enabled, is_active, mx, my)
function ui_draw_button(rx, ry, rw, rh, text, enabled, is_active, mouse_px, mouse_py, style = "default", hotkey = "") {
    var hovered = enabled && ui_point_in_rect(mouse_px, mouse_py, rx, ry, rw, rh);
    var key = "btn" + string(round(rx)) + "_" + string(round(ry)) + "_" + string(round(rw));
    var h = ui_anim(key, hovered ? 1 : 0, 0.3);
    if (hovered) global.ui_hover_key = key;
    var pressed = hovered && mouse_check_button(mb_left);

    var fill = C_RAISED, border = C_LINE, txt = C_TEXT, glow = C_ACCENT;
    if (is_active && style == "default") style = "primary";
    switch (style) {
        case "primary": fill = make_color_rgb(10, 70, 98); border = C_ACCENT; txt = c_white; glow = C_ACCENT; break;
        case "success": fill = make_color_rgb(22, 104, 66); border = C_GOOD; txt = c_white; glow = C_GOOD; break;
        case "danger":  fill = make_color_rgb(88, 26, 32); border = C_BAD; txt = make_color_rgb(255, 220, 220); glow = C_BAD; break;
        case "ghost":   fill = C_PANEL; border = C_LINE; txt = C_DIM; glow = C_ACCENT; break;
        case "amber":   fill = make_color_rgb(96, 64, 12); border = C_AMBER; txt = c_white; glow = C_AMBER; break;
    }
    if (!enabled) {
        fill = make_color_rgb(17, 21, 31); border = make_color_rgb(32, 38, 52); txt = make_color_rgb(84, 94, 112);
    }

    var lift = pressed ? 1 : 0;
    var y0 = ry + lift;
    // Glow on hover
    if (h > 0.01 && enabled) {
        draw_set_alpha(0.25 * h);
        draw_set_color(glow);
        draw_roundrect_ext(rx - 3, y0 - 3, rx + rw + 3, y0 + rh + 3, 9, 9, false);
        draw_set_alpha(1);
    }
    var f = ui_col_mix(fill, ui_col_mix(fill, glow, 0.35), h * 0.8);
    ui_box(rx, y0, rx + rw, y0 + rh, f, ui_col_mix(border, glow, h), 6);

    // Label (+ optional hotkey cap)
    var pf = draw_get_font();
    draw_set_font(rh >= 40 ? fnt_h3 : fnt_bold);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    var label = text;
    var cap_w = 0;
    if (hotkey != "") {
        draw_set_font(fnt_small);
        cap_w = max(18, string_width(hotkey) + 10) + 8;
        draw_set_font(rh >= 40 ? fnt_h3 : fnt_bold);
    }
    label = ui_fit_text(label, rw - 14 - cap_w);
    var lw = string_width(label);
    var tx = rx + rw * 0.5 - cap_w * 0.5;
    draw_set_color(enabled ? ui_col_mix(txt, c_white, h) : txt);
    draw_text(round(tx), round(y0 + rh * 0.5), label);
    if (hotkey != "") {
        ui_keycap(tx + lw * 0.5 + 8, y0 + rh * 0.5, hotkey);
    }
    draw_set_font(pf);
    return hovered;
}

// -----------------------------------------------------------------------------
// PROCEDURAL ICONS
// -----------------------------------------------------------------------------
function ui_resource_color(key) {
    switch (key) {
        case "wood": return make_color_rgb(196, 132, 74);
        case "scrap": return make_color_rgb(190, 150, 120);
        case "stone": return make_color_rgb(160, 168, 180);
        case "metal": return make_color_rgb(200, 215, 230);
        case "crystals": return make_color_rgb(70, 220, 255);
        case "power_gem": return make_color_rgb(230, 80, 255);
        case "gold": return C_GOLD;
    }
    return C_DIM;
}

/// @desc Draws a small vector icon for a resource type centered at (ix, iy)
function ui_icon_resource(ix, iy, key, size = 16) {
    var s = size * 0.5;
    var col = ui_resource_color(key);
    var dark = merge_color(col, c_black, 0.55);
    switch (key) {
        case "wood":
            draw_set_color(dark);
            draw_roundrect_ext(ix - s, iy - s * 0.45, ix + s * 0.7, iy + s * 0.45, 4, 4, false);
            draw_set_color(col);
            draw_roundrect_ext(ix - s, iy - s * 0.45, ix + s * 0.6, iy + s * 0.35, 4, 4, false);
            draw_set_color(make_color_rgb(240, 200, 140));
            draw_ellipse(ix + s * 0.35, iy - s * 0.45, ix + s, iy + s * 0.45, false);
            draw_set_color(dark);
            draw_ellipse(ix + s * 0.55, iy - s * 0.2, ix + s * 0.8, iy + s * 0.2, true);
            break;
        case "scrap":
            draw_set_color(dark);
            draw_circle(ix, iy, s * 0.95, false);
            draw_set_color(col);
            for (var i = 0; i < 8; i++) {
                var a = i * 45;
                draw_line_width(ix, iy, ix + lengthdir_x(s, a), iy + lengthdir_y(s, a), max(2, s * 0.35));
            }
            draw_circle(ix, iy, s * 0.62, false);
            draw_set_color(dark);
            draw_circle(ix, iy, s * 0.25, false);
            break;
        case "stone":
            draw_set_color(dark);
            draw_triangle(ix - s, iy + s * 0.6, ix - s * 0.3, iy - s * 0.8, ix + s * 0.9, iy + s * 0.6, false);
            draw_set_color(col);
            draw_triangle(ix - s * 0.85, iy + s * 0.5, ix - s * 0.3, iy - s * 0.7, ix + s * 0.5, iy + s * 0.5, false);
            draw_triangle(ix - s * 0.3, iy - s * 0.7, ix + s * 0.75, iy - s * 0.1, ix + s * 0.5, iy + s * 0.5, false);
            break;
        case "metal":
            draw_set_color(dark);
            draw_primitive_begin(pr_trianglestrip);
            draw_vertex(ix - s, iy + s * 0.55); draw_vertex(ix - s * 0.6, iy - s * 0.45);
            draw_vertex(ix + s, iy + s * 0.55); draw_vertex(ix + s * 0.6, iy - s * 0.45);
            draw_primitive_end();
            draw_set_color(col);
            draw_primitive_begin(pr_trianglestrip);
            draw_vertex(ix - s * 0.8, iy + s * 0.35); draw_vertex(ix - s * 0.5, iy - s * 0.35);
            draw_vertex(ix + s * 0.8, iy + s * 0.35); draw_vertex(ix + s * 0.5, iy - s * 0.35);
            draw_primitive_end();
            break;
        case "crystals":
            draw_set_color(dark);
            draw_triangle(ix, iy - s, ix - s * 0.7, iy - s * 0.1, ix, iy + s, false);
            draw_set_color(col);
            draw_triangle(ix, iy - s, ix + s * 0.7, iy - s * 0.1, ix, iy + s, false);
            draw_triangle(ix, iy - s * 0.7, ix - s * 0.45, iy - s * 0.1, ix, iy + s * 0.6, false);
            draw_set_color(c_white);
            draw_line(ix, iy - s, ix, iy + s);
            break;
        case "power_gem":
            draw_set_color(dark);
            ui_hexagon(ix, iy, s, true, 0);
            draw_set_color(col);
            ui_hexagon(ix, iy, s * 0.72, true, 0);
            draw_set_color(make_color_rgb(255, 200, 255));
            draw_circle(ix - s * 0.2, iy - s * 0.2, s * 0.18, false);
            break;
        case "gold":
            draw_set_color(merge_color(col, c_black, 0.4));
            draw_circle(ix, iy + 1, s, false);
            draw_set_color(col);
            draw_circle(ix, iy, s * 0.92, false);
            draw_set_color(merge_color(col, c_white, 0.45));
            draw_circle(ix, iy, s * 0.6, true);
            draw_set_color(merge_color(col, c_black, 0.35));
            draw_line_width(ix, iy - s * 0.4, ix, iy + s * 0.4, max(1.5, s * 0.18));
            break;
        default:
            draw_set_color(col);
            draw_circle(ix, iy, s, false);
    }
}

/// @desc Lightning bolt icon (energy)
function ui_icon_energy(bx, by, size, filled = true) {
    ui_draw_lightning(bx, by, size, filled);
}

/// @desc Heart / shield icons
function ui_icon_heart(hx, hy, size, col) {
    ui_draw_heart(hx, hy, size, col);
}

function ui_icon_shield(sx, sy, size, col) {
    var s = size * 0.5;
    draw_set_color(merge_color(col, c_black, 0.5));
    draw_triangle(sx - s, sy - s * 0.8, sx + s, sy - s * 0.8, sx, sy + s, false);
    draw_rectangle(sx - s, sy - s, sx + s, sy - s * 0.4, false);
    draw_set_color(col);
    draw_triangle(sx - s * 0.75, sy - s * 0.6, sx + s * 0.75, sy - s * 0.6, sx, sy + s * 0.72, false);
    draw_rectangle(sx - s * 0.75, sy - s * 0.8, sx + s * 0.75, sy - s * 0.4, false);
}

/// @desc Map node structure icon
function ui_icon_node(nx, ny, ntype, r, col, t = 0) {
    var s = r;
    switch (ntype) {
        case "gather_forest":
            for (var i = -1; i <= 1; i++) {
                var tx = nx + i * s * 0.42;
                var ty = ny + (i == 0 ? -s * 0.12 : s * 0.08);
                draw_set_color(make_color_rgb(70, 44, 26));
                draw_rectangle(tx - 2, ty + s * 0.2, tx + 2, ty + s * 0.48, false);
                draw_set_color(i == 0 ? make_color_rgb(90, 200, 110) : make_color_rgb(56, 156, 84));
                draw_triangle(tx - s * 0.32, ty + s * 0.25, tx + s * 0.32, ty + s * 0.25, tx, ty - s * 0.45, false);
                draw_triangle(tx - s * 0.26, ty + s * 0.0, tx + s * 0.26, ty + s * 0.0, tx, ty - s * 0.6, false);
            }
            break;
        case "gather_cave1":
        case "gather_cave2":
        case "gather_cave3":
            draw_set_color(merge_color(col, c_white, 0.15));
            draw_triangle(nx - s * 0.75, ny + s * 0.45, nx - s * 0.2, ny - s * 0.5, nx + s * 0.75, ny + s * 0.45, false);
            draw_triangle(nx - s * 0.2, ny - s * 0.5, nx + s * 0.35, ny - s * 0.25, nx + s * 0.75, ny + s * 0.45, false);
            draw_set_color(make_color_rgb(12, 8, 8));
            draw_ellipse(nx - s * 0.3, ny - s * 0.02, nx + s * 0.3, ny + s * 0.55, false);
            var gem_c = (ntype == "gather_cave3") ? make_color_rgb(230, 80, 255) : ((ntype == "gather_cave2") ? make_color_rgb(70, 220, 255) : make_color_rgb(200, 215, 230));
            draw_set_color(gem_c);
            draw_triangle(nx + s * 0.38, ny - s * 0.05, nx + s * 0.48, ny - s * 0.32, nx + s * 0.58, ny - s * 0.05, false);
            break;
        case "town":
            draw_set_color(make_color_rgb(250, 190, 210));
            draw_rectangle(nx - s * 0.55, ny - s * 0.05, nx - s * 0.05, ny + s * 0.45, false);
            draw_triangle(nx - s * 0.65, ny - s * 0.05, nx + s * 0.05, ny - s * 0.05, nx - s * 0.3, ny - s * 0.45, false);
            draw_set_color(make_color_rgb(236, 140, 176));
            draw_rectangle(nx + s * 0.02, ny - s * 0.2, nx + s * 0.55, ny + s * 0.45, false);
            draw_triangle(nx - s * 0.06, ny - s * 0.2, nx + s * 0.63, ny - s * 0.2, nx + s * 0.28, ny - s * 0.62, false);
            draw_set_color(make_color_rgb(60, 30, 44));
            draw_rectangle(nx - s * 0.36, ny + s * 0.18, nx - s * 0.22, ny + s * 0.45, false);
            draw_rectangle(nx + s * 0.2, ny + s * 0.0, nx + s * 0.36, ny + s * 0.14, false);
            break;
        case "shop":
            draw_set_color(make_color_rgb(140, 96, 20));
            draw_rectangle(nx - s * 0.55, ny - s * 0.2, nx + s * 0.55, ny + s * 0.45, false);
            draw_set_color(C_GOLD);
            draw_rectangle(nx - s * 0.62, ny - s * 0.32, nx + s * 0.62, ny - s * 0.12, false);
            draw_set_color(make_color_rgb(255, 236, 150));
            draw_circle(nx, ny + s * 0.12, s * 0.2, false);
            draw_set_color(make_color_rgb(140, 96, 20));
            draw_line_width(nx, ny + s * 0.0, nx, ny + s * 0.24, 2);
            break;
        case "workstation":
            draw_set_color(make_color_rgb(120, 240, 220));
            var gr = s * 0.42;
            for (var i = 0; i < 8; i++) {
                var a = i * 45 + t * 20;
                draw_line_width(nx, ny, nx + lengthdir_x(gr * 1.35, a), ny + lengthdir_y(gr * 1.35, a), s * 0.2);
            }
            draw_circle(nx, ny, gr, false);
            draw_set_color(merge_color(col, c_black, 0.4));
            draw_circle(nx, ny, gr * 0.45, false);
            break;
        case "main_base":
            draw_set_color(make_color_rgb(150, 210, 255));
            ui_hexagon(nx, ny, s * 0.55, true, 30);
            draw_set_color(merge_color(col, c_black, 0.3));
            ui_hexagon(nx, ny, s * 0.34, true, 30);
            draw_set_color(c_white);
            draw_circle(nx, ny, s * 0.12, false);
            break;
        case "tower":
            draw_set_color(make_color_rgb(170, 215, 255));
            draw_rectangle(nx - s * 0.22, ny - s * 0.35, nx + s * 0.22, ny + s * 0.42, false);
            draw_rectangle(nx - s * 0.36, ny - s * 0.52, nx + s * 0.36, ny - s * 0.32, false);
            draw_rectangle(nx - s * 0.42, ny + s * 0.32, nx + s * 0.42, ny + s * 0.46, false);
            break;
        default:
            draw_set_color(merge_color(col, c_white, 0.3));
            draw_primitive_begin(pr_trianglefan);
            draw_vertex(nx, ny);
            draw_vertex(nx, ny - s * 0.4); draw_vertex(nx + s * 0.4, ny); draw_vertex(nx, ny + s * 0.4); draw_vertex(nx - s * 0.4, ny); draw_vertex(nx, ny - s * 0.4);
            draw_primitive_end();
    }
}

/// @desc Procedural alien creature glyph. Distinct silhouettes per species.
function ui_draw_alien_glyph(ax, ay, catalog_id, tier, size, anim_t = 0, flash = 0) {
    var s = size * 0.5;
    var body = make_color_rgb(120, 210, 110);
    if (tier == 2) body = make_color_rgb(240, 160, 60);
    else if (tier == 3) body = make_color_rgb(236, 72, 92);
    switch (catalog_id) {
        case "acid_spitter": body = make_color_rgb(140, 255, 80); break;
        case "drooper": body = make_color_rgb(170, 110, 255); break;
        case "leech": body = make_color_rgb(200, 60, 80); break;
        case "screamer": body = make_color_rgb(255, 120, 200); break;
        case "the_syphon": body = make_color_rgb(110, 180, 255); break;
        case "emp_weaver": body = make_color_rgb(80, 220, 255); break;
        case "alien_queen": body = make_color_rgb(220, 90, 255); break;
        case "hatchling": body = make_color_rgb(170, 230, 150); break;
    }
    if (flash > 0) body = merge_color(body, c_white, clamp(flash, 0, 1));
    var dark = merge_color(body, c_black, 0.55);
    var bob = sin(anim_t * 3 + ax * 0.05) * s * 0.06;
    var cy = ay + bob;
    var a0 = draw_get_alpha();
    
    // Ground shadow
    draw_set_alpha(a0 * 0.35);
    draw_set_color(c_black);
    draw_ellipse(ax - s * 0.7, ay + s * 0.78, ax + s * 0.7, ay + s * 0.98, false);
    draw_set_alpha(a0);

    // Legs / tentacles
    draw_set_color(dark);
    var legs = (tier == 1) ? 4 : ((tier == 2) ? 6 : 8);
    for (var i = 0; i < legs; i++) {
        var f = (i / max(1, legs - 1)) - 0.5;
        var lx = ax + f * s * 1.5;
        var wig = sin(anim_t * 6 + i) * s * 0.06;
        draw_line_width(ax + f * s * 0.8, cy + s * 0.2, lx + wig, ay + s * 0.86, max(2, s * 0.09));
    }

    // Body shape per species
    draw_set_color(dark);
    switch (catalog_id) {
        case "goliath":
        case "armorback":
            draw_roundrect_ext(ax - s * 0.9, cy - s * 0.55, ax + s * 0.9, cy + s * 0.45, s * 0.35, s * 0.35, false);
            draw_set_color(body);
            draw_roundrect_ext(ax - s * 0.8, cy - s * 0.5, ax + s * 0.8, cy + s * 0.35, s * 0.3, s * 0.3, false);
            draw_set_color(dark);
            for (var p = -1; p <= 1; p++) draw_line_width(ax + p * s * 0.35, cy - s * 0.48, ax + p * s * 0.35, cy + s * 0.3, 2);
            break;
        case "drooper":
        case "the_syphon":
            draw_ellipse(ax - s * 0.85, cy - s * 0.75, ax + s * 0.85, cy + s * 0.25, false);
            draw_set_color(body);
            draw_ellipse(ax - s * 0.75, cy - s * 0.7, ax + s * 0.75, cy + s * 0.15, false);
            break;
        case "alien_queen":
        case "broodlord":
            draw_ellipse(ax - s * 0.75, cy - s * 0.85, ax + s * 0.75, cy + s * 0.4, false);
            draw_set_color(body);
            draw_ellipse(ax - s * 0.65, cy - s * 0.8, ax + s * 0.65, cy + s * 0.3, false);
            // crown spikes
            draw_set_color(merge_color(body, c_white, 0.35));
            for (var c = -2; c <= 2; c++) draw_triangle(ax + c * s * 0.22 - s * 0.09, cy - s * 0.72, ax + c * s * 0.22 + s * 0.09, cy - s * 0.72, ax + c * s * 0.22, cy - s * (1.0 + (c == 0) * 0.15), false);
            break;
        default:
            draw_circle(ax, cy - s * 0.15, s * 0.62, false);
            draw_set_color(body);
            draw_circle(ax, cy - s * 0.18, s * 0.54, false);
    }
    // Spikes for tier 3 / screamer
    if (tier == 3 || catalog_id == "screamer") {
        draw_set_color(merge_color(body, c_white, 0.25));
        draw_triangle(ax - s * 0.62, cy - s * 0.3, ax - s * 0.42, cy - s * 0.4, ax - s * 0.85, cy - s * 0.85, false);
        draw_triangle(ax + s * 0.62, cy - s * 0.3, ax + s * 0.42, cy - s * 0.4, ax + s * 0.85, cy - s * 0.85, false);
    }
    // Eyes
    var eyes = (catalog_id == "scout" || catalog_id == "hatchling") ? 1 : ((tier == 3) ? 3 : 2);
    var blink = (frac(anim_t * 0.37 + ax * 0.013) < 0.04);
    for (var e = 0; e < eyes; e++) {
        var ef = (eyes == 1) ? 0 : (e / (eyes - 1) - 0.5);
        var ex = ax + ef * s * 0.55;
        var ey = cy - s * 0.25 - (eyes == 3 && e == 1 ? s * 0.12 : 0);
        draw_set_color(c_black);
        draw_ellipse(ex - s * 0.16, ey - (blink ? s * 0.02 : s * 0.14), ex + s * 0.16, ey + (blink ? s * 0.02 : s * 0.14), false);
        if (!blink) {
            draw_set_color(make_color_rgb(255, 250, 200));
            draw_circle(ex + s * 0.04, ey - s * 0.03, max(1.5, s * 0.06), false);
        }
    }
}

/// @desc Weapon emblem icon
function ui_icon_weapon(wx, wy, catalog_id, size, col) {
    var s = size * 0.5;
    var dark = merge_color(col, c_black, 0.5);
    draw_set_color(dark);
    draw_circle(wx, wy + s * 0.35, s * 0.55, false);
    draw_set_color(col);
    switch (catalog_id) {
        case "turret":
            draw_rectangle(wx - s * 0.5, wy - s * 0.15, wx + s * 0.1, wy + s * 0.1, false);
            draw_rectangle(wx - s * 0.5, wy + s * 0.18, wx + s * 0.1, wy + s * 0.4, false);
            draw_rectangle(wx + s * 0.1, wy - s * 0.3, wx + s * 0.9, wy - s * 0.15, false);
            draw_rectangle(wx + s * 0.1, wy + s * 0.05, wx + s * 0.9, wy + s * 0.2, false);
            break;
        case "cannon":
        case "plasma_mortar":
            draw_circle(wx - s * 0.1, wy + s * 0.1, s * 0.45, false);
            draw_line_width(wx, wy, wx + s * 0.85, wy - s * 0.6, s * 0.32);
            break;
        case "railgun":
            draw_rectangle(wx - s * 0.9, wy - s * 0.12, wx + s * 0.9, wy + s * 0.12, false);
            draw_rectangle(wx - s * 0.6, wy - s * 0.32, wx + s * 0.6, wy - s * 0.2, false);
            draw_rectangle(wx - s * 0.6, wy + s * 0.2, wx + s * 0.6, wy + s * 0.32, false);
            break;
        case "tesla":
        case "overcharge_pylon":
        case "energy_pylon":
            draw_rectangle(wx - s * 0.15, wy - s * 0.2, wx + s * 0.15, wy + s * 0.6, false);
            draw_circle(wx, wy - s * 0.45, s * 0.32, false);
            draw_set_color(c_white);
            draw_line_width(wx - s * 0.5, wy - s * 0.8, wx - s * 0.2, wy - s * 0.55, 2);
            draw_line_width(wx + s * 0.5, wy - s * 0.8, wx + s * 0.2, wy - s * 0.55, 2);
            break;
        case "flamethrower":
            draw_rectangle(wx - s * 0.8, wy - s * 0.15, wx + s * 0.3, wy + s * 0.15, false);
            draw_set_color(make_color_rgb(255, 160, 40));
            draw_triangle(wx + s * 0.3, wy - s * 0.35, wx + s * 0.3, wy + s * 0.35, wx + s, wy, false);
            break;
        case "shield_generator":
            ui_icon_shield(wx, wy, size * 0.85, col);
            break;
        case "cryo_emitter":
            for (var i = 0; i < 3; i++) draw_line_width(wx + lengthdir_x(s * 0.8, i * 60), wy + lengthdir_y(s * 0.8, i * 60), wx - lengthdir_x(s * 0.8, i * 60), wy - lengthdir_y(s * 0.8, i * 60), 2);
            break;
        case "resource_drone":
            draw_ellipse(wx - s * 0.5, wy - s * 0.2, wx + s * 0.5, wy + s * 0.25, false);
            draw_line_width(wx - s * 0.9, wy - s * 0.35, wx + s * 0.9, wy - s * 0.35, 2);
            break;
        case "lazer_gun":
        default:
            draw_rectangle(wx - s * 0.7, wy - s * 0.18, wx + s * 0.55, wy + s * 0.18, false);
            draw_set_color(make_color_rgb(255, 90, 90));
            draw_circle(wx + s * 0.75, wy, s * 0.16, false);
    }
}

/// @desc Mouse position in GUI space (overridable by the autotest harness)
function ui_mouse_x() {
    if (autotest_active()) return global.at.mouse_x;
    return device_mouse_x_to_gui(0);
}
function ui_mouse_y() {
    if (autotest_active()) return global.at.mouse_y;
    return device_mouse_y_to_gui(0);
}
