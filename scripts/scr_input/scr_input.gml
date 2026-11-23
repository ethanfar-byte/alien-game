/// @desc All per-frame input handling and simulation ticking (called from obj_game Step).
/// Gameplay inputs never mutate state directly: they go through game_do(), which executes
/// locally or sends a request to the host when playing online as a client.

function input_step(state) {
    var mx = ui_mouse_x();
    var my = ui_mouse_y();
    var clicked = mouse_check_button_pressed(mb_left);
    if (autotest_active() && variable_struct_exists(global.at, "click") && global.at.click) {
        clicked = true;
        global.at.click = false;
    }

    network_step_update(state);
    game_music_update(state);
    input_tick_effects(state);

    // Combat simulation (authoritative on host/local; clients only smooth visuals)
    if (state.screen == "game" && (state.phase == "combat_weapons" || state.phase == "combat_aliens")) {
        if (!state.is_online || state.is_host) {
            var paused = !state.is_online && !is_undefined(state.modal) && state.modal.type != "tactical_combat";
            if (!paused) game_combat_update(state);
        } else {
            game_combat_visual_update(state);
        }
        if (is_undefined(state.modal) && state.phase != "game_over" && state.phase != "victory") {
            state.modal = { type: "tactical_combat" };
        }
    }

    input_display_hotkeys(state);

    if (!is_undefined(state.modal)) { input_modal(state, mx, my, clicked); return; }
    if (state.screen != "game") { input_screens(state, mx, my, clicked); return; }
    input_game(state, mx, my, clicked);
}

// =============================================================================
// TIMERS, PARTICLES, ANIMATION
// =============================================================================
function input_tick_effects(state) {
    // Soft whoosh when a window opens or closes (combat / end screens have their own sounds)
    var mt = is_undefined(state.modal) ? "" : state.modal.type;
    var prev_mt = state[$ "sfx_prev_modal"] ?? "";
    if (mt != prev_mt) {
        var quiet = ["", "tactical_combat", "game_over", "victory"];
        if (prev_mt == "" && !array_contains(quiet, mt)) game_play_sfx("modal_open", 0.8);
        else if (mt == "" && !array_contains(quiet, prev_mt)) game_play_sfx("modal_close", 0.7);
        state.sfx_prev_modal = mt;
    }

    if (state.toast_timer > 0) state.toast_timer--;
    if (state.turn_popup_timer > 0) state.turn_popup_timer--;
    state.name_cursor_timer++;
    state.chat_cursor_timer++;
    if (state.screen_shake > 0) state.screen_shake = max(0, state.screen_shake * 0.88 - 0.15);
    for (var t = 0; t < 4; t++) state.tower_hit_flash[t] = max(0, state.tower_hit_flash[t] - 0.05);
    for (var a = 0; a < array_length(state.active_zone); a++) {
        var al = state.active_zone[a];
        if ((al[$ "flash"] ?? 0) > 0) al.flash = max(0, al.flash - 0.08);
    }

    // Combat impacts
    for (var e = array_length(state.combat_impact_effects) - 1; e >= 0; e--) {
        var eff = state.combat_impact_effects[e];
        eff.life++;
        for (var i = array_length(eff.fireballs) - 1; i >= 0; i--) {
            var fb = eff.fireballs[i];
            fb.x += fb.vx; fb.y += fb.vy; fb.vx *= 0.91; fb.vy *= 0.91; fb.radius += fb.grow_rate; fb.life--;
            if (fb.life <= 0) array_delete(eff.fireballs, i, 1);
        }
        for (var i = array_length(eff.smoke) - 1; i >= 0; i--) {
            var sm = eff.smoke[i];
            sm.x += sm.vx; sm.y += sm.vy; sm.vy -= 0.04; sm.radius += sm.grow_rate; sm.life--;
            if (sm.life <= 0) array_delete(eff.smoke, i, 1);
        }
        for (var i = array_length(eff.sparks) - 1; i >= 0; i--) {
            var sp = eff.sparks[i];
            sp.x += sp.vx; sp.y += sp.vy; sp.vy += 0.14; sp.vx *= 0.95; sp.life--;
            if (sp.life <= 0) array_delete(eff.sparks, i, 1);
        }
        if (eff.life >= eff.max_life) array_delete(state.combat_impact_effects, e, 1);
    }
    // Board effects
    for (var b = array_length(state.board_action_effects) - 1; b >= 0; b--) {
        var ba = state.board_action_effects[b];
        ba.life++;
        for (var p = array_length(ba.particles) - 1; p >= 0; p--) {
            var pt = ba.particles[p];
            pt.x += pt.vx; pt.y += pt.vy; pt.vy += pt.gravity; pt.vx *= 0.95; pt.life--;
            if (pt.life <= 0) array_delete(ba.particles, p, 1);
        }
        if (ba.life >= ba.max_life) array_delete(state.board_action_effects, b, 1);
    }
    // Floating texts
    for (var f = array_length(state.floating_texts) - 1; f >= 0; f--) {
        var ft = state.floating_texts[f];
        ft.life--; ft.y += ft.vy; ft.vy *= 0.96;
        ft.alpha = clamp(ft.life / (ft.max_life * 0.4), 0, 1);
        if (ft.life <= 0) array_delete(state.floating_texts, f, 1);
    }
    for (var d = array_length(state.dying_aliens) - 1; d >= 0; d--) {
        state.dying_aliens[d].life--;
        if (state.dying_aliens[d].life <= 0) array_delete(state.dying_aliens, d, 1);
    }
    for (var r = array_length(state.combat_arcs) - 1; r >= 0; r--) {
        state.combat_arcs[r].life--;
        if (state.combat_arcs[r].life <= 0) array_delete(state.combat_arcs, r, 1);
    }
    if (state.combat_speed_2x && state.turn_popup_timer > 0 && (state.phase == "combat_weapons" || state.phase == "combat_aliens")) state.turn_popup_timer--;
    for (var c = array_length(state.combat_texts) - 1; c >= 0; c--) {
        var ct = state.combat_texts[c];
        ct.life--; ct.y += ct.vy; ct.vy *= 0.93;
        if (ct.life <= 0) array_delete(state.combat_texts, c, 1);
    }
    // Pawns
    for (var p = 0; p < array_length(state.players); p++) {
        var pl = state.players[p];
        if ((pl[$ "action_timer"] ?? 0) > 0) {
            pl.action_timer--;
            if (pl.action_timer <= 0) pl.action_anim = "";
        }
        if (pl.is_moving) {
            pl.move_progress = min(1.0, pl.move_progress + 0.075);
            var tt = pl.move_progress;
            var st = tt * tt * (3.0 - 2.0 * tt);
            pl.anim_x = lerp(pl.move_start_x, pl.target_x, st);
            pl.anim_y = lerp(pl.move_start_y, pl.target_y, st);
            pl.hop_y = -sin(tt * pi) * 22;
            if (random(1) < 0.3) game_spawn_board_action_effect(state, pl.anim_x, pl.anim_y, "motion_spark", pl.color);
            if (pl.move_progress >= 1.0) {
                pl.is_moving = false;
                pl.anim_x = pl.target_x; pl.anim_y = pl.target_y; pl.hop_y = 0;
                game_spawn_board_action_effect(state, pl.target_x, pl.target_y, "arrival_puff", pl.color);
            }
        }
    }
}

