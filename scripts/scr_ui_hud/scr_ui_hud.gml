/// @desc In-game HUD: top bar, animated tactical map, base status, comms log, operative panel,
/// storage, action bar, threat lanes, banners, toasts, tooltips, pause & help overlays.

/// @desc Shared layout constants (used by drawing AND input so hit boxes always match)
function ui_hud_layout() {
    static L = {
        top_h: 58,
        board_x1: 20, board_y1: 70, board_x2: 1500, board_y2: 636,
        right_x: 1516, right_x2: 1900,
        status_y1: 70, status_y2: 384,
        log_y1: 394, log_y2: 636,
        bottom_y: 650,
        op_x1: 20, op_x2: 548, op_y1: 650, op_y2: 762,
        res_x1: 560, res_x2: 1232,
        act_x1: 1244, act_x2: 1900,
        lane_in_y1: 774, lane_in_y2: 900,
        lane_act_y1: 910, lane_act_y2: 1066,
        lane_label_w: 128,
        card_w: 150, card_step: 160
    };
    return L;
}

// =============================================================================
// TOP BAR
// =============================================================================
function ui_draw_hud_top(state, mx, my) {
    var L = ui_hud_layout();
    // Bar background
    draw_set_color(C_BG1);
    draw_rectangle(0, 0, 1920, L.top_h, false);
    draw_set_alpha(0.5);
    draw_set_color(C_ACCENT_D);
    draw_line_width(0, L.top_h, 1920, L.top_h, 2);
    draw_set_alpha(1);

    // Day / wave badge
    var in_combat = (state.phase == "combat_weapons" || state.phase == "combat_aliens");
    var day_col = in_combat ? C_BAD : C_ACCENT;
    ui_box(20, 9, 210, 49, C_PANEL, day_col, 8);
    draw_set_font(fnt_small);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_FAINT);
    draw_text(34, 20, state.endless_mode && state.round_number > 17 ? "ENDLESS" : "DAY");
    draw_set_font(fnt_h2);
    draw_set_color(C_TEXT);
    var day_str = string(state.round_number);
    draw_text(34, 37, day_str);
    var dw = string_width(day_str);
    draw_set_font(fnt_bold);
    draw_set_color(C_FAINT);
    if (!(state.endless_mode && state.round_number > 17)) draw_text(38 + dw, 39, "/ 17");
    // Phase chip
    var phase_lbl = "PLANNING";
    var phase_col = C_ACCENT;
    if (state.phase == "combat_weapons") { phase_lbl = "DEFENSE"; phase_col = C_WARN; }
    else if (state.phase == "combat_aliens") { phase_lbl = "UNDER ATTACK"; phase_col = C_BAD; }
    else if (state.phase == "game_over") { phase_lbl = "OVERRUN"; phase_col = C_BAD; }
    else if (state.phase == "victory") { phase_lbl = "VICTORY"; phase_col = C_GOOD; }
    draw_set_font(fnt_small);
    var pw = string_width(phase_lbl) + 18;
    var pulse = in_combat ? (0.5 + 0.5 * sin(current_time * 0.008)) : 0;
    ui_box(200 - pw, 17, 200, 41, ui_col_mix(merge_color(phase_col, c_black, 0.75), merge_color(phase_col, c_black, 0.55), pulse), phase_col, 12);
    draw_set_halign(fa_center);
    draw_set_color(phase_col);
    draw_text(200 - pw * 0.5, 29, phase_lbl);

    // Squad chips
    var local_idx = game_local_player_idx(state);
    var cx = 232;
    state.player_tab_bounds = [];
    for (var p = 0; p < state.num_players; p++) {
        var pl = state.players[p];
        var is_me = (p == local_idx);
        var offline = pl[$ "disconnected"] ?? false;
        var done = state.is_online && pl.ended_turn && state.phase == "player_actions";
        draw_set_font(fnt_bold);
        var nw = string_width(pl.name);
        var chip_w = max(170, nw + 92);
        var hov = !state.is_online && ui_point_in_rect(mx, my, cx, 8, chip_w, 42);
        array_push(state.player_tab_bounds, [cx, cx + chip_w]);
        var a_key = "chip" + string(p);
        var hl = ui_anim(a_key, (is_me ? 1 : 0), 0.2);
        var fill = ui_col_mix(C_PANEL, merge_color(pl.color, C_PANEL, 0.72), hl);
        ui_box(cx, 8, cx + chip_w, 50, hov ? ui_col_mix(fill, C_HOVER, 0.5) : fill, is_me ? pl.color : C_LINE, 8);
        // color stripe + emblem
        draw_set_color(pl.color);
        draw_roundrect_ext(cx + 3, 12, cx + 7, 46, 2, 2, false);
        ui_draw_operative_token(cx + 30, 29, pl, p, 13, false);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(offline ? C_FAINT : (is_me ? c_white : C_DIM));
        draw_text(cx + 50, 21, pl.name);
        // energy pips
        var pip_x = cx + 50;
        var max_e = max(1, pl.max_energy);
        var pip_w = clamp(floor((chip_w - 62) / max_e) - 2, 3, 12);
        for (var e = 0; e < max_e; e++) {
            draw_set_color(e < pl.energy ? C_ENERGY : make_color_rgb(44, 50, 64));
            draw_roundrect_ext(pip_x + e * (pip_w + 2), 35, pip_x + e * (pip_w + 2) + pip_w, 41, 2, 2, false);
        }
        if (offline || done) {
            draw_set_font(fnt_small);
            var tag = offline ? "OFFLINE" : "READY";
            draw_set_halign(fa_right);
            draw_set_color(offline ? C_BAD : C_GOOD);
            draw_text(cx + chip_w - 8, 21, tag);
        }
        if (hov) state.hover_tooltip = "Switch control to " + pl.name + "  [" + string(p + 1) + "] / [Tab]";
        cx += chip_w + 8;
    }

    // Right: gold + menu
    var menu_w = 116;
    var menu_x = 1900 - menu_w;
    state.btn_settings_hover = ui_draw_button(menu_x, 11, menu_w, 36, "MENU", true, false, mx, my, "ghost", "Esc");
    var g_w = 150;
    var g_x = menu_x - 12 - g_w;
    ui_box(g_x, 11, g_x + g_w, 47, C_PANEL, C_LINE, 8);
    ui_icon_resource(g_x + 22, 29, "gold", 20);
    draw_set_font(fnt_h3);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_GOLD);
    var gold_disp = round(ui_anim("gold_disp", state.storage.gold, 0.15));
    draw_text(g_x + 40, 28, string(gold_disp));
    draw_set_font(fnt_small);
    draw_set_color(C_FAINT);
    draw_set_halign(fa_right);
    draw_text(g_x + g_w - 10, 29, "TEAM GOLD");
    if (ui_point_in_rect(mx, my, g_x, 11, g_w, 36)) state.hover_tooltip = "Team Gold - spend it on weapon blueprints at the Shop.";

    // Online connection badge
    if (state.is_online) {
        var nb_w = 130;
        var nb_x = g_x - 12 - nb_w;
        if (nb_x > cx) {
            ui_box(nb_x, 11, nb_x + nb_w, 47, C_PANEL, C_LINE, 8);
            var lag = state.is_host ? 0 : state.net_pending_requests;
            draw_set_color(lag > 2 ? C_WARN : C_GOOD);
            draw_circle(nb_x + 16, 29, 5, false);
            draw_set_font(fnt_small);
            draw_set_halign(fa_left);
            draw_set_color(C_DIM);
            draw_text(nb_x + 28, 22, state.is_host ? "HOSTING" : "CONNECTED");
            draw_set_color(C_FAINT);
            draw_text(nb_x + 28, 37, "Local network");
        }
    }
    draw_set_font(fnt_body);
}

/// @desc Small round operative token with class emblem (used on board & HUD)
function ui_draw_operative_token(tx, ty, pl, p_idx, r, big = false) {
    var offline = pl[$ "disconnected"] ?? false;
    var col = offline ? make_color_rgb(90, 96, 110) : pl.color;
    draw_set_color(c_black);
    draw_set_alpha(0.5);
    draw_circle(tx, ty + 2, r + 2, false);
    draw_set_alpha(1);
    draw_set_color(merge_color(col, c_black, 0.55));
    draw_circle(tx, ty, r + 1, false);
    draw_set_color(col);
    draw_circle(tx, ty, r, false);
    draw_set_color(merge_color(col, c_white, 0.35));
    draw_circle(tx - r * 0.3, ty - r * 0.35, r * 0.35, false);
    // number
    draw_set_font(r >= 12 ? fnt_bold : fnt_small);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(10, 12, 18));
    draw_text(tx, ty, string(p_idx + 1));
    draw_set_color(c_white);
    draw_circle(tx, ty, r, true);
    draw_set_font(fnt_body);
}

