/// @desc UI rendering and interaction drawing for Alien Game

function ui_point_in_rect(px, py, rx, ry, rw, rh) {
    return (px >= rx && px <= rx + rw && py >= ry && py <= ry + rh);
}

function ui_draw_button(rx, ry, rw, rh, text, enabled, is_active, mouse_px, mouse_py) {
    var hovered = enabled && ui_point_in_rect(mouse_px, mouse_py, rx, ry, rw, rh);
    
    var bg_col = is_active ? make_color_rgb(41, 128, 185) : (hovered ? make_color_rgb(52, 73, 94) : make_color_rgb(44, 62, 80));
    if (!enabled) bg_col = make_color_rgb(60, 60, 60);
    
    var border_col = is_active ? c_yellow : (hovered ? c_white : make_color_rgb(127, 140, 141));
    if (!enabled) border_col = make_color_rgb(80, 80, 80);
    
    draw_set_color(bg_col);
    draw_roundrect_ext(rx, ry, rx + rw, ry + rh, 10, 10, false);
    
    draw_set_color(border_col);
    draw_roundrect_ext(rx, ry, rx + rw, ry + rh, 10, 10, true);
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(enabled ? (hovered ? c_yellow : c_white) : make_color_rgb(140, 140, 140));
    draw_text(rx + rw * 0.5, ry + rh * 0.5, text);
    
    return hovered;
}

function ui_draw_heart(hx, hy, size, color, border_color = undefined, border_width = 2) {
    if (!is_undefined(border_color)) {
        draw_set_color(border_color);
        var bsize = size + border_width * 2;
        var br = bsize * 0.28;
        var bcy = hy - bsize * 0.12;
        draw_circle(hx - br, bcy, br, false);
        draw_circle(hx + br, bcy, br, false);
        draw_rectangle(hx - br, bcy, hx + br, bcy + br * 0.6, false);
        draw_triangle(hx - bsize * 0.52, bcy + br * 0.2, hx + bsize * 0.52, bcy + br * 0.2, hx, hy + bsize * 0.52, false);
    }
    
    draw_set_color(color);
    var r = size * 0.28;
    var cy = hy - size * 0.12;
    // Left & Right lobes
    draw_circle(hx - r, cy, r, false);
    draw_circle(hx + r, cy, r, false);
    // Center connector
    draw_rectangle(hx - r, cy, hx + r, cy + r * 0.6, false);
    // Bottom triangle pointing down
    draw_triangle(hx - size * 0.52, cy + r * 0.2, hx + size * 0.52, cy + r * 0.2, hx, hy + size * 0.52, false);
}

function ui_draw_lightning(bx, by, size, is_filled) {
    var w = size * 0.7;
    var h = size;
    
    var x0 = bx + w * 0.1,  y0 = by - h * 0.5; // Top tip
    var x1 = bx - w * 0.5,  y1 = by + h * 0.05; // Left bend
    var x2 = bx - w * 0.05, y2 = by + h * 0.05; // Inner left notch
    var x3 = bx - w * 0.2,  y3 = by + h * 0.5; // Bottom tip
    var x4 = bx + w * 0.5,  y4 = by - h * 0.05; // Right bend
    var x5 = bx + w * 0.05, y5 = by - h * 0.05; // Inner right notch
    
    if (is_filled) {
        // Bright radiant yellow fill
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_triangle(x0, y0, x1, y1, x5, y5, false);
        draw_triangle(x1, y1, x2, y2, x5, y5, false);
        draw_triangle(x2, y2, x4, y4, x5, y5, false);
        draw_triangle(x2, y2, x3, y3, x4, y4, false);
        
        // Crisp outline
        draw_set_color(make_color_rgb(255, 250, 180));
        draw_line(x0, y0, x1, y1);
        draw_line(x1, y1, x2, y2);
        draw_line(x2, y2, x3, y3);
        draw_line(x3, y3, x4, y4);
        draw_line(x4, y4, x5, y5);
        draw_line(x5, y5, x0, y0);
    } else {
        // Empty / Depleted socket: dark fill with subdued slate outline
        draw_set_color(make_color_rgb(28, 34, 45));
        draw_triangle(x0, y0, x1, y1, x5, y5, false);
        draw_triangle(x1, y1, x2, y2, x5, y5, false);
        draw_triangle(x2, y2, x4, y4, x5, y5, false);
        draw_triangle(x2, y2, x3, y3, x4, y4, false);
        
        draw_set_color(make_color_rgb(75, 88, 105));
        draw_line(x0, y0, x1, y1);
        draw_line(x1, y1, x2, y2);
        draw_line(x2, y2, x3, y3);
        draw_line(x3, y3, x4, y4);
        draw_line(x4, y4, x5, y5);
        draw_line(x5, y5, x0, y0);
    }
}

function ui_draw_resource_token(tx, ty, res_type, rad = 9) {
    var res_defs = game_get_resource_definitions();
    var rdef = variable_struct_exists(res_defs, res_type) ? res_defs[$ res_type] : undefined;
    if (is_undefined(rdef)) {
        draw_set_color(make_color_rgb(180, 180, 180));
        draw_circle(tx, ty, rad, false);
        draw_set_color(c_white);
        draw_circle(tx, ty, rad, true);
        return;
    }
    draw_set_color(rdef.color);
    draw_circle(tx, ty, rad, false);
    draw_set_color(c_white);
    draw_circle(tx, ty, rad, true);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text(tx, ty, rdef.icon_char);
}

function ui_draw_die(dx, dy, dsize, value, die_color, dot_color) {
    draw_set_color(die_color);
    draw_roundrect_ext(dx, dy, dx + dsize, dy + dsize, 8, 8, false);
    draw_set_color(c_black);
    draw_roundrect_ext(dx, dy, dx + dsize, dy + dsize, 8, 8, true);
    
    draw_set_color(dot_color);
    var rad = dsize * 0.1;
    var c = dx + dsize * 0.5;
    var cy = dy + dsize * 0.5;
    var l = dx + dsize * 0.28;
    var r = dx + dsize * 0.72;
    var t = dy + dsize * 0.28;
    var b = dy + dsize * 0.72;
    
    if (value == 1) {
        draw_circle(c, cy, rad, false);
    } else if (value == 2) {
        draw_circle(l, t, rad, false);
        draw_circle(r, b, rad, false);
    } else if (value == 3) {
        draw_circle(l, t, rad, false);
        draw_circle(c, cy, rad, false);
        draw_circle(r, b, rad, false);
    } else if (value == 4) {
        draw_circle(l, t, rad, false);
        draw_circle(r, t, rad, false);
        draw_circle(l, b, rad, false);
        draw_circle(r, b, rad, false);
    } else if (value == 5) {
        draw_circle(l, t, rad, false);
        draw_circle(r, t, rad, false);
        draw_circle(c, cy, rad, false);
        draw_circle(l, b, rad, false);
        draw_circle(r, b, rad, false);
    } else if (value >= 6) {
        draw_circle(l, t, rad, false);
        draw_circle(r, t, rad, false);
        draw_circle(l, cy, rad, false);
        draw_circle(r, cy, rad, false);
        draw_circle(l, b, rad, false);
        draw_circle(r, b, rad, false);
    }
}

function ui_draw_d20(dx, dy, dsize, value, die_color, text_color) {
    // Hexagonal approximation for D20 die
    draw_set_color(die_color);
    var cx = dx + dsize * 0.5;
    var cy = dy + dsize * 0.5;
    var r = dsize * 0.48;
    
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(cx, cy);
    for (var i = 0; i <= 6; i++) {
        var ang = degtorad(i * 60 + 30);
        draw_vertex(cx + cos(ang) * r, cy + sin(ang) * r);
    }
    draw_primitive_end();
    
    draw_set_color(c_white);
    for (var i = 0; i < 6; i++) {
        var a1 = degtorad(i * 60 + 30);
        var a2 = degtorad((i + 1) * 60 + 30);
        draw_line_width(cx + cos(a1) * r, cy + sin(a1) * r, cx + cos(a2) * r, cy + sin(a2) * r, 2);
        draw_line(cx, cy, cx + cos(a1) * r, cy + sin(a1) * r);
    }
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(text_color);
    draw_text(cx, cy, string(value));
}

function ui_draw_board(state, mx, my) {
    // Main board background (blueprint / tactical map style)
    var bx = 20;
    var by = 50;
    var bw = 1480;
    var bh = 570;
    
    draw_set_color(make_color_rgb(26, 32, 44));
    draw_roundrect_ext(bx, by, bx + bw, by + bh, 16, 16, false);
    draw_set_color(make_color_rgb(52, 73, 94));
    draw_roundrect_ext(bx, by, bx + bw, by + bh, 16, 16, true);
    
    // Forest background zone
    draw_set_color(make_color_rgb(18, 48, 28));
    draw_roundrect_ext(30, 60, 270, 310, 14, 14, false);
    draw_set_color(make_color_rgb(46, 125, 50));
    draw_roundrect_ext(30, 60, 270, 310, 14, 14, true);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(129, 199, 132));
    draw_text(40, 70, "FOREST ZONE (Wood, Scrap)");
    
    // Town background zone
    draw_set_color(make_color_rgb(50, 30, 40));
    draw_roundrect_ext(30, 380, 270, 600, 14, 14, false);
    draw_set_color(make_color_rgb(186, 104, 200));
    draw_roundrect_ext(30, 380, 270, 600, 14, 14, true);
    draw_set_color(make_color_rgb(240, 98, 146));
    draw_text(40, 390, "TOWN (Sell & Barter)");
    
    // Cave background zone
    draw_set_color(make_color_rgb(38, 28, 25));
    draw_roundrect_ext(1160, 60, 1480, 600, 14, 14, false);
    draw_set_color(make_color_rgb(121, 85, 72));
    draw_roundrect_ext(1160, 60, 1480, 600, 14, 14, true);
    draw_set_color(make_color_rgb(215, 204, 200));
    draw_text(1180, 70, "THE CAVERNS (Stone, Metal, Gems)");
    
    var cur_player = state.players[state.current_player_idx];
    
    // Draw all connection edges
    for (var i = 0; i < array_length(state.edges); i++) {
        var edge = state.edges[i];
        var n1 = state.nodes[$ edge[0]];
        var n2 = state.nodes[$ edge[1]];
        if (!is_undefined(n1) && !is_undefined(n2)) {
            var is_cur_path = ((edge[0] == cur_player.node && game_player_can_move(state, cur_player, edge[1])) || 
                               (edge[1] == cur_player.node && game_player_can_move(state, cur_player, edge[0])));
            if (is_cur_path) {
                // Energetic pulsating connection path to reachable node
                draw_set_color(make_color_rgb(0, 140, 160));
                draw_line_width(n1.x, n1.y, n2.x, n2.y, 7);
                draw_set_color(make_color_rgb(0, 240, 210));
                draw_line_width(n1.x, n1.y, n2.x, n2.y, 4);
                draw_set_color(make_color_rgb(210, 255, 250));
                draw_line_width(n1.x, n1.y, n2.x, n2.y, 2);
                
                // Animated traveling energy dot gliding along the connection
                var travel_t = (current_time * 0.0012) % 1.0;
                var p_from = (edge[0] == cur_player.node) ? n1 : n2;
                var p_to = (edge[0] == cur_player.node) ? n2 : n1;
                var dot_x = lerp(p_from.x, p_to.x, travel_t);
                var dot_y = lerp(p_from.y, p_to.y, travel_t);
                draw_set_color(c_white);
                draw_circle(dot_x, dot_y, 4, false);
                draw_set_color(make_color_rgb(100, 255, 240));
                draw_circle(dot_x, dot_y, 6, true);
            } else {
                // Glow line
                draw_set_color(make_color_rgb(41, 128, 185));
                draw_line_width(n1.x, n1.y, n2.x, n2.y, 4);
                draw_set_color(make_color_rgb(142, 202, 230));
                draw_line_width(n1.x, n1.y, n2.x, n2.y, 2);
            }
        }
    }
    
    // Draw base perimeter wall connecting Tower 1, 2, 3, 4
    var t1 = state.nodes.tower_1;
    var t2 = state.nodes.tower_2;
    var t3 = state.nodes.tower_3;
    var t4 = state.nodes.tower_4;
    draw_set_color(make_color_rgb(33, 150, 243));
    draw_line_width(t1.x, t1.y, t2.x, t2.y, 3);
    draw_line_width(t2.x, t2.y, t3.x, t3.y, 3);
    draw_line_width(t3.x, t3.y, t4.x, t4.y, 3);
    draw_line_width(t4.x, t4.y, t1.x, t1.y, 3);
    
    // Draw all map nodes
    var node_keys = variable_struct_get_names(state.nodes);
    
    for (var i = 0; i < array_length(node_keys); i++) {
        var k = node_keys[i];
        var node = state.nodes[$ k];
        var is_player_here = (cur_player.node == k);
        var can_move_here = game_player_can_move(state, cur_player, k);
        var is_hovered = point_in_circle(mx, my, node.x, node.y, 36);
        
        // Node circle
        var nrad = (node.type == "main_base" || node.type == "tower") ? 36 : 28;
        
        // Background
        draw_set_color(node.color);
        draw_circle(node.x, node.y, nrad, false);
        
        // Movable Space Emphasis: Pulsating neon glow rings & energy cost pill
        if (can_move_here && !is_player_here) {
            var pulse_anim = sin(current_time * 0.007) * 4;
            draw_set_color(make_color_rgb(0, 255, 200));
            draw_circle(node.x, node.y, nrad + 6 + pulse_anim, true);
            draw_set_color(make_color_rgb(76, 217, 100));
            draw_circle(node.x, node.y, nrad + 3 + pulse_anim * 0.5, true);
            
            // Movement Energy Cost Badge Pill
            var m_cost = game_player_get_move_cost(cur_player);
            var pill_w = 46;
            var pill_h = 18;
            var pill_x = node.x - pill_w * 0.5;
            var pill_y = node.y - nrad - 22;
            
            draw_set_color(make_color_rgb(12, 35, 28));
            draw_roundrect_ext(pill_x, pill_y, pill_x + pill_w, pill_y + pill_h, 6, 6, false);
            draw_set_color(is_hovered ? c_yellow : make_color_rgb(0, 255, 180));
            draw_roundrect_ext(pill_x, pill_y, pill_x + pill_w, pill_y + pill_h, 6, 6, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(is_hovered ? c_yellow : make_color_rgb(180, 255, 220));
            draw_text(node.x, pill_y + pill_h * 0.5, "> " + string(m_cost) + "E");
        }
        
        // Border / Highlight
        if (is_hovered) {
            draw_set_color(c_yellow);
            draw_circle(node.x, node.y, nrad + 4, true);
            
            // Set contextual tooltip
            if (node.type == "tower") {
                var tow = state.towers[node.tower_idx];
                var wep_str = (is_undefined(tow.weapon) || !tow.weapon.alive) ? "No weapon mounted" : (tow.weapon.name + " (" + string(tow.weapon.hp) + "/" + string(tow.weapon.max_hp) + " HP, " + string(tow.weapon.damage) + " Dmg)");
                if (tow.manual_cooldown > 0) {
                    wep_str += "\n[Cooling Down: " + string(tow.manual_cooldown) + " turns left]";
                } else if (tow.manual_powers_this_turn > 0) {
                    wep_str += "\n[Powered: " + string(tow.manual_powers_this_turn) + "x this turn - will have " + string(tow.manual_powers_this_turn) + " turn cooldown]";
                }
                state.hover_tooltip = tow.name + " [Base Tower]\nHealth: " + string(tow.hp) + " / 10\nMounted Weapon: " + wep_str + "\n(Move here to manually fire mounted defense)";
                if (is_player_here && !is_undefined(tow.weapon) && tow.weapon.alive) {
                    state.hover_tooltip += "\n[You are here: Press [D] or click 'Dismantle' in action bar to destroy weapon & clear mount]";
                }
            } else if (node.type == "gather_forest") {
                state.hover_tooltip = "Forest Gathering Zone\nCosts 1 Energy to draw from the 50-card Forest Deck (Wood, Scrap, Events).";
            } else if (string_pos("gather_cave", node.type) > 0) {
                state.hover_tooltip = node.name + " Gathering Zone\nCosts 1 Energy to draw from the Cavern Deck (Stone, Scrap, Metal, Crystals, Power Gems, Events).";
            } else if (node.type == "town") {
                var cur_fav = state.town_favors[state.active_town_favor];
                state.hover_tooltip = "Town Market & Trading\nSell resources for Gold (Costs 1 Energy per trade).\nToday's Town Favor: " + cur_fav.name + " (" + cur_fav.desc + ")\n[Always viewable via Town Favor button or [T] key]";
            } else if (node.type == "workstation") {
                state.hover_tooltip = "Defense Workstation\nForge owned Blueprints into mounted defenses using resources.\nRepair damaged base towers & weapons (Workstation area only).";
            } else if (node.type == "shop") {
                state.hover_tooltip = "Weapon Blueprint Shop\nPurchase weapon blueprints using Gold (Forge them at Workstation).\n[Always viewable via Shop button or [S] key]";
            } else if (node.type == "main_base") {
                state.hover_tooltip = "Main Base Command Bunker\nCentral command room. Resources are pooled into team storage here.";
            }
            
            var m_cost = game_player_get_move_cost(cur_player);
            if (!is_player_here) {
                if (can_move_here) {
                    state.hover_tooltip += "\n[Connected - Click to Move (Costs " + string(m_cost) + " Energy)]";
                } else if (game_is_adjacent(state, cur_player.node, k)) {
                    state.hover_tooltip += "\n[Adjacent - Need " + string(m_cost) + " Energy to Move here]";
                }
            }
        } else if (!can_move_here || is_player_here) {
            draw_set_color(c_white);
            draw_circle(node.x, node.y, nrad, true);
        }
        
        // Node Type specifics
        if (node.type == "tower") {
            var tower = state.towers[node.tower_idx];
            if (tower.alive) {
                // High contrast dark badge plate for tower health
                var th_bw = 56;
                var th_bh = 22;
                draw_set_color(make_color_rgb(14, 20, 32));
                draw_roundrect_ext(node.x - th_bw * 0.5, node.y - th_bh * 0.5, node.x + th_bw * 0.5, node.y + th_bh * 0.5, 6, 6, false);
                draw_set_color(make_color_rgb(80, 110, 150));
                draw_roundrect_ext(node.x - th_bw * 0.5, node.y - th_bh * 0.5, node.x + th_bw * 0.5, node.y + th_bh * 0.5, 6, 6, true);
                
                // Tower Health: BLUE Heart Icon with a crisp WHITE border + BLUE number
                ui_draw_heart(node.x - 14, node.y, 14, make_color_rgb(33, 150, 243), c_white, 2);
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(100, 220, 255));
                draw_text(node.x + 1, node.y, string(tower.hp));
                
                // Stationed Weapon Badge on map: RED Heart Icon + RED number + Weapon Name (Dynamically sized to fit)
                if (!is_undefined(tower.weapon) && tower.weapon.alive && tower.weapon.hp > 0) {
                    var wep = tower.weapon;
                    var badge_str = string(wep.hp) + " " + wep.name;
                    var b_w = max(140, string_width(badge_str) + 36);
                    var b_h = 24;
                    var bx0 = node.x - b_w * 0.5;
                    var by0 = node.y - nrad - 26;
                    
                    draw_set_color(make_color_rgb(28, 20, 25));
                    draw_roundrect_ext(bx0, by0, bx0 + b_w, by0 + b_h, 6, 6, false);
                    draw_set_color(make_color_rgb(231, 76, 60));
                    draw_roundrect_ext(bx0, by0, bx0 + b_w, by0 + b_h, 6, 6, true);
                    
                    // Red Heart Icon
                    ui_draw_heart(bx0 + 12, by0 + 12, 12, make_color_rgb(231, 76, 60));
                    
                    // Weapon HP & Name in Red
                    draw_set_halign(fa_left); draw_set_valign(fa_middle);
                    draw_set_color(make_color_rgb(255, 120, 120));
                    draw_text(bx0 + 24, by0 + 12, badge_str);
                }
            } else {
                draw_set_color(c_red);
                draw_line_width(node.x - 15, node.y - 15, node.x + 15, node.y + 15, 3);
                draw_line_width(node.x - 15, node.y + 15, node.x + 15, node.y - 15, 3);
            }
        }
        
        // Label
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(c_white);
        draw_text(node.x, node.y + nrad + 6, node.label);
    }
    
    // Draw Board Action Shockwaves & Particles
    if (variable_struct_exists(state, "board_action_effects") && is_array(state.board_action_effects)) {
        for (var b = 0; b < array_length(state.board_action_effects); b++) {
            var ba = state.board_action_effects[b];
            var prog = ba.life / max(1, ba.max_life);
            var cur_r = prog * ba.max_radius;
            var cur_a = clamp((1.0 - prog) * 0.9, 0.0, 1.0);
            
            draw_set_alpha(cur_a);
            draw_set_color(ba.color);
            draw_circle(ba.x, ba.y, cur_r, true);
            if (cur_r > 6) {
                draw_circle(ba.x, ba.y, cur_r - 2, true);
            }
            
            // Particles
            for (var p = 0; p < array_length(ba.particles); p++) {
                var pt = ba.particles[p];
                var pt_a = clamp(pt.life / max(1, pt.max_life), 0.0, 1.0);
                draw_set_alpha(pt_a);
                draw_set_color(pt.color);
                if (pt.shape == "cross") {
                    draw_line_width(pt.x - pt.size, pt.y, pt.x + pt.size, pt.y, 2);
                    draw_line_width(pt.x, pt.y - pt.size, pt.x, pt.y + pt.size, 2);
                } else {
                    draw_circle(pt.x, pt.y, pt.size, false);
                }
            }
        }
        draw_set_alpha(1.0);
    }
    
    // Draw Player Pawns on nodes with animated gliding movement & action animations
    for (var p = 0; p < state.num_players; p++) {
        var pl = state.players[p];
        var pnode = state.nodes[$ pl.node];
        if (!is_undefined(pnode)) {
            var ox = (p - 1.5) * 16;
            var oy = (p % 2 == 0 ? -12 : 12);
            
            var px = variable_struct_exists(pl, "anim_x") ? pl.anim_x : (pnode.x + ox);
            var py = variable_struct_exists(pl, "anim_y") ? pl.anim_y : (pnode.y + oy);
            var hop = variable_struct_exists(pl, "hop_y") ? pl.hop_y : 0;
            
            // Action animation offsets and feedback
            var act_x = 0;
            var act_y = 0;
            if (variable_struct_exists(pl, "action_timer") && pl.action_timer > 0) {
                var anim = pl.action_anim;
                if (anim == "gather_forest" || anim == "gather_cave") {
                    act_y = -abs(sin(pl.action_timer * 0.45) * 10);
                    act_x = sin(pl.action_timer * 0.9) * 3;
                } else if (anim == "craft" || anim == "forge") {
                    act_x = ((pl.action_timer % 4) < 2) ? 4 : -4;
                    act_y = ((pl.action_timer % 4) < 2) ? -2 : 3;
                } else if (anim == "deposit" || anim == "trade") {
                    act_y = -abs(sin(pl.action_timer * 0.35) * 14);
                } else if (anim == "dismantle") {
                    act_x = sin(pl.action_timer * 0.8) * 6;
                } else if (anim == "repair") {
                    act_y = sin(pl.action_timer * 0.6) * 4;
                    act_x = cos(pl.action_timer * 0.6) * 4;
                } else if (anim == "fire") {
                    act_y = 6 * (pl.action_timer / max(1, pl.action_max));
                }
                
                // Pulsating action ring aura
                draw_set_color(make_color_rgb(255, 235, 59));
                draw_circle(px, py + hop, 18 + sin(current_time * 0.02) * 3, true);
            }
            
            // Ground drop shadow (scales with hop)
            var shadow_scale = clamp(1.0 - (-hop / 30.0), 0.35, 1.0);
            draw_set_alpha(0.45 * shadow_scale);
            draw_set_color(c_black);
            draw_ellipse(px - 11 * shadow_scale, py + 9 - 4 * shadow_scale, px + 11 * shadow_scale, py + 9 + 4 * shadow_scale, false);
            draw_set_alpha(1.0);
            
            var draw_pawn_x = px + act_x;
            var draw_pawn_y = py + hop + act_y;
            
            // Draw Pawn Body
            draw_set_color(c_black);
            draw_circle(draw_pawn_x, draw_pawn_y, 14, false);
            draw_set_color(pl.color);
            draw_circle(draw_pawn_x, draw_pawn_y, 12, false);
            draw_set_color(c_white);
            draw_circle(draw_pawn_x, draw_pawn_y, 12, true);
            
            // Active operative ring and floating indicator chevron
            if (p == state.current_player_idx) {
                var act_pulse = sin(current_time * 0.008) * 3;
                draw_set_color(c_yellow);
                draw_circle(draw_pawn_x, draw_pawn_y, 15 + act_pulse, true);
                
                // Pointer chevron ▼ pointing to active operative
                var ind_y = draw_pawn_y - 20 - abs(sin(current_time * 0.008) * 5);
                draw_set_color(c_yellow);
                draw_triangle(draw_pawn_x - 5, ind_y - 6, draw_pawn_x + 5, ind_y - 6, draw_pawn_x, ind_y, false);
                draw_set_color(c_black);
                draw_triangle(draw_pawn_x - 5, ind_y - 6, draw_pawn_x + 5, ind_y - 6, draw_pawn_x, ind_y, true);
            }
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(c_white);
            draw_text(draw_pawn_x, draw_pawn_y, string(p + 1));
        }
    }
    
    // Draw Floating Text Labels on the board
    if (variable_struct_exists(state, "floating_texts") && is_array(state.floating_texts)) {
        for (var f = 0; f < array_length(state.floating_texts); f++) {
            var ft = state.floating_texts[f];
            draw_set_alpha(ft.alpha);
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            
            // Drop shadow
            draw_set_color(c_black);
            draw_text(ft.x + 1, ft.y + 1, ft.text);
            draw_text(ft.x - 1, ft.y - 1, ft.text);
            draw_text(ft.x + 1, ft.y - 1, ft.text);
            draw_text(ft.x - 1, ft.y + 1, ft.text);
            
            // Foreground text
            draw_set_color(ft.color);
            draw_text(ft.x, ft.y, ft.text);
        }
        draw_set_alpha(1.0);
    }
}