function input_display_hotkeys(state) {
    if (keyboard_check_pressed(vk_f11)) {
        var r = state.resolutions[state.settings.resolution_idx];
        state.settings.display_mode = (state.settings.display_mode == "windowed") ? "borderless" : "windowed";
        game_apply_display_settings(state.settings.display_mode, r[0], r[1]);
        game_play_sfx("click");
    }
    // Drop to windowed when tabbing out of exclusive/borderless fullscreen so the desktop stays usable
    var cur_focus = window_has_focus();
    if (cur_focus) state.has_had_focus = true;
    if (state.has_had_focus && !cur_focus && state.prev_window_focus && state.settings.display_mode != "windowed" && !autotest_active()) {
        state.settings.display_mode = "windowed";
        var r2 = state.resolutions[state.settings.resolution_idx];
        game_apply_display_settings("windowed", r2[0], r2[1]);
    }
    state.prev_window_focus = cur_focus;
}

/// @desc Shared text-entry helper on keyboard_string; returns the trimmed-to-length string
function input_text_field(max_chars, allowed = "") {
    var s = keyboard_string;
    if (allowed != "") {
        var clean = "";
        for (var i = 1; i <= string_length(s); i++) {
            var ch = string_char_at(s, i);
            if (string_pos(ch, allowed) > 0) clean += ch;
        }
        s = clean;
    }
    if (string_length(s) > max_chars) s = string_copy(s, 1, max_chars);
    keyboard_string = s;
    return s;
}

// =============================================================================
// MODALS
// =============================================================================
function input_close_modal(state) {
    var m = state.modal;
    state.market_cart = {};
    game_play_sfx("click");
    if (!is_undefined(m) && (m[$ "from_pause"] ?? false) && state.screen == "game") state.modal = { type: "pause" };
    else state.modal = undefined;
}