// =============================================================================
// TACTICAL MAP
// =============================================================================
function ui_draw_board(state, mx, my) {
    var L = ui_hud_layout();
    var t = current_time / 1000;
    var bx1 = L.board_x1, by1 = L.board_y1, bx2 = L.board_x2, by2 = L.board_y2;
    var local_idx = game_local_player_idx(state);
    var cur_player = state.players[local_idx];
    var can_act = (state.phase == "player_actions") && !(state.is_online && cur_player.ended_turn);

    // Frame + terrain base
    ui_shadow(bx1, by1, bx2, by2, 14, 0.4);
    ui_box(bx1, by1, bx2, by2, make_color_rgb(11, 16, 24), C_LINE, 14);

    // Subtle animated grid
    draw_set_alpha(0.05);
    draw_set_color(C_ACCENT);
    var off = (t * 8) mod 40;
    for (var gx = bx1 + 20 + off; gx < bx2 - 10; gx += 40) draw_line(gx, by1 + 6, gx, by2 - 6);
    for (var gy = by1 + 20; gy < by2 - 10; gy += 40) draw_line(bx1 + 6, gy, bx2 - 6, gy);
    draw_set_alpha(1);
    // Radar sweep line
    var sweep_x = bx1 + ((t * 90) mod (bx2 - bx1));
    for (var sw = 0; sw < 6; sw++) {
        draw_set_alpha(0.035 * (6 - sw) / 6);
        draw_set_color(C_ACCENT);
        draw_rectangle(sweep_x - sw * 6 - 6, by1 + 2, sweep_x - sw * 6, by2 - 2, false);
    }
    draw_set_alpha(1);

    // Terrain zones (soft glows + labels)
    ui_board_zone(32, 84, 280, 316, make_color_rgb(40, 120, 60), "FOREST", "Wood & Scrap", t);
    ui_board_zone(32, 392, 280, 624, make_color_rgb(190, 90, 140), "TOWN", "Sell for Gold", t);
    ui_board_zone(1160, 84, 1488, 624, make_color_rgb(130, 90, 70), "THE CAVERNS", "Stone, Metal, Crystals, Gems", t);
    // Base compound glow
    var mb = state.nodes.main_base;
    ui_glow(mb.x, mb.y, 260, make_color_rgb(20, 80, 160), 0.18);

    // Base perimeter wall between towers
    var t1 = state.nodes.tower_1, t2 = state.nodes.tower_2, t3 = state.nodes.tower_3, t4 = state.nodes.tower_4;
    draw_set_alpha(0.45);
    draw_set_color(C_TOWER);
    draw_line_width(t1.x, t1.y, t2.x, t2.y, 4);
    draw_line_width(t2.x, t2.y, t3.x, t3.y, 4);
    draw_line_width(t3.x, t3.y, t4.x, t4.y, 4);
    draw_line_width(t4.x, t4.y, t1.x, t1.y, 4);
    draw_set_alpha(1);

    // Hovered node (for path preview)
    var hover_key = "";
    var node_keys = variable_struct_get_names(state.nodes);
    for (var i = 0; i < array_length(node_keys); i++) {
        var n = state.nodes[$ node_keys[i]];
        if (point_in_circle(mx, my, n.x, n.y, 36)) hover_key = node_keys[i];
    }
    state.board_hover_node = hover_key;

    // Edges
    for (var i = 0; i < array_length(state.edges); i++) {
        var edge = state.edges[i];
        var n1 = state.nodes[$ edge[0]];
        var n2 = state.nodes[$ edge[1]];
        var from_me = (edge[0] == cur_player.node) ? edge[1] : ((edge[1] == cur_player.node) ? edge[0] : "");
        var reachable = can_act && (from_me != "") && game_player_can_move(state, cur_player, from_me);
        if (reachable) {
            var hot = (hover_key == from_me);
            draw_set_color(hot ? C_ENERGY : C_ACCENT);
            draw_set_alpha(hot ? 0.9 : 0.55);
            draw_line_width(n1.x, n1.y, n2.x, n2.y, hot ? 5 : 3);
            draw_set_alpha(1);
            // flowing dashes away from the player
            var pa = (edge[0] == cur_player.node) ? n1 : n2;
            var pb = (edge[0] == cur_player.node) ? n2 : n1;
            var len = point_distance(pa.x, pa.y, pb.x, pb.y);
            var dir = point_direction(pa.x, pa.y, pb.x, pb.y);
            draw_set_color(c_white);
            for (var d = ((t * 90) mod 26); d < len; d += 26) {
                var dx1 = pa.x + lengthdir_x(d, dir), dy1 = pa.y + lengthdir_y(d, dir);
                var dx2 = pa.x + lengthdir_x(min(len, d + 8), dir), dy2 = pa.y + lengthdir_y(min(len, d + 8), dir);
                draw_line_width(dx1, dy1, dx2, dy2, 2);
            }
        } else {
            draw_set_color(make_color_rgb(40, 66, 98));
            draw_line_width(n1.x, n1.y, n2.x, n2.y, 3);
        }
    }

    // Nodes
    for (var i = 0; i < array_length(node_keys); i++) {
        var k = node_keys[i];
        var node = state.nodes[$ k];
        var is_here = (cur_player.node == k);
        var can_move_here = can_act && game_player_can_move(state, cur_player, k);
        var hovered = (hover_key == k);
        var big = (node.type == "main_base" || node.type == "tower");
        var nrad = big ? 32 : 27;
        if (node.type == "empty") nrad = 18;
        var lift = ui_anim("node" + k, hovered ? 1 : 0, 0.25);
        var r = nrad + lift * 3;
        var tower = (node.type == "tower") ? state.towers[node.tower_idx] : undefined;
        var dead = !is_undefined(tower) && !tower.alive;
        var ncol = dead ? make_color_rgb(70, 60, 66) : node.color;

        if (can_move_here) {
            var pulse = 0.5 + 0.5 * sin(current_time * 0.006 + i);
            ui_glow(node.x, node.y, r + 20, C_ACCENT, 0.25 + pulse * 0.2);
        }
        if (is_here) ui_glow(node.x, node.y, r + 26, cur_player.color, 0.35);

        // Disc: shadow, outer ring, plate
        draw_set_color(c_black); draw_set_alpha(0.45);
        draw_circle(node.x + 2, node.y + 5, r + 2, false);
        draw_set_alpha(1);
        draw_set_color(merge_color(ncol, c_black, 0.35));
        draw_circle(node.x, node.y, r + 3, false);
        draw_set_color(merge_color(ncol, make_color_rgb(10, 14, 22), 0.62));
        draw_circle(node.x, node.y, r, false);
        draw_set_color(merge_color(ncol, c_white, 0.15));
        draw_circle(node.x, node.y, r, true);
        draw_circle(node.x, node.y, r - 1, true);

        // Tower HP arc
        if (!is_undefined(tower) && tower.alive) {
            var frac_hp = clamp(tower.hp / tower.max_hp, 0, 1);
            var arc_col = (frac_hp > 0.5) ? C_TOWER : ((frac_hp > 0.25) ? C_WARN : C_BAD);
            draw_set_color(make_color_rgb(20, 30, 44));
            for (var aa = 0; aa < 360; aa += 10) draw_line_width(node.x + lengthdir_x(r + 7, aa + 90), node.y + lengthdir_y(r + 7, aa + 90), node.x + lengthdir_x(r + 7, aa + 98), node.y + lengthdir_y(r + 7, aa + 98), 4);
            draw_set_color(arc_col);
            for (var aa = 0; aa < 360 * frac_hp; aa += 10) draw_line_width(node.x + lengthdir_x(r + 7, 90 - aa), node.y + lengthdir_y(r + 7, 90 - aa), node.x + lengthdir_x(r + 7, 90 - aa - 8), node.y + lengthdir_y(r + 7, 90 - aa - 8), 4);
        }

        // Structure icon
        if (dead) {
            draw_set_color(C_BAD);
            draw_line_width(node.x - 12, node.y - 12, node.x + 12, node.y + 12, 4);
            draw_line_width(node.x - 12, node.y + 12, node.x + 12, node.y - 12, 4);
        } else {
            ui_icon_node(node.x, node.y - lift * 2, node.type, r * 0.95, ncol, t);
        }

        // Reachable ring + cost tag
        if (can_move_here && !is_here) {
            var pr = r + 10 + sin(current_time * 0.007) * 2;
            draw_set_color(hovered ? C_ENERGY : C_ACCENT);
            draw_circle(node.x, node.y, pr, true);
            var m_cost = game_player_get_move_cost(cur_player);
            var tag = string(m_cost);
            var tx = node.x + r * 0.75, ty = node.y - r * 0.85;
            draw_set_color(make_color_rgb(10, 14, 22));
            draw_circle(tx, ty, 12, false);
            draw_set_color(hovered ? C_ENERGY : C_ACCENT);
            draw_circle(tx, ty, 12, true);
            ui_draw_lightning(tx - 4, ty, 11, true);
            draw_set_font(fnt_small);
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(c_white);
            draw_text(tx + 5, ty, tag);
        }

        // Weapon badge above towers
        if (!is_undefined(tower) && tower.alive && !is_undefined(tower.weapon) && tower.weapon.alive && tower.weapon.hp > 0) {
            var wep = tower.weapon;
            draw_set_font(fnt_small);
            var bw = max(96, string_width(wep.name) + 44);
            var bx0 = node.x - bw * 0.5;
            var by0 = node.y - r - 40;
            ui_box(bx0, by0, bx0 + bw, by0 + 26, make_color_rgb(28, 16, 20), C_WEAPON, 6);
            ui_icon_weapon(bx0 + 14, by0 + 12, wep.catalog_id, 16, C_WEAPON);
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(C_TEXT);
            draw_text(bx0 + 26, by0 + 10, wep.name);
            ui_bar(bx0 + 26, by0 + 19, bw - 34, 4, wep.hp / max(1, wep.max_hp), C_WEAPON);
            if (tower.manual_cooldown > 0) {
                draw_set_halign(fa_center);
                draw_set_color(C_WARN);
                draw_text(node.x, by0 - 9, "COOLDOWN " + string(tower.manual_cooldown));
            }
        }

        // Label pill below
        draw_set_font(fnt_small);
        var lbl = string_upper(node.name);
        if (node.type == "empty") lbl = "";
        if (lbl != "") {
            var lw = string_width(lbl) + 14;
            var ly = node.y + r + 8 + (is_undefined(tower) ? 0 : 6);
            draw_set_alpha(0.85);
            draw_set_color(make_color_rgb(8, 12, 20));
            draw_roundrect_ext(node.x - lw * 0.5, ly, node.x + lw * 0.5, ly + 18, 9, 9, false);
            draw_set_alpha(1);
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(hovered ? c_white : merge_color(ncol, c_white, 0.55));
            draw_text(node.x, ly + 9, lbl);
        }

        // Tooltip
        if (hovered) ui_board_node_tooltip(state, k, node, cur_player, is_here, can_move_here);
    }

    // Movement key hints around the local operative
    if (can_act && !cur_player.is_moving) {
        var dirs = [["W", 0, -1], ["A", -1, 0], ["S", 0, 1], ["D", 1, 0]];
        var here = state.nodes[$ cur_player.node];
        for (var d = 0; d < 4; d++) {
            var dest = game_node_in_direction(state, cur_player.node, dirs[d][1], dirs[d][2]);
            if (dest == "" || !game_player_can_move(state, cur_player, dest)) continue;
            var dn = state.nodes[$ dest];
            var ang = point_direction(here.x, here.y, dn.x, dn.y);
            var dist = min(70, point_distance(here.x, here.y, dn.x, dn.y) * 0.5);
            ui_keycap(here.x + lengthdir_x(dist, ang), here.y + lengthdir_y(dist, ang), dirs[d][0], true);
        }
    }

    // Board particles & shockwaves
    if (is_array(state.board_action_effects)) {
        for (var b = 0; b < array_length(state.board_action_effects); b++) {
            var ba = state.board_action_effects[b];
            var prog = ba.life / max(1, ba.max_life);
            draw_set_alpha(clamp((1 - prog) * 0.8, 0, 1));
            draw_set_color(ba.color);
            draw_circle(ba.x, ba.y, prog * ba.max_radius, true);
            for (var p = 0; p < array_length(ba.particles); p++) {
                var pt = ba.particles[p];
                draw_set_alpha(clamp(pt.life / max(1, pt.max_life), 0, 1));
                draw_set_color(pt.color);
                if (pt.shape == "cross") {
                    draw_line_width(pt.x - pt.size, pt.y, pt.x + pt.size, pt.y, 2);
                    draw_line_width(pt.x, pt.y - pt.size, pt.x, pt.y + pt.size, 2);
                } else {
                    draw_circle(pt.x, pt.y, pt.size, false);
                }
            }
        }
        draw_set_alpha(1);
    }

    // Operative pawns
    for (var p = 0; p < state.num_players; p++) {
        var pl = state.players[p];
        var pnode = state.nodes[$ pl.node];
        if (is_undefined(pnode)) continue;
        var ox = (p - 1.5) * 16;
        var oy = (p % 2 == 0 ? -12 : 12);
        var px = pl[$ "anim_x"] ?? (pnode.x + ox);
        var py = pl[$ "anim_y"] ?? (pnode.y + oy);
        var hop = pl[$ "hop_y"] ?? 0;
        var act_x = 0, act_y = 0;
        if ((pl[$ "action_timer"] ?? 0) > 0) {
            var anim = pl.action_anim;
            if (anim == "gather_forest" || anim == "gather_cave") { act_y = -abs(sin(pl.action_timer * 0.45) * 10); act_x = sin(pl.action_timer * 0.9) * 3; }
            else if (anim == "craft" || anim == "forge") { act_x = ((pl.action_timer % 4) < 2) ? 3 : -3; }
            else if (anim == "deposit" || anim == "trade") { act_y = -abs(sin(pl.action_timer * 0.35) * 12); }
            else if (anim == "dismantle") { act_x = sin(pl.action_timer * 0.8) * 5; }
            else if (anim == "repair") { act_y = sin(pl.action_timer * 0.6) * 4; }
            else if (anim == "event") { act_x = sin(pl.action_timer * 1.4) * 6; }
        }
        var idle = (pl.is_moving) ? 0 : sin(current_time * 0.004 + p * 1.7) * 1.5;
        var shadow_scale = clamp(1.0 - (-hop / 30.0), 0.35, 1.0);
        draw_set_alpha(0.45 * shadow_scale);
        draw_set_color(c_black);
        draw_ellipse(px - 12 * shadow_scale, py + 10 - 4 * shadow_scale, px + 12 * shadow_scale, py + 10 + 4 * shadow_scale, false);
        draw_set_alpha(1);
        var dx = px + act_x;
        var dy = py + hop + act_y + idle;
        var is_me = (p == local_idx);
        if (is_me && state.phase == "player_actions") {
            draw_set_color(c_white);
            draw_set_alpha(0.6 + 0.4 * sin(current_time * 0.008));
            draw_circle(dx, dy, 17, true);
            draw_set_alpha(1);
            var ind_y = dy - 24 - abs(sin(current_time * 0.006) * 5);
            draw_set_color(pl.color);
            draw_triangle(dx - 6, ind_y - 8, dx + 6, ind_y - 8, dx, ind_y, false);
            draw_set_color(c_white);
            draw_triangle(dx - 6, ind_y - 8, dx + 6, ind_y - 8, dx, ind_y, true);
        }
        ui_draw_operative_token(dx, dy, pl, p, 12, false);
        if (state.is_online && pl.ended_turn && state.phase == "player_actions") {
            draw_set_font(fnt_small);
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(C_GOOD);
            draw_text(dx, dy + 21, "READY");
        }
    }

    // Floating texts
    if (is_array(state.floating_texts)) {
        draw_set_font(fnt_bold);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        for (var f = 0; f < array_length(state.floating_texts); f++) {
            var ft = state.floating_texts[f];
            draw_set_alpha(ft.alpha);
            ui_text_outline(ft.x, ft.y, ft.text, ft.color);
        }
        draw_set_alpha(1);
    }
    draw_set_font(fnt_body);
}

