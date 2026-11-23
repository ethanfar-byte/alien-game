/// @desc obj_game Draw GUI Event
var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// -------------------------------------------------------------
// SCREEN DISPATCH: TITLE, LOCAL SETUP, ONLINE MULTIPLAYER
// -------------------------------------------------------------
if (game_state.screen != "game") {
    switch (game_state.screen) {
        case "title":
            ui_draw_title_screen(game_state, mx, my);
            break;
        case "local_setup":
            ui_draw_local_setup_screen(game_state, mx, my);
            break;
        case "online_username":
            ui_draw_online_username_screen(game_state, mx, my);
            break;
        case "online_browser":
            ui_draw_online_browser_screen(game_state, mx, my);
            break;
        case "online_lobby":
            ui_draw_online_lobby_screen(game_state, mx, my);
            break;
        default:
            ui_draw_title_screen(game_state, mx, my);
            break;
    }
    
    // If a modal (such as Settings) is open while in menu screens, draw on top
    if (!is_undefined(game_state.modal)) {
        ui_draw_modals(game_state, mx, my);
    }
    return;
}

// =============================================================
// IN-GAME ACTIVE MATCH DRAWING
// =============================================================

// Background clear
draw_set_color(make_color_rgb(15, 18, 25));
draw_rectangle(0, 0, 1920, 1080, false);

// Top Header Bar
draw_set_color(make_color_rgb(26, 32, 44));
draw_rectangle(0, 0, 1920, 44, false);
draw_set_color(make_color_rgb(52, 73, 94));
draw_line_width(0, 44, 1920, 44, 2);

draw_set_halign(fa_left); draw_set_valign(fa_middle);
draw_set_color(c_yellow);
draw_text(25, 22, "ALIEN DEFENSE // TACTICAL BOARD PROTOTYPE");

// Multiplayer Player Tabs with Dynamic Width Stretching
var cur_tab_x = 550;
game_state.player_tab_bounds = [];

for (var p = 0; p < game_state.num_players; p++) {
    var pl = game_state.players[p];
    var is_cur = (p == game_state.current_player_idx);
    
    // Dynamically calculate box width to guarantee space between name and energy icon
    var name_w = string_width(pl.name);
    var energy_str = string(pl.energy);
    var num_w = string_width(energy_str);
    var bolt_w = 14;
    var pad_left = 12;
    var pad_between = 14; // Guaranteed space between username and lightning bolt icon
    var pad_right = 14;
    
    var tab_w = max(130, pad_left + name_w + pad_between + bolt_w + 8 + num_w + pad_right);
    array_push(game_state.player_tab_bounds, [cur_tab_x, cur_tab_x + tab_w]);
    
    draw_set_color(is_cur ? pl.color : make_color_rgb(45, 55, 72));
    draw_roundrect_ext(cur_tab_x, 8, cur_tab_x + tab_w, 36, 6, 6, false);
    draw_set_color(is_cur ? c_white : make_color_rgb(160, 174, 192));
    draw_roundrect_ext(cur_tab_x, 8, cur_tab_x + tab_w, 36, 6, 6, true);
    
    draw_set_valign(fa_middle);
    draw_set_halign(fa_left);
    draw_set_color(is_cur ? c_white : make_color_rgb(220, 220, 220));
    draw_text(cur_tab_x + pad_left, 22, pl.name);
    
    // Lightning bolt icon positioned after username with guaranteed spacing
    var icon_x = cur_tab_x + pad_left + name_w + pad_between + (bolt_w * 0.5);
    ui_draw_lightning(icon_x, 22, bolt_w, (pl.energy > 0));
    
    draw_set_halign(fa_left);
    draw_set_color(is_cur ? make_color_rgb(255, 235, 59) : make_color_rgb(210, 210, 150));
    draw_text(icon_x + 9, 22, energy_str);
    
    cur_tab_x += tab_w + 10;
}

// Settings Menu Button on top right
var s_hov = ui_draw_button(1760, 7, 135, 30, "Settings", true, false, mx, my);
game_state.btn_settings_hover = s_hov;

// Online Multiplayer Status Badge in Header
if (game_state.is_online) {
    var my_p = game_state.net_my_player_idx;
    var my_name = (my_p >= 0 && my_p < game_state.num_players) ? game_state.players[my_p].name : game_state.net_username;
    var is_my_turn = (game_state.current_player_idx == my_p);
    
    var net_badge_x = 1450;
    var net_badge_w = 295;
    draw_set_color(make_color_rgb(20, 28, 42));
    draw_roundrect_ext(net_badge_x, 8, net_badge_x + net_badge_w, 36, 6, 6, false);
    draw_set_color(is_my_turn ? c_yellow : make_color_rgb(0, 180, 216));
    draw_roundrect_ext(net_badge_x, 8, net_badge_x + net_badge_w, 36, 6, 6, true);
    
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(is_my_turn ? c_yellow : make_color_rgb(0, 229, 255));
    draw_circle(net_badge_x + 14, 22, 4, false);
    draw_text(net_badge_x + 24, 22, "WI-FI: You are " + my_name + (is_my_turn ? " (YOUR TURN!)" : ""));
    
    // Sub-header turn waiting indicator
    if (!is_my_turn && game_state.current_player_idx < game_state.num_players) {
        var act_pl = game_state.players[game_state.current_player_idx];
        draw_set_color(make_color_rgb(20, 28, 40));
        draw_roundrect_ext(760, 48, 1160, 78, 6, 6, false);
        draw_set_color(act_pl.color);
        draw_roundrect_ext(760, 48, 1160, 78, 6, 6, true);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(960, 63, "Waiting for " + act_pl.name + " to complete their action...");
    }
}