function input_modal(state, mx, my, clicked) {
    var m = state.modal;
    var esc = keyboard_check_pressed(vk_escape);

    if (clicked && state.modal_close_hover) { input_close_modal(state); return; }

    switch (m.type) {
        case "pause":
            if (esc) { state.modal = undefined; game_play_sfx("click"); return; }
            if (clicked && state.pause_hover >= 0) {
                var items = ui_pause_items(state);
                var pick = items[state.pause_hover][0];
                game_play_sfx("click");
                switch (pick) {
                    case "resume": state.modal = undefined; break;
                    case "help": state.modal = { type: "help", from_pause: true }; break;
                    case "settings": state.modal = { type: "settings", from_pause: true }; break;
                    case "restart":
                        game_reset_match(state);
                        game_apply_setup_roster(state);
                        state.modal = undefined;
                        ui_transition_to(state, "game");
                        break;
                    case "title":
                        if (state.is_online) network_leave_room(state);
                        game_reset_match(state);
                        state.modal = undefined;
                        ui_transition_to(state, state.is_online ? "online_browser" : "title");
                        if (state.screen == "online_browser") network_start_browsing(state);
                        break;
                    case "quit": game_end(); break;
                }
            }
            return;

        case "help":
            if (esc || (clicked && (state[$ "help_close_hover"] ?? false))) input_close_modal(state);
            return;

        case "settings":
            input_settings(state, mx, my, clicked, esc);
            return;

        case "alien_inspect":
            if (esc || (clicked && state.alien_inspect_close_hover)) input_close_modal(state);
            return;

        case "shop":
            if (esc || keyboard_check_pressed(ord("S"))) { input_close_modal(state); return; }
            if (clicked && !is_undefined(state.ui_click_action)) input_run_ui_action(state, state.ui_click_action);
            return;

        case "town":
            if (esc || keyboard_check_pressed(ord("T"))) { input_close_modal(state); return; }
            if (keyboard_check_pressed(vk_enter)) { input_run_ui_action(state, { a: "@sell_cart", args: {} }); return; }
            if (clicked && !is_undefined(state.ui_click_action)) input_run_ui_action(state, state.ui_click_action);
            return;

        case "repair":
        case "workstation":
            if (esc || keyboard_check_pressed(ord("R"))) { input_close_modal(state); return; }
            var ws_mx0 = (1920 - 1240) * 0.5;
            var ws_my0 = (1080 - 780) * 0.5;
            var WL = ui_workshop_layout(ws_mx0, ws_my0, 1240, 780);
            if (point_in_rectangle(mx, my, WL.lx, WL.ly, WL.lx + WL.lw, WL.ly + WL.lh)) {
                if (mouse_wheel_up()) state.workstation_bp_scroll_y = max(0, state.workstation_bp_scroll_y - 90);
                if (mouse_wheel_down()) state.workstation_bp_scroll_y = min(state.workstation_bp_max_scroll, state.workstation_bp_scroll_y + 90);
            }
            if (clicked && state.workstation_bp_thumb_hover) {
                state.workstation_bp_drag = true;
                state.workstation_bp_drag_start_my = my;
                state.workstation_bp_drag_start_val = state.workstation_bp_scroll_y;
                return;
            }
            if (state.workstation_bp_drag) {
                if (mouse_check_button(mb_left)) {
                    state.workstation_bp_scroll_y = clamp(state.workstation_bp_drag_start_val + ((my - state.workstation_bp_drag_start_my) / max(1, state.workstation_bp_usable_track)) * state.workstation_bp_max_scroll, 0, state.workstation_bp_max_scroll);
                } else state.workstation_bp_drag = false;
                return;
            }
            if (keyboard_check_pressed(ord("C"))) { game_do(state, "craft_metal", {}); return; }
            if (clicked && !is_undefined(state.ui_click_action)) input_run_ui_action(state, state.ui_click_action);
            return;

        case "tactical_combat":
            input_combat(state, mx, my, clicked, esc);
            return;

        case "victory":
            if (!clicked) return;
            if (state.victory_endless_hover) { game_do(state, "endless", {}); return; }
            if (state.victory_restart_hover) {
                game_play_sfx("click");
                if (state.is_online) input_end_online_match(state);
                else { game_reset_match(state); state.modal = undefined; ui_transition_to(state, "local_setup"); }
                return;
            }
            if (state.victory_exit_hover) { game_end(); return; }
            return;

        case "game_over":
            if (!clicked) return;
            if (state.gameover_restart_hover) {
                game_play_sfx("click");
                if (state.is_online) input_end_online_match(state);
                else {
                    game_reset_match(state);
                    game_apply_setup_roster(state);
                    state.modal = undefined;
                    ui_transition_to(state, "game");
                }
                return;
            }
            if (state.gameover_menu_hover) {
                game_play_sfx("click");
                game_reset_match(state);
                state.modal = undefined;
                ui_transition_to(state, "title");
                return;
            }
            if (state.gameover_quit_hover) { game_end(); return; }
            return;

        default:
            if (esc) input_close_modal(state);
            return;
    }
}

function input_end_online_match(state) {
    if (state.is_host) {
        network_host_return_to_lobby(state);
    } else {
        network_leave_room(state);
        game_reset_match(state);
        state.modal = undefined;
    }
}