function ui_board_zone(x1, y1, x2, y2, col, title, sub, t) {
    draw_set_alpha(0.16);
    draw_set_color(col);
    draw_roundrect_ext(x1, y1, x2, y2, 18, 18, false);
    draw_set_alpha(0.5);
    draw_roundrect_ext(x1, y1, x2, y2, 18, 18, true);
    draw_set_alpha(1);
    ui_corner_brackets(x1 + 4, y1 + 4, x2 - 4, y2 - 4, 14, merge_color(col, c_white, 0.3), 2);
    draw_set_font(fnt_h3);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(merge_color(col, c_white, 0.55));
    draw_text(x1 + 16, y1 + 12, title);
    draw_set_font(fnt_small);
    draw_set_color(merge_color(col, c_white, 0.25));
    draw_text(x1 + 16, y1 + 36, sub);
    draw_set_font(fnt_body);
}

function ui_board_node_tooltip(state, k, node, cur_player, is_here, can_move_here) {
    var tip = "";
    switch (node.type) {
        case "tower":
            var tow = state.towers[node.tower_idx];
            tip = tow.name + "  -  Base Tower\nIntegrity: " + string(tow.hp) + " / " + string(tow.max_hp);
            if (is_undefined(tow.weapon) || !tow.weapon.alive) tip += "\nNo weapon mounted (forge one at the Workstation).";
            else {
                tip += "\nMounted: " + tow.weapon.name + "  (" + string(tow.weapon.hp) + "/" + string(tow.weapon.max_hp) + " HP, " + string(tow.weapon.damage) + " dmg)";
                if (tow.manual_cooldown > 0) tip += "\nCooling down: " + string(tow.manual_cooldown) + " day(s)";
                tip += "\nStand here to fire it manually [F] or dismantle it [X].";
            }
            break;
        case "gather_forest": tip = "Forest\nGather [G] to draw from the forest deck: Wood, Scrap - and the odd surprise."; break;
        case "gather_cave1": tip = node.name + "\nGather [G]: mostly Stone and Metal."; break;
        case "gather_cave2": tip = node.name + "\nGather [G]: Metal, Crystals and Power Gems."; break;
        case "gather_cave3": tip = node.name + "\nGather [G]: Crystals and Power Gems."; break;
        case "town":
            var fav = state.town_favors[state.active_town_favor];
            tip = "Town Market\nSell team resources for Gold [T].\nToday's favor: " + fav.name + " (" + fav.desc + ")";
            break;
        case "workstation": tip = "Workstation\nForge blueprints onto towers and repair defenses [R]."; break;
        case "shop": tip = "Blueprint Shop\nBuy weapon blueprints with Gold [S]."; break;
        case "main_base": tip = "Main Base\nWalking in deposits your backpack into team storage.\nCraft Metal here [C] (1 Stone + 1 Scrap)."; break;
        case "empty": tip = node.name + "\nA waypoint between zones."; break;
    }
    var mc = game_player_get_move_cost(cur_player);
    if (is_here) tip += "\n[You are here - press E to interact]";
    else if (can_move_here) tip += "\n[Click to move - " + string(mc) + " energy]";
    else if (game_is_adjacent(state, cur_player.node, k)) tip += "\n[Need " + string(mc) + " energy to move here]";
    state.hover_tooltip = tip;
}

// =============================================================================
// RIGHT COLUMN: BASE STATUS + COMMS LOG
// =============================================================================
function ui_draw_right_panel(state, mx, my) {
    var L = ui_hud_layout();
    var rx = L.right_x, rw = L.right_x2 - L.right_x;

    // ---- Base status ----
    ui_panel(rx, L.status_y1, rw, L.status_y2 - L.status_y1, "BASE STATUS", C_TOWER);
    var alive_n = 0;
    for (var t = 0; t < 4; t++) if (state.towers[t].alive) alive_n++;
    draw_set_font(fnt_small);
    draw_set_halign(fa_right); draw_set_valign(fa_middle);
    draw_set_color(alive_n <= 1 ? C_BAD : C_DIM);
    draw_text(rx + rw - 14, L.status_y1 + 21, string(alive_n) + "/4 towers standing");

    for (var t = 0; t < 4; t++) {
        var tow = state.towers[t];
        var ty = L.status_y1 + 48 + t * 66;
        var flash = state.tower_hit_flash[t];
        var row_fill = ui_col_mix(C_RAISED, C_BAD_D, flash);
        ui_box(rx + 10, ty, rx + rw - 10, ty + 60, row_fill, tow.alive ? C_LINE : C_BAD_D, 8);
        draw_set_font(fnt_bold);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(tow.alive ? C_TEXT : C_BAD);
        draw_text(rx + 22, ty + 15, "TOWER " + string(t + 1));
        if (!tow.alive) {
            draw_set_font(fnt_small);
            draw_set_color(C_BAD);
            draw_text(rx + 22, ty + 41, "DESTROYED");
            continue;
        }
        // HP bar
        var hp_col = (tow.hp / tow.max_hp > 0.5) ? C_TOWER : ((tow.hp / tow.max_hp > 0.25) ? C_WARN : C_BAD);
        ui_bar(rx + 110, ty + 9, rw - 190, 12, tow.hp / tow.max_hp, hp_col, tow.max_hp);
        draw_set_font(fnt_small);
        draw_set_halign(fa_right);
        draw_set_color(hp_col);
        draw_text(rx + rw - 20, ty + 15, string(tow.hp) + "/" + string(tow.max_hp));
        // Weapon line
        var w = tow.weapon;
        draw_set_halign(fa_left);
        if (is_undefined(w) || !w.alive) {
            draw_set_color(C_FAINT);
            draw_text(rx + 22, ty + 41, "Empty hardpoint");
        } else {
            ui_icon_weapon(rx + 30, ty + 41, w.catalog_id, 18, C_WEAPON);
            draw_set_font(fnt_bold);
            draw_set_color(C_TEXT);
            draw_text(rx + 46, ty + 40, ui_fit_text(w.name, 140));
            ui_bar(rx + 196, ty + 37, 80, 7, w.hp / max(1, w.max_hp), C_WEAPON);
            draw_set_font(fnt_small);
            var tag = string(w.damage + w.bonus_damage) + " DMG";
            var tcol = C_DIM;
            if (w.disabled) { tag = "EMP"; tcol = C_ACCENT; }
            else if (tow.manual_cooldown > 0) { tag = "CD " + string(tow.manual_cooldown); tcol = C_WARN; }
            else if (w.damage <= 0) { tag = "SUPPORT"; }
            draw_set_halign(fa_right);
            draw_set_color(tcol);
            draw_text(rx + rw - 20, ty + 41, tag);
        }
        if (ui_point_in_rect(mx, my, rx + 10, ty, rw - 20, 60)) {
            var tip = "Tower " + string(t + 1) + ": " + string(tow.hp) + "/" + string(tow.max_hp) + " integrity";
            if (!is_undefined(w) && w.alive) tip += "\n" + w.name + ": " + string(w.hp) + "/" + string(w.max_hp) + " HP\n" + w.ability;
            state.hover_tooltip = tip;
        }
    }

    // ---- Comms / log ----
    ui_draw_comms_log(state, mx, my);
}

function ui_log_category(log_str) {
    if (string_pos("[CHAT]", log_str) == 1) return ["CHAT", C_ACCENT, make_color_rgb(200, 245, 255)];
    if (string_pos("DESTROYED", log_str) > 0 || string_pos("CRITICAL", log_str) > 0 || string_pos("destroyed in defense", log_str) > 0) return ["ALERT", C_BAD, make_color_rgb(255, 205, 205)];
    if (string_pos("VICTORY", log_str) > 0 || string_pos("---", log_str) > 0 || string_pos("Round", log_str) > 0 || string_pos("new day", log_str) > 0 || string_pos("INCOMING", log_str) > 0) return ["WAVE", C_AMBER, make_color_rgb(255, 238, 200)];
    if (string_pos("bought", log_str) > 0 || string_pos("sold", log_str) > 0) return ["TRADE", C_GOLD, make_color_rgb(250, 238, 200)];
    if (string_pos("dealt", log_str) > 0 || string_pos("Tesla discharges", log_str) > 0 || string_pos("splash", log_str) > 0 || string_pos("overcharged", log_str) > 0 || string_pos("powered", log_str) > 0 || string_pos("destroyed!", log_str) > 0) return ["COMBAT", C_WARN, make_color_rgb(255, 232, 210)];
    if (string_pos("struck", log_str) > 0 || string_pos("intercepted", log_str) > 0 || string_pos("bombs", log_str) > 0 || string_pos("drained", log_str) > 0 || string_pos("summoned", log_str) > 0 || string_pos("spawned", log_str) > 0 || string_pos("EMP", log_str) > 0) return ["ALIEN", C_ALIEN, make_color_rgb(236, 220, 255)];
    if (string_pos("repaired", log_str) > 0 || string_pos("fortified", log_str) > 0 || string_pos("restored", log_str) > 0 || string_pos("infused", log_str) > 0) return ["REPAIR", C_GOOD, make_color_rgb(215, 255, 230)];
    if (string_pos("sold", log_str) > 0 || string_pos("bought", log_str) > 0 || string_pos("reroll", log_str) > 0 || string_pos("Favor", log_str) > 0) return ["TRADE", C_GOLD, make_color_rgb(250, 238, 200)];
    if (string_pos("forged", log_str) > 0 || string_pos("mounted", log_str) > 0 || string_pos("dismantled", log_str) > 0) return ["CRAFT", C_TOWER, make_color_rgb(210, 232, 255)];
    if (string_pos("drew", log_str) > 0 || string_pos("deposited", log_str) > 0 || string_pos("retrieved", log_str) > 0) return ["LOOT", C_GOOD, make_color_rgb(210, 240, 220)];
    if (string_pos("moved to", log_str) > 0) return ["MOVE", C_FAINT, C_DIM];
    return ["INFO", C_FAINT, C_DIM];
}