function ui_draw_colored_log_entry(draw_x, draw_y, l, log_count, log_str, do_draw = true) {
    // 1. Determine Category & Importance
    var cat_tag = "INFO";
    var cat_col = make_color_rgb(120, 135, 155);
    var cat_bg = make_color_rgb(25, 32, 44);
    var is_important = false;
    var default_text_col = make_color_rgb(140, 155, 175); // Basic text color (muted cool slate)
    
    if (string_pos("[CHAT]", log_str) == 1) {
        cat_tag = "CHAT";
        cat_col = make_color_rgb(0, 229, 255);
        cat_bg = make_color_rgb(10, 42, 62);
        is_important = true;
        default_text_col = make_color_rgb(180, 245, 255);
    }
    else if (string_pos("DESTROYED", log_str) > 0 || string_pos("CRITICAL", log_str) > 0 || string_pos("FAILED", log_str) > 0 || string_pos("Humanity has fallen", log_str) > 0) {
        cat_tag = "CRIT";
        cat_col = make_color_rgb(255, 75, 75);
        cat_bg = make_color_rgb(60, 15, 15);
        is_important = true;
        default_text_col = make_color_rgb(255, 210, 210);
    }
    else if (string_pos("VICTORY", log_str) > 0 || string_pos("WAVE", log_str) > 0 || string_pos("Wave", log_str) > 0 || string_pos("Round", log_str) > 0 || string_pos("PHASE", log_str) > 0 || string_pos("A new day begins", log_str) > 0) {
        cat_tag = "WAVE";
        cat_col = make_color_rgb(255, 215, 0);
        cat_bg = make_color_rgb(50, 42, 10);
        is_important = true;
        default_text_col = make_color_rgb(255, 245, 190);
    }
    else if (string_pos("incinerated", log_str) > 0 || string_pos("obliterated", log_str) > 0 || string_pos("fired at", log_str) > 0 || string_pos("fired", log_str) > 0 || string_pos("discharges", log_str) > 0 || string_pos("splash", log_str) > 0 || string_pos("overcharged", log_str) > 0) {
        cat_tag = "DEFENSE";
        cat_col = make_color_rgb(255, 160, 60);
        cat_bg = make_color_rgb(55, 30, 10);
        is_important = true;
        default_text_col = make_color_rgb(255, 245, 225);
    }
    else if (string_pos("struck", log_str) > 0 || string_pos("deals", log_str) > 0 || string_pos("carpet bombs", log_str) > 0 || string_pos("drained", log_str) > 0 || string_pos("disabled", log_str) > 0 || string_pos("spawned", log_str) > 0 || string_pos("summoned", log_str) > 0 || string_pos("FROZEN", log_str) > 0 || string_pos("INCOMING", log_str) > 0) {
        cat_tag = "ALIEN";
        cat_col = make_color_rgb(225, 115, 235);
        cat_bg = make_color_rgb(50, 18, 55);
        is_important = true;
        default_text_col = make_color_rgb(245, 225, 255);
    }
    else if (string_pos("tanked", log_str) > 0 || string_pos("absorbed", log_str) > 0 || string_pos("OVERLOAD", log_str) > 0) {
        cat_tag = "SHIELD";
        cat_col = make_color_rgb(64, 196, 255);
        cat_bg = make_color_rgb(15, 40, 60);
        is_important = true;
        default_text_col = make_color_rgb(220, 245, 255);
    }
    else if (string_pos("repaired", log_str) > 0 || string_pos("Healed", log_str) > 0 || string_pos("healed", log_str) > 0) {
        cat_tag = "REPAIR";
        cat_col = make_color_rgb(105, 240, 174);
        cat_bg = make_color_rgb(15, 48, 28);
        is_important = true;
        default_text_col = make_color_rgb(225, 255, 235);
    }
    else if (string_pos("Perk", log_str) > 0 || string_pos("Immune", log_str) > 0) {
        cat_tag = "PERK";
        cat_col = make_color_rgb(76, 217, 100);
        cat_bg = make_color_rgb(15, 45, 20);
        is_important = true;
        default_text_col = make_color_rgb(230, 255, 235);
    }
    else if (string_pos("sold", log_str) > 0 || string_pos("Favor", log_str) > 0 || string_pos("reroll", log_str) > 0) {
        cat_tag = "TRADE";
        cat_col = make_color_rgb(255, 215, 0);
        cat_bg = make_color_rgb(45, 38, 12);
        is_important = false;
        default_text_col = make_color_rgb(240, 230, 200);
    }
    else if (string_pos("crafted", log_str) > 0 || string_pos("forged", log_str) > 0 || string_pos("stationed", log_str) > 0) {
        cat_tag = "CRAFT";
        cat_col = make_color_rgb(100, 210, 255);
        cat_bg = make_color_rgb(18, 42, 58);
        is_important = false;
        default_text_col = make_color_rgb(215, 235, 250);
    }
    else if (string_pos("drew", log_str) > 0 || string_pos("deposited", log_str) > 0 || string_pos("retrieved", log_str) > 0) {
        cat_tag = "LOOT";
        cat_col = make_color_rgb(129, 199, 132);
        cat_bg = make_color_rgb(18, 44, 25);
        is_important = false;
        default_text_col = make_color_rgb(215, 240, 220);
    }
    else if (string_pos("moved to", log_str) > 0) {
        cat_tag = "MOVE";
        cat_col = make_color_rgb(100, 149, 237);
        cat_bg = make_color_rgb(20, 30, 50);
        is_important = false;
        default_text_col = make_color_rgb(140, 155, 175);
    }
    else if (string_pos("Switched to", log_str) > 0 || string_pos("Energy", log_str) > 0) {
        cat_tag = "TURN";
        cat_col = make_color_rgb(140, 160, 185);
        cat_bg = make_color_rgb(25, 32, 42);
        is_important = false;
        default_text_col = make_color_rgb(140, 155, 175);
    }

    var cur_x = draw_x;

    // 2. Draw Index Number Badge [#42]
    var idx_str = "[" + string(log_count - l) + "] ";
    var idx_w = string_width(idx_str);
    if (do_draw) {
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(is_important ? make_color_rgb(140, 160, 190) : make_color_rgb(85, 100, 120));
        draw_text(cur_x, draw_y + 3, idx_str);
    }
    cur_x += idx_w;

    // 3. Draw Category Badge Pill
    var tag_pad_x = 4;
    var tag_text_w = string_width(cat_tag);
    var tag_total_w = tag_text_w + tag_pad_x * 2;
    if (do_draw) {
        draw_set_color(cat_bg);
        draw_roundrect_ext(cur_x, draw_y + 3, cur_x + tag_total_w, draw_y + 19, 4, 4, false);
        draw_set_color(cat_col);
        draw_roundrect_ext(cur_x, draw_y + 3, cur_x + tag_total_w, draw_y + 19, 4, 4, true);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_text(cur_x + tag_total_w * 0.5, draw_y + 11, cat_tag);
    }
    cur_x += tag_total_w + 6;

    // 4. Tokenize and Draw Words with Custom Thematic Colors
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    var words = string_split(log_str, " ");
    var space_w = string_width(" ");
    var num_words = array_length(words);

    for (var w = 0; w < num_words; w++) {
        var word = words[w];
        if (word == "") continue;
        
        var clean = string_lower(string_lettersdigits(word));
        var next_clean = (w < num_words - 1) ? string_lower(string_lettersdigits(words[w + 1])) : "";
        var w_col = default_text_col;

        // Check contextual modifiers and prefixes:
        // Prefixes (+ / -)
        if (string_pos("+", word) > 0 || clean == "bonus") {
            w_col = make_color_rgb(105, 240, 174); // Green for positive bonus/gain
        } else if (string_pos("-", word) > 0 && string_length(clean) > 0 && (clean == "1" || clean == "2" || clean == "3" || clean == "4")) {
            w_col = make_color_rgb(255, 90, 80); // Red for penalty/loss
        }
        // Resources (Word itself or number directly before resource)
        else if (clean == "wood" || clean == "lumber" || next_clean == "wood" || next_clean == "lumber") {
            w_col = make_color_rgb(205, 140, 85); // Wood brown/amber
        } else if (clean == "stone" || next_clean == "stone") {
            w_col = make_color_rgb(180, 190, 200); // Stone grey
        } else if (clean == "scrap" || clean == "scraps" || next_clean == "scrap" || next_clean == "scraps") {
            w_col = make_color_rgb(215, 145, 95); // Scrap rusty copper
        } else if (clean == "metal" || next_clean == "metal") {
            w_col = make_color_rgb(225, 235, 245); // Metal silver
        } else if (clean == "crystal" || clean == "crystals" || next_clean == "crystals" || next_clean == "crystal") {
            w_col = make_color_rgb(0, 229, 255); // Cyan crystal
        } else if (clean == "power" || clean == "gem" || clean == "gems" || next_clean == "gem" || next_clean == "gems") {
            w_col = make_color_rgb(224, 64, 251); // Power gem magenta
        } else if (clean == "gold" || string_pos("gold", clean) > 0 || next_clean == "gold" || clean == "favor") {
            w_col = make_color_rgb(255, 215, 0); // Coin gold
        }
        // Combat stats & Numbers (Word itself or number directly before damage/hp/energy)
        else if (clean == "damage" || clean == "dmg" || string_pos("dmg", clean) > 0 || next_clean == "damage" || next_clean == "dmg" || clean == "incinerated" || clean == "obliterated" || clean == "struck") {
            w_col = make_color_rgb(255, 100, 60); // Fiery attack/damage red-orange
        } else if (clean == "hp" || string_pos("hp", clean) > 0 || next_clean == "hp" || clean == "healed" || clean == "repaired") {
            w_col = make_color_rgb(105, 240, 174); // Health green
        } else if (clean == "energy" || clean == "overcharged" || next_clean == "energy") {
            w_col = make_color_rgb(255, 235, 59); // Energy yellow
        }
        // Aliens & Bosses
        else if (clean == "alien" || clean == "aliens" || clean == "queen" || clean == "drooper" || clean == "leech" || clean == "syphon" || clean == "hatcher" || clean == "hatchling" || clean == "hatchlings" || clean == "spitter" || clean == "stalker" || clean == "weaver") {
            w_col = make_color_rgb(225, 115, 235); // Alien violet
        } else if (clean == "emp" || clean == "frozen" || clean == "thawed") {
            w_col = make_color_rgb(80, 220, 255); // EMP/Ice blue
        }
        // Weapons & Defenses
        else if (clean == "turret" || clean == "flamethrower" || clean == "railgun" || clean == "tesla" || clean == "mortar" || clean == "pylon" || clean == "shield" || clean == "generator" || clean == "drone") {
            w_col = make_color_rgb(255, 183, 77); // Tech weapon amber
        } else if (clean == "tower" || clean == "towers" || clean == "base") {
            w_col = make_color_rgb(80, 175, 255); // Tower blue
        }
        // Critical alerts
        else if (clean == "destroyed" || clean == "critical" || clean == "failed" || clean == "alert") {
            w_col = make_color_rgb(255, 60, 60); // Alarm scarlet
        }
        // Players
        else if (clean == "player" || clean == "survivor" || clean == "scout" || clean == "engineer" || clean == "miner" || clean == "gunner" || clean == "pathfinder") {
            w_col = make_color_rgb(130, 220, 255); // Operative sky-blue
        }
        // Perks & Victory
        else if (clean == "perk" || clean == "immune" || clean == "victory") {
            w_col = make_color_rgb(105, 240, 174); // Perk green / gold
        }

        if (do_draw) {
            draw_set_color(w_col);
            draw_text(cur_x, draw_y + 3, word);
        }
        cur_x += string_width(word) + space_w;
    }

    return cur_x - draw_x;
}

function ui_draw_right_panel(state, mx, my) {
    var rx = 1520;
    var ry = 50;
    var rw = 380;
    
    // -------------------------------------------------------------
    // TOP SECTION: WAVE INFO, TOWERS & WEAPON STATUS
    // -------------------------------------------------------------
    var top_box_h = 300;
    draw_set_color(make_color_rgb(26, 32, 44));
    draw_roundrect_ext(rx, ry, rx + rw, ry + top_box_h, 14, 14, false);
    draw_set_color(make_color_rgb(52, 73, 94));
    draw_roundrect_ext(rx, ry, rx + rw, ry + top_box_h, 14, 14, true);
    
    // Round info header
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    var wave_text = (state.round_number <= 17) ? ("WAVE " + string(state.round_number) + " / 17") : ("ENDLESS WAVE " + string(state.round_number));
    draw_text(rx + 16, ry + 10, wave_text);
    
    draw_set_color(c_white);
    var phase_str = "Phase: ";
    if (state.phase == "player_actions") phase_str += "Player Action Turn";
    else if (state.phase == "combat_weapons") phase_str += "Weapons Defending";
    else if (state.phase == "combat_aliens") phase_str += "Alien Assault";
    draw_text(rx + 16, ry + 30, phase_str);
    
    // -------------------------------------------------------------
    // BASE TOWERS (TOWER HP: BLUE)
    // -------------------------------------------------------------
    draw_set_color(make_color_rgb(100, 180, 255));
    draw_text(rx + 16, ry + 52, "-- BASE TOWERS (TOWER HP: BLUE) --");
    
    for (var t = 0; t < 4; t++) {
        var tow = state.towers[t];
        var ty = ry + 72 + t * 24;
        
        // Tower label
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(tow.alive ? c_white : c_red);
        draw_text(rx + 16, ty + 9, "T" + string(t + 1) + ":");
        
        // Blue Heart Icon for Tower Health
        ui_draw_heart(rx + 58, ty + 9, 13, tow.alive ? make_color_rgb(33, 150, 243) : make_color_rgb(90, 90, 90));
        
        // Bar
        var bx = rx + 75;
        var bw = rw - 95;
        var bh = 17;
        draw_set_color(make_color_rgb(30, 36, 48));
        draw_roundrect_ext(bx, ty, bx + bw, ty + bh, 4, 4, false);
        
        if (tow.alive && tow.hp > 0) {
            var fill_w = (tow.hp / tow.max_hp) * bw;
            draw_set_color(make_color_rgb(33, 150, 243));
            draw_roundrect_ext(bx, ty, bx + fill_w, ty + bh, 4, 4, false);
        }
        draw_set_color(tow.alive ? make_color_rgb(80, 140, 200) : make_color_rgb(100, 60, 60));
        draw_roundrect_ext(bx, ty, bx + bw, ty + bh, 4, 4, true);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(tow.alive ? make_color_rgb(220, 240, 255) : c_red);
        draw_text(bx + bw * 0.5, ty + 9, tow.alive ? (string(tow.hp) + " / 10 HP") : "DESTROYED");
    }
    
    // -------------------------------------------------------------
    // TOWER WEAPON MOUNTS (WEAPON HP: RED)
    // -------------------------------------------------------------
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(255, 138, 128));
    draw_text(rx + 16, ry + 172, "-- WEAPON DEFENSES (WEAPON HP: RED) --");
    
    for (var t = 0; t < 4; t++) {
        var tow = state.towers[t];
        var wy = ry + 192 + t * 24;
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(rx + 16, wy + 9, "T" + string(t + 1) + ":");
        
        if (!tow.alive) {
            draw_set_color(make_color_rgb(160, 80, 80));
            draw_text(rx + 52, wy + 9, "[Tower Destroyed]");
        } else if (is_undefined(tow.weapon) || !tow.weapon.alive) {
            draw_set_color(make_color_rgb(120, 130, 140));
            draw_text(rx + 52, wy + 9, "[No Weapon Mounted]");
        } else {
            var wep = tow.weapon;
            // Red Heart Icon for Weapon Health
            ui_draw_heart(rx + 58, wy + 9, 13, make_color_rgb(231, 76, 60));
            
            // Weapon HP in Red
            draw_set_color(make_color_rgb(255, 110, 110));
            var hp_str = string(wep.hp) + "/" + string(wep.max_hp);
            draw_text(rx + 72, wy + 9, hp_str);
            
            // Weapon Name and Damage in White/Yellow
            draw_set_color(c_white);
            var wep_tag = wep.name + " (" + string(wep.damage) + "d)";
            if (tow.manual_cooldown > 0) wep_tag += " [CD:" + string(tow.manual_cooldown) + "]";
            else if (tow.manual_powers_this_turn > 0) wep_tag += " [Pwr:" + string(tow.manual_powers_this_turn) + "]";
            if (wep.disabled) wep_tag += " [EMP]";
            if (string_length(wep_tag) > 25) wep_tag = string_copy(wep_tag, 1, 23) + "..";
            draw_text(rx + 132, wy + 9, wep_tag);
        }
    }
    
    // -------------------------------------------------------------
    // BOTTOM SECTION: ACTION & COMBAT LOGS (DRAGGABLE & 2D SCROLLABLE)
    // -------------------------------------------------------------
    var log_x = variable_struct_exists(state, "action_log_x") ? state.action_log_x : 1520;
    log_x = clamp(log_x, 250, 1520);
    state.action_log_x = log_x;
    
    var log_y = 362;
    var log_y2 = 622;
    var log_w = 1900 - log_x;
    var log_h = log_y2 - log_y;
    
    // Container background (opaque to cover the map when expanded to the left)
    draw_set_color(make_color_rgb(22, 28, 38));
    draw_roundrect_ext(log_x, log_y, 1900, log_y2, 12, 12, false);
    draw_set_color(make_color_rgb(52, 73, 94));
    draw_roundrect_ext(log_x, log_y, 1900, log_y2, 12, 12, true);
    
    // Left border drag handle
    var handle_hov = point_in_rectangle(mx, my, log_x - 8, log_y, log_x + 8, log_y2);
    state.action_log_resizer_hover = handle_hov;
    
    var handle_col = (state.action_log_dragging || handle_hov) ? make_color_rgb(0, 229, 255) : make_color_rgb(60, 85, 115);
    draw_set_color(handle_col);
    draw_line_width(log_x, log_y, log_x, log_y2, (state.action_log_dragging || handle_hov) ? 3 : 2);
    
    // Handle grip tab pill
    var grip_y = log_y + log_h * 0.5;
    draw_set_color(make_color_rgb(18, 24, 34));
    draw_roundrect_ext(log_x - 7, grip_y - 20, log_x + 7, grip_y + 20, 6, 6, false);
    draw_set_color(handle_col);
    draw_roundrect_ext(log_x - 7, grip_y - 20, log_x + 7, grip_y + 20, 6, 6, true);
    
    draw_set_color((state.action_log_dragging || handle_hov) ? c_white : make_color_rgb(140, 165, 195));
    draw_line_width(log_x - 2, grip_y - 10, log_x - 2, grip_y + 10, 1);
    draw_line_width(log_x + 2, grip_y - 10, log_x + 2, grip_y + 10, 1);
    
    // Header text (no buttons here so text is never overlapped)
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(180, 215, 255));
    var log_count = array_length(state.action_logs);
    draw_text(log_x + 14, log_y + 14, "-- ACTION & COMBAT LOGS -- (" + string(log_count) + ")");
    
    // Inner Log View Box
    var box_x = log_x + 12;
    var box_y = log_y + 28;
    var box_w = (1900 - 12) - box_x;
    var box_h = (log_y2 - 68) - box_y;
    
    draw_set_color(make_color_rgb(15, 19, 27));
    draw_roundrect_ext(box_x, box_y, box_x + box_w, box_y + box_h, 8, 8, false);
    draw_set_color(make_color_rgb(42, 54, 74));
    draw_roundrect_ext(box_x, box_y, box_x + box_w, box_y + box_h, 8, 8, true);
    
    // Viewport dimensions for scrolling & clipping
    var view_x = box_x + 4;
    var view_y = box_y + 4;
    var view_w = max(10, box_w - 18);
    var view_h = max(10, box_h - 18);
    
    var line_h = 24;
    var total_h = log_count * line_h;
    
    var max_text_w = view_w;
    for (var i = 0; i < log_count; i++) {
        var ew = ui_draw_colored_log_entry(0, 0, i, log_count, state.action_logs[i], false);
        if (ew > max_text_w) max_text_w = ew;
    }
    
    var max_scroll_y = max(0, total_h - view_h);
    var max_scroll_x = max(0, max_text_w + 30 - view_w);
    state.action_log_max_scroll_y = max_scroll_y;
    state.action_log_max_scroll_x = max_scroll_x;
    state.action_log_scroll_y = clamp(state.action_log_scroll_y, 0, max_scroll_y);
    state.action_log_scroll_x = clamp(state.action_log_scroll_x, 0, max_scroll_x);
    
    var surf_w = max(1, floor(view_w));
    var surf_h = max(1, floor(view_h));
    
    if (!variable_struct_exists(state, "action_log_surf") || is_undefined(state.action_log_surf) || !surface_exists(state.action_log_surf)) {
        state.action_log_surf = surface_create(surf_w, surf_h);
    } else if (surface_get_width(state.action_log_surf) != surf_w || surface_get_height(state.action_log_surf) != surf_h) {
        surface_free(state.action_log_surf);
        state.action_log_surf = surface_create(surf_w, surf_h);
    }
    
    surface_set_target(state.action_log_surf);
    draw_clear_alpha(c_black, 0);
    draw_set_valign(fa_top);
    
    var start_line = max(0, floor(state.action_log_scroll_y / line_h));
    var end_line = min(log_count - 1, ceil((state.action_log_scroll_y + view_h) / line_h));
    
    for (var l = start_line; l <= end_line; l++) {
        var ly = (l * line_h) - state.action_log_scroll_y;
        var lx = 6 - state.action_log_scroll_x;
        ui_draw_colored_log_entry(lx, ly, l, log_count, state.action_logs[l], true);
    }
    
    surface_reset_target();
    draw_surface(state.action_log_surf, view_x, view_y);
    
    // Vertical Scrollbar
    var v_track_x = box_x + box_w - 12;
    var v_track_y = box_y + 4;
    var v_track_w = 8;
    var v_track_h = view_h;
    
    draw_set_color(make_color_rgb(24, 30, 42));
    draw_roundrect_ext(v_track_x, v_track_y, v_track_x + v_track_w, v_track_y + v_track_h, 4, 4, false);
    
    if (total_h > view_h) {
        var thumb_h = max(22, (view_h / total_h) * v_track_h);
        var thumb_y = v_track_y + (state.action_log_scroll_y / max_scroll_y) * (v_track_h - thumb_h);
        var thumb_hov = point_in_rectangle(mx, my, v_track_x - 3, thumb_y, v_track_x + v_track_w + 3, thumb_y + thumb_h);
        state.action_log_v_thumb_hover = thumb_hov;
        state.action_log_usable_v_track = max(1, v_track_h - thumb_h);
        
        var thumb_col = (state.action_log_v_drag || thumb_hov) ? make_color_rgb(100, 160, 230) : make_color_rgb(60, 80, 110);
        draw_set_color(thumb_col);
        draw_roundrect_ext(v_track_x, thumb_y, v_track_x + v_track_w, thumb_y + thumb_h, 4, 4, false);
    } else {
        state.action_log_v_thumb_hover = false;
        state.action_log_usable_v_track = 1;
    }
    
    // Horizontal Scrollbar
    var h_track_x = box_x + 4;
    var h_track_y = box_y + box_h - 12;
    var h_track_w = view_w;
    var h_track_h = 8;
    
    draw_set_color(make_color_rgb(24, 30, 42));
    draw_roundrect_ext(h_track_x, h_track_y, h_track_x + h_track_w, h_track_y + h_track_h, 4, 4, false);
    
    if (max_text_w + 30 > view_w) {
        var thumb_w = max(24, (view_w / (max_text_w + 30)) * h_track_w);
        var thumb_x = h_track_x + (state.action_log_scroll_x / max_scroll_x) * (h_track_w - thumb_w);
        var thumb_hov = point_in_rectangle(mx, my, thumb_x, h_track_y - 3, thumb_x + thumb_w, h_track_y + h_track_h + 3);
        state.action_log_h_thumb_hover = thumb_hov;
        state.action_log_usable_h_track = max(1, h_track_w - thumb_w);
        
        var thumb_col = (state.action_log_h_drag || thumb_hov) ? make_color_rgb(100, 160, 230) : make_color_rgb(60, 80, 110);
        draw_set_color(thumb_col);
        draw_roundrect_ext(thumb_x, h_track_y, thumb_x + thumb_w, h_track_y + h_track_h, 4, 4, false);
    } else {
        state.action_log_h_thumb_hover = false;
        state.action_log_usable_h_track = 1;
    }
    
    // -------------------------------------------------------------
    // LIVE CHAT INPUT BAR: Send messages to team / Wi-Fi lobby
    // -------------------------------------------------------------
    var chat_y = log_y2 - 62;
    var chat_h = 26;
    var chat_total_w = (1900 - 12) - (log_x + 12);
    var send_w = 64;
    var inp_w = chat_total_w - send_w - 6;
    var inp_x = log_x + 12;
    var send_x = inp_x + inp_w + 6;
    
    var is_chat_active = (variable_struct_exists(state, "chat_input_active") && state.chat_input_active);
    var chat_hov = ui_point_in_rect(mx, my, inp_x, chat_y, inp_w, chat_h);
    state.chat_input_hover = chat_hov;
    
    draw_set_color(is_chat_active ? make_color_rgb(18, 30, 48) : (chat_hov ? make_color_rgb(16, 24, 36) : make_color_rgb(12, 16, 24)));
    draw_roundrect_ext(inp_x, chat_y, inp_x + inp_w, chat_y + chat_h, 6, 6, false);
    draw_set_color(is_chat_active ? make_color_rgb(0, 229, 255) : (chat_hov ? c_white : make_color_rgb(45, 65, 95)));
    draw_roundrect_ext(inp_x, chat_y, inp_x + inp_w, chat_y + chat_h, 6, 6, true);
    
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    var disp_chat = variable_struct_exists(state, "chat_input_text") ? state.chat_input_text : "";
    if (is_chat_active) {
        if ((state.chat_cursor_timer div 25) % 2 == 0) disp_chat += "|";
        draw_set_color(c_white);
        draw_text(inp_x + 8, chat_y + chat_h * 0.5, disp_chat);
    } else {
        draw_set_color(make_color_rgb(110, 135, 165));
        var placeholder = (disp_chat != "") ? disp_chat : "Chat to squad... [Click or press T]";
        draw_text(inp_x + 8, chat_y + chat_h * 0.5, placeholder);
    }
    
    // Send Button
    state.chat_send_hover = ui_draw_button(send_x, chat_y, send_w, chat_h, "SEND", true, is_chat_active, mx, my);
    
    // -------------------------------------------------------------
    // BOTTOM CONTROLS BAR: Action log navigation buttons at bottom of UI box
    // -------------------------------------------------------------
    var footer_y = log_y2 - 30;
    
    // Left: Expand / Collapse window button
    var btn_toggle_w = 115;
    var btn_toggle_x = log_x + 12;
    var toggle_lbl = (log_x < 1400) ? "> Collapse" : "< Expand";
    state.action_log_btn_toggle_hover = ui_draw_button(btn_toggle_x, footer_y, btn_toggle_w, 24, toggle_lbl, true, (log_x < 1400), mx, my);
    
    // Right: Directional scroll buttons (<, >, ^, v) and Top reset button
    var btn_arr_w = 26;
    var btn_down_x = 1888 - btn_arr_w;
    var btn_up_x = btn_down_x - btn_arr_w - 4;
    var btn_right_x = btn_up_x - btn_arr_w - 6;
    var btn_left_x = btn_right_x - btn_arr_w - 4;
    
    var btn_top_w = 42;
    var btn_top_x = btn_left_x - btn_top_w - 6;
    
    state.action_log_btn_top_hover = ui_draw_button(btn_top_x, footer_y, btn_top_w, 24, "Top", true, (state.action_log_scroll_y == 0), mx, my);
    state.action_log_btn_left_hover = ui_draw_button(btn_left_x, footer_y, btn_arr_w, 24, "<", true, false, mx, my);
    state.action_log_btn_right_hover = ui_draw_button(btn_right_x, footer_y, btn_arr_w, 24, ">", true, false, mx, my);
    state.action_log_btn_up_hover = ui_draw_button(btn_up_x, footer_y, btn_arr_w, 24, "^", true, false, mx, my);
    state.action_log_btn_down_hover = ui_draw_button(btn_down_x, footer_y, btn_arr_w, 24, "v", true, false, mx, my);
    
    if (state.action_log_btn_toggle_hover) {
        state.hover_tooltip = (log_x < 1400) ? "Collapse action log back to right panel" : "Expand action log to cover map";
    } else if (state.action_log_btn_top_hover) {
        state.hover_tooltip = "Scroll log to newest / top entry";
    } else if (state.action_log_btn_left_hover) {
        state.hover_tooltip = "Scroll log left";
    } else if (state.action_log_btn_right_hover) {
        state.hover_tooltip = "Scroll log right";
    } else if (state.action_log_btn_up_hover) {
        state.hover_tooltip = "Scroll log up";
    } else if (state.action_log_btn_down_hover) {
        state.hover_tooltip = "Scroll log down";
    }
}