function input_settings(state, mx, my, clicked, esc) {
    var mw = 900, mh = 640;
    var mx0 = (1920 - mw) * 0.5, my0 = (1080 - mh) * 0.5;
    var S = ui_settings_layout(mx0, my0, mw, mh);

    // Sliders
    if (mouse_check_button_pressed(mb_left)) {
        if (point_in_rectangle(mx, my, S.track_x - 12, S.sfx_y - 14, S.track_x + S.track_w + 12, S.sfx_y + S.track_h + 14)) state.settings.slider_dragging = true;
        if (point_in_rectangle(mx, my, S.track_x - 12, S.music_y - 14, S.track_x + S.track_w + 12, S.music_y + S.track_h + 14)) state.settings.music_dragging = true;
    }
    if (state.settings.slider_dragging) {
        if (mouse_check_button(mb_left)) state.settings.sfx_volume = clamp((mx - S.track_x) / S.track_w, 0, 1);
        else { state.settings.slider_dragging = false; game_play_sfx("coin"); }
        return;
    }
    if (state.settings.music_dragging) {
        if (mouse_check_button(mb_left)) state.settings.music_volume = clamp((mx - S.track_x) / S.track_w, 0, 1);
        else state.settings.music_dragging = false;
        return;
    }
    if (esc || (clicked && state.settings_close_hover)) { input_close_modal(state); return; }
    if (!clicked) return;
    var r = state.resolutions[state.settings.resolution_idx];
    if (state.settings_test_sfx_hover) { game_play_sfx("kill"); return; }
    if (state.settings_mode_borderless_hover) { state.settings.display_mode = "borderless"; game_apply_display_settings("borderless", r[0], r[1]); game_play_sfx("click"); return; }
    if (state.settings_mode_fullscreen_hover) { state.settings.display_mode = "fullscreen"; game_apply_display_settings("fullscreen", r[0], r[1]); game_play_sfx("click"); return; }
    if (state.settings_mode_windowed_hover) { state.settings.display_mode = "windowed"; game_apply_display_settings("windowed", r[0], r[1]); game_play_sfx("click"); return; }
    var rdir = (state[$ "settings_res_prev_hover"] ?? false) ? -1 : ((state[$ "settings_res_next_hover"] ?? false) ? 1 : 0);
    if (rdir != 0) {
        state.settings.resolution_idx = clamp(state.settings.resolution_idx + rdir, 0, array_length(state.resolutions) - 1);
        var rr = state.resolutions[state.settings.resolution_idx];
        if (state.settings.display_mode == "windowed") game_apply_display_settings("windowed", rr[0], rr[1]);
        game_play_sfx("click");
        return;
    }
    if (state[$ "settings_shake_hover"] ?? false) {
        state.settings.screen_shake = !(state.settings[$ "screen_shake"] ?? true);
        game_play_sfx("click");
        if (state.settings.screen_shake) state.screen_shake = 10;
        return;
    }
}

function input_combat(state, mx, my, clicked, esc) {
    if (esc) { state.modal = { type: "pause" }; game_play_sfx("click"); return; }
    if (clicked && state.combat_speed_btn_hover) { game_do(state, "combat_speed", {}); return; }
    if (keyboard_check_pressed(vk_tab)) { game_do(state, "combat_speed", {}); return; }

    if (state.combat_subphase == "combat_concluded") {
        if ((clicked && state.combat_conclude_btn_hover) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter)) {
            game_do(state, "combat_conclude", {});
        }
        return;
    }
    if (state.combat_subphase != "player_weapons") return;

    // Number keys arm a tower's weapon
    for (var k = 0; k < 4; k++) {
        if (keyboard_check_pressed(ord(string(k + 1)))) { game_do(state, "combat_select", { tower: k }); return; }
    }
    var sel = state.combat_selected_tower;
    if (keyboard_check_pressed(vk_space)) {
        if (sel >= 0 && sel < 4 && !state.tower_weapon_used[sel] && !is_undefined(state.towers[sel].weapon) && state.towers[sel].weapon.catalog_id == "tesla") {
            game_do(state, "combat_tesla", { tower: sel });
        } else {
            game_do(state, "combat_skip", {});
        }
        return;
    }
    if (!clicked) return;
    if (state.combat_advance_hover) { game_do(state, "combat_skip", {}); return; }
    if (state.combat_tesla_btn_hover) {
        for (var t = 0; t < 4; t++) {
            var tw = state.towers[t];
            if (!state.tower_weapon_used[t] && !is_undefined(tw.weapon) && tw.weapon.alive && tw.weapon.catalog_id == "tesla" && state.combat_tower_hover[t]) {
                game_do(state, "combat_tesla", { tower: t });
                return;
            }
        }
        game_do(state, "combat_tesla", { tower: sel });
        return;
    }
    for (var t = 0; t < 4; t++) {
        if (state.combat_tower_hover[t]) { game_do(state, "combat_select", { tower: t }); return; }
    }
    if (state.combat_alien_hover >= 0) {
        game_do(state, "combat_fire", { tower: sel, target: state.combat_alien_hover });
        return;
    }
}

