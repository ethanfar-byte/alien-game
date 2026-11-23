/// @desc UI rendering and interaction drawing for Alien Game

function ui_point_in_rect(px, py, rx, ry, rw, rh) {
    return (px >= rx && px <= rx + rw && py >= ry && py <= ry + rh);
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
    ui_icon_resource(tx, ty, res_type, rad * 2.2);
}

function ui_draw_die(dx, dy, dsize, value, die_color, dot_color) {
    ui_box(dx, dy, dx + dsize, dy + dsize, die_color, c_black, 8);
    
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

function ui_draw_modals(state, mx, my) {
    if (is_undefined(state.modal)) return;
    
    var m = state.modal;

    // Dimmed backdrop with a soft vignette
    var fade_in = ui_anim("modal_fade", 1, 0.25);
    draw_set_color(make_color_rgb(2, 4, 8));
    draw_set_alpha(0.72 * fade_in);
    draw_rectangle(0, 0, 1920, 1080, false);
    draw_set_alpha(1.0);

    if (m.type == "pause") { ui_draw_pause_menu(state, mx, my); state.modal_close_hover = false; return; }
    if (m.type == "help") { ui_draw_help(state, mx, my); state.modal_close_hover = false; return; }

    var mw = 840;
    var mh = 560;
    if (m.type == "settings") { mw = 900; mh = 640; }
    if (m.type == "victory" || m.type == "game_over") { mw = 860; mh = 600; }
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
    
    var frame_col = C_LINE_HI;
    if (m.type == "tactical_combat") frame_col = (state.combat_subphase == "alien_attacks") ? C_BAD : C_WARN;
    else if (m.type == "game_over") frame_col = C_BAD;
    else if (m.type == "victory") frame_col = C_GOOD;
    ui_shadow(mx0, my0, mx0 + mw, my0 + mh, 16, 0.7);
    ui_box(mx0, my0, mx0 + mw, my0 + mh, C_PANEL, frame_col, 16);
    draw_set_color(frame_col);
    draw_line_width(mx0 + 24, my0 + 1, mx0 + mw - 24, my0 + 1, 2);
    ui_corner_brackets(mx0 - 4, my0 - 4, mx0 + mw + 4, my0 + mh + 4, 22, frame_col, 2);

    // Close button (hidden where the player must pick an explicit option)
    if (m.type != "player_setup" && m.type != "game_over" && m.type != "victory" && m.type != "tactical_combat" && m.type != "alien_damage_decision") {
        state.modal_close_hover = ui_draw_button(mx0 + mw - 50, my0 + 14, 34, 32, "×", true, false, mx, my, "ghost");
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
        ui_modal_title(mx0 + mw * 0.5, my0 + 16, string_upper(al.name) + "  //  THREAT DOSSIER", tier_col);
        ui_draw_alien_glyph(mx0 + mw - 110, my0 + 112, al.catalog_id, al.tier, 70, current_time / 1000, 0);
        
        // Stats Overview Box
        var box_x = mx0 + 40;
        var box_y = my0 + 65;
        var box_w = mw - 80;
        var box_h = 95;
        
        ui_box(box_x, box_y, box_x + box_w, box_y + box_h, make_color_rgb(18, 24, 34), tier_col, 8);
        
        // Health with Red Heart Icon
        ui_draw_heart(box_x + 35, box_y + 32, 20, make_color_rgb(231, 76, 60), c_white, 2);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(box_x + 55, box_y + 32, "Health: " + string(al.hp) + " / " + string(al.max_hp) + " HP");
        
        // Attack Damage
        draw_set_color(C_AMBER);
        draw_text(box_x + 280, box_y + 32, "Attack Power: " + string(al.damage) + " Damage");
        
        // Status Condition
        var stat_str = al.frozen ? "FROZEN (Deals 0 dmg next attack)" : (al.vulnerable ? "VULNERABLE (+1 damage taken)" : "Active Combat Ready");
        draw_set_color(al.frozen ? C_ACCENT : (al.vulnerable ? C_WARN : make_color_rgb(180, 210, 240)));
        draw_text(box_x + 55, box_y + 68, "Status Condition: " + stat_str);
        
        // Special Ability Profile
        var ab_y = box_y + box_h + 18;
        var ab_h = 295;
        ui_box(box_x, ab_y, box_x + box_w, ab_y + ab_h, make_color_rgb(18, 24, 34), make_color_rgb(70, 85, 110), 8);
        
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(C_AMBER);
        draw_text(box_x + 20, ab_y + 16, "TACTICAL PROFILE & SPECIAL ABILITY:");
        
        draw_set_color(c_white);
        ui_text_ext(box_x + 20, ab_y + 46, al.ability, 22, box_w - 40);
        
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
            ui_text_ext(box_x + 20, ab_y + 170, tip_text, 22, box_w - 40);
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
        ui_box(mx0 + 16, head_y, mx0 + mw - 16, head_y + 54, make_color_rgb(18, 24, 38), make_color_rgb(45, 65, 95), 8);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(255, 215, 0));
        draw_set_font(fnt_h3);
        draw_text(mx0 + 32, head_y + 17, "TACTICAL DEFENSE  //  DAY " + string(state.round_number));
        draw_set_font(fnt_body);
        
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
        var spd_lbl = is_2x ? "Speed 2x" : "Speed 1x";
        state.combat_speed_btn_hover = ui_draw_button(spd_x, spd_y, spd_w, spd_h, spd_lbl, true, is_2x, mx, my, "default", "Tab");
        if (state.combat_speed_btn_hover) {
            state.hover_tooltip = "Toggle 2x speed for weapon attacks, projectiles and animations.";
        }
        
        if (state.combat_subphase == "player_weapons") {
            var adv_w = 250;
            var adv_h = 36;
            var adv_x = spd_x - adv_w - 12;
            var adv_y = head_y + 9;
            state.combat_advance_hover = ui_draw_button(adv_x, adv_y, adv_w, adv_h, "End Volley", array_length(state.combat_player_projectiles) == 0, false, mx, my, "danger", "Space");
            if (state.combat_advance_hover) {
                state.hover_tooltip = "End weapons attack phase immediately and proceed to alien retaliation.";
            }
        } else if (state.combat_subphase == "combat_concluded") {
            var conc_w = 260;
            var conc_h = 36;
            var conc_x = spd_x - conc_w - 12;
            var conc_y = head_y + 9;
            var chov = ui_draw_button(conc_x, conc_y, conc_w, conc_h, "Continue", true, true, mx, my, "success", "Space");
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
            ui_box(mx0 + 30, card_y, mx0 + mw - 30, card_y + 80, make_color_rgb(18, 24, 34), make_color_rgb(46, 60, 80), 8);
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
                
                ui_draw_combat_alien_card(state, ac_x, card_y, card_w, card_h, al, a, is_al_hov, is_target_locked, is_scout);
            }
        }
        
        // -------------------------------------------------------------
        // 3. MIDDLE ENGAGEMENT ZONE: TARGETING RETICLES, PROJECTILES & IMPACTS
        // -------------------------------------------------------------
        var mid_y0 = card_y + card_h + 10;
        ui_draw_combat_battlefield(state, mx0, mw, mid_y0, tw_sec_y - 8);
        
        // Targeting line from active selected tower to hovered alien
        if (state.combat_subphase == "player_weapons" && state.combat_selected_tower >= 0 && state.combat_alien_hover >= 0) {
            var st_idx = state.combat_selected_tower;
            var al_idx = state.combat_alien_hover;
            if (st_idx < array_length(state.combat_tower_coords) && al_idx < array_length(state.combat_alien_coords)) {
                var p_start = state.combat_tower_coords[st_idx];
                var p_end = state.combat_alien_coords[al_idx];
                var can_tgt = !(has_scout_alive && state.active_zone[al_idx].catalog_id != "scout");
                
                draw_set_color(can_tgt ? C_ACCENT : make_color_rgb(255, 80, 80));
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
                    ui_box(tag_x - 45, tag_y - 14, tag_x + 45, tag_y + 14, c_black, C_AMBER, 4);
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
            
            ui_box(con_panel_x, con_panel_y, con_panel_x + con_panel_w, con_panel_y + con_panel_h, make_color_rgb(18, 24, 36), make_color_rgb(46, 204, 113), 12);
            
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
            var conc_b_hover = ui_draw_button(conc_btn_x, conc_btn_y, conc_btn_w, conc_btn_h, "Return to Base", true, true, mx, my, "success", "Space");
            if (conc_b_hover) {
                state.combat_conclude_btn_hover = true;
                state.hover_tooltip = "Close tactical combat display and return to the main base.";
            }
        }
        
        // -------------------------------------------------------------
        // 4. BOTTOM SECTION: TOWER HARDPOINTS
        // -------------------------------------------------------------
        ui_section_label(mx0 + 32, tw_sec_y, "Base hardpoints  -  arm a weapon, then click an alien");
        state.combat_tower_coords = [];
        for (var t = 0; t < 4; t++) {
            var t_x = slot_start_x + t * (slot_w + slot_gap);
            state.combat_tower_coords[t] = [t_x + slot_w * 0.5, slot_y];
            var tres = ui_draw_combat_tower_card(state, t, t_x, slot_y, slot_w, slot_h, mx, my);
            state.combat_tower_hover[t] = tres.hover;
            if (tres.tesla_hover) {
                state.combat_tesla_btn_hover = true;
                state.hover_tooltip = "Discharge the Tesla coil: damages and weakens every active alien.";
            }
        }
        // Floating damage numbers
        if (is_array(state.combat_texts)) {
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            for (var ct = 0; ct < array_length(state.combat_texts); ct++) {
                var ctx = state.combat_texts[ct];
                var pop = 1 + max(0, (ctx.life - (ctx.max_life - 8)) / 8) * 0.6;
                draw_set_font(ctx.big ? fnt_h1 : fnt_h2);
                draw_set_alpha(clamp(ctx.life / 18, 0, 1));
                if (pop > 1.01) draw_text_transformed_color(ctx.x, ctx.y, ctx.text, pop, pop, 0, ctx.color, ctx.color, ctx.color, ctx.color, draw_get_alpha());
                else ui_text_outline(ctx.x, ctx.y, ctx.text, ctx.color);
            }
            draw_set_alpha(1);
            draw_set_font(fnt_body);
        }
    }
    else if (m.type == "shop") {
        // -------------------------------------------------------------
        // HEADER: TITLE & CORE HUD BADGES
        // -------------------------------------------------------------
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(C_AMBER);
        ui_modal_title(mx0 + mw * 0.5, my0 + 10, "BLUEPRINT SHOP", C_AMBER);
        
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
        
        ui_box(st_x, st_y, st_x + st_w, st_y + st_h, is_at_shop ? make_color_rgb(16, 38, 24) : make_color_rgb(38, 30, 14), is_at_shop ? make_color_rgb(46, 204, 113) : make_color_rgb(243, 156, 18), 6);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(is_at_shop ? make_color_rgb(140, 240, 170) : make_color_rgb(255, 200, 80));
        var st_msg = is_at_shop ? ("[AT SHOP] " + cur_p.name + " (" + string(task_cost) + "E to buy)") : "[REMOTE VIEW] Station at Shop to buy";
        draw_text(st_x + 12, st_y + st_h * 0.5, st_msg);
        
        // Team Treasury Badge (Top-Middle)
        var gold_w = 200;
        var gold_h = 28;
        var gold_x = st_x + st_w + 20;
        var gold_y = my0 + 44;
        
        ui_box(gold_x, gold_y, gold_x + gold_w, gold_y + gold_h, make_color_rgb(36, 30, 14), make_color_rgb(255, 215, 0), 6);
        
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
            ui_box(wx, wy, wx + card_w, wy + card_h, card_hov ? make_color_rgb(32, 40, 56) : make_color_rgb(22, 28, 40), make_color_rgb(255, 215, 0), 10);
            
            // 1. Weapon Name
            draw_set_halign(fa_center); draw_set_valign(fa_top);
            draw_set_color(C_AMBER);
            draw_text(wx + card_w * 0.5, wy + 14, item.name);
            
            // 2. Stats Badge Plate (HP, Dmg, Targets)
            var st_py = wy + 40;
            var st_ph = 30;
            ui_box(wx + 12, st_py, wx + card_w - 12, st_py + st_ph, make_color_rgb(16, 20, 30), make_color_rgb(46, 60, 80), 6);
            
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
            ui_box(wx + 12, ab_py, wx + card_w - 12, ab_py + ab_ph, make_color_rgb(16, 20, 30), make_color_rgb(46, 60, 80), 6);
            
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            draw_set_color(make_color_rgb(100, 210, 255));
            draw_text(wx + 20, ab_py + 8, "TACTICAL ABILITY:");
            
            draw_set_color(make_color_rgb(220, 235, 245));
            ui_text_ext(wx + 20, ab_py + 26, item.ability, 17, card_w - 40);
            
            // 4. Blueprint Specs & Materials Box
            var sp_py = wy + 172;
            var sp_ph = 254;
            ui_box(wx + 12, sp_py, wx + card_w - 12, sp_py + sp_ph, make_color_rgb(16, 20, 30), make_color_rgb(46, 60, 80), 6);
            
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
                
                ui_icon_resource(wx + 28, my_row, rk, 18);
                
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
        draw_set_color(C_AMBER);
        ui_modal_title(mx0 + mw * 0.5, my0 + 10, "TOWN MARKET", C_AMBER);
        
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
        
        ui_box(st_x, st_y, st_x + st_w, st_y + st_h, is_at_town ? make_color_rgb(16, 38, 24) : make_color_rgb(38, 30, 14), is_at_town ? make_color_rgb(46, 204, 113) : make_color_rgb(243, 156, 18), 6);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(is_at_town ? make_color_rgb(140, 240, 170) : make_color_rgb(255, 200, 80));
        var st_msg = is_at_town ? ("[AT TOWN] " + cur_p.name + " Ready to Trade • " + cost_note) : "[REMOTE VIEW] Move operative to Town to trade goods";
        draw_text(st_x + 12, st_y + st_h * 0.5, st_msg);
        
        // Team Treasury Badge (Top-Right)
        var gold_w = 230;
        var gold_h = 28;
        var gold_x = mx0 + mw - 30 - gold_w;
        var gold_y = my0 + 44;
        
        ui_box(gold_x, gold_y, gold_x + gold_w, gold_y + gold_h, make_color_rgb(36, 30, 14), make_color_rgb(255, 215, 0), 6);
        
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
        
        ui_box(fav_x, fav_y, fav_x + fav_w, fav_y + fav_h, make_color_rgb(32, 26, 18), make_color_rgb(255, 179, 0), 8);
        
        // Star badge pill on left
        var pill_w = 90;
        var pill_h = 32;
        var pill_x = fav_x + 12;
        var pill_y = fav_y + 11;
        ui_box(pill_x, pill_y, pill_x + pill_w, pill_y + pill_h, make_color_rgb(64, 48, 14), make_color_rgb(255, 215, 0), 6);
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
        ui_box(bon_x, bon_y, bon_x + bon_w, bon_y + bon_h, make_color_rgb(20, 48, 28), make_color_rgb(46, 204, 113), 6);
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
            ui_box(rx, ry, rx + row_w, ry + row_h, is_favored ? make_color_rgb(34, 30, 20) : make_color_rgb(22, 28, 40), is_favored ? make_color_rgb(255, 179, 0) : make_color_rgb(46, 60, 80), 8);
            
            // 1. Resource Icon Token
            var ic_x = rx + 26;
            ui_icon_resource(ic_x, r_mid_y, rk, 28);
            
            // 2. Resource Name
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(is_favored ? make_color_rgb(255, 235, 130) : c_white);
            draw_text(rx + 54, r_mid_y, rdef.name);
            
            if (is_favored) {
                var name_w = string_width(rdef.name);
                var f_pill_x = rx + 54 + name_w + 12;
                var f_pill_w = 68;
                var f_pill_h = 20;
                ui_box(f_pill_x, r_mid_y - 10, f_pill_x + f_pill_w, r_mid_y + 10, make_color_rgb(58, 44, 14), make_color_rgb(255, 193, 7), 4);
                
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
        draw_set_color(C_AMBER);
        ui_modal_title(mx0 + mw * 0.5, my0 + 10, "WORKSHOP  //  FORGE & REPAIR", C_AMBER);
        
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
        
        ui_box(st_x, st_y, st_x + st_w, st_y + st_h, is_at_workstation ? make_color_rgb(16, 38, 24) : make_color_rgb(38, 30, 14), is_at_workstation ? make_color_rgb(46, 204, 113) : make_color_rgb(243, 156, 18), 6);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(is_at_workstation ? make_color_rgb(140, 240, 170) : make_color_rgb(255, 200, 80));
        var st_msg = is_at_workstation ? ("[AT WORKSTATION] " + cur_p.name + " Ready • " + cost_note) : "[REMOTE VIEW] Move operative to Workstation to forge/repair";
        draw_text(st_x + 12, st_y + st_h * 0.5, st_msg);
        
        // Right Perk / System Pill
        var pk_w = 560;
        var pk_h = 28;
        var pk_x = mx0 + 590;
        var pk_y = my0 + 44;
        
        ui_box(pk_x, pk_y, pk_x + pk_w, pk_y + pk_h, make_color_rgb(20, 28, 40), is_engineer ? make_color_rgb(255, 215, 0) : make_color_rgb(66, 165, 245), 6);
        
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
        ui_box(col1_x, my0 + 78, col1_x + col1_w, my0 + 104, make_color_rgb(20, 28, 40), make_color_rgb(46, 75, 105), 6);
        
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
            ui_box(col1_x, view_y, col1_x + col1_w, view_y + view_h, make_color_rgb(18, 24, 34), make_color_rgb(45, 60, 80), 8);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(180, 200, 220));
            ui_text_ext(col1_x + col1_w * 0.5, view_y + view_h * 0.5, "[No Blueprints Owned]\n\nVisit the Weapon Shop (south of Main Base) to purchase\nweapon blueprints using Gold.\n\nOnce acquired, bring them here to spend raw materials\nand forge them directly onto Towers 1-4!", 22, col1_w - 40);
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
            ui_box(0, 0, surf_w, surf_h, make_color_rgb(18, 24, 34), make_color_rgb(45, 60, 80), 8);
            
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
                
                ui_box(4, bpy, 4 + card_inner_w, bpy + bp_h, make_color_rgb(22, 28, 40), make_color_rgb(52, 73, 94), 8);
                
                // Name & Stats
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                draw_set_color(C_AMBER);
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
                ui_text_ext(18, bpy + 62, bp.ability, 16, card_inner_w - 24);
                
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
        ui_box(col2_x, my0 + 78, col2_x + col2_w, my0 + 104, make_color_rgb(20, 28, 40), make_color_rgb(46, 75, 105), 6);
        
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
            ui_box(col2_x, r_row_y, col2_x + col2_w, r_row_y + rep_row_h, make_color_rgb(22, 28, 40), make_color_rgb(46, 60, 80), 6);
            
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
            draw_set_color(can_rep1 ? (bhov1 ? C_AMBER : make_color_rgb(120, 240, 150)) : make_color_rgb(140, 140, 140));
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
            draw_set_color(can_rep3 ? (bhov3 ? C_AMBER : make_color_rgb(100, 220, 255)) : make_color_rgb(140, 140, 140));
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
        ui_box(col2_x, wep_sec_y, col2_x + col2_w, wep_sec_y + 26, make_color_rgb(20, 28, 40), make_color_rgb(46, 75, 105), 6);
        
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
                ui_box(col2_x, wy_row, col2_x + col2_w, wy_row + 40, make_color_rgb(22, 28, 40), make_color_rgb(46, 60, 80), 6);
                
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
                draw_set_color(can_wrep ? (bhov_w ? C_AMBER : make_color_rgb(120, 240, 150)) : make_color_rgb(140, 140, 140));
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
            ui_box(col2_x, wy, col2_x + col2_w, wy + 80, make_color_rgb(18, 24, 34), make_color_rgb(45, 60, 80), 6);
            
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
        ui_draw_end_screen(state, mx, my, mx0, my0, mw, mh, true);
    }
    else if (m.type == "game_over" || state.phase == "game_over") {
        ui_draw_end_screen(state, mx, my, mx0, my0, mw, mh, false);
    }
    else if (m.type == "player_setup") {
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(C_AMBER);
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
            ui_box(row_x, ry, row_x + row_w, ry + row_h, make_color_rgb(26, 33, 46), p_colors[p], 8);
            
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
            
            ui_box(name_bx, name_by, name_bx + name_bw, name_by + name_bh, is_editing ? make_color_rgb(42, 52, 72) : (name_hov ? make_color_rgb(32, 42, 58) : make_color_rgb(18, 24, 34)), is_editing ? C_AMBER : (name_hov ? c_white : make_color_rgb(80, 100, 130)), 6);
            
            draw_set_valign(fa_middle);
            draw_set_color(is_editing ? C_AMBER : c_white);
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
            ui_box(info_x, info_y, info_x + info_w, info_y + info_h, make_color_rgb(18, 23, 33), make_color_rgb(52, 70, 95), 6);
            
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
            draw_set_color(C_AMBER);
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
        ui_draw_settings(state, mx, my, mx0, my0, mw, mh);
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
    
    // Ambient nebula glows (smooth radial gradients that drift slowly)
    var nt = current_time / 1000;
    ui_glow(450 + sin(nt * 0.05) * 40, 320, 620, make_color_rgb(30, 90, 160), 0.35);
    ui_glow(1480, 700 + cos(nt * 0.04) * 30, 700, make_color_rgb(110, 50, 150), 0.28);
    ui_glow(960, 540, 420, make_color_rgb(16, 110, 110), 0.18);
    
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

/// @desc Title screen: animated planet horizon, glowing logo and a keyboard/mouse menu
function ui_draw_title_screen(state, mx, my) {
    ui_draw_screen_starfield(state);
    var t = current_time / 1000;

    // Planet horizon with atmosphere glow
    var pcx = 1300, pcy = 2050, pr = 1250;
    // Atmosphere: gradient band hugging the horizon
    draw_primitive_begin(pr_trianglestrip);
    for (var ang = 40; ang <= 140; ang += 1.5) {
        draw_vertex_color(pcx + lengthdir_x(pr + 150, ang), pcy + lengthdir_y(pr + 150, ang), make_color_rgb(40, 120, 220), 0);
        draw_vertex_color(pcx + lengthdir_x(pr, ang), pcy + lengthdir_y(pr, ang), make_color_rgb(60, 150, 255), 0.35);
    }
    draw_primitive_end();
    // Planet body as a finely tessellated arc so the horizon stays perfectly smooth
    draw_set_color(make_color_rgb(9, 15, 26));
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(pcx, pcy);
    for (var ang = 30; ang <= 150; ang += 1) draw_vertex(pcx + lengthdir_x(pr, ang), pcy + lengthdir_y(pr, ang));
    draw_primitive_end();
    draw_set_color(make_color_rgb(90, 180, 255));
    for (var ang = 30; ang < 150; ang += 1) {
        draw_line_width(pcx + lengthdir_x(pr, ang), pcy + lengthdir_y(pr, ang), pcx + lengthdir_x(pr, ang + 1), pcy + lengthdir_y(pr, ang + 1), 2);
    }
    // Outpost silhouette on the horizon with blinking beacons
    var ox = 1460, oy = pcy - pr + 2;
    draw_set_color(make_color_rgb(6, 10, 16));
    draw_rectangle(ox - 120, oy - 40, ox - 70, oy + 20, false);
    draw_rectangle(ox - 60, oy - 70, ox - 30, oy + 20, false);
    draw_rectangle(ox - 20, oy - 30, ox + 80, oy + 20, false);
    draw_triangle(ox - 70, oy - 70, ox - 20, oy - 70, ox - 45, oy - 100, false);
    draw_rectangle(ox + 90, oy - 55, ox + 110, oy + 20, false);
    var blink = (frac(t * 0.7) < 0.5);
    draw_set_color(blink ? make_color_rgb(255, 80, 80) : make_color_rgb(90, 30, 30));
    draw_circle(ox - 45, oy - 102, 3, false);
    draw_set_color(make_color_rgb(120, 220, 255));
    draw_circle(ox + 100, oy - 58, 2, false);
    // Distant swarm silhouettes drifting over the planet
    for (var i = 0; i < 7; i++) {
        var sx = 1920 - ((t * (18 + i * 4) + i * 260) mod 2200) + 140;
        var sy = 520 + i * 34 + sin(t * 1.3 + i) * 12;
        draw_set_alpha(0.35);
        ui_draw_alien_glyph(sx, sy, (i mod 3 == 0) ? "drooper" : "drone", 1 + (i mod 3), 22 + (i mod 3) * 6, t + i, 0);
        draw_set_alpha(1);
    }

    // Logo
    var lx = 160, ly = 210;
    var intro = 1 - (state[$ "transition"] ?? 0);
    draw_set_font(fnt_small);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_ACCENT);
    draw_text(lx + 4, ly - 82, "CO-OP OUTPOST DEFENSE   //   1-4 OPERATIVES   //   LOCAL & LAN");
    draw_set_color(C_ACCENT);
    draw_line_width(lx, ly - 64, lx + 120 * intro + 520, ly - 64, 2);
    draw_set_font(fnt_title);
    ui_glow(lx + 360, ly + 10, 260, C_ACCENT, 0.12 + 0.04 * sin(t * 2));
    draw_set_alpha(0.6);
    draw_set_color(C_ACCENT_D);
    draw_text(lx + 4, ly + 6, "ALIEN GAME");
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_text(lx, ly, "ALIEN GAME");
    draw_set_font(fnt_h2);
    draw_set_color(C_AMBER);
    draw_text(lx + 6, ly + 74, "HOLD THE OUTPOST FOR 17 DAYS");

    // Menu
    var items = [
        ["PLAY LOCAL", "1-4 operatives sharing this screen"],
        ["PLAY ON LAN", "Host or join a squad on your Wi-Fi network"],
        ["HOW TO PLAY", "Rules and controls"],
        ["SETTINGS", "Display, audio and gameplay options"],
        ["QUIT", "Exit to desktop"]
    ];
    var my0 = 430, bh = 70;
    state.title_hover = -1;
    state.title_btn_local_hover = false; state.title_btn_online_hover = false; state.title_btn_settings_hover = false; state.title_btn_quit_hover = false;
    for (var i = 0; i < array_length(items); i++) {
        var by = my0 + i * (bh + 6);
        var hov = ui_point_in_rect(mx, my, lx - 20, by, 560, bh);
        if (hov && is_undefined(state.modal)) {
            state.title_hover = i;
            state.title_sel = i;
        }
        var sel = (state[$ "title_sel"] ?? 0) == i;
        var a = ui_anim("title_item" + string(i), sel ? 1 : 0, 0.22);
        if (sel) global.ui_hover_key = "title" + string(i);
        // Highlight bar
        if (a > 0.01) {
            draw_set_alpha(0.85 * a);
            draw_set_color(make_color_rgb(12, 30, 46));
            draw_rectangle(lx - 20, by, lx - 20 + 560 * a, by + bh, false);
            draw_set_alpha(a);
            draw_set_color(i == 4 ? C_BAD : C_ACCENT);
            draw_rectangle(lx - 20, by, lx - 15, by + bh, false);
            draw_set_alpha(1);
        }
        draw_set_font(fnt_h2);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(ui_col_mix(C_DIM, (i == 4) ? C_BAD : c_white, a));
        draw_text(lx + 10 + a * 14, by + 26, items[i][0]);
        draw_set_font(fnt_small);
        draw_set_color(ui_col_mix(C_FAINT, C_DIM, a));
        draw_text(lx + 10 + a * 14, by + 52, items[i][1]);
    }

    // Footer
    draw_set_font(fnt_small);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_FAINT);
    var kx = lx - 20;
    kx += ui_keycap(kx, 1030, "W") + 4;
    kx += ui_keycap(kx, 1030, "S") + 8;
    draw_text(kx, 1030, "Navigate");
    kx += 80;
    kx += ui_keycap(kx, 1030, "Enter") + 8;
    draw_set_color(C_FAINT);
    draw_text(kx, 1030, "Select");
    kx += 70;
    kx += ui_keycap(kx, 1030, "F11") + 8;
    draw_set_color(C_FAINT);
    draw_text(kx, 1030, "Fullscreen");
    draw_set_halign(fa_right);
    draw_text(1890, 1030, "v2.1  -  LAN ports TCP 6510 / UDP 6511");
    draw_set_font(fnt_body);
}

