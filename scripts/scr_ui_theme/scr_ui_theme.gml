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
    var want = 17 * scale;
    var f = fnt_body; var fpx = 17;
    if (want >= 80) { f = fnt_title; fpx = 96; }
    else if (want >= 33) { f = fnt_h1; fpx = 40; }
    else if (want >= 24) { f = fnt_h2; fpx = 27; }
    else if (want >= 19.5) { f = fnt_h3; fpx = 21; }
    else if (want >= 17.5) { f = fnt_bold; fpx = 17; }
    else if (want < 16) { f = fnt_small; fpx = 15; }
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
/// @desc Word-wraps text to max_w using the current font and keeps at most max_lines lines (the last one ends in "...")
function ui_wrap_clamp(str, max_w, max_lines) {
    var words = string_split(str, " ");
    var lines = [];
    var cur = "";
    for (var i = 0; i < array_length(words); i++) {
        var wd = words[i];
        if (wd == "") continue;
        var test = (cur == "") ? wd : (cur + " " + wd);
        if (string_width(test) <= max_w || cur == "") cur = test;
        else { array_push(lines, cur); cur = wd; }
    }
    if (cur != "") array_push(lines, cur);
    if (array_length(lines) > max_lines) {
        var last = lines[max_lines - 1] + " " + lines[max_lines];
        array_resize(lines, max_lines);
        lines[max_lines - 1] = ui_fit_text(last, max_w);
    }
    var out = "";
    for (var i = 0; i < array_length(lines); i++) out += ((i > 0) ? "\n" : "") + ui_fit_text(lines[i], max_w);
    return out;
}

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
    // Top sheen: soft vertical gradient (no hard edge)
    if (y2 - y1 > 14) {
        var sh = min(22, (y2 - y1) * 0.55);
        var inset = r * 0.35;
        draw_primitive_begin(pr_trianglestrip);
        draw_vertex_color(x1 + inset, y1 + 1, c_white, a0 * alpha * 0.07);
        draw_vertex_color(x2 - inset, y1 + 1, c_white, a0 * alpha * 0.07);
        draw_vertex_color(x1 + 1, y1 + sh, c_white, 0);
        draw_vertex_color(x2 - 1, y1 + sh, c_white, 0);
        draw_primitive_end();
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

/// @desc Weapon emblem icon. Every weapon has its own silhouette and palette.
/// Pass C_WEAPON for the full-colour version; any other colour draws a muted (spent / unavailable) version tinted with it.
function ui_icon_weapon(wx, wy, catalog_id, size, col) {
    var s = size * 0.5;
    var live = (col == C_WEAPON);
    var a0 = draw_get_alpha();
    var mt   = ui_wi_tone(make_color_rgb(150, 162, 180), live, col);
    var mt_d = ui_wi_tone(make_color_rgb(66, 76, 94), live, col);
    var mt_l = ui_wi_tone(make_color_rgb(214, 222, 234), live, col);
    var ink  = ui_wi_tone(make_color_rgb(18, 22, 30), live, col);
    switch (catalog_id) {
        case "turret": {
            var ac = ui_wi_tone(make_color_rgb(0, 229, 255), live, col);
            ui_wi_base(wx, wy, s, mt_d, mt);
            ui_wi_rrect(wx, wy, s, -0.6, -0.34, 0.18, 0.44, 0.18, mt);
            ui_wi_rect(wx, wy, s, -0.48, 0.16, 0.06, 0.24, mt_d);
            ui_wi_rect(wx, wy, s, 0.14, -0.22, 0.92, -0.07, mt_l);
            ui_wi_rect(wx, wy, s, 0.14, 0.07, 0.92, 0.22, mt_l);
            ui_wi_rect(wx, wy, s, 0.82, -0.27, 0.98, -0.02, mt_d);
            ui_wi_rect(wx, wy, s, 0.82, 0.02, 0.98, 0.27, mt_d);
            ui_wi_circ(wx, wy, s, -0.3, -0.1, 0.1, ac);
            break;
        }
        case "gatling_gun": {
            var brass = ui_wi_tone(make_color_rgb(255, 196, 64), live, col);
            ui_wi_base(wx, wy, s, mt_d, mt);
            ui_wi_circ(wx, wy, s, -0.4, 0.05, 0.38, mt);
            ui_wi_circ(wx, wy, s, -0.4, 0.05, 0.17, mt_d);
            ui_wi_line(wx, wy, s, -0.12, -0.17, 0.96, -0.17, 0.11, mt_l);
            ui_wi_line(wx, wy, s, -0.12, 0.03, 0.96, 0.03, 0.11, mt_l);
            ui_wi_line(wx, wy, s, -0.12, 0.23, 0.96, 0.23, 0.11, mt_l);
            ui_wi_rect(wx, wy, s, 0.2, -0.3, 0.3, 0.36, mt_d);
            ui_wi_rect(wx, wy, s, 0.74, -0.3, 0.82, 0.36, mt_d);
            for (var b = 0; b < 4; b++) ui_wi_rect(wx, wy, s, -0.86 + b * 0.13, 0.3 - b * 0.05, -0.79 + b * 0.13, 0.46 - b * 0.05, brass);
            break;
        }
        case "cannon": {
            var ac = ui_wi_tone(make_color_rgb(255, 140, 60), live, col);
            ui_wi_base(wx, wy, s, mt_d, mt);
            ui_wi_line(wx, wy, s, -0.2, 0.12, 0.72, -0.5, 0.4, mt_l);
            ui_wi_circ(wx, wy, s, 0.72, -0.5, 0.25, mt_d);
            ui_wi_circ(wx, wy, s, 0.72, -0.5, 0.12, ink);
            ui_wi_circ(wx, wy, s, -0.22, 0.16, 0.42, mt_d);
            ui_wi_circ(wx, wy, s, -0.22, 0.16, 0.3, mt);
            ui_wi_circ(wx, wy, s, -0.22, 0.16, 0.1, ac);
            break;
        }
        case "makeshift_cannon": {
            var wood   = ui_wi_tone(make_color_rgb(168, 116, 64), live, col);
            var wood_d = ui_wi_tone(make_color_rgb(98, 64, 34), live, col);
            var rope   = ui_wi_tone(make_color_rgb(224, 190, 128), live, col);
            var stone  = ui_wi_tone(make_color_rgb(140, 136, 130), live, col);
            ui_wi_rect(wx, wy, s, -0.8, 0.52, 0.8, 0.8, wood_d);
            ui_wi_line(wx, wy, s, -0.8, 0.66, 0.8, 0.66, 0.04, wood);
            ui_wi_circ(wx, wy, s, -0.52, 0.4, 0.18, stone);
            ui_wi_circ(wx, wy, s, 0.5, 0.42, 0.16, stone);
            ui_wi_line(wx, wy, s, -0.5, 0.28, 0.7, -0.34, 0.36, wood);
            // rope lashings across the barrel
            for (var k = 0; k < 2; k++) {
                var bx = lerp(-0.5, 0.7, 0.3 + k * 0.4), by = lerp(0.28, -0.34, 0.3 + k * 0.4);
                ui_wi_line(wx, wy, s, bx - 0.1, by - 0.2, bx + 0.1, by + 0.2, 0.09, rope);
            }
            ui_wi_circ(wx, wy, s, 0.72, -0.35, 0.15, wood_d);
            ui_wi_circ(wx, wy, s, 0.72, -0.35, 0.08, ink);
            break;
        }
        case "plasma_mortar": {
            var ac = ui_wi_tone(make_color_rgb(200, 80, 255), live, col);
            ui_wi_base(wx, wy, s, mt_d, mt);
            ui_wi_line(wx, wy, s, -0.05, 0.12, 0.3, -0.6, 0.46, mt_l);
            ui_wi_ell(wx, wy, s, 0.06, -0.74, 0.54, -0.5, mt_d);
            ui_wi_rrect(wx, wy, s, -0.58, -0.02, 0.48, 0.48, 0.12, mt);
            for (var v = 0; v < 3; v++) ui_wi_rect(wx, wy, s, -0.44 + v * 0.22, 0.14, -0.34 + v * 0.22, 0.34, ac);
            draw_set_alpha(a0 * 0.35);
            ui_wi_circ(wx, wy, s, 0.36, -0.82, 0.28, ac);
            draw_set_alpha(a0);
            ui_wi_circ(wx, wy, s, 0.36, -0.82, 0.16, ac);
            break;
        }
        case "railgun": {
            var ac = ui_wi_tone(make_color_rgb(120, 230, 255), live, col);
            ui_wi_base(wx, wy, s, mt_d, mt);
            ui_wi_rrect(wx, wy, s, -0.9, -0.2, -0.22, 0.42, 0.1, mt);
            ui_wi_rect(wx, wy, s, -0.26, -0.26, 1.0, -0.14, mt_l);
            ui_wi_rect(wx, wy, s, -0.26, 0.14, 1.0, 0.26, mt_l);
            draw_set_alpha(a0 * 0.6);
            ui_wi_line(wx, wy, s, -0.22, 0, 1.0, 0, 0.06, ac);
            draw_set_alpha(a0);
            for (var c = 0; c < 3; c++) ui_wi_rect(wx, wy, s, 0.02 + c * 0.3, -0.14, 0.1 + c * 0.3, 0.14, ac);
            ui_wi_circ(wx, wy, s, -0.56, 0.1, 0.12, ac);
            break;
        }
        case "lazer_gun": {
            var ac = ui_wi_tone(make_color_rgb(255, 70, 90), live, col);
            ui_wi_base(wx, wy, s, mt_d, mt);
            ui_wi_tri(wx, wy, s, -0.5, -0.18, -0.05, -0.18, -0.35, -0.42, mt_d);
            ui_wi_rrect(wx, wy, s, -0.75, -0.2, 0.42, 0.24, 0.2, mt);
            ui_wi_line(wx, wy, s, -0.6, 0.02, 0.3, 0.02, 0.06, ac);
            ui_wi_tri(wx, wy, s, 0.38, -0.26, 0.38, 0.3, 0.7, 0.02, mt_l);
            draw_set_alpha(a0 * 0.35);
            ui_wi_circ(wx, wy, s, 0.74, 0.02, 0.24, ac);
            draw_set_alpha(a0);
            ui_wi_circ(wx, wy, s, 0.74, 0.02, 0.12, ac);
            ui_wi_line(wx, wy, s, 0.8, 0.02, 1.05, 0.02, 0.06, ac);
            break;
        }
        case "flamethrower": {
            var tank  = ui_wi_tone(make_color_rgb(205, 72, 52), live, col);
            var fl_o  = ui_wi_tone(make_color_rgb(255, 130, 30), live, col);
            var fl_y  = ui_wi_tone(make_color_rgb(255, 222, 90), live, col);
            ui_wi_base(wx, wy, s, mt_d, mt);
            ui_wi_rrect(wx, wy, s, -0.86, -0.4, -0.38, 0.46, 0.22, tank);
            ui_wi_rect(wx, wy, s, -0.72, -0.5, -0.52, -0.38, mt_d);
            ui_wi_line(wx, wy, s, -0.62, 0.1, -0.62, 0.32, 0.05, mt_l);
            ui_wi_rect(wx, wy, s, -0.4, -0.07, 0.34, 0.13, mt_l);
            ui_wi_rect(wx, wy, s, 0.28, -0.13, 0.42, 0.19, mt_d);
            ui_wi_tri(wx, wy, s, 0.42, -0.26, 0.42, 0.32, 1.02, 0.03, fl_o);
            ui_wi_tri(wx, wy, s, 0.42, -0.12, 0.42, 0.18, 0.8, 0.03, fl_y);
            break;
        }
        case "tesla": {
            var ac  = ui_wi_tone(make_color_rgb(120, 220, 255), live, col);
            var cop = ui_wi_tone(make_color_rgb(214, 136, 72), live, col);
            ui_wi_rect(wx, wy, s, -0.38, 0.58, 0.38, 0.82, mt_d);
            ui_wi_rect(wx, wy, s, -0.08, -0.3, 0.08, 0.6, mt_d);
            var ws = [0.5, 0.44, 0.38, 0.32];
            for (var r = 0; r < 4; r++) ui_wi_ell(wx, wy, s, -ws[r], 0.42 - r * 0.2, ws[r], 0.56 - r * 0.2, (r % 2 == 0) ? cop : mt_d);
            ui_wi_circ(wx, wy, s, 0, -0.46, 0.27, mt_l);
            ui_wi_circ(wx, wy, s, -0.08, -0.54, 0.08, c_white);
            ui_wi_line(wx, wy, s, -0.26, -0.5, -0.48, -0.32, 0.06, ac);
            ui_wi_line(wx, wy, s, -0.48, -0.32, -0.64, -0.62, 0.06, ac);
            ui_wi_line(wx, wy, s, -0.64, -0.62, -0.92, -0.44, 0.06, ac);
            ui_wi_line(wx, wy, s, 0.26, -0.5, 0.48, -0.32, 0.06, ac);
            ui_wi_line(wx, wy, s, 0.48, -0.32, 0.64, -0.62, 0.06, ac);
            ui_wi_line(wx, wy, s, 0.64, -0.62, 0.92, -0.44, 0.06, ac);
            break;
        }
        case "overcharge_pylon": {
            var ac = ui_wi_tone(make_color_rgb(255, 214, 60), live, col);
            ui_wi_rect(wx, wy, s, -0.48, 0.58, 0.48, 0.82, mt_d);
            ui_wi_tri(wx, wy, s, -0.34, 0.58, 0.34, 0.58, 0.18, -0.58, mt);
            ui_wi_tri(wx, wy, s, -0.34, 0.58, 0.18, -0.58, -0.18, -0.58, mt);
            ui_wi_tri(wx, wy, s, -0.18, -0.58, 0.18, -0.58, 0, -0.95, ac);
            for (var ch = 0; ch < 2; ch++) {
                var cy2 = 0.36 - ch * 0.36;
                ui_wi_line(wx, wy, s, -0.18, cy2, 0, cy2 - 0.18, 0.08, ac);
                ui_wi_line(wx, wy, s, 0, cy2 - 0.18, 0.18, cy2, 0.08, ac);
            }
            ui_wi_line(wx, wy, s, 0.5, -0.5, 0.72, -0.72, 0.05, ac);
            ui_wi_line(wx, wy, s, -0.5, -0.5, -0.72, -0.72, 0.05, ac);
            break;
        }
        case "energy_pylon": {
            var ac = ui_wi_tone(make_color_rgb(100, 240, 140), live, col);
            ui_wi_rect(wx, wy, s, -0.16, -0.78, 0.16, -0.6, mt_l);
            ui_wi_rrect(wx, wy, s, -0.44, -0.62, 0.44, 0.8, 0.14, mt_d);
            ui_wi_rect(wx, wy, s, -0.32, -0.5, 0.32, 0.68, ink);
            ui_wi_rect(wx, wy, s, -0.32, 0.02, 0.32, 0.68, ac);
            ui_wi_tri(wx, wy, s, 0.12, -0.44, -0.22, 0.12, 0.06, 0.06, c_white);
            ui_wi_tri(wx, wy, s, -0.06, -0.02, 0.22, -0.08, -0.12, 0.6, c_white);
            break;
        }
        case "cryo_emitter": {
            var ac = ui_wi_tone(make_color_rgb(150, 232, 255), live, col);
            for (var arm = 0; arm < 6; arm++) {
                var ang = arm * 60 + 90;
                var ex = lengthdir_x(0.82, ang), ey = lengthdir_y(0.82, ang);
                ui_wi_line(wx, wy, s, 0, 0, ex, ey, 0.1, ac);
                var mx2 = lengthdir_x(0.5, ang), my2 = lengthdir_y(0.5, ang);
                ui_wi_line(wx, wy, s, mx2, my2, mx2 + lengthdir_x(0.24, ang + 45), my2 + lengthdir_y(0.24, ang + 45), 0.07, ac);
                ui_wi_line(wx, wy, s, mx2, my2, mx2 + lengthdir_x(0.24, ang - 45), my2 + lengthdir_y(0.24, ang - 45), 0.07, ac);
            }
            ui_wi_circ(wx, wy, s, 0, 0, 0.22, mt_l);
            ui_wi_circ(wx, wy, s, 0, 0, 0.11, ac);
            break;
        }
        case "shield_generator": {
            var ac = ui_wi_tone(make_color_rgb(90, 170, 255), live, col);
            var ac_d = ui_wi_tone(make_color_rgb(34, 70, 130), live, col);
            // heater shield: rounded top, pointed bottom
            ui_wi_rrect(wx, wy, s, -0.72, -0.82, 0.72, 0.1, 0.22, mt_d);
            ui_wi_tri(wx, wy, s, -0.72, 0.0, 0.72, 0.0, 0, 0.9, mt_d);
            ui_wi_rrect(wx, wy, s, -0.6, -0.7, 0.6, 0.06, 0.16, ac);
            ui_wi_tri(wx, wy, s, -0.6, -0.02, 0.6, -0.02, 0, 0.74, ac);
            ui_wi_rrect(wx, wy, s, -0.6, -0.7, 0.0, 0.06, 0.16, ac_d);
            ui_wi_tri(wx, wy, s, -0.6, -0.02, 0.0, -0.02, 0, 0.74, ac_d);
            // energy core
            draw_set_alpha(a0 * 0.4);
            ui_wi_circ(wx, wy, s, 0, -0.16, 0.3, c_white);
            draw_set_alpha(a0);
            ui_wi_circ(wx, wy, s, 0, -0.16, 0.16, mt_l);
            break;
        }
        case "resource_drone": {
            var crate = ui_wi_tone(make_color_rgb(196, 146, 80), live, col);
            var crate_d = ui_wi_tone(make_color_rgb(120, 84, 40), live, col);
            var ac = ui_wi_tone(make_color_rgb(100, 240, 140), live, col);
            ui_wi_line(wx, wy, s, -0.74, -0.42, 0.74, -0.42, 0.09, mt_d);
            ui_wi_rect(wx, wy, s, -0.78, -0.56, -0.7, -0.42, mt_d);
            ui_wi_rect(wx, wy, s, 0.7, -0.56, 0.78, -0.42, mt_d);
            draw_set_alpha(a0 * 0.85);
            ui_wi_ell(wx, wy, s, -1.0, -0.64, -0.48, -0.52, mt_l);
            ui_wi_ell(wx, wy, s, 0.48, -0.64, 1.0, -0.52, mt_l);
            draw_set_alpha(a0);
            ui_wi_rrect(wx, wy, s, -0.36, -0.54, 0.36, -0.14, 0.14, mt);
            ui_wi_circ(wx, wy, s, 0, -0.34, 0.09, ac);
            ui_wi_line(wx, wy, s, -0.18, -0.14, -0.3, 0.18, 0.07, mt_d);
            ui_wi_line(wx, wy, s, 0.18, -0.14, 0.3, 0.18, 0.07, mt_d);
            ui_wi_rect(wx, wy, s, -0.32, 0.16, 0.32, 0.74, crate);
            ui_wi_line(wx, wy, s, -0.32, 0.16, 0.32, 0.74, 0.05, crate_d);
            ui_wi_line(wx, wy, s, 0.32, 0.16, -0.32, 0.74, 0.05, crate_d);
            break;
        }
        default: {
            ui_wi_base(wx, wy, s, mt_d, mt);
            ui_wi_rrect(wx, wy, s, -0.6, -0.25, 0.6, 0.35, 0.15, mt);
            ui_wi_rect(wx, wy, s, 0.5, -0.06, 0.95, 0.12, mt_l);
        }
    }
    draw_set_alpha(a0);
}

/// @desc Icon colour: full colour when live, otherwise a muted tint of the given colour
function ui_wi_tone(rgb, live, col) {
    return live ? rgb : merge_color(col, rgb, 0.22);
}
/// @desc Gun mount shared by the turret-style weapons
function ui_wi_base(wx, wy, s, c_dark, c_mid) {
    ui_wi_tri(wx, wy, s, -0.64, 0.84, 0.64, 0.84, 0.42, 0.5, c_dark);
    ui_wi_tri(wx, wy, s, -0.64, 0.84, 0.42, 0.5, -0.42, 0.5, c_dark);
    ui_wi_rect(wx, wy, s, -0.48, 0.44, 0.48, 0.54, c_mid);
}
function ui_wi_rect(wx, wy, s, x1, y1, x2, y2, c) {
    draw_set_color(c);
    draw_rectangle(wx + x1 * s, wy + y1 * s, wx + x2 * s, wy + y2 * s, false);
}
function ui_wi_rrect(wx, wy, s, x1, y1, x2, y2, r, c) {
    draw_set_color(c);
    draw_roundrect_ext(wx + x1 * s, wy + y1 * s, wx + x2 * s, wy + y2 * s, r * s * 2, r * s * 2, false);
}
function ui_wi_circ(wx, wy, s, cx, cy, r, c) {
    draw_set_color(c);
    draw_circle(wx + cx * s, wy + cy * s, max(1, r * s), false);
}
function ui_wi_ell(wx, wy, s, x1, y1, x2, y2, c) {
    draw_set_color(c);
    draw_ellipse(wx + x1 * s, wy + y1 * s, wx + x2 * s, wy + y2 * s, false);
}
function ui_wi_line(wx, wy, s, x1, y1, x2, y2, w, c) {
    draw_set_color(c);
    draw_line_width(wx + x1 * s, wy + y1 * s, wx + x2 * s, wy + y2 * s, max(1, w * s));
}
function ui_wi_tri(wx, wy, s, x1, y1, x2, y2, x3, y3, c) {
    draw_set_color(c);
    draw_triangle(wx + x1 * s, wy + y1 * s, wx + x2 * s, wy + y2 * s, wx + x3 * s, wy + y3 * s, false);
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

/// @desc Autotest only: every weapon icon at the sizes the game uses, live and muted
function ui_draw_weapon_icon_gallery() {
    draw_set_color(C_BG1);
    draw_rectangle(0, 0, 1920, 1080, false);
    var cat = game_get_weapon_catalog();
    var ids = [], names = [];
    for (var i = 0; i < array_length(cat); i++) { array_push(ids, cat[i].id); array_push(names, cat[i].name); }
    array_push(ids, "makeshift_cannon"); array_push(names, "Makeshift Cannon");
    var cols = 5;
    for (var i = 0; i < array_length(ids); i++) {
        var cx = 40 + (i mod cols) * 376, cy = 30 + (i div cols) * 345;
        ui_box(cx, cy, cx + 356, cy + 325, C_PANEL, C_LINE, 10);
        ui_icon_weapon(cx + 110, cy + 120, ids[i], 150, C_WEAPON);
        ui_icon_weapon(cx + 270, cy + 80, ids[i], 50, C_WEAPON);
        ui_icon_weapon(cx + 270, cy + 160, ids[i], 50, C_FAINT);
        ui_icon_weapon(cx + 250, cy + 230, ids[i], 18, C_WEAPON);
        ui_icon_weapon(cx + 290, cy + 230, ids[i], 16, C_WEAPON);
        draw_set_font(fnt_h3);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(C_TEXT);
        draw_text(cx + 178, cy + 290, names[i]);
    }
}