function ui_draw_bottom_panel(state, mx, my) {
    var px = 20;
    var py = 635;
    var pw = 1880;
    var ph = 435;
    
    // Panel container
    draw_set_color(make_color_rgb(20, 24, 33));
    draw_roundrect_ext(px, py, px + pw, py + ph, 16, 16, false);
    draw_set_color(make_color_rgb(52, 73, 94));
    draw_roundrect_ext(px, py, px + pw, py + ph, 16, 16, true);
    
    // -------------------------------------------------------------
    // 1. RESOURCE METER (Lumber, Gold, Scrap, Stone, Crystals, Power Gems, Metal)
    // -------------------------------------------------------------
    var res_box_x = px + 15;
    var res_box_y = py + 10;
    var res_w = 88;
    var res_h = 68;
    
    var res_order = [
        { key: "wood", label: "Lumber", col: make_color_rgb(141, 110, 99), tcol: c_white },
        { key: "gold", label: "Gold", col: make_color_rgb(255, 215, 0), tcol: make_color_rgb(20, 20, 20) },
        { key: "scrap", label: "Scrap", col: make_color_rgb(158, 158, 158), tcol: make_color_rgb(20, 20, 20) },
        { key: "stone", label: "Stone", col: make_color_rgb(120, 144, 156), tcol: c_white },
        { key: "crystals", label: "Crystals", col: make_color_rgb(0, 229, 255), tcol: make_color_rgb(15, 25, 40) },
        { key: "power_gem", label: "Power Gem", col: make_color_rgb(224, 64, 251), tcol: c_white },
        { key: "metal", label: "Metal", col: make_color_rgb(207, 216, 220), tcol: make_color_rgb(20, 25, 35) }
    ];
    
    draw_set_halign(fa_center); draw_set_valign(fa_top);
    for (var r = 0; r < array_length(res_order); r++) {
        var ro = res_order[r];
        var rx = res_box_x + r * (res_w + 5);
        
        // Slot border
        draw_set_color(make_color_rgb(30, 38, 50));
        draw_rectangle(rx, res_box_y, rx + res_w, res_box_y + res_h, false);
        draw_set_color(make_color_rgb(60, 75, 95));
        draw_rectangle(rx, res_box_y, rx + res_w, res_box_y + res_h, true);
        
        // Label - ensure uniform top alignment for every single resource slot
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(c_white);
        draw_text(rx + res_w * 0.5, res_box_y + 4, ro.label);
        
        var val = state.storage[$ ro.key];
        
        // Resource Token: Colored circle with quantity number inside (No dice!)
        var rcx = rx + res_w * 0.5;
        var rcy = res_box_y + 42;
        var rrad = 18;
        
        draw_set_color(ro.col);
        draw_circle(rcx, rcy, rrad, false);
        draw_set_color(c_white);
        draw_circle(rcx, rcy, rrad, true);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(ro.tcol);
        draw_text(rcx, rcy, string(val));
    }
    
    // -------------------------------------------------------------
    // 2. ACTIVE PLAYER BAR OR WEAPONS DEFENSE TACTICAL CONSOLE
    // -------------------------------------------------------------
    if (state.phase == "combat_weapons" || state.phase == "combat_aliens") {
        var console_x = res_box_x + 7 * (res_w + 5) + 12;
        var console_w = (px + pw - 15) - console_x;
        var console_h = res_h;
        
        draw_set_color(make_color_rgb(18, 24, 36));
        draw_roundrect_ext(console_x, res_box_y, console_x + console_w, res_box_y + console_h, 8, 8, false);
        draw_set_color(make_color_rgb(0, 229, 255));
        draw_roundrect_ext(console_x, res_box_y, console_x + console_w, res_box_y + console_h, 8, 8, true);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_text(console_x + console_w * 0.5, res_box_y + console_h * 0.5, "TACTICAL COMBAT CONSOLE ACTIVE // TARGETING DISPLAY IN MISSION WINDOW ABOVE");
        
        // Clear standard action button hovers
        state.btn_gather_hover = false;
        state.btn_craft_hover = false;
        state.btn_dismantle_hover = false;
        state.btn_shop_hover = false;
        state.btn_repair_hover = false;
        state.btn_town_hover = false;
        state.btn_fire_hover = false;
        state.btn_endturn_hover = false;
        state.btn_combat_hover = false;
    }
    else {
        // Standard Active Player Bar & Status
        var p_panel_x = res_box_x + 7 * (res_w + 5) + 12;
        var p_panel_w = 345;
        var cur_p = state.players[state.current_player_idx];
        
        draw_set_color(make_color_rgb(30, 38, 50));
        draw_roundrect_ext(p_panel_x, res_box_y, p_panel_x + p_panel_w, res_box_y + res_h, 8, 8, false);
        draw_set_color(cur_p.color);
        draw_roundrect_ext(p_panel_x, res_box_y, p_panel_x + p_panel_w, res_box_y + res_h, 8, 8, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(cur_p.color);
        draw_text(p_panel_x + 12, res_box_y + 5, cur_p.name + " (Active Turn)");
        
        // Centered Energy Row: Exact counter and yellow lightning bolt icons that scale cleanly to fit
        var energy_row_y = res_box_y + 31;
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        var e_txt = "Energy: " + string(cur_p.energy) + "/" + string(cur_p.max_energy);
        draw_text(p_panel_x + 12, energy_row_y, e_txt);
        
        var energy_label_w = string_width(e_txt);
        var avail_bolt_w = (p_panel_w - 20) - (12 + energy_label_w + 10);
        var bolt_spacing = clamp(floor(avail_bolt_w / max(1, cur_p.max_energy)), 10, 20);
        var bolt_size = clamp(bolt_spacing - 2, 8, 16);
        var start_bolt_x = p_panel_x + 12 + energy_label_w + 10;
        
        for (var e = 0; e < cur_p.max_energy; e++) {
            var bx = start_bolt_x + e * bolt_spacing;
            var has_energy = (e < cur_p.energy);
            ui_draw_lightning(bx, energy_row_y, bolt_size, has_energy);
        }
        
        // Perk / Role Tag
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(make_color_rgb(170, 205, 240));
        var perk_disp = cur_p.character.name + " (" + cur_p.character.perk_tag + ")";
        if (string_length(perk_disp) > 36) perk_disp = string_copy(perk_disp, 1, 34) + "..";
        draw_text(p_panel_x + 12, res_box_y + 47, perk_disp);
        
        // -------------------------------------------------------------
        // 3. ACTION BUTTONS (Clean 2-Row Grid on Top Right)
        // -------------------------------------------------------------
        var btn_x0 = p_panel_x + p_panel_w + 14;
        var btn_y1 = res_box_y;
        var btn_y2 = res_box_y + 35;
        var btn_w1 = 195;
        var btn_w2 = 215;
        var btn_h = 31;
        
        var is_scout = (variable_struct_exists(cur_p, "character") && cur_p.character.id == "scout");
        var task_cost = is_scout ? 2 : 1;
        
        var cur_node = state.nodes[$ cur_p.node];
        var can_gather = (cur_p.energy >= task_cost && (cur_node.type == "gather_forest" || string_pos("gather_cave", cur_node.type) > 0));
        var can_craft = (cur_p.energy >= task_cost && (cur_p.node == "main_base" || cur_p.node == "workstation"));
        var can_shop = true; // Always viewable from anywhere
        var can_repair = true; // Always viewable from anywhere
        var can_town = true; // Always viewable from anywhere
        
        // Check if player is on a tower space to fire mounted weapon or dismantle
        var cur_tower_idx = -1;
        if (cur_p.node == "tower_1") cur_tower_idx = 0;
        else if (cur_p.node == "tower_2") cur_tower_idx = 1;
        else if (cur_p.node == "tower_3") cur_tower_idx = 2;
        else if (cur_p.node == "tower_4") cur_tower_idx = 3;
        
        var cur_tower_has_wep = (cur_tower_idx >= 0 && !is_undefined(state.towers[cur_tower_idx].weapon) && state.towers[cur_tower_idx].weapon.alive && state.towers[cur_tower_idx].weapon.damage > 0);
        var cur_tower_has_any_wep = (cur_tower_idx >= 0 && !is_undefined(state.towers[cur_tower_idx].weapon) && state.towers[cur_tower_idx].weapon.alive && state.towers[cur_tower_idx].weapon.hp > 0);
        var cur_tower_cd = (cur_tower_idx >= 0) ? state.towers[cur_tower_idx].manual_cooldown : 0;
        var cur_tower_powers = (cur_tower_idx >= 0) ? state.towers[cur_tower_idx].manual_powers_this_turn : 0;
        var fire_cost = 2;
        for (var i = 0; i < array_length(state.weapons); i++) {
            if (state.weapons[i].alive && state.weapons[i].catalog_id == "overcharge_pylon") {
                fire_cost = 1;
                break;
            }
        }
        if (variable_struct_exists(cur_p, "character")) {
            if (cur_p.character.id == "gunner") {
                fire_cost = 1; // Gunner firing weapon costs only 1 energy instead of 2
            } else if (cur_p.character.id == "scout") {
                fire_cost = 2; // Scout tasks cost 2 energy
            }
        }
        var can_fire = (cur_tower_has_wep && cur_tower_cd <= 0 && cur_p.energy >= fire_cost && array_length(state.active_zone) > 0);
        var fire_lbl = "At Tower Only";
        if (cur_tower_idx >= 0) {
            if (!cur_tower_has_wep) fire_lbl = "No Weapon";
            else if (cur_tower_cd > 0) fire_lbl = "Cooldown (" + string(cur_tower_cd) + "T)";
            else if (cur_tower_powers > 0) fire_lbl = "Fire (" + string(fire_cost) + "E) [#" + string(cur_tower_powers + 1) + "]";
            else fire_lbl = "Fire (" + string(fire_cost) + "E)";
        }
        
        var gather_lbl = is_scout ? "Gather (2E) [G]" : "Gather (1E) [G]";
        var craft_lbl = is_scout ? "Craft Metal (2E)" : "Craft Metal [C]";
        state.btn_dismantle_hover = false;
        if (cur_tower_has_any_wep) {
            craft_lbl = is_scout ? "Dismantle (2E) [D]" : "Dismantle (1E) [D]";
            can_craft = (cur_p.energy >= task_cost);
        }
        
        var shop_lbl = (cur_p.node == "shop") ? (is_scout ? "Shop (2E) [S]" : "Shop (1E) [S]") : "View Shop [S]";
        var repair_lbl = (cur_p.node == "workstation") ? (is_scout ? "Workstation (2E) [R]" : "Workstation [R]") : "Workstation [R]";
        var town_lbl = (cur_p.node == "town") ? (is_scout ? "Town Trade (2E) [T]" : "Town Trade [T]") : "Town Favor [T]";
        
        // Row 1
        state.btn_gather_hover = ui_draw_button(btn_x0, btn_y1, btn_w1, btn_h, gather_lbl, can_gather, false, mx, my);
        var chov = ui_draw_button(btn_x0 + (btn_w1 + 8), btn_y1, btn_w1, btn_h, craft_lbl, can_craft, false, mx, my);
        if (cur_tower_has_any_wep) {
            state.btn_dismantle_hover = chov;
            state.btn_craft_hover = false;
            if (chov) {
                state.hover_tooltip = "Dismantle mounted weapon to clear mount (+1 Scrap salvaged).";
            }
        } else {
            state.btn_craft_hover = chov;
        }
        state.btn_shop_hover = ui_draw_button(btn_x0 + 2 * (btn_w1 + 8), btn_y1, btn_w1, btn_h, shop_lbl, can_shop, (cur_p.node == "shop"), mx, my);
        state.btn_repair_hover = ui_draw_button(btn_x0 + 3 * (btn_w1 + 8), btn_y1, btn_w2, btn_h, repair_lbl, can_repair, (cur_p.node == "workstation"), mx, my);
        
        // Row 2
        state.btn_town_hover = ui_draw_button(btn_x0, btn_y2, btn_w1, btn_h, town_lbl, can_town, (cur_p.node == "town"), mx, my);
        state.btn_fire_hover = ui_draw_button(btn_x0 + (btn_w1 + 8), btn_y2, btn_w1, btn_h, fire_lbl, can_fire, false, mx, my);
        state.btn_endturn_hover = ui_draw_button(btn_x0 + 2 * (btn_w1 + 8), btn_y2, btn_w1, btn_h, "Pass Turn", true, false, mx, my);
        var combat_btn_text = (array_length(state.active_zone) > 0) ? "Begin Defense [Space]" : "Next Day [Space]";
        state.btn_combat_hover = ui_draw_button(btn_x0 + 3 * (btn_w1 + 8), btn_y2, btn_w2, btn_h, combat_btn_text, true, true, mx, my);
        if (state.btn_combat_hover) {
            if (array_length(state.active_zone) > 0) {
                state.hover_tooltip = "End operative actions and engage active hostiles in tactical combat.";
            } else {
                state.hover_tooltip = "No active hostiles attacking. Conclude turn and advance to the next day.";
            }
        }
    }
    
    // -------------------------------------------------------------
    // 4. THE TWO ALIEN ZONES
    // Row 1: SPAWN ALIEN ZONE (Incoming Next Wave)
    // Row 2: ACTIVE ALIEN ZONE (Attacking Base Now)
    // -------------------------------------------------------------
    var card_w = 152;
    var card_h1 = 114;
    var card_h2 = 124;
    
    // Top Row: Spawn Alien Zone
    var alien_start_y = py + 88;
    draw_set_color(make_color_rgb(180, 210, 240));
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_text(px + 16, alien_start_y, "INCOMING SPAWN ZONE (Wave " + string(state.round_number) + " Incoming - Cannot Be Attacked Yet):");
    
    var card_y1 = alien_start_y + 20;
    state.alien_inspect_hover = undefined;
    if (array_length(state.spawn_zone) == 0) {
        draw_set_color(make_color_rgb(120, 130, 145));
        draw_text(px + 16, card_y1 + 12, "(No aliens incoming this wave - Grace period!)");
    } else {
        for (var s = 0; s < array_length(state.spawn_zone); s++) {
            var al = state.spawn_zone[s];
            ui_draw_alien_card(state, px + 16 + s * (card_w + 12), card_y1, card_w, card_h1, al, false, mx, my, s);
        }
    }
    
    // Bottom Row: Active Alien Zone with Horizontal Scrolling
    var active_start_y = card_y1 + card_h1 + 10;
    var zone_x = px + 16;
    var zone_w = pw - 32;
    var card_step = card_w + 12; // 164 px
    var num_active = array_length(state.active_zone);
    var total_active_w = (num_active > 0) ? (num_active * card_step - 12) : 0;
    var max_active_scroll = max(0, total_active_w - zone_w);
    
    if (!variable_struct_exists(state, "active_aliens_scroll_x")) state.active_aliens_scroll_x = 0;
    state.active_aliens_scroll_x = clamp(state.active_aliens_scroll_x, 0, max_active_scroll);
    
    // Mouse wheel scrolling when hovered over active alien zone
    var card_y2 = active_start_y + 20;
    var in_active_zone = ui_point_in_rect(mx, my, zone_x, active_start_y, zone_w, card_h2 + 35);
    if (in_active_zone && max_active_scroll > 0) {
        if (mouse_wheel_down()) state.active_aliens_scroll_x = min(max_active_scroll, state.active_aliens_scroll_x + card_step);
        if (mouse_wheel_up()) state.active_aliens_scroll_x = max(0, state.active_aliens_scroll_x - card_step);
    }
    
    // Header text & Scroll Buttons
    draw_set_color(make_color_rgb(255, 138, 128));
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    var header_str = "ACTIVE ALIEN ZONE";
    if (state.phase == "combat_weapons") {
        if (variable_struct_exists(state, "combat_selected_tower") && state.combat_selected_tower >= 0 && !state.tower_weapon_used[state.combat_selected_tower]) {
            var tw = state.towers[state.combat_selected_tower];
            if (tw.alive && !is_undefined(tw.weapon)) {
                var w = tw.weapon;
                header_str = "TARGET SELECTION: Aiming " + string_upper(w.name) + " (" + string(w.damage + w.bonus_damage) + " Dmg)";
                if (game_has_active_scout(state)) {
                    header_str += "  [SCOUT ALIEN MUST BE KILLED FIRST!]";
                }
            } else {
                header_str = "ACTIVE ALIEN ZONE // Tactical Combat Active";
            }
        } else {
            header_str = "ACTIVE ALIEN ZONE // Tactical Combat Active";
        }
    } else {
        header_str = "ACTIVE ALIEN ZONE (Attacking Base - Click Any Alien to Target or Inspect)";
        if (max_active_scroll > 0) {
            header_str += "  [Threats: " + string(num_active) + " // Scroll Left/Right < >]";
        }
    }
    draw_text(zone_x, active_start_y, header_str);
    
    if (max_active_scroll > 0) {
        var can_sc_left = (state.active_aliens_scroll_x > 0);
        var can_sc_right = (state.active_aliens_scroll_x < max_active_scroll);
        state.btn_active_scroll_left = ui_draw_button(px + pw - 245, active_start_y - 4, 115, 22, "< Scroll Left", can_sc_left, false, mx, my);
        state.btn_active_scroll_right = ui_draw_button(px + pw - 120, active_start_y - 4, 115, 22, "Scroll Right >", can_sc_right, false, mx, my);
    } else {
        state.btn_active_scroll_left = false;
        state.btn_active_scroll_right = false;
    }
    
    state.active_alien_hover = -1;
    if (num_active == 0) {
        draw_set_color(make_color_rgb(120, 130, 145));
        draw_text(zone_x, card_y2 + 12, "(Active combat zone clear! All threats neutralized.)");
    } else {
        // Draw active aliens using surface clipping so cards never overflow screen
        var surf_w = max(1, zone_w);
        var surf_h = card_h2 + 4;
        if (!variable_struct_exists(state, "active_aliens_surf") || !surface_exists(state.active_aliens_surf)) {
            state.active_aliens_surf = surface_create(surf_w, surf_h);
        } else if (surface_get_width(state.active_aliens_surf) != surf_w || surface_get_height(state.active_aliens_surf) != surf_h) {
            surface_free(state.active_aliens_surf);
            state.active_aliens_surf = surface_create(surf_w, surf_h);
        }
        
        surface_set_target(state.active_aliens_surf);
        draw_clear_alpha(c_black, 0);
        
        var m_rel_x = (mx >= zone_x && mx <= zone_x + zone_w) ? (mx - zone_x) : -9999;
        var m_rel_y = my - card_y2;
        
        for (var a = 0; a < num_active; a++) {
            var al = state.active_zone[a];
            var card_rel_x = a * card_step - state.active_aliens_scroll_x;
            if (card_rel_x + card_w < 0 || card_rel_x > surf_w) continue;
            ui_draw_alien_card(state, card_rel_x, 2, card_w, card_h2, al, true, m_rel_x, m_rel_y, a);
        }
        
        surface_reset_target();
        draw_surface(state.active_aliens_surf, zone_x, card_y2);
        
        // Horizontal Scrollbar Track & Thumb
        if (max_active_scroll > 0) {
            var bar_y = card_y2 + card_h2 + 8;
            var bar_h = 6;
            draw_set_color(make_color_rgb(25, 32, 45));
            draw_roundrect_ext(zone_x, bar_y, zone_x + zone_w, bar_y + bar_h, 3, 3, false);
            draw_set_color(make_color_rgb(45, 58, 80));
            draw_roundrect_ext(zone_x, bar_y, zone_x + zone_w, bar_y + bar_h, 3, 3, true);
            
            var thumb_w = max(80, (zone_w / total_active_w) * zone_w);
            var thumb_x = zone_x + (state.active_aliens_scroll_x / max_active_scroll) * (zone_w - thumb_w);
            draw_set_color(make_color_rgb(100, 180, 240));
            draw_roundrect_ext(thumb_x, bar_y, thumb_x + thumb_w, bar_y + bar_h, 3, 3, false);
        }
    }
}

function ui_draw_alien_card(state, cx, cy, cw, ch, alien, is_active, mx, my, alien_idx = -1) {
    var hovered = ui_point_in_rect(mx, my, cx, cy, cw, ch);
    
    var cur_p = state.players[state.current_player_idx];
    var cur_tower_idx = -1;
    if (cur_p.node == "tower_1") cur_tower_idx = 0;
    else if (cur_p.node == "tower_2") cur_tower_idx = 1;
    else if (cur_p.node == "tower_3") cur_tower_idx = 2;
    else if (cur_p.node == "tower_4") cur_tower_idx = 3;
    var cur_tow = (cur_tower_idx >= 0) ? state.towers[cur_tower_idx] : undefined;
    var cur_tower_has_wep = (!is_undefined(cur_tow) && !is_undefined(cur_tow.weapon) && cur_tow.weapon.alive && cur_tow.weapon.damage > 0);
    var cur_tower_cd = (!is_undefined(cur_tow)) ? cur_tow.manual_cooldown : 0;
    var can_pilot = (cur_tower_has_wep && cur_tower_cd <= 0);
    
    var has_scout = game_has_active_scout(state);
    var is_scout_unit = (alien.catalog_id == "scout");
    var target_locked = (has_scout && !is_scout_unit);
    
    if (hovered) {
        state.alien_inspect_hover = alien;
        state.hover_tooltip = alien.name + " [Tier " + string(alien.tier) + " Alien]\n" +
            "Health: " + string(alien.hp) + " / " + string(alien.max_hp) + "  |  Damage: " + string(alien.damage) + "\n" +
            "Ability: " + alien.ability;
            
        if (state.phase == "combat_weapons") {
            if (is_active && alien_idx >= 0) {
                state.active_alien_hover = alien_idx;
                if (target_locked) {
                    state.hover_tooltip += "\n[CANNOT TARGET: Scout alien must be destroyed first!]";
                } else if (variable_struct_exists(state, "combat_selected_tower") && state.combat_selected_tower >= 0 && !state.tower_weapon_used[state.combat_selected_tower]) {
                    var cur_tw = state.towers[state.combat_selected_tower];
                    if (cur_tw.alive && !is_undefined(cur_tw.weapon)) {
                        var w_name = cur_tw.weapon.name;
                        var w_dmg = cur_tw.weapon.damage + cur_tw.weapon.bonus_damage;
                        state.hover_tooltip += "\n[Click to attack with " + w_name + " (" + string(w_dmg) + " Dmg)]";
                        if (cur_tw.weapon.catalog_id == "plasma_mortar") {
                            state.hover_tooltip += "\n[Plasma Mortar: Deals 7 dmg to primary target, and 3 splash dmg to adjacent left & right aliens!]";
                        }
                    }
                }
            }
        } else {
            if (is_active && alien_idx >= 0) {
                state.active_alien_hover = alien_idx;
                if (can_pilot) {
                    state.hover_tooltip += "\n[Click to fire mounted weapon at this target]";
                } else if (cur_tower_has_wep && cur_tower_cd > 0) {
                    state.hover_tooltip += "\n[Mounted weapon cooling down (" + string(cur_tower_cd) + " turns left)]";
                } else {
                    state.hover_tooltip += "\n[Click to inspect alien intel (Move to an armed Tower to pilot)]";
                }
            } else {
                state.hover_tooltip += "\n[Click to inspect alien details]";
            }
        }
    }
    
    // Tier colors
    var border_col = c_white;
    if (alien.tier == 1) border_col = make_color_rgb(76, 175, 80);       // Green
    else if (alien.tier == 2) border_col = make_color_rgb(255, 152, 0);  // Amber
    else if (alien.tier == 3) border_col = make_color_rgb(244, 67, 54);   // Crimson
    
    if (state.phase == "combat_weapons" && is_active) {
        if (target_locked) {
            border_col = make_color_rgb(90, 90, 100);
        } else if (is_scout_unit && has_scout) {
            border_col = c_yellow;
        } else if (hovered) {
            border_col = make_color_rgb(0, 229, 255);
        }
    }
    
    var bg_col = hovered ? make_color_rgb(45, 52, 71) : make_color_rgb(28, 34, 46);
    if (state.phase == "combat_weapons" && is_active && target_locked) {
        bg_col = make_color_rgb(20, 24, 32);
    }
    
    draw_set_color(bg_col);
    draw_roundrect_ext(cx, cy, cx + cw, cy + ch, 8, 8, false);
    draw_set_color(border_col);
    draw_roundrect_ext(cx, cy, cx + cw, cy + ch, 8, 8, true);
    
    // Name & Tier
    draw_set_halign(fa_center); draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(cx + cw * 0.5, cy + 6, alien.name);
    
    draw_set_color(border_col);
    draw_text(cx + cw * 0.5, cy + 24, "Tier " + string(alien.tier));
    
    // ENEMY HEALTH: RED HEART ICON + ACTUAL NUMBERS
    ui_draw_heart(cx + 32, cy + 50, 14, make_color_rgb(231, 76, 60));
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(255, 180, 180));
    draw_text(cx + 46, cy + 50, string(alien.hp) + " / " + string(alien.max_hp));
    
    // Miniature Health Bar
    var bx = cx + 12;
    var by = cy + 63;
    var bw = cw - 24;
    var bh = 5;
    draw_set_color(make_color_rgb(40, 40, 50));
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    var hp_pct = clamp(alien.hp / max(1, alien.max_hp), 0, 1);
    draw_set_color(make_color_rgb(231, 76, 60));
    draw_rectangle(bx, by, bx + bw * hp_pct, by + bh, false);
    
    // Damage
    draw_set_halign(fa_center); draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    draw_text(cx + cw * 0.5, cy + 72, "Attack: " + string(alien.damage) + " Dmg");
    
    // Special Status / Ability Tag
    var tag = "";
    if (alien.frozen) tag = "[FROZEN]";
    else if (alien.vulnerable) tag = "[VULN +1]";
    else if (alien.catalog_id == "scout") tag = "[TARGET 1ST]";
    else if (alien.catalog_id == "acid_spitter") tag = "[x2 VS WEP]";
    else if (alien.catalog_id == "drooper") tag = "[HITS ALL]";
    else if (alien.catalog_id == "goliath") tag = "[IGNS WEP]";
    
    if (tag != "") {
        draw_set_color(alien.frozen ? c_aqua : c_orange);
        draw_text(cx + cw * 0.5, cy + 90, tag);
    }
    
    // Interactive action footer text
    if (is_active) {
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        if (state.phase == "combat_weapons") {
            if (target_locked) {
                draw_set_color(make_color_rgb(220, 80, 80));
                draw_text(cx + cw * 0.5, cy + 106, "[SCOUT FIRST]");
            } else if (is_scout_unit && has_scout) {
                draw_set_color(c_yellow);
                draw_text(cx + cw * 0.5, cy + 106, "[TARGET SCOUT]");
            } else if (hovered) {
                draw_set_color(make_color_rgb(0, 229, 255));
                draw_text(cx + cw * 0.5, cy + 106, "[CLICK ATTACK]");
            } else {
                draw_set_color(make_color_rgb(130, 180, 230));
                draw_text(cx + cw * 0.5, cy + 106, "[TARGETABLE]");
            }
        } else if (hovered) {
            if (can_pilot) {
                draw_set_color(c_yellow);
                draw_text(cx + cw * 0.5, cy + 106, "[CLICK TARGET]");
            } else if (cur_tower_has_wep && cur_tower_cd > 0) {
                draw_set_color(make_color_rgb(255, 120, 120));
                draw_text(cx + cw * 0.5, cy + 106, "[COOLDOWN: " + string(cur_tower_cd) + "T]");
            } else {
                draw_set_color(make_color_rgb(160, 200, 255));
                draw_text(cx + cw * 0.5, cy + 106, "[CLICK INTEL]");
            }
        }
    }
}