// =============================================================================
// MENU SCREENS
// =============================================================================
function input_title_activate(state, idx) {
    game_play_sfx("click");
    switch (idx) {
        case 0: ui_transition_to(state, "local_setup"); break;
        case 1: ui_transition_to(state, "online_username"); keyboard_string = state.net_username; break;
        case 2: state.modal = { type: "help" }; break;
        case 3: state.modal = { type: "settings" }; break;
        case 4: game_end(); break;
    }
}

function input_screens(state, mx, my, clicked) {
    switch (state.screen) {
        case "title": {
            var n = 5;
            if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) { state.title_sel = ((state[$ "title_sel"] ?? 0) + 1) mod n; game_play_sfx("hover", 0.7); }
            if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) { state.title_sel = ((state[$ "title_sel"] ?? 0) + n - 1) mod n; game_play_sfx("hover", 0.7); }
            if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) { input_title_activate(state, state[$ "title_sel"] ?? 0); return; }
            if (clicked && (state[$ "title_hover"] ?? -1) >= 0) { input_title_activate(state, state.title_hover); return; }
            break;
        }

        case "local_setup": {
            if (state.editing_player_name_idx >= 0) {
                var ep = state.editing_player_name_idx;
                if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
                    if (string_trim(state.setup_player_names[ep]) == "") state.setup_player_names[ep] = "Player " + string(ep + 1);
                    state.editing_player_name_idx = -1;
                    game_play_sfx("click");
                    return;
                }
                state.setup_player_names[ep] = input_text_field(14);
            }
            if (clicked) {
                for (var p = 0; p < state.setup_player_count; p++) {
                    if (state.local_setup_name_hover[p]) {
                        state.editing_player_name_idx = p;
                        keyboard_string = state.setup_player_names[p];
                        game_play_sfx("click");
                        return;
                    }
                }
                if (state.editing_player_name_idx >= 0) {
                    var ep2 = state.editing_player_name_idx;
                    if (string_trim(state.setup_player_names[ep2]) == "") state.setup_player_names[ep2] = "Player " + string(ep2 + 1);
                    state.editing_player_name_idx = -1;
                }
                for (var c = 0; c < 4; c++) {
                    if (state.local_setup_count_hover[c]) { state.setup_player_count = c + 1; game_play_sfx("click"); return; }
                }
                for (var p = 0; p < state.setup_player_count; p++) {
                    if (state.local_setup_prev_hover[p]) { state.setup_player_classes[p] = game_cycle_class_exclusive(state.setup_player_classes[p], -1, p, state.setup_player_classes); game_play_sfx("click"); return; }
                    if (state.local_setup_next_hover[p]) { state.setup_player_classes[p] = game_cycle_class_exclusive(state.setup_player_classes[p], 1, p, state.setup_player_classes); game_play_sfx("click"); return; }
                }
                if (state.local_setup_back_hover) { game_play_sfx("click"); ui_transition_to(state, "title"); return; }
                if (state.local_setup_start_hover) { input_launch_local(state); return; }
            }
            if (state.editing_player_name_idx < 0) {
                if (keyboard_check_pressed(vk_enter)) { input_launch_local(state); return; }
                if (keyboard_check_pressed(vk_escape)) { game_play_sfx("click"); ui_transition_to(state, "title"); return; }
                for (var k = 0; k < 4; k++) if (keyboard_check_pressed(ord(string(k + 1)))) { state.setup_player_count = k + 1; game_play_sfx("click"); }
            }
            break;
        }

        case "online_username": {
            state.net_username_input = input_text_field(14);
            var confirm = keyboard_check_pressed(vk_enter) || (clicked && state.online_user_confirm_hover);
            if (confirm) {
                if (string_trim(state.net_username_input) != "") {
                    state.net_username = string_trim(state.net_username_input);
                    network_start_browsing(state);
                    game_play_sfx("click");
                } else {
                    state.net_error_message = "Please enter a callsign.";
                    state.net_error_timer = 180;
                    game_play_sfx("error");
                }
                return;
            }
            if (keyboard_check_pressed(vk_escape) || (clicked && state.online_user_back_hover)) { game_play_sfx("click"); ui_transition_to(state, "title"); return; }
            break;
        }

        case "online_browser": {
            if (state.net_direct_ip_editing) {
                state.net_direct_ip_input = input_text_field(39, "0123456789.abcdefABCDEF:localhst-");
                if (keyboard_check_pressed(vk_enter)) {
                    state.net_direct_ip_editing = false;
                    var ip = string_trim(state.net_direct_ip_input);
                    if (ip != "") network_connect_to_room(state, ip, NET_PORT_TCP);
                    return;
                }
                if (keyboard_check_pressed(vk_escape)) { state.net_direct_ip_editing = false; return; }
            }
            if (clicked) {
                if (state[$ "online_browser_ip_hover"] ?? false) {
                    state.net_direct_ip_editing = true;
                    keyboard_string = state.net_direct_ip_input;
                    game_play_sfx("click");
                    return;
                }
                state.net_direct_ip_editing = false;
                if (state.online_browser_create_hover) { network_start_hosting(state); return; }
                if (state.online_browser_refresh_hover) { state.net_discovered_rooms = []; game_play_sfx("click"); return; }
                if (state.online_browser_edit_user_hover) { ui_transition_to(state, "online_username"); keyboard_string = state.net_username; game_play_sfx("click"); return; }
                if (state.online_browser_back_hover) { network_cleanup_sockets(state); ui_transition_to(state, "title"); game_play_sfx("click"); return; }
                if (state.online_browser_room_hover >= 0 && state.online_browser_room_hover < array_length(state.net_discovered_rooms)) {
                    var rm = state.net_discovered_rooms[state.online_browser_room_hover];
                    network_connect_to_room(state, rm.ip, rm.port);
                    return;
                }
                if (state.online_browser_direct_hover) {
                    var ip2 = string_trim(state.net_direct_ip_input);
                    if (ip2 != "") network_connect_to_room(state, ip2, NET_PORT_TCP);
                    return;
                }
            }
            if (!state.net_direct_ip_editing) {
                if (keyboard_check_pressed(ord("R"))) { state.net_discovered_rooms = []; game_play_sfx("click"); }
                if (keyboard_check_pressed(ord("H"))) { network_start_hosting(state); return; }
                if (keyboard_check_pressed(vk_escape)) { network_cleanup_sockets(state); ui_transition_to(state, "title"); game_play_sfx("click"); return; }
            }
            break;
        }

        case "online_lobby": {
            var classes = game_get_character_classes();
            var my_idx = state.net_my_player_idx;
            var cyc = 0;
            if (clicked && state.online_lobby_prev_hover) cyc = -1;
            if (clicked && state.online_lobby_next_hover) cyc = 1;
            if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) cyc = -1;
            if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) cyc = 1;
            if (cyc != 0 && my_idx >= 0 && my_idx < array_length(state.net_lobby_players)) {
                var cur_ci = 0;
                for (var ci = 0; ci < array_length(classes); ci++) if (classes[ci].id == state.net_lobby_players[my_idx].character_id) cur_ci = ci;
                var new_ci = game_cycle_class_exclusive(cur_ci, cyc, my_idx, state.net_lobby_players);
                network_lobby_change_character(state, classes[new_ci].id);
                game_play_sfx("click");
                return;
            }
            if ((clicked && state.online_lobby_leave_hover) || keyboard_check_pressed(vk_escape)) {
                game_play_sfx("click");
                network_leave_room(state);
                return;
            }
            if (state.is_host && array_length(state.net_lobby_players) >= 2) {
                if ((clicked && state.online_lobby_start_hover) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
                    network_host_start_mission(state);
                    return;
                }
            }
            break;
        }
    }
}