/// @desc Squad comms: word-wrapped colour-coded log with scrollbar + chat input
function ui_draw_comms_log(state, mx, my) {
    var L = ui_hud_layout();
    var log_x = (state.action_log_x < 1400) ? 820 : L.right_x;
    state.action_log_x = log_x;
    var lw = L.right_x2 - log_x;
    var ly1 = L.log_y1, ly2 = L.log_y2;
    var expanded = (log_x < 1400);
    ui_panel(log_x, ly1, lw, ly2 - ly1, "SQUAD COMMS", C_ACCENT);

    // Header buttons: expand + jump to latest
    state.action_log_btn_toggle_hover = ui_draw_button(log_x + lw - 44, ly1 + 8, 32, 26, expanded ? ">" : "<", true, false, mx, my, "ghost");
    if (state.action_log_btn_toggle_hover) state.hover_tooltip = expanded ? "Shrink the comms panel" : "Expand the comms panel over the map";
    var at_top = (state.action_log_scroll_y <= 0);
    state.action_log_btn_top_hover = !at_top && ui_draw_button(log_x + lw - 120, ly1 + 8, 70, 26, "Latest", true, false, mx, my, "ghost");

    // Viewport
    var vx = log_x + 12, vy = ly1 + 46, vw = lw - 24 - 12, vh = (ly2 - 44) - vy;
    // Layout cache (recomputed only when logs or width change)
    var n = array_length(state.action_logs);
    if (state.action_log_cache_dirty || (state[$ "log_cache_w"] ?? -1) != vw || !variable_struct_exists(state, "log_cache")) {
        draw_set_font(fnt_small);
        var items = [];
        var total = 0;
        var tag_w = 66;
        for (var i = 0; i < n; i++) {
            var str = state.action_logs[i];
            var cat = ui_log_category(str);
            var body = str;
            if (cat[0] == "CHAT") body = string_delete(str, 1, 7);
            var h = string_height_ext(body, 16, vw - tag_w - 6) + 6;
            array_push(items, { y: total, h: h, tag: cat[0], col: cat[1], tcol: cat[2], text: body });
            total += h;
        }
        state.log_cache = items;
        state.log_cache_total = total;
        state.log_cache_w = vw;
        state.action_log_cache_dirty = false;
    }
    var items = state.log_cache;
    var total_h = state.log_cache_total;
    var max_scroll = max(0, total_h - vh);
    state.action_log_max_scroll_y = max_scroll;
    state.action_log_scroll_y = clamp(state.action_log_scroll_y, 0, max_scroll);

    var surf_w = max(1, vw), surf_h = max(1, vh);
    if (is_undefined(state.action_log_surf) || !surface_exists(state.action_log_surf)) state.action_log_surf = surface_create(surf_w, surf_h);
    else if (surface_get_width(state.action_log_surf) != surf_w || surface_get_height(state.action_log_surf) != surf_h) {
        surface_free(state.action_log_surf);
        state.action_log_surf = surface_create(surf_w, surf_h);
    }
    surface_set_target(state.action_log_surf);
    draw_clear_alpha(c_black, 0);
    draw_set_font(fnt_small);
    for (var i = 0; i < array_length(items); i++) {
        var it = items[i];
        var iy = it.y - state.action_log_scroll_y;
        if (iy + it.h < 0) continue;
        if (iy > surf_h) break;
        // Tag pill
        draw_set_alpha(0.22);
        draw_set_color(it.col);
        draw_roundrect_ext(0, iy + 1, 58, iy + 16, 4, 4, false);
        draw_set_alpha(1);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(it.col);
        draw_text(29, iy + 8, it.tag);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(i == 0 ? c_white : it.tcol);
        draw_text_ext(66, iy, it.text, 16, surf_w - 72);
    }
    surface_reset_target();
    draw_surface(state.action_log_surf, vx, vy);

    // Fade at the bottom edge
    // Scrollbar
    var sb_x = vx + vw + 4;
    draw_set_color(C_BG1);
    draw_roundrect_ext(sb_x, vy, sb_x + 6, vy + vh, 3, 3, false);
    state.action_log_v_thumb_hover = false;
    if (max_scroll > 0) {
        var th = max(24, vh * vh / total_h);
        var tyy = vy + (state.action_log_scroll_y / max_scroll) * (vh - th);
        var hov = point_in_rectangle(mx, my, sb_x - 4, tyy, sb_x + 10, tyy + th);
        state.action_log_v_thumb_hover = hov;
        state.action_log_usable_v_track = max(1, vh - th);
        draw_set_color((hov || state.action_log_v_drag) ? C_ACCENT : C_LINE_HI);
        draw_roundrect_ext(sb_x, tyy, sb_x + 6, tyy + th, 3, 3, false);
    }

    // Chat bar
    var cy = ly2 - 38;
    var send_w = 64;
    var inp_x = log_x + 12, inp_w = lw - 24 - send_w - 6;
    var active = state.chat_input_active;
    var hov_in = ui_point_in_rect(mx, my, inp_x, cy, inp_w, 28);
    state.chat_input_hover = hov_in;
    ui_box(inp_x, cy, inp_x + inp_w, cy + 28, active ? C_BG0 : C_BG1, active ? C_ACCENT : (hov_in ? C_LINE_HI : C_LINE), 6);
    draw_set_font(fnt_body);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    if (active) {
        var txt = state.chat_input_text + (((state.chat_cursor_timer div 25) % 2 == 0) ? "|" : "");
        draw_set_color(c_white);
        draw_text(inp_x + 10, cy + 14, ui_fit_text(txt, inp_w - 16));
    } else {
        draw_set_color(C_FAINT);
        draw_text(inp_x + 10, cy + 14, state.is_online ? "Message your squad...  [Enter]" : "Add a note to the log...  [Enter]");
    }
    state.chat_send_hover = ui_draw_button(inp_x + inp_w + 6, cy, send_w, 28, "Send", true, active, mx, my);
}

// =============================================================================
// BOTTOM: OPERATIVE, STORAGE, ACTIONS, THREAT LANES
// =============================================================================
function ui_draw_bottom_panel(state, mx, my) {
    var L = ui_hud_layout();
    var local_idx = game_local_player_idx(state);
    var pl = state.players[local_idx];
    var in_combat = (state.phase == "combat_weapons" || state.phase == "combat_aliens");

    // ---- Operative card ----
    var ox1 = L.op_x1, oy1 = L.op_y1, ox2 = L.op_x2, oy2 = L.op_y2;
    ui_shadow(ox1, oy1, ox2, oy2, 12, 0.4);
    ui_box(ox1, oy1, ox2, oy2, C_PANEL, pl.color, 12);
    draw_set_color(pl.color);
    draw_roundrect_ext(ox1 + 4, oy1 + 10, ox1 + 8, oy2 - 10, 2, 2, false);
    ui_draw_class_emblem(ox1 + 64, oy1 + 56, pl.character.id, pl.color, false);
    draw_set_font(fnt_h3);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(C_TEXT);
    draw_text(ox1 + 112, oy1 + 10, pl.name);
    var nmw = string_width(pl.name);
    draw_set_font(fnt_small);
    draw_set_color(pl.color);
    draw_text(ox1 + 120 + nmw, oy1 + 14, string_upper(pl.character.name));
    draw_set_color(C_FAINT);
    var loc_node = state.nodes[$ pl.node];
    draw_text(ox1 + 112, oy1 + 34, "Location: " + (is_undefined(loc_node) ? "?" : loc_node.name) + "   |   " + pl.character.perk_tag);
    // Energy bar
    var eb_x = ox1 + 112, eb_y = oy1 + 58, eb_w = ox2 - ox1 - 200;
    var e_disp = ui_anim("energy_disp" + string(local_idx), pl.energy, 0.2);
    ui_bar(eb_x, eb_y, eb_w, 14, e_disp / max(1, pl.max_energy), C_ENERGY, pl.max_energy);
    ui_draw_lightning(eb_x + eb_w + 16, eb_y + 7, 18, pl.energy > 0);
    draw_set_font(fnt_h3);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(pl.energy > 0 ? C_ENERGY : C_FAINT);
    draw_text(eb_x + eb_w + 28, eb_y + 6, string(pl.energy) + "/" + string(pl.max_energy));
    // Backpack
    draw_set_font(fnt_small);
    draw_set_color(C_FAINT);
    draw_text(ox1 + 112, oy1 + 92, "PACK");
    var bpx = ox1 + 152;
    var bkeys = ["wood", "scrap", "stone", "metal", "crystals", "power_gem"];
    var carried = 0;
    for (var b = 0; b < 6; b++) {
        var amt = pl.backpack[$ bkeys[b]];
        if (amt <= 0) continue;
        carried += amt;
        ui_icon_resource(bpx + 8, oy1 + 92, bkeys[b], 14);
        draw_set_color(C_TEXT);
        draw_text(bpx + 18, oy1 + 92, string(amt));
        bpx += 46;
    }
    if (carried == 0) { draw_set_color(C_FAINT); draw_text(bpx, oy1 + 92, "empty  -  gathered loot also goes straight to storage"); }
    if (state.is_online && pl.ended_turn && state.phase == "player_actions") {
        ui_pill(ox2 - 96, oy1 + 10, "STANDING BY", C_GOOD_D, C_GOOD, C_GOOD);
    }

    // ---- Team storage ----
    var rx1 = L.res_x1, rx2 = L.res_x2;
    ui_box(rx1, oy1, rx2, oy2, C_PANEL, C_LINE, 12);
    ui_section_label(rx1 + 14, oy1 + 14, "Team storage");
    var res_order = ["gold", "wood", "scrap", "stone", "metal", "crystals", "power_gem"];
    var res_names = ["Gold", "Wood", "Scrap", "Stone", "Metal", "Crystals", "Gems"];
    var tile_w = floor((rx2 - rx1 - 24 - 6 * 6) / 7);
    for (var r = 0; r < 7; r++) {
        var key = res_order[r];
        var tx = rx1 + 12 + r * (tile_w + 6);
        var ty = oy1 + 28;
        var val = state.storage[$ key];
        var shown = ui_anim("res_" + key, val, 0.18);
        var bump = clamp(abs(val - shown), 0, 1);
        ui_box(tx, ty, tx + tile_w, oy2 - 10, ui_col_mix(C_RAISED, merge_color(ui_resource_color(key), C_RAISED, 0.6), bump), C_LINE, 8);
        ui_icon_resource(tx + tile_w * 0.5, ty + 20, key, 24);
        draw_set_font(fnt_h3);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(val > 0 ? C_TEXT : C_FAINT);
        draw_text(tx + tile_w * 0.5, ty + 48, string(round(shown)));
        draw_set_font(fnt_small);
        draw_set_color(C_FAINT);
        draw_text(tx + tile_w * 0.5, ty + 67, res_names[r]);
        if (ui_point_in_rect(mx, my, tx, ty, tile_w, oy2 - 10 - ty)) {
            var rdefs = game_get_resource_definitions();
            state.hover_tooltip = res_names[r] + ": " + string(val) + " in team storage" + ((key != "gold") ? ("\nSells for " + string(rdefs[$ key].sell_value) + "g each in Town") : "");
        }
    }

    // ---- Action bar ----
    ui_draw_action_bar(state, mx, my, pl, in_combat);

    // ---- Threat lanes ----
    ui_draw_threat_lanes(state, mx, my);
}

function ui_draw_action_bar(state, mx, my, pl, in_combat) {
    var L = ui_hud_layout();
    var ax1 = L.act_x1, ax2 = L.act_x2, ay1 = L.op_y1, ay2 = L.op_y2;
    state.btn_gather_hover = false; state.btn_craft_hover = false; state.btn_dismantle_hover = false;
    state.btn_shop_hover = false; state.btn_repair_hover = false; state.btn_town_hover = false;
    state.btn_fire_hover = false; state.btn_endturn_hover = false; state.btn_combat_hover = false;

    if (in_combat || state.phase == "game_over" || state.phase == "victory") {
        ui_box(ax1, ay1, ax2, ay2, C_PANEL, C_BAD, 12);
        draw_set_font(fnt_h3);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(C_BAD);
        draw_text((ax1 + ax2) * 0.5, (ay1 + ay2) * 0.5 - 10, "DEFENSE IN PROGRESS");
        draw_set_font(fnt_small);
        draw_set_color(C_DIM);
        draw_text((ax1 + ax2) * 0.5, (ay1 + ay2) * 0.5 + 14, "Use the tactical display to run the guns");
        draw_set_font(fnt_body);
        return;
    }

    var can_act = !(state.is_online && pl.ended_turn);
    var task_cost = game_task_cost(pl);
    var node = state.nodes[$ pl.node];
    var ti = game_player_tower_idx(pl);
    var tw = (ti >= 0) ? state.towers[ti] : undefined;
    var has_any_wep = !is_undefined(tw) && !is_undefined(tw.weapon) && tw.weapon.alive && tw.weapon.hp > 0;
    var has_gun = has_any_wep && tw.weapon.damage > 0;
    var fire_cost = game_fire_cost(state, pl);

    var can_gather = can_act && pl.energy >= task_cost && (node.type == "gather_forest" || string_pos("gather_cave", node.type) > 0);
    var can_craft = can_act && pl.energy >= task_cost && (pl.node == "main_base" || pl.node == "workstation") && state.storage.stone >= 1 && state.storage.scrap >= 1;
    var can_dismantle = can_act && has_any_wep && pl.energy >= task_cost;
    var can_fire = can_act && has_gun && tw.manual_cooldown <= 0 && pl.energy >= fire_cost && array_length(state.active_zone) > 0;

    var bw = floor((ax2 - ax1 - 3 * 8) / 4);
    var bh = 50;
    var r1 = ay1, r2 = ay1 + bh + 12;

    state.btn_gather_hover = ui_draw_button(ax1, r1, bw, bh, "Gather " + string(task_cost) + "E", can_gather, false, mx, my, can_gather ? "success" : "default", "G");
    if (state.btn_gather_hover) state.hover_tooltip = "Draw a card from this zone's deck (" + string(task_cost) + " energy).";
    else if (!can_gather && ui_point_in_rect(mx, my, ax1, r1, bw, bh)) state.hover_tooltip = "Move to the Forest or a Cave to gather.";

    if (has_any_wep) {
        state.btn_dismantle_hover = ui_draw_button(ax1 + (bw + 8), r1, bw, bh, "Dismantle", can_dismantle, false, mx, my, "danger", "X");
        if (state.btn_dismantle_hover) state.hover_tooltip = "Scrap the " + tw.weapon.name + " to free this hardpoint (+1 Scrap).";
    } else {
        state.btn_craft_hover = ui_draw_button(ax1 + (bw + 8), r1, bw, bh, "Forge Metal", can_craft, false, mx, my, "default", "C");
        if (ui_point_in_rect(mx, my, ax1 + (bw + 8), r1, bw, bh)) state.hover_tooltip = "Turn 1 Stone + 1 Scrap into 1 Metal at the Main Base or Workstation (" + string(task_cost) + " energy).";
    }
    state.btn_shop_hover = ui_draw_button(ax1 + 2 * (bw + 8), r1, bw, bh, "Shop", true, pl.node == "shop", mx, my, "default", "S");
    if (state.btn_shop_hover) state.hover_tooltip = (pl.node == "shop") ? "Browse and buy weapon blueprints." : "Preview the shop (go to the Shop to buy).";
    state.btn_repair_hover = ui_draw_button(ax1 + 3 * (bw + 8), r1, bw, bh, "Workshop", true, pl.node == "workstation", mx, my, "default", "R");
    if (state.btn_repair_hover) state.hover_tooltip = "Forge blueprints onto towers and repair defenses (at the Workstation).";

    state.btn_town_hover = ui_draw_button(ax1, r2, bw, bh, "Market", true, pl.node == "town", mx, my, "default", "T");
    if (state.btn_town_hover) state.hover_tooltip = "Sell resources for Gold (at Town). Today's favor: " + state.town_favors[state.active_town_favor].name;
    var fire_lbl = has_gun ? ((tw.manual_cooldown > 0) ? ("Cooldown " + string(tw.manual_cooldown)) : ("Fire " + string(fire_cost) + "E")) : "Fire";
    state.btn_fire_hover = ui_draw_button(ax1 + (bw + 8), r2, bw, bh, fire_lbl, can_fire, false, mx, my, can_fire ? "amber" : "default", "F");
    if (ui_point_in_rect(mx, my, ax1 + (bw + 8), r2, bw, bh)) {
        if (!has_gun) state.hover_tooltip = "Stand on an armed tower to fire its weapon at an active alien.";
        else if (array_length(state.active_zone) == 0) state.hover_tooltip = "No hostiles in range.";
        else state.hover_tooltip = "Fire " + tw.weapon.name + " at the first valid target (or click an alien card).";
    }

    if (state.is_online) {
        var ready_n = 0;
        for (var p = 0; p < state.num_players; p++) if (state.players[p].ended_turn || state.players[p].energy <= 0) ready_n++;
        var lbl = pl.ended_turn ? ("Waiting " + string(ready_n) + "/" + string(state.num_players)) : "Ready Up";
        state.btn_endturn_hover = ui_draw_button(ax1 + 2 * (bw + 8), r2, bw * 2 + 8, bh, lbl, !pl.ended_turn, false, mx, my, "primary", "Space");
        if (state.btn_endturn_hover) state.hover_tooltip = "Finish your actions for today. The defense phase starts when the whole squad is ready.";
    } else {
        state.btn_endturn_hover = ui_draw_button(ax1 + 2 * (bw + 8), r2, bw, bh, "End Turn", true, false, mx, my, "default", "Space");
        if (state.btn_endturn_hover) state.hover_tooltip = "Pass to the next operative with energy left.";
        var threats = array_length(state.active_zone);
        state.btn_combat_hover = ui_draw_button(ax1 + 3 * (bw + 8), r2, bw, bh, threats > 0 ? "Defend!" : "Next Day", true, true, mx, my, threats > 0 ? "danger" : "primary", "B");
        if (state.btn_combat_hover) state.hover_tooltip = (threats > 0) ? "End everyone's turn and start the defense phase." : "No hostiles at the walls - end the day.";
    }
}