function ui_draw_modals(state, mx, my) {
    if (is_undefined(state.modal)) return;
    
    var m = state.modal;
    
    // Dark overlay
    draw_set_color(c_black);
    draw_set_alpha(0.65);
    draw_rectangle(0, 0, 1920, 1080, false);
    draw_set_alpha(1.0);
    
    var mw = 840;
    var mh = 560;
    if (m.type == "player_setup") {
        mw = 1060;
        mh = 570;
    } else if (m.type == "shop" || m.type == "repair" || m.type == "workstation" || m.type == "town") {
        mw = 1180;
        mh = 650;
    } else if (m.type == "tactical_combat") {
        mw = 1720;
        mh = 940;
    } else if (m.type == "alien_damage_decision") {
        mw = 860;
        mh = 480;
    }
    var mx0 = (1920 - mw) * 0.5;
    var my0 = (1080 - mh) * 0.5;
    
    draw_set_color(make_color_rgb(26, 32, 44));
    draw_roundrect_ext(mx0, my0, mx0 + mw, my0 + mh, 16, 16, false);
    draw_set_color(make_color_rgb(52, 73, 94));
    draw_roundrect_ext(mx0, my0, mx0 + mw, my0 + mh, 16, 16, true);
    
    // Close button [X] (Hide on modal types where user must choose an explicit option)
    if (m.type != "player_setup" && m.type != "game_over" && m.type != "victory" && m.type != "tactical_combat" && m.type != "alien_damage_decision") {
        state.modal_close_hover = ui_draw_button(mx0 + mw - 45, my0 + 15, 30, 30, "X", true, false, mx, my);
    } else {
        state.modal_close_hover = false;
    }
    
    if (m.type == "alien_inspect") {
        var al = m.alien;
        
        var tier_col = make_color_rgb(76, 175, 80); // Green
        if (al.tier == 2) tier_col = make_color_rgb(255, 152, 0); // Amber
        else if (al.tier == 3) tier_col = make_color_rgb(244, 67, 54); // Crimson
        
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(tier_col);
        draw_text(mx0 + mw * 0.5, my0 + 20, string_upper(al.name) + " // THREAT DOSSIER [TIER " + string(al.tier) + "]");
        
        // Stats Overview Box
        var box_x = mx0 + 40;
        var box_y = my0 + 65;
        var box_w = mw - 80;
        var box_h = 95;
        
        draw_set_color(make_color_rgb(18, 24, 34));
        draw_roundrect_ext(box_x, box_y, box_x + box_w, box_y + box_h, 8, 8, false);
        draw_set_color(tier_col);
        draw_roundrect_ext(box_x, box_y, box_x + box_w, box_y + box_h, 8, 8, true);
        
        // Health with Red Heart Icon
        ui_draw_heart(box_x + 35, box_y + 32, 20, make_color_rgb(231, 76, 60), c_white, 2);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(box_x + 55, box_y + 32, "Health: " + string(al.hp) + " / " + string(al.max_hp) + " HP");
        
        // Attack Damage
        draw_set_color(c_yellow);
        draw_text(box_x + 280, box_y + 32, "Attack Power: " + string(al.damage) + " Damage");
        
        // Status Condition
        var stat_str = al.frozen ? "FROZEN (Deals 0 dmg next attack)" : (al.vulnerable ? "VULNERABLE (+1 damage taken)" : "Active Combat Ready");
        draw_set_color(al.frozen ? c_aqua : (al.vulnerable ? c_orange : make_color_rgb(180, 210, 240)));
        draw_text(box_x + 55, box_y + 68, "Status Condition: " + stat_str);
        
        // Special Ability Profile
        var ab_y = box_y + box_h + 18;
        var ab_h = 295;
        draw_set_color(make_color_rgb(18, 24, 34));
        draw_roundrect_ext(box_x, ab_y, box_x + box_w, ab_y + ab_h, 8, 8, false);
        draw_set_color(make_color_rgb(70, 85, 110));
        draw_roundrect_ext(box_x, ab_y, box_x + box_w, ab_y + ab_h, 8, 8, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(c_yellow);
        draw_text(box_x + 20, ab_y + 16, "TACTICAL PROFILE & SPECIAL ABILITY:");
        
        draw_set_color(c_white);
        draw_text_ext(box_x + 20, ab_y + 46, al.ability, 22, box_w - 40);
        
        // Tactical Tip / Lore
        var tip_text = "";
        if (al.catalog_id == "scout") tip_text = "Priority Target: All base weapons must target this Scout first before hitting other aliens.";
        else if (al.catalog_id == "armorback") tip_text = "Thick Carapace: Reduces all incoming attack damage by 1 (minimum 1 damage).";
        else if (al.catalog_id == "screamer") tip_text = "Pack Leader: Buffs all other active aliens with +1 Damage while alive.";
        else if (al.catalog_id == "acid_spitter") tip_text = "Anti-Defense: Deals DOUBLE damage (2x) when striking player defense weapons stationed at towers.";
        else if (al.catalog_id == "drooper") tip_text = "Aerial Assault: Ignores tower roll and strikes ALL 4 base towers simultaneously!";
        else if (al.catalog_id == "saboteur") tip_text = "Death Retaliation: Deals 2 damage back to whichever weapon deals the killing blow.";
        else if (al.catalog_id == "goliath") tip_text = "Siege Juggernaut: Direct damage cannot be tanked by defense weapons; strikes tower directly!";
        else if (al.catalog_id == "emp_weaver") tip_text = "Electromagnetic Pulse: Completely disables the base's highest damage weapon each wave!";
        else if (al.catalog_id == "hatcher") tip_text = "Brood Mother: Spawns two new Hatchlings (2 HP, 1 Dmg) into the active zone each wave.";
        else if (al.catalog_id == "alien_queen") tip_text = "Apex Swarm Matriarch: Summons Tier 1 and Tier 2 alien reinforcements with +3 HP each wave!";
        else if (al.catalog_id == "apex_predator") tip_text = "Colossal Health Pool: Max 10 damage taken from any single attack. Requires sustained team fire.";
        
        if (tip_text != "") {
            draw_set_color(make_color_rgb(100, 210, 255));
            draw_text(box_x + 20, ab_y + 140, "BASE DEFENSE INTEL & TACTICS:");
            draw_set_color(make_color_rgb(200, 225, 245));
            draw_text_ext(box_x + 20, ab_y + 170, tip_text, 22, box_w - 40);
        }
        
        // Close Button
        state.alien_inspect_close_hover = ui_draw_button(mx0 + (mw - 240) * 0.5, my0 + mh - 55, 240, 38, "Close Dossier [Esc]", true, true, mx, my);
    }
    else if (m.type == "tactical_combat") {
        // Reset interactive hover flags
        state.combat_alien_hover = -1;
        state.combat_tower_hover = [false, false, false, false];
        state.combat_tesla_btn_hover = false;
        state.combat_advance_hover = false;
        state.combat_conclude_btn_hover = false;
        
        // -------------------------------------------------------------
        // 1. HEADER BANNER: MISSION STATUS & TACTICAL DIRECTIVE
        // -------------------------------------------------------------
        var head_y = my0 + 12;
        draw_set_color(make_color_rgb(18, 24, 38));
        draw_roundrect_ext(mx0 + 16, head_y, mx0 + mw - 16, head_y + 54, 8, 8, false);
        draw_set_color(make_color_rgb(45, 65, 95));
        draw_roundrect_ext(mx0 + 16, head_y, mx0 + mw - 16, head_y + 54, 8, 8, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_text(mx0 + 32, head_y + 18, "TACTICAL COMBAT // BASE DEFENSE // WAVE " + string(state.round_number));
        
        // Dynamic prompt / subphase instruction
        var prompt_str = "";
        var prompt_col = c_white;
        if (state.combat_subphase == "player_weapons") {
            if (state.combat_selected_tower >= 0 && !state.tower_weapon_used[state.combat_selected_tower]) {
                var sel_tw = state.towers[state.combat_selected_tower];
                var sel_w = sel_tw.weapon;
                var shots_l = state.tower_weapon_shots[state.combat_selected_tower];
                prompt_str = "AIMING " + string_upper(sel_w.name) + " (" + sel_tw.name + "): Click any alien above to attack! (" + string(shots_l) + " shot" + (shots_l > 1 ? "s" : "") + " remaining)";
                prompt_col = make_color_rgb(100, 230, 255);
            } else {
                prompt_str = "SELECT WEAPON: Click a mounted weapon below, then target an alien above to attack!";
                prompt_col = make_color_rgb(255, 230, 140);
            }
        } else if (state.combat_subphase == "alien_attacks") {
            prompt_str = "ALIEN RETALIATION: Swarm hostiles are shooting projectiles at base fortifications!";
            prompt_col = make_color_rgb(255, 120, 120);
        } else if (state.combat_subphase == "combat_concluded") {
            if (state.combat_concluded_reason == "aliens_eradicated") {
                prompt_str = "MISSION CLEAR: All active hostiles eradicated! Sector perimeter secured.";
                prompt_col = make_color_rgb(105, 240, 174);
            } else if (state.combat_concluded_reason == "no_threats") {
                prompt_str = "ALL CLEAR: No hostile threats in range! Sector perimeter secured.";
                prompt_col = make_color_rgb(100, 230, 255);
            } else {
                prompt_str = "COMBAT CONCLUDED: All attacks finished! Sector perimeter secured.";
                prompt_col = make_color_rgb(255, 215, 0);
            }
        }
        draw_set_color(prompt_col);
        draw_text(mx0 + 32, head_y + 38, prompt_str);
        
        // Header buttons in top-right
        var spd_w = 150;
        var spd_h = 36;
        var spd_x = mx0 + mw - 16 - spd_w;
        var spd_y = head_y + 9;
        var is_2x = (variable_struct_exists(state, "combat_speed_2x") && state.combat_speed_2x);
        var spd_lbl = is_2x ? "2X SPEED: ON" : "2X SPEED: OFF";
        state.combat_speed_btn_hover = ui_draw_button(spd_x, spd_y, spd_w, spd_h, spd_lbl, true, is_2x, mx, my);
        if (state.combat_speed_btn_hover) {
            state.hover_tooltip = "Toggle 2x speed for weapon attacks, projectiles and animations.";
        }
        
        if (state.combat_subphase == "player_weapons") {
            var adv_w = 250;
            var adv_h = 36;
            var adv_x = spd_x - adv_w - 12;
            var adv_y = head_y + 9;
            state.combat_advance_hover = ui_draw_button(adv_x, adv_y, adv_w, adv_h, "Skip to Alien Retaliation >>", true, false, mx, my);
            if (state.combat_advance_hover) {
                state.hover_tooltip = "End weapons attack phase immediately and proceed to alien retaliation.";
            }
        } else if (state.combat_subphase == "combat_concluded") {
            var conc_w = 260;
            var conc_h = 36;
            var conc_x = spd_x - conc_w - 12;
            var conc_y = head_y + 9;
            var chov = ui_draw_button(conc_x, conc_y, conc_w, conc_h, "Close Combat Menu [Space] >>", true, true, mx, my);
            if (chov) {
                state.combat_conclude_btn_hover = true;
                state.hover_tooltip = "Close tactical combat menu and return to the main base.";
            }
        }
        
        // Tower section layout measurements (shared across engagement, projectiles, and tower drawing)
        var tw_sec_y = my0 + 580;
        var slot_w = 390;
        var slot_h = 320;
        var slot_gap = 20;
        var slot_start_x = mx0 + (mw - (4 * slot_w + 3 * slot_gap)) * 0.5;
        var slot_y = tw_sec_y + 16;
        
        // -------------------------------------------------------------
        // 2. TOP SECTION: ACTIVE INVASION ZONE (ALIENS)
        // -------------------------------------------------------------
        var num_act = array_length(state.active_zone);
        var act_zone_y = head_y + 64;
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(255, 100, 100));
        draw_text(mx0 + 32, act_zone_y + 10, "ACTIVE THREAT CLUSTER (" + string(num_act) + " Hostiles In Range)");
        
        var max_act_w = mw - 60;
        var card_w = 186;
        var card_h = 220;
        var card_gap = 14;
        if (num_act > 0) {
            if (num_act * (card_w + card_gap) - card_gap > max_act_w) {
                card_gap = clamp(floor((max_act_w - num_act * 130) / max(1, num_act - 1)), 6, 12);
                card_w = clamp(floor((max_act_w - (num_act - 1) * card_gap) / num_act), 120, 186);
            }
        }
        var cards_total_w = (num_act > 0) ? (num_act * (card_w + card_gap) - card_gap) : 0;
        var card_start_x = mx0 + (mw - cards_total_w) * 0.5;
        var card_y = act_zone_y + 24;
        
        state.combat_alien_coords = [];
        var has_scout_alive = game_has_active_scout(state);
        
        if (num_act == 0) {
            draw_set_color(make_color_rgb(18, 24, 34));
            draw_roundrect_ext(mx0 + 30, card_y, mx0 + mw - 30, card_y + 80, 8, 8, false);
            draw_set_color(make_color_rgb(46, 60, 80));
            draw_roundrect_ext(mx0 + 30, card_y, mx0 + mw - 30, card_y + 80, 8, 8, true);
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(120, 230, 150));
            draw_text(mx0 + mw * 0.5, card_y + 40, "★ ALL ACTIVE THREATS NEUTRALIZED -- SECTOR PERIMETER CLEAR ★");
        } else {
            for (var a = 0; a < num_act; a++) {
                var al = state.active_zone[a];
                var ac_x = card_start_x + a * (card_w + card_gap);
                state.combat_alien_coords[a] = [ac_x + card_w * 0.5, card_y + card_h];
                
                var is_al_hov = ui_point_in_rect(mx, my, ac_x, card_y, card_w, card_h);
                if (is_al_hov) state.combat_alien_hover = a;
                
                var is_scout = (al.catalog_id == "scout");
                var is_target_locked = (has_scout_alive && !is_scout);
                
                var tier_color = make_color_rgb(76, 175, 80);
                if (al.tier == 2) tier_color = make_color_rgb(255, 152, 0);
                else if (al.tier == 3) tier_color = make_color_rgb(244, 67, 54);
                
                draw_set_color(make_color_rgb(22, 28, 40));
                draw_roundrect_ext(ac_x, card_y, ac_x + card_w, card_y + card_h, 8, 8, false);
                
                if (is_al_hov && state.combat_subphase == "player_weapons" && !is_target_locked) {
                    draw_set_color(c_aqua);
                    draw_roundrect_ext(ac_x - 2, card_y - 2, ac_x + card_w + 2, card_y + card_h + 2, 8, 8, true);
                } else if (is_scout) {
                    draw_set_color(make_color_rgb(255, 215, 0));
                    draw_roundrect_ext(ac_x - 1, card_y - 1, ac_x + card_w + 1, card_y + card_h + 1, 8, 8, true);
                } else {
                    draw_set_color(tier_color);
                    draw_roundrect_ext(ac_x, card_y, ac_x + card_w, card_y + card_h, 8, 8, true);
                }
                
                // Tier badge
                draw_set_color(tier_color);
                draw_roundrect_ext(ac_x + 6, card_y + 6, ac_x + 50, card_y + 24, 4, 4, false);
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_set_color(c_black);
                draw_text(ac_x + 28, card_y + 15, "T" + string(al.tier));
                
                // Alien Name
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(c_white);
                var max_c = (card_w < 150) ? 9 : 13;
                var short_al_name = al.name;
                if (string_length(short_al_name) > max_c) short_al_name = string_copy(short_al_name, 1, max_c - 1) + ".";
                draw_text(ac_x + 56, card_y + 15, short_al_name);
                
                // Health with Red Heart & Bar
                ui_draw_heart(ac_x + 16, card_y + 40, 11, make_color_rgb(231, 76, 60));
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(c_white);
                draw_text(ac_x + 34, card_y + 40, string(al.hp) + "/" + string(al.max_hp) + " HP");
                
                // Health Bar Fill
                var bar_w = card_w - 20;
                var bar_h = 6;
                var bar_x = ac_x + 10;
                var bar_y_pos = card_y + 54;
                var hp_ratio = clamp(al.hp / max(1, al.max_hp), 0.0, 1.0);
                draw_set_color(make_color_rgb(40, 40, 50));
                draw_roundrect_ext(bar_x, bar_y_pos, bar_x + bar_w, bar_y_pos + bar_h, 3, 3, false);
                draw_set_color(hp_ratio > 0.5 ? make_color_rgb(46, 204, 113) : (hp_ratio > 0.25 ? make_color_rgb(241, 196, 15) : make_color_rgb(231, 76, 60)));
                draw_roundrect_ext(bar_x, bar_y_pos, bar_x + bar_w * hp_ratio, bar_y_pos + bar_h, 3, 3, false);
                
                // Attack Power
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(255, 120, 120));
                draw_text(ac_x + 12, card_y + 74, "ATK: " + string(al.damage) + " Dmg");
                
                // Status Tag
                if (al.frozen) {
                    draw_set_color(c_aqua);
                    draw_text(ac_x + 12, card_y + 92, "[FROZEN - 0 DMG]");
                } else if (al.tesla_weakened) {
                    draw_set_color(c_yellow);
                    draw_text(ac_x + 12, card_y + 92, "[TESLA WEAK -1]");
                }
                
                // Ability Summary
                draw_set_color(make_color_rgb(180, 205, 230));
                draw_text_ext(ac_x + 10, card_y + 110, al.ability, 14, card_w - 20);
                
                // Scout Target Priority Badge or Target Lock Overlay
                if (is_scout) {
                    draw_set_color(make_color_rgb(255, 70, 70));
                    draw_roundrect_ext(ac_x + 8, card_y + card_h - 26, ac_x + card_w - 8, card_y + card_h - 6, 4, 4, false);
                    draw_set_halign(fa_center); draw_set_valign(fa_middle);
                    draw_set_color(c_white);
                    draw_text(ac_x + card_w * 0.5, card_y + card_h - 16, "PRIORITY TARGET");
                } else if (is_target_locked) {
                    draw_set_color(make_color_rgb(60, 20, 20));
                    draw_roundrect_ext(ac_x + 8, card_y + card_h - 26, ac_x + card_w - 8, card_y + card_h - 6, 4, 4, false);
                    draw_set_halign(fa_center); draw_set_valign(fa_middle);
                    draw_set_color(make_color_rgb(255, 120, 120));
                    draw_text(ac_x + card_w * 0.5, card_y + card_h - 16, "LOCKED BY SCOUT");
                }
            }
        }
        
        // -------------------------------------------------------------
        // 3. MIDDLE ENGAGEMENT ZONE: TARGETING RETICLES, PROJECTILES & IMPACTS
        // -------------------------------------------------------------
        var mid_y0 = card_y + card_h + 10;
        
        // Targeting line from active selected tower to hovered alien
        if (state.combat_subphase == "player_weapons" && state.combat_selected_tower >= 0 && state.combat_alien_hover >= 0) {
            var st_idx = state.combat_selected_tower;
            var al_idx = state.combat_alien_hover;
            if (st_idx < array_length(state.combat_tower_coords) && al_idx < array_length(state.combat_alien_coords)) {
                var p_start = state.combat_tower_coords[st_idx];
                var p_end = state.combat_alien_coords[al_idx];
                var can_tgt = !(has_scout_alive && state.active_zone[al_idx].catalog_id != "scout");
                
                draw_set_color(can_tgt ? c_aqua : make_color_rgb(255, 80, 80));
                draw_set_alpha(0.75);
                draw_line_width(p_start[0], p_start[1], p_end[0], p_end[1], 3);
                draw_circle(p_end[0], p_end[1] - card_h * 0.5, 24, true);
                draw_set_alpha(1.0);
                
                // Damage projection tag
                if (can_tgt && !is_undefined(state.towers[st_idx].weapon)) {
                    var w = state.towers[st_idx].weapon;
                    var dmg_proj = w.damage + w.bonus_damage;
                    var tag_x = (p_start[0] + p_end[0]) * 0.5;
                    var tag_y = (p_start[1] + p_end[1]) * 0.5;
                    draw_set_color(c_black);
                    draw_roundrect_ext(tag_x - 45, tag_y - 14, tag_x + 45, tag_y + 14, 4, 4, false);
                    draw_set_color(c_yellow);
                    draw_roundrect_ext(tag_x - 45, tag_y - 14, tag_x + 45, tag_y + 14, 4, 4, true);
                    draw_set_halign(fa_center); draw_set_valign(fa_middle);
                    draw_text(tag_x, tag_y, "-" + string(dmg_proj) + " DMG");
                }
            }
        }
        
        // In-flight Player Projectiles (Traveling from tower to alien)
        if (variable_struct_exists(state, "combat_player_projectiles") && is_array(state.combat_player_projectiles)) {
            for (var pp_i = 0; pp_i < array_length(state.combat_player_projectiles); pp_i++) {
                var pp = state.combat_player_projectiles[pp_i];
                var st_pos = (pp.tower_idx < array_length(state.combat_tower_coords)) ? state.combat_tower_coords[pp.tower_idx] : [mx0 + mw * 0.5, slot_y];
                var al_pos = (pp.target_idx < array_length(state.combat_alien_coords)) ? state.combat_alien_coords[pp.target_idx] : [mx0 + mw * 0.5, card_y + card_h];
                
                var start_y = st_pos[1] + 20;
                var target_y = al_pos[1] - card_h * 0.5;
                
                var cur_px = lerp(st_pos[0], al_pos[0], pp.progress);
                var cur_py = lerp(start_y, target_y, pp.progress);
                
                var trail_px = lerp(st_pos[0], al_pos[0], max(0, pp.progress - 0.16));
                var trail_py = lerp(start_y, target_y, max(0, pp.progress - 0.16));
                
                var pp_col = make_color_rgb(0, 229, 255); // bright cyan
                if (pp.catalog_id == "sniper") pp_col = make_color_rgb(255, 235, 59);
                else if (pp.catalog_id == "plasma") pp_col = make_color_rgb(180, 50, 255);
                else if (pp.catalog_id == "flamethrower" || pp.catalog_id == "minigun") pp_col = make_color_rgb(255, 110, 30);
                else if (pp.catalog_id == "cryo") pp_col = make_color_rgb(120, 240, 255);
                
                draw_set_color(pp_col);
                draw_set_alpha(0.6);
                draw_line_width(trail_px, trail_py, cur_px, cur_py, 6);
                draw_set_alpha(1.0);
                
                draw_set_color(pp_col);
                draw_circle(cur_px, cur_py, 9, false);
                draw_set_color(c_white);
                draw_circle(cur_px, cur_py, 4, false);
            }
        }
        
        // In-flight Alien Projectiles (Traveling from alien to tower)
        if (variable_struct_exists(state, "combat_projectiles") && is_array(state.combat_projectiles)) {
            for (var p_i = 0; p_i < array_length(state.combat_projectiles); p_i++) {
                var pr = state.combat_projectiles[p_i];
                var a_pos = (pr.alien_idx < array_length(state.combat_alien_coords)) ? state.combat_alien_coords[pr.alien_idx] : [mx0 + mw * 0.5, card_y + card_h];
                var t_pos = (pr.target_tower_idx < array_length(state.combat_tower_coords)) ? state.combat_tower_coords[pr.target_tower_idx] : [mx0 + mw * 0.5, my0 + mh - 100];
                
                var start_y = a_pos[1] - 20;
                var target_y = t_pos[1] + 160;
                
                var cur_px = lerp(a_pos[0], t_pos[0], pr.progress);
                var cur_py = lerp(start_y, target_y, pr.progress);
                
                var trail_px = lerp(a_pos[0], t_pos[0], max(0, pr.progress - 0.12));
                var trail_py = lerp(start_y, target_y, max(0, pr.progress - 0.12));
                
                var p_col = make_color_rgb(255, 170, 0); // bio orange
                if (pr.is_acid_spitter) p_col = make_color_rgb(57, 255, 20); // neon acidic green
                else if (pr.skips_weapon) p_col = make_color_rgb(255, 50, 50); // deep crimson
                else if (pr.alien.catalog_id == "drooper") p_col = make_color_rgb(180, 50, 255); // purple
                
                // Motion Trail
                draw_set_color(p_col);
                draw_set_alpha(0.5);
                draw_line_width(trail_px, trail_py, cur_px, cur_py, 6);
                draw_set_alpha(1.0);
                
                // Glowing core
                draw_set_color(p_col);
                draw_circle(cur_px, cur_py, 10, false);
                draw_set_color(c_white);
                draw_circle(cur_px, cur_py, 5, false);
            }
        }
        
        // Impact Particle Effects (Explosion fireball blasts, smoke puffs, shockwaves & debris sparks)
        if (variable_struct_exists(state, "combat_impact_effects") && is_array(state.combat_impact_effects)) {
            for (var e_i = 0; e_i < array_length(state.combat_impact_effects); e_i++) {
                var eff = state.combat_impact_effects[e_i];
                var life_ratio = eff.life / max(1, eff.max_life);
                var ring_rad = eff.max_radius * life_ratio;
                var ring_alpha = 1.0 - life_ratio;
                
                // 1. Smoke puffs (background soft charcoal smoke drifting up)
                if (variable_struct_exists(eff, "smoke") && is_array(eff.smoke)) {
                    for (var sm_i = 0; sm_i < array_length(eff.smoke); sm_i++) {
                        var sm = eff.smoke[sm_i];
                        var sm_alpha = clamp(sm.life / max(1, sm.max_life), 0.0, 1.0) * 0.45;
                        draw_set_color(sm.color);
                        draw_set_alpha(sm_alpha);
                        draw_circle(sm.x, sm.y, sm.radius, false);
                    }
                }
                
                // 2. Expanding shockwave rings
                draw_set_color(eff.color);
                draw_set_alpha(ring_alpha * 0.9);
                draw_circle(eff.x, eff.y, ring_rad, true);
                draw_set_alpha(ring_alpha * 0.5);
                draw_circle(eff.x, eff.y, max(1, ring_rad * 0.65), true);
                
                // 3. Fireball blast puffs
                if (variable_struct_exists(eff, "fireballs") && is_array(eff.fireballs)) {
                    for (var fb_i = 0; fb_i < array_length(eff.fireballs); fb_i++) {
                        var fb = eff.fireballs[fb_i];
                        var fb_ratio = fb.life / max(1, fb.max_life);
                        var fb_alpha = clamp(fb_ratio * 1.2, 0.0, 1.0);
                        draw_set_color(fb.color);
                        draw_set_alpha(fb_alpha * 0.85);
                        draw_circle(fb.x, fb.y, fb.radius, false);
                        draw_set_color(make_color_rgb(255, 240, 180));
                        draw_set_alpha(fb_alpha * 0.95);
                        draw_circle(fb.x, fb.y, max(1, fb.radius * 0.5), false);
                    }
                }
                
                // 4. Central bright blast flash
                if (eff.life < 8) {
                    var flash_alpha = 1.0 - (eff.life / 8.0);
                    draw_set_color(c_white);
                    draw_set_alpha(flash_alpha * 0.95);
                    draw_circle(eff.x, eff.y, eff.max_radius * 0.45, false);
                }
                
                // 5. Fiery sparks & high-velocity shrapnel debris
                for (var s_i = 0; s_i < array_length(eff.sparks); s_i++) {
                    var sp = eff.sparks[s_i];
                    var sp_alpha = clamp(sp.life / max(1, sp.max_life), 0.0, 1.0);
                    draw_set_color(sp.color);
                    draw_set_alpha(sp_alpha);
                    draw_circle(sp.x, sp.y, sp.size, false);
                    draw_set_color(c_white);
                    draw_set_alpha(sp_alpha * 0.75);
                    draw_circle(sp.x, sp.y, max(1, sp.size * 0.4), false);
                }
                draw_set_alpha(1.0);
            }
        }
        
        // Central Concluded Mission HUD Panel & Prominent Close Button
        if (state.combat_subphase == "combat_concluded") {
            var mid_center_y = (card_y + card_h + tw_sec_y) * 0.5;
            var con_panel_w = 840;
            var con_panel_h = 160;
            var con_panel_x = mx0 + (mw - con_panel_w) * 0.5;
            var con_panel_y = mid_center_y - con_panel_h * 0.5;
            
            draw_set_color(make_color_rgb(18, 24, 36));
            draw_roundrect_ext(con_panel_x, con_panel_y, con_panel_x + con_panel_w, con_panel_y + con_panel_h, 12, 12, false);
            draw_set_color(make_color_rgb(46, 204, 113));
            draw_roundrect_ext(con_panel_x, con_panel_y, con_panel_x + con_panel_w, con_panel_y + con_panel_h, 12, 12, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_top);
            var con_title = "COMBAT ENGAGEMENT CONCLUDED";
            var con_desc = "All sector weapons have fired and hostile swarm attacks have ended.";
            var con_col = make_color_rgb(255, 215, 0);
            if (state.combat_concluded_reason == "aliens_eradicated") {
                con_title = "MISSION SUCCESS // ALL ACTIVE THREATS NEUTRALIZED";
                con_desc = "Every active alien in the sector has been wiped out. Base perimeter secured!";
                con_col = make_color_rgb(105, 240, 174);
            } else if (state.combat_concluded_reason == "no_threats") {
                con_title = "ALL CLEAR // NO HOSTILE DETECTIONS";
                con_desc = "No incoming alien threats detected in combat sector.";
                con_col = make_color_rgb(100, 220, 255);
            }
            draw_set_color(con_col);
            draw_text(con_panel_x + con_panel_w * 0.5, con_panel_y + 18, con_title);
            draw_set_color(make_color_rgb(190, 215, 240));
            draw_text(con_panel_x + con_panel_w * 0.5, con_panel_y + 46, con_desc);
            
            var conc_btn_w = 480;
            var conc_btn_h = 44;
            var conc_btn_x = con_panel_x + (con_panel_w - conc_btn_w) * 0.5;
            var conc_btn_y = con_panel_y + 92;
            var conc_b_hover = ui_draw_button(conc_btn_x, conc_btn_y, conc_btn_w, conc_btn_h, "Close Combat Menu & Proceed [Space]", true, true, mx, my);
            if (conc_b_hover) {
                state.combat_conclude_btn_hover = true;
                state.hover_tooltip = "Close tactical combat display and return to the main base.";
            }
        }
        
        // -------------------------------------------------------------
        // 4. BOTTOM SECTION: 4 BASE TOWERS & MOUNTED WEAPONS
        // -------------------------------------------------------------
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(100, 210, 255));
        draw_text(mx0 + 32, tw_sec_y, "BASE FORTIFICATIONS // SECTOR DEFENSE WEAPONS");
        
        state.combat_tower_coords = [];
        
        for (var t = 0; t < 4; t++) {
            var tow = state.towers[t];
            var twep = tow.weapon;
            var t_x = slot_start_x + t * (slot_w + slot_gap);
            state.combat_tower_coords[t] = [t_x + slot_w * 0.5, slot_y];
            
            var is_tow_hov = ui_point_in_rect(mx, my, t_x, slot_y, slot_w, slot_h);
            state.combat_tower_hover[t] = is_tow_hov;
            
            var has_wep = (!is_undefined(twep) && twep.alive);
            var is_used = state.tower_weapon_used[t];
            var is_sel = (state.combat_selected_tower == t && !is_used && has_wep);
            var shots_rem = state.tower_weapon_shots[t];
            var max_shots = state.tower_weapon_max_shots[t];
            
            // Background Card
            if (!tow.alive) {
                // Destroyed tower card
                draw_set_color(make_color_rgb(18, 14, 16));
                draw_roundrect_ext(t_x, slot_y, t_x + slot_w, slot_y + slot_h, 8, 8, false);
                draw_set_color(make_color_rgb(120, 40, 40));
                draw_roundrect_ext(t_x, slot_y, t_x + slot_w, slot_y + slot_h, 8, 8, true);
                
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(255, 80, 80));
                draw_text(t_x + slot_w * 0.5, slot_y + 40, "SECTOR TOWER " + string(t + 1) + " // DESTROYED");
                draw_set_color(make_color_rgb(180, 120, 120));
                draw_text(t_x + slot_w * 0.5, slot_y + 120, "Tower defenses have fallen.\nCannot mount weapons or absorb attacks.");
                continue;
            }
            
            if (!has_wep) {
                // Empty Hardpoint
                draw_set_color(make_color_rgb(18, 24, 32));
                draw_roundrect_ext(t_x, slot_y, t_x + slot_w, slot_y + slot_h, 8, 8, false);
                draw_set_color(make_color_rgb(50, 70, 95));
                draw_roundrect_ext(t_x, slot_y, t_x + slot_w, slot_y + slot_h, 8, 8, true);
                
                // Tower Header
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(140, 180, 220));
                draw_text(t_x + 16, slot_y + 22, tow.name + " Fortification");
                
                // Tower Health
                ui_draw_heart(t_x + 20, slot_y + 54, 12, make_color_rgb(46, 204, 113));
                draw_set_color(c_white);
                draw_text(t_x + 40, slot_y + 54, "Tower Integrity: " + string(tow.hp) + " / 10 HP");
                
                // Empty slot banner
                draw_set_color(make_color_rgb(26, 34, 46));
                draw_roundrect_ext(t_x + 16, slot_y + 90, t_x + slot_w - 16, slot_y + slot_h - 24, 6, 6, false);
                draw_set_color(make_color_rgb(50, 65, 85));
                draw_roundrect_ext(t_x + 16, slot_y + 90, t_x + slot_w - 16, slot_y + slot_h - 24, 6, 6, true);
                
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(160, 180, 200));
                draw_text(t_x + slot_w * 0.5, slot_y + 150, "[EMPTY DEFENSE HARDPOINT]\nNo weapon stationed at this tower.");
                draw_set_color(make_color_rgb(110, 130, 155));
                draw_text(t_x + slot_w * 0.5, slot_y + 210, "Forge blueprints at the Workstation\nto station defensive turrets here.");
                continue;
            }
            
            // Mounted Weapon Card
            if (is_used) {
                // Greys out as it was used!
                draw_set_color(make_color_rgb(20, 22, 28));
                draw_roundrect_ext(t_x, slot_y, t_x + slot_w, slot_y + slot_h, 8, 8, false);
                draw_set_color(make_color_rgb(55, 60, 70));
                draw_roundrect_ext(t_x, slot_y, t_x + slot_w, slot_y + slot_h, 8, 8, true);
            } else if (is_sel) {
                // Bright glowing selected state
                draw_set_color(make_color_rgb(24, 38, 55));
                draw_roundrect_ext(t_x, slot_y, t_x + slot_w, slot_y + slot_h, 8, 8, false);
                draw_set_color(make_color_rgb(100, 230, 255));
                draw_roundrect_ext(t_x - 2, slot_y - 2, t_x + slot_w + 2, slot_y + slot_h + 2, 8, 8, true);
            } else {
                // Ready to select
                draw_set_color(make_color_rgb(22, 30, 44));
                draw_roundrect_ext(t_x, slot_y, t_x + slot_w, slot_y + slot_h, 8, 8, false);
                draw_set_color(is_tow_hov ? c_aqua : make_color_rgb(52, 152, 219));
                draw_roundrect_ext(t_x, slot_y, t_x + slot_w, slot_y + slot_h, 8, 8, true);
            }
            
            // Header: Tower & Weapon Name
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(is_used ? make_color_rgb(130, 140, 150) : (is_sel ? make_color_rgb(255, 215, 0) : c_white));
            var w_hdr = string_upper(twep.name) + " [" + tow.name + "]";
            if (string_width(w_hdr) > slot_w - 180) {
                w_hdr = string_upper(twep.name);
            }
            draw_text(t_x + 16, slot_y + 20, w_hdr);
            
            // Status Badge
            var badge_lbl = is_used ? "[EXHAUSTED / USED]" : (is_sel ? "[ARMED // ACTIVE]" : "[CLICK TO SELECT]");
            var badge_col = is_used ? make_color_rgb(100, 110, 120) : (is_sel ? make_color_rgb(100, 230, 255) : make_color_rgb(46, 204, 113));
            draw_set_halign(fa_right); draw_set_valign(fa_middle);
            draw_set_color(badge_col);
            draw_text(t_x + slot_w - 16, slot_y + 20, badge_lbl);
            
            // Health Stats
            ui_draw_heart(t_x + 18, slot_y + 48, 10, make_color_rgb(231, 76, 60));
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(is_used ? make_color_rgb(140, 150, 160) : c_white);
            draw_text(t_x + 36, slot_y + 48, "Weapon HP: " + string(twep.hp) + " / " + string(twep.max_hp));
            
            draw_set_color(is_used ? make_color_rgb(120, 130, 140) : make_color_rgb(100, 200, 255));
            draw_text(t_x + 220, slot_y + 48, "Tower: " + string(tow.hp) + " / 10 HP");
            
            // Damage & Shots
            var eff_dmg = twep.damage + twep.bonus_damage;
            draw_set_color(is_used ? make_color_rgb(140, 150, 160) : make_color_rgb(255, 215, 0));
            draw_text(t_x + 16, slot_y + 78, "Damage: " + string(eff_dmg) + " Dmg");
            
            var shots_str = string(shots_rem) + " / " + string(max_shots) + " Shots";
            draw_set_color(shots_rem > 0 ? make_color_rgb(100, 230, 255) : make_color_rgb(140, 150, 160));
            draw_text(t_x + 220, slot_y + 78, shots_str);
            
            // Ability Box
            draw_set_color(make_color_rgb(18, 22, 30));
            draw_roundrect_ext(t_x + 14, slot_y + 104, t_x + slot_w - 14, slot_y + slot_h - 60, 4, 4, false);
            draw_set_color(make_color_rgb(45, 55, 75));
            draw_roundrect_ext(t_x + 14, slot_y + 104, t_x + slot_w - 14, slot_y + slot_h - 60, 4, 4, true);
            
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            draw_set_color(is_used ? make_color_rgb(120, 130, 140) : make_color_rgb(180, 205, 230));
            draw_text_ext(t_x + 22, slot_y + 112, twep.ability, 16, slot_w - 44);
            
            // Tesla Coil Discharge Action Button
            if (twep.catalog_id == "tesla" && !is_used && state.combat_subphase == "player_weapons") {
                var btn_y_tes = slot_y + slot_h - 48;
                state.combat_tesla_btn_hover = ui_draw_button(t_x + 14, btn_y_tes, slot_w - 28, 38, "⚡ Discharge (Hit All)", true, false, mx, my);
                if (state.combat_tesla_btn_hover) {
                    state.hover_tooltip = "Discharge shockwave dealing " + string(eff_dmg) + " damage and weakening ALL active aliens!";
                }
            } else {
                // Click weapon selection action / status text
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                if (is_used) {
                    draw_set_color(make_color_rgb(110, 120, 130));
                    draw_text(t_x + slot_w * 0.5, slot_y + slot_h - 28, "All shots fired for this wave");
                } else if (is_sel) {
                    draw_set_color(make_color_rgb(100, 230, 255));
                    draw_text(t_x + slot_w * 0.5, slot_y + slot_h - 28, "TARGET READY // Click alien above to fire");
                } else {
                    draw_set_color(make_color_rgb(255, 215, 0));
                    draw_text(t_x + slot_w * 0.5, slot_y + slot_h - 28, "[Click to Arm This Weapon]");
                }
            }
        }
    }
    else if (m.type == "shop") {
        // -------------------------------------------------------------
        // HEADER: TITLE & CORE HUD BADGES
        // -------------------------------------------------------------
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(c_yellow);
        draw_text(mx0 + mw * 0.5, my0 + 14, "WEAPON & DEFENSE BLUEPRINT SHOP");
        
        var cur_p = state.players[state.current_player_idx];
        var is_at_shop = (cur_p.node == "shop");
        var is_scout = (variable_struct_exists(cur_p, "character") && cur_p.character.id == "scout");
        var task_cost = is_scout ? 2 : 1;
        var cost_note = is_scout ? "Costs 2 Energy to buy (Scout)" : "Costs 1 Energy to buy";
        
        // Operative Status Badge (Top-Left)
        var st_w = 360;
        var st_h = 28;
        var st_x = mx0 + 30;
        var st_y = my0 + 44;
        
        draw_set_color(is_at_shop ? make_color_rgb(16, 38, 24) : make_color_rgb(38, 30, 14));
        draw_roundrect_ext(st_x, st_y, st_x + st_w, st_y + st_h, 6, 6, false);
        draw_set_color(is_at_shop ? make_color_rgb(46, 204, 113) : make_color_rgb(243, 156, 18));
        draw_roundrect_ext(st_x, st_y, st_x + st_w, st_y + st_h, 6, 6, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(is_at_shop ? make_color_rgb(140, 240, 170) : make_color_rgb(255, 200, 80));
        var st_msg = is_at_shop ? ("[AT SHOP] " + cur_p.name + " (" + string(task_cost) + "E to buy)") : "[REMOTE VIEW] Station at Shop to buy";
        draw_text(st_x + 12, st_y + st_h * 0.5, st_msg);
        
        // Team Treasury Badge (Top-Middle)
        var gold_w = 200;
        var gold_h = 28;
        var gold_x = st_x + st_w + 20;
        var gold_y = my0 + 44;
        
        draw_set_color(make_color_rgb(36, 30, 14));
        draw_roundrect_ext(gold_x, gold_y, gold_x + gold_w, gold_y + gold_h, 6, 6, false);
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_roundrect_ext(gold_x, gold_y, gold_x + gold_w, gold_y + gold_h, 6, 6, true);
        
        // Small gold coin icon
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_circle(gold_x + 16, gold_y + gold_h * 0.5, 9, false);
        draw_set_color(make_color_rgb(20, 20, 20));
        draw_circle(gold_x + 16, gold_y + gold_h * 0.5, 9, true);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(20, 20, 20));
        draw_text(gold_x + 16, gold_y + gold_h * 0.5, "G");
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(255, 235, 59));
        draw_text(gold_x + 32, gold_y + gold_h * 0.5, "Team Gold: " + string(state.storage.gold) + "g");
        
        // Reroll Catalog Button (Top-Right)
        var can_reroll = (is_at_shop && state.storage.gold >= state.shop_reroll_cost);
        var r_btn_w = 320;
        var r_btn_x = mx0 + mw - 30 - r_btn_w;
        var r_btn_lbl = is_at_shop ? ("Reroll (" + string(state.shop_reroll_cost) + "g) [+" + string(state.days_without_reroll) + "/3d]") : ("Reroll (" + string(state.shop_reroll_cost) + "g - At Shop)");
        state.shop_reroll_hover = ui_draw_button(r_btn_x, my0 + 42, r_btn_w, 32, r_btn_lbl, can_reroll, false, mx, my);
        if (state.shop_reroll_hover) {
            state.hover_tooltip = "Rerolls catalog items. Next cost: " + string(state.shop_reroll_cost) + "g (+2g/use). Free every 3 days.";
        }
        
        // Subtitle note with deck counter
        var deck_count = variable_struct_exists(state, "shop_deck") ? array_length(state.shop_deck) : 0;
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(140, 165, 195));
        draw_text(mx0 + mw * 0.5, my0 + 82, "Purchase blueprints with Gold. Each purchase instantly draws the next blueprint from the deck (" + string(deck_count) + " in deck).");
        
        // -------------------------------------------------------------
        // 3 WEAPON BLUEPRINT CARDS
        // -------------------------------------------------------------
        var card_w = 356;
        var card_h = 510;
        var card_gap = 26;
        var start_x = mx0 + 30;
        var start_y = my0 + 104;
        state.shop_buy_hover = -1;
        
        var res_defs = game_get_resource_definitions();
        
        for (var i = 0; i < array_length(state.shop_available_items); i++) {
            var item = state.shop_available_items[i];
            if (is_undefined(item)) continue;
            
            // If item is index rather than struct, resolve from catalog
            if (is_real(item)) item = state.shop_catalog[item];
            
            var wx = start_x + i * (card_w + card_gap);
            var wy = start_y;
            var card_hov = ui_point_in_rect(mx, my, wx, wy, card_w, card_h);
            
            // Outer Card Plate
            draw_set_color(card_hov ? make_color_rgb(32, 40, 56) : make_color_rgb(22, 28, 40));
            draw_roundrect_ext(wx, wy, wx + card_w, wy + card_h, 10, 10, false);
            draw_set_color(make_color_rgb(255, 215, 0));
            draw_roundrect_ext(wx, wy, wx + card_w, wy + card_h, 10, 10, true);
            
            // 1. Weapon Name
            draw_set_halign(fa_center); draw_set_valign(fa_top);
            draw_set_color(c_yellow);
            draw_text(wx + card_w * 0.5, wy + 14, item.name);
            
            // 2. Stats Badge Plate (HP, Dmg, Targets)
            var st_py = wy + 40;
            var st_ph = 30;
            draw_set_color(make_color_rgb(16, 20, 30));
            draw_roundrect_ext(wx + 12, st_py, wx + card_w - 12, st_py + st_ph, 6, 6, false);
            draw_set_color(make_color_rgb(46, 60, 80));
            draw_roundrect_ext(wx + 12, st_py, wx + card_w - 12, st_py + st_ph, 6, 6, true);
            
            // Heart icon + HP
            ui_draw_heart(wx + 26, st_py + st_ph * 0.5, 12, make_color_rgb(231, 76, 60));
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(255, 120, 120));
            draw_text(wx + 44, st_py + st_ph * 0.5, string(item.hp) + " HP");
            
            // Damage
            draw_set_color(make_color_rgb(255, 215, 0));
            draw_text(wx + 140, st_py + st_ph * 0.5, string(item.damage) + " Dmg");
            
            // Targets
            draw_set_color(c_white);
            var tgt_str = (item.target_count >= 99) ? "All" : string(item.target_count);
            draw_text(wx + 245, st_py + st_ph * 0.5, "Targets: " + tgt_str);
            
            // 3. Tactical Ability Box
            var ab_py = wy + 78;
            var ab_ph = 86;
            draw_set_color(make_color_rgb(16, 20, 30));
            draw_roundrect_ext(wx + 12, ab_py, wx + card_w - 12, ab_py + ab_ph, 6, 6, false);
            draw_set_color(make_color_rgb(46, 60, 80));
            draw_roundrect_ext(wx + 12, ab_py, wx + card_w - 12, ab_py + ab_ph, 6, 6, true);
            
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            draw_set_color(make_color_rgb(100, 210, 255));
            draw_text(wx + 20, ab_py + 8, "TACTICAL ABILITY:");
            
            draw_set_color(make_color_rgb(220, 235, 245));
            draw_text_ext(wx + 20, ab_py + 26, item.ability, 17, card_w - 40);
            
            // 4. Blueprint Specs & Materials Box
            var sp_py = wy + 172;
            var sp_ph = 254;
            draw_set_color(make_color_rgb(16, 20, 30));
            draw_roundrect_ext(wx + 12, sp_py, wx + card_w - 12, sp_py + sp_ph, 6, 6, false);
            draw_set_color(make_color_rgb(46, 60, 80));
            draw_roundrect_ext(wx + 12, sp_py, wx + card_w - 12, sp_py + sp_ph, 6, 6, true);
            
            // Price Tag
            draw_set_color(make_color_rgb(255, 215, 0));
            draw_circle(wx + 28, sp_py + 18, 9, false);
            draw_set_color(make_color_rgb(20, 20, 20));
            draw_circle(wx + 28, sp_py + 18, 9, true);
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_text(wx + 28, sp_py + 18, "G");
            
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(255, 220, 70));
            draw_text(wx + 44, sp_py + 18, "Blueprint Price: " + string(item.cost_gold) + " Gold");
            
            // Divider
            draw_set_color(make_color_rgb(38, 50, 68));
            draw_line_width(wx + 16, sp_py + 34, wx + card_w - 16, sp_py + 34, 1);
            
            // Materials Header
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(140, 195, 240));
            draw_text(wx + 20, sp_py + 48, "Forge Materials (Workstation):");
            
            // Materials Rows
            var rkeys = variable_struct_get_names(item.cost_res);
            var mat_start_y = sp_py + 72;
            var has_all_mats = true;
            
            for (var k = 0; k < array_length(rkeys); k++) {
                var rk = rkeys[k];
                var rdef = res_defs[$ rk];
                var need = item.cost_res[$ rk];
                var have = state.storage[$ rk];
                if (have < need) has_all_mats = false;
                
                var my_row = mat_start_y + k * 24;
                
                // Mini resource token
                draw_set_color(rdef.color);
                draw_circle(wx + 28, my_row, 8, false);
                draw_set_color(c_white);
                draw_circle(wx + 28, my_row, 8, true);
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_text(wx + 28, my_row, rdef.icon_char);
                
                // Label
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color((have >= need) ? make_color_rgb(120, 230, 150) : make_color_rgb(255, 120, 120));
                draw_text(wx + 44, my_row, string(need) + " " + rdef.name + " (" + string(have) + " in storage)");
            }
            
            // Unique copy in stock & deck replenishment note
            var stk_y = sp_py + 196;
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(105, 240, 174));
            draw_text(wx + 20, stk_y, "★ 1 In Stock (Single Blueprint)");
            
            draw_set_color(make_color_rgb(130, 150, 175));
            draw_text(wx + 20, stk_y + 18, "Auto-replenishes from deck");
            
            // 5. Buy Blueprint Button
            var can_buy = (is_at_shop && cur_p.energy >= task_cost && state.storage.gold >= item.cost_gold);
            var buy_lbl = "Buy Blueprint (" + string(item.cost_gold) + "g)";
            if (!is_at_shop) buy_lbl = "Visit Shop to Buy";
            else if (cur_p.energy < task_cost) buy_lbl = "Need " + string(task_cost) + " Energy";
            else if (state.storage.gold < item.cost_gold) buy_lbl = "Need " + string(item.cost_gold) + " Gold";
            
            var btn_y = wy + 442;
            var btn_w = card_w - 24;
            var bhov = ui_draw_button(wx + 12, btn_y, btn_w, 48, buy_lbl, can_buy, false, mx, my);
            if (bhov) {
                state.shop_buy_hover = i;
                if (!is_at_shop) state.hover_tooltip = "Must be stationed at the Shop to buy blueprints.";
                else if (cur_p.energy < task_cost) state.hover_tooltip = "Not enough Energy (Requires " + string(task_cost) + " Energy).";
                else if (state.storage.gold < item.cost_gold) state.hover_tooltip = "Need " + string(item.cost_gold - state.storage.gold) + " more Gold in Team Storage.";
                else state.hover_tooltip = "Purchase " + item.name + " Blueprint for " + string(item.cost_gold) + " Gold. (Next deck card will take its place)";
            }
        }
    }
    else if (m.type == "town") {
        // -------------------------------------------------------------
        // HEADER: TITLE & CORE HUD BADGES
        // -------------------------------------------------------------
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(c_yellow);
        draw_text(mx0 + mw * 0.5, my0 + 14, "TOWN TRADING MARKET");
        
        var cur_fav = state.town_favors[state.active_town_favor];
        var cur_p = state.players[state.current_player_idx];
        var is_at_town = (cur_p.node == "town");
        var is_scout = (variable_struct_exists(cur_p, "character") && cur_p.character.id == "scout");
        var task_cost = is_scout ? 2 : 1;
        var cost_note = is_scout ? "Costs 2 Energy per trade (Scout)" : "Costs 1 Energy per trade";
        
        // Operative Status Badge (Top-Left)
        var st_w = 480;
        var st_h = 28;
        var st_x = mx0 + 30;
        var st_y = my0 + 44;
        
        draw_set_color(is_at_town ? make_color_rgb(16, 38, 24) : make_color_rgb(38, 30, 14));
        draw_roundrect_ext(st_x, st_y, st_x + st_w, st_y + st_h, 6, 6, false);
        draw_set_color(is_at_town ? make_color_rgb(46, 204, 113) : make_color_rgb(243, 156, 18));
        draw_roundrect_ext(st_x, st_y, st_x + st_w, st_y + st_h, 6, 6, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(is_at_town ? make_color_rgb(140, 240, 170) : make_color_rgb(255, 200, 80));
        var st_msg = is_at_town ? ("[AT TOWN] " + cur_p.name + " Ready to Trade • " + cost_note) : "[REMOTE VIEW] Move operative to Town to trade goods";
        draw_text(st_x + 12, st_y + st_h * 0.5, st_msg);
        
        // Team Treasury Badge (Top-Right)
        var gold_w = 230;
        var gold_h = 28;
        var gold_x = mx0 + mw - 30 - gold_w;
        var gold_y = my0 + 44;
        
        draw_set_color(make_color_rgb(36, 30, 14));
        draw_roundrect_ext(gold_x, gold_y, gold_x + gold_w, gold_y + gold_h, 6, 6, false);
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_roundrect_ext(gold_x, gold_y, gold_x + gold_w, gold_y + gold_h, 6, 6, true);
        
        // Small gold coin icon
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_circle(gold_x + 18, gold_y + gold_h * 0.5, 9, false);
        draw_set_color(make_color_rgb(20, 20, 20));
        draw_circle(gold_x + 18, gold_y + gold_h * 0.5, 9, true);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(20, 20, 20));
        draw_text(gold_x + 18, gold_y + gold_h * 0.5, "G");
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(255, 235, 59));
        draw_text(gold_x + 34, gold_y + gold_h * 0.5, "Team Gold: " + string(state.storage.gold) + "g");
        
        // -------------------------------------------------------------
        // TODAY'S TOWN FAVOR BANNER
        // -------------------------------------------------------------
        var fav_x = mx0 + 30;
        var fav_y = my0 + 80;
        var fav_w = mw - 60; // 1120px
        var fav_h = 54;
        
        draw_set_color(make_color_rgb(32, 26, 18));
        draw_roundrect_ext(fav_x, fav_y, fav_x + fav_w, fav_y + fav_h, 8, 8, false);
        draw_set_color(make_color_rgb(255, 179, 0));
        draw_roundrect_ext(fav_x, fav_y, fav_x + fav_w, fav_y + fav_h, 8, 8, true);
        
        // Star badge pill on left
        var pill_w = 90;
        var pill_h = 32;
        var pill_x = fav_x + 12;
        var pill_y = fav_y + 11;
        draw_set_color(make_color_rgb(64, 48, 14));
        draw_roundrect_ext(pill_x, pill_y, pill_x + pill_w, pill_y + pill_h, 6, 6, false);
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_roundrect_ext(pill_x, pill_y, pill_x + pill_w, pill_y + pill_h, 6, 6, true);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_text(pill_x + pill_w * 0.5, pill_y + pill_h * 0.5, "★ FAVOR");
        
        // Favor text descriptions
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(255, 225, 110));
        draw_text(fav_x + 115, fav_y + 18, "TODAY'S TOWN FAVOR: " + string_upper(cur_fav.name) + " (" + cur_fav.desc + ")");
        
        draw_set_color(make_color_rgb(205, 195, 175));
        draw_text(fav_x + 115, fav_y + 38, "Market demand rotates each wave. Sell favored items today for maximum return!");
        
        // Right side bonus pill
        var bon_w = 210;
        var bon_h = 32;
        var bon_x = fav_x + fav_w - 14 - bon_w;
        var bon_y = fav_y + 11;
        draw_set_color(make_color_rgb(20, 48, 28));
        draw_roundrect_ext(bon_x, bon_y, bon_x + bon_w, bon_y + bon_h, 6, 6, false);
        draw_set_color(make_color_rgb(46, 204, 113));
        draw_roundrect_ext(bon_x, bon_y, bon_x + bon_w, bon_y + bon_h, 6, 6, true);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(105, 240, 174));
        draw_text(bon_x + bon_w * 0.5, bon_y + bon_h * 0.5, "+ " + string(cur_fav.bonus_gold) + "g EXTRA / ITEM");
        
        // -------------------------------------------------------------
        // COLUMN HEADERS
        // -------------------------------------------------------------
        var col_y = my0 + 148;
        draw_set_color(make_color_rgb(130, 155, 185));
        draw_set_valign(fa_middle);
        
        draw_set_halign(fa_left);
        draw_text(mx0 + 44, col_y, "COMMODITY");
        draw_text(mx0 + 260, col_y, "TEAM STORAGE");
        draw_text(mx0 + 450, col_y, "CURRENT VALUE");
        draw_text(mx0 + 740, col_y, "QUICK TRADE (SELL FROM STORAGE)");
        
        // -------------------------------------------------------------
        // 6 RESOURCE TRADE ROWS
        // -------------------------------------------------------------
        var trade_res = ["wood", "scrap", "stone", "metal", "crystals", "power_gem"];
        var start_ty = my0 + 166;
        var row_h = 60;
        var row_gap = 6;
        var row_w = mw - 60; // 1120px
        
        state.town_sell_hover = -1;
        state.town_sell_count = 0;
        
        var res_defs = game_get_resource_definitions();
        var can_act = (is_at_town && cur_p.energy >= task_cost);
        
        for (var t = 0; t < array_length(trade_res); t++) {
            var rk = trade_res[t];
            var rdef = res_defs[$ rk];
            var total_have = state.storage[$ rk];
            var base_v = rdef.sell_value;
            var bonus = (cur_fav.resource == rk) ? cur_fav.bonus_gold : 0;
            var per_item = base_v + bonus;
            var is_favored = (bonus > 0);
            
            var ry = start_ty + t * (row_h + row_gap);
            var rx = mx0 + 30;
            var r_mid_y = ry + row_h * 0.5;
            
            // Row Container
            draw_set_color(is_favored ? make_color_rgb(34, 30, 20) : make_color_rgb(22, 28, 40));
            draw_roundrect_ext(rx, ry, rx + row_w, ry + row_h, 8, 8, false);
            draw_set_color(is_favored ? make_color_rgb(255, 179, 0) : make_color_rgb(46, 60, 80));
            draw_roundrect_ext(rx, ry, rx + row_w, ry + row_h, 8, 8, true);
            
            // 1. Resource Icon Token
            var ic_x = rx + 26;
            draw_set_color(rdef.color);
            draw_circle(ic_x, r_mid_y, 16, false);
            draw_set_color(c_white);
            draw_circle(ic_x, r_mid_y, 16, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(c_white);
            draw_text(ic_x, r_mid_y, rdef.icon_char);
            
            // 2. Resource Name
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(is_favored ? make_color_rgb(255, 235, 130) : c_white);
            draw_text(rx + 54, r_mid_y, rdef.name);
            
            if (is_favored) {
                var name_w = string_width(rdef.name);
                var f_pill_x = rx + 54 + name_w + 12;
                var f_pill_w = 68;
                var f_pill_h = 20;
                draw_set_color(make_color_rgb(58, 44, 14));
                draw_roundrect_ext(f_pill_x, r_mid_y - 10, f_pill_x + f_pill_w, r_mid_y + 10, 4, 4, false);
                draw_set_color(make_color_rgb(255, 193, 7));
                draw_roundrect_ext(f_pill_x, r_mid_y - 10, f_pill_x + f_pill_w, r_mid_y + 10, 4, 4, true);
                
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(255, 225, 80));
                draw_text(f_pill_x + f_pill_w * 0.5, r_mid_y, "FAVOR");
            }
            
            // 3. Storage Count
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            if (total_have > 0) {
                draw_set_color(make_color_rgb(100, 215, 255));
                draw_text(mx0 + 260, r_mid_y, string(total_have) + " in storage");
            } else {
                draw_set_color(make_color_rgb(130, 140, 150));
                draw_text(mx0 + 260, r_mid_y, "0 in storage");
            }
            
            // 4. Unit Market Value
            if (is_favored) {
                draw_set_color(make_color_rgb(255, 215, 0));
                draw_text(mx0 + 450, r_mid_y, string(per_item) + "g each (Base " + string(base_v) + " + " + string(bonus) + "g Favor)");
            } else {
                draw_set_color(make_color_rgb(220, 220, 220));
                draw_text(mx0 + 450, r_mid_y, string(per_item) + "g each");
            }
            
            // 5. Sell Quantity Buttons
            var btn_y = ry + 12;
            var btn_h = 36;
            var btn_w = 115;
            
            var b1_x = mx0 + 740;
            var b2_x = mx0 + 865;
            var b3_x = mx0 + 990;
            
            var b1_can = (can_act && total_have >= 1);
            var b2_can = (can_act && total_have >= 2);
            var b3_can = (can_act && total_have >= 3);
            
            var bh1 = ui_draw_button(b1_x, btn_y, btn_w, btn_h, "Sell 1 (" + string(per_item * 1) + "g)", b1_can, false, mx, my);
            if (bh1) { 
                state.town_sell_hover = t; 
                state.town_sell_count = 1; 
                if (!is_at_town) state.hover_tooltip = "Must be stationed at Town to sell resources.";
                else if (cur_p.energy < task_cost) state.hover_tooltip = "Not enough Energy to trade (Requires " + string(task_cost) + " Energy).";
                else if (total_have < 1) state.hover_tooltip = "No " + rdef.name + " available in storage.";
            }
            
            var bh2 = ui_draw_button(b2_x, btn_y, btn_w, btn_h, "Sell 2 (" + string(per_item * 2) + "g)", b2_can, false, mx, my);
            if (bh2) { 
                state.town_sell_hover = t; 
                state.town_sell_count = 2; 
                if (!is_at_town) state.hover_tooltip = "Must be stationed at Town to sell resources.";
                else if (cur_p.energy < task_cost) state.hover_tooltip = "Not enough Energy to trade (Requires " + string(task_cost) + " Energy).";
                else if (total_have < 2) state.hover_tooltip = "Need at least 2 " + rdef.name + " in storage.";
            }
            
            var bh3 = ui_draw_button(b3_x, btn_y, btn_w, btn_h, "Sell 3 (" + string(per_item * 3) + "g)", b3_can, false, mx, my);
            if (bh3) { 
                state.town_sell_hover = t; 
                state.town_sell_count = 3; 
                if (!is_at_town) state.hover_tooltip = "Must be stationed at Town to sell resources.";
                else if (cur_p.energy < task_cost) state.hover_tooltip = "Not enough Energy to trade (Requires " + string(task_cost) + " Energy).";
                else if (total_have < 3) state.hover_tooltip = "Need at least 3 " + rdef.name + " in storage.";
            }
        }
        
        // -------------------------------------------------------------
        // FOOTER HINT
        // -------------------------------------------------------------
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(130, 150, 175));
        draw_text(mx0 + mw * 0.5, my0 + mh - 20, "All proceeds from sales are immediately placed into Base Storage for weapon blueprints & upgrades.");
    }
    else if (m.type == "repair" || m.type == "workstation") {
        // -------------------------------------------------------------
        // HEADER: TITLE & CORE HUD BADGES
        // -------------------------------------------------------------
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(c_yellow);
        draw_text(mx0 + mw * 0.5, my0 + 14, "DEFENSE WORKSTATION // BLUEPRINT FORGE & BASE REPAIR");
        
        var cur_p = state.players[state.current_player_idx];
        var is_at_workstation = (cur_p.node == "workstation");
        var is_scout = (variable_struct_exists(cur_p, "character") && cur_p.character.id == "scout");
        var is_engineer = (variable_struct_exists(cur_p, "character") && cur_p.character.id == "engineer");
        var task_cost = is_scout ? 2 : 1;
        var cost_note = is_scout ? "Costs 2 Energy (Scout)" : "Costs 1 Energy";
        
        // Operative Status Badge (Top-Left)
        var st_w = 540;
        var st_h = 28;
        var st_x = mx0 + 30;
        var st_y = my0 + 44;
        
        draw_set_color(is_at_workstation ? make_color_rgb(16, 38, 24) : make_color_rgb(38, 30, 14));
        draw_roundrect_ext(st_x, st_y, st_x + st_w, st_y + st_h, 6, 6, false);
        draw_set_color(is_at_workstation ? make_color_rgb(46, 204, 113) : make_color_rgb(243, 156, 18));
        draw_roundrect_ext(st_x, st_y, st_x + st_w, st_y + st_h, 6, 6, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(is_at_workstation ? make_color_rgb(140, 240, 170) : make_color_rgb(255, 200, 80));
        var st_msg = is_at_workstation ? ("[AT WORKSTATION] " + cur_p.name + " Ready • " + cost_note) : "[REMOTE VIEW] Move operative to Workstation to forge/repair";
        draw_text(st_x + 12, st_y + st_h * 0.5, st_msg);
        
        // Right Perk / System Pill
        var pk_w = 560;
        var pk_h = 28;
        var pk_x = mx0 + 590;
        var pk_y = my0 + 44;
        
        draw_set_color(make_color_rgb(20, 28, 40));
        draw_roundrect_ext(pk_x, pk_y, pk_x + pk_w, pk_y + pk_h, 6, 6, false);
        draw_set_color(is_engineer ? make_color_rgb(255, 215, 0) : make_color_rgb(66, 165, 245));
        draw_roundrect_ext(pk_x, pk_y, pk_x + pk_w, pk_y + pk_h, 6, 6, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(is_engineer ? make_color_rgb(255, 235, 110) : make_color_rgb(170, 215, 255));
        var pk_txt = is_engineer ? "★ Combat Engineer Perk: Base & weapon repairs restore +1 extra HP!" : (is_scout ? "Scout Operative: High map speed / Base tasks cost 2 Energy" : "Base Fortification & Tactical Defense Mount Hub");
        draw_text(pk_x + 12, pk_y + pk_h * 0.5, pk_txt);
        
        state.workstation_craft_bp_idx = -1;
        state.workstation_craft_target_tower = -1;
        state.repair_tower_1_hover = -1;
        state.repair_tower_3_hover = -1;
        state.repair_weapon_hover = -1;
        
        // -------------------------------------------------------------
        // LEFT COLUMN: OWNED BLUEPRINTS (FORGE & MOUNT DEFENSES)
        // -------------------------------------------------------------
        var col1_x = mx0 + 30;
        var col1_w = 550;
        var num_bp = array_length(state.blueprints);
        var view_y = my0 + 112;
        var view_h = 488;
        
        // Section Header Banner
        draw_set_color(make_color_rgb(20, 28, 40));
        draw_roundrect_ext(col1_x, my0 + 78, col1_x + col1_w, my0 + 104, 6, 6, false);
        draw_set_color(make_color_rgb(46, 75, 105));
        draw_roundrect_ext(col1_x, my0 + 78, col1_x + col1_w, my0 + 104, 6, 6, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(100, 210, 255));
        var bp_header_title = "OWNED BLUEPRINTS (" + string(num_bp) + ") // FORGE DEFENSES";
        draw_text(col1_x + 12, my0 + 91, bp_header_title);
        
        if (num_bp > 3) {
            draw_set_halign(fa_right); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(140, 165, 195));
            draw_text(col1_x + col1_w - 12, my0 + 91, "Scrollable [Wheel]");
        }
        
        if (num_bp == 0) {
            draw_set_color(make_color_rgb(18, 24, 34));
            draw_roundrect_ext(col1_x, view_y, col1_x + col1_w, view_y + view_h, 8, 8, false);
            draw_set_color(make_color_rgb(45, 60, 80));
            draw_roundrect_ext(col1_x, view_y, col1_x + col1_w, view_y + view_h, 8, 8, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(180, 200, 220));
            draw_text_ext(col1_x + col1_w * 0.5, view_y + view_h * 0.5, "[No Blueprints Owned]\n\nVisit the Weapon Shop (south of Main Base) to purchase\nweapon blueprints using Gold.\n\nOnce acquired, bring them here to spend raw materials\nand forge them directly onto Towers 1-4!", 22, col1_w - 40);
        } else {
            var total_bp_h = num_bp * 160;
            var max_scroll = max(0, total_bp_h - view_h);
            state.workstation_bp_max_scroll = max_scroll;
            state.workstation_bp_scroll_y = clamp(state.workstation_bp_scroll_y, 0, max_scroll);
            
            var surf_w = col1_w;
            var surf_h = view_h;
            
            if (!variable_struct_exists(state, "workstation_bp_surf") || is_undefined(state.workstation_bp_surf) || !surface_exists(state.workstation_bp_surf)) {
                state.workstation_bp_surf = surface_create(surf_w, surf_h);
            } else if (surface_get_width(state.workstation_bp_surf) != surf_w || surface_get_height(state.workstation_bp_surf) != surf_h) {
                surface_free(state.workstation_bp_surf);
                state.workstation_bp_surf = surface_create(surf_w, surf_h);
            }
            
            surface_set_target(state.workstation_bp_surf);
            draw_clear_alpha(c_black, 0);
            
            // Background box for surface
            draw_set_color(make_color_rgb(18, 24, 34));
            draw_roundrect_ext(0, 0, surf_w, surf_h, 8, 8, false);
            draw_set_color(make_color_rgb(45, 60, 80));
            draw_roundrect_ext(0, 0, surf_w, surf_h, 8, 8, true);
            
            var in_view = (mx >= col1_x && mx <= col1_x + col1_w && my >= view_y && my <= view_y + view_h);
            var local_mx = in_view ? (mx - col1_x) : -9999;
            var local_my = in_view ? (my - view_y) : -9999;
            
            var card_inner_w = (total_bp_h > view_h) ? (surf_w - 22) : (surf_w - 8);
            
            for (var b = 0; b < num_bp; b++) {
                var bp = state.blueprints[b];
                var bp_h = 152;
                var bpy = b * 160 - state.workstation_bp_scroll_y;
                
                // Cull invisible cards
                if (bpy + bp_h < 0 || bpy > surf_h) continue;
                
                draw_set_color(make_color_rgb(22, 28, 40));
                draw_roundrect_ext(4, bpy, 4 + card_inner_w, bpy + bp_h, 8, 8, false);
                draw_set_color(make_color_rgb(52, 73, 94));
                draw_roundrect_ext(4, bpy, 4 + card_inner_w, bpy + bp_h, 8, 8, true);
                
                // Name & Stats
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(c_yellow);
                draw_text(18, bpy + 16, bp.name);
                
                // Stats Plate (HP, Dmg, Targets)
                ui_draw_heart(295, bpy + 16, 11, make_color_rgb(231, 76, 60));
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(255, 120, 120));
                draw_text(308, bpy + 16, string(bp.hp) + " HP");
                
                draw_set_color(make_color_rgb(255, 215, 0));
                draw_text(385, bpy + 16, string(bp.damage) + " Dmg");
                
                draw_set_color(c_white);
                var tgt_lbl = (bp.target_count >= 99) ? "All" : string(bp.target_count);
                draw_text(465, bpy + 16, "Tgt: " + tgt_lbl);
                
                // Required Resources
                var rkeys = variable_struct_get_names(bp.cost_res);
                var req_str = "Needs: ";
                var has_all_mats = true;
                for (var k = 0; k < array_length(rkeys); k++) {
                    var rk = rkeys[k];
                    var need = bp.cost_res[$ rk];
                    var have = state.storage[$ rk];
                    if (have < need) has_all_mats = false;
                    req_str += string(need) + " " + string_upper(rk) + " (" + string(have) + ")   ";
                }
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(has_all_mats ? make_color_rgb(120, 230, 150) : make_color_rgb(255, 120, 120));
                draw_text(18, bpy + 40, req_str);
                
                // Ability
                draw_set_color(make_color_rgb(180, 205, 230));
                draw_text_ext(18, bpy + 62, bp.ability, 16, card_inner_w - 24);
                
                // Mount Buttons (T1, T2, T3, T4)
                var can_craft_base = (is_at_workstation && cur_p.energy >= task_cost && has_all_mats);
                var tw_w = floor((card_inner_w - 24 - 3 * 8) / 4);
                var tw_gap = 8;
                var tw_y = bpy + 102;
                
                for (var t = 0; t < 4; t++) {
                    var tw = state.towers[t];
                    var tw_x = 12 + t * (tw_w + tw_gap);
                    var tw_can = false;
                    var tw_lbl = "Mount T" + string(t + 1);
                    
                    if (!tw.alive) {
                        tw_lbl = "T" + string(t + 1) + " Dead";
                    } else if (!is_undefined(tw.weapon) && tw.weapon.alive && tw.weapon.hp > 0) {
                        tw_lbl = "T" + string(t + 1) + " Full";
                    } else {
                        tw_can = can_craft_base;
                    }
                    
                    var tw_hov = ui_draw_button(tw_x, tw_y, tw_w, 38, tw_lbl, tw_can, false, local_mx, local_my);
                    if (tw_hov && tw_can) {
                        state.workstation_craft_bp_idx = b;
                        state.workstation_craft_target_tower = t;
                    }
                    if (tw_hov) {
                        if (!tw.alive) state.hover_tooltip = "Tower " + string(t + 1) + " is destroyed!";
                        else if (!is_undefined(tw.weapon) && tw.weapon.alive && tw.weapon.hp > 0) {
                            state.hover_tooltip = "Tower " + string(t + 1) + " already has " + tw.weapon.name + "! Stand at Tower " + string(t + 1) + " to dismantle it first.";
                        } else if (!is_at_workstation) {
                            state.hover_tooltip = "Must be stationed at the Workstation to forge defenses.";
                        } else if (cur_p.energy < task_cost) {
                            state.hover_tooltip = "Not enough Energy (Requires " + string(task_cost) + " Energy).";
                        } else if (!has_all_mats) {
                            state.hover_tooltip = "Missing required resources in storage to forge " + bp.name + ".";
                        } else {
                            state.hover_tooltip = "Forge " + bp.name + " and station it on Tower " + string(t + 1) + ".";
                        }
                    }
                }
            }
            
            surface_reset_target();
            draw_surface(state.workstation_bp_surf, col1_x, view_y);
            
            // Vertical Scrollbar for Blueprints
            if (total_bp_h > view_h) {
                var v_track_x = col1_x + col1_w - 14;
                var v_track_y = view_y + 4;
                var v_track_w = 8;
                var v_track_h = view_h - 8;
                
                draw_set_color(make_color_rgb(24, 30, 42));
                draw_roundrect_ext(v_track_x, v_track_y, v_track_x + v_track_w, v_track_y + v_track_h, 4, 4, false);
                
                var thumb_h = max(28, (view_h / total_bp_h) * v_track_h);
                var thumb_y = v_track_y + (state.workstation_bp_scroll_y / max_scroll) * (v_track_h - thumb_h);
                var thumb_hov = point_in_rectangle(mx, my, v_track_x - 3, thumb_y, v_track_x + v_track_w + 3, thumb_y + thumb_h);
                state.workstation_bp_thumb_hover = thumb_hov;
                state.workstation_bp_usable_track = max(1, v_track_h - thumb_h);
                
                var thumb_col = ((variable_struct_exists(state, "workstation_bp_drag") && state.workstation_bp_drag) || thumb_hov) ? make_color_rgb(100, 160, 230) : make_color_rgb(60, 80, 110);
                draw_set_color(thumb_col);
                draw_roundrect_ext(v_track_x, thumb_y, v_track_x + v_track_w, thumb_y + thumb_h, 4, 4, false);
            } else {
                state.workstation_bp_thumb_hover = false;
                state.workstation_bp_usable_track = 1;
            }
        }
        
        // -------------------------------------------------------------
        // RIGHT COLUMN: REPAIR BASE TOWERS & DEFENSES
        // -------------------------------------------------------------
        var col2_x = mx0 + 600;
        var col2_w = 550;
        
        // Section Header Banner: Base Towers
        draw_set_color(make_color_rgb(20, 28, 40));
        draw_roundrect_ext(col2_x, my0 + 78, col2_x + col2_w, my0 + 104, 6, 6, false);
        draw_set_color(make_color_rgb(46, 75, 105));
        draw_roundrect_ext(col2_x, my0 + 78, col2_x + col2_w, my0 + 104, 6, 6, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(100, 210, 255));
        draw_text(col2_x + 12, my0 + 91, "BASE TOWER FORTIFICATIONS // REPAIRS");
        
        var ry = my0 + 112;
        var rep_row_h = 44;
        var rep_gap = 6;
        
        for (var t = 0; t < 4; t++) {
            var tow = state.towers[t];
            var r_row_y = ry + t * (rep_row_h + rep_gap);
            var r_mid = r_row_y + rep_row_h * 0.5;
            
            // Tower Row Card
            draw_set_color(make_color_rgb(22, 28, 40));
            draw_roundrect_ext(col2_x, r_row_y, col2_x + col2_w, r_row_y + rep_row_h, 6, 6, false);
            draw_set_color(make_color_rgb(46, 60, 80));
            draw_roundrect_ext(col2_x, r_row_y, col2_x + col2_w, r_row_y + rep_row_h, 6, 6, true);
            
            // Blue Heart Icon
            ui_draw_heart(col2_x + 18, r_mid, 11, tow.alive ? make_color_rgb(33, 150, 243) : make_color_rgb(90, 90, 90));
            
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(tow.alive ? c_white : make_color_rgb(220, 80, 80));
            draw_text(col2_x + 36, r_mid, tow.name + ":");
            
            draw_set_color(tow.alive ? (tow.hp < tow.max_hp ? make_color_rgb(255, 205, 100) : make_color_rgb(100, 220, 255)) : make_color_rgb(220, 80, 80));
            draw_text(col2_x + 104, r_mid, tow.alive ? (string(tow.hp) + "/" + string(tow.max_hp)) : "DEAD");
            
            // Repair Buttons with Resource Icons
            var can_rep1 = (is_at_workstation && tow.alive && tow.hp < tow.max_hp && cur_p.energy >= task_cost && state.storage.stone >= 1 && state.storage.wood >= 1);
            var can_rep3 = (is_at_workstation && tow.alive && tow.hp < tow.max_hp && cur_p.energy >= task_cost && (state.storage.metal >= 1 || (state.storage.scrap >= 1 && state.storage.stone >= 1)));
            
            var b1_x = col2_x + 172;
            var b1_w = 170;
            var b1_y = r_mid - 16;
            var b1_h = 32;
            var bhov1 = ui_draw_button(b1_x, b1_y, b1_w, b1_h, "", can_rep1, false, mx, my);
            
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(can_rep1 ? (bhov1 ? c_yellow : make_color_rgb(120, 240, 150)) : make_color_rgb(140, 140, 140));
            draw_text(b1_x + 10, r_mid, "+1 HP");
            draw_set_color(can_rep1 ? c_white : make_color_rgb(140, 140, 140));
            draw_text(b1_x + 60, r_mid, "1");
            ui_draw_resource_token(b1_x + 78, r_mid, "stone", 8);
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(can_rep1 ? c_white : make_color_rgb(140, 140, 140));
            draw_text(b1_x + 94, r_mid, "+ 1");
            ui_draw_resource_token(b1_x + 128, r_mid, "wood", 8);
            
            if (bhov1) {
                state.repair_tower_1_hover = t;
                if (!is_at_workstation) state.hover_tooltip = "Must be at Workstation to repair base.";
                else if (tow.hp >= tow.max_hp) state.hover_tooltip = tow.name + " is already at full health.";
                else if (state.storage.stone < 1 || state.storage.wood < 1) state.hover_tooltip = "Requires 1 Stone and 1 Wood in Team Storage.";
                else state.hover_tooltip = "Repair 1 HP on " + tow.name + " (Costs 1 Stone + 1 Wood).";
            }
            
            var b2_x = col2_x + 352;
            var b2_w = 186;
            var b2_y = r_mid - 16;
            var b2_h = 32;
            var bhov3 = ui_draw_button(b2_x, b2_y, b2_w, b2_h, "", can_rep3, false, mx, my);
            
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(can_rep3 ? (bhov3 ? c_yellow : make_color_rgb(100, 220, 255)) : make_color_rgb(140, 140, 140));
            draw_text(b2_x + 10, r_mid, "+3 HP");
            draw_set_color(can_rep3 ? c_white : make_color_rgb(140, 140, 140));
            draw_text(b2_x + 60, r_mid, "1");
            ui_draw_resource_token(b2_x + 78, r_mid, "metal", 8);
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(can_rep3 ? make_color_rgb(180, 200, 220) : make_color_rgb(140, 140, 140));
            draw_text(b2_x + 93, r_mid, "/");
            ui_draw_resource_token(b2_x + 110, r_mid, "scrap", 8);
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(can_rep3 ? make_color_rgb(180, 200, 220) : make_color_rgb(140, 140, 140));
            draw_text(b2_x + 125, r_mid, "+");
            ui_draw_resource_token(b2_x + 144, r_mid, "stone", 8);
            
            if (bhov3) {
                state.repair_tower_3_hover = t;
                if (!is_at_workstation) state.hover_tooltip = "Must be at Workstation to repair base.";
                else if (tow.hp >= tow.max_hp) state.hover_tooltip = tow.name + " is already at full health.";
                else if (state.storage.metal < 1 && (state.storage.scrap < 1 || state.storage.stone < 1)) state.hover_tooltip = "Requires 1 Metal OR (1 Scrap + 1 Stone) in Storage.";
                else state.hover_tooltip = "Fortify 3 HP on " + tow.name + " (Costs 1 Metal or 1 Scrap+1 Stone).";
            }
        }
        
        // Mounted Weapons Section Header
        var wep_sec_y = my0 + 322;
        draw_set_color(make_color_rgb(20, 28, 40));
        draw_roundrect_ext(col2_x, wep_sec_y, col2_x + col2_w, wep_sec_y + 26, 6, 6, false);
        draw_set_color(make_color_rgb(46, 75, 105));
        draw_roundrect_ext(col2_x, wep_sec_y, col2_x + col2_w, wep_sec_y + 26, 6, 6, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(100, 210, 255));
        draw_text(col2_x + 12, wep_sec_y + 13, "REPAIR MOUNTED DEFENSE WEAPONS");
        
        var wy = my0 + 356;
        var wep_count = 0;
        for (var t = 0; t < 4; t++) {
            var tow = state.towers[t];
            if (!is_undefined(tow.weapon) && tow.weapon.alive) {
                var wep = tow.weapon;
                var wy_row = wy + wep_count * 46;
                var w_mid = wy_row + 20;
                wep_count++;
                
                // Weapon Card
                draw_set_color(make_color_rgb(22, 28, 40));
                draw_roundrect_ext(col2_x, wy_row, col2_x + col2_w, wy_row + 40, 6, 6, false);
                draw_set_color(make_color_rgb(46, 60, 80));
                draw_roundrect_ext(col2_x, wy_row, col2_x + col2_w, wy_row + 40, 6, 6, true);
                
                // Red heart
                ui_draw_heart(col2_x + 18, w_mid, 11, make_color_rgb(231, 76, 60));
                
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(c_white);
                var w_disp_name = "T" + string(t + 1) + ": " + wep.name;
                draw_text(col2_x + 36, w_mid, w_disp_name);
                
                draw_set_color(wep.hp < wep.max_hp ? make_color_rgb(255, 120, 120) : make_color_rgb(100, 220, 255));
                draw_text(col2_x + 185, w_mid, string(wep.hp) + "/" + string(wep.max_hp) + " HP");
                
                var can_wrep = (is_at_workstation && wep.alive && wep.hp < wep.max_hp && cur_p.energy >= task_cost);
                var bw_x = col2_x + 280;
                var bw_w = 258;
                var bw_y = w_mid - 15;
                var bw_h = 30;
                var bhov_w = ui_draw_button(bw_x, bw_y, bw_w, bw_h, "", can_wrep, false, mx, my);
                
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(can_wrep ? (bhov_w ? c_yellow : make_color_rgb(120, 240, 150)) : make_color_rgb(140, 140, 140));
                draw_text(bw_x + 10, w_mid, "+2 HP (1x:");
                var rnames = variable_struct_get_names(wep.cost_res);
                var r_cnt = min(3, array_length(rnames));
                var rx_start = bw_x + 106;
                for (var ri = 0; ri < r_cnt; ri++) {
                    if (ri > 0) {
                        draw_set_halign(fa_left); draw_set_valign(fa_middle);
                        draw_set_color(can_wrep ? make_color_rgb(180, 200, 220) : make_color_rgb(140, 140, 140));
                        draw_text(rx_start + ri * 30 - 10, w_mid, "/");
                    }
                    ui_draw_resource_token(rx_start + ri * 30 + 4, w_mid, rnames[ri], 8);
                }
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(can_wrep ? make_color_rgb(120, 240, 150) : make_color_rgb(140, 140, 140));
                draw_text(rx_start + r_cnt * 30 - 4, w_mid, ")");
                
                if (bhov_w) {
                    state.repair_weapon_hover = t;
                    if (!is_at_workstation) state.hover_tooltip = "Must be at Workstation to repair weapons.";
                    else if (wep.hp >= wep.max_hp) state.hover_tooltip = wep.name + " is already at full health.";
                    else state.hover_tooltip = "Repair 2 HP on " + wep.name + " using 1 material from its blueprint recipe.";
                }
            }
        }
        if (wep_count == 0) {
            draw_set_color(make_color_rgb(18, 24, 34));
            draw_roundrect_ext(col2_x, wy, col2_x + col2_w, wy + 80, 6, 6, false);
            draw_set_color(make_color_rgb(45, 60, 80));
            draw_roundrect_ext(col2_x, wy, col2_x + col2_w, wy + 80, 6, 6, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(140, 155, 175));
            draw_text(col2_x + col2_w * 0.5, wy + 40, "[No weapons currently mounted to towers]\nForge blueprints on the left to install defenses.");
        }
        
        // -------------------------------------------------------------
        // FOOTER HINT
        // -------------------------------------------------------------
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(130, 150, 175));
        draw_text(mx0 + mw * 0.5, my0 + mh - 20, "Base fortifications and defenses can only be repaired while stationed at the Workstation area.");
    }
    else if (m.type == "victory" || state.phase == "victory") {
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(make_color_rgb(46, 204, 113));
        draw_text(mx0 + mw * 0.5, my0 + 40, "VICTORY! HUMANITY SURVIVED!");
        
        draw_set_color(c_white);
        draw_text(mx0 + mw * 0.5, my0 + 100, "You defended the base through all 17 waves of the alien invasion!\nEarth is reclaiming its future thanks to your teamwork and tactical defenses.");
        
        var btn_w = 400;
        var btn_h = 48;
        var btn_x = mx0 + (mw - btn_w) * 0.5;
        
        state.victory_endless_hover = ui_draw_button(btn_x, my0 + 240, btn_w, btn_h, "Continue to Endless Mode", true, false, mx, my);
        state.victory_restart_hover = ui_draw_button(btn_x, my0 + 305, btn_w, btn_h, "Start New Game", true, true, mx, my);
        state.victory_exit_hover = ui_draw_button(btn_x, my0 + 370, btn_w, btn_h, "Exit to Desktop", true, false, mx, my);
    }
    else if (m.type == "game_over" || state.phase == "game_over") {
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(make_color_rgb(231, 76, 60));
        draw_text(mx0 + mw * 0.5, my0 + 35, "MISSION FAILED // ALL TOWERS DESTROYED");
        
        draw_set_color(make_color_rgb(255, 110, 110));
        draw_text(mx0 + mw * 0.5, my0 + 72, "YOU LOST");
        
        draw_set_color(c_white);
        draw_text(mx0 + mw * 0.5, my0 + 115, "All four defensive towers have been wiped out by the alien swarm.\nThe base defenses were breached and humanity has been overrun.\n\nSurviving Waves Defended: " + string(state.round_number - 1));
        
        var btn_w = 380;
        var btn_h = 48;
        var btn_x = mx0 + (mw - btn_w) * 0.5;
        
        state.gameover_restart_hover = ui_draw_button(btn_x, my0 + 250, btn_w, btn_h, "Play Again (Start New Game)", true, true, mx, my);
        state.gameover_quit_hover = ui_draw_button(btn_x, my0 + 315, btn_w, btn_h, "Close Game (Exit to Desktop)", true, false, mx, my);
    }
    else if (m.type == "player_setup") {
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(c_yellow);
        draw_text(mx0 + mw * 0.5, my0 + 16, "STRIKE TEAM DEPLOYMENT // OPERATIVE SETUP");
        
        draw_set_color(make_color_rgb(180, 200, 220));
        draw_text(mx0 + mw * 0.5, my0 + 38, "Select team size (1-4 players) and pick any role for each operative (duplicates allowed):");
        
        // -------------------------------------------------------------
        // 1. PLAYER COUNT SELECTION BUTTONS
        // -------------------------------------------------------------
        var count_w = 200;
        var count_h = 32;
        var count_x0 = mx0 + (mw - (4 * count_w + 3 * 10)) * 0.5;
        var count_y = my0 + 60;
        
        var count_labels = ["1P Solo (3x Energy)", "2P Duo (1.5x Energy)", "3P Trio (Normal)", "4P Squad (-1 Energy)"];
        for (var c = 0; c < 4; c++) {
            var is_sel = (state.setup_player_count == (c + 1));
            state.setup_count_hover[c] = ui_draw_button(count_x0 + c * (count_w + 10), count_y, count_w, count_h, count_labels[c], true, is_sel, mx, my);
        }
        
        // -------------------------------------------------------------
        // 2. PLAYER ROSTER & INDIVIDUAL ROLE SELECTOR WITH HORIZONTAL SCROLL
        // -------------------------------------------------------------
        var char_classes = game_get_character_classes();
        var num_classes = array_length(char_classes);
        var p_colors = [
            make_color_rgb(229, 57, 53),   // P1 Red
            make_color_rgb(30, 136, 229),  // P2 Blue
            make_color_rgb(253, 216, 53),  // P3 Yellow
            make_color_rgb(67, 160, 71)    // P4 Green
        ];
        
        var row_h = 78;
        var row_spacing = 8;
        var row_y0 = my0 + 102;
        var row_w = mw - 60;
        var row_x = mx0 + 30;
        
        if (!variable_struct_exists(state, "setup_scroll_x") || !is_array(state.setup_scroll_x)) {
            state.setup_scroll_x = [0, 0, 0, 0];
        }
        if (!variable_struct_exists(state, "setup_surf") || !is_array(state.setup_surf)) {
            state.setup_surf = [undefined, undefined, undefined, undefined];
        }
        
        for (var p = 0; p < state.setup_player_count; p++) {
            var ry = row_y0 + p * (row_h + row_spacing);
            
            // Operative card background & color border
            draw_set_color(make_color_rgb(26, 33, 46));
            draw_roundrect_ext(row_x, ry, row_x + row_w, ry + row_h, 8, 8, false);
            draw_set_color(p_colors[p]);
            draw_roundrect_ext(row_x, ry, row_x + row_w, ry + row_h, 8, 8, true);
            
            // Editable Player Name Box
            var name_bx = row_x + 12;
            var name_by = ry + 24;
            var name_bw = 140;
            var name_bh = 32;
            
            var is_editing = (state.editing_player_name_idx == p);
            var name_hov = ui_point_in_rect(mx, my, name_bx, name_by, name_bw, name_bh);
            state.setup_name_hover[p] = name_hov;
            
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            draw_set_color(p_colors[p]);
            draw_text(name_bx, ry + 7, "Operative " + string(p + 1) + ":");
            
            draw_set_color(is_editing ? make_color_rgb(42, 52, 72) : (name_hov ? make_color_rgb(32, 42, 58) : make_color_rgb(18, 24, 34)));
            draw_roundrect_ext(name_bx, name_by, name_bx + name_bw, name_by + name_bh, 6, 6, false);
            draw_set_color(is_editing ? c_yellow : (name_hov ? c_white : make_color_rgb(80, 100, 130)));
            draw_roundrect_ext(name_bx, name_by, name_bx + name_bw, name_by + name_bh, 6, 6, true);
            
            draw_set_valign(fa_middle);
            draw_set_color(is_editing ? c_yellow : c_white);
            var disp_name = state.setup_player_names[p];
            if (is_editing) {
                var cursor_bar = (state.name_cursor_timer % 30 < 15) ? "|" : "";
                draw_text(name_bx + 8, name_by + name_bh * 0.5, disp_name + cursor_bar);
            } else {
                draw_text(name_bx + 8, name_by + name_bh * 0.5, disp_name);
                if (name_hov) {
                    state.hover_tooltip = "Click to rename Operative " + string(p + 1);
                }
            }
            
            var c_idx = state.setup_player_classes[p] % num_classes;
            var cur_class = char_classes[c_idx];
            
            // Interactive Role Cycler: [<] [ Role Name ] [>]
            var btn_cy = ry + 24;
            state.setup_prev_hover[p] = ui_draw_button(row_x + 160, btn_cy, 34, 32, "<", true, false, mx, my);
            ui_draw_button(row_x + 198, btn_cy, 155, 32, cur_class.name, true, true, mx, my);
            state.setup_next_hover[p] = ui_draw_button(row_x + 357, btn_cy, 34, 32, ">", true, false, mx, my);
            
            // ---------------------------------------------------------
            // Bounded Role Description Section with Horizontal Scrolling
            // ---------------------------------------------------------
            var info_x = row_x + 398;
            var info_y = ry + 8;
            var info_w = (row_x + row_w - 10) - info_x;
            var info_h = row_h - 16;
            
            // Background box for the info section
            draw_set_color(make_color_rgb(18, 23, 33));
            draw_roundrect_ext(info_x, info_y, info_x + info_w, info_y + info_h, 6, 6, false);
            draw_set_color(make_color_rgb(52, 70, 95));
            draw_roundrect_ext(info_x, info_y, info_x + info_w, info_y + info_h, 6, 6, true);
            
            var p_scaled_e = game_calculate_player_max_energy(cur_class, state.setup_player_count, 0);
            var title_str = cur_class.role + " (" + string(p_scaled_e) + " Energy)  [" + cur_class.perk_tag + "]";
            var desc_str = cur_class.desc;
            var text_max_w = max(string_width(title_str), string_width(desc_str)) + 16;
            var can_scroll = (text_max_w > (info_w - 8));
            var view_w = can_scroll ? (info_w - 56) : (info_w - 8);
            var max_scroll = max(0, text_max_w - view_w);
            
            state.setup_scroll_x[p] = clamp(state.setup_scroll_x[p], 0, max_scroll);
            
            // Mouse wheel scroll when hovered over this operative's info section
            var in_info_box = ui_point_in_rect(mx, my, info_x, info_y, info_w, info_h);
            if (in_info_box && max_scroll > 0) {
                if (mouse_wheel_down()) state.setup_scroll_x[p] = min(max_scroll, state.setup_scroll_x[p] + 40);
                if (mouse_wheel_up()) state.setup_scroll_x[p] = max(0, state.setup_scroll_x[p] - 40);
            }
            
            // Scroll buttons [<] and [>] on the right of the section
            if (can_scroll) {
                var can_sc_left = (state.setup_scroll_x[p] > 0);
                var can_sc_right = (state.setup_scroll_x[p] < max_scroll);
                state.setup_scroll_left_hover[p] = ui_draw_button(info_x + info_w - 50, info_y + 18, 22, 24, "<", can_sc_left, false, mx, my);
                state.setup_scroll_right_hover[p] = ui_draw_button(info_x + info_w - 25, info_y + 18, 22, 24, ">", can_sc_right, false, mx, my);
            } else {
                state.setup_scroll_left_hover[p] = false;
                state.setup_scroll_right_hover[p] = false;
            }
            
            // Surface-clipped text rendering (guarantees text NEVER bleeds outside the section)
            var surf_w = max(1, view_w);
            var surf_h = max(1, info_h - 6);
            
            if (!is_undefined(state.setup_surf[p]) && surface_exists(state.setup_surf[p])) {
                if (surface_get_width(state.setup_surf[p]) != surf_w || surface_get_height(state.setup_surf[p]) != surf_h) {
                    surface_free(state.setup_surf[p]);
                    state.setup_surf[p] = surface_create(surf_w, surf_h);
                }
            } else {
                state.setup_surf[p] = surface_create(surf_w, surf_h);
            }
            
            surface_set_target(state.setup_surf[p]);
            draw_clear_alpha(c_black, 0);
            
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            var sx = 6 - state.setup_scroll_x[p];
            
            // Role Title & Tag
            draw_set_color(c_yellow);
            draw_text(sx, 4, title_str);
            
            // Role Description
            draw_set_color(make_color_rgb(190, 215, 245));
            draw_text(sx, 26, desc_str);
            
            surface_reset_target();
            draw_surface(state.setup_surf[p], info_x + 4, info_y + 3);
        }
        
        // -------------------------------------------------------------
        // 3. START MISSION / DEPLOY BUTTON
        // -------------------------------------------------------------
        var start_btn_w = 460;
        var start_btn_h = 44;
        var start_btn_x = mx0 + (mw - start_btn_w) * 0.5;
        var start_btn_y = my0 + mh - 54;
        state.setup_start_hover = ui_draw_button(start_btn_x, start_btn_y, start_btn_w, start_btn_h, "DEPLOY STRIKE TEAM (START MISSION)", true, true, mx, my);
    }
    else if (m.type == "settings") {
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(c_yellow);
        draw_text(mx0 + mw * 0.5, my0 + 25, "SYSTEM & DISPLAY SETTINGS");
        
        // -------------------------------------------------------------
        // 1. DISPLAY MODE PICKER (Borderless vs Fullscreen vs Windowed)
        // -------------------------------------------------------------
        draw_set_halign(fa_left);
        draw_set_color(c_white);
        draw_text(mx0 + 40, my0 + 70, "DISPLAY MODE:");
        
        var cur_mode = state.settings.display_mode;
        var btn_w = 235;
        var btn_h = 38;
        var b_y = my0 + 100;
        
        var is_borderless = (cur_mode == "borderless");
        var is_fullscreen = (cur_mode == "fullscreen");
        var is_windowed = (cur_mode == "windowed");
        
        state.settings_mode_borderless_hover = ui_draw_button(mx0 + 40, b_y, btn_w, btn_h, "Borderless (Default)", true, is_borderless, mx, my);
        state.settings_mode_fullscreen_hover = ui_draw_button(mx0 + 295, b_y, btn_w, btn_h, "Exclusive Fullscreen", true, is_fullscreen, mx, my);
        state.settings_mode_windowed_hover = ui_draw_button(mx0 + 550, b_y, btn_w, btn_h, "Windowed Mode", true, is_windowed, mx, my);
        
        // -------------------------------------------------------------
        // 2. RESOLUTION PICKER
        // -------------------------------------------------------------
        draw_set_color(c_white);
        draw_text(mx0 + 40, my0 + 165, "RESOLUTION (Windowed & Target Scale):");
        
        var res_y = my0 + 195;
        var res_w = 175;
        var res_h = 36;
        state.settings_res_hover = -1;
        
        for (var r = 0; r < array_length(state.resolutions); r++) {
            var rx = mx0 + 40 + r * (res_w + 18);
            var is_active_res = (state.settings.resolution_idx == r);
            var r_label = state.resolutions[r][2];
            var r_hov = ui_draw_button(rx, res_y, res_w, res_h, r_label, true, is_active_res, mx, my);
            if (r_hov) {
                state.settings_res_hover = r;
            }
        }
        
        // -------------------------------------------------------------
        // 3. SOUND EFFECT VOLUME SLIDER
        // -------------------------------------------------------------
        draw_set_color(c_white);
        draw_text(mx0 + 40, my0 + 265, "SOUND EFFECT VOLUME:");
        
        var vol_pct = round(state.settings.sfx_volume * 100);
        draw_set_halign(fa_right);
        draw_set_color(c_yellow);
        draw_text(mx0 + mw - 200, my0 + 265, string(vol_pct) + "%");
        draw_set_halign(fa_left);
        
        // Track
        var track_x = mx0 + 40;
        var track_y = my0 + 295;
        var track_w = mw - 250;
        var track_h = 18;
        
        // Background track bar
        draw_set_color(make_color_rgb(33, 43, 54));
        draw_roundrect_ext(track_x, track_y, track_x + track_w, track_y + track_h, 8, 8, false);
        draw_set_color(make_color_rgb(74, 85, 104));
        draw_roundrect_ext(track_x, track_y, track_x + track_w, track_y + track_h, 8, 8, true);
        
        // Fill bar
        var fill_w = track_w * clamp(state.settings.sfx_volume, 0.0, 1.0);
        if (fill_w > 0) {
            draw_set_color(make_color_rgb(46, 204, 113));
            draw_roundrect_ext(track_x, track_y, track_x + fill_w, track_y + track_h, 8, 8, false);
        }
        
        // Slider Thumb handle
        var thumb_x = track_x + fill_w;
        var thumb_y = track_y + track_h * 0.5;
        var thumb_rad = 12;
        var thumb_hover = point_in_circle(mx, my, thumb_x, thumb_y, thumb_rad + 4);
        
        draw_set_color(c_black);
        draw_circle(thumb_x, thumb_y, thumb_rad + 2, false);
        draw_set_color(thumb_hover ? c_yellow : c_white);
        draw_circle(thumb_x, thumb_y, thumb_rad, false);
        draw_set_color(c_black);
        draw_circle(thumb_x, thumb_y, thumb_rad, true);
        
        // Test SFX Button
        state.settings_test_sfx_hover = ui_draw_button(track_x + track_w + 30, track_y - 8, 140, 34, "Play Test SFX", true, false, mx, my);
        
        // -------------------------------------------------------------
        // 4. CURRENT STATUS & DONE BUTTON
        // -------------------------------------------------------------
        draw_set_color(make_color_rgb(160, 185, 210));
        var active_res_str = string(state.resolutions[state.settings.resolution_idx][0]) + " x " + string(state.resolutions[state.settings.resolution_idx][1]);
        draw_text(mx0 + 40, my0 + 360, "Active Display: " + string_upper(cur_mode) + "  |  Resolution: " + active_res_str + "  |  SFX: " + string(vol_pct) + "%");
        
        // Buttons: Restart Game & Apply / Close
        state.settings_restart_hover = ui_draw_button(mx0 + 40, my0 + 420, 340, 44, "Restart Game (New Mission)", true, false, mx, my);
        state.settings_close_hover = ui_draw_button(mx0 + mw - 380, my0 + 420, 340, 44, "Apply & Close", true, true, mx, my);
    }
}