// Auto-trigger game over modal if all towers lost
if (game_state.phase == "game_over" && is_undefined(game_state.modal)) {
    game_state.modal = { type: "game_over" };
}

// Draw Board, Right Panel, Bottom UI
ui_draw_board(game_state, mx, my);
ui_draw_right_panel(game_state, mx, my);
ui_draw_bottom_panel(game_state, mx, my);

// Draw Modals (if active)
ui_draw_modals(game_state, mx, my);

// -------------------------------------------------------------
// TURN SWITCH POPUP BANNER (When player energy depletes)
// -------------------------------------------------------------
if (game_state.turn_popup_timer > 0) {
    var p_msg = game_state.turn_popup_message;
    var p_title = game_state.turn_popup_title;
    
    var pop_w = max(580, max(string_width(p_msg), string_width(p_title)) + 60);
    var pop_h = 72;
    var pop_x = (1920 - pop_w) * 0.5;
    var pop_y = 54;
    var alpha = min(1.0, game_state.turn_popup_timer / 25.0);
    
    draw_set_alpha(alpha * 0.96);
    draw_set_color(make_color_rgb(14, 18, 28));
    draw_roundrect_ext(pop_x - 3, pop_y - 3, pop_x + pop_w + 3, pop_y + pop_h + 3, 12, 12, false);
    draw_set_color(make_color_rgb(26, 34, 48));
    draw_roundrect_ext(pop_x, pop_y, pop_x + pop_w, pop_y + pop_h, 10, 10, false);
    
    draw_set_color(game_state.turn_popup_color);
    draw_roundrect_ext(pop_x, pop_y, pop_x + pop_w, pop_y + pop_h, 10, 10, true);
    draw_roundrect_ext(pop_x + 1, pop_y + 1, pop_x + pop_w - 1, pop_y + pop_h - 1, 10, 10, true);
    
    draw_set_halign(fa_center); draw_set_valign(fa_top);
    draw_set_color(game_state.turn_popup_color);
    draw_text(pop_x + pop_w * 0.5, pop_y + 10, p_title);
    
    draw_set_color(c_white);
    draw_text(pop_x + pop_w * 0.5, pop_y + 36, p_msg);
    draw_set_alpha(1.0);
}
// Standard Toast Notification Banner (when turn popup not active)
else if (game_state.toast_timer > 0) {
    var toast_w = string_width(game_state.toast_message) + 40;
    var toast_x = (1920 - toast_w) * 0.5;
    var toast_y = 52;
    var alpha = min(1.0, game_state.toast_timer / 30.0);
    
    draw_set_alpha(alpha * 0.9);
    draw_set_color(make_color_rgb(33, 43, 54));
    draw_roundrect_ext(toast_x, toast_y, toast_x + toast_w, toast_y + 36, 8, 8, false);
    draw_set_color(c_yellow);
    draw_roundrect_ext(toast_x, toast_y, toast_x + toast_w, toast_y + 36, 8, 8, true);
    
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text(toast_x + toast_w * 0.5, toast_y + 18, game_state.toast_message);
    draw_set_alpha(1.0);
}

// Floating Tooltip Inspector (On top of everything)
if (game_state.hover_tooltip != "") {
    var tip_str = game_state.hover_tooltip;
    var tip_w = string_width_ext(tip_str, 18, 380) + 24;
    var tip_h = string_height_ext(tip_str, 18, 380) + 20;
    var tip_x = clamp(mx + 16, 15, 1920 - tip_w - 15);
    var tip_y = clamp(my + 16, 15, 1080 - tip_h - 15);
    
    draw_set_color(make_color_rgb(18, 22, 32));
    draw_roundrect_ext(tip_x, tip_y, tip_x + tip_w, tip_y + tip_h, 8, 8, false);
    draw_set_color(make_color_rgb(100, 181, 246));
    draw_roundrect_ext(tip_x, tip_y, tip_x + tip_w, tip_y + tip_h, 8, 8, true);
    
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text_ext(tip_x + 12, tip_y + 10, tip_str, 18, 380);
    
    // Clear tooltip for next frame
    game_state.hover_tooltip = "";
}
