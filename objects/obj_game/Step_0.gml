/// @desc obj_game Step Event
var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);
var clicked = mouse_check_button_pressed(mb_left);

// Network step update (LAN broadcast beacons, discovery pruning, timers)
network_step_update(game_state);

// Toast and popup notification timers
if (game_state.toast_timer > 0) {
    game_state.toast_timer--;
}
if (variable_struct_exists(game_state, "turn_popup_timer") && game_state.turn_popup_timer > 0) {
    game_state.turn_popup_timer--;
}
if (variable_struct_exists(game_state, "name_cursor_timer")) {
    game_state.name_cursor_timer++;
}

// Update combat impact effects & particle physics (Fireball blast, smoke clouds, sparks)
if (variable_struct_exists(game_state, "combat_impact_effects") && is_array(game_state.combat_impact_effects)) {
    for (var e = array_length(game_state.combat_impact_effects) - 1; e >= 0; e--) {
        var eff = game_state.combat_impact_effects[e];
        eff.life++;
        
        // Fireballs
        if (variable_struct_exists(eff, "fireballs")) {
            for (var fb_i = array_length(eff.fireballs) - 1; fb_i >= 0; fb_i--) {
                var fb = eff.fireballs[fb_i];
                fb.x += fb.vx;
                fb.y += fb.vy;
                fb.vx *= 0.91;
                fb.vy *= 0.91;
                fb.radius += fb.grow_rate;
                fb.life--;
                if (fb.life <= 0) array_delete(eff.fireballs, fb_i, 1);
            }
        }
        
        // Smoke puffs
        if (variable_struct_exists(eff, "smoke")) {
            for (var sm_i = array_length(eff.smoke) - 1; sm_i >= 0; sm_i--) {
                var sm = eff.smoke[sm_i];
                sm.x += sm.vx;
                sm.y += sm.vy;
                sm.vy -= 0.04; // rising heat draft
                sm.radius += sm.grow_rate;
                sm.life--;
                if (sm.life <= 0) array_delete(eff.smoke, sm_i, 1);
            }
        }
        
        // Sparks & debris
        for (var s = array_length(eff.sparks) - 1; s >= 0; s--) {
            var sp = eff.sparks[s];
            sp.x += sp.vx;
            sp.y += sp.vy;
            sp.vy += 0.14; // gravity
            sp.vx *= 0.95; // drag
            sp.life--;
            if (sp.life <= 0) array_delete(eff.sparks, s, 1);
        }
        
        if (eff.life >= eff.max_life) {
            array_delete(game_state.combat_impact_effects, e, 1);
        }
    }
}

// Update board action particle effects & expanding shockwaves
if (variable_struct_exists(game_state, "board_action_effects") && is_array(game_state.board_action_effects)) {
    for (var b = array_length(game_state.board_action_effects) - 1; b >= 0; b--) {
        var ba = game_state.board_action_effects[b];
        ba.life++;
        for (var p = array_length(ba.particles) - 1; p >= 0; p--) {
            var pt = ba.particles[p];
            pt.x += pt.vx;
            pt.y += pt.vy;
            pt.vy += pt.gravity;
            pt.vx *= 0.95;
            pt.life--;
            if (pt.life <= 0) array_delete(ba.particles, p, 1);
        }
        if (ba.life >= ba.max_life) {
            array_delete(game_state.board_action_effects, b, 1);
        }
    }
}

// Update floating text indicators (damage, resources, actions)
if (variable_struct_exists(game_state, "floating_texts") && is_array(game_state.floating_texts)) {
    for (var f = array_length(game_state.floating_texts) - 1; f >= 0; f--) {
        var ft = game_state.floating_texts[f];
        ft.life--;
        ft.y += ft.vy;
        ft.vy *= 0.96;
        ft.alpha = clamp(ft.life / (ft.max_life * 0.4), 0.0, 1.0);
        if (ft.life <= 0) {
            array_delete(game_state.floating_texts, f, 1);
        }
    }
}

// Update player pawn movement animation, hop, and action feedback
if (variable_struct_exists(game_state, "players") && is_array(game_state.players)) {
    for (var p_idx = 0; p_idx < array_length(game_state.players); p_idx++) {
        var pl = game_state.players[p_idx];
        
        // Action timer countdown
        if (variable_struct_exists(pl, "action_timer") && pl.action_timer > 0) {
            pl.action_timer--;
            if (pl.action_timer <= 0) {
                pl.action_anim = "";
            }
        }
        
        // Interpolated movement
        if (variable_struct_exists(pl, "is_moving") && pl.is_moving) {
            pl.move_progress = min(1.0, pl.move_progress + 0.07);
            var t = pl.move_progress;
            var smooth_t = t * t * (3.0 - 2.0 * t);
            pl.anim_x = lerp(pl.move_start_x, pl.target_x, smooth_t);
            pl.anim_y = lerp(pl.move_start_y, pl.target_y, smooth_t);
            pl.hop_y = -sin(t * pi) * 22;
            
            // Motion sparks while gliding
            if (random(1) < 0.25) {
                game_spawn_board_action_effect(game_state, pl.anim_x, pl.anim_y, "motion_spark", pl.color);
            }
            
            if (pl.move_progress >= 1.0) {
                pl.is_moving = false;
                pl.anim_x = pl.target_x;
                pl.anim_y = pl.target_y;
                pl.hop_y = 0;
                game_spawn_board_action_effect(game_state, pl.target_x, pl.target_y, "arrival_puff", pl.color);
            }
        }
    }
}

// Screen shake decay
if (variable_struct_exists(game_state, "screen_shake") && game_state.screen_shake > 0) {
    game_state.screen_shake = max(0, game_state.screen_shake - 0.5);
}

var active_p_idx = (game_state.is_online) ? game_state.net_my_player_idx : game_state.current_player_idx;
var cur_p = (active_p_idx >= 0 && active_p_idx < array_length(game_state.players)) ? game_state.players[active_p_idx] : game_state.players[0];

// ------------------------------------------------------------------
// WINDOW FOCUS & FULLSCREEN TOGGLE
// ------------------------------------------------------------------
// F11 toggles between Borderless Fullscreen and Windowed
if (keyboard_check_pressed(vk_f11)) {
    if (game_state.settings.display_mode == "windowed") {
        game_state.settings.display_mode = "borderless";
        var r = game_state.resolutions[game_state.settings.resolution_idx];
        game_apply_display_settings("borderless", r[0], r[1]);
        game_log(game_state, "Display Mode: Borderless Fullscreen (F11)");
        game_play_sfx("click");
    } else {
        game_state.settings.display_mode = "windowed";
        var r = game_state.resolutions[game_state.settings.resolution_idx];
        game_apply_display_settings("windowed", r[0], r[1]);
        game_log(game_state, "Display Mode: Windowed (F11)");
        game_play_sfx("click");
    }
}

// If player tabs out (loses window focus), switch to windowed mode
var cur_focus = window_has_focus();
if (cur_focus) {
    game_state.has_had_focus = true;
}
if (game_state.has_had_focus && !cur_focus && game_state.prev_window_focus) {
    if (game_state.settings.display_mode != "windowed") {
        game_state.settings.display_mode = "windowed";
        var r = game_state.resolutions[game_state.settings.resolution_idx];
        game_apply_display_settings("windowed", r[0], r[1]);
        game_log(game_state, "Switched to Windowed mode (Tabbed out).");
    }
}
game_state.prev_window_focus = cur_focus;