/// @desc Incoming (spawn) and active alien lanes with horizontal scrolling
function ui_draw_threat_lanes(state, mx, my) {
    var L = ui_hud_layout();
    state.alien_inspect_hover = undefined;
    state.active_alien_hover = -1;

    // ---- Incoming lane ----
    var y1 = L.lane_in_y1, y2 = L.lane_in_y2;
    ui_box(L.op_x1, y1, L.act_x2, y2, C_PANEL, C_LINE, 12);
    ui_box(L.op_x1, y1, L.op_x1 + L.lane_label_w, y2, C_BG1, undefined, 12);
    draw_set_font(fnt_bold);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_AMBER);
    draw_text(L.op_x1 + 14, y1 + 26, "INCOMING");
    draw_set_font(fnt_small);
    draw_set_color(C_FAINT);
    draw_text(L.op_x1 + 14, y1 + 48, "Arrive next day");
    draw_text(L.op_x1 + 14, y1 + 66, "Can't be targeted");
    draw_set_font(fnt_h2);
    draw_set_color(array_length(state.spawn_zone) > 0 ? C_AMBER : C_FAINT);
    draw_text(L.op_x1 + 14, y1 + 96, string(array_length(state.spawn_zone)));
    var cx0 = L.op_x1 + L.lane_label_w + 12;
    if (array_length(state.spawn_zone) == 0) {
        draw_set_font(fnt_body);
        draw_set_color(C_FAINT);
        draw_text(cx0 + 8, (y1 + y2) * 0.5, "Radar is clear - nothing inbound for tomorrow.");
    } else {
        var max_cards = floor((L.act_x2 - cx0 - 10) / L.card_step);
        for (var s = 0; s < min(max_cards, array_length(state.spawn_zone)); s++) {
            ui_draw_alien_card(state, cx0 + s * L.card_step, y1 + 8, L.card_w, y2 - y1 - 16, state.spawn_zone[s], false, mx, my, s);
        }
    }

    // ---- Active lane ----
    y1 = L.lane_act_y1; y2 = L.lane_act_y2;
    var n_act = array_length(state.active_zone);
    var hot = n_act > 0;
    ui_box(L.op_x1, y1, L.act_x2, y2, C_PANEL, hot ? merge_color(C_BAD, C_PANEL, 0.4) : C_LINE, 12);
    ui_box(L.op_x1, y1, L.op_x1 + L.lane_label_w, y2, hot ? make_color_rgb(40, 14, 20) : C_BG1, undefined, 12);
    draw_set_font(fnt_bold);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(hot ? C_BAD : C_DIM);
    draw_text(L.op_x1 + 14, y1 + 26, "AT THE WALLS");
    draw_set_font(fnt_small);
    draw_set_color(C_FAINT);
    draw_text(L.op_x1 + 14, y1 + 48, "Attack the base");
    draw_text(L.op_x1 + 14, y1 + 66, "at day's end");
    draw_set_font(fnt_h2);
    draw_set_color(hot ? C_BAD : C_FAINT);
    draw_text(L.op_x1 + 14, y1 + 100, string(n_act));
    if (game_has_active_scout(state)) {
        draw_set_font(fnt_small);
        draw_set_color(C_AMBER);
        draw_text(L.op_x1 + 14, y1 + 132, "Scout: kill first");
    }

    var zone_x = L.op_x1 + L.lane_label_w + 12;
    var zone_w = L.act_x2 - 12 - zone_x;
    var card_h = y2 - y1 - 28;
    var total_w = (n_act > 0) ? (n_act * L.card_step - (L.card_step - L.card_w)) : 0;
    var max_scroll = max(0, total_w - zone_w);
    state.active_aliens_scroll_x = clamp(state.active_aliens_scroll_x, 0, max_scroll);
    if (ui_point_in_rect(mx, my, zone_x, y1, zone_w, y2 - y1) && max_scroll > 0) {
        if (mouse_wheel_down()) state.active_aliens_scroll_x = min(max_scroll, state.active_aliens_scroll_x + L.card_step);
        if (mouse_wheel_up()) state.active_aliens_scroll_x = max(0, state.active_aliens_scroll_x - L.card_step);
    }
    var smooth_x = ui_anim("act_scroll", state.active_aliens_scroll_x, 0.3);

    if (n_act == 0) {
        draw_set_font(fnt_body);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(C_FAINT);
        draw_text(zone_x + 8, (y1 + y2) * 0.5, "No hostiles at the walls. Build up your defenses while it's quiet.");
    } else {
        var surf_w = max(1, zone_w), surf_h = card_h + 6;
        if (is_undefined(state.active_aliens_surf) || !surface_exists(state.active_aliens_surf)) state.active_aliens_surf = surface_create(surf_w, surf_h);
        else if (surface_get_width(state.active_aliens_surf) != surf_w || surface_get_height(state.active_aliens_surf) != surf_h) {
            surface_free(state.active_aliens_surf);
            state.active_aliens_surf = surface_create(surf_w, surf_h);
        }
        surface_set_target(state.active_aliens_surf);
        draw_clear_alpha(c_black, 0);
        var in_zone = (mx >= zone_x && mx <= zone_x + zone_w);
        var m_rel_x = in_zone ? (mx - zone_x) : -9999;
        var m_rel_y = my - (y1 + 5);
        for (var a = 0; a < n_act; a++) {
            var cx = a * L.card_step - smooth_x;
            if (cx + L.card_w < 0 || cx > surf_w) continue;
            ui_draw_alien_card(state, cx, 3, L.card_w, card_h, state.active_zone[a], true, m_rel_x, m_rel_y, a);
        }
        surface_reset_target();
        draw_surface(state.active_aliens_surf, zone_x, y1 + 5);

        if (max_scroll > 0) {
            var bar_y = y2 - 14;
            draw_set_color(C_BG1);
            draw_roundrect_ext(zone_x, bar_y, zone_x + zone_w, bar_y + 6, 3, 3, false);
            var thumb_w = max(60, zone_w * zone_w / total_w);
            var thumb_x = zone_x + (state.active_aliens_scroll_x / max_scroll) * (zone_w - thumb_w);
            if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mx, my, zone_x, bar_y - 6, zone_x + zone_w, bar_y + 12)) state.active_aliens_dragging = true;
            if (state.active_aliens_dragging) {
                if (mouse_check_button(mb_left)) state.active_aliens_scroll_x = clamp((mx - zone_x - thumb_w * 0.5) / max(1, zone_w - thumb_w), 0, 1) * max_scroll;
                else state.active_aliens_dragging = false;
            }
            draw_set_color(state.active_aliens_dragging ? C_ACCENT : C_LINE_HI);
            draw_roundrect_ext(thumb_x, bar_y, thumb_x + thumb_w, bar_y + 6, 3, 3, false);
        }
    }
}

/// @desc Compact alien card with creature art, HP bar and ability tags
function ui_draw_alien_card(state, cx, cy, cw, ch, alien, is_active, mx, my, alien_idx = -1) {
    var hovered = ui_point_in_rect(mx, my, cx, cy, cw, ch);
    var pl = game_local_player(state);
    var ti = game_player_tower_idx(pl);
    var tw = (ti >= 0) ? state.towers[ti] : undefined;
    var can_pilot = !is_undefined(tw) && !is_undefined(tw.weapon) && tw.weapon.alive && tw.weapon.damage > 0 && tw.manual_cooldown <= 0 && state.phase == "player_actions";
    var locked = game_has_active_scout(state) && alien.catalog_id != "scout";

    var tier_col = (alien.tier == 1) ? make_color_rgb(110, 210, 120) : ((alien.tier == 2) ? C_AMBER : C_BAD);
    var flash = alien[$ "flash"] ?? 0;
    var lift = ui_anim("acard" + string(alien.uid) + (is_active ? "a" : "s"), hovered ? 1 : 0, 0.3);
    var y0 = cy - lift * 3;
    var fill = ui_col_mix(make_color_rgb(20, 24, 36), make_color_rgb(32, 38, 56), lift);
    fill = ui_col_mix(fill, c_white, flash * 0.5);
    var border = hovered ? (is_active && can_pilot && !locked ? C_AMBER : C_LINE_HI) : merge_color(tier_col, C_PANEL, 0.45);
    ui_box(cx, y0, cx + cw, y0 + ch, fill, border, 8);
    // Tier strip
    draw_set_color(tier_col);
    draw_roundrect_ext(cx + 6, y0 + 6, cx + 34, y0 + 22, 4, 4, false);
    draw_set_font(fnt_small);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(10, 12, 18));
    draw_text(cx + 20, y0 + 14, "T" + string(alien.tier));
    // Name
    draw_set_font(fnt_bold);
    draw_set_halign(fa_left);
    draw_set_color(C_TEXT);
    draw_text(cx + 40, y0 + 14, ui_fit_text(alien.name, cw - 46));
    // Creature art
    var art_h = ch - 62;
    if (art_h > 26) {
        ui_draw_alien_glyph(cx + cw * 0.5, y0 + 26 + art_h * 0.5, alien.catalog_id, alien.tier, min(art_h, 54), current_time / 1000, flash);
    }
    // HP
    var hb_y = y0 + ch - 32;
    var hp_ratio = clamp(alien.hp / max(1, alien.max_hp), 0, 1);
    ui_bar(cx + 8, hb_y, cw - 16, 7, hp_ratio, (hp_ratio > 0.5) ? C_GOOD : ((hp_ratio > 0.25) ? C_WARN : C_BAD));
    draw_set_font(fnt_small);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_TEXT);
    draw_text(cx + 8, y0 + ch - 13, string(max(0, alien.hp)) + "/" + string(alien.max_hp));
    draw_set_halign(fa_right);
    draw_set_color(C_WEAPON);
    draw_text(cx + cw - 8, y0 + ch - 13, string(alien.damage) + " ATK");
    // Status tags
    var tag = "";
    var tag_col = C_WARN;
    if (alien.frozen) { tag = "FROZEN"; tag_col = C_ACCENT; }
    else if (alien.vulnerable) { tag = "BURNING"; tag_col = C_WARN; }
    else if (alien.tesla_weakened) { tag = "SHOCKED"; tag_col = C_ACCENT; }
    else if (alien.catalog_id == "scout") { tag = "PRIORITY"; tag_col = C_AMBER; }
    if (tag != "") {
        draw_set_font(fnt_small);
        var tw2 = string_width(tag) + 10;
        draw_set_alpha(0.85);
        ui_box(cx + cw - tw2 - 6, y0 + 26, cx + cw - 6, y0 + 42, C_BG0, tag_col, 4);
        draw_set_alpha(1);
        draw_set_halign(fa_center);
        draw_set_color(tag_col);
        draw_text(cx + cw - tw2 * 0.5 - 6, y0 + 34, tag);
    }
    if (is_active && state.phase == "player_actions" && hovered && can_pilot && !locked) {
        ui_corner_brackets(cx + 2, y0 + 2, cx + cw - 2, y0 + ch - 2, 12, C_AMBER, 2);
    }
    if (locked && is_active) {
        draw_set_alpha(0.35);
        draw_set_color(c_black);
        draw_roundrect_ext(cx, y0, cx + cw, y0 + ch, 8, 8, false);
        draw_set_alpha(1);
    }

    if (hovered) {
        state.alien_inspect_hover = alien;
        if (is_active) state.active_alien_hover = alien_idx;
        var tip = alien.name + "  (Tier " + string(alien.tier) + ")\nHP " + string(alien.hp) + "/" + string(alien.max_hp) + "   Attack " + string(alien.damage) + "\n" + alien.ability;
        if (is_active && state.phase == "player_actions") {
            if (locked) tip += "\n[A Scout is alive - it must be targeted first]";
            else if (can_pilot) tip += "\n[Click to fire " + tw.weapon.name + " at this alien]";
            else tip += "\n[Click for full intel]";
        } else tip += "\n[Click for full intel]";
        state.hover_tooltip = tip;
    }
    draw_set_font(fnt_body);
}