/// @desc Draws dedicated, significantly improved Local Setup Screen (1-4 players & character roles)
function ui_draw_local_setup_screen(state, mx, my) {
    ui_draw_screen_starfield(state);
    
    var con_x = 70;
    var con_y = 35;
    var con_w = 1780;
    var con_h = 1010;
    
    // Main Console Housing
    ui_box(con_x, con_y, con_x + con_w, con_y + con_h, make_color_rgb(16, 22, 32), make_color_rgb(44, 60, 84), 14);
    
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
    ui_box(con_x + 10, con_y + 10, con_x + con_w - 10, con_y + 70, make_color_rgb(24, 32, 48), make_color_rgb(52, 73, 94), 8);
    
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_AMBER);
    ui_text_scaled(con_x + 30, con_y + 32, "TACTICAL SQUAD BRIEFING // ROSTER ALLOCATION", 1.35);
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
        var card_bd = is_sel ? C_AMBER : (chov ? c_white : make_color_rgb(60, 80, 110));
        
        ui_box(cx, count_y, cx + count_w, count_y + count_h, card_bg, card_bd, 8);
        if (is_sel) {
            draw_roundrect_ext(cx + 1, count_y + 1, cx + count_w - 1, count_y + count_h - 1, 8, 8, true);
        }
        
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(is_sel ? C_AMBER : (chov ? c_white : make_color_rgb(180, 205, 230)));
        ui_text_scaled(cx + 16, count_y + 10, size_info[c][0], 1.1);
        
        draw_set_color(is_sel ? make_color_rgb(255, 235, 59) : make_color_rgb(120, 180, 160));
        draw_text(cx + 16, count_y + 32, size_info[c][1]);
        
        draw_set_color(make_color_rgb(130, 145, 165));
        draw_text(cx + 16, count_y + 50, size_info[c][2]);
        
        // Active radio check indicator on right
        var rad_x = cx + count_w - 24;
        var rad_y = count_y + 22;
        draw_set_color(is_sel ? C_AMBER : make_color_rgb(60, 75, 100));
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
        ui_box(card_x, dossier_y, card_x + card_w, dossier_y + dossier_h, make_color_rgb(20, 26, 38), p_col, 10);
        draw_roundrect_ext(card_x + 1, dossier_y + 1, card_x + card_w - 1, dossier_y + dossier_h - 1, 10, 10, true);
        
        // 1. Operative Header Strip
        draw_set_color(p_col);
        draw_roundrect_ext(card_x + 4, dossier_y + 4, card_x + card_w - 4, dossier_y + 42, 6, 6, false);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(c_black);
        ui_text_scaled(card_x + 16, dossier_y + 23, "OPERATIVE 0" + string(p + 1), 1.15);
        
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
        
        ui_box(name_bx, name_by, name_bx + name_bw, name_by + name_bh, is_editing ? make_color_rgb(38, 52, 74) : (name_hov ? make_color_rgb(30, 42, 60) : make_color_rgb(14, 18, 28)), is_editing ? C_AMBER : (name_hov ? c_white : make_color_rgb(70, 95, 130)), 6);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(make_color_rgb(130, 160, 195));
        draw_text(name_bx + 12, name_by + 14, "CALLSIGN:");
        
        var disp_name = state.setup_player_names[p];
        if (is_editing && ((state.name_cursor_timer div 25) % 2 == 0)) {
            disp_name += "|";
        }
        draw_set_color(is_editing ? C_AMBER : c_white);
        ui_text_scaled(name_bx + 90, name_by + 26, disp_name, 1.2);
        
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
        
        ui_box(cname_x, cycler_y, cname_x + cname_w, cycler_y + cycler_h, make_color_rgb(26, 36, 52), make_color_rgb(52, 73, 94), 6);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(C_AMBER);
        ui_text_scaled(cname_x + cname_w * 0.5, cycler_y + 18, p_class.name, 1.2);
        draw_set_color(make_color_rgb(100, 181, 246));
        draw_text(cname_x + cname_w * 0.5, cycler_y + 38, "// " + p_class.role + " //");
        
        // 4. Class Emblem & Holographic Avatar Plate
        var avatar_y = cycler_y + cycler_h + 14;
        var avatar_h = 135;
        ui_box(card_x + 16, avatar_y, card_x + card_w - 16, avatar_y + avatar_h, make_color_rgb(14, 18, 28), make_color_rgb(40, 56, 80), 8);
        
        // Draw Class Emblem Vector
        var emblem_cx = card_x + card_w * 0.5;
        var emblem_cy = avatar_y + avatar_h * 0.5;
        ui_draw_class_emblem(emblem_cx, emblem_cy, p_class.id, p_col, true);
        
        // 5. Tactical Specification Dossier Box
        var spec_y = avatar_y + avatar_h + 14;
        var spec_h = 230;
        var spec_w = card_w - 32;
        var spec_x = card_x + 16;
        
        ui_box(spec_x, spec_y, spec_x + spec_w, spec_y + spec_h, make_color_rgb(16, 22, 34), make_color_rgb(45, 62, 88), 8);
        
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(make_color_rgb(0, 229, 255));
        draw_text(spec_x + 14, spec_y + 12, "[FIELD SPECIFICATIONS]");
        
        // Perk Tag Badge
        ui_box(spec_x + 14, spec_y + 36, spec_x + spec_w - 14, spec_y + 64, make_color_rgb(32, 45, 65), make_color_rgb(64, 90, 130), 4);
        
        draw_set_valign(fa_middle);
        draw_set_color(C_AMBER);
        draw_text(spec_x + 22, spec_y + 50, p_class.perk_tag);
        
        // Descriptive perks text
        draw_set_valign(fa_top);
        draw_set_color(c_white);
        ui_text_ext(spec_x + 14, spec_y + 74, p_class.desc, 20, spec_w - 28);
        
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
        
        ui_box(eplate_x, eplate_y, eplate_x + eplate_w, eplate_y + eplate_h, make_color_rgb(26, 38, 56), make_color_rgb(255, 215, 0), 8);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        ui_text_scaled(eplate_x + 16, eplate_y + eplate_h * 0.5, "STARTING ENERGY:", 1.1);
        
        draw_set_halign(fa_right);
        draw_set_color(C_AMBER);
        ui_text_scaled(eplate_x + eplate_w - 44, eplate_y + eplate_h * 0.5, string(calc_energy), 1.4);
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
    
    ui_box(launch_x, bottom_y, launch_x + launch_w, bottom_y + launch_h, l_hov ? make_color_rgb(46, 204, 113) : make_color_rgb(39, 174, 96), l_hov ? C_AMBER : c_white, 10);
    draw_roundrect_ext(launch_x + 1, bottom_y + 1, launch_x + launch_w - 1, bottom_y + launch_h - 1, 10, 10, true);
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(l_hov ? c_black : c_white);
    ui_text_scaled(launch_x + launch_w * 0.5, bottom_y + launch_h * 0.5, "LAUNCH MISSION   [ENTER]", 1.15);
}