// ------------------------------------------------------------------
// 0. SETTINGS BUTTON (Top Right Header)
// ------------------------------------------------------------------
if (clicked && variable_struct_exists(game_state, "btn_settings_hover") && game_state.btn_settings_hover) {
    game_play_sfx("click");
    game_state.modal = { type: "settings" };
    return;
}

// ------------------------------------------------------------------
// 1. MODAL HANDLING
// ------------------------------------------------------------------
if (!is_undefined(game_state.modal)) {
    var m = game_state.modal;
    
    // Close button
    if (clicked && game_state.modal_close_hover) {
        game_play_sfx("click");
        game_state.modal = undefined;
        return;
    }
    
    // Escape key closes modal
    if (keyboard_check_pressed(vk_escape) && m.type != "player_setup" && m.type != "victory" && m.type != "game_over" && m.type != "tactical_combat") {
        game_play_sfx("click");
        game_state.modal = undefined;
        return;
    }
    
    if (m.type == "settings") {
        var mw = 840;
        var mh = 560;
        var mx0 = (1920 - mw) * 0.5;
        var my0 = (1080 - mh) * 0.5;
        
        var track_x = mx0 + 40;
        var track_y = my0 + 295;
        var track_w = mw - 250;
        var track_h = 18;
        
        // Handle dragging/clicking the SFX slider
        if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mx, my, track_x - 10, track_y - 12, track_x + track_w + 10, track_y + track_h + 12)) {
            game_state.settings.slider_dragging = true;
        }
        
        if (game_state.settings.slider_dragging) {
            if (mouse_check_button(mb_left)) {
                var new_vol = clamp((mx - track_x) / track_w, 0.0, 1.0);
                game_state.settings.sfx_volume = new_vol;
            } else {
                game_state.settings.slider_dragging = false;
                game_play_sfx("click");
            }
        }
        
        // Test SFX Button
        if (clicked && game_state.settings_test_sfx_hover) {
            game_play_sfx("coin");
            return;
        }
        
        // Display mode buttons
        if (clicked && game_state.settings_mode_borderless_hover) {
            game_state.settings.display_mode = "borderless";
            var r = game_state.resolutions[game_state.settings.resolution_idx];
            game_apply_display_settings("borderless", r[0], r[1]);
            game_play_sfx("click");
            return;
        }
        
        if (clicked && game_state.settings_mode_fullscreen_hover) {
            game_state.settings.display_mode = "fullscreen";
            var r = game_state.resolutions[game_state.settings.resolution_idx];
            game_apply_display_settings("fullscreen", r[0], r[1]);
            game_play_sfx("click");
            return;
        }
        
        if (clicked && game_state.settings_mode_windowed_hover) {
            game_state.settings.display_mode = "windowed";
            var r = game_state.resolutions[game_state.settings.resolution_idx];
            game_apply_display_settings("windowed", r[0], r[1]);
            game_play_sfx("click");
            return;
        }
        
        // Resolution buttons
        if (clicked && game_state.settings_res_hover >= 0) {
            var r_idx = game_state.settings_res_hover;
            game_state.settings.resolution_idx = r_idx;
            var r = game_state.resolutions[r_idx];
            if (game_state.settings.display_mode == "windowed") {
                game_apply_display_settings("windowed", r[0], r[1]);
            }
            game_play_sfx("click");
            return;
        }
        
        // Restart Game
        if (clicked && variable_struct_exists(game_state, "settings_restart_hover") && game_state.settings_restart_hover) {
            var old_s = game_state.settings;
            game_state = game_init_state(game_state.num_players, game_state.setup_player_classes, game_state.setup_player_names);
            game_state.settings = old_s;
            game_state.screen = "title";
            game_state.modal = undefined;
            game_play_sfx("click");
            game_log(game_state, "Returned to Title Screen.");
            return;
        }
        
        // Close / Apply
        if (clicked && (game_state.settings_close_hover || game_state.modal_close_hover)) {
            game_play_sfx("click");
            game_state.modal = undefined;
            return;
        }
        
        return;
    }
    
    if (m.type == "player_setup") {
        var char_classes = game_get_character_classes();
        var num_classes = array_length(char_classes);
        
        // Handle active keyboard typing into player name
        if (game_state.editing_player_name_idx >= 0) {
            var ep = game_state.editing_player_name_idx;
            
            // Confirm with Enter or Escape
            if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
                var clean_n = string_replace_all(game_state.setup_player_names[ep], " ", "");
                if (clean_n == "") game_state.setup_player_names[ep] = "Player " + string(ep + 1);
                game_state.editing_player_name_idx = -1;
                game_play_sfx("click");
            }
            else {
                // Update name from keyboard buffer (up to 14 chars)
                var max_chars = 14;
                if (string_length(keyboard_string) > max_chars) {
                    keyboard_string = string_copy(keyboard_string, 1, max_chars);
                }
                game_state.setup_player_names[ep] = keyboard_string;
            }
        }
        
        if (clicked) {
            // Check if user clicked a player name box to start editing
            var clicked_name_box = false;
            for (var p = 0; p < game_state.setup_player_count; p++) {
                if (game_state.setup_name_hover[p]) {
                    game_state.editing_player_name_idx = p;
                    keyboard_string = game_state.setup_player_names[p];
                    clicked_name_box = true;
                    game_play_sfx("click");
                    return;
                }
            }
            
            // If user clicked outside the active name box, finish editing
            if (!clicked_name_box && game_state.editing_player_name_idx >= 0) {
                var ep = game_state.editing_player_name_idx;
                var clean_n = string_replace_all(game_state.setup_player_names[ep], " ", "");
                if (clean_n == "") game_state.setup_player_names[ep] = "Player " + string(ep + 1);
                game_state.editing_player_name_idx = -1;
            }
            
            // 1. Select player count
            for (var c = 0; c < 4; c++) {
                if (game_state.setup_count_hover[c]) {
                    game_state.setup_player_count = c + 1;
                    game_play_sfx("click");
                    return;
                }
            }
            
            // 2. Select / Cycle character role for each player
            for (var p = 0; p < game_state.setup_player_count; p++) {
                if (game_state.setup_prev_hover[p]) {
                    game_state.setup_player_classes[p] = (game_state.setup_player_classes[p] - 1 + num_classes) % num_classes;
                    if (variable_struct_exists(game_state, "setup_scroll_x")) game_state.setup_scroll_x[p] = 0;
                    game_play_sfx("click");
                    return;
                }
                if (game_state.setup_next_hover[p]) {
                    game_state.setup_player_classes[p] = (game_state.setup_player_classes[p] + 1) % num_classes;
                    if (variable_struct_exists(game_state, "setup_scroll_x")) game_state.setup_scroll_x[p] = 0;
                    game_play_sfx("click");
                    return;
                }
                if (variable_struct_exists(game_state, "setup_scroll_left_hover") && game_state.setup_scroll_left_hover[p]) {
                    game_state.setup_scroll_x[p] = max(0, game_state.setup_scroll_x[p] - 50);
                    game_play_sfx("click");
                    return;
                }
                if (variable_struct_exists(game_state, "setup_scroll_right_hover") && game_state.setup_scroll_right_hover[p]) {
                    game_state.setup_scroll_x[p] += 50;
                    game_play_sfx("click");
                    return;
                }
            }
            
            // 3. Deploy Team / Start Game
            if (game_state.setup_start_hover) {
                var old_s = game_state.settings;
                if (variable_struct_exists(game_state, "setup_surf") && is_array(game_state.setup_surf)) {
                    for (var s = 0; s < array_length(game_state.setup_surf); s++) {
                        if (!is_undefined(game_state.setup_surf[s]) && surface_exists(game_state.setup_surf[s])) {
                            surface_free(game_state.setup_surf[s]);
                            game_state.setup_surf[s] = undefined;
                        }
                    }
                }
                game_apply_setup_roster(game_state);
                game_state.settings = old_s;
                game_state.modal = undefined;
                game_play_sfx("buy");
                return;
            }
        }
        return;
    }
    
    if (m.type == "shop" && clicked) {
        if (variable_struct_exists(game_state, "shop_reroll_hover") && game_state.shop_reroll_hover) {
            game_reroll_shop(game_state, cur_p);
            if (game_state.is_online) network_broadcast_action(game_state, "action_shop_reroll", {});
            return;
        }
        if (variable_struct_exists(game_state, "shop_buy_hover") && game_state.shop_buy_hover >= 0) {
            var slot_idx = game_state.shop_buy_hover;
            game_player_buy_blueprint(game_state, cur_p, slot_idx);
            if (game_state.is_online) network_broadcast_action(game_state, "action_shop_buy", { item_idx: slot_idx });
            return;
        }
    }
    
    if (m.type == "town" && clicked && game_state.town_sell_hover >= 0) {
        var trade_keys = ["wood", "scrap", "stone", "metal", "crystals", "power_gem"];
        var rk = trade_keys[game_state.town_sell_hover];
        var cnt = game_state[$ "town_sell_count"] ?? 1;
        game_player_town_trade(game_state, cur_p, rk, cnt);
        if (game_state.is_online) network_broadcast_action(game_state, "action_trade", { resource: rk, count: cnt });
        return;
    }
    
    if (m.type == "repair" || m.type == "workstation") {
        var ws_mx0 = (1920 - 1180) * 0.5;
        var ws_my0 = (1080 - 650) * 0.5;
        var ws_col1_x = ws_mx0 + 30;
        var ws_col1_w = 550;
        var in_ws_bp_bounds = (mx >= ws_col1_x && mx <= ws_col1_x + ws_col1_w && my >= ws_my0 + 112 && my <= ws_my0 + 600);
        var max_scr = variable_struct_exists(game_state, "workstation_bp_max_scroll") ? game_state.workstation_bp_max_scroll : 0;
        
        if (in_ws_bp_bounds) {
            if (mouse_wheel_up()) {
                game_state.workstation_bp_scroll_y = max(0, game_state.workstation_bp_scroll_y - 48);
            } else if (mouse_wheel_down()) {
                game_state.workstation_bp_scroll_y = min(max_scr, game_state.workstation_bp_scroll_y + 48);
            }
        }
        
        if (clicked && variable_struct_exists(game_state, "workstation_bp_thumb_hover") && game_state.workstation_bp_thumb_hover) {
            game_state.workstation_bp_drag = true;
            game_state.workstation_bp_drag_start_my = my;
            game_state.workstation_bp_drag_start_val = game_state.workstation_bp_scroll_y;
            return;
        }
        
        if (clicked) {
            if (variable_struct_exists(game_state, "workstation_craft_bp_idx") && game_state.workstation_craft_bp_idx >= 0 &&
                variable_struct_exists(game_state, "workstation_craft_target_tower") && game_state.workstation_craft_target_tower >= 0) {
                var c_bp = game_state.workstation_craft_bp_idx;
                var c_tw = game_state.workstation_craft_target_tower;
                game_player_craft_blueprint(game_state, cur_p, c_bp, c_tw);
                if (game_state.is_online) network_broadcast_action(game_state, "action_craft", { bp_idx: c_bp, target_tower: c_tw });
                return;
            }
            if (game_state.repair_tower_1_hover >= 0) {
                var r1_tow = game_state.repair_tower_1_hover;
                game_player_repair_tower(game_state, cur_p, r1_tow, "stone_wood");
                if (game_state.is_online) network_broadcast_action(game_state, "action_repair_tower", { tower_idx: r1_tow, method: "stone_wood" });
                return;
            } else if (game_state.repair_tower_3_hover >= 0) {
                var r3_tow = game_state.repair_tower_3_hover;
                game_player_repair_tower(game_state, cur_p, r3_tow, "metal_or_scrap_stone");
                if (game_state.is_online) network_broadcast_action(game_state, "action_repair_tower", { tower_idx: r3_tow, method: "metal_or_scrap_stone" });
                return;
            } else if (game_state.repair_weapon_hover >= 0) {
                var tow_idx = game_state.repair_weapon_hover;
                if (tow_idx >= 0 && tow_idx < 4 && !is_undefined(game_state.towers[tow_idx].weapon) && game_state.towers[tow_idx].weapon.alive) {
                    var w = game_state.towers[tow_idx].weapon;
                    var rnames = variable_struct_get_names(w.cost_res);
                    var first_res = (array_length(rnames) > 0) ? rnames[0] : "metal";
                    var wep_idx = 0;
                    for (var wi = 0; wi < array_length(game_state.weapons); wi++) {
                        if (game_state.weapons[wi] == w) { wep_idx = wi; break; }
                    }
                    game_player_repair_weapon(game_state, cur_p, wep_idx, "recipe_resource", first_res);
                    if (game_state.is_online) network_broadcast_action(game_state, "action_repair_weapon", { tower_idx: tow_idx, res_choice: first_res });
                }
                return;
            }
        }
    }
    
    if (m.type == "alien_inspect" && clicked) {
        if (game_state.alien_inspect_close_hover || game_state.modal_close_hover) {
            game_state.modal = undefined;
            game_play_sfx("click");
            return;
        }
    }
    
    if (m.type == "tactical_combat") {
        // Toggle 2x Speed button in Top Right of Attack UI
        if (clicked && variable_struct_exists(game_state, "combat_speed_btn_hover") && game_state.combat_speed_btn_hover) {
            game_state.combat_speed_2x = !game_state.combat_speed_2x;
            game_play_sfx("click");
            return;
        }
        
        var spd_mult = (variable_struct_exists(game_state, "combat_speed_2x") && game_state.combat_speed_2x) ? 2.0 : 1.0;
        
        // 1. Update in-flight player projectiles
        if (variable_struct_exists(game_state, "combat_player_projectiles") && is_array(game_state.combat_player_projectiles)) {
            var num_pp = array_length(game_state.combat_player_projectiles);
            for (var p = num_pp - 1; p >= 0; p--) {
                var pp = game_state.combat_player_projectiles[p];
                pp.progress += pp.speed * spd_mult;
                if (pp.progress >= 1.0) {
                    // Find target alien
                    var tgt_idx = -1;
                    for (var a = 0; a < array_length(game_state.active_zone); a++) {
                        if (game_state.active_zone[a].uid == pp.target_uid) {
                            tgt_idx = a;
                            break;
                        }
                    }
                    if (tgt_idx < 0 && pp.target_idx < array_length(game_state.active_zone)) {
                        tgt_idx = pp.target_idx;
                    }
                    
                    var imp_x = (tgt_idx >= 0 && tgt_idx < array_length(game_state.combat_alien_coords)) ? game_state.combat_alien_coords[tgt_idx][0] : 960;
                    var imp_y = (tgt_idx >= 0 && tgt_idx < array_length(game_state.combat_alien_coords)) ? (game_state.combat_alien_coords[tgt_idx][1] - 110) : 220;
                    
                    game_spawn_combat_impact_effect(game_state, imp_x, imp_y, "player", pp.catalog_id);
                    game_state.screen_shake = max(game_state.screen_shake, 6);
                    game_play_sfx("hit");
                    
                    if (tgt_idx >= 0) {
                        game_apply_weapon_damage(game_state, pp.weapon, tgt_idx);
                    }
                    
                    array_delete(game_state.combat_player_projectiles, p, 1);
                    
                    // Check if all active aliens were wiped out!
                    if (array_length(game_state.active_zone) == 0) {
                        game_log(game_state, "All active aliens eliminated! Base is secured.");
                        game_state.combat_subphase = "combat_concluded";
                        game_state.combat_concluded_reason = "aliens_eradicated";
                    } else {
                        // Check if all 4 weapons have finished their attacks and no projectiles left
                        var all_greyed = true;
                        for (var i = 0; i < 4; i++) {
                            if (!game_state.tower_weapon_used[i]) all_greyed = false;
                        }
                        if (all_greyed && array_length(game_state.combat_player_projectiles) == 0) {
                            game_log(game_state, "All mounted weapons have completed their attacks! Alien retaliation incoming!");
                            game_start_alien_attack_phase(game_state);
                        }
                    }
                }
            }
        }
        
        // 2. Swarm Retaliation (alien projectiles)
        if (game_state.combat_subphase == "alien_attacks") {
            var num_p = array_length(game_state.combat_projectiles);
            for (var p = num_p - 1; p >= 0; p--) {
                var proj = game_state.combat_projectiles[p];
                proj.progress += proj.speed * spd_mult;
                if (proj.progress >= 1.0) {
                    game_apply_projectile_impact(game_state, proj);
                    array_delete(game_state.combat_projectiles, p, 1);
                }
            }
            
            // If all current projectiles have landed
            if (array_length(game_state.combat_projectiles) == 0) {
                if (game_state.alien_attack_delay > 0) {
                    game_state.alien_attack_delay = max(0, game_state.alien_attack_delay - (game_state.combat_speed_2x ? 2 : 1));
                } else {
                    var launched = game_spawn_next_alien_projectile(game_state);
                    if (launched) {
                        game_state.alien_attack_delay = game_state.combat_speed_2x ? 9 : 18;
                    } else {
                        // All attacking aliens have completed their turns! Transition to combat concluded
                        game_state.combat_subphase = "combat_concluded";
                        game_state.combat_concluded_reason = "retaliation_ended";
                    }
                }
            }
            return;
        }
        
        // 3. Combat Concluded (Waiting for player to press button to close UI menu)
        if (game_state.combat_subphase == "combat_concluded") {
            var do_conclude = false;
            if (clicked && variable_struct_exists(game_state, "combat_conclude_btn_hover") && game_state.combat_conclude_btn_hover) {
                do_conclude = true;
            } else if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
                do_conclude = true;
            }
            
            if (do_conclude) {
                game_play_sfx("click");
                if (game_state.round_number >= 17 && !game_state.endless_mode && array_length(game_state.active_zone) == 0 && array_length(game_state.spawn_zone) == 0) {
                    game_state.phase = "victory";
                    game_state.modal = { type: "victory" };
                    game_play_sfx("victory");
                    return;
                } else {
                    game_state.modal = undefined;
                    if (game_state.phase != "game_over") {
                        game_advance_wave_phase(game_state);
                        if (game_state.is_online) network_broadcast_action(game_state, "action_conclude_combat", {});
                    }
                    return;
                }
            }
            return;
        }
        
        // 4. Player Weapons Attack Interactions
        if (game_state.combat_subphase == "player_weapons" && clicked) {
            // 1. Advance to alien attacks button
            if (variable_struct_exists(game_state, "combat_advance_hover") && game_state.combat_advance_hover) {
                game_play_sfx("click");
                game_start_alien_attack_phase(game_state);
                return;
            }
            
            // 2. Tesla Discharge button
            if (variable_struct_exists(game_state, "combat_tesla_btn_hover") && game_state.combat_tesla_btn_hover) {
                game_combat_discharge_tesla(game_state);
                return;
            }
            
            // 3. Tower weapon card clicked at the bottom
            if (variable_struct_exists(game_state, "combat_tower_hover") && is_array(game_state.combat_tower_hover)) {
                for (var t = 0; t < 4; t++) {
                    if (game_state.combat_tower_hover[t]) {
                        game_combat_select_tower(game_state, t);
                        return;
                    }
                }
            }
            
            // 4. Active alien clicked at the top
            if (variable_struct_exists(game_state, "combat_alien_hover") && game_state.combat_alien_hover >= 0) {
                var cur_tow = game_state.combat_selected_tower;
                var tgt_idx = game_state.combat_alien_hover;
                game_combat_fire_tower_at_alien(game_state, tgt_idx);
                if (game_state.is_online) network_broadcast_action(game_state, "action_fire_weapon", { tower_idx: cur_tow, target_idx: tgt_idx });
                return;
            }
            return;
        }
        return;
    }
    
    if (m.type == "victory" && clicked) {
        if (game_state.victory_endless_hover) {
            game_state.endless_mode = true;
            game_state.modal = undefined;
            game_play_sfx("click");
            game_advance_wave_phase(game_state);
            return;
        } else if (game_state.victory_restart_hover) {
            var old_s = game_state.settings;
            game_state = game_init_state(game_state.num_players, game_state.setup_player_classes, game_state.setup_player_names);
            game_state.settings = old_s;
            game_state.screen = "title";
            game_state.modal = undefined;
            game_play_sfx("click");
            return;
        } else if (variable_struct_exists(game_state, "victory_exit_hover") && game_state.victory_exit_hover) {
            game_play_sfx("click");
            game_end();
            return;
        }
    }
    
    if (m.type == "game_over" && clicked) {
        if (variable_struct_exists(game_state, "gameover_restart_hover") && game_state.gameover_restart_hover) {
            var old_s = game_state.settings;
            game_state = game_init_state(game_state.num_players, game_state.setup_player_classes, game_state.setup_player_names);
            game_state.settings = old_s;
            game_state.screen = "title";
            game_state.modal = undefined;
            game_play_sfx("click");
            return;
        }
        if (variable_struct_exists(game_state, "gameover_quit_hover") && game_state.gameover_quit_hover) {
            game_play_sfx("click");
            game_end();
            return;
        }
    }
    
    return; // Block background interaction while modal is open
}