function input_launch_local(state) {
    game_reset_match(state);
    game_apply_setup_roster(state);
    state.modal = undefined;
    ui_transition_to(state, "game");
    game_popup(state, "DAY 1 / " + string(game_final_day(state)), "Gather resources and fortify the base. The first aliens show up on radar on Day 3.", C_ACCENT, 220);
    game_play_sfx("wave");
}

// =============================================================================
// IN-GAME (no modal open)
// =============================================================================
function input_game(state, mx, my, clicked) {
    var L = ui_hud_layout();
    var pl = game_local_player(state);

    // ---- Chat ----
    var send_clicked = clicked && state.chat_send_hover;
    if (state.chat_input_active) {
        state.chat_input_text = input_text_field(80);
        if (keyboard_check_pressed(vk_enter) || send_clicked) {
            var txt = string_trim(state.chat_input_text);
            if (txt != "") game_do(state, "chat", { text: txt });
            state.chat_input_text = "";
            keyboard_string = "";
            state.chat_input_active = false;
            return;
        }
        if (keyboard_check_pressed(vk_escape) || (clicked && !state.chat_input_hover)) {
            state.chat_input_active = false;
            if (!clicked) return;
        } else return;
    }
    if ((clicked && state.chat_input_hover) || keyboard_check_pressed(vk_enter)) {
        state.chat_input_active = true;
        keyboard_string = state.chat_input_text;
        game_play_sfx("click", 0.6);
        return;
    }

    // ---- Comms panel ----
    var log_x = state.action_log_x;
    var in_log = point_in_rectangle(mx, my, log_x, L.log_y1, L.right_x2, L.log_y2);
    if (in_log) {
        if (mouse_wheel_up()) state.action_log_scroll_y = max(0, state.action_log_scroll_y - 48);
        if (mouse_wheel_down()) state.action_log_scroll_y = min(state.action_log_max_scroll_y, state.action_log_scroll_y + 48);
    }
    if (clicked && state.action_log_btn_toggle_hover) { state.action_log_x = (state.action_log_x < 1400) ? L.right_x : 820; game_play_sfx("click"); return; }
    if (clicked && state.action_log_btn_top_hover) { state.action_log_scroll_y = 0; game_play_sfx("click"); return; }
    if (clicked && state.action_log_v_thumb_hover) {
        state.action_log_v_drag = true;
        state.action_log_v_drag_start_my = my;
        state.action_log_v_drag_start_val = state.action_log_scroll_y;
        return;
    }
    if (state.action_log_v_drag) {
        if (mouse_check_button(mb_left)) {
            state.action_log_scroll_y = clamp(state.action_log_v_drag_start_val + ((my - state.action_log_v_drag_start_my) / max(1, state[$ "action_log_usable_v_track"] ?? 1)) * state.action_log_max_scroll_y, 0, state.action_log_max_scroll_y);
        } else state.action_log_v_drag = false;
        return;
    }
    if (clicked && in_log) return;

    // ---- Menus ----
    if (keyboard_check_pressed(vk_escape) || (clicked && state.btn_settings_hover)) { state.modal = { type: "pause" }; game_play_sfx("click"); return; }
    if (keyboard_check_pressed(vk_f1) || keyboard_check_pressed(ord("H"))) { state.modal = { type: "help" }; game_play_sfx("click"); return; }

    if (state.phase != "player_actions") return;

    // ---- Operative switching (local pass-and-play) ----
    if (!state.is_online) {
        if (clicked && my >= 8 && my <= 50) {
            for (var p = 0; p < min(state.num_players, array_length(state.player_tab_bounds)); p++) {
                var b = state.player_tab_bounds[p];
                if (mx >= b[0] && mx <= b[1]) { input_switch_operative(state, p); return; }
            }
        }
        for (var k = 0; k < state.num_players; k++) {
            if (keyboard_check_pressed(ord(string(k + 1)))) { input_switch_operative(state, k); return; }
        }
        if (keyboard_check_pressed(vk_tab)) {
            var nxt = state.current_player_idx;
            for (var step = 1; step <= state.num_players; step++) {
                var cand = (state.current_player_idx + step) mod state.num_players;
                if (state.players[cand].energy > 0) { nxt = cand; break; }
            }
            input_switch_operative(state, nxt);
            return;
        }
    }

    var standing_by = state.is_online && pl.ended_turn;

    // ---- Directional movement (WASD / arrows, diagonals by combining) ----
    var kdx = (keyboard_check(ord("D")) || keyboard_check(vk_right)) - (keyboard_check(ord("A")) || keyboard_check(vk_left));
    var kdy = (keyboard_check(ord("S")) || keyboard_check(vk_down)) - (keyboard_check(ord("W")) || keyboard_check(vk_up));
    var dir_pressed = keyboard_check_pressed(ord("W")) || keyboard_check_pressed(ord("A")) || keyboard_check_pressed(ord("S")) || keyboard_check_pressed(ord("D"))
                   || keyboard_check_pressed(vk_up) || keyboard_check_pressed(vk_down) || keyboard_check_pressed(vk_left) || keyboard_check_pressed(vk_right);
    if (dir_pressed && (state[$ "move_buffer"] ?? 0) <= 0) {
        state.move_buffer = 6;
        state.move_vec = [0, 0];
    }
    if ((state[$ "move_buffer"] ?? 0) > 0) {
        if (kdx != 0) state.move_vec[0] = kdx;
        if (kdy != 0) state.move_vec[1] = kdy;
        state.move_buffer--;
        if (state.move_buffer == 0 && !pl.is_moving) {
            var dest = game_node_in_direction(state, pl.node, state.move_vec[0], state.move_vec[1]);
            if (dest != "") game_do(state, "move", { node: dest });
            else game_play_sfx("error", 0.5);
        }
    }

    // ---- Hotkeys ----
    if (keyboard_check_pressed(ord("E"))) { input_interact(state, pl, pl.node); return; }
    if (keyboard_check_pressed(ord("G"))) { game_do(state, "gather", {}); return; }
    if (keyboard_check_pressed(ord("C"))) { game_do(state, "craft_metal", {}); return; }
    if (keyboard_check_pressed(ord("X"))) { game_do(state, "dismantle", {}); return; }
    if (keyboard_check_pressed(ord("F"))) { input_quick_fire(state, pl); return; }
    if (keyboard_check_pressed(ord("B")) && !state.is_online) { game_do(state, "begin_defense", {}); return; }
    if (keyboard_check_pressed(vk_space)) { game_do(state, "end_turn", {}); return; }

    if (!clicked) return;

    // ---- Action bar (contextual buttons register their action while drawing) ----
    if (!is_undefined(state.ui_click_action)) { input_run_ui_action(state, state.ui_click_action); return; }

    // ---- Alien cards: fire if piloting an armed tower, otherwise inspect ----
    if (state.active_alien_hover >= 0) {
        var ti = game_player_tower_idx(pl);
        var tw = (ti >= 0) ? state.towers[ti] : undefined;
        var can_pilot = !standing_by && !is_undefined(tw) && !is_undefined(tw.weapon) && tw.weapon.alive && tw.weapon.damage > 0 && tw.manual_cooldown <= 0 && pl.energy >= game_fire_cost(state, pl);
        if (can_pilot) { input_quick_fire(state, pl); return; } // opens the attack screen
    }
    if (!is_undefined(state.alien_inspect_hover)) {
        state.modal = { type: "alien_inspect", alien: state.alien_inspect_hover };
        game_play_sfx("click");
        return;
    }

    // ---- Map ----
    if (point_in_rectangle(mx, my, L.board_x1, L.board_y1, L.board_x2, L.board_y2)) {
        var k2 = state[$ "board_hover_node"] ?? "";
        if (k2 != "") {
            if (pl.node == k2) input_interact(state, pl, k2);
            else if (game_player_can_move(state, pl, k2) && !standing_by) game_do(state, "move", { node: k2 });
            else {
                var n2 = state.nodes[$ k2];
                // Facilities can always be previewed from afar
                if (n2.type == "town") { state.modal = { type: "town" }; game_play_sfx("click"); }
                else if (n2.type == "shop") { state.modal = { type: "shop" }; game_play_sfx("click"); }
                else if (n2.type == "workstation") { state.modal = { type: "repair" }; game_play_sfx("click"); }
                else game_do(state, "move", { node: k2 }); // produces a helpful "why not" message
            }
        }
    }
}