// =============================================================================
// SCREEN RENDERING FUNCTIONS: TITLE, LOCAL SETUP, ONLINE MULTIPLAYER
// =============================================================================

/// @desc Draws animated background starfield and subtle deep space nebula
function ui_draw_screen_starfield(state) {
    // Deep space gradient
    draw_set_color(make_color_rgb(10, 14, 22));
    draw_rectangle(0, 0, 1920, 1080, false);
    
    // Ambient cosmic nebula glows
    draw_set_alpha(0.08);
    draw_set_color(make_color_rgb(41, 128, 185));
    draw_circle(450, 320, 380, false);
    draw_set_color(make_color_rgb(142, 68, 173));
    draw_circle(1480, 720, 440, false);
    draw_set_color(make_color_rgb(22, 160, 133));
    draw_circle(960, 540, 300, false);
    draw_set_alpha(1.0);
    
    // Subtle sci-fi background grid
    draw_set_alpha(0.04);
    draw_set_color(make_color_rgb(100, 181, 246));
    for (var gx = 0; gx <= 1920; gx += 80) {
        draw_line(gx, 0, gx, 1080);
    }
    for (var gy = 0; gy <= 1080; gy += 80) {
        draw_line(0, gy, 1920, gy);
    }
    draw_set_alpha(1.0);
    
    // Moving starfield
    if (variable_struct_exists(state, "title_stars") && is_array(state.title_stars)) {
        for (var s = 0; s < array_length(state.title_stars); s++) {
            var st = state.title_stars[s];
            st.x -= st.spd;
            if (st.x < 0) {
                st.x = 1920;
                st.y = random(1080);
            }
            st.twinkle += 0.05;
            var cur_alpha = st.alpha * (0.6 + 0.4 * sin(st.twinkle));
            draw_set_alpha(cur_alpha);
            draw_set_color(c_white);
            if (st.size > 1.8) {
                draw_circle(st.x, st.y, st.size * 0.5, false);
            } else {
                draw_point(st.x, st.y);
            }
        }
        draw_set_alpha(1.0);
    }
}