// ------------------------------------------------------------------
// SCREEN INPUT ROUTING (TITLE, LOCAL SETUP, ONLINE MULTIPLAYER)
// ------------------------------------------------------------------
if (game_state.screen != "game") {
    switch (game_state.screen) {
        case "title": {
            if (clicked) {
                if (game_state.title_btn_local_hover) {
                    game_play_sfx("click");
                    game_state.screen = "local_setup";
                    return;
                }
                if (game_state.title_btn_online_hover) {
                    game_play_sfx("click");
                    game_state.screen = "online_username";
                    keyboard_string = game_state.net_username;
                    return;
                }
                if (game_state.title_btn_settings_hover) {
                    game_play_sfx("click");
                    game_state.modal = { type: "settings" };
                    return;
                }
                if (game_state.title_btn_quit_hover) {
                    game_play_sfx("click");
                    game_end();
                    return;
                }
            }
            if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter)) {
                game_play_sfx("click");
                game_state.screen = "local_setup";
                return;
            }
            break;
        }
        
        case "local_setup": {
            var char_classes = game_get_character_classes();
            var num_classes = array_length(char_classes);
            
            // Callsign keyboard input
            if (game_state.editing_player_name_idx >= 0) {
                var ep = game_state.editing_player_name_idx;
                if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
                    var clean_n = string_replace_all(game_state.setup_player_names[ep], " ", "");
                    if (clean_n == "") game_state.setup_player_names[ep] = "Player " + string(ep + 1);
                    game_state.editing_player_name_idx = -1;
                    game_play_sfx("click");
                } else {
                    var max_chars = 14;
                    if (string_length(keyboard_string) > max_chars) {
                        keyboard_string = string_copy(keyboard_string, 1, max_chars);
                    }
                    game_state.setup_player_names[ep] = keyboard_string;
                }
            }
            
            if (clicked) {
                var clicked_name_box = false;
                for (var p = 0; p < game_state.setup_player_count; p++) {
                    if (game_state.local_setup_name_hover[p]) {
                        game_state.editing_player_name_idx = p;
                        keyboard_string = game_state.setup_player_names[p];
                        clicked_name_box = true;
                        game_play_sfx("click");
                        return;
                    }
                }
                if (!clicked_name_box && game_state.editing_player_name_idx >= 0) {
                    var ep = game_state.editing_player_name_idx;
                    var clean_n = string_replace_all(game_state.setup_player_names[ep], " ", "");
                    if (clean_n == "") game_state.setup_player_names[ep] = "Player " + string(ep + 1);
                    game_state.editing_player_name_idx = -1;
                }
                
                // Select squad count
                for (var c = 0; c < 4; c++) {
                    if (game_state.local_setup_count_hover[c]) {
                        game_state.setup_player_count = c + 1;
                        game_play_sfx("click");
                        return;
                    }
                }
                
                // Prev/Next Class Cyclers (No duplicate non-default classes)
                for (var p = 0; p < game_state.setup_player_count; p++) {
                    if (game_state.local_setup_prev_hover[p]) {
                        game_state.setup_player_classes[p] = game_cycle_class_exclusive(game_state.setup_player_classes[p], -1, p, game_state.setup_player_classes);
                        game_play_sfx("click");
                        return;
                    }
                    if (game_state.local_setup_next_hover[p]) {
                        game_state.setup_player_classes[p] = game_cycle_class_exclusive(game_state.setup_player_classes[p], 1, p, game_state.setup_player_classes);
                        game_play_sfx("click");
                        return;
                    }
                }
                
                // Back to Title
                if (game_state.local_setup_back_hover) {
                    game_play_sfx("click");
                    game_state.screen = "title";
                    return;
                }
                
                // Launch Mission / Deploy Strike Team
                if (game_state.local_setup_start_hover) {
                    game_apply_setup_roster(game_state);
                    game_state.screen = "game";
                    game_state.modal = undefined;
                    game_play_sfx("buy");
                    return;
                }
            }
            
            // Keyboard Shortcuts
            if (game_state.editing_player_name_idx < 0) {
                if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter)) {
                    game_apply_setup_roster(game_state);
                    game_state.screen = "game";
                    game_state.modal = undefined;
                    game_play_sfx("buy");
                    return;
                }
                if (keyboard_check_pressed(vk_escape)) {
                    game_play_sfx("click");
                    game_state.screen = "title";
                    return;
                }
            }
            break;
        }
        
        case "online_username": {
            var max_chars = 14;
            if (string_length(keyboard_string) > max_chars) {
                keyboard_string = string_copy(keyboard_string, 1, max_chars);
            }
            game_state.net_username_input = keyboard_string;
            
            var do_confirm = false;
            if (keyboard_check_pressed(vk_enter)) do_confirm = true;
            if (clicked && game_state.online_user_confirm_hover) do_confirm = true;
            
            if (do_confirm) {
                var clean_u = string_replace_all(game_state.net_username_input, " ", "");
                if (clean_u != "") {
                    game_state.net_username = game_state.net_username_input;
                    network_start_browsing(game_state);
                    game_play_sfx("click");
                    return;
                } else {
                    game_state.net_error_message = "Please enter a valid callsign.";
                    game_state.net_error_timer = 180;
                    game_play_sfx("error");
                    return;
                }
            }
            
            if (keyboard_check_pressed(vk_escape) || (clicked && game_state.online_user_back_hover)) {
                game_play_sfx("click");
                game_state.screen = "title";
                return;
            }
            break;
        }
        
        case "online_browser": {
            if (clicked) {
                // Create Public Room
                if (game_state.online_browser_create_hover) {
                    network_start_hosting(game_state);
                    return;
                }
                
                // Refresh Rooms
                if (game_state.online_browser_refresh_hover) {
                    game_state.net_discovered_rooms = [];
                    network_broadcast_udp(game_state.net_udp_broadcaster, NET_PORT_UDP, { type: "room_ping" });
                    game_play_sfx("click");
                    return;
                }
                
                // Change Username
                if (game_state.online_browser_edit_user_hover) {
                    game_state.screen = "online_username";
                    keyboard_string = game_state.net_username;
                    game_play_sfx("click");
                    return;
                }
                
                // Back to Title
                if (game_state.online_browser_back_hover) {
                    network_cleanup_sockets(game_state);
                    game_state.screen = "title";
                    game_play_sfx("click");
                    return;
                }
                
                // Join Discovered Room
                if (game_state.online_browser_room_hover >= 0 && game_state.online_browser_room_hover < array_length(game_state.net_discovered_rooms)) {
                    var rm = game_state.net_discovered_rooms[game_state.online_browser_room_hover];
                    network_connect_to_room(game_state, rm.ip, rm.port);
                    return;
                }
                
                // Direct IP Connect
                if (game_state.online_browser_direct_hover) {
                    var target_ip = string_replace_all(game_state.net_direct_ip_input, " ", "");
                    if (target_ip != "") {
                        network_connect_to_room(game_state, target_ip, NET_PORT_TCP);
                        return;
                    }
                }
            }
            
            if (keyboard_check_pressed(ord("R"))) {
                game_state.net_discovered_rooms = [];
                network_broadcast_udp(game_state.net_udp_broadcaster, NET_PORT_UDP, { type: "room_ping" });
                game_play_sfx("click");
                return;
            }
            
            if (keyboard_check_pressed(vk_escape)) {
                network_cleanup_sockets(game_state);
                game_state.screen = "title";
                game_play_sfx("click");
                return;
            }
            break;
        }
        
        case "online_lobby": {
            var num_classes = array_length(game_get_character_classes());
            var char_classes = game_get_character_classes();
            var my_idx = game_state.net_my_player_idx;
            
            if (clicked) {
                // Local player class cycler
                if (my_idx >= 0 && my_idx < array_length(game_state.net_lobby_players)) {
                    var cur_c_id = game_state.net_lobby_players[my_idx].character_id;
                    var cur_ci = 0;
                    for (var ci = 0; ci < num_classes; ci++) {
                        if (char_classes[ci].id == cur_c_id) { cur_ci = ci; break; }
                    }
                    
                    if (game_state.online_lobby_prev_hover) {
                        var new_ci = game_cycle_class_exclusive(cur_ci, -1, my_idx, game_state.net_lobby_players);
                        network_lobby_change_character(game_state, char_classes[new_ci].id);
                        game_play_sfx("click");
                        return;
                    }
                    if (game_state.online_lobby_next_hover) {
                        var new_ci = game_cycle_class_exclusive(cur_ci, 1, my_idx, game_state.net_lobby_players);
                        network_lobby_change_character(game_state, char_classes[new_ci].id);
                        game_play_sfx("click");
                        return;
                    }
                }
                
                // Leave Room
                if (game_state.online_lobby_leave_hover) {
                    network_cleanup_sockets(game_state);
                    network_start_browsing(game_state);
                    game_state.screen = "online_browser";
                    game_play_sfx("click");
                    return;
                }
                
                // Host Start Mission (Requirement: at least 1 other player joined -> >= 2 players)
                if (game_state.online_lobby_start_hover && game_state.is_host && array_length(game_state.net_lobby_players) >= 2) {
                    network_host_start_mission(game_state);
                    return;
                }
            }
            
            // Space or Enter launches if Host and >= 2 players
            if ((keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter)) && game_state.is_host && array_length(game_state.net_lobby_players) >= 2) {
                network_host_start_mission(game_state);
                return;
            }
            
            if (keyboard_check_pressed(vk_escape)) {
                network_cleanup_sockets(game_state);
                network_start_browsing(game_state);
                game_state.screen = "online_browser";
                game_play_sfx("click");
                return;
            }
            break;
        }
    }
    
    return; // Don't process in-game board clicks or shortcuts when outside of match!
}