// =============================================================================
// BANNERS, TOASTS, TOOLTIPS, TRANSITIONS
// =============================================================================
function ui_draw_banner(state) {
    if (state.turn_popup_timer <= 0) return;
    if (!is_undefined(state.modal) && (state.modal.type == "game_over" || state.modal.type == "victory")) return;
    var mx_t = max(1, state[$ "turn_popup_max"] ?? 180);
    var prog = 1 - state.turn_popup_timer / mx_t;      // 0 -> 1
    var in_t = clamp(prog / 0.12, 0, 1);
    var out_t = clamp((1 - prog) / 0.15, 0, 1);
    var a = min(in_t, out_t);
    var ease = 1 - power(1 - in_t, 3);
    var cy = 300;
    if (!is_undefined(state.modal) && state.modal.type == "tactical_combat") cy = 520;
    var col = state.turn_popup_color;
    var w = 1000 * ease;
    draw_set_alpha(0.82 * a);
    draw_set_color(make_color_rgb(6, 9, 15));
    draw_rectangle(960 - w * 0.5, cy - 58, 960 + w * 0.5, cy + 58, false);
    draw_set_alpha(a);
    draw_set_color(col);
    draw_line_width(960 - w * 0.5, cy - 58, 960 + w * 0.5, cy - 58, 3);
    draw_line_width(960 - w * 0.5, cy + 58, 960 + w * 0.5, cy + 58, 3);
    var slide = (1 - ease) * 60;
    draw_set_font(fnt_h1);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    ui_text_shadow(960 - slide, cy - 14, state.turn_popup_title, col);
    draw_set_font(fnt_h3);
    draw_set_color(C_TEXT);
    draw_text(960 + slide, cy + 28, state.turn_popup_message);
    draw_set_alpha(1);
    draw_set_font(fnt_body);
}

function ui_draw_toast(state) {
    if (state.toast_timer <= 0 || state.toast_message == "") return;
    var is_err0 = state[$ "toast_is_error"] ?? false;
    if (state.turn_popup_timer > 0 && !is_err0) return;
    if (!is_err0 && !is_undefined(state.modal) && state.modal.type == "tactical_combat" && string_pos("[CHAT]", state.toast_message) != 1) return;
    var a = clamp(state.toast_timer / 20, 0, 1);
    var is_err = state[$ "toast_is_error"] ?? false;
    draw_set_font(fnt_bold);
    var msg = state.toast_message;
    if (string_pos("[CHAT] ", msg) == 1) msg = string_delete(msg, 1, 7);
    msg = ui_fit_text(msg, 1100);
    var w = string_width(msg) + 56;
    var x0 = 960 - w * 0.5;
    var y0 = 76 - (1 - a) * 10;
    draw_set_alpha(a);
    ui_box(x0, y0, x0 + w, y0 + 36, is_err ? make_color_rgb(54, 16, 22) : make_color_rgb(14, 22, 34), is_err ? C_BAD : C_LINE_HI, 18);
    draw_set_color(is_err ? C_BAD : C_ACCENT);
    draw_circle(x0 + 20, y0 + 18, 5, false);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_TEXT);
    draw_text(x0 + 34, y0 + 17, msg);
    draw_set_alpha(1);
    draw_set_font(fnt_body);
    if (state.toast_timer <= 1) state.toast_is_error = false;
}

function ui_draw_tooltip(state, mx, my) {
    if (state.hover_tooltip == "") return;
    var tip = state.hover_tooltip;
    draw_set_font(fnt_body);
    var tw = string_width_ext(tip, 20, 420) + 26;
    var th = string_height_ext(tip, 20, 420) + 20;
    var tx = clamp(mx + 18, 10, 1910 - tw);
    var ty = clamp(my + 20, 10, 1070 - th);
    if (my + 20 + th > 1070) ty = my - th - 12;
    ui_shadow(tx, ty, tx + tw, ty + th, 8, 0.6);
    ui_box(tx, ty, tx + tw, ty + th, make_color_rgb(10, 14, 22), C_LINE_HI, 8);
    draw_set_color(C_ACCENT);
    draw_line_width(tx + 1, ty + 8, tx + 1, ty + th - 8, 2);
    // First line bold as a title
    var nl = string_pos("\n", tip);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    if (nl > 0) {
        draw_set_font(fnt_bold);
        draw_set_color(c_white);
        draw_text(tx + 13, ty + 9, string_copy(tip, 1, nl - 1));
        draw_set_font(fnt_body);
        draw_set_color(C_DIM);
        draw_text_ext(tx + 13, ty + 9 + 20, string_delete(tip, 1, nl), 20, 420);
    } else {
        draw_set_color(C_TEXT);
        draw_text_ext(tx + 13, ty + 9, tip, 20, 420);
    }
    state.hover_tooltip = "";
}

/// @desc Switches screens with a short fade-in (the switch itself is immediate so logic stays simple)
function ui_transition_to(state, scr) {
    state.screen = scr;
    state.transition = 1.0;
    state.hover_tooltip = "";
}

function ui_draw_transition(state) {
    var tr = state[$ "transition"] ?? 0;
    if (tr <= 0) return;
    draw_set_alpha(clamp(tr, 0, 1));
    draw_set_color(c_black);
    draw_rectangle(0, 0, 1920, 1080, false);
    draw_set_alpha(1);
    state.transition = max(0, tr - 0.07);
}

// =============================================================================
// PAUSE MENU & HOW TO PLAY
// =============================================================================
function ui_pause_items(state) {
    var items = [["resume", "Resume"], ["help", "How to Play"], ["settings", "Settings"]];
    if (!state.is_online) array_push(items, ["restart", "Restart Mission"]);
    array_push(items, ["title", state.is_online ? "Leave Match" : "Main Menu"]);
    array_push(items, ["quit", "Quit to Desktop"]);
    return items;
}

function ui_draw_pause_menu(state, mx, my) {
    var items = ui_pause_items(state);
    var w = 460, bh = 54, gap = 12;
    var h = 120 + array_length(items) * (bh + gap);
    var x0 = 960 - w * 0.5, y0 = 540 - h * 0.5;
    ui_panel(x0, y0, w, h, "PAUSED", C_ACCENT, state.is_online ? "the match keeps running online" : "");
    state.pause_hover = -1;
    for (var i = 0; i < array_length(items); i++) {
        var by = y0 + 64 + i * (bh + gap);
        var style = (items[i][0] == "resume") ? "primary" : ((items[i][0] == "quit" || items[i][0] == "title") ? "danger" : "default");
        if (ui_draw_button(x0 + 30, by, w - 60, bh, items[i][1], true, false, mx, my, style)) state.pause_hover = i;
    }
    draw_set_font(fnt_small);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(C_FAINT);
    draw_text(960, y0 + h - 24, "Esc to resume  -  F11 toggles fullscreen");
    draw_set_font(fnt_body);
}

function ui_draw_help(state, mx, my) {
    var w = 1360, h = 800;
    var x0 = 960 - w * 0.5, y0 = 540 - h * 0.5;
    ui_panel(x0, y0, w, h, "HOW TO PLAY", C_ACCENT, "survive 17 days of alien attacks");
    var col_w = (w - 80) / 3;
    var sections = [
        ["THE GOAL", C_AMBER, "Keep at least one of the four base towers standing until the end of Day 17 - and clear the final wave.\n\nEach day has two phases: PLANNING, where your squad spends energy, and DEFENSE, where mounted weapons fire and the aliens strike back."],
        ["YOUR DAY", C_ACCENT, "Every operative has energy (the yellow bar). Moving along a path costs 1-2 energy; most tasks cost 1.\n\nGather at the Forest and Caves, sell loot in Town for Gold, buy weapon blueprints at the Shop, then forge them onto towers at the Workstation."],
        ["DEFENSE", C_BAD, "When everyone is out of energy (or you press Defend), each mounted weapon picks targets. Click a weapon, then click an alien.\n\nAliens that survive hit your towers - weapons on a tower absorb the blows first. Repair at the Workstation."]
    ];
    for (var c = 0; c < 3; c++) {
        var sx = x0 + 30 + c * (col_w + 10);
        ui_box(sx, y0 + 60, sx + col_w, y0 + 380, C_RAISED, C_LINE, 10);
        draw_set_font(fnt_h3);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(sections[c][1]);
        draw_text(sx + 18, y0 + 76, sections[c][0]);
        draw_set_font(fnt_body);
        draw_set_color(C_TEXT);
        draw_text_ext(sx + 18, y0 + 112, sections[c][2], 22, col_w - 36);
    }
    // Controls
    var cy = y0 + 400;
    ui_box(x0 + 30, cy, x0 + w - 30, y0 + h - 80, C_RAISED, C_LINE, 10);
    draw_set_font(fnt_h3);
    draw_set_color(C_TEXT);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_text(x0 + 48, cy + 16, "CONTROLS");
    var keys = [
        ["W A S D / Arrows", "Move to a connected location (combine for diagonals)"],
        ["Click a location", "Move there / interact if you're already on it"],
        ["E", "Interact with your current location"],
        ["G", "Gather resources"],
        ["C / X", "Forge Metal / Dismantle a tower weapon"],
        ["S  R  T", "Shop, Workshop, Market"],
        ["F", "Fire a tower weapon you're standing on"],
        ["Space", "End turn (online: Ready Up)"],
        ["B", "Begin the defense phase"],
        ["Tab / 1-4", "Switch operative (local play)"],
        ["Enter", "Chat / add a note"],
        ["Esc", "Pause menu"]
    ];
    draw_set_font(fnt_body);
    for (var i = 0; i < array_length(keys); i++) {
        var colx = x0 + 48 + (i div 6) * 640;
        var rowy = cy + 60 + (i mod 6) * 34;
        var kw = 0;
        var ks = string_split(keys[i][0], "/");
        var kx = colx;
        for (var j = 0; j < array_length(ks); j++) {
            kw = ui_keycap(kx, rowy + 10, string_trim(ks[j]));
            kx += kw + 6;
        }
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(C_DIM);
        draw_text(colx + 230, rowy + 10, keys[i][1]);
    }
    state.help_close_hover = ui_draw_button(960 - 120, y0 + h - 64, 240, 46, "Got it", true, true, mx, my, "primary", "Esc");
}