/// @desc Draws Callsign / Username Entry Screen for Online Wi-Fi Multiplayer
function ui_draw_online_username_screen(state, mx, my) {
    ui_draw_screen_starfield(state);
    
    var term_w = 760;
    var term_h = 520;
    var term_x = (1920 - term_w) * 0.5;
    var term_y = (1080 - term_h) * 0.5;
    
    // Terminal Housing
    ui_box(term_x, term_y, term_x + term_w, term_y + term_h, make_color_rgb(18, 24, 36), make_color_rgb(0, 180, 216), 14);
    
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
    ui_text_scaled(960, term_y + 36, "OPERATIVE IDENTIFICATION TERMINAL", 1.4);
    draw_set_color(make_color_rgb(140, 185, 225));
    draw_text(960, term_y + 76, "// SECURE LOCAL WI-FI PROTOCOL // LAN DISCOVERY REGISTRATION //");
    
    draw_set_color(make_color_rgb(45, 65, 95));
    draw_line(term_x + 40, term_y + 106, term_x + term_w - 40, term_y + 106);
    
    // Information Notice
    draw_set_color(make_color_rgb(200, 225, 245));
    ui_text_ext(960, term_y + 130, "Please enter your Tactical Callsign before entering public Wi-Fi rooms.\nOther players on your local network will identify your room and actions by this name.", 24, term_w - 100);
    
    // Textbox
    var input_w = 560;
    var input_h = 58;
    var input_x = 960 - input_w * 0.5;
    var input_y = term_y + 225;
    
    ui_box(input_x, input_y, input_x + input_w, input_y + input_h, make_color_rgb(12, 16, 24), C_AMBER, 8);
    draw_roundrect_ext(input_x + 1, input_y + 1, input_x + input_w - 1, input_y + input_h - 1, 8, 8, true);
    
    var disp_input = state.net_username_input;
    if ((state.name_cursor_timer div 25) % 2 == 0) {
        disp_input += "|";
    }
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(c_white);
    ui_text_scaled(960, input_y + input_h * 0.5, disp_input, 1.4);
    
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
    
    ui_box(conf_x, by, conf_x + conf_w, by + btn_h, conf_hov ? make_color_rgb(46, 204, 113) : make_color_rgb(39, 174, 96), conf_hov ? C_AMBER : c_white, 8);
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(conf_hov ? c_black : c_white);
    ui_text_scaled(conf_x + conf_w * 0.5, by + btn_h * 0.5, "CONTINUE TO WI-FI ROOMS >>", 1.1);
}