// ------------------------------------------------------------------
// 1.5 ACTION & COMBAT LOG (EXPAND, RESIZE DRAG & 2D SCROLL)
// ------------------------------------------------------------------
var in_action_log_bounds = point_in_rectangle(mx, my, game_state.action_log_x, 362, 1900, 622);

// Mouse wheel scrolling inside the log box
var wheel_up = mouse_wheel_up();
var wheel_down = mouse_wheel_down();
if ((wheel_up || wheel_down) && in_action_log_bounds) {
    if (keyboard_check(vk_shift)) {
        game_state.action_log_scroll_x = clamp(game_state.action_log_scroll_x + (wheel_down - wheel_up) * 48, 0, game_state.action_log_max_scroll_x);
    } else {
        game_state.action_log_scroll_y = clamp(game_state.action_log_scroll_y + (wheel_down - wheel_up) * 36, 0, game_state.action_log_max_scroll_y);
    }
}

// Left border drag handle start
if (clicked && variable_struct_exists(game_state, "action_log_resizer_hover") && game_state.action_log_resizer_hover) {
    game_state.action_log_dragging = true;
    game_state.action_log_drag_start_mx = mx;
    game_state.action_log_drag_start_x = game_state.action_log_x;
    return;
}

// Vertical scrollbar thumb drag start
if (clicked && variable_struct_exists(game_state, "action_log_v_thumb_hover") && game_state.action_log_v_thumb_hover) {
    game_state.action_log_v_drag = true;
    game_state.action_log_v_drag_start_my = my;
    game_state.action_log_v_drag_start_val = game_state.action_log_scroll_y;
    return;
}