// =============================================================================
// FRAME ENTRY POINT
// =============================================================================
/// @desc Renders the full GUI for the current screen
function ui_draw_gui(state, mx, my) {
    ui_begin_frame();
    
    if (state.screen != "game") {
        switch (state.screen) {
            case "local_setup":     ui_draw_local_setup_screen(state, mx, my); break;
            case "online_username": ui_draw_online_username_screen(state, mx, my); break;
            case "online_browser":  ui_draw_online_browser_screen(state, mx, my); break;
            case "online_lobby":    ui_draw_online_lobby_screen(state, mx, my); break;
            default:                ui_draw_title_screen(state, mx, my); break;
        }
        if (!is_undefined(state.modal)) ui_draw_modals(state, mx, my);
        ui_draw_tooltip(state, mx, my);
        ui_draw_transition(state);
        return;
    }
    
    // Screen shake (can be disabled in Settings)
    var shake = (state.settings[$ "screen_shake"] ?? true) ? state.screen_shake : 0;
    if (shake > 0.2) {
        matrix_set(matrix_world, matrix_build(random_range(-shake, shake) * 0.7, random_range(-shake, shake) * 0.7, 0, 0, 0, 0, 1, 1, 1));
    }
    
    draw_set_color(C_BG0);
    draw_rectangle(0, 0, 1920, 1080, false);
    ui_draw_hud_top(state, mx, my);
    ui_draw_board(state, mx, my);
    ui_draw_right_panel(state, mx, my);
    ui_draw_bottom_panel(state, mx, my);
    
    if (state.phase == "game_over" && is_undefined(state.modal)) state.modal = { type: "game_over" };
    ui_draw_modals(state, mx, my);
    
    matrix_set(matrix_world, matrix_build_identity());
    ui_draw_banner(state);
    ui_draw_toast(state);
    ui_draw_tooltip(state, mx, my);
    ui_draw_transition(state);
}

// =============================================================================
// MODAL HELPERS: TITLE, SETTINGS, END SCREENS
// =============================================================================
function ui_modal_title(cx, ty, text, col) {
    draw_set_font(fnt_h2);
    draw_set_halign(fa_center); draw_set_valign(fa_top);
    ui_text_shadow(cx, ty, text, col);
    draw_set_font(fnt_body);
}

/// @desc Geometry shared by the settings drawing and its input handling
function ui_settings_layout(mx0, my0, mw, mh) {
    var bw3 = floor((mw - 80 - 24) / 3);
    var bw4 = floor((mw - 80 - 36) / 4);
    return {
        mode_y: my0 + 100, mode_w: bw3, mode_h: 44,
        res_y: my0 + 186, res_w: bw4, res_h: 40,
        track_x: mx0 + 190, track_w: mw - 190 - 290, track_h: 14,
        sfx_y: my0 + 292, music_y: my0 + 344,
        test_x: mx0 + mw - 190, test_w: 150,
        shake_y: my0 + 432,
        close_x: mx0 + (mw - 260) * 0.5, close_y: my0 + mh - 72, close_w: 260, close_h: 48,
        x0: mx0 + 40
    };
}

function ui_draw_slider(tx, ty, tw, th, val, col, mx, my, dragging) {
    ui_bar(tx, ty, tw, th, val, col, 0, C_BG0);
    var kx = tx + tw * clamp(val, 0, 1);
    var ky = ty + th * 0.5;
    var hov = dragging || point_in_circle(mx, my, kx, ky, 16);
    draw_set_color(c_black); draw_set_alpha(0.5);
    draw_circle(kx, ky + 2, 12, false);
    draw_set_alpha(1);
    draw_set_color(hov ? c_white : make_color_rgb(220, 228, 240));
    draw_circle(kx, ky, 11, false);
    draw_set_color(col);
    draw_circle(kx, ky, 5, false);
}

function ui_draw_settings(state, mx, my, mx0, my0, mw, mh) {
    var S = ui_settings_layout(mx0, my0, mw, mh);
    ui_modal_title(mx0 + mw * 0.5, my0 + 18, "SETTINGS", C_TEXT);
    
    ui_section_label(S.x0, S.mode_y - 18, "Display mode");
    var cur_mode = state.settings.display_mode;
    state.settings_mode_borderless_hover = ui_draw_button(S.x0, S.mode_y, S.mode_w, S.mode_h, "Borderless", true, cur_mode == "borderless", mx, my);
    state.settings_mode_fullscreen_hover = ui_draw_button(S.x0 + (S.mode_w + 12), S.mode_y, S.mode_w, S.mode_h, "Fullscreen", true, cur_mode == "fullscreen", mx, my);
    state.settings_mode_windowed_hover = ui_draw_button(S.x0 + 2 * (S.mode_w + 12), S.mode_y, S.mode_w, S.mode_h, "Windowed", true, cur_mode == "windowed", mx, my);
    
    ui_section_label(S.x0, S.res_y - 18, "Window size (windowed mode)");
    state.settings_res_hover = -1;
    for (var r = 0; r < array_length(state.resolutions); r++) {
        if (ui_draw_button(S.x0 + r * (S.res_w + 12), S.res_y, S.res_w, S.res_h, state.resolutions[r][2], true, state.settings.resolution_idx == r, mx, my)) state.settings_res_hover = r;
    }
    
    ui_section_label(S.x0, S.sfx_y - 34, "Audio");
    draw_set_font(fnt_bold);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_TEXT);
    draw_text(S.x0, S.sfx_y + 7, "Sound effects");
    draw_text(S.x0, S.music_y + 7, "Music");
    ui_draw_slider(S.track_x, S.sfx_y, S.track_w, S.track_h, state.settings.sfx_volume, C_GOOD, mx, my, state.settings.slider_dragging);
    ui_draw_slider(S.track_x, S.music_y, S.track_w, S.track_h, state.settings.music_volume, C_ACCENT, mx, my, state.settings.music_dragging);
    draw_set_halign(fa_right);
    draw_set_color(C_DIM);
    draw_text(S.track_x + S.track_w + 56, S.sfx_y + 7, string(round(state.settings.sfx_volume * 100)) + "%");
    draw_text(S.track_x + S.track_w + 56, S.music_y + 7, string(round(state.settings.music_volume * 100)) + "%");
    state.settings_test_sfx_hover = ui_draw_button(S.test_x, S.sfx_y - 12, S.test_w, 38, "Test", true, false, mx, my, "ghost");
    
    ui_section_label(S.x0, S.shake_y - 18, "Gameplay");
    var shake_on = state.settings[$ "screen_shake"] ?? true;
    state.settings_shake_hover = ui_draw_button(S.x0, S.shake_y, 300, 42, "Screen shake: " + (shake_on ? "ON" : "OFF"), true, shake_on, mx, my);
    draw_set_font(fnt_small);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_FAINT);
    draw_text(S.x0 + 320, S.shake_y + 21, "F11 toggles fullscreen at any time.");
    
    state.settings_restart_hover = false;
    state.settings_close_hover = ui_draw_button(S.close_x, S.close_y, S.close_w, S.close_h, "Done", true, true, mx, my, "primary", "Esc");
}

function ui_draw_end_screen(state, mx, my, mx0, my0, mw, mh, won) {
    var col = won ? C_GOOD : C_BAD;
    var cx = mx0 + mw * 0.5;
    ui_glow(cx, my0 + 96, 220, col, 0.18);
    draw_set_font(fnt_h1);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    ui_text_shadow(cx, my0 + 80, won ? "VICTORY" : "BASE OVERRUN", col);
    draw_set_font(fnt_h3);
    draw_set_color(C_TEXT);
    draw_text(cx, my0 + 128, won ? "The outpost held. Seventeen days of hell - and you're still standing." : "The last tower has fallen. The swarm takes the outpost.");
    
    // Stats
    var towers_up = 0; for (var t = 0; t < 4; t++) if (state.towers[t].alive) towers_up++;
    var weps = 0; for (var w = 0; w < array_length(state.weapons); w++) if (state.weapons[w].alive) weps++;
    var stats = [
        [won ? "DAYS HELD" : "DAYS SURVIVED", string(won ? state.round_number : max(0, state.round_number - 1)), C_ACCENT],
        ["TOWERS STANDING", string(towers_up) + "/4", C_TOWER],
        ["WEAPONS ONLINE", string(weps), C_WEAPON],
        ["GOLD BANKED", string(state.storage.gold), C_GOLD]
    ];
    var sw = floor((mw - 80 - 36) / 4);
    for (var i = 0; i < 4; i++) {
        var sx = mx0 + 40 + i * (sw + 12);
        ui_box(sx, my0 + 176, sx + sw, my0 + 266, C_RAISED, C_LINE, 10);
        draw_set_font(fnt_h1);
        draw_set_color(stats[i][2]);
        draw_text(sx + sw * 0.5, my0 + 212, stats[i][1]);
        draw_set_font(fnt_small);
        draw_set_color(C_FAINT);
        draw_text(sx + sw * 0.5, my0 + 248, stats[i][0]);
    }
    
    var bw = 420, bh = 52, bx = cx - bw * 0.5;
    var by = my0 + 300;
    var is_client = state.is_online && !state.is_host;
    state.victory_endless_hover = false; state.victory_restart_hover = false; state.victory_exit_hover = false;
    state.gameover_restart_hover = false; state.gameover_menu_hover = false; state.gameover_quit_hover = false;
    if (won) {
        state.victory_endless_hover = ui_draw_button(bx, by, bw, bh, is_client ? "Waiting for host: Endless?" : "Keep Fighting (Endless Mode)", !is_client, true, mx, my, "success");
        var again = state.is_online ? (state.is_host ? "Return to Lobby" : "Leave Match") : "New Mission";
        state.victory_restart_hover = ui_draw_button(bx, by + bh + 14, bw, bh, again, true, false, mx, my);
        state.victory_exit_hover = ui_draw_button(bx, by + 2 * (bh + 14), bw, bh, "Quit to Desktop", true, false, mx, my, "ghost");
    } else {
        var retry = state.is_online ? (state.is_host ? "Return to Lobby" : "Leave Match") : "Try Again (Same Squad)";
        state.gameover_restart_hover = ui_draw_button(bx, by, bw, bh, retry, true, true, mx, my, "primary");
        if (!state.is_online) state.gameover_menu_hover = ui_draw_button(bx, by + bh + 14, bw, bh, "Main Menu", true, false, mx, my);
        state.gameover_quit_hover = ui_draw_button(bx, by + (state.is_online ? 1 : 2) * (bh + 14), bw, bh, "Quit to Desktop", true, false, mx, my, "ghost");
    }
    draw_set_font(fnt_body);
}

// =============================================================================
// TACTICAL COMBAT VIEW PIECES
// =============================================================================
/// @desc The open ground between the swarm and the walls
function ui_draw_combat_battlefield(state, mx0, mw, y1, y2) {
    var x1 = mx0 + 24, x2 = mx0 + mw - 24;
    var t = current_time / 1000;
    // ground gradient
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_color(x1, y1, make_color_rgb(26, 10, 18), 1);
    draw_vertex_color(x2, y1, make_color_rgb(26, 10, 18), 1);
    draw_vertex_color(x1, y2, make_color_rgb(8, 20, 34), 1);
    draw_vertex_color(x2, y2, make_color_rgb(8, 20, 34), 1);
    draw_primitive_end();
    // perspective lines
    draw_set_alpha(0.08);
    draw_set_color(C_ACCENT);
    var cx = (x1 + x2) * 0.5;
    for (var i = -8; i <= 8; i++) draw_line(cx + i * 40, y1, cx + i * 110, y2);
    for (var j = 1; j < 5; j++) {
        var yy = y1 + (y2 - y1) * power(j / 5, 1.6);
        draw_line(x1, yy, x2, yy);
    }
    draw_set_alpha(1);
    // perimeter wall
    var wy = y2 - 18;
    draw_set_color(make_color_rgb(20, 40, 64));
    draw_rectangle(x1, wy, x2, wy + 10, false);
    draw_set_color(C_TOWER);
    draw_set_alpha(0.7 + 0.3 * sin(t * 3));
    draw_line_width(x1, wy, x2, wy, 2);
    draw_set_alpha(1);
    for (var sx = x1; sx < x2; sx += 48) {
        draw_set_color(make_color_rgb(34, 60, 92));
        draw_rectangle(sx, wy - 6, sx + 24, wy, false);
    }
    draw_set_font(fnt_small);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(C_FAINT);
    draw_text(cx, wy + 22, "PERIMETER WALL");
    draw_set_font(fnt_body);
}