/// @desc Draws distinct sci-fi vector emblem for character classes
function ui_draw_class_emblem(ex, ey, class_id, p_color, is_large = false) {
    var scale = is_large ? 1.4 : 1.0;
    
    // Circular background plate
    var bg_rad = 34 * scale;
    draw_set_color(make_color_rgb(18, 24, 34));
    draw_circle(ex, ey, bg_rad, false);
    draw_set_color(p_color);
    draw_circle(ex, ey, bg_rad, true);
    draw_circle(ex, ey, bg_rad - 3, true);
    
    draw_set_color(p_color);
    switch (class_id) {
        case "scout": {
            // Winged swift chevrons
            var s = 14 * scale;
            draw_triangle(ex, ey - s * 1.3, ex - s * 1.2, ey + s * 0.5, ex, ey, false);
            draw_triangle(ex, ey - s * 1.3, ex + s * 1.2, ey + s * 0.5, ex, ey, false);
            draw_triangle(ex, ey - s * 0.3, ex - s * 1.0, ey + s * 1.2, ex, ey + s * 0.6, false);
            draw_triangle(ex, ey - s * 0.3, ex + s * 1.0, ey + s * 1.2, ex, ey + s * 0.6, false);
            break;
        }
        case "engineer": {
            // Fortified shield + inner wrench/gear
            var s = 15 * scale;
            draw_rectangle(ex - s * 0.7, ey - s, ex + s * 0.7, ey + s * 0.4, false);
            draw_triangle(ex - s * 0.7, ey + s * 0.4, ex + s * 0.7, ey + s * 0.4, ex, ey + s * 1.3, false);
            draw_set_color(c_white);
            draw_circle(ex, ey - s * 0.2, 5 * scale, true);
            draw_line_width(ex - s * 0.5, ey + s * 0.3, ex + s * 0.5, ey - s * 0.7, 3);
            break;
        }
        case "miner": {
            // Crossed pickaxe and mineral core
            var s = 16 * scale;
            draw_line_width(ex - s * 0.8, ey + s * 0.8, ex + s * 0.8, ey - s * 0.8, 3 * scale);
            draw_triangle(ex + s * 0.4, ey - s * 1.1, ex + s * 1.1, ey - s * 0.4, ex + s * 0.6, ey - s * 0.6, false);
            draw_set_color(make_color_rgb(255, 215, 0));
            draw_triangle(ex, ey - 6 * scale, ex - 6 * scale, ey, ex, ey + 6 * scale, false);
            draw_triangle(ex, ey - 6 * scale, ex + 6 * scale, ey, ex, ey + 6 * scale, false);
            break;
        }
        case "gunner": {
            // Heavy dual artillery barrels & crosshair
            var s = 16 * scale;
            draw_rectangle(ex - s * 0.6, ey - s * 1.1, ex - s * 0.2, ey + s * 0.6, false);
            draw_rectangle(ex + s * 0.2, ey - s * 1.1, ex + s * 0.6, ey + s * 0.6, false);
            draw_rectangle(ex - s * 0.8, ey + s * 0.3, ex + s * 0.8, ey + s * 0.9, false);
            draw_set_color(c_white);
            draw_circle(ex, ey - s * 0.2, 7 * scale, true);
            draw_line(ex - 10 * scale, ey - s * 0.2, ex + 10 * scale, ey - s * 0.2);
            draw_line(ex, ey - s * 0.2 - 10 * scale, ex, ey - s * 0.2 + 10 * scale);
            break;
        }
        case "pathfinder": {
            // 8-point compass star
            var s = 17 * scale;
            draw_triangle(ex, ey - s * 1.2, ex - s * 0.3, ey, ex + s * 0.3, ey, false);
            draw_triangle(ex, ey + s * 1.2, ex - s * 0.3, ey, ex + s * 0.3, ey, false);
            draw_triangle(ex - s * 1.2, ey, ex, ey - s * 0.3, ex, ey + s * 0.3, false);
            draw_triangle(ex + s * 1.2, ey, ex, ey - s * 0.3, ex, ey + s * 0.3, false);
            draw_set_color(c_white);
            draw_circle(ex, ey, 4 * scale, false);
            break;
        }
        default: {
            // Survivor: Balanced tactical crest & reticle
            var s = 16 * scale;
            draw_circle(ex, ey, s * 0.8, true);
            draw_line(ex - s, ey, ex + s, ey);
            draw_line(ex, ey - s, ex, ey + s);
            draw_set_color(c_white);
            draw_circle(ex, ey, 3 * scale, false);
            break;
        }
    }
}