// Horizontal scrollbar thumb drag start
if (clicked && variable_struct_exists(game_state, "action_log_h_thumb_hover") && game_state.action_log_h_thumb_hover) {
    game_state.action_log_h_drag = true;
    game_state.action_log_h_drag_start_mx = mx;
    game_state.action_log_h_drag_start_val = game_state.action_log_scroll_x;
    return;
}

// Header buttons
if (clicked && variable_struct_exists(game_state, "action_log_btn_toggle_hover") && game_state.action_log_btn_toggle_hover) {
    game_state.action_log_x = (game_state.action_log_x < 1400) ? 1520 : 800;
    game_play_sfx("click");
    return;
}
if (clicked && variable_struct_exists(game_state, "action_log_btn_top_hover") && game_state.action_log_btn_top_hover) {
    game_state.action_log_scroll_y = 0;
    game_state.action_log_scroll_x = 0;
    game_play_sfx("click");
    return;
}
if (clicked && variable_struct_exists(game_state, "action_log_btn_up_hover") && game_state.action_log_btn_up_hover) {
    game_state.action_log_scroll_y = max(0, game_state.action_log_scroll_y - 48);
    return;
}
if (clicked && variable_struct_exists(game_state, "action_log_btn_down_hover") && game_state.action_log_btn_down_hover) {
    game_state.action_log_scroll_y = min(game_state.action_log_max_scroll_y, game_state.action_log_scroll_y + 48);
    return;
}
if (clicked && variable_struct_exists(game_state, "action_log_btn_left_hover") && game_state.action_log_btn_left_hover) {
    game_state.action_log_scroll_x = max(0, game_state.action_log_scroll_x - 60);
    return;
}
if (clicked && variable_struct_exists(game_state, "action_log_btn_right_hover") && game_state.action_log_btn_right_hover) {
    game_state.action_log_scroll_x = min(game_state.action_log_max_scroll_x, game_state.action_log_scroll_x + 60);
    return;
}