/// @desc Draws Public Room Browser for Local Wi-Fi Multiplayer
function ui_draw_online_browser_screen(state, mx, my) {
    ui_draw_screen_starfield(state);
    
    var con_x = 70;
    var con_y = 35;
    var con_w = 1780;
    var con_h = 1010;
    
    // Console Housing
    ui_box(con_x, con_y, con_x + con_w, con_y + con_h, make_color_rgb(16, 22, 32), make_color_rgb(44, 60, 84), 14);
    
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
    ui_box(con_x + 10, con_y + 10, con_x + con_w - 10, con_y + 70, make_color_rgb(24, 32, 48), make_color_rgb(52, 73, 94), 8);
    
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(0, 229, 255));
    ui_text_scaled(con_x + 30, con_y + 32, "LOCAL WI-FI MULTIPLAYER // PUBLIC ROOM BROWSER", 1.35);
    draw_set_color(make_color_rgb(140, 180, 215));
    draw_text(con_x + 30, con_y + 54, "Auto-discovering defense outpost rooms beaconing on local Wi-Fi subnet (UDP 6511 / TCP 6510).");
    
    // User Identity & Status Strip
    draw_set_halign(fa_right);
    draw_set_color(c_white);
    draw_text(con_x + con_w - 180, con_y + 32, "CALLSIGN: " + state.net_username);
    state.online_browser_edit_user_hover = ui_draw_button(con_x + con_w - 160, con_y + 18, 130, 28, "[Change]", true, false, mx, my);
    
    // Status message / pulsing green dot
    draw_set_color(make_color_rgb(46, 204, 113));
    draw_circle(con_x + con_w - 250, con_y + 54, 5, false);
    draw_set_color(make_color_rgb(160, 220, 180));
    draw_set_halign(fa_left);
    draw_text(con_x + con_w - 238, con_y + 54, (state.net_udp_listener >= 0) ? "Scanning for rooms..." : "Auto-discovery offline");
    
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
    
    ui_box(create_x, act_y, create_x + create_w, act_y + act_h, c_hov ? make_color_rgb(46, 204, 113) : make_color_rgb(39, 174, 96), c_hov ? C_AMBER : c_white, 8);
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(c_hov ? c_black : c_white);
    ui_text_scaled(create_x + create_w * 0.5, act_y + act_h * 0.5, "+ CREATE PUBLIC ROOM", 1.2);
    
    // Refresh Discovery Ping Button
    var ref_w = 210;
    var ref_x = create_x + create_w + 16;
    state.online_browser_refresh_hover = ui_draw_button(ref_x, act_y, ref_w, act_h, "REFRESH ROOMS [R]", true, false, mx, my);
    
    // Direct IP Connect Box (For local subnets / same machine multi-instance testing)
    var dir_w = 560;
    var dir_x = con_x + con_w - 30 - dir_w;
    ui_box(dir_x, act_y, dir_x + dir_w, act_y + act_h, make_color_rgb(20, 28, 42), make_color_rgb(52, 73, 94), 8);
    
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(140, 180, 220));
    draw_text(dir_x + 14, act_y + act_h * 0.5, "Direct IP:");
    
    // IP input textbox
    var ip_bx = dir_x + 95;
    var ip_bw = 250;
    var ip_bh = 38;
    var ip_by = act_y + (act_h - ip_bh) * 0.5;
    
    var is_editing_ip = state.net_direct_ip_editing;
    state.online_browser_ip_hover = ui_point_in_rect(mx, my, ip_bx, ip_by, ip_bw, ip_bh);
    if (state.online_browser_ip_hover && !is_editing_ip) state.hover_tooltip = "Click to type the host's IP address";
    ui_box(ip_bx, ip_by, ip_bx + ip_bw, ip_by + ip_bh, is_editing_ip ? make_color_rgb(32, 45, 68) : make_color_rgb(14, 18, 28), is_editing_ip ? C_AMBER : make_color_rgb(60, 85, 120), 6);
    
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
    
    ui_box(list_x, list_y, list_x + list_w, list_y + list_h, make_color_rgb(20, 26, 38), make_color_rgb(45, 60, 85), 10);
    
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
        ui_text_scaled(rad_cx, rad_cy + rad_r + 45, "SCANNING LOCAL WI-FI SUBNET FOR DEFENSE ROOMS...", 1.25);
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
            
            ui_box(list_x + 12, ry, list_x + list_w - 12, ry + r_row_h, make_color_rgb(24, 32, 48), make_color_rgb(45, 65, 95), 8);
            
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(C_AMBER);
            ui_text_scaled(list_x + 30, ry + r_row_h * 0.5, rm.room_name, 1.15);
            
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
    ui_box(con_x, con_y, con_x + con_w, con_y + con_h, make_color_rgb(16, 22, 32), make_color_rgb(44, 60, 84), 14);
    
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
    ui_box(con_x + 10, con_y + 10, con_x + con_w - 10, con_y + 70, make_color_rgb(24, 32, 48), make_color_rgb(52, 73, 94), 8);
    
    var num_joined = array_length(state.net_lobby_players);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_AMBER);
    ui_text_scaled(con_x + 30, con_y + 32, "TACTICAL DEFENSE OUTPOST // WI-FI MISSION LOBBY", 1.35);
    
    draw_set_color(make_color_rgb(140, 180, 215));
    var role_label = state.is_host ? "You are the host - launch when your squad is ready" : "Joined - waiting for the host to launch";
    var ip_hint = state.is_host ? ((state.net_local_ip != "") ? ("Friends can join by IP: " + state.net_local_ip) : "Friends on your Wi-Fi will see this room automatically") : ("Host: " + state.net_host_ip);
    draw_text(con_x + 30, con_y + 54, role_label + "   |   " + ip_hint);
    if (state.net_status_message != "") {
        draw_set_halign(fa_right);
        draw_set_color(C_FAINT);
        draw_text(con_x + con_w - 30, con_y + 96, state.net_status_message);
        draw_set_halign(fa_left);
    }
    
    draw_set_halign(fa_right);
    draw_set_color(make_color_rgb(0, 229, 255));
    ui_text_scaled(con_x + con_w - 30, con_y + 40, string(num_joined) + " / 4 OPERATIVES CONNECTED", 1.25);
    
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
        ui_box(sx, slot_y, sx + slot_w, slot_y + slot_h, is_occupied ? make_color_rgb(20, 26, 38) : make_color_rgb(14, 18, 26), is_occupied ? p_col : make_color_rgb(45, 60, 80), 10);
        if (is_occupied) {
            draw_roundrect_ext(sx + 1, slot_y + 1, sx + slot_w - 1, slot_y + slot_h - 1, 10, 10, true);
        }
        
        // Header Strip
        draw_set_color(is_occupied ? p_col : make_color_rgb(28, 38, 52));
        draw_roundrect_ext(sx + 4, slot_y + 4, sx + slot_w - 4, slot_y + 42, 6, 6, false);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(is_occupied ? c_black : make_color_rgb(140, 160, 180));
        ui_text_scaled(sx + 16, slot_y + 23, "OPERATIVE 0" + string(s + 1), 1.1);
        
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
            ui_box(sx + 16, nb_y, sx + slot_w - 16, nb_y + 48, make_color_rgb(14, 18, 28), is_me ? C_AMBER : make_color_rgb(60, 85, 120), 6);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(c_white);
            ui_text_scaled(sx + slot_w * 0.5, nb_y + 24, pl.name, 1.25);
            
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
                
                ui_box(cx_box, cyc_y, cx_box + cw_box, cyc_y + cyc_h, make_color_rgb(26, 36, 52), C_AMBER, 6);
                
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_set_color(C_AMBER);
                ui_text_scaled(cx_box + cw_box * 0.5, cyc_y + 18, p_class.name, 1.15);
                draw_set_color(make_color_rgb(100, 181, 246));
                draw_text(cx_box + cw_box * 0.5, cyc_y + 38, "// " + p_class.role + " //");
            } else {
                // Other connected players: read-only class plate
                ui_box(sx + 16, cyc_y, sx + slot_w - 16, cyc_y + cyc_h, make_color_rgb(24, 32, 46), make_color_rgb(52, 73, 94), 6);
                
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_set_color(c_white);
                ui_text_scaled(sx + slot_w * 0.5, cyc_y + 18, p_class.name, 1.15);
                draw_set_color(make_color_rgb(140, 180, 215));
                draw_text(sx + slot_w * 0.5, cyc_y + 38, "// " + p_class.role + " //");
            }
            
            // Class Emblem Box
            var em_y = cyc_y + cyc_h + 14;
            var em_h = 145;
            ui_box(sx + 16, em_y, sx + slot_w - 16, em_y + em_h, make_color_rgb(14, 18, 28), make_color_rgb(40, 56, 80), 8);
            ui_draw_class_emblem(sx + slot_w * 0.5, em_y + em_h * 0.5, p_class.id, p_col, true);
            
            // Tactical Perks Box
            var pk_y = em_y + em_h + 14;
            var pk_h = 240;
            var pk_w = slot_w - 32;
            var pk_x = sx + 16;
            
            ui_box(pk_x, pk_y, pk_x + pk_w, pk_y + pk_h, make_color_rgb(16, 22, 34), make_color_rgb(45, 62, 88), 8);
            
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            draw_set_color(make_color_rgb(0, 229, 255));
            draw_text(pk_x + 14, pk_y + 12, "[TACTICAL SPECIALTY]");
            
            draw_set_color(C_AMBER);
            draw_text(pk_x + 14, pk_y + 38, p_class.perk_tag);
            
            draw_set_color(c_white);
            ui_text_ext(pk_x + 14, pk_y + 68, p_class.desc, 20, pk_w - 28);
            
            // Connected Status Badge
            var stat_y = slot_y + slot_h - 75;
            ui_box(sx + 16, stat_y, sx + slot_w - 16, stat_y + 54, make_color_rgb(26, 44, 34), make_color_rgb(46, 204, 113), 8);
            
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
            ui_text_scaled(sx + slot_w * 0.5, wait_cy - 40, "?", 2.2);
            
            draw_set_color(make_color_rgb(120, 150, 185));
            ui_text_scaled(sx + slot_w * 0.5, wait_cy + 40, "WAITING FOR ALLY...", 1.15);
            
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
            ui_box(start_x, bottom_y, start_x + start_w, bottom_y + start_h, make_color_rgb(40, 45, 55), make_color_rgb(80, 85, 95), 10);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(make_color_rgb(170, 175, 185));
            ui_text_scaled(start_x + start_w * 0.5, bottom_y + start_h * 0.5, "WAITING FOR OPERATIVES (Need 2-4 Players to Launch)", 1.1);
        } else {
            // Active: Host can launch!
            ui_box(start_x, bottom_y, start_x + start_w, bottom_y + start_h, s_btn_hov ? make_color_rgb(46, 204, 113) : make_color_rgb(39, 174, 96), s_btn_hov ? C_AMBER : c_white, 10);
            draw_roundrect_ext(start_x + 1, bottom_y + 1, start_x + start_w - 1, bottom_y + start_h - 1, 10, 10, true);
            
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(s_btn_hov ? c_black : c_white);
            ui_text_scaled(start_x + start_w * 0.5, bottom_y + start_h * 0.5, "LAUNCH MISSION  -  " + string(num_joined) + " OPERATIVES   [ENTER]", 1.15);
        }
    } else {
        // Non-host Client view
        ui_box(start_x, bottom_y, start_x + start_w, bottom_y + start_h, make_color_rgb(26, 38, 56), make_color_rgb(0, 180, 216), 10);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        var client_msg = (num_joined < 2) ? "WAITING FOR ANOTHER ALLY TO JOIN (1/4)..." : "WAITING FOR HOST TO LAUNCH MISSION (" + string(num_joined) + "/4 Ready)...";
        ui_text_scaled(start_x + start_w * 0.5, bottom_y + start_h * 0.5, client_msg, 1.15);
    }
}