function input_switch_operative(state, p) {
    if (p < 0 || p >= state.num_players || p == state.current_player_idx) return;
    state.current_player_idx = p;
    game_play_sfx("turn", 0.6);
    var np = state.players[p];
    state.toast_message = np.name + " (" + np.character.name + ") - " + string(np.energy) + " energy";
    state.toast_timer = 90;
    state.toast_is_error = false;
}

/// @desc Context action for the node the operative stands on
function input_interact(state, pl, node_key) {
    var n = state.nodes[$ node_key];
    if (is_undefined(n)) return;
    switch (n.type) {
        case "gather_forest": case "gather_cave1": case "gather_cave2": case "gather_cave3":
            game_do(state, "gather", {}); break;
        case "town": state.modal = { type: "town" }; game_play_sfx("click"); break;
        case "shop": state.modal = { type: "shop" }; game_play_sfx("click"); break;
        case "workstation": state.modal = { type: "repair" }; game_play_sfx("click"); break;
        case "main_base":
            game_do(state, "deposit", {});
            break;
        case "tower": input_quick_fire(state, pl); break;
        default: game_play_sfx("error", 0.5);
    }
}

/// @desc Fire key / button / alien click on an armed tower: opens the attack screen for that weapon
function input_quick_fire(state, pl) {
    game_do(state, "volley_start", {});
}