// Drag updates while holding mb_left
if (mouse_check_button(mb_left)) {
    if (game_state.action_log_dragging) {
        var delta = mx - game_state.action_log_drag_start_mx;
        game_state.action_log_x = clamp(game_state.action_log_drag_start_x + delta, 250, 1520);
    }
    if (game_state.action_log_v_drag) {
        var delta_y = my - game_state.action_log_v_drag_start_my;
        var usable_track_h = variable_struct_exists(game_state, "action_log_usable_v_track") ? game_state.action_log_usable_v_track : max(1, 194 - 30);
        game_state.action_log_scroll_y = clamp(game_state.action_log_v_drag_start_val + (delta_y / usable_track_h) * game_state.action_log_max_scroll_y, 0, game_state.action_log_max_scroll_y);
    }
    if (game_state.action_log_h_drag) {
        var delta_x = mx - game_state.action_log_h_drag_start_mx;
        var usable_track_w = variable_struct_exists(game_state, "action_log_usable_h_track") ? game_state.action_log_usable_h_track : max(1, (1900 - game_state.action_log_x - 50));
        game_state.action_log_scroll_x = clamp(game_state.action_log_h_drag_start_val + (delta_x / usable_track_w) * game_state.action_log_max_scroll_x, 0, game_state.action_log_max_scroll_x);
    }
    if (variable_struct_exists(game_state, "workstation_bp_drag") && game_state.workstation_bp_drag) {
        var ws_delta_y = my - game_state.workstation_bp_drag_start_my;
        var ws_usable_track = variable_struct_exists(game_state, "workstation_bp_usable_track") ? game_state.workstation_bp_usable_track : 1;
        var ws_max_scr = variable_struct_exists(game_state, "workstation_bp_max_scroll") ? game_state.workstation_bp_max_scroll : 0;
        game_state.workstation_bp_scroll_y = clamp(game_state.workstation_bp_drag_start_val + (ws_delta_y / ws_usable_track) * ws_max_scr, 0, ws_max_scr);
    }
}
if (mouse_check_button_released(mb_left)) {
    game_state.action_log_dragging = false;
    game_state.action_log_v_drag = false;
    game_state.action_log_h_drag = false;
    game_state.workstation_bp_drag = false;
}

// -------------------------------------------------------------
// LIVE CHAT INPUT & TICKER INTERACTION
// -------------------------------------------------------------
if (variable_struct_exists(game_state, "chat_cursor_timer")) {
    game_state.chat_cursor_timer++;
} else {
    game_state.chat_cursor_timer = 0;
}

// Clicking the chat bar activates input
if (clicked && variable_struct_exists(game_state, "chat_input_hover") && game_state.chat_input_hover) {
    game_state.chat_input_active = true;
    keyboard_string = game_state.chat_input_text;
    game_play_sfx("click");
    return;
}

// Clicking SEND or pressing Enter delivers chat message
var send_clicked = (clicked && variable_struct_exists(game_state, "chat_send_hover") && game_state.chat_send_hover);
var enter_pressed = keyboard_check_pressed(vk_enter);