function ui_draw_combat_alien_card(state, x, y, w, h, al, idx, hov, locked, is_scout) {
    var tier_col = (al.tier == 1) ? make_color_rgb(110, 210, 120) : ((al.tier == 2) ? C_AMBER : C_BAD);
    var flash = al[$ "flash"] ?? 0;
    var targetable = (state.combat_subphase == "player_weapons" && !locked);
    var lift = ui_anim("cal" + string(al.uid), (hov && targetable) ? 1 : 0, 0.3);
    var attacking = (state.combat_subphase == "alien_attacks" && state.alien_attack_idx - 1 == idx);
    var y0 = y - lift * 6;
    if (attacking) ui_glow(x + w * 0.5, y0 + h * 0.5, w * 0.9, C_BAD, 0.4);
    if (lift > 0.01) ui_glow(x + w * 0.5, y0 + h * 0.5, w * 0.8, C_ACCENT, 0.25 * lift);
    var fill = ui_col_mix(make_color_rgb(18, 22, 34), make_color_rgb(28, 38, 58), lift);
    fill = ui_col_mix(fill, c_white, flash * 0.6);
    var border = merge_color(tier_col, C_PANEL, 0.3);
    if (lift > 0.5) border = C_ACCENT;
    if (attacking) border = C_BAD;
    ui_shadow(x, y0, x + w, y0 + h, 10, 0.5);
    ui_box(x, y0, x + w, y0 + h, fill, border, 10);

    // Header
    draw_set_color(tier_col);
    draw_roundrect_ext(x + 8, y0 + 8, x + 36, y0 + 26, 4, 4, false);
    draw_set_font(fnt_small);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(10, 12, 18));
    draw_text(x + 22, y0 + 17, "T" + string(al.tier));
    draw_set_font(fnt_bold);
    draw_set_halign(fa_left);
    draw_set_color(C_TEXT);
    draw_text(x + 42, y0 + 17, ui_fit_text(al.name, w - 50));

    // Creature
    var art = min(w * 0.55, 76);
    var art_cy = y0 + 36 + art * 0.55;
    ui_draw_alien_glyph(x + w * 0.5, art_cy, al.catalog_id, al.tier, art, current_time / 1000 + idx, flash);
    if (hov && targetable) {
        var rr = art * 0.62 + sin(current_time * 0.012) * 3;
        draw_set_color(C_ACCENT);
        draw_circle(x + w * 0.5, art_cy, rr, true);
        draw_line_width(x + w * 0.5 - rr - 8, art_cy, x + w * 0.5 - rr + 6, art_cy, 2);
        draw_line_width(x + w * 0.5 + rr - 6, art_cy, x + w * 0.5 + rr + 8, art_cy, 2);
        draw_line_width(x + w * 0.5, art_cy - rr - 8, x + w * 0.5, art_cy - rr + 6, 2);
        draw_line_width(x + w * 0.5, art_cy + rr - 6, x + w * 0.5, art_cy + rr + 8, 2);
    }

    // HP
    var hp_y = y0 + h - 84;
    var hp_ratio = clamp(al.hp / max(1, al.max_hp), 0, 1);
    var shown = ui_anim("calhp" + string(al.uid), hp_ratio, 0.12);
    ui_bar(x + 10, hp_y, w - 20, 9, shown, make_color_rgb(255, 255, 255));
    ui_bar(x + 10, hp_y, w - 20, 9, hp_ratio, (hp_ratio > 0.5) ? C_GOOD : ((hp_ratio > 0.25) ? C_WARN : C_BAD), 0, make_color_rgb(0, 0, 0));
    draw_set_font(fnt_bold);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_TEXT);
    draw_text(x + 10, hp_y + 22, string(max(0, al.hp)) + " / " + string(al.max_hp));
    draw_set_halign(fa_right);
    draw_set_color(C_WEAPON);
    draw_text(x + w - 10, hp_y + 22, string(al.damage) + " ATK");

    // Status chips
    var chips = [];
    if (al.frozen) array_push(chips, ["FROZEN", C_ACCENT]);
    if (al.vulnerable) array_push(chips, ["BURNING", C_WARN]);
    if (al.tesla_weakened) array_push(chips, ["SHOCKED", make_color_rgb(180, 255, 255)]);
    var cxp = x + 10;
    draw_set_font(fnt_small);
    for (var c = 0; c < array_length(chips); c++) {
        var cw = string_width(chips[c][0]) + 12;
        if (cxp + cw > x + w - 6) break;
        ui_box(cxp, hp_y + 34, cxp + cw, hp_y + 50, C_BG0, chips[c][1], 4);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(chips[c][1]);
        draw_text(cxp + cw * 0.5, hp_y + 42, chips[c][0]);
        cxp += cw + 4;
    }
    // Ability (one or two lines)
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(C_FAINT);
    if (array_length(chips) == 0) draw_text_ext(x + 10, hp_y + 34, al.ability, 15, w - 20);

    if (is_scout) {
        ui_pill(x + w - 78, y0 - 10, "PRIORITY", make_color_rgb(70, 50, 10), C_AMBER, C_AMBER, 20);
    }
    if (locked && state.combat_subphase == "player_weapons") {
        draw_set_alpha(0.55);
        draw_set_color(c_black);
        draw_roundrect_ext(x, y0, x + w, y0 + h, 10, 10, false);
        draw_set_alpha(1);
        draw_set_font(fnt_small);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(C_BAD);
        draw_text(x + w * 0.5, y0 + h * 0.5, "SCOUT FIRST");
    }
    if (attacking) ui_pill(x + w * 0.5 - 40, y0 + h - 10, "ATTACKING", C_BAD_D, C_BAD, C_BAD, 20);
    draw_set_font(fnt_body);
}

/// @desc Weapon hardpoint card for one tower. Returns { hover, tesla_hover }
function ui_draw_combat_tower_card(state, t, x, y, w, h, mx, my) {
    var tow = state.towers[t];
    var wep = tow.weapon;
    var res = { hover: false, tesla_hover: false };
    var hov = ui_point_in_rect(mx, my, x, y, w, h);
    res.hover = hov;
    var hit = state.tower_hit_flash[t];
    var xo = x + random_range(-6, 6) * hit;
    var has_wep = !is_undefined(wep) && wep.alive;
    var used = state.tower_weapon_used[t];
    var sel = (state.combat_selected_tower == t && !used && has_wep);
    var phase_w = (state.combat_subphase == "player_weapons");

    if (!tow.alive) {
        ui_box(xo, y, xo + w, y + h, make_color_rgb(24, 12, 16), C_BAD_D, 10);
        draw_set_color(C_BAD_D);
        draw_line_width(xo + w * 0.5 - 30, y + h * 0.5 - 50, xo + w * 0.5 + 30, y + h * 0.5 + 10, 6);
        draw_line_width(xo + w * 0.5 + 30, y + h * 0.5 - 50, xo + w * 0.5 - 30, y + h * 0.5 + 10, 6);
        draw_set_font(fnt_h3);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(C_BAD);
        draw_text(xo + w * 0.5, y + h * 0.5 + 50, "TOWER " + string(t + 1) + " DESTROYED");
        draw_set_font(fnt_body);
        return res;
    }

    var fill = C_RAISED;
    var border = C_LINE;
    if (has_wep && !used && phase_w) border = hov ? C_ACCENT : C_LINE_HI;
    if (sel) { fill = make_color_rgb(14, 40, 58); border = C_ACCENT; }
    if (used || !has_wep) fill = make_color_rgb(17, 21, 31);
    fill = ui_col_mix(fill, C_BAD_D, hit);
    if (sel) ui_glow(xo + w * 0.5, y + h * 0.5, w * 0.6, C_ACCENT, 0.18);
    ui_box(xo, y, xo + w, y + h, fill, border, 10);
    if (sel) ui_corner_brackets(xo - 3, y - 3, xo + w + 3, y + h + 3, 18, C_ACCENT, 2);

    // Header
    ui_keycap(xo + 12, y + 22, string(t + 1));
    draw_set_font(fnt_small);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_FAINT);
    draw_text(xo + 40, y + 14, "TOWER " + string(t + 1));
    ui_bar(xo + 40, y + 27, 110, 6, tow.hp / tow.max_hp, C_TOWER, tow.max_hp);
    draw_set_halign(fa_left);
    draw_set_color(C_TOWER);
    draw_text(xo + 158, y + 29, string(tow.hp) + "/" + string(tow.max_hp));

    if (!has_wep) {
        draw_set_font(fnt_h3);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(C_FAINT);
        draw_text(xo + w * 0.5, y + h * 0.5 - 6, "EMPTY HARDPOINT");
        draw_set_font(fnt_small);
        draw_text(xo + w * 0.5, y + h * 0.5 + 20, "Forge a blueprint at the Workshop to arm it");
        draw_set_font(fnt_body);
        return res;
    }

    // Status pill
    var st_lbl = "READY", st_col = C_GOOD;
    if (wep.disabled) { st_lbl = "EMP DISABLED"; st_col = C_ACCENT; }
    else if (wep.damage <= 0) { st_lbl = "SUPPORT"; st_col = C_DIM; }
    else if (used && state.tower_weapon_max_shots[t] == 0) { st_lbl = "CHARGING"; st_col = C_WARN; }
    else if (used) { st_lbl = "SPENT"; st_col = C_FAINT; }
    else if (sel) { st_lbl = "ARMED"; st_col = C_ACCENT; }
    draw_set_font(fnt_small);
    var pw = string_width(st_lbl) + 16;
    ui_pill(xo + w - pw - 12, y + 12, st_lbl, merge_color(st_col, c_black, 0.75), st_col, st_col, 22);

    // Weapon identity
    var icon_col = used ? C_FAINT : C_WEAPON;
    ui_icon_weapon(xo + 34, y + 70, wep.catalog_id, 40, icon_col);
    draw_set_font(fnt_h3);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(used ? C_DIM : C_TEXT);
    draw_text(xo + 66, y + 60, ui_fit_text(wep.name, w - 80));
    ui_bar(xo + 66, y + 78, w - 130, 7, wep.hp / max(1, wep.max_hp), C_WEAPON);
    draw_set_font(fnt_small);
    draw_set_color(C_WEAPON);
    draw_set_halign(fa_right);
    draw_text(xo + w - 14, y + 81, string(wep.hp) + "/" + string(wep.max_hp));

    // Damage + shots
    var eff = wep.damage + wep.bonus_damage;
    draw_set_halign(fa_left);
    draw_set_font(fnt_h1);
    draw_set_color(used ? C_FAINT : C_AMBER);
    draw_text(xo + 16, y + 124, string(eff));
    var dw = string_width(string(eff));
    draw_set_font(fnt_small);
    draw_set_color(C_FAINT);
    draw_text(xo + 22 + dw, y + 116, "DAMAGE");
    if (wep.bonus_damage > 0) { draw_set_color(C_GOOD); draw_text(xo + 22 + dw, y + 132, "+" + string(wep.bonus_damage) + " overcharge"); }
    var shots = state.tower_weapon_shots[t], max_shots = state.tower_weapon_max_shots[t];
    draw_set_halign(fa_right);
    draw_set_color(C_FAINT);
    draw_text(xo + w - 14, y + 108, "SHOTS");
    for (var s = 0; s < max_shots; s++) {
        var px = xo + w - 20 - s * 18;
        draw_set_color(s < shots ? C_ACCENT : make_color_rgb(40, 48, 64));
        draw_circle(px, y + 130, 6, false);
    }

    // Ability
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(used ? C_FAINT : C_DIM);
    draw_text_ext(xo + 16, y + 156, wep.ability, 17, w - 32);

    // Footer
    var fy = y + h - 50;
    if (wep.catalog_id == "tesla" && !used && phase_w) {
        res.tesla_hover = ui_draw_button(xo + 14, fy, w - 28, 38, "Discharge - hit every alien", true, true, mx, my, "amber", sel ? "Space" : "");
    } else {
        draw_set_font(fnt_small);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        var hint = "", hcol = C_FAINT;
        if (!phase_w) hint = used ? "Spent for today" : "Standing by";
        else if (used) hint = (st_lbl == "CHARGING") ? "Railgun capacitor charging - ready next wave" : "All shots fired this wave";
        else if (sel) { hint = "Click an alien to fire"; hcol = C_ACCENT; }
        else { hint = "Click or press " + string(t + 1) + " to arm"; hcol = C_AMBER; }
        draw_set_color(hcol);
        draw_text(xo + w * 0.5, fy + 20, hint);
    }
    draw_set_font(fnt_body);
    return res;
}