/// @desc Runs an action registered by a UI button: "modal:<type>" opens a screen, "@fire" quick-fires, anything else is a game action
function input_run_ui_action(state, act) {
    var a = act.a;
    if (a == "") return;
    if (string_pos("modal:", a) == 1) {
        state.modal = { type: string_delete(a, 1, 6) };
        game_play_sfx("click");
        return;
    }
    if (a == "@fire") { input_quick_fire(state, game_local_player(state)); return; }
    if (a == "@cart") {
        if (!is_struct(state[$ "market_cart"])) state.market_cart = {};
        var k = act.args.res;
        var cur = state.market_cart[$ k] ?? 0;
        state.market_cart[$ k] = clamp(cur + act.args.d, 0, state.storage[$ k]);
        game_play_sfx((act.args.d > 0) ? "coin" : "click", 0.5);
        return;
    }
    if (a == "@cart_clear") { state.market_cart = {}; game_play_sfx("click"); return; }
    if (a == "@sell_cart") {
        var cart = state[$ "market_cart"] ?? {};
        var total = 0;
        var keys = variable_struct_get_names(cart);
        for (var i = 0; i < array_length(keys); i++) total += cart[$ keys[i]];
        if (total <= 0) return;
        if (game_do(state, "sell_cart", { cart: cart })) state.market_cart = {};
        return;
    }
    game_do(state, a, act.args);
}