if (variable_struct_exists(game_state, "chat_input_active") && game_state.chat_input_active) {
    game_state.chat_input_text = string_copy(keyboard_string, 1, 60);
    
    if (enter_pressed || send_clicked) {
        var msg_to_send = string_trim(game_state.chat_input_text);
        if (msg_to_send != "") {
            var my_name = cur_p.name;
            if (game_state.is_online && variable_struct_exists(game_state, "net_username") && game_state.net_username != "") {
                my_name = game_state.net_username;
            }
            game_log(game_state, "[CHAT] " + my_name + ": " + msg_to_send);
            if (game_state.is_online) {
                network_broadcast_action(game_state, "action_chat", { sender: my_name, text: msg_to_send });
            }
            game_play_sfx("coin");
        }
        game_state.chat_input_text = "";
        keyboard_string = "";
        game_state.chat_input_active = false;
        return;
    }
    
    if (keyboard_check_pressed(vk_escape)) {
        game_state.chat_input_active = false;
        return;
    }
    
    // While typing chat, do not trigger board shortcuts
    return;
} else if (enter_pressed && is_undefined(game_state.modal)) {
    // Pressing Enter when chat is idle focuses chat bar
    game_state.chat_input_active = true;
    keyboard_string = game_state.chat_input_text;
    game_play_sfx("click");
    return;
}

// Absorbing general clicks inside action log area so underlying map or elements aren't triggered
if (clicked && in_action_log_bounds) {
    return;
}

// Escape key when no modal is open toggles Settings modal
if (keyboard_check_pressed(vk_escape)) {
    game_play_sfx("click");
    game_state.modal = { type: "settings" };
    return;
}

// ------------------------------------------------------------------
// ONLINE ASYNCHRONOUS MULTIPLAYER RESTRICTION
// In online multiplayer, players act asynchronously on their own pawn.
// Once an operative runs out of energy or completes their turn, block further actions.
// ------------------------------------------------------------------
if (game_state.is_online && (cur_p.ended_turn || cur_p.energy <= 0)) {
    if (clicked || keyboard_check_pressed(vk_space) || keyboard_check_pressed(ord("G")) || keyboard_check_pressed(ord("C")) || keyboard_check_pressed(ord("S")) || keyboard_check_pressed(ord("R")) || keyboard_check_pressed(ord("T")) || keyboard_check_pressed(ord("D"))) {
        game_state.toast_message = "You have completed your actions for this wave! Waiting for squad...";
        game_state.toast_timer = 90;
        return;
    }
}

// Player Tab Click (Switch Active Player with dynamic stretched bounds - Local mode only)
if (clicked && my >= 8 && my <= 40 && !game_state.is_online) {
    if (variable_struct_exists(game_state, "player_tab_bounds") && is_array(game_state.player_tab_bounds)) {
        for (var p = 0; p < min(game_state.num_players, array_length(game_state.player_tab_bounds)); p++) {
            var b = game_state.player_tab_bounds[p];
            if (mx >= b[0] && mx <= b[1]) {
                game_state.current_player_idx = p;
                game_play_sfx("click");
                game_log(game_state, "Switched to " + game_state.players[p].name + " (" + string(game_state.players[p].energy) + " Energy).");
                return;
            }
        }
    }
}

// ------------------------------------------------------------------
// 2. KEYBOARD SHORTCUTS
// ------------------------------------------------------------------
if (keyboard_check_pressed(vk_space)) {
    game_play_sfx("click");
    if (game_state.phase == "combat_weapons") {
        var st = game_state.combat_selected_tower;
        if (st >= 0 && st < 4 && !game_state.tower_weapon_used[st] && !is_undefined(game_state.towers[st].weapon)) {
            if (game_state.towers[st].weapon.catalog_id == "tesla") {
                game_combat_discharge_tesla(game_state);
                return;
            }
        }
        game_start_alien_attack_phase(game_state);
        return;
    } else {
        if (game_state.is_online) {
            cur_p.ended_turn = true;
            cur_p.energy = 0;
            network_broadcast_action(game_state, "action_player_turn_done", { player_idx: game_state.net_my_player_idx });
            game_log(game_state, cur_p.name + " marked turn complete. Waiting for squad...");
            game_state.toast_message = "Turn ended! Waiting for squad mates...";
            game_state.toast_timer = 120;
            if (game_check_all_players_ready(game_state)) {
                game_start_weapons_attack_phase(game_state);
            }
            return;
        } else {
            game_end_current_player_turn(game_state);
            return;
        }
    }
}
if (keyboard_check_pressed(ord("O")) || keyboard_check_pressed(ord("P"))) {
    game_play_sfx("click");
    game_state.modal = { type: "settings" };
    return;
}
if (keyboard_check_pressed(ord("1")) && game_state.num_players >= 1 && !game_state.is_online) { game_state.current_player_idx = 0; game_play_sfx("click"); return; }
if (keyboard_check_pressed(ord("2")) && game_state.num_players >= 2 && !game_state.is_online) { game_state.current_player_idx = 1; game_play_sfx("click"); return; }
if (keyboard_check_pressed(ord("3")) && game_state.num_players >= 3 && !game_state.is_online) { game_state.current_player_idx = 2; game_play_sfx("click"); return; }
if (keyboard_check_pressed(ord("4")) && game_state.num_players >= 4 && !game_state.is_online) { game_state.current_player_idx = 3; game_play_sfx("click"); return; }
if (keyboard_check_pressed(ord("G"))) {
    game_player_gather(game_state, cur_p);
    return;
}
if (keyboard_check_pressed(ord("C"))) {
    game_player_craft_metal(game_state, cur_p);
    return;
}
if (keyboard_check_pressed(ord("S"))) {
    game_play_sfx("click");
    game_state.modal = { type: "shop" };
    return;
}
if (keyboard_check_pressed(ord("R"))) {
    game_play_sfx("click");
    game_state.modal = { type: "repair" };
    return;
}
if (keyboard_check_pressed(ord("T"))) {
    game_play_sfx("click");
    game_state.modal = { type: "town" };
    return;
}
if (keyboard_check_pressed(ord("D")) || keyboard_check_pressed(ord("X"))) {
    var cur_t_idx = -1;
    if (cur_p.node == "tower_1") cur_t_idx = 0;
    else if (cur_p.node == "tower_2") cur_t_idx = 1;
    else if (cur_p.node == "tower_3") cur_t_idx = 2;
    else if (cur_p.node == "tower_4") cur_t_idx = 3;
    if (cur_t_idx >= 0 && !is_undefined(game_state.towers[cur_t_idx].weapon) && game_state.towers[cur_t_idx].weapon.alive) {
        game_player_dismantle_weapon(game_state, cur_p, cur_t_idx);
        return;
    }
}

// ------------------------------------------------------------------
// 3. BOTTOM PANEL BUTTON CLICKS & SCROLLING
// ------------------------------------------------------------------
var zone_x = 20 + 16;
var zone_w = 1880 - 32;
var card_step = 164;
var num_act = array_length(game_state.active_zone);
var max_act_scroll = max(0, num_act * card_step - 12 - zone_w);
var bar_y = 1019; // card_y2 + card_h2 + 8

if (max_act_scroll > 0) {
    if (mouse_check_button_pressed(mb_left) && point_in_rectangle(mx, my, zone_x, bar_y - 6, zone_x + zone_w, bar_y + 14)) {
        game_state.active_aliens_dragging = true;
    }
    if (game_state.active_aliens_dragging) {
        if (mouse_check_button(mb_left)) {
            var drag_ratio = clamp((mx - zone_x) / zone_w, 0.0, 1.0);
            game_state.active_aliens_scroll_x = drag_ratio * max_act_scroll;
        } else {
            game_state.active_aliens_dragging = false;
        }
    }
} else {
    game_state.active_aliens_dragging = false;
}