/// @desc Draws stylized Title Screen for "Alien game"
function ui_draw_title_screen(state, mx, my) {
    ui_draw_screen_starfield(state);
    
    // Main Title Branding Box
    var title_cx = 960;
    var title_cy = 230;
    
    // Glowing cyan laser header line
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_line_width(title_cx - 420, title_cy - 75, title_cx + 420, title_cy - 75, 2);
    draw_circle(title_cx - 420, title_cy - 75, 4, false);
    draw_circle(title_cx + 420, title_cy - 75, 4, false);
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    
    // Top Sub-header
    draw_set_color(make_color_rgb(100, 181, 246));
    draw_text(title_cx, title_cy - 50, "// PLANETARY OUTPOST PROTOCOL // TACTICAL CO-OP DEFENSE //");
    
    // Massive Stylized Title: "Alien game"
    var title_text = "Alien game";
    
    // Drop shadow
    draw_set_color(make_color_rgb(10, 20, 35));
    draw_text_transformed(title_cx + 4, title_cy + 18, title_text, 3.8, 3.8, 0);
    draw_text_transformed(title_cx + 2, title_cy + 16, title_text, 3.8, 3.8, 0);
    
    // Outer Cyan Glow
    draw_set_color(make_color_rgb(0, 180, 216));
    draw_text_transformed(title_cx - 1, title_cy + 14, title_text, 3.8, 3.8, 0);
    draw_text_transformed(title_cx + 1, title_cy + 14, title_text, 3.8, 3.8, 0);
    
    // Crisp Core Title Text
    draw_set_color(c_white);
    draw_text_transformed(title_cx, title_cy + 14, title_text, 3.8, 3.8, 0);
    
    // Edition Tag
    draw_set_color(make_color_rgb(255, 215, 0));
    draw_text(title_cx, title_cy + 75, "-- LOCAL WI-FI MULTIPLAYER & SQUAD DEFENSE --");
    
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_line_width(title_cx - 420, title_cy + 95, title_cx + 420, title_cy + 95, 2);
    draw_circle(title_cx - 420, title_cy + 95, 4, false);
    draw_circle(title_cx + 420, title_cy + 95, 4, false);
    
    // Menu Container Box
    var box_w = 540;
    var box_h = 440;
    var box_x = title_cx - box_w * 0.5;
    var box_y = 420;
    
    draw_set_color(make_color_rgb(18, 24, 36));
    draw_roundrect_ext(box_x, box_y, box_x + box_w, box_y + box_h, 14, 14, false);
    draw_set_color(make_color_rgb(45, 60, 85));
    draw_roundrect_ext(box_x, box_y, box_x + box_w, box_y + box_h, 14, 14, true);
    
    // Corner brackets
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_line_width(box_x, box_y + 24, box_x, box_y, 3);
    draw_line_width(box_x, box_y, box_x + 24, box_y, 3);
    draw_line_width(box_x + box_w, box_y + 24, box_x + box_w, box_y, 3);
    draw_line_width(box_x + box_w - 24, box_y, box_x + box_w, box_y, 3);
    draw_line_width(box_x, box_y + box_h - 24, box_x, box_y + box_h, 3);
    draw_line_width(box_x, box_y + box_h, box_x + 24, box_y + box_h, 3);
    draw_line_width(box_x + box_w, box_y + box_h - 24, box_x + box_w, box_y + box_h, 3);
    draw_line_width(box_x + box_w - 24, box_y + box_h, box_x + box_w, box_y + box_h, 3);
    
    // Menu Buttons
    var btn_w = 460;
    var btn_h = 68;
    var btn_x = title_cx - btn_w * 0.5;
    var btn_spacing = 18;
    var start_btn_y = box_y + 42;
    
    // 1. Local Play Button
    var by1 = start_btn_y;
    var hov1 = ui_point_in_rect(mx, my, btn_x, by1, btn_w, btn_h);
    state.title_btn_local_hover = hov1;
    draw_set_color(hov1 ? make_color_rgb(38, 55, 82) : make_color_rgb(26, 36, 52));
    draw_roundrect_ext(btn_x, by1, btn_x + btn_w, by1 + btn_h, 8, 8, false);
    draw_set_color(hov1 ? c_yellow : make_color_rgb(64, 90, 125));
    draw_roundrect_ext(btn_x, by1, btn_x + btn_w, by1 + btn_h, 8, 8, true);
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(hov1 ? c_yellow : c_white);
    draw_text_transformed(title_cx, by1 + 22, "LOCAL PLAY", 1.25, 1.25, 0);
    draw_set_color(hov1 ? make_color_rgb(220, 220, 220) : make_color_rgb(140, 160, 180));
    draw_text(title_cx, by1 + 48, "1 - 4 Local Operatives on this Machine");
    
    // 2. Online Wi-Fi Multiplayer Button
    var by2 = by1 + btn_h + btn_spacing;
    var hov2 = ui_point_in_rect(mx, my, btn_x, by2, btn_w, btn_h);
    state.title_btn_online_hover = hov2;
    draw_set_color(hov2 ? make_color_rgb(22, 60, 75) : make_color_rgb(20, 42, 56));
    draw_roundrect_ext(btn_x, by2, btn_x + btn_w, by2 + btn_h, 8, 8, false);
    draw_set_color(hov2 ? make_color_rgb(0, 229, 255) : make_color_rgb(38, 110, 140));
    draw_roundrect_ext(btn_x, by2, btn_x + btn_w, by2 + btn_h, 8, 8, true);
    
    draw_set_color(hov2 ? make_color_rgb(0, 229, 255) : c_white);
    draw_text_transformed(title_cx, by2 + 22, "ONLINE (LOCAL WI-FI)", 1.25, 1.25, 0);
    draw_set_color(hov2 ? make_color_rgb(200, 245, 255) : make_color_rgb(120, 175, 195));
    draw_text(title_cx, by2 + 48, "Create or Join Public Rooms with Players on Same Wi-Fi");
    
    // 3. Settings Button
    var by3 = by2 + btn_h + btn_spacing;
    var hov3 = ui_point_in_rect(mx, my, btn_x, by3, btn_w, btn_h);
    state.title_btn_settings_hover = hov3;
    draw_set_color(hov3 ? make_color_rgb(44, 52, 68) : make_color_rgb(28, 34, 46));
    draw_roundrect_ext(btn_x, by3, btn_x + btn_w, by3 + btn_h, 8, 8, false);
    draw_set_color(hov3 ? c_white : make_color_rgb(70, 85, 110));
    draw_roundrect_ext(btn_x, by3, btn_x + btn_w, by3 + btn_h, 8, 8, true);
    
    draw_set_color(hov3 ? c_yellow : c_white);
    draw_text_transformed(title_cx, by3 + 22, "SETTINGS", 1.2, 1.2, 0);
    draw_set_color(make_color_rgb(140, 155, 175));
    draw_text(title_cx, by3 + 48, "Display Mode, Resolution & SFX Volume");
    
    // 4. Exit to Desktop Button
    var by4 = by3 + btn_h + btn_spacing;
    var hov4 = ui_point_in_rect(mx, my, btn_x, by4, btn_w, btn_h);
    state.title_btn_quit_hover = hov4;
    draw_set_color(hov4 ? make_color_rgb(60, 30, 30) : make_color_rgb(38, 24, 28));
    draw_roundrect_ext(btn_x, by4, btn_x + btn_w, by4 + btn_h, 8, 8, false);
    draw_set_color(hov4 ? make_color_rgb(255, 82, 82) : make_color_rgb(110, 50, 55));
    draw_roundrect_ext(btn_x, by4, btn_x + btn_w, by4 + btn_h, 8, 8, true);
    
    draw_set_color(hov4 ? make_color_rgb(255, 100, 100) : make_color_rgb(220, 180, 180));
    draw_text_transformed(title_cx, by4 + 22, "EXIT TO DESKTOP", 1.15, 1.15, 0);
    draw_set_color(make_color_rgb(150, 120, 120));
    draw_text(title_cx, by4 + 48, "Quit Application");
    
    // Footer Information
    draw_set_color(make_color_rgb(90, 110, 140));
    draw_text(title_cx, 1020, "Local Wi-Fi Subnet Broadcast (Ports 6510/6511)  |  Press F11 for Fullscreen");
}

/// @desc Draws dedicated, significantly improved Local Setup Screen (1-4 players & character roles)
function ui_draw_local_setup_screen(state, mx, my) {
    ui_draw_screen_starfield(state);
    
    var con_x = 70;
    var con_y = 35;
    var con_w = 1780;
    var con_h = 1010;
    
    // Main Console Housing
    draw_set_color(make_color_rgb(16, 22, 32));
    draw_roundrect_ext(con_x, con_y, con_x + con_w, con_y + con_h, 14, 14, false);
    draw_set_color(make_color_rgb(44, 60, 84));
    draw_roundrect_ext(con_x, con_y, con_x + con_w, con_y + con_h, 14, 14, true);
    
    // High-tech corner brackets
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_line_width(con_x, con_y + 30, con_x, con_y, 3);
    draw_line_width(con_x, con_y, con_x + 30, con_y, 3);
    draw_line_width(con_x + con_w, con_y + 30, con_x + con_w, con_y, 3);
    draw_line_width(con_x + con_w - 30, con_y, con_x + con_w, con_y, 3);
    draw_line_width(con_x, con_y + con_h - 30, con_x, con_y + con_h, 3);
    draw_line_width(con_x, con_y + con_h, con_x + 30, con_y + con_h, 3);
    draw_line_width(con_x + con_w, con_y + con_h - 30, con_x + con_w, con_y + con_h, 3);
    draw_line_width(con_x + con_w - 30, con_y + con_h, con_x + con_w, con_y + con_h, 3);
    
    // Header Bar
    draw_set_color(make_color_rgb(24, 32, 48));
    draw_roundrect_ext(con_x + 10, con_y + 10, con_x + con_w - 10, con_y + 70, 8, 8, false);
    draw_set_color(make_color_rgb(52, 73, 94));
    draw_roundrect_ext(con_x + 10, con_y + 10, con_x + con_w - 10, con_y + 70, 8, 8, true);
    
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(c_yellow);
    draw_text_transformed(con_x + 30, con_y + 32, "TACTICAL SQUAD BRIEFING // ROSTER ALLOCATION", 1.35, 1.35, 0);
    draw_set_color(make_color_rgb(140, 180, 215));
    draw_text(con_x + 30, con_y + 54, "Select operative count and assign specialized tactical classes. Team size dynamically scales starting operative energy.");
    
    // -----------------------------------------------------------------
    // SECTION 1: SQUAD SIZE SELECTOR CARDS (Top Row)
    // -----------------------------------------------------------------
    var count_y = con_y + 85;
    var count_h = 75;
    var count_spacing = 16;
    var count_w = (con_w - 60 - count_spacing * 3) / 4;
    
    var size_info = [
        ["1 SOLO SURVIVOR", "3x Base Energy (15+ Energy)", "Pure solo endurance"],
        ["2 DUO SQUAD", "1.5x Base Energy (7+ Energy)", "Coordinated tactical pair"],
        ["3 TRIO FIRETEAM", "Standard Base Energy (5+ Energy)", "Balanced squad distribution"],
        ["4 BATTALION", "-1 Energy Modifier (4+ Energy)", "Full 4-corner defense coverage"]
    ];
    
    for (var c = 0; c < 4; c++) {
        var cx = con_x + 30 + c * (count_w + count_spacing);
        var is_sel = (state.setup_player_count == (c + 1));
        var chov = ui_point_in_rect(mx, my, cx, count_y, count_w, count_h);
        state.local_setup_count_hover[c] = chov;
        
        var card_bg = is_sel ? make_color_rgb(32, 60, 88) : (chov ? make_color_rgb(28, 40, 58) : make_color_rgb(20, 26, 38));
        var card_bd = is_sel ? c_yellow : (chov ? c_white : make_color_rgb(60, 80, 110));
        
        draw_set_color(card_bg);
        draw_roundrect_ext(cx, count_y, cx + count_w, count_y + count_h, 8, 8, false);
        draw_set_color(card_bd);
        draw_roundrect_ext(cx, count_y, cx + count_w, count_y + count_h, 8, 8, true);
        if (is_sel) {
            draw_roundrect_ext(cx + 1, count_y + 1, cx + count_w - 1, count_y + count_h - 1, 8, 8, true);
        }
        
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(is_sel ? c_yellow : (chov ? c_white : make_color_rgb(180, 205, 230)));
        draw_text_transformed(cx + 16, count_y + 10, size_info[c][0], 1.1, 1.1, 0);
        
        draw_set_color(is_sel ? make_color_rgb(255, 235, 59) : make_color_rgb(120, 180, 160));
        draw_text(cx + 16, count_y + 32, size_info[c][1]);
        
        draw_set_color(make_color_rgb(130, 145, 165));
        draw_text(cx + 16, count_y + 50, size_info[c][2]);
        
        // Active radio check indicator on right
        var rad_x = cx + count_w - 24;
        var rad_y = count_y + 22;
        draw_set_color(is_sel ? c_yellow : make_color_rgb(60, 75, 100));
        draw_circle(rad_x, rad_y, 9, is_sel ? false : true);
        if (is_sel) {
            draw_set_color(c_black);
            draw_circle(rad_x, rad_y, 4, false);
        }
    }
    
    // -----------------------------------------------------------------
    // SECTION 2: OPERATIVE DOSSIER CARDS (Middle Row)
    // -----------------------------------------------------------------
    var p_colors = [
        make_color_rgb(229, 57, 53),   // P1 Red
        make_color_rgb(30, 136, 229),  // P2 Blue
        make_color_rgb(253, 216, 53),  // P3 Yellow
        make_color_rgb(67, 160, 71)    // P4 Green
    ];
    
    var char_classes = game_get_character_classes();
    var num_classes = array_length(char_classes);
    var p_count = state.setup_player_count;
    
    var dossier_y = count_y + count_h + 16;
    var dossier_h = 710;
    var d_spacing = 18;
    var total_w = con_w - 60;
    var card_w = (total_w - d_spacing * (p_count - 1)) / p_count;
    
    for (var p = 0; p < p_count; p++) {
        var card_x = con_x + 30 + p * (card_w + d_spacing);
        var c_idx = state.setup_player_classes[p] % num_classes;
        var p_class = char_classes[c_idx];
        var p_col = p_colors[p];
        var calc_energy = game_calculate_player_max_energy(p_class, p_count, 0);
        
        // Card Body Housing
        draw_set_color(make_color_rgb(20, 26, 38));
        draw_roundrect_ext(card_x, dossier_y, card_x + card_w, dossier_y + dossier_h, 10, 10, false);
        draw_set_color(p_col);
        draw_roundrect_ext(card_x, dossier_y, card_x + card_w, dossier_y + dossier_h, 10, 10, true);
        draw_roundrect_ext(card_x + 1, dossier_y + 1, card_x + card_w - 1, dossier_y + dossier_h - 1, 10, 10, true);
        
        // 1. Operative Header Strip
        draw_set_color(p_col);
        draw_roundrect_ext(card_x + 4, dossier_y + 4, card_x + card_w - 4, dossier_y + 42, 6, 6, false);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(c_black);
        draw_text_transformed(card_x + 16, dossier_y + 23, "OPERATIVE 0" + string(p + 1), 1.15, 1.15, 0);
        
        draw_set_halign(fa_right);
        draw_text(card_x + card_w - 16, dossier_y + 23, "TEAM SLOT " + string(p + 1));
        
        // 2. Callsign / Name Plate
        var name_bx = card_x + 16;
        var name_by = dossier_y + 54;
        var name_bw = card_w - 32;
        var name_bh = 46;
        
        var is_editing = (state.editing_player_name_idx == p);
        var name_hov = ui_point_in_rect(mx, my, name_bx, name_by, name_bw, name_bh);
        state.local_setup_name_hover[p] = name_hov;
        
        draw_set_color(is_editing ? make_color_rgb(38, 52, 74) : (name_hov ? make_color_rgb(30, 42, 60) : make_color_rgb(14, 18, 28)));
        draw_roundrect_ext(name_bx, name_by, name_bx + name_bw, name_by + name_bh, 6, 6, false);
        draw_set_color(is_editing ? c_yellow : (name_hov ? c_white : make_color_rgb(70, 95, 130)));
        draw_roundrect_ext(name_bx, name_by, name_bx + name_bw, name_by + name_bh, 6, 6, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(130, 160, 195));
        draw_text(name_bx + 12, name_by + 14, "CALLSIGN:");
        
        var disp_name = state.setup_player_names[p];
        if (is_editing && ((state.name_cursor_timer div 25) % 2 == 0)) {
            disp_name += "|";
        }
        draw_set_color(is_editing ? c_yellow : c_white);
        draw_text_transformed(name_bx + 90, name_by + 26, disp_name, 1.2, 1.2, 0);
        
        draw_set_halign(fa_right);
        draw_set_color(make_color_rgb(90, 115, 145));
        draw_text(name_bx + name_bw - 10, name_by + 24, is_editing ? "[Typing...]" : "[Edit]");
        
        // 3. Class Navigation Bar (< Class Name >)
        var cycler_y = name_by + name_bh + 14;
        var cycler_h = 52;
        var arrow_w = 46;
        
        var prev_x = card_x + 16;
        var next_x = card_x + card_w - 16 - arrow_w;
        var cname_x = prev_x + arrow_w + 8;
        var cname_w = next_x - cname_x - 8;
        
        var prev_hov = ui_draw_button(prev_x, cycler_y, arrow_w, cycler_h, "<", true, false, mx, my);
        var next_hov = ui_draw_button(next_x, cycler_y, arrow_w, cycler_h, ">", true, false, mx, my);
        state.local_setup_prev_hover[p] = prev_hov;
        state.local_setup_next_hover[p] = next_hov;
        
        draw_set_color(make_color_rgb(26, 36, 52));
        draw_roundrect_ext(cname_x, cycler_y, cname_x + cname_w, cycler_y + cycler_h, 6, 6, false);
        draw_set_color(make_color_rgb(52, 73, 94));
        draw_roundrect_ext(cname_x, cycler_y, cname_x + cname_w, cycler_y + cycler_h, 6, 6, true);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(c_yellow);
        draw_text_transformed(cname_x + cname_w * 0.5, cycler_y + 18, p_class.name, 1.2, 1.2, 0);
        draw_set_color(make_color_rgb(100, 181, 246));
        draw_text(cname_x + cname_w * 0.5, cycler_y + 38, "// " + p_class.role + " //");
        
        // 4. Class Emblem & Holographic Avatar Plate
        var avatar_y = cycler_y + cycler_h + 14;
        var avatar_h = 135;
        draw_set_color(make_color_rgb(14, 18, 28));
        draw_roundrect_ext(card_x + 16, avatar_y, card_x + card_w - 16, avatar_y + avatar_h, 8, 8, false);
        draw_set_color(make_color_rgb(40, 56, 80));
        draw_roundrect_ext(card_x + 16, avatar_y, card_x + card_w - 16, avatar_y + avatar_h, 8, 8, true);
        
        // Draw Class Emblem Vector
        var emblem_cx = card_x + card_w * 0.5;
        var emblem_cy = avatar_y + avatar_h * 0.5;
        ui_draw_class_emblem(emblem_cx, emblem_cy, p_class.id, p_col, true);
        
        // 5. Tactical Specification Dossier Box
        var spec_y = avatar_y + avatar_h + 14;
        var spec_h = 230;
        var spec_w = card_w - 32;
        var spec_x = card_x + 16;
        
        draw_set_color(make_color_rgb(16, 22, 34));
        draw_roundrect_ext(spec_x, spec_y, spec_x + spec_w, spec_y + spec_h, 8, 8, false);
        draw_set_color(make_color_rgb(45, 62, 88));
        draw_roundrect_ext(spec_x, spec_y, spec_x + spec_w, spec_y + spec_h, 8, 8, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(make_color_rgb(0, 229, 255));
        draw_text(spec_x + 14, spec_y + 12, "[FIELD SPECIFICATIONS]");
        
        // Perk Tag Badge
        draw_set_color(make_color_rgb(32, 45, 65));
        draw_roundrect_ext(spec_x + 14, spec_y + 36, spec_x + spec_w - 14, spec_y + 64, 4, 4, false);
        draw_set_color(make_color_rgb(64, 90, 130));
        draw_roundrect_ext(spec_x + 14, spec_y + 36, spec_x + spec_w - 14, spec_y + 64, 4, 4, true);
        
        draw_set_valign(fa_middle);
        draw_set_color(c_yellow);
        draw_text(spec_x + 22, spec_y + 50, p_class.perk_tag);
        
        // Descriptive perks text
        draw_set_valign(fa_top);
        draw_set_color(c_white);
        draw_text_ext(spec_x + 14, spec_y + 74, p_class.desc, 20, spec_w - 28);
        
        // Base Energy & Move Cost stat line
        var move_cost_str = (p_class.id == "scout" || p_class.id == "pathfinder") ? "1 Energy (Agile)" : "2 Energy (Standard)";
        draw_set_color(make_color_rgb(140, 185, 220));
        draw_text(spec_x + 14, spec_y + 172, "Tactical Movement Cost: " + move_cost_str);
        
        var b_e = p_class.bonus_energy;
        var b_str = (b_e > 0) ? ("+" + string(b_e)) : string(b_e);
        draw_text(spec_x + 14, spec_y + 196, "Class Base Energy Modifier: " + b_str);
        
        // 6. Max Energy Plate (Bottom of Dossier Card)
        var eplate_y = dossier_y + dossier_h - 70;
        var eplate_h = 56;
        var eplate_x = card_x + 16;
        var eplate_w = card_w - 32;
        
        draw_set_color(make_color_rgb(26, 38, 56));
        draw_roundrect_ext(eplate_x, eplate_y, eplate_x + eplate_w, eplate_y + eplate_h, 8, 8, false);
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_roundrect_ext(eplate_x, eplate_y, eplate_x + eplate_w, eplate_y + eplate_h, 8, 8, true);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text_transformed(eplate_x + 16, eplate_y + eplate_h * 0.5, "STARTING ENERGY:", 1.1, 1.1, 0);
        
        draw_set_halign(fa_right);
        draw_set_color(c_yellow);
        draw_text_transformed(eplate_x + eplate_w - 44, eplate_y + eplate_h * 0.5, string(calc_energy), 1.4, 1.4, 0);
        ui_draw_lightning(eplate_x + eplate_w - 20, eplate_y + eplate_h * 0.5, 20, true);
    }
    
    // -----------------------------------------------------------------
    // SECTION 3: BOTTOM NAVIGATION & LAUNCH BUTTONS
    // -----------------------------------------------------------------
    var bottom_y = con_y + con_h - 75;
    
    // Back to Title Button
    var back_w = 260;
    var back_h = 52;
    var back_x = con_x + 30;
    var back_hov = ui_draw_button(back_x, bottom_y, back_w, back_h, "< BACK TO TITLE", true, false, mx, my);
    state.local_setup_back_hover = back_hov;
    
    // Launch Mission Button
    var launch_w = 540;
    var launch_h = 56;
    var launch_x = con_x + con_w - 30 - launch_w;
    var l_hov = ui_point_in_rect(mx, my, launch_x, bottom_y, launch_w, launch_h);
    state.local_setup_start_hover = l_hov;
    
    draw_set_color(l_hov ? make_color_rgb(46, 204, 113) : make_color_rgb(39, 174, 96));
    draw_roundrect_ext(launch_x, bottom_y, launch_x + launch_w, bottom_y + launch_h, 10, 10, false);
    draw_set_color(l_hov ? c_yellow : c_white);
    draw_roundrect_ext(launch_x, bottom_y, launch_x + launch_w, bottom_y + launch_h, 10, 10, true);
    draw_roundrect_ext(launch_x + 1, bottom_y + 1, launch_x + launch_w - 1, bottom_y + launch_h - 1, 10, 10, true);
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(l_hov ? c_black : c_white);
    draw_text_transformed(launch_x + launch_w * 0.5, bottom_y + launch_h * 0.5, "DEPLOY STRIKE TEAM // LAUNCH MISSION [SPACE] >>", 1.15, 1.15, 0);
}

/// @desc Draws Callsign / Username Entry Screen for Online Wi-Fi Multiplayer
function ui_draw_online_username_screen(state, mx, my) {
    ui_draw_screen_starfield(state);
    
    var term_w = 760;
    var term_h = 520;
    var term_x = (1920 - term_w) * 0.5;
    var term_y = (1080 - term_h) * 0.5;
    
    // Terminal Housing
    draw_set_color(make_color_rgb(18, 24, 36));
    draw_roundrect_ext(term_x, term_y, term_x + term_w, term_y + term_h, 14, 14, false);
    draw_set_color(make_color_rgb(0, 180, 216));
    draw_roundrect_ext(term_x, term_y, term_x + term_w, term_y + term_h, 14, 14, true);
    
    // Glowing Laser Accent Brackets
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_line_width(term_x, term_y + 24, term_x, term_y, 3);
    draw_line_width(term_x, term_y, term_x + 24, term_y, 3);
    draw_line_width(term_x + term_w, term_y + 24, term_x + term_w, term_y, 3);
    draw_line_width(term_x + term_w - 24, term_y, term_x + term_w, term_y, 3);
    draw_line_width(term_x, term_y + term_h - 24, term_x, term_y + term_h, 3);
    draw_line_width(term_x, term_y + term_h, term_x + 24, term_y + term_h, 3);
    draw_line_width(term_x + term_w, term_y + term_h - 24, term_x + term_w, term_y + term_h, 3);
    draw_line_width(term_x + term_w - 24, term_y + term_h, term_x + term_w, term_y + term_h, 3);
    
    // Header
    draw_set_halign(fa_center); draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_text_transformed(960, term_y + 36, "OPERATIVE IDENTIFICATION TERMINAL", 1.4, 1.4, 0);
    draw_set_color(make_color_rgb(140, 185, 225));
    draw_text(960, term_y + 76, "// SECURE LOCAL WI-FI PROTOCOL // LAN DISCOVERY REGISTRATION //");
    
    draw_set_color(make_color_rgb(45, 65, 95));
    draw_line(term_x + 40, term_y + 106, term_x + term_w - 40, term_y + 106);
    
    // Information Notice
    draw_set_color(make_color_rgb(200, 225, 245));
    draw_text_ext(960, term_y + 130, "Please enter your Tactical Callsign before entering public Wi-Fi rooms.\nOther players on your local network will identify your room and actions by this name.", 24, term_w - 100);
    
    // Textbox
    var input_w = 560;
    var input_h = 58;
    var input_x = 960 - input_w * 0.5;
    var input_y = term_y + 225;
    
    draw_set_color(make_color_rgb(12, 16, 24));
    draw_roundrect_ext(input_x, input_y, input_x + input_w, input_y + input_h, 8, 8, false);
    draw_set_color(c_yellow);
    draw_roundrect_ext(input_x, input_y, input_x + input_w, input_y + input_h, 8, 8, true);
    draw_roundrect_ext(input_x + 1, input_y + 1, input_x + input_w - 1, input_y + input_h - 1, 8, 8, true);
    
    var disp_input = state.net_username_input;
    if ((state.name_cursor_timer div 25) % 2 == 0) {
        disp_input += "|";
    }
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text_transformed(960, input_y + input_h * 0.5, disp_input, 1.4, 1.4, 0);
    
    draw_set_color(make_color_rgb(100, 130, 165));
    draw_text(960, input_y + input_h + 24, "Type your callsign (up to 14 characters) and press ENTER to confirm.");
    
    // Error Notification Banner (if any)
    if (state.net_error_timer > 0 && state.net_error_message != "") {
        draw_set_color(make_color_rgb(231, 76, 60));
        draw_text(960, input_y + input_h + 52, state.net_error_message);
    }
    
    // Bottom Buttons
    var btn_w = 260;
    var btn_h = 52;
    var by = term_y + term_h - 75;
    
    state.online_user_back_hover = ui_draw_button(term_x + 50, by, btn_w, btn_h, "< BACK TO TITLE", true, false, mx, my);
    
    var conf_w = 360;
    var conf_x = term_x + term_w - 50 - conf_w;
    var conf_hov = ui_point_in_rect(mx, my, conf_x, by, conf_w, btn_h);
    state.online_user_confirm_hover = conf_hov;
    
    draw_set_color(conf_hov ? make_color_rgb(46, 204, 113) : make_color_rgb(39, 174, 96));
    draw_roundrect_ext(conf_x, by, conf_x + conf_w, by + btn_h, 8, 8, false);
    draw_set_color(conf_hov ? c_yellow : c_white);
    draw_roundrect_ext(conf_x, by, conf_x + conf_w, by + btn_h, 8, 8, true);
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(conf_hov ? c_black : c_white);
    draw_text_transformed(conf_x + conf_w * 0.5, by + btn_h * 0.5, "CONTINUE TO WI-FI ROOMS >>", 1.1, 1.1, 0);
}

/// @desc Draws Public Room Browser for Local Wi-Fi Multiplayer
function ui_draw_online_browser_screen(state, mx, my) {
    ui_draw_screen_starfield(state);
    
    var con_x = 70;
    var con_y = 35;
    var con_w = 1780;
    var con_h = 1010;
    
    // Console Housing
    draw_set_color(make_color_rgb(16, 22, 32));
    draw_roundrect_ext(con_x, con_y, con_x + con_w, con_y + con_h, 14, 14, false);
    draw_set_color(make_color_rgb(44, 60, 84));
    draw_roundrect_ext(con_x, con_y, con_x + con_w, con_y + con_h, 14, 14, true);
    
    // Corner brackets
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_line_width(con_x, con_y + 30, con_x, con_y, 3);
    draw_line_width(con_x, con_y, con_x + 30, con_y, 3);
    draw_line_width(con_x + con_w, con_y + 30, con_x + con_w, con_y, 3);
    draw_line_width(con_x + con_w - 30, con_y, con_x + con_w, con_y, 3);
    draw_line_width(con_x, con_y + con_h - 30, con_x, con_y + con_h, 3);
    draw_line_width(con_x, con_y + con_h, con_x + 30, con_y + con_h, 3);
    draw_line_width(con_x + con_w, con_y + con_h - 30, con_x + con_w, con_y + con_h, 3);
    draw_line_width(con_x + con_w - 30, con_y + con_h, con_x + con_w, con_y + con_h, 3);
    
    // Header Bar
    draw_set_color(make_color_rgb(24, 32, 48));
    draw_roundrect_ext(con_x + 10, con_y + 10, con_x + con_w - 10, con_y + 70, 8, 8, false);
    draw_set_color(make_color_rgb(52, 73, 94));
    draw_roundrect_ext(con_x + 10, con_y + 10, con_x + con_w - 10, con_y + 70, 8, 8, true);
    
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_text_transformed(con_x + 30, con_y + 32, "LOCAL WI-FI MULTIPLAYER // PUBLIC ROOM BROWSER", 1.35, 1.35, 0);
    draw_set_color(make_color_rgb(140, 180, 215));
    draw_text(con_x + 30, con_y + 54, "Auto-discovering defense outpost rooms beaconing on local Wi-Fi subnet (UDP 6511 / TCP 6510).");
    
    // User Identity & Status Strip
    draw_set_halign(fa_right);
    draw_set_color(c_white);
    draw_text(con_x + con_w - 180, con_y + 32, "CALLSIGN: " + state.net_username);
    state.online_browser_edit_user_hover = ui_draw_button(con_x + con_w - 160, con_y + 18, 130, 28, "[Change]", true, false, mx, my);
    
    // Status message / pulsing green dot
    draw_set_color(make_color_rgb(46, 204, 113));
    draw_circle(con_x + con_w - 220, con_y + 54, 5, false);
    draw_set_color(make_color_rgb(160, 220, 180));
    draw_text(con_x + con_w - 30, con_y + 54, "Wi-Fi Subnet Scanner Online");
    
    // -----------------------------------------------------------------
    // ACTION CONTROLS ROW
    // -----------------------------------------------------------------
    var act_y = con_y + 85;
    var act_h = 56;
    
    // Create Public Room Button
    var create_w = 340;
    var create_x = con_x + 30;
    var c_hov = ui_point_in_rect(mx, my, create_x, act_y, create_w, act_h);
    state.online_browser_create_hover = c_hov;
    
    draw_set_color(c_hov ? make_color_rgb(46, 204, 113) : make_color_rgb(39, 174, 96));
    draw_roundrect_ext(create_x, act_y, create_x + create_w, act_y + act_h, 8, 8, false);
    draw_set_color(c_hov ? c_yellow : c_white);
    draw_roundrect_ext(create_x, act_y, create_x + create_w, act_y + act_h, 8, 8, true);
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(c_hov ? c_black : c_white);
    draw_text_transformed(create_x + create_w * 0.5, act_y + act_h * 0.5, "+ CREATE PUBLIC ROOM", 1.2, 1.2, 0);
    
    // Refresh Discovery Ping Button
    var ref_w = 210;
    var ref_x = create_x + create_w + 16;
    state.online_browser_refresh_hover = ui_draw_button(ref_x, act_y, ref_w, act_h, "REFRESH ROOMS [R]", true, false, mx, my);
    
    // Direct IP Connect Box (For local subnets / same machine multi-instance testing)
    var dir_w = 560;
    var dir_x = con_x + con_w - 30 - dir_w;
    draw_set_color(make_color_rgb(20, 28, 42));
    draw_roundrect_ext(dir_x, act_y, dir_x + dir_w, act_y + act_h, 8, 8, false);
    draw_set_color(make_color_rgb(52, 73, 94));
    draw_roundrect_ext(dir_x, act_y, dir_x + dir_w, act_y + act_h, 8, 8, true);
    
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(140, 180, 220));
    draw_text(dir_x + 14, act_y + act_h * 0.5, "Direct IP:");
    
    // IP input textbox
    var ip_bx = dir_x + 95;
    var ip_bw = 250;
    var ip_bh = 38;
    var ip_by = act_y + (act_h - ip_bh) * 0.5;
    
    var is_editing_ip = state.net_direct_ip_editing;
    draw_set_color(is_editing_ip ? make_color_rgb(32, 45, 68) : make_color_rgb(14, 18, 28));
    draw_roundrect_ext(ip_bx, ip_by, ip_bx + ip_bw, ip_by + ip_bh, 6, 6, false);
    draw_set_color(is_editing_ip ? c_yellow : make_color_rgb(60, 85, 120));
    draw_roundrect_ext(ip_bx, ip_by, ip_bx + ip_bw, ip_by + ip_bh, 6, 6, true);
    
    var disp_ip = state.net_direct_ip_input;
    if (is_editing_ip && ((state.name_cursor_timer div 25) % 2 == 0)) disp_ip += "|";
    draw_set_color(c_white);
    draw_text(ip_bx + 10, ip_by + ip_bh * 0.5, disp_ip);
    
    // Direct Connect Button
    var conn_w = 170;
    var conn_x = ip_bx + ip_bw + 12;
    state.online_browser_direct_hover = ui_draw_button(conn_x, ip_by, conn_w, ip_bh, "CONNECT IP >>", true, false, mx, my);
    
    // -----------------------------------------------------------------
    // DISCOVERED ROOMS LIST / RADAR SECTION
    // -----------------------------------------------------------------
    var list_y = act_y + act_h + 18;
    var list_h = 740;
    var list_w = con_w - 60;
    var list_x = con_x + 30;
    
    draw_set_color(make_color_rgb(20, 26, 38));
    draw_roundrect_ext(list_x, list_y, list_x + list_w, list_y + list_h, 10, 10, false);
    draw_set_color(make_color_rgb(45, 60, 85));
    draw_roundrect_ext(list_x, list_y, list_x + list_w, list_y + list_h, 10, 10, true);
    
    var num_rooms = array_length(state.net_discovered_rooms);
    state.online_browser_room_hover = -1;
    
    if (num_rooms == 0) {
        // Sci-Fi Radar Animation
        var rad_cx = list_x + list_w * 0.5;
        var rad_cy = list_y + 300;
        var rad_r = 130;
        
        draw_set_color(make_color_rgb(24, 34, 50));
        draw_circle(rad_cx, rad_cy, rad_r, false);
        draw_set_color(make_color_rgb(0, 180, 216));
        draw_circle(rad_cx, rad_cy, rad_r, true);
        draw_circle(rad_cx, rad_cy, rad_r * 0.66, true);
        draw_circle(rad_cx, rad_cy, rad_r * 0.33, true);
        draw_line(rad_cx - rad_r, rad_cy, rad_cx + rad_r, rad_cy);
        draw_line(rad_cx, rad_cy - rad_r, rad_cx, rad_cy + rad_r);
        
        // Rotating sweep line
        var sweep_ang = (current_time * 0.12) % 360;
        var sw_x = rad_cx + lengthdir_x(rad_r, sweep_ang);
        var sw_y = rad_cy + lengthdir_y(rad_r, sweep_ang);
        draw_set_color(make_color_rgb(0, 229, 255));
        draw_line_width(rad_cx, rad_cy, sw_x, sw_y, 2);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text_transformed(rad_cx, rad_cy + rad_r + 45, "SCANNING LOCAL WI-FI SUBNET FOR DEFENSE ROOMS...", 1.25, 1.25, 0);
        draw_set_color(make_color_rgb(140, 170, 205));
        draw_text(rad_cx, rad_cy + rad_r + 85, "No rooms detected yet on your local network.\nClick '+ CREATE PUBLIC ROOM' to host your own, or ask another player on the same Wi-Fi to create a room.");
    } else {
        // Table Header
        var th_y = list_y + 12;
        draw_set_color(make_color_rgb(26, 36, 52));
        draw_rectangle(list_x + 12, th_y, list_x + list_w - 12, th_y + 36, false);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(100, 181, 246));
        draw_text(list_x + 30, th_y + 18, "ROOM NAME");
        draw_text(list_x + 480, th_y + 18, "HOST CALLSIGN");
        draw_text(list_x + 850, th_y + 18, "PLAYERS CONNECTED");
        draw_text(list_x + 1150, th_y + 18, "IP ADDRESS / PORT");
        draw_set_halign(fa_center);
        draw_text(list_x + list_w - 130, th_y + 18, "ACTION");
        
        // List each room
        var r_row_h = 68;
        var r_start_y = th_y + 46;
        for (var r = 0; r < min(8, num_rooms); r++) {
            var rm = state.net_discovered_rooms[r];
            var ry = r_start_y + r * (r_row_h + 10);
            
            draw_set_color(make_color_rgb(24, 32, 48));
            draw_roundrect_ext(list_x + 12, ry, list_x + list_w - 12, ry + r_row_h, 8, 8, false);
            draw_set_color(make_color_rgb(45, 65, 95));
            draw_roundrect_ext(list_x + 12, ry, list_x + list_w - 12, ry + r_row_h, 8, 8, true);
            
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(c_yellow);
            draw_text_transformed(list_x + 30, ry + r_row_h * 0.5, rm.room_name, 1.15, 1.15, 0);
            
            draw_set_color(c_white);
            draw_text(list_x + 480, ry + r_row_h * 0.5, rm.host_name);
            
            // Player capacity indicator with dots
            var p_str = string(rm.players) + " / " + string(rm.max_players) + " Operatives";
            draw_set_color(make_color_rgb(0, 229, 255));
            draw_text(list_x + 850, ry + r_row_h * 0.5, p_str);
            
            draw_set_color(make_color_rgb(160, 185, 215));
            draw_text(list_x + 1150, ry + r_row_h * 0.5, rm.ip + ":" + string(rm.port));
            
            // Join Room Button
            var j_btn_w = 180;
            var j_btn_h = 44;
            var j_btn_x = list_x + list_w - 24 - j_btn_w;
            var j_btn_y = ry + (r_row_h - j_btn_h) * 0.5;
            var is_full = (rm.players >= rm.max_players);
            
            var j_hov = ui_draw_button(j_btn_x, j_btn_y, j_btn_w, j_btn_h, is_full ? "ROOM FULL" : "JOIN ROOM >>", !is_full, false, mx, my);
            if (j_hov && !is_full) {
                state.online_browser_room_hover = r;
            }
        }
    }
    
    // Bottom Controls Bar
    var bottom_y = con_y + con_h - 75;
    state.online_browser_back_hover = ui_draw_button(con_x + 30, bottom_y, 240, 52, "< BACK TO TITLE", true, false, mx, my);
    
    if (state.net_error_timer > 0 && state.net_error_message != "") {
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(231, 76, 60));
        draw_text(con_x + 300, bottom_y + 26, "ERROR: " + state.net_error_message);
    }
}