if (clicked) {
    if (variable_struct_exists(game_state, "btn_active_scroll_left") && game_state.btn_active_scroll_left) {
        game_state.active_aliens_scroll_x = max(0, game_state.active_aliens_scroll_x - card_step);
        game_play_sfx("click");
        return;
    }
    if (variable_struct_exists(game_state, "btn_active_scroll_right") && game_state.btn_active_scroll_right) {
        game_state.active_aliens_scroll_x = min(max_act_scroll, game_state.active_aliens_scroll_x + card_step);
        game_play_sfx("click");
        return;
    }
    
    // -------------------------------------------------------------
    // WEAPONS COMBAT PHASE CLICKS: Order Swapping, Selection, Targeting
    // -------------------------------------------------------------
    if (game_state.phase == "combat_weapons") {
        if (is_undefined(game_state.modal)) {
            game_state.modal = { type: "tactical_combat" };
            game_play_sfx("click");
            return;
        }
    }
    if (game_state.btn_gather_hover) {
        game_player_gather(game_state, cur_p);
        if (game_state.is_online) network_broadcast_action(game_state, "action_gather", {});
        return;
    }
    if (variable_struct_exists(game_state, "btn_dismantle_hover") && game_state.btn_dismantle_hover) {
        var cur_t_idx = -1;
        if (cur_p.node == "tower_1") cur_t_idx = 0;
        else if (cur_p.node == "tower_2") cur_t_idx = 1;
        else if (cur_p.node == "tower_3") cur_t_idx = 2;
        else if (cur_p.node == "tower_4") cur_t_idx = 3;
        if (cur_t_idx >= 0) {
            game_player_dismantle_weapon(game_state, cur_p, cur_t_idx);
        }
        return;
    }
    if (game_state.btn_craft_hover) {
        game_player_craft_metal(game_state, cur_p);
        return;
    }
    if (game_state.btn_shop_hover) {
        game_play_sfx("click");
        game_state.modal = { type: "shop" };
        return;
    }
    if (game_state.btn_repair_hover) {
        game_play_sfx("click");
        game_state.modal = { type: "repair" };
        return;
    }
    if (game_state.btn_town_hover) {
        game_play_sfx("click");
        game_state.modal = { type: "town" };
        return;
    }
    if (game_state.btn_fire_hover) {
        if (array_length(game_state.active_zone) > 0) {
            game_player_manual_fire(game_state, cur_p, 0);
        }
        return;
    }
    if (variable_struct_exists(game_state, "active_alien_hover") && game_state.active_alien_hover >= 0) {
        var cur_t_idx = -1;
        if (cur_p.node == "tower_1") cur_t_idx = 0;
        else if (cur_p.node == "tower_2") cur_t_idx = 1;
        else if (cur_p.node == "tower_3") cur_t_idx = 2;
        else if (cur_p.node == "tower_4") cur_t_idx = 3;
        
        var can_m_fire = false;
        if (cur_t_idx >= 0 && !is_undefined(game_state.towers[cur_t_idx].weapon)) {
            var cur_t = game_state.towers[cur_t_idx];
            var twep = cur_t.weapon;
            var f_cost = 2;
            for (var w = 0; w < array_length(game_state.weapons); w++) {
                if (game_state.weapons[w].alive && game_state.weapons[w].catalog_id == "overcharge_pylon") {
                    f_cost = 1;
                    break;
                }
            }
            if (variable_struct_exists(cur_p, "character")) {
                if (cur_p.character.id == "gunner") f_cost = 1;
                else if (cur_p.character.id == "scout") f_cost = 2;
            }
            if (twep.alive && twep.damage > 0 && cur_p.energy >= f_cost && cur_t.manual_cooldown <= 0) {
                can_m_fire = true;
            }
        }
        
        if (can_m_fire) {
            game_player_manual_fire(game_state, cur_p, game_state.active_alien_hover);
        } else if (variable_struct_exists(game_state, "alien_inspect_hover") && !is_undefined(game_state.alien_inspect_hover)) {
            game_state.modal = { type: "alien_inspect", alien: game_state.alien_inspect_hover };
            game_play_sfx("click");
        }
        return;
    }
    if (variable_struct_exists(game_state, "alien_inspect_hover") && !is_undefined(game_state.alien_inspect_hover)) {
        game_state.modal = { type: "alien_inspect", alien: game_state.alien_inspect_hover };
        game_play_sfx("click");
        return;
    }
    if (game_state.btn_endturn_hover) {
        game_play_sfx("click");
        if (game_state.is_online) {
            cur_p.ended_turn = true;
            cur_p.energy = 0;
            network_broadcast_action(game_state, "action_player_turn_done", { player_idx: game_state.net_my_player_idx });
            game_log(game_state, cur_p.name + " marked turn complete. Waiting for squad...");
            game_state.toast_message = "Turn ended! Waiting for squad mates...";
            game_state.toast_timer = 120;
            if (game_check_all_players_ready(game_state)) {
                game_start_weapons_attack_phase(game_state);
            }
            return;
        } else {
            game_end_current_player_turn(game_state);
            return;
        }
    }
    if (variable_struct_exists(game_state, "btn_combat_hover") && game_state.btn_combat_hover) {
        game_play_sfx("click");
        game_force_start_combat(game_state);
        return;
    }
    
    // ------------------------------------------------------------------
    // 4. MAP NODE CLICKS (Movement & Context Action)
    // ------------------------------------------------------------------
    var node_keys = variable_struct_get_names(game_state.nodes);
    for (var i = 0; i < array_length(node_keys); i++) {
        var k = node_keys[i];
        var n = game_state.nodes[$ k];
        if (point_in_circle(mx, my, n.x, n.y, 36)) {
            if (cur_p.node == k) {
                // Context action on current node
                if (n.type == "gather_forest" || string_pos("gather_cave", n.type) > 0) {
                    game_player_gather(game_state, cur_p);
                    if (game_state.is_online) network_broadcast_action(game_state, "action_gather", {});
                } else if (n.type == "town") {
                    game_play_sfx("click");
                    game_state.modal = { type: "town" };
                } else if (n.type == "shop") {
                    game_play_sfx("click");
                    game_state.modal = { type: "shop" };
                } else if (n.type == "workstation") {
                    game_play_sfx("click");
                    game_state.modal = { type: "repair" };
                } else if (n.type == "main_base") {
                    game_player_deposit(game_state, cur_p);
                }
            } else if (game_player_can_move(game_state, cur_p, k)) {
                game_player_move(game_state, cur_p, k);
                if (game_state.is_online) network_broadcast_action(game_state, "action_move", { node: k });
            } else {
                if (n.type == "town") {
                    game_play_sfx("click");
                    game_state.modal = { type: "town" };
                    return;
                } else if (n.type == "shop") {
                    game_play_sfx("click");
                    game_state.modal = { type: "shop" };
                    return;
                } else if (n.type == "workstation") {
                    game_play_sfx("click");
                    game_state.modal = { type: "repair" };
                    return;
                }
                var m_cost = game_player_get_move_cost(cur_p);
                game_log(game_state, "Cannot move directly to " + n.name + " (Requires " + string(m_cost) + " Energy or connected path)!");
            }
            return;
        }
    }
}