/// @desc Draws 4-slot Room Lobby Screen for Local Wi-Fi Multiplayer
function ui_draw_online_lobby_screen(state, mx, my) {
    ui_draw_screen_starfield(state);
    
    var con_x = 70;
    var con_y = 35;
    var con_w = 1780;
    var con_h = 1010;
    
    // Console Housing
    draw_set_color(make_color_rgb(16, 22, 32));
    draw_roundrect_ext(con_x, con_y, con_x + con_w, con_y + con_h, 14, 14, false);
    draw_set_color(make_color_rgb(44, 60, 84));
    draw_roundrect_ext(con_x, con_y, con_x + con_w, con_y + con_h, 14, 14, true);
    
    // Corner brackets
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_line_width(con_x, con_y + 30, con_x, con_y, 3);
    draw_line_width(con_x, con_y, con_x + 30, con_y, 3);
    draw_line_width(con_x + con_w, con_y + 30, con_x + con_w, con_y, 3);
    draw_line_width(con_x + con_w - 30, con_y, con_x + con_w, con_y, 3);
    draw_line_width(con_x, con_y + con_h - 30, con_x, con_y + con_h, 3);
    draw_line_width(con_x, con_y + con_h, con_x + 30, con_y + con_h, 3);
    draw_line_width(con_x + con_w, con_y + con_h - 30, con_x + con_w, con_y + con_h, 3);
    draw_line_width(con_x + con_w - 30, con_y + con_h, con_x + con_w, con_y + con_h, 3);
    
    // Header Bar
    draw_set_color(make_color_rgb(24, 32, 48));
    draw_roundrect_ext(con_x + 10, con_y + 10, con_x + con_w - 10, con_y + 70, 8, 8, false);
    draw_set_color(make_color_rgb(52, 73, 94));
    draw_roundrect_ext(con_x + 10, con_y + 10, con_x + con_w - 10, con_y + 70, 8, 8, true);
    
    var num_joined = array_length(state.net_lobby_players);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(c_yellow);
    draw_text_transformed(con_x + 30, con_y + 32, "TACTICAL DEFENSE OUTPOST // WI-FI MISSION LOBBY", 1.35, 1.35, 0);
    
    draw_set_color(make_color_rgb(140, 180, 215));
    var role_label = state.is_host ? "HOST COMMANDER (You control mission launch)" : "JOINED OPERATIVE (Waiting for commander)";
    draw_text(con_x + 30, con_y + 54, "Status: " + role_label + "  |  Network: Local Wi-Fi Subnet");
    
    draw_set_halign(fa_right);
    draw_set_color(make_color_rgb(0, 229, 255));
    draw_text_transformed(con_x + con_w - 30, con_y + 40, string(num_joined) + " / 4 OPERATIVES CONNECTED", 1.25, 1.25, 0);
    
    // -----------------------------------------------------------------
    // 4 OPERATIVE SLOTS (Large columns side-by-side)
    // -----------------------------------------------------------------
    var p_colors = [
        make_color_rgb(229, 57, 53),   // P1 Red
        make_color_rgb(30, 136, 229),  // P2 Blue
        make_color_rgb(253, 216, 53),  // P3 Yellow
        make_color_rgb(67, 160, 71)    // P4 Green
    ];
    
    var char_classes = game_get_character_classes();
    var num_classes = array_length(char_classes);
    
    var slot_y = con_y + 85;
    var slot_h = 750;
    var s_spacing = 18;
    var total_w = con_w - 60;
    var slot_w = (total_w - s_spacing * 3) / 4;
    
    state.online_lobby_prev_hover = false;
    state.online_lobby_next_hover = false;
    
    for (var s = 0; s < 4; s++) {
        var sx = con_x + 30 + s * (slot_w + s_spacing);
        var p_col = p_colors[s];
        var is_occupied = (s < num_joined);
        var pl = is_occupied ? state.net_lobby_players[s] : undefined;
        var is_me = (s == state.net_my_player_idx);
        
        // Slot Box
        draw_set_color(is_occupied ? make_color_rgb(20, 26, 38) : make_color_rgb(14, 18, 26));
        draw_roundrect_ext(sx, slot_y, sx + slot_w, slot_y + slot_h, 10, 10, false);
        draw_set_color(is_occupied ? p_col : make_color_rgb(45, 60, 80));
        draw_roundrect_ext(sx, slot_y, sx + slot_w, slot_y + slot_h, 10, 10, true);
        if (is_occupied) {
            draw_roundrect_ext(sx + 1, slot_y + 1, sx + slot_w - 1, slot_y + slot_h - 1, 10, 10, true);
        }
        
        // Header Strip
        draw_set_color(is_occupied ? p_col : make_color_rgb(28, 38, 52));
        draw_roundrect_ext(sx + 4, slot_y + 4, sx + slot_w - 4, slot_y + 42, 6, 6, false);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(is_occupied ? c_black : make_color_rgb(140, 160, 180));
        draw_text_transformed(sx + 16, slot_y + 23, "OPERATIVE 0" + string(s + 1), 1.1, 1.1, 0);
        
        draw_set_halign(fa_right);
        if (s == 0) {
            draw_set_color(is_occupied ? c_black : make_color_rgb(140, 160, 180));
            draw_text(sx + slot_w - 16, slot_y + 23, "[HOST COMMANDER]");
        } else if (is_me) {
            draw_set_color(c_black);
            draw_text(sx + slot_w - 16, slot_y + 23, "[YOU]");
        }
        
        if (is_occupied) {
            // Player Name / Callsign Plate
            var nb_y = slot_y + 54;
            draw_set_color(make_color_rgb(14, 18, 28));
            draw_roundrect_ext(sx + 16, nb_y, sx + slot_w - 16, nb_y + 48, 6, 6, false);
            draw_set_color(is_me ? c_yellow : make_color_rgb(60, 85, 120));
            draw_roundrect_ext(sx + 16, nb_y, sx + slot_w - 16, nb_y + 48, 6, 6, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(c_white);
            draw_text_transformed(sx + slot_w * 0.5, nb_y + 24, pl.name, 1.25, 1.25, 0);
            
            // Match Class
            var c_idx = 0;
            for (var ci = 0; ci < num_classes; ci++) {
                if (char_classes[ci].id == pl.character_id) { c_idx = ci; break; }
            }
            var p_class = char_classes[c_idx];
            
            // Class Cycler / Display
            var cyc_y = nb_y + 60;
            var cyc_h = 52;
            
            if (is_me) {
                // Local player can cycle their class!
                var arr_w = 42;
                var px = sx + 16;
                var nx = sx + slot_w - 16 - arr_w;
                var cx_box = px + arr_w + 6;
                var cw_box = nx - cx_box - 6;
                
                var prev_h = ui_draw_button(px, cyc_y, arr_w, cyc_h, "<", true, false, mx, my);
                var next_h = ui_draw_button(nx, cyc_y, arr_w, cyc_h, ">", true, false, mx, my);
                if (prev_h) state.online_lobby_prev_hover = true;
                if (next_h) state.online_lobby_next_hover = true;
                
                draw_set_color(make_color_rgb(26, 36, 52));
                draw_roundrect_ext(cx_box, cyc_y, cx_box + cw_box, cyc_y + cyc_h, 6, 6, false);
                draw_set_color(c_yellow);
                draw_roundrect_ext(cx_box, cyc_y, cx_box + cw_box, cyc_y + cyc_h, 6, 6, true);
                
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_set_color(c_yellow);
                draw_text_transformed(cx_box + cw_box * 0.5, cyc_y + 18, p_class.name, 1.15, 1.15, 0);
                draw_set_color(make_color_rgb(100, 181, 246));
                draw_text(cx_box + cw_box * 0.5, cyc_y + 38, "// " + p_class.role + " //");
            } else {
                // Other connected players: read-only class plate
                draw_set_color(make_color_rgb(24, 32, 46));
                draw_roundrect_ext(sx + 16, cyc_y, sx + slot_w - 16, cyc_y + cyc_h, 6, 6, false);
                draw_set_color(make_color_rgb(52, 73, 94));
                draw_roundrect_ext(sx + 16, cyc_y, sx + slot_w - 16, cyc_y + cyc_h, 6, 6, true);
                
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_set_color(c_white);
                draw_text_transformed(sx + slot_w * 0.5, cyc_y + 18, p_class.name, 1.15, 1.15, 0);
                draw_set_color(make_color_rgb(140, 180, 215));
                draw_text(sx + slot_w * 0.5, cyc_y + 38, "// " + p_class.role + " //");
            }
            
            // Class Emblem Box
            var em_y = cyc_y + cyc_h + 14;
            var em_h = 145;
            draw_set_color(make_color_rgb(14, 18, 28));
            draw_roundrect_ext(sx + 16, em_y, sx + slot_w - 16, em_y + em_h, 8, 8, false);
            draw_set_color(make_color_rgb(40, 56, 80));
            draw_roundrect_ext(sx + 16, em_y, sx + slot_w - 16, em_y + em_h, 8, 8, true);
            ui_draw_class_emblem(sx + slot_w * 0.5, em_y + em_h * 0.5, p_class.id, p_col, true);
            
            // Tactical Perks Box
            var pk_y = em_y + em_h + 14;
            var pk_h = 240;
            var pk_w = slot_w - 32;
            var pk_x = sx + 16;
            
            draw_set_color(make_color_rgb(16, 22, 34));
            draw_roundrect_ext(pk_x, pk_y, pk_x + pk_w, pk_y + pk_h, 8, 8, false);
            draw_set_color(make_color_rgb(45, 62, 88));
            draw_roundrect_ext(pk_x, pk_y, pk_x + pk_w, pk_y + pk_h, 8, 8, true);
            
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            draw_set_color(make_color_rgb(0, 229, 255));
            draw_text(pk_x + 14, pk_y + 12, "[TACTICAL SPECIALTY]");
            
            draw_set_color(c_yellow);
            draw_text(pk_x + 14, pk_y + 38, p_class.perk_tag);
            
            draw_set_color(c_white);
            draw_text_ext(pk_x + 14, pk_y + 68, p_class.desc, 20, pk_w - 28);
            
            // Connected Status Badge
            var stat_y = slot_y + slot_h - 75;
            draw_set_color(make_color_rgb(26, 44, 34));
            draw_roundrect_ext(sx + 16, stat_y, sx + slot_w - 16, stat_y + 54, 8, 8, false);
            draw_set_color(make_color_rgb(46, 204, 113));
            draw_roundrect_ext(sx + 16, stat_y, sx + slot_w - 16, stat_y + 54, 8, 8, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(46, 204, 113));
            draw_circle(sx + 40, stat_y + 27, 6, false);
            draw_set_color(c_white);
            draw_text(sx + slot_w * 0.5 + 10, stat_y + 27, "READY FOR MISSION");
        } else {
            // Empty Waiting Slot
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            
            var wait_cy = slot_y + slot_h * 0.5;
            draw_set_color(make_color_rgb(40, 52, 70));
            draw_circle(sx + slot_w * 0.5, wait_cy - 40, 48, true);
            
            draw_set_color(make_color_rgb(80, 105, 140));
            draw_text_transformed(sx + slot_w * 0.5, wait_cy - 40, "?", 2.2, 2.2, 0);
            
            draw_set_color(make_color_rgb(120, 150, 185));
            draw_text_transformed(sx + slot_w * 0.5, wait_cy + 40, "WAITING FOR ALLY...", 1.15, 1.15, 0);
            
            draw_set_color(make_color_rgb(80, 100, 130));
            draw_text(sx + slot_w * 0.5, wait_cy + 75, "Open slot for player on\nsame Wi-Fi network.");
        }
    }
    
    // -----------------------------------------------------------------
    // BOTTOM MISSION LAUNCH CONTROLS
    // -----------------------------------------------------------------
    var bottom_y = con_y + con_h - 75;
    
    // Leave Room Button
    state.online_lobby_leave_hover = ui_draw_button(con_x + 30, bottom_y, 220, 54, "< LEAVE ROOM", true, false, mx, my);
    
    // Launch Mission Requirement: Host can start ONCE 1 other player has joined (2-4 players)
    var can_start = state.is_host && (num_joined >= 2);
    var start_w = 680;
    var start_x = con_x + con_w - 30 - start_w;
    var start_h = 56;
    
    var s_btn_hov = ui_point_in_rect(mx, my, start_x, bottom_y, start_w, start_h);
    state.online_lobby_start_hover = can_start && s_btn_hov;
    
    if (state.is_host) {
        if (num_joined < 2) {
            // Disabled: waiting for at least 1 other player
            draw_set_color(make_color_rgb(40, 45, 55));
            draw_roundrect_ext(start_x, bottom_y, start_x + start_w, bottom_y + start_h, 10, 10, false);
            draw_set_color(make_color_rgb(80, 85, 95));
            draw_roundrect_ext(start_x, bottom_y, start_x + start_w, bottom_y + start_h, 10, 10, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(170, 175, 185));
            draw_text_transformed(start_x + start_w * 0.5, bottom_y + start_h * 0.5, "WAITING FOR OPERATIVES (Need 2-4 Players to Launch)", 1.1, 1.1, 0);
        } else {
            // Active: Host can launch!
            draw_set_color(s_btn_hov ? make_color_rgb(46, 204, 113) : make_color_rgb(39, 174, 96));
            draw_roundrect_ext(start_x, bottom_y, start_x + start_w, bottom_y + start_h, 10, 10, false);
            draw_set_color(s_btn_hov ? c_yellow : c_white);
            draw_roundrect_ext(start_x, bottom_y, start_x + start_w, bottom_y + start_h, 10, 10, true);
            draw_roundrect_ext(start_x + 1, bottom_y + 1, start_x + start_w - 1, bottom_y + start_h - 1, 10, 10, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(s_btn_hov ? c_black : c_white);
            draw_text_transformed(start_x + start_w * 0.5, bottom_y + start_h * 0.5, "LAUNCH MISSION (" + string(num_joined) + " OPERATIVES ASSEMBLED) [SPACE] >>", 1.15, 1.15, 0);
        }
    } else {
        // Non-host Client view
        draw_set_color(make_color_rgb(26, 38, 56));
        draw_roundrect_ext(start_x, bottom_y, start_x + start_w, bottom_y + start_h, 10, 10, false);
        draw_set_color(make_color_rgb(0, 180, 216));
        draw_roundrect_ext(start_x, bottom_y, start_x + start_w, bottom_y + start_h, 10, 10, true);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        var client_msg = (num_joined < 2) ? "WAITING FOR ANOTHER ALLY TO JOIN (1/4)..." : "WAITING FOR HOST TO LAUNCH MISSION (" + string(num_joined) + "/4 Ready)...";
        draw_text_transformed(start_x + start_w * 0.5, bottom_y + start_h * 0.5, client_msg, 1.15, 1.15, 0);
    }
}


