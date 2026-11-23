/// @desc Gameplay logic and state machines for Alien Game

/// @desc Calculates player maximum energy scaled by team size and character class
function game_calculate_player_max_energy(p_class, num_players, energy_bonus = 0) {
    var base_e = 5 + ((variable_struct_exists(p_class, "bonus_energy") && !is_undefined(p_class.bonus_energy)) ? p_class.bonus_energy : 0);
    var scaled_e = base_e;
    
    if (num_players == 1) {
        // Single player: 3x the normal energy
        scaled_e = base_e * 3;
    } else if (num_players == 2) {
        // Two player: 1.5x normal energy (round down)
        scaled_e = floor(base_e * 1.5);
    } else if (num_players == 4) {
        // Four player: every player has 1 less energy
        scaled_e = max(1, base_e - 1);
    } else {
        // Three player: normal energy
        scaled_e = base_e;
    }
    
    return max(1, scaled_e + energy_bonus);
}

/// @desc Reconstructs or updates player operative instances from setup roster
function game_apply_setup_roster(state) {
    var char_classes = game_get_character_classes();
    var p_colors = [
        make_color_rgb(229, 57, 53),   // P1 Red
        make_color_rgb(30, 136, 229),  // P2 Blue
        make_color_rgb(253, 216, 53),  // P3 Yellow
        make_color_rgb(67, 160, 71)    // P4 Green
    ];
    
    var base_node_x = 740;
    var base_node_y = 340;
    if (variable_struct_exists(state, "nodes") && variable_struct_exists(state.nodes, "main_base")) {
        base_node_x = state.nodes.main_base.x;
        base_node_y = state.nodes.main_base.y;
    }
    
    state.num_players = clamp(state.setup_player_count, 1, 4);
    state.players = [];
    for (var i = 0; i < state.num_players; i++) {
        var c_idx = state.setup_player_classes[i] % array_length(char_classes);
        var p_class = char_classes[c_idx];
        var max_e = game_calculate_player_max_energy(p_class, state.num_players, 0);
        
        var raw_name = (is_array(state.setup_player_names) && i < array_length(state.setup_player_names)) ? state.setup_player_names[i] : "";
        var clean_name = string_replace_all(raw_name, " ", "");
        var p_name = (clean_name != "") ? raw_name : ("Player " + string(i + 1));
        
        var ox = (i - 1.5) * 16;
        var oy = (i % 2 == 0 ? -12 : 12);
        var start_x = base_node_x + ox;
        var start_y = base_node_y + oy;
        
        array_push(state.players, {
            id: i,
            name: p_name,
            character: p_class,
            character_idx: c_idx,
            color: p_colors[i],
            energy: max_e,
            max_energy: max_e,
            energy_penalty: 0,
            node: "main_base",
            anim_x: start_x,
            anim_y: start_y,
            target_x: start_x,
            target_y: start_y,
            move_start_x: start_x,
            move_start_y: start_y,
            is_moving: false,
            move_progress: 1.0,
            hop_y: 0,
            action_anim: "",
            action_timer: 0,
            action_max: 0,
            ended_turn: false,
            backpack: {
                wood: 0,
                scrap: 0,
                stone: 0,
                metal: 0,
                crystals: 0,
                power_gem: 0
            }
        });
    }
    state.current_player_idx = 0;
}

/// @desc Checks if all players have completed their actions or depleted energy
function game_check_all_players_ready(state) {
    if (!variable_struct_exists(state, "players") || !is_array(state.players)) return true;
    for (var i = 0; i < state.num_players; i++) {
        var pl = state.players[i];
        var is_ended = variable_struct_exists(pl, "ended_turn") && pl.ended_turn;
        if (pl.energy > 0 && !is_ended) {
            return false;
        }
    }
    return true;
}

/// @desc Cycles to the next available character class, ensuring no duplicate non-default classes
function game_cycle_class_exclusive(cur_c_idx, dir, p_idx, roster_classes) {
    var char_classes = game_get_character_classes();
    var num_classes = array_length(char_classes);
    var candidate = (cur_c_idx + dir + num_classes) % num_classes;
    
    // Search up to num_classes times to find an unselected class or "default"
    for (var step = 0; step < num_classes; step++) {
        var c_id = char_classes[candidate].id;
        
        // "default" (Survivor) is always available to anyone
        if (c_id == "default") {
            return candidate;
        }
        
        // Non-default class: check if already claimed by another operative
        var taken = false;
        for (var op = 0; op < array_length(roster_classes); op++) {
            if (op != p_idx) {
                var other_cid = "";
                if (is_string(roster_classes[op])) {
                    other_cid = roster_classes[op];
                } else if (is_struct(roster_classes[op]) && variable_struct_exists(roster_classes[op], "character_id")) {
                    other_cid = roster_classes[op].character_id;
                } else if (is_real(roster_classes[op])) {
                    other_cid = char_classes[roster_classes[op] % num_classes].id;
                }
                
                if (other_cid == c_id) {
                    taken = true;
                    break;
                }
            }
        }
        
        if (!taken) {
            return candidate;
        }
        
        // Try next candidate in direction
        candidate = (candidate + dir + num_classes) % num_classes;
    }
    
    return 0; // Fallback to default
}

function game_init_state(num_players = 4, chosen_class_indices = undefined, chosen_player_names = undefined) {
    var state = {};
    
    state.num_players = clamp(num_players, 1, 4);
    state.current_player_idx = 0;
    state.round_number = 1;
    state.phase = "player_actions"; // "player_actions", "combat_weapons", "combat_aliens", "game_over", "victory"
    state.endless_mode = false;
    
    // Players setup data
    state.setup_player_count = state.num_players;
    state.setup_player_classes = [0, 0, 0, 0];
    state.setup_player_names = ["Player 1", "Player 2", "Player 3", "Player 4"];
    state.editing_player_name_idx = -1;
    state.name_cursor_timer = 0;
    
    if (is_array(chosen_class_indices)) {
        for (var c = 0; c < min(4, array_length(chosen_class_indices)); c++) {
            state.setup_player_classes[c] = chosen_class_indices[c];
        }
    }
    if (is_array(chosen_player_names)) {
        for (var n = 0; n < min(4, array_length(chosen_player_names)); n++) {
            state.setup_player_names[n] = chosen_player_names[n];
        }
    }
    
    state.setup_count_hover = [false, false, false, false];
    state.setup_prev_hover = [false, false, false, false];
    state.setup_next_hover = [false, false, false, false];
    state.setup_name_hover = [false, false, false, false];
    state.setup_start_hover = false;
    
    // Popup state for automatic player switch when energy is depleted
    state.turn_popup_title = "";
    state.turn_popup_message = "";
    state.turn_popup_color = c_yellow;
    state.turn_popup_timer = 0;
    
    // Map data
    state.nodes = game_get_map_nodes();
    state.edges = game_get_map_edges();
    state.waves = game_get_waves();
    
    // Visual FX & Animations
    state.floating_texts = [];
    state.board_action_effects = [];
    state.screen_shake = 0;
    state.drawn_card_popup = undefined;
    state.hover_tooltip = "";
    
    state.players = [];
    game_apply_setup_roster(state);
    
    // Base & Towers (each can have a stationed defense weapon and its own manual powering cooldown)
    state.towers = [
        { id: 0, name: "Tower 1", node_id: "tower_1", hp: 10, max_hp: 10, alive: true, weapon: undefined, manual_cooldown: 0, manual_powers_this_turn: 0 },
        { id: 1, name: "Tower 2", node_id: "tower_2", hp: 10, max_hp: 10, alive: true, weapon: undefined, manual_cooldown: 0, manual_powers_this_turn: 0 },
        { id: 2, name: "Tower 3", node_id: "tower_3", hp: 10, max_hp: 10, alive: true, weapon: undefined, manual_cooldown: 0, manual_powers_this_turn: 0 },
        { id: 3, name: "Tower 4", node_id: "tower_4", hp: 10, max_hp: 10, alive: true, weapon: undefined, manual_cooldown: 0, manual_powers_this_turn: 0 }
    ];
    
    // Shared Base Storage (Starting gold is 0)
    state.storage = {
        wood: 0,
        scrap: 0,
        stone: 0,
        metal: 0,
        crystals: 0,
        power_gem: 0,
        gold: 0
    };
    
    // Weapons built & Owned Blueprints
    state.weapons = [];
    state.blueprints = [];
    
    // Weapon blueprint shop deck & display (Deck of cards system)
    state.shop_catalog = game_get_weapon_catalog();
    state.shop_deck = game_create_shop_deck();
    state.shop_discard = [];
    state.shop_available_items = [];
    for (var i = 0; i < 3; i++) {
        if (array_length(state.shop_deck) > 0) {
            array_push(state.shop_available_items, array_pop(state.shop_deck));
        }
    }
    state.shop_reroll_cost = 3;
    state.days_without_reroll = 0;
    state.rerolled_this_day = false;
    state.shop_reroll_hover = false;
    
    // Resource decks
    state.decks = {
        forest: game_create_deck("forest"),
        cave_1: game_create_deck("cave_1"),
        cave_2: game_create_deck("cave_2"),
        cave_3: game_create_deck("cave_3")
    };
    
    // Town favors
    state.town_favors = game_get_town_favors();
    state.active_town_favor = 0; // Starts with Wood Favor
    
    // Alien zones
    state.alien_catalog = game_get_alien_catalog();
    state.spawn_zone = [];
    state.active_zone = [];
    state.alien_uid = 1;
    
    // Log ticker
    state.action_logs = ["Game started! Defend the 4 Base Towers across 17 Waves."];
    
    // Settings & Display state
    state.settings = {
        display_mode: "borderless", // "borderless" | "fullscreen" | "windowed"
        resolution_idx: 0,          // 0: 1920x1080, 1: 1600x900, 2: 1366x768, 3: 1280x720
        sfx_volume: 0.8,
        slider_dragging: false
    };
    state.resolutions = [
        [1920, 1080, "1920 x 1080"],
        [1600, 900,  "1600 x 900"],
        [1366, 768,  "1366 x 768"],
        [1280, 720,  "1280 x 720"]
    ];
    state.btn_settings_hover = false;
    state.settings_mode_borderless_hover = false;
    state.settings_mode_fullscreen_hover = false;
    state.settings_mode_windowed_hover = false;
    state.settings_res_hover = -1;
    state.settings_test_sfx_hover = false;
    state.settings_close_hover = false;
    state.settings_restart_hover = false;

    // UI Modal state
    state.modal = undefined; // undefined or struct: { type: "shop"|"craft"|"repair"|"town"|"pylon_buff"|"tanking"|"alert"|"settings", ... }
    state.toast_message = "";
    state.toast_timer = 0;
    
    // Hover flags initialized
    state.btn_gather_hover = false;
    state.btn_craft_hover = false;
    state.btn_shop_hover = false;
    state.btn_repair_hover = false;
    state.btn_town_hover = false;
    state.btn_fire_hover = false;
    state.btn_endturn_hover = false;
    state.btn_combat_hover = false;
    state.active_alien_hover = -1;
    state.alien_inspect_hover = undefined;
    state.alien_inspect_close_hover = false;

    state.modal_close_hover = false;
    state.shop_buy_hover = -1;
    state.shop_target_tower = 0;
    state.workstation_craft_bp_idx = -1;
    state.workstation_craft_target_tower = -1;
    state.btn_dismantle_hover = false;
    state.town_sell_hover = -1;
    state.town_sell_count = 1;
    state.repair_tower_1_hover = -1;

    // Active aliens horizontal scroll system
    state.active_aliens_scroll_x = 0;
    state.active_aliens_dragging = false;
    state.btn_active_scroll_left = false;
    state.btn_active_scroll_right = false;
    state.active_aliens_surf = undefined;

    // Role selection horizontal scroll & clipping system
    state.setup_scroll_x = [0, 0, 0, 0];
    state.setup_scroll_left_hover = [false, false, false, false];
    state.setup_scroll_right_hover = [false, false, false, false];
    state.setup_surf = [undefined, undefined, undefined, undefined];

    // Dynamic player tab layout bounds
    state.player_tab_bounds = [];
    
    // Screen navigation state ("title" | "local_setup" | "online_username" | "online_browser" | "online_lobby" | "game")
    state.screen = "title";
    
    // Animated title starfield
    state.title_stars = [];
    for (var s = 0; s < 120; s++) {
        array_push(state.title_stars, {
            x: random(1920),
            y: random(1080),
            spd: random_range(0.25, 0.95),
            size: random_range(1.0, 2.5),
            alpha: random_range(0.3, 0.95),
            twinkle: random(360)
        });
    }
    
    // Title menu hovers
    state.title_btn_local_hover = false;
    state.title_btn_online_hover = false;
    state.title_btn_settings_hover = false;
    state.title_btn_quit_hover = false;
    
    // Local setup screen hovers
    state.local_setup_count_hover = [false, false, false, false];
    state.local_setup_name_hover = [false, false, false, false];
    state.local_setup_prev_hover = [false, false, false, false];
    state.local_setup_next_hover = [false, false, false, false];
    state.local_setup_start_hover = false;
    state.local_setup_back_hover = false;
    
    // Online multiplayer screens hovers
    state.online_user_confirm_hover = false;
    state.online_user_back_hover = false;
    state.online_browser_create_hover = false;
    state.online_browser_refresh_hover = false;
    state.online_browser_direct_hover = false;
    state.online_browser_back_hover = false;
    state.online_browser_edit_user_hover = false;
    state.online_browser_room_hover = -1;
    state.online_lobby_leave_hover = false;
    state.online_lobby_start_hover = false;
    state.online_lobby_prev_hover = false;
    state.online_lobby_next_hover = false;
    
    // Network Manager
    network_init_manager(state);

    // Window focus & Fullscreen toggle state
    state.prev_window_focus = true;
    state.has_had_focus = false;

    // Action & Combat log scroll, expand and drag state
    state.action_log_x = 1520; // Default right panel left edge
    state.action_log_scroll_y = 0; // Vertical scroll
    state.action_log_scroll_x = 0; // Horizontal scroll
    state.action_log_max_scroll_y = 0;
    state.action_log_max_scroll_x = 0;
    state.action_log_dragging = false; // Dragging left border to resize panel
    state.action_log_drag_start_mx = 0;
    state.action_log_drag_start_x = 1520;
    state.action_log_v_drag = false; // Dragging vertical scrollbar
    state.action_log_v_drag_start_my = 0;
    state.action_log_v_drag_start_val = 0;
    state.action_log_h_drag = false; // Dragging horizontal scrollbar
    state.action_log_h_drag_start_mx = 0;
    state.action_log_h_drag_start_val = 0;
    state.action_log_surf = undefined;
    state.action_log_resizer_hover = false;
    state.action_log_v_thumb_hover = false;
    state.action_log_h_thumb_hover = false;
    state.action_log_btn_toggle_hover = false;
    state.action_log_btn_top_hover = false;
    state.action_log_btn_up_hover = false;
    state.action_log_btn_down_hover = false;
    state.action_log_btn_left_hover = false;
    state.action_log_btn_right_hover = false;

    // In-game log chat system
    state.chat_input_text = "";
    state.chat_input_active = false;
    state.chat_input_hover = false;
    state.chat_send_hover = false;
    state.chat_cursor_timer = 0;

    // Game over loss dialog button hovers
    state.gameover_restart_hover = false;
    state.gameover_quit_hover = false;
    state.repair_tower_3_hover = -1;
    state.repair_weapon_hover = -1;

    state.setup_p1_hover = false;
    state.setup_p2_hover = false;
    state.setup_p3_hover = false;
    state.setup_p4_hover = false;

    state.victory_endless_hover = false;
    state.victory_restart_hover = false;
    state.victory_exit_hover = false;
    state.gameover_restart_hover = false;
    
    // Dedicated Tactical Combat Screen State
    state.tower_weapon_shots = [0, 0, 0, 0];
    state.tower_weapon_max_shots = [0, 0, 0, 0];
    state.tower_weapon_used = [true, true, true, true];
    state.combat_selected_tower = -1;
    state.combat_selected_weapon_idx = -1;
    state.combat_weapons_queue = [];
    state.combat_subphase = "player_weapons"; // "player_weapons" | "alien_attacks" | "combat_concluded"
    state.combat_concluded_reason = "";
    state.combat_conclude_btn_hover = false;
    state.combat_speed_2x = false;
    state.combat_speed_btn_hover = false;
    state.combat_projectiles = [];
    state.combat_player_projectiles = [];
    state.combat_impact_effects = [];
    state.alien_attack_idx = 0;
    state.alien_attack_delay = 0;
    state.combat_alien_hover = -1;
    state.combat_tower_hover = [false, false, false, false];
    state.combat_tesla_btn_hover = false;
    state.combat_advance_hover = false;
    state.combat_alien_coords = [];
    state.combat_tower_coords = [];
    
    // Workstation blueprint scrollbar state
    state.workstation_bp_scroll_y = 0;
    state.workstation_bp_drag = false;
    state.workstation_bp_drag_start_my = 0;
    state.workstation_bp_drag_start_val = 0;
    state.workstation_bp_thumb_hover = false;
    state.workstation_bp_usable_track = 1;
    state.workstation_bp_max_scroll = 0;
    
    // Spawn Wave 1 (Grace period: no aliens)
    game_spawn_wave_for_round(state, 1);
    
    // Initial 3 items in shop
    game_reroll_shop(state, state.players[0], true);
    
    return state;
}

/// @desc Applies display mode and resolution
/// @param {string} mode "borderless" | "fullscreen" | "windowed"
/// @param {real} res_w Window width (for windowed mode)
/// @param {real} res_h Window height (for windowed mode)
function game_apply_display_settings(mode, res_w, res_h) {
    if (mode == "borderless") {
        window_enable_borderless_fullscreen(true);
        window_set_fullscreen(true);
    } else if (mode == "fullscreen") {
        window_enable_borderless_fullscreen(false);
        window_set_fullscreen(true);
    } else if (mode == "windowed") {
        window_enable_borderless_fullscreen(false);
        window_set_fullscreen(false);
        window_set_showborder(true);
        var disp_w = display_get_width();
        var disp_h = display_get_height();
        var target_w = res_w;
        var target_h = res_h;
        if (target_w >= disp_w && disp_w > 1280) target_w = min(res_w, 1600);
        if (target_h >= disp_h && disp_h > 720) target_h = min(res_h, 900);
        window_set_size(target_w, target_h);
        window_center();
        surface_resize(application_surface, target_w, target_h);
    }
    display_set_gui_size(1920, 1080);
}

function game_log(state, msg) {
    array_insert(state.action_logs, 0, msg);
    if (array_length(state.action_logs) > 200) {
        array_delete(state.action_logs, 200, 1);
    }
    state.toast_message = msg;
    state.toast_timer = 180;
}

/// @desc Checks if current player ran out of energy, switching to next player with unused energy and triggering a popup
function game_check_player_energy_depleted(state, player) {
    if (player.energy <= 0) {
        player.energy = 0;
        
        // In online multiplayer, each player plays asynchronously and only controls their own pawn
        if (state.is_online) {
            player.ended_turn = true;
            network_broadcast_action(state, "action_player_turn_done", { player_idx: state.net_my_player_idx });
            state.toast_message = "Energy depleted! Waiting for squad mates...";
            state.toast_timer = 120;
            
            if (game_check_all_players_ready(state)) {
                for (var i = array_length(state.active_zone) - 1; i >= 0; i--) {
                    if (!state.active_zone[i].alive) {
                        array_delete(state.active_zone, i, 1);
                    }
                }
                if (array_length(state.active_zone) == 0) {
                    game_start_weapons_attack_phase(state);
                    return true;
                }
                state.turn_popup_title = "ALL SQUAD OPERATIVES READY!";
                state.turn_popup_message = "All squad operatives are ready. Initiating base defense phase!";
                state.turn_popup_color = make_color_rgb(231, 76, 60);
                state.turn_popup_timer = 180;
                game_log(state, "All squad operatives are ready! Beginning Defense Phase.");
                state.phase = "combat_weapons";
                game_start_weapons_attack_phase(state);
                return true;
            }
            return true;
        }
        
        // Find next player with unused energy
        var next_p_idx = -1;
        for (var step = 1; step <= state.num_players; step++) {
            var check_idx = (state.current_player_idx + step) % state.num_players;
            if (state.players[check_idx].energy > 0) {
                next_p_idx = check_idx;
                break;
            }
        }
        
        if (next_p_idx >= 0 && next_p_idx != state.current_player_idx) {
            state.current_player_idx = next_p_idx;
            var next_p = state.players[next_p_idx];
            
            // Popup notification
            state.turn_popup_title = string_upper(player.name) + " OUT OF ENERGY!";
            state.turn_popup_message = "Turn automatically switched to " + next_p.name + " (" + string(next_p.energy) + " Energy remaining)";
            state.turn_popup_color = next_p.color;
            state.turn_popup_timer = 180;
            
            game_log(state, player.name + " ran out of Energy! Switched to " + next_p.name + ".");
            game_play_sfx("click");
            return true;
        }
        else {
            // All players are out of energy!
            // Clean dead aliens first to accurately check if any active threats exist
            for (var i = array_length(state.active_zone) - 1; i >= 0; i--) {
                if (!state.active_zone[i].alive) {
                    array_delete(state.active_zone, i, 1);
                }
            }
            
            // If no hostiles or towers attacking, directly start the new day and skip combat UI!
            if (array_length(state.active_zone) == 0) {
                game_start_weapons_attack_phase(state);
                return true;
            }
            
            state.turn_popup_title = "ALL PLAYERS OUT OF ENERGY!";
            state.turn_popup_message = "All team operatives have used their energy. Initiating base defense phase!";
            state.turn_popup_color = make_color_rgb(231, 76, 60);
            state.turn_popup_timer = 180;
            
            game_log(state, "All players are out of Energy! Beginning Defense Phase.");
            state.phase = "combat_weapons";
            game_start_weapons_attack_phase(state);
            return true;
        }
    }
    return false;
}

function game_is_adjacent(state, node_a, node_b) {
    if (node_a == node_b) return false;
    for (var i = 0; i < array_length(state.edges); i++) {
        var edge = state.edges[i];
        if ((edge[0] == node_a && edge[1] == node_b) || (edge[0] == node_b && edge[1] == node_a)) {
            return true;
        }
    }
    return false;
}

function game_player_get_move_cost(player) {
    var cost = 2; // Moving costs 2 Energy by default
    if (variable_struct_exists(player, "character") && !is_undefined(player.character)) {
        if (player.character.id == "pathfinder" || player.character.id == "scout") {
            cost = 1; // Roles that have move cost 1 less
        }
    }
    return cost;
}

function game_player_can_move(state, player, target_node) {
    var move_cost = game_player_get_move_cost(player);
    if (player.energy < move_cost) return false;
    return game_is_adjacent(state, player.node, target_node);
}

function game_player_move(state, player, target_node) {
    if (!game_player_can_move(state, player, target_node)) return false;
    
    var move_cost = game_player_get_move_cost(player);
    player.energy -= move_cost;
    
    var old_node_key = player.node;
    var old_node = state.nodes[$ old_node_key];
    var new_node = state.nodes[$ target_node];
    
    var p_idx = player.id;
    var ox = (p_idx - 1.5) * 16;
    var oy = (p_idx % 2 == 0 ? -12 : 12);
    
    // Smooth animated movement setup
    if (!variable_struct_exists(player, "anim_x")) {
        player.anim_x = old_node.x + ox;
        player.anim_y = old_node.y + oy;
    }
    player.move_start_x = player.anim_x;
    player.move_start_y = player.anim_y;
    player.target_x = new_node.x + ox;
    player.target_y = new_node.y + oy;
    player.is_moving = true;
    player.move_progress = 0.0;
    player.hop_y = 0;
    
    player.node = target_node;
    var node_name = new_node.name;
    game_log(state, player.name + " moved to " + node_name + " (" + string(move_cost) + " Energy spent).");
    game_play_sfx("click");
    
    // Spawn departure dust puff
    game_spawn_board_action_effect(state, old_node.x + ox, old_node.y + oy, "move_dust", player.color);
    
    // Auto-deposit upon reaching main_base
    if (target_node == "main_base") {
        game_player_deposit(state, player);
    }
    
    game_check_player_energy_depleted(state, player);
    return true;
}

function game_player_deposit(state, player) {
    var total_deposited = 0;
    var keys = variable_struct_get_names(player.backpack);
    for (var i = 0; i < array_length(keys); i++) {
        var k = keys[i];
        var amt = player.backpack[$ k];
        if (amt > 0) {
            state.storage[$ k] += amt;
            player.backpack[$ k] = 0;
            total_deposited += amt;
        }
    }
    if (total_deposited > 0) {
        game_log(state, player.name + " deposited " + string(total_deposited) + " items into Base Storage.");
        game_trigger_player_action(state, player, "deposit", "+STORED (" + string(total_deposited) + ")", make_color_rgb(100, 220, 255));
    }
}

/// @desc Spawns dynamic particle burst or ripple on the board
function game_spawn_board_action_effect(state, ex, ey, type, color = c_white) {
    if (!variable_struct_exists(state, "board_action_effects") || !is_array(state.board_action_effects)) {
        state.board_action_effects = [];
    }
    
    var count = 12;
    var rad = 32;
    var max_l = 28;
    
    if (type == "gather_forest") {
        count = 14;
        rad = 36;
    } else if (type == "gather_cave") {
        count = 16;
        rad = 36;
    } else if (type == "craft") {
        count = 20;
        rad = 42;
    } else if (type == "deposit") {
        count = 14;
        rad = 34;
    } else if (type == "dismantle") {
        count = 16;
        rad = 38;
    } else if (type == "trade") {
        count = 16;
        rad = 38;
    } else if (type == "repair" || type == "forge") {
        count = 18;
        rad = 40;
    } else if (type == "fire") {
        count = 16;
        rad = 45;
    } else if (type == "move_dust" || type == "arrival_puff") {
        count = 8;
        rad = 20;
        max_l = 16;
    } else if (type == "motion_spark") {
        count = 2;
        rad = 10;
        max_l = 12;
    }
    
    var particles = [];
    for (var s = 0; s < count; s++) {
        var ang = random(360);
        var spd = random_range(1.5, 5.5);
        var p_col = color;
        var p_shape = "circle";
        
        if (type == "gather_forest") {
            p_col = (irandom(1) == 0) ? make_color_rgb(76, 175, 80) : make_color_rgb(141, 110, 99);
        } else if (type == "trade") {
            p_col = (irandom(1) == 0) ? make_color_rgb(255, 215, 0) : make_color_rgb(255, 245, 150);
        } else if (type == "craft") {
            p_col = (irandom(1) == 0) ? make_color_rgb(255, 140, 20) : make_color_rgb(255, 220, 80);
        } else if (type == "dismantle") {
            p_col = (irandom(1) == 0) ? make_color_rgb(180, 180, 190) : make_color_rgb(220, 80, 60);
        } else if (type == "repair" || type == "forge") {
            p_col = (irandom(1) == 0) ? make_color_rgb(0, 229, 255) : make_color_rgb(105, 240, 174);
            if (irandom(2) == 0) p_shape = "cross";
        }
        
        array_push(particles, {
            x: ex,
            y: ey,
            vx: lengthdir_x(spd, ang),
            vy: lengthdir_y(spd, ang) - (type == "trade" || type == "craft" ? random_range(1.0, 2.5) : 0),
            gravity: 0.1,
            size: random_range(2.5, 5.0),
            color: p_col,
            shape: p_shape,
            life: irandom_range(max_l - 8, max_l),
            max_life: max_l
        });
    }
    
    array_push(state.board_action_effects, {
        x: ex,
        y: ey,
        type: type,
        life: 0,
        max_life: max_l,
        max_radius: rad,
        color: color,
        particles: particles
    });
}

/// @desc Triggers an action animation on the player pawn and creates floating text feedback
function game_trigger_player_action(state, player, action_type, text_label = "", text_color = c_white, custom_x = undefined, custom_y = undefined) {
    player.action_anim = action_type;
    player.action_timer = 24;
    player.action_max = 24;
    
    var pnode = state.nodes[$ player.node];
    var fx = is_undefined(custom_x) ? (variable_struct_exists(player, "anim_x") ? player.anim_x : (!is_undefined(pnode) ? pnode.x : 740)) : custom_x;
    var fy = is_undefined(custom_y) ? (variable_struct_exists(player, "anim_y") ? player.anim_y : (!is_undefined(pnode) ? pnode.y : 340)) : custom_y;
    
    if (text_label != "") {
        if (!variable_struct_exists(state, "floating_texts") || !is_array(state.floating_texts)) {
            state.floating_texts = [];
        }
        array_push(state.floating_texts, {
            x: fx,
            y: fy - 26,
            text: text_label,
            color: text_color,
            alpha: 1.0,
            vy: -1.6,
            life: 52,
            max_life: 52
        });
    }
    
    game_spawn_board_action_effect(state, fx, fy, action_type, text_color);
}

function game_player_gather(state, player) {
    var cost = (variable_struct_exists(player, "character") && player.character.id == "scout") ? 2 : 1;
    if (player.energy < cost) {
        game_log(state, "Not enough Energy to gather! (Requires " + string(cost) + " Energy)");
        return false;
    }
    
    var cur_node = state.nodes[$ player.node];
    var deck_key = "";
    if (cur_node.type == "gather_forest") deck_key = "forest";
    else if (cur_node.type == "gather_cave1") deck_key = "cave_1";
    else if (cur_node.type == "gather_cave2") deck_key = "cave_2";
    else if (cur_node.type == "gather_cave3") deck_key = "cave_3";
    
    if (deck_key == "") {
        game_log(state, "Cannot gather resources here!");
        return false;
    }
    
    player.energy -= cost;
    
    // Draw card
    var deck = state.decks[$ deck_key];
    if (array_length(deck) == 0) {
        // Reshuffle deck
        state.decks[$ deck_key] = game_create_deck(deck_key);
        deck = state.decks[$ deck_key];
    }
    
    var card = array_pop(deck);
    if (card.type == "resource") {
        var amt = card.amount;
        if (variable_struct_exists(player, "character") && player.character.id == "miner") {
            if (irandom(99) < 25) {
                amt += 1;
                game_log(state, player.name + " (Cavern Miner Perk): Extracted +1 bonus " + card.resource + "!");
            }
        }
        state.storage[$ card.resource] += amt;
        player.backpack[$ card.resource] += amt;
        var rname = state.nodes[$ player.node].name;
        game_log(state, player.name + " drew " + card.name + " at " + rname + " (Added to Team Pool)!");
        game_play_sfx("gather");
        
        var res_defs = game_get_resource_definitions();
        var rdef = res_defs[$ card.resource];
        var is_forest = (cur_node.type == "gather_forest");
        game_trigger_player_action(state, player, is_forest ? "gather_forest" : "gather_cave", "+" + string(amt) + " " + string_upper(rdef.name), rdef.color);
    }
    else if (card.type == "event") {
        if (variable_struct_exists(player, "character") && player.character.id == "miner" && string_pos("Bat", card.name) > 0) {
            game_log(state, player.name + " (Cavern Miner Perk): Immune to cave bats! No energy lost.");
            game_trigger_player_action(state, player, "gather_cave", "IMMUNE TO BATS!", make_color_rgb(105, 240, 174));
        } else {
            player.energy = max(0, player.energy + card.energy_delta);
            game_log(state, player.name + ": " + card.name + " (" + card.desc + ")");
            game_play_sfx("hit");
            game_trigger_player_action(state, player, "event", card.name + " (" + string(card.energy_delta) + "E)", make_color_rgb(255, 100, 100));
        }
    }
    
    game_check_player_energy_depleted(state, player);
    return true;
}

function game_player_craft_metal(state, player) {
    var cost = (variable_struct_exists(player, "character") && player.character.id == "scout") ? 2 : 1;
    if (player.energy < cost) {
        game_log(state, "Need " + string(cost) + " Energy to craft Metal!");
        return false;
    }
    if (player.node != "main_base" && player.node != "workstation") {
        game_log(state, "Crafting is only available at Main Base or Workstation!");
        return false;
    }
    if (state.storage.stone < 1 || state.storage.scrap < 1) {
        game_log(state, "Need 1 Stone and 1 Scrap in Storage to craft 1 Metal!");
        return false;
    }
    
    player.energy -= cost;
    state.storage.stone -= 1;
    state.storage.scrap -= 1;
    state.storage.metal += 1;
    game_log(state, player.name + " forged 1 Metal from 1 Stone and 1 Scrap (" + string(cost) + " Energy spent)!");
    game_play_sfx("repair");
    game_trigger_player_action(state, player, "craft", "+1 METAL FORGED", make_color_rgb(207, 216, 220));
    game_check_player_energy_depleted(state, player);
    return true;
}

/// @desc Rerolls what 3 weapon blueprints are displayed in the shop
function game_reroll_shop(state, player, is_free = false) {
    if (!is_free) {
        if (player.node != "shop") {
            game_log(state, "Must be at the Shop to reroll available weapons!");
            return false;
        }
        if (state.storage.gold < state.shop_reroll_cost) {
            game_log(state, "Need " + string(state.shop_reroll_cost) + " Gold to reroll shop! (You have " + string(state.storage.gold) + "g)");
            return false;
        }
        state.storage.gold -= state.shop_reroll_cost;
        var paid = state.shop_reroll_cost;
        state.shop_reroll_cost += 2; // Keeps costing 2 more every time
        state.days_without_reroll = 0;
        state.rerolled_this_day = true;
        game_play_sfx("coin");
        game_log(state, player.name + " paid " + string(paid) + " Gold to reroll shop! (Next reroll: " + string(state.shop_reroll_cost) + "g)");
    }
    
    // Cycle currently displayed cards into discard pile
    for (var i = 0; i < array_length(state.shop_available_items); i++) {
        var it = state.shop_available_items[i];
        if (!is_undefined(it)) {
            array_push(state.shop_discard, it);
        }
    }
    state.shop_available_items = [];
    
    // Deal 3 new cards from the shop deck
    for (var i = 0; i < 3; i++) {
        if (array_length(state.shop_deck) == 0) {
            if (array_length(state.shop_discard) > 0) {
                state.shop_deck = state.shop_discard;
                state.shop_discard = [];
                for (var d = array_length(state.shop_deck) - 1; d > 0; d--) {
                    var j = irandom(d);
                    var tmp = state.shop_deck[d];
                    state.shop_deck[d] = state.shop_deck[j];
                    state.shop_deck[j] = tmp;
                }
            } else {
                state.shop_deck = game_create_shop_deck();
            }
        }
        if (array_length(state.shop_deck) > 0) {
            array_push(state.shop_available_items, array_pop(state.shop_deck));
        }
    }
    return true;
}

function game_player_buy_blueprint(state, player, slot_or_item) {
    var cost = (variable_struct_exists(player, "character") && player.character.id == "scout") ? 2 : 1;
    if (player.energy < cost) {
        game_log(state, "Need " + string(cost) + " Energy to buy blueprint!");
        return false;
    }
    if (player.node != "shop") {
        game_log(state, "Must be at the Shop to purchase blueprints!");
        return false;
    }
    
    var slot = -1;
    var item = undefined;
    if (is_real(slot_or_item)) {
        if (slot_or_item >= 0 && slot_or_item < array_length(state.shop_available_items)) {
            slot = slot_or_item;
            item = state.shop_available_items[slot];
        } else if (slot_or_item >= 0 && slot_or_item < array_length(state.shop_catalog)) {
            var cat_item = state.shop_catalog[slot_or_item];
            for (var s = 0; s < array_length(state.shop_available_items); s++) {
                if (!is_undefined(state.shop_available_items[s]) && state.shop_available_items[s].id == cat_item.id) {
                    slot = s;
                    item = state.shop_available_items[s];
                    break;
                }
            }
        }
    } else if (is_struct(slot_or_item)) {
        item = slot_or_item;
        for (var s = 0; s < array_length(state.shop_available_items); s++) {
            if (state.shop_available_items[s] == item) {
                slot = s;
                break;
            }
        }
    }
    
    if (is_undefined(item)) {
        game_log(state, "Blueprint is no longer available in the shop!");
        return false;
    }
    if (state.storage.gold < item.cost_gold) {
        game_log(state, "Not enough Gold! (Requires " + string(item.cost_gold) + " Gold)");
        return false;
    }
    
    // Deduct cost
    player.energy -= cost;
    state.storage.gold -= item.cost_gold;
    
    // Add blueprint to inventory
    array_push(state.blueprints, {
        catalog_id: item.id,
        name: item.name,
        hp: item.hp,
        damage: item.damage,
        cost_res: item.cost_res,
        ability: item.ability,
        target_count: item.target_count,
        splash_count: item[$ "splash_count"] ?? 0,
        splash_dmg: item[$ "splash_dmg"] ?? 0
    });
    
    game_log(state, player.name + " bought the " + item.name + " Blueprint (" + string(item.cost_gold) + "g)! Bring it to the Workstation to forge and mount it.");
    game_play_sfx("buy");
    game_trigger_player_action(state, player, "trade", "BOUGHT " + string_upper(item.name), make_color_rgb(255, 215, 0));
    
    // If deck is empty, reshuffle discard pile or create fresh deck
    if (slot >= 0) {
        if (array_length(state.shop_deck) == 0) {
            if (array_length(state.shop_discard) > 0) {
                state.shop_deck = state.shop_discard;
                state.shop_discard = [];
                for (var d = array_length(state.shop_deck) - 1; d > 0; d--) {
                    var j = irandom(d);
                    var tmp = state.shop_deck[d];
                    state.shop_deck[d] = state.shop_deck[j];
                    state.shop_deck[j] = tmp;
                }
                game_log(state, "Shop blueprint deck reshuffled!");
            } else {
                state.shop_deck = game_create_shop_deck();
            }
        }
        
        // Immediately draw a new card from top of shop_deck to take its place
        if (array_length(state.shop_deck) > 0) {
            var new_card = array_pop(state.shop_deck);
            state.shop_available_items[slot] = new_card;
            game_log(state, "A new blueprint appeared in the shop: " + new_card.name + " (" + string(new_card.cost_gold) + "g)!");
        } else {
            state.shop_available_items[slot] = undefined;
        }
    }
    
    game_check_player_energy_depleted(state, player);
    return true;
}

function game_player_craft_blueprint(state, player, bp_idx, target_tower_idx) {
    var cost = (variable_struct_exists(player, "character") && player.character.id == "scout") ? 2 : 1;
    if (player.energy < cost) {
        game_log(state, "Need " + string(cost) + " Energy to forge defense!");
        return false;
    }
    if (player.node != "workstation") {
        game_log(state, "Must be at the Workstation area to forge defenses!");
        return false;
    }
    if (bp_idx < 0 || bp_idx >= array_length(state.blueprints)) {
        game_log(state, "Invalid blueprint selection!");
        return false;
    }
    
    target_tower_idx = clamp(target_tower_idx, 0, 3);
    var tower = state.towers[target_tower_idx];
    if (!tower.alive) {
        game_log(state, tower.name + " is destroyed and cannot mount weapons!");
        return false;
    }
    
    // Check if tower already has an active weapon mounted
    if (!is_undefined(tower.weapon) && tower.weapon.alive && tower.weapon.hp > 0) {
        game_log(state, tower.name + " already has an active " + tower.weapon.name + "! Travel to " + tower.name + " to dismantle and destroy it first.");
        return false;
    }
    
    var bp = state.blueprints[bp_idx];
    
    // Check required resources in storage
    var reqs = variable_struct_get_names(bp.cost_res);
    for (var i = 0; i < array_length(reqs); i++) {
        var r = reqs[i];
        if (state.storage[$ r] < bp.cost_res[$ r]) {
            game_log(state, "Missing resources to forge " + bp.name + "! Needs " + string(bp.cost_res[$ r]) + " " + r + " in storage.");
            return false;
        }
    }
    
    // Deduct resources & energy
    player.energy -= cost;
    for (var i = 0; i < array_length(reqs); i++) {
        var r = reqs[i];
        state.storage[$ r] -= bp.cost_res[$ r];
    }
    
    // Build and mount weapon
    var new_w = {
        catalog_id: bp.catalog_id,
        name: bp.name,
        hp: bp.hp,
        max_hp: bp.hp,
        damage: bp.damage,
        bonus_damage: 0,
        ability: bp.ability,
        target_count: bp.target_count,
        splash_count: bp.splash_count,
        splash_dmg: bp.splash_dmg,
        cooldown: 0,
        cost_res: bp.cost_res,
        power_gem_used: false,
        disabled: false,
        stationed_tower: target_tower_idx,
        alive: true
    };
    
    tower.weapon = new_w;
    tower.manual_cooldown = 0;
    tower.manual_powers_this_turn = 0;
    array_push(state.weapons, new_w);
    
    // Remove the forged blueprint
    array_delete(state.blueprints, bp_idx, 1);
    
    game_log(state, player.name + " forged " + bp.name + " at the Workstation and mounted it to " + tower.name + "!");
    game_play_sfx("buy");
    game_trigger_player_action(state, player, "forge", "MOUNTED " + string_upper(bp.name), make_color_rgb(100, 230, 255));
    game_check_player_energy_depleted(state, player);
    return true;
}

function game_player_dismantle_weapon(state, player, tower_idx) {
    var cost = (variable_struct_exists(player, "character") && player.character.id == "scout") ? 2 : 1;
    if (player.energy < cost) {
        game_log(state, "Need " + string(cost) + " Energy to dismantle weapon!");
        return false;
    }
    if (player.node != ("tower_" + string(tower_idx + 1))) {
        game_log(state, "Must be stationed at Tower " + string(tower_idx + 1) + " to dismantle its weapon!");
        return false;
    }
    
    var tower = state.towers[tower_idx];
    if (is_undefined(tower.weapon) || !tower.weapon.alive || tower.weapon.hp <= 0) {
        game_log(state, "No active weapon to dismantle at " + tower.name + "!");
        return false;
    }
    
    var old_w = tower.weapon;
    var w_name = old_w.name;
    old_w.alive = false;
    tower.weapon = undefined;
    tower.manual_cooldown = 0;
    tower.manual_powers_this_turn = 0;
    
    for (var wi = array_length(state.weapons) - 1; wi >= 0; wi--) {
        if (state.weapons[wi] == old_w) {
            array_delete(state.weapons, wi, 1);
            break;
        }
    }
    
    // Salvage 1 scrap
    state.storage.scrap += 1;
    player.energy -= cost;
    
    game_log(state, player.name + " dismantled and destroyed the " + w_name + " at " + tower.name + " (+1 Scrap salvaged). Mount is now empty!");
    game_play_sfx("hit");
    game_trigger_player_action(state, player, "dismantle", "+1 SCRAP (DISMANTLED)", make_color_rgb(255, 120, 120));
    game_check_player_energy_depleted(state, player);
    return true;
}

function game_player_buy_weapon(state, player, catalog_idx, target_tower_idx) {
    return game_player_buy_blueprint(state, player, catalog_idx);
}

function game_player_repair_tower(state, player, tower_idx, type) {
    var cost = (variable_struct_exists(player, "character") && player.character.id == "scout") ? 2 : 1;
    if (player.energy < cost) {
        game_log(state, "Need " + string(cost) + " Energy to repair!");
        return false;
    }
    if (player.node != "workstation") {
        game_log(state, "Base repairs can only be conducted at the Workstation area!");
        return false;
    }
    
    var tower = state.towers[tower_idx];
    if (!tower.alive || tower.hp <= 0) {
        game_log(state, tower.name + " is destroyed and cannot be repaired!");
        return false;
    }
    if (tower.hp >= tower.max_hp) {
        game_log(state, tower.name + " is already at full health!");
        return false;
    }
    
    var rep_bonus = (variable_struct_exists(player, "character") && player.character.id == "engineer") ? 1 : 0;
    
    if (type == "stone_wood") {
        if (state.storage.stone < 1 || state.storage.wood < 1) {
            game_log(state, "Requires 1 Stone and 1 Wood in Storage!");
            return false;
        }
        state.storage.stone -= 1;
        state.storage.wood -= 1;
        tower.hp = min(tower.max_hp, tower.hp + 1 + rep_bonus);
        player.energy -= cost;
        game_log(state, player.name + " repaired " + tower.name + " (+" + string(1 + rep_bonus) + " HP).");
        game_play_sfx("repair");
        game_trigger_player_action(state, player, "repair", "+" + string(1 + rep_bonus) + " HP (" + tower.name + ")", make_color_rgb(76, 175, 80));
        game_check_player_energy_depleted(state, player);
        return true;
    }
    else if (type == "metal_or_scrap_stone") {
        if (state.storage.metal >= 1) {
            state.storage.metal -= 1;
        } else if (state.storage.scrap >= 1 && state.storage.stone >= 1) {
            state.storage.scrap -= 1;
            state.storage.stone -= 1;
        } else {
            game_log(state, "Requires 1 Metal OR (1 Scrap + 1 Stone) in Storage!");
            return false;
        }
        tower.hp = min(tower.max_hp, tower.hp + 3 + rep_bonus);
        player.energy -= cost;
        game_log(state, player.name + " fortified " + tower.name + " (+" + string(3 + rep_bonus) + " HP).");
        game_play_sfx("repair");
        game_trigger_player_action(state, player, "repair", "+" + string(3 + rep_bonus) + " HP (" + tower.name + ")", make_color_rgb(0, 229, 255));
        game_check_player_energy_depleted(state, player);
        return true;
    }
    
    return false;
}

function game_player_repair_weapon(state, player, weapon_idx, method, res_choice) {
    var cost = (variable_struct_exists(player, "character") && player.character.id == "scout") ? 2 : 1;
    if (player.energy < cost) {
        game_log(state, "Need " + string(cost) + " Energy to repair!");
        return false;
    }
    if (player.node != "workstation") {
        game_log(state, "Weapon repairs can only be conducted at the Workstation area!");
        return false;
    }
    if (weapon_idx < 0 || weapon_idx >= array_length(state.weapons)) return false;
    var w = state.weapons[weapon_idx];
    if (!w.alive || w.hp <= 0) {
        game_log(state, w.name + " is destroyed!");
        return false;
    }
    if (w.hp >= w.max_hp) {
        game_log(state, w.name + " is already at full health!");
        return false;
    }
    
    var rep_bonus = (variable_struct_exists(player, "character") && player.character.id == "engineer") ? 1 : 0;
    
    if (method == "recipe_resource") {
        if (!variable_struct_exists(w.cost_res, res_choice) || state.storage[$ res_choice] < 1) {
            game_log(state, "Requires 1 " + res_choice + " from its blueprint!");
            return false;
        }
        state.storage[$ res_choice] -= 1;
        w.hp = min(w.max_hp, w.hp + 2 + rep_bonus);
        player.energy -= cost;
        game_log(state, player.name + " repaired " + w.name + " (+" + string(2 + rep_bonus) + " HP).");
        game_play_sfx("repair");
        game_trigger_player_action(state, player, "repair", "+" + string(2 + rep_bonus) + " HP (" + w.name + ")", make_color_rgb(76, 175, 80));
        game_check_player_energy_depleted(state, player);
        return true;
    }
    else if (method == "crystal") {
        if (!variable_struct_exists(w.cost_res, "crystals")) {
            game_log(state, w.name + " does not use Crystals in its blueprint!");
            return false;
        }
        if (state.storage.crystals < 1) {
            game_log(state, "Requires 1 Crystal in Storage!");
            return false;
        }
        state.storage.crystals -= 1;
        w.hp = min(w.max_hp, w.hp + 4 + rep_bonus);
        player.energy -= cost;
        game_log(state, player.name + " infused " + w.name + " with Crystal (+" + string(4 + rep_bonus) + " HP).");
        game_play_sfx("repair");
        game_trigger_player_action(state, player, "repair", "+" + string(4 + rep_bonus) + " HP (" + w.name + ")", make_color_rgb(224, 64, 251));
        game_check_player_energy_depleted(state, player);
        return true;
    }
    else if (method == "power_gem") {
        if (w.power_gem_used) {
            game_log(state, "A Power Gem has already been used on " + w.name + "!");
            return false;
        }
        if (state.storage.power_gem < 1) {
            game_log(state, "Requires 1 Power Gem in Storage!");
            return false;
        }
        state.storage.power_gem -= 1;
        w.hp = w.max_hp;
        w.power_gem_used = true;
        player.energy -= cost;
        game_log(state, player.name + " restored " + w.name + " to FULL HEALTH with a Power Gem!");
        game_play_sfx("repair");
        game_trigger_player_action(state, player, "repair", "FULL REPAIR (" + w.name + ")", make_color_rgb(255, 215, 0));
        game_check_player_energy_depleted(state, player);
        return true;
    }
    
    return false;
}

function game_player_town_trade(state, player, res_type, amount) {
    var cost = (variable_struct_exists(player, "character") && player.character.id == "scout") ? 2 : 1;
    if (player.energy < cost) {
        game_log(state, "Need " + string(cost) + " Energy to trade in Town!");
        return false;
    }
    if (player.node != "town") {
        game_log(state, "Must be at Town to trade!");
        return false;
    }
    
    amount = clamp(amount, 1, 3);
    if (state.storage[$ res_type] < amount) {
        game_log(state, "Not enough " + res_type + " in storage to sell!");
        return false;
    }
    
    state.storage[$ res_type] -= amount;
    player.energy -= cost;
    
    var res_defs = game_get_resource_definitions();
    var base_val = res_defs[$ res_type].sell_value;
    var favor = state.town_favors[state.active_town_favor];
    var bonus = (favor.resource == res_type) ? favor.bonus_gold : 0;
    var total_gold = (base_val + bonus) * amount;
    
    state.storage.gold += total_gold;
    var bonus_str = (bonus > 0) ? (" (+" + string(bonus * amount) + " Favor Bonus!)") : "";
    game_log(state, player.name + " sold " + string(amount) + " " + res_type + " for " + string(total_gold) + " Gold" + bonus_str + " (" + string(cost) + " Energy spent).");
    game_play_sfx("coin");
    game_trigger_player_action(state, player, "trade", "+" + string(total_gold) + " GOLD", make_color_rgb(255, 215, 0));
    game_check_player_energy_depleted(state, player);
    return true;
}

function game_player_manual_fire(state, player, target_alien_idx) {
    var cur_tower_idx = -1;
    if (player.node == "tower_1") cur_tower_idx = 0;
    else if (player.node == "tower_2") cur_tower_idx = 1;
    else if (player.node == "tower_3") cur_tower_idx = 2;
    else if (player.node == "tower_4") cur_tower_idx = 3;
    
    if (cur_tower_idx < 0) {
        game_log(state, "Move onto Tower 1, 2, 3, or 4 to fire its mounted weapon!");
        return false;
    }
    
    var tower = state.towers[cur_tower_idx];
    if (is_undefined(tower.weapon) || !tower.weapon.alive || tower.weapon.hp <= 0) {
        game_log(state, tower.name + " has no mounted defense weapon!");
        return false;
    }
    
    var w = tower.weapon;
    if (w.damage <= 0) {
        game_log(state, w.name + " is a support structure and cannot directly fire!");
        return false;
    }
    
    if (tower.manual_cooldown > 0) {
        var rem_str = (tower.manual_cooldown == 1) ? "1 turn" : (string(tower.manual_cooldown) + " turns");
        game_log(state, tower.name + "'s " + w.name + " is cooling down (" + rem_str + " remaining)!");
        return false;
    }
    
    var cost = 2;
    // Overcharge Pylon reduces manual reuse cost to 1
    for (var i = 0; i < array_length(state.weapons); i++) {
        if (state.weapons[i].alive && state.weapons[i].catalog_id == "overcharge_pylon") {
            cost = 1;
            break;
        }
    }
    if (variable_struct_exists(player, "character")) {
        if (player.character.id == "gunner") {
            cost = 1; // Gunner firing weapon costs only 1 energy instead of 2
        } else if (player.character.id == "scout") {
            cost = 2; // Scout tasks cost 2 energy
        }
    }
    
    if (player.energy < cost) {
        game_log(state, "Need " + string(cost) + " Energy to fire " + w.name + "!");
        return false;
    }
    
    if (array_length(state.active_zone) == 0) {
        game_log(state, "No active aliens to attack!");
        return false;
    }
    
    player.energy -= cost;
    game_apply_weapon_damage(state, w, target_alien_idx);
    tower.manual_powers_this_turn += 1;
    var next_cd_str = (tower.manual_powers_this_turn == 1) ? "1-turn" : (string(tower.manual_powers_this_turn) + "-turn");
    game_log(state, player.name + " powered " + w.name + " at " + tower.name + " (" + string(cost) + " Energy spent, powered " + string(tower.manual_powers_this_turn) + "x - " + next_cd_str + " cooldown next round).");
    game_trigger_player_action(state, player, "fire", "WEAPON FIRED!", make_color_rgb(255, 170, 0));
    game_check_player_energy_depleted(state, player);
    return true;
}

function game_spawn_alien(state, catalog_id, zone_name) {
    var cat = state.alien_catalog[$ catalog_id];
    if (is_undefined(cat)) cat = state.alien_catalog.drone;
    
    var inst = {
        uid: state.alien_uid++,
        catalog_id: catalog_id,
        name: cat.name,
        tier: cat.tier,
        hp: cat.hp,
        max_hp: cat.hp,
        damage: cat.damage,
        ability: cat.ability,
        frozen: false,
        vulnerable: false,
        tesla_weakened: false,
        alive: true
    };
    
    if (zone_name == "active") {
        array_push(state.active_zone, inst);
    } else {
        array_push(state.spawn_zone, inst);
    }
    
    // Broodlord effect: draws two Tier 1 aliens
    if (catalog_id == "broodlord") {
        var t1_pool = game_get_alien_tier_pool(1);
        game_spawn_alien(state, t1_pool[irandom(array_length(t1_pool) - 1)], zone_name);
        game_spawn_alien(state, t1_pool[irandom(array_length(t1_pool) - 1)], zone_name);
        game_log(state, "Broodlord summoned two Tier 1 Aliens!");
    }
    
    return inst;
}

function game_spawn_wave_for_round(state, rnum) {
    var wave_list = [];
    if (rnum <= array_length(state.waves)) {
        wave_list = state.waves[rnum - 1];
    } else {
        // Endless mode: procedural escalation
        var extra = rnum - 17;
        wave_list = [3, 3, 3];
        for (var i = 0; i < extra; i++) {
            array_push(wave_list, (i % 2 == 0) ? 2 : 3);
        }
    }
    
    for (var i = 0; i < array_length(wave_list); i++) {
        var tier = wave_list[i];
        var pool = game_get_alien_tier_pool(tier);
        var chosen_id = pool[irandom(array_length(pool) - 1)];
        game_spawn_alien(state, chosen_id, "spawn");
    }
}

/// @desc Checks if any alive Scout alien is present in the active zone
function game_has_active_scout(state) {
    if (!variable_struct_exists(state, "active_zone") || !is_array(state.active_zone)) return false;
    for (var i = 0; i < array_length(state.active_zone); i++) {
        if (state.active_zone[i].alive && state.active_zone[i].catalog_id == "scout") {
            return true;
        }
    }
    return false;
}

function game_apply_weapon_damage(state, w, target_idx) {
    if (target_idx < 0 || target_idx >= array_length(state.active_zone)) return;
    
    // Scout Priority Rule: If any Scout is present, Scout must be targeted first!
    var has_scout = game_has_active_scout(state);
    if (has_scout && state.active_zone[target_idx].catalog_id != "scout") {
        for (var i = 0; i < array_length(state.active_zone); i++) {
            if (state.active_zone[i].alive && state.active_zone[i].catalog_id == "scout") {
                target_idx = i;
                break;
            }
        }
    }
    
    var target = state.active_zone[target_idx];
    var dmg = w.damage + w.bonus_damage;
    if (target.vulnerable) dmg += 1; // Flamethrower vulnerability
    
    // Armorback ability: damage reduced by 1
    if (target.catalog_id == "armorback") dmg = max(1, dmg - 1);
    
    // Apex Predator ability: max 10 damage from single attack
    if (target.catalog_id == "apex_predator") dmg = min(10, dmg);
    
    var overkill = max(0, dmg - target.hp);
    target.hp -= dmg;
    game_log(state, w.name + " dealt " + string(dmg) + " dmg to " + target.name + "!");
    
    // Cryo Emitter freeze
    if (w.catalog_id == "cryo_emitter") {
        target.frozen = true;
        game_log(state, target.name + " is FROZEN (deals 0 dmg on next attack)!");
    }
    
    // Lazer Gun damage increase
    if (w.catalog_id == "lazer_gun") {
        w.damage += 1;
        game_log(state, "Lazer Gun calibrated! Damage increased to " + string(w.damage) + ".");
    }
    
    // Flamethrower vulnerability
    if (w.catalog_id == "flamethrower") {
        target.vulnerable = true;
    }
    
    // Handle primary target death
    if (target.hp <= 0) {
        target.alive = false;
        game_log(state, target.name + " destroyed!");
        game_play_sfx("hit");
        
        // Saboteur: deals 2 damage to killer weapon
        if (target.catalog_id == "saboteur") {
            w.hp -= 2;
            game_log(state, "Saboteur death explosion dealt 2 dmg to " + w.name + "!");
            if (w.hp <= 0) {
                w.alive = false;
                game_log(state, w.name + " was destroyed by Saboteur!");
            }
        }
        
        // Railgun overkill carryover
        if (w.catalog_id == "railgun" && overkill > 0) {
            for (var j = 0; j < array_length(state.active_zone); j++) {
                if (state.active_zone[j].alive && state.active_zone[j].uid != target.uid) {
                    var second_target = state.active_zone[j];
                    second_target.hp -= overkill;
                    game_log(state, "Railgun pierce dealt " + string(overkill) + " surplus dmg to " + second_target.name + "!");
                    if (second_target.hp <= 0) {
                        second_target.alive = false;
                        game_log(state, second_target.name + " destroyed!");
                    }
                    break;
                }
            }
        }
    }
    
    // Plasma Mortar: 3 splash damage prioritizing the aliens to the left and right of primary target
    if (w.catalog_id == "plasma_mortar") {
        var splash_candidates = [];
        
        // 1. Prioritize Left neighbor (target_idx - 1)
        if (target_idx - 1 >= 0 && state.active_zone[target_idx - 1].alive) {
            array_push(splash_candidates, state.active_zone[target_idx - 1]);
        }
        
        // 2. Prioritize Right neighbor (target_idx + 1)
        if (target_idx + 1 < array_length(state.active_zone) && state.active_zone[target_idx + 1].alive) {
            array_push(splash_candidates, state.active_zone[target_idx + 1]);
        }
        
        // 3. If under 2 targets, check 2 steps away (target_idx - 2, target_idx + 2)
        if (array_length(splash_candidates) < 2 && target_idx - 2 >= 0 && state.active_zone[target_idx - 2].alive) {
            array_push(splash_candidates, state.active_zone[target_idx - 2]);
        }
        if (array_length(splash_candidates) < 2 && target_idx + 2 < array_length(state.active_zone) && state.active_zone[target_idx + 2].alive) {
            array_push(splash_candidates, state.active_zone[target_idx + 2]);
        }
        
        // 4. Any remaining alive alien that isn't the primary target
        for (var a = 0; a < array_length(state.active_zone); a++) {
            if (array_length(splash_candidates) >= 2) break;
            var other_al = state.active_zone[a];
            if (other_al.alive && other_al.uid != target.uid) {
                var exists_already = false;
                for (var sc = 0; sc < array_length(splash_candidates); sc++) {
                    if (splash_candidates[sc].uid == other_al.uid) exists_already = true;
                }
                if (!exists_already) array_push(splash_candidates, other_al);
            }
        }
        
        // Apply 3 splash damage to each prioritized splash target
        for (var s = 0; s < array_length(splash_candidates); s++) {
            var sal = splash_candidates[s];
            var s_dmg = 3;
            if (sal.catalog_id == "armorback") s_dmg = max(1, s_dmg - 1);
            if (sal.catalog_id == "apex_predator") s_dmg = min(10, s_dmg);
            sal.hp -= s_dmg;
            game_log(state, "Plasma Mortar splash dealt " + string(s_dmg) + " dmg to " + sal.name + " (adjacent)! (HP: " + string(max(0, sal.hp)) + "/" + string(sal.max_hp) + ")");
            if (sal.hp <= 0) {
                sal.alive = false;
                game_log(state, sal.name + " destroyed by splash damage!");
                if (sal.catalog_id == "saboteur") {
                    w.hp -= 2;
                    game_log(state, "Saboteur death explosion dealt 2 dmg to " + w.name + "!");
                    if (w.hp <= 0) {
                        w.alive = false;
                        game_log(state, w.name + " was destroyed by Saboteur!");
                    }
                }
            }
        }
    }
    
    // Clean dead aliens from active zone
    for (var i = array_length(state.active_zone) - 1; i >= 0; i--) {
        if (!state.active_zone[i].alive) {
            array_delete(state.active_zone, i, 1);
        }
    }
}

/// @desc Spawns dynamic particle explosion and shockwave impact effect
function game_spawn_combat_impact_effect(state, ix, iy, origin, sub_id = "") {
    if (!variable_struct_exists(state, "combat_impact_effects") || !is_array(state.combat_impact_effects)) {
        state.combat_impact_effects = [];
    }
    
    var col = make_color_rgb(255, 170, 0);
    var rad = 38;
    var count = 14;
    
    if (origin == "player") {
        if (sub_id == "flamethrower") {
            col = make_color_rgb(255, 75, 20);
            rad = 42;
            count = 18;
        } else if (sub_id == "plasma_mortar") {
            col = make_color_rgb(210, 50, 255);
            rad = 48;
            count = 20;
        } else if (sub_id == "railgun") {
            col = make_color_rgb(0, 229, 255);
            rad = 44;
            count = 18;
        } else if (sub_id == "tesla") {
            col = make_color_rgb(180, 255, 255);
            rad = 40;
            count = 16;
        } else {
            // Turret / Default
            col = make_color_rgb(255, 215, 0);
            rad = 36;
            count = 14;
        }
    } else {
        // Alien impact
        if (sub_id == "acid_spitter") {
            col = make_color_rgb(57, 255, 20); // Neon green acid
            rad = 44;
            count = 18;
        } else if (sub_id == "goliath") {
            col = make_color_rgb(255, 50, 50); // Heavy crimson blast
            rad = 54;
            count = 22;
        } else if (sub_id == "drooper") {
            col = make_color_rgb(180, 50, 255); // Purple blast
            rad = 46;
            count = 18;
        } else {
            col = make_color_rgb(255, 150, 20); // Bio orange
            rad = 36;
            count = 14;
        }
    }
    
    var sparks = [];
    var spark_count = count + 6;
    for (var s = 0; s < spark_count; s++) {
        var ang = random(360);
        var spd = random_range(2.5, 9.0);
        array_push(sparks, {
            x: ix,
            y: iy,
            vx: lengthdir_x(spd, ang),
            vy: lengthdir_y(spd, ang),
            life: irandom_range(16, 28),
            max_life: 28,
            size: random_range(2.5, 5.5),
            color: col
        });
    }
    
    // Fireball blast core puffs
    var fireballs = [];
    var fb_count = 8;
    for (var f = 0; f < fb_count; f++) {
        var fb_ang = random(360);
        var fb_spd = random_range(0.8, 3.6);
        array_push(fireballs, {
            x: ix + lengthdir_x(random_range(0, 10), fb_ang),
            y: iy + lengthdir_y(random_range(0, 10), fb_ang),
            vx: lengthdir_x(fb_spd, fb_ang),
            vy: lengthdir_y(fb_spd, fb_ang),
            radius: random_range(10, 18),
            grow_rate: random_range(0.7, 1.3),
            life: irandom_range(16, 26),
            max_life: 26,
            color: col
        });
    }
    
    // Upward-drifting smoke puffs
    var smoke = [];
    var sm_count = 10;
    for (var sm_i = 0; sm_i < sm_count; sm_i++) {
        array_push(smoke, {
            x: ix + random_range(-14, 14),
            y: iy + random_range(-10, 10),
            vx: random_range(-0.9, 0.9),
            vy: random_range(-0.8, -2.4),
            radius: random_range(10, 16),
            grow_rate: random_range(0.5, 0.9),
            life: irandom_range(26, 42),
            max_life: 42,
            color: make_color_rgb(45, 48, 55)
        });
    }
    
    array_push(state.combat_impact_effects, {
        x: ix,
        y: iy,
        life: 0,
        max_life: 36,
        max_radius: rad * 1.5,
        color: col,
        sparks: sparks,
        fireballs: fireballs,
        smoke: smoke
    });
}

/// @desc Opens dedicated tactical combat modal with active aliens at top and 4 tower weapons at bottom
function game_start_weapons_attack_phase(state) {
    // Clean dead aliens first
    for (var i = array_length(state.active_zone) - 1; i >= 0; i--) {
        if (!state.active_zone[i].alive) {
            array_delete(state.active_zone, i, 1);
        }
    }
    
    // Skip the tactical combat UI menu if there are no aliens or towers attacking
    if (array_length(state.active_zone) == 0) {
        state.modal = undefined;
        if (state.phase != "game_over" && state.phase != "victory") {
            game_advance_wave_phase(state);
            
            // Check incoming aliens in the upcoming wave
            var upcoming_count = array_length(state.spawn_zone);
            if (upcoming_count == 0 && array_length(state.active_zone) > 0) {
                upcoming_count = array_length(state.active_zone);
            }
            
            var arriving_str = "";
            if (upcoming_count == 1) {
                arriving_str = " An alien is arriving!";
            } else if (upcoming_count > 1) {
                arriving_str = " " + string(upcoming_count) + " aliens are arriving!";
            }
            
            state.turn_popup_title = "NO HOSTILES DETECTED // A NEW DAY BEGINS";
            state.turn_popup_message = "No hostiles detected and everyone has more energy this new day." + arriving_str;
            state.turn_popup_color = make_color_rgb(105, 240, 174);
            state.turn_popup_timer = 240;
            
            game_log(state, "No hostiles detected and everyone has more energy this new day." + arriving_str);
        }
        return;
    }
    
    state.phase = "combat_weapons";
    state.combat_subphase = "player_weapons";
    state.modal = { type: "tactical_combat" };
    state.combat_projectiles = [];
    state.combat_player_projectiles = [];
    state.combat_concluded_reason = "";
    state.combat_conclude_btn_hover = false;
    state.alien_attack_idx = 0;
    state.alien_attack_delay = 0;
    
    game_log(state, "--- TACTICAL COMBAT DEFENSE PHASE ---");
    
    // Check EMP Weaver: disables highest damage weapon mounted on towers
    var has_emp = false;
    for (var i = 0; i < array_length(state.active_zone); i++) {
        if (state.active_zone[i].alive && state.active_zone[i].catalog_id == "emp_weaver") {
            has_emp = true;
            break;
        }
    }
    
    var highest_dmg = -1;
    var emp_tower_idx = -1;
    for (var t = 0; t < 4; t++) {
        var tw = state.towers[t];
        if (tw.alive && !is_undefined(tw.weapon)) {
            var w = tw.weapon;
            w.disabled = false;
            if (w.alive && w.damage > highest_dmg) {
                highest_dmg = w.damage;
                emp_tower_idx = t;
            }
        }
    }
    if (has_emp && emp_tower_idx >= 0) {
        state.towers[emp_tower_idx].weapon.disabled = true;
        game_log(state, "EMP Weaver disabled " + state.towers[emp_tower_idx].weapon.name + " on " + state.towers[emp_tower_idx].name + "!");
    }
    
    // Overcharge Pylon buff (+3 damage up to pylon count)
    var pylon_count = 0;
    for (var i = 0; i < array_length(state.weapons); i++) {
        if (state.weapons[i].alive && state.weapons[i].catalog_id == "overcharge_pylon") {
            pylon_count += 2;
        }
    }
    var buffed_count = 0;
    for (var t = 0; t < 4; t++) {
        var tw = state.towers[t];
        if (tw.alive && !is_undefined(tw.weapon)) {
            var w = tw.weapon;
            w.bonus_damage = 0;
            if (buffed_count < pylon_count && w.alive && w.damage > 0 && !w.disabled) {
                w.bonus_damage = 3;
                buffed_count++;
                game_log(state, w.name + " on " + tw.name + " overcharged (+3 Damage)!");
            }
        }
    }
    
    // Initialize 4 tower weapon slots
    state.tower_weapon_shots = [0, 0, 0, 0];
    state.tower_weapon_max_shots = [0, 0, 0, 0];
    state.tower_weapon_used = [true, true, true, true];
    state.combat_selected_tower = -1;
    state.combat_selected_weapon_idx = -1;
    state.combat_weapons_queue = [];
    
    var ready_wep_count = 0;
    for (var t = 0; t < 4; t++) {
        var tw = state.towers[t];
        if (tw.alive && !is_undefined(tw.weapon) && tw.weapon.alive && !tw.weapon.disabled && tw.weapon.damage > 0) {
            var w = tw.weapon;
            // Railgun cooldown check
            if (w.catalog_id == "railgun") {
                if (w.cooldown > 0) {
                    w.cooldown--;
                    game_log(state, "Railgun charging capacitor (ready next wave)...");
                    continue;
                } else {
                    w.cooldown = 1;
                }
            }
            
            var shots = 1;
            if (w.catalog_id == "turret") shots = 2;
            else if (w.catalog_id == "flamethrower") shots = 3;
            
            state.tower_weapon_shots[t] = shots;
            state.tower_weapon_max_shots[t] = shots;
            state.tower_weapon_used[t] = false;
            ready_wep_count++;
            
            if (state.combat_selected_tower == -1) {
                state.combat_selected_tower = t;
            }
        }
    }
    
    if (ready_wep_count == 0) {
        game_log(state, "No offensive mounted weapons ready to fire! Proceeding to Alien Attack Phase.");
        game_start_alien_attack_phase(state);
        return;
    }
    
    game_log(state, "Tactical Combat Active: Click a mounted weapon below, then target an alien above to attack!");
}

/// @desc Selects a ready tower weapon card
function game_combat_select_tower(state, tower_idx) {
    if (tower_idx < 0 || tower_idx >= 4) return;
    var tw = state.towers[tower_idx];
    if (tw.alive && !is_undefined(tw.weapon) && tw.weapon.alive && !state.tower_weapon_used[tower_idx]) {
        state.combat_selected_tower = tower_idx;
        game_play_sfx("click");
    }
}

/// @desc Launches active selected tower weapon projectile at targeted alien in active zone
function game_combat_fire_tower_at_alien(state, target_idx) {
    if (state.phase != "combat_weapons" || state.combat_subphase != "player_weapons") return false;
    var t = state.combat_selected_tower;
    if (t < 0 || t >= 4) return false;
    if (state.tower_weapon_used[t] || state.tower_weapon_shots[t] <= 0) return false;
    if (target_idx < 0 || target_idx >= array_length(state.active_zone)) return false;
    
    // Scout Priority: if any scout is alive in active zone, players MUST target scout first!
    if (game_has_active_scout(state) && state.active_zone[target_idx].catalog_id != "scout") {
        state.toast_message = "Scout ability: You must target the Scout alien first!";
        state.toast_timer = 90;
        game_log(state, "Scout ability active! You must target the Scout alien first.");
        game_play_sfx("error");
        return false;
    }
    
    var w = state.towers[t].weapon;
    var dmg = w.damage + w.bonus_damage;
    
    // Launch player projectile
    array_push(state.combat_player_projectiles, {
        tower_idx: t,
        target_idx: target_idx,
        target_uid: state.active_zone[target_idx].uid,
        weapon: w,
        damage: dmg,
        progress: 0.0,
        speed: 0.045,
        catalog_id: w.catalog_id
    });
    
    state.tower_weapon_shots[t] -= 1;
    game_play_sfx("hit");
    
    // Check if this weapon has depleted its shots this wave
    if (state.tower_weapon_shots[t] <= 0) {
        state.tower_weapon_used[t] = true;
        
        // Auto-select next unused weapon tower
        var next_t = -1;
        for (var i = 0; i < 4; i++) {
            if (!state.tower_weapon_used[i]) {
                next_t = i;
                break;
            }
        }
        state.combat_selected_tower = next_t;
    }
    
    return true;
}

/// @desc Fires Tesla shockwave hitting all active aliens
function game_combat_discharge_tesla(state) {
    if (state.phase != "combat_weapons" || state.combat_subphase != "player_weapons") return false;
    var t = state.combat_selected_tower;
    if (t < 0 || t >= 4) return false;
    if (state.tower_weapon_used[t] || state.tower_weapon_shots[t] <= 0) return false;
    
    var tw = state.towers[t];
    if (is_undefined(tw.weapon) || tw.weapon.catalog_id != "tesla") return false;
    
    var w = tw.weapon;
    game_log(state, "Tesla discharges electric shockwave hitting ALL aliens!");
    game_play_sfx("hit");
    state.screen_shake = max(state.screen_shake, 8);
    
    for (var a = 0; a < array_length(state.active_zone); a++) {
        var tgt = state.active_zone[a];
        tgt.hp -= (w.damage + w.bonus_damage);
        tgt.tesla_weakened = true;
        if (tgt.hp <= 0) tgt.alive = false;
        
        // Spawn electric impact effect on each alien
        var apos_x = 960;
        var apos_y = 220;
        if (a < array_length(state.combat_alien_coords)) {
            apos_x = state.combat_alien_coords[a][0];
            apos_y = state.combat_alien_coords[a][1] - 110;
        }
        game_spawn_combat_impact_effect(state, apos_x, apos_y, "player", "tesla");
    }
    for (var a = array_length(state.active_zone) - 1; a >= 0; a--) {
        if (!state.active_zone[a].alive) array_delete(state.active_zone, a, 1);
    }
    
    state.tower_weapon_shots[t] = 0;
    state.tower_weapon_used[t] = true;
    
    // Auto-select next unused weapon tower
    var next_t = -1;
    for (var i = 0; i < 4; i++) {
        if (!state.tower_weapon_used[i]) {
            next_t = i;
            break;
        }
    }
    state.combat_selected_tower = next_t;
    
    // Check if all aliens eliminated
    if (array_length(state.active_zone) == 0) {
        game_log(state, "All active aliens eliminated! Base is secured.");
        state.combat_subphase = "combat_concluded";
        state.combat_concluded_reason = "aliens_eradicated";
        return true;
    }
    
    // Check if all weapons greyed out
    var all_greyed = true;
    for (var i = 0; i < 4; i++) {
        if (!state.tower_weapon_used[i]) all_greyed = false;
    }
    if (all_greyed) {
        game_log(state, "All mounted weapons have completed their attacks! Alien retaliation incoming!");
        game_start_alien_attack_phase(state);
        return true;
    }
    
    return true;
}

/// @desc Initiates alien retaliation phase with animated projectiles targeting base towers & weapons
function game_start_alien_attack_phase(state) {
    state.phase = "combat_aliens";
    state.combat_subphase = "alien_attacks";
    state.combat_projectiles = [];
    state.alien_attack_idx = 0;
    state.alien_attack_delay = 15;
    
    game_log(state, "--- ALIEN RETALIATION PHASE ---");
    
    // Clean dead aliens
    for (var i = array_length(state.active_zone) - 1; i >= 0; i--) {
        if (!state.active_zone[i].alive) {
            array_delete(state.active_zone, i, 1);
        }
    }
    
    if (array_length(state.active_zone) == 0) {
        game_log(state, "All alien threats neutralized! Base is secure.");
        state.combat_subphase = "combat_concluded";
        state.combat_concluded_reason = "aliens_eradicated";
        return;
    }
}

/// @desc Spawns the projectile for the next attacking alien in queue
function game_spawn_next_alien_projectile(state) {
    // If all towers already destroyed, trigger game over immediately
    var any_alive_t = false;
    for (var t = 0; t < 4; t++) {
        if (state.towers[t].alive && state.towers[t].hp > 0) any_alive_t = true;
    }
    if (!any_alive_t) {
        state.phase = "game_over";
        state.modal = { type: "game_over" };
        game_log(state, "CRITICAL ALERT: All Base Towers have been destroyed! Humanity has fallen.");
        game_play_sfx("alien");
        return false;
    }
    
    // Check Screamer buff
    var screamer_count = 0;
    for (var i = 0; i < array_length(state.active_zone); i++) {
        if (state.active_zone[i].alive && state.active_zone[i].catalog_id == "screamer") {
            screamer_count++;
        }
    }
    
    while (state.alien_attack_idx < array_length(state.active_zone)) {
        var alien = state.active_zone[state.alien_attack_idx];
        if (!alien.alive) {
            state.alien_attack_idx++;
            continue;
        }
        
        // Frozen alien skips attack
        if (alien.frozen) {
            alien.frozen = false;
            game_log(state, alien.name + " was FROZEN and thawed out (0 damage dealt)!");
            state.alien_attack_idx++;
            continue;
        }
        
        // Alien Queen does not attack directly
        if (alien.catalog_id == "alien_queen") {
            state.alien_attack_idx++;
            continue;
        }
        
        // Calculate attack damage
        var atk_dmg = alien.damage;
        if (screamer_count > 0 && alien.catalog_id != "screamer") atk_dmg += screamer_count;
        if (alien.tesla_weakened) {
            atk_dmg = max(0, atk_dmg - 1);
            alien.tesla_weakened = false;
        }
        
        if (atk_dmg <= 0) {
            state.alien_attack_idx++;
            continue;
        }
        
        // Leech ability: heals 2 HP when attacking
        if (alien.catalog_id == "leech") {
            alien.hp += 2;
            game_log(state, "Leech drained life force! Healed to " + string(alien.hp) + " HP.");
        }
        
        // The Syphon: random player loses 1 energy on next turn
        if (alien.catalog_id == "the_syphon") {
            var rand_p = irandom(state.num_players - 1);
            state.players[rand_p].energy_penalty += 1;
            game_log(state, "The Syphon drained energy! " + state.players[rand_p].name + " has -1 Energy next turn.");
        }
        
        // Alive towers candidates
        var alive_towers = [];
        for (var t = 0; t < 4; t++) {
            if (state.towers[t].alive && state.towers[t].hp > 0) array_push(alive_towers, t);
        }
        if (array_length(alive_towers) == 0) {
            state.phase = "game_over";
            state.modal = { type: "game_over" };
            game_log(state, "CRITICAL ALERT: All Base Towers have been destroyed! Humanity has fallen.");
            game_play_sfx("alien");
            return false;
        }
        
        var cur_a_idx = state.alien_attack_idx;
        state.alien_attack_idx++;
        
        // Drooper hits all alive towers simultaneously!
        if (alien.catalog_id == "drooper") {
            game_log(state, "Drooper carpet bombs all Defense Sectors!");
            game_play_sfx("alien");
            for (var d = 0; d < array_length(alive_towers); d++) {
                array_push(state.combat_projectiles, {
                    alien: alien,
                    alien_idx: cur_a_idx,
                    target_tower_idx: alive_towers[d],
                    damage: atk_dmg,
                    progress: 0.0,
                    speed: 0.0225,
                    is_acid_spitter: false,
                    skips_weapon: false
                });
            }
            return true;
        }
        
        // Standard single target selection
        var target_tower_idx = alive_towers[irandom(array_length(alive_towers) - 1)];
        game_play_sfx("alien");
        
        array_push(state.combat_projectiles, {
            alien: alien,
            alien_idx: cur_a_idx,
            target_tower_idx: target_tower_idx,
            damage: atk_dmg,
            progress: 0.0,
            speed: 0.0225,
            is_acid_spitter: (alien.catalog_id == "acid_spitter"),
            skips_weapon: (alien.catalog_id == "goliath")
        });
        return true;
    }
    
    // No more aliens to attack
    return false;
}

/// @desc Applies projectile impact to target tower or mounted weapon (automated interception)
function game_apply_projectile_impact(state, p) {
    var target_tower = state.towers[p.target_tower_idx];
    if (!target_tower.alive || target_tower.hp <= 0) return;
    
    // Spawn impact burst effect on target tower/weapon
    var imp_x = (p.target_tower_idx < array_length(state.combat_tower_coords)) ? state.combat_tower_coords[p.target_tower_idx][0] : 960;
    var imp_y = (p.target_tower_idx < array_length(state.combat_tower_coords)) ? (state.combat_tower_coords[p.target_tower_idx][1] + 160) : 750;
    game_spawn_combat_impact_effect(state, imp_x, imp_y, "alien", p.alien.catalog_id);
    state.screen_shake = max(state.screen_shake, 7);
    
    var atk_dmg = p.damage;
    var alien = p.alien;
    
    // Shield Generator: absorbs damage meant for weapons or base
    var shield_idx = -1;
    for (var s = 0; s < array_length(state.weapons); s++) {
        if (state.weapons[s].alive && state.weapons[s].catalog_id == "shield_generator") {
            shield_idx = s;
            break;
        }
    }
    if (shield_idx >= 0) {
        var shield = state.weapons[shield_idx];
        shield.hp -= atk_dmg;
        game_log(state, "Shield Generator absorbed " + string(atk_dmg) + " dmg from " + alien.name + "!");
        game_play_sfx("hit");
        if (shield.hp <= 0) {
            shield.alive = false;
            game_log(state, "Shield Generator OVERLOAD! Discharge deals 4 dmg to all aliens!");
            for (var a = 0; a < array_length(state.active_zone); a++) {
                state.active_zone[a].hp -= 4;
                if (state.active_zone[a].hp <= 0) {
                    state.active_zone[a].alive = false;
                    game_log(state, state.active_zone[a].name + " destroyed by Shield discharge!");
                }
            }
        }
        return;
    }
    
    var twep = target_tower.weapon;
    var has_active_wep = (!is_undefined(twep) && twep.alive && twep.hp > 0);
    
    // Goliath Colossal ability: skips weapon, strikes tower directly
    if (p.skips_weapon && has_active_wep) {
        target_tower.hp = max(0, target_tower.hp - atk_dmg);
        game_log(state, alien.name + " bypassed the mounted " + twep.name + " (Colossal ability) and struck " + target_tower.name + " directly for " + string(atk_dmg) + " dmg! (HP: " + string(target_tower.hp) + "/10)");
        game_play_sfx("hit");
        if (target_tower.hp <= 0) {
            target_tower.alive = false;
            game_log(state, target_tower.name + " DESTROYED!");
            if (!is_undefined(target_tower.weapon)) {
                target_tower.weapon.alive = false;
                target_tower.weapon = undefined;
            }
        }
        return;
    }
    
    // Mounted Weapon Interception: Weapon automatically tanks the blow to protect the tower!
    if (has_active_wep) {
        var wep_dmg = atk_dmg;
        if (p.is_acid_spitter) {
            wep_dmg *= 2; // Acid Spitter deals 2x damage against weapons!
            game_log(state, "! Acid Spitter projectile dealt double damage (" + string(wep_dmg) + " Dmg) to " + twep.name + " !");
        }
        
        twep.hp -= wep_dmg;
        game_log(state, twep.name + " on " + target_tower.name + " intercepted projectile for " + string(wep_dmg) + " dmg! (Weapon HP: " + string(max(0, twep.hp)) + "/" + string(twep.max_hp) + ")");
        game_play_sfx("hit");
        
        if (twep.hp <= 0) {
            twep.alive = false;
            target_tower.weapon = undefined;
            game_log(state, twep.name + " on " + target_tower.name + " was destroyed in defense!");
        }
        return;
    }
    
    // Tower takes damage directly (no mounted weapon)
    target_tower.hp = max(0, target_tower.hp - atk_dmg);
    game_log(state, alien.name + " projectile struck " + target_tower.name + " for " + string(atk_dmg) + " dmg! (HP: " + string(target_tower.hp) + "/10)");
    game_play_sfx("hit");
    if (target_tower.hp <= 0) {
        target_tower.alive = false;
        game_log(state, target_tower.name + " DESTROYED!");
        if (!is_undefined(target_tower.weapon)) {
            target_tower.weapon.alive = false;
            target_tower.weapon = undefined;
        }
    }
}

function game_advance_wave_phase(state) {
    game_log(state, "--- REGROUP & WAVE ADVANCE ---");
    game_play_sfx("wave");
    
    // 1. Hatchers spawn Hatchlings
    for (var i = 0; i < array_length(state.active_zone); i++) {
        if (state.active_zone[i].alive && state.active_zone[i].catalog_id == "hatcher") {
            game_spawn_alien(state, "hatchling", "active");
            game_spawn_alien(state, "hatchling", "active");
            game_log(state, "Hatcher spawned two Hatchlings (2 HP, 1 Dmg)!");
        }
    }
    
    // 2. Alien Queen summons T1 and T2 alien with +3 HP
    for (var i = 0; i < array_length(state.active_zone); i++) {
        if (state.active_zone[i].alive && state.active_zone[i].catalog_id == "alien_queen") {
            var t1 = game_get_alien_tier_pool(1);
            var t2 = game_get_alien_tier_pool(2);
            var a1 = game_spawn_alien(state, t1[irandom(array_length(t1) - 1)], "active");
            var a2 = game_spawn_alien(state, t2[irandom(array_length(t2) - 1)], "active");
            a1.hp += 3; a1.max_hp += 3;
            a2.hp += 3; a2.max_hp += 3;
            game_log(state, "Alien Queen summoned elite reinforcements (+3 HP)!");
        }
    }
    
    // 3. Move all spawn_zone aliens into active_zone
    while (array_length(state.spawn_zone) > 0) {
        var al = array_pop(state.spawn_zone);
        array_push(state.active_zone, al);
        game_log(state, "INCOMING WAVE: " + al.name + " entered the active combat zone!");
    }
    
    // 4. Resource Drone: gathers 1 random Forest or Cave 1 card
    for (var i = 0; i < array_length(state.weapons); i++) {
        if (state.weapons[i].alive && state.weapons[i].catalog_id == "resource_drone") {
            var d_key = (irandom(1) == 0) ? "forest" : "cave_1";
            var d_deck = state.decks[$ d_key];
            if (array_length(d_deck) > 0) {
                var d_card = array_pop(d_deck);
                if (d_card.type == "resource") {
                    state.storage[$ d_card.resource] += d_card.amount;
                    game_log(state, "Resource Drone retrieved " + d_card.name + "!");
                }
            }
        }
    }
    
    // 5. Energy Pylon: check bonus
    var energy_bonus = 0;
    for (var i = 0; i < array_length(state.weapons); i++) {
        if (state.weapons[i].alive && state.weapons[i].catalog_id == "energy_pylon") {
            energy_bonus++;
        }
    }
    
    // 6. Advance Round / Day
    state.round_number++;
    
    // Weapon manual powering cooldown progression
    for (var t = 0; t < 4; t++) {
        var tow = state.towers[t];
        if (tow.manual_powers_this_turn > 0) {
            tow.manual_cooldown = tow.manual_powers_this_turn;
            tow.manual_powers_this_turn = 0;
            var cd_str = (tow.manual_cooldown == 1) ? "1 turn" : (string(tow.manual_cooldown) + " turns");
            game_log(state, tow.name + "'s mounted weapon entered cooldown for " + cd_str + " (powered " + string(tow.manual_cooldown) + " times).");
        } else if (tow.manual_cooldown > 0) {
            tow.manual_cooldown -= 1;
            if (tow.manual_cooldown == 0) {
                game_log(state, tow.name + "'s mounted weapon cooled down and is ready to be powered!");
            }
        }
    }
    
    // Shop reroll cost decay: resets to 3 after 3 days of not rerolling
    if (!state.rerolled_this_day) {
        state.days_without_reroll++;
        if (state.days_without_reroll >= 3) {
            if (state.shop_reroll_cost > 3) {
                state.shop_reroll_cost = 3;
                game_log(state, "Shop reroll cost returned to 3 Gold after 3 days without rerolling.");
            }
        }
    } else {
        state.days_without_reroll = 0;
    }
    state.rerolled_this_day = false;
    
    // Victory Check (after Wave 17 without endless)
    // The game does NOT end on the final wave until all aliens are dead!
    if (state.round_number > 17 && !state.endless_mode) {
        if (array_length(state.active_zone) == 0 && array_length(state.spawn_zone) == 0) {
            state.phase = "victory";
            state.modal = { type: "victory" };
            game_log(state, "VICTORY ACHIEVED! All aliens eliminated on the Final Wave!");
            game_play_sfx("victory");
            return;
        } else {
            // Hostiles still remain from Wave 17! Keep players on Wave 17 until eradicated
            state.round_number = 17;
            game_log(state, "FINAL WAVE STAND: Alien threats still remain! Eliminate all aliens to claim victory!");
            
            // Refill players energy to battle the remaining aliens
            for (var i = 0; i < state.num_players; i++) {
                var p = state.players[i];
                p.max_energy = game_calculate_player_max_energy(p.character, state.num_players, energy_bonus);
                p.energy = max(1, p.max_energy - p.energy_penalty);
                p.energy_penalty = 0;
                p.ended_turn = false;
            }
            
            state.active_town_favor = irandom(array_length(state.town_favors) - 1);
            var new_fav = state.town_favors[state.active_town_favor];
            game_log(state, "A new day begins! Town Favor is now " + new_fav.name + " (" + new_fav.desc + ")!");
            
            state.current_player_idx = 0;
            state.phase = "player_actions";
            game_log(state, "Round 17 Final Stand continued! Prepare your defenses.");
            return;
        }
    }
    
    // 7. Spawn new wave into spawn_zone
    game_spawn_wave_for_round(state, state.round_number);
    
    // 8. Refill players energy (scaled by team size + Energy Pylon bonus)
    for (var i = 0; i < state.num_players; i++) {
        var p = state.players[i];
        p.max_energy = game_calculate_player_max_energy(p.character, state.num_players, energy_bonus);
        p.energy = max(1, p.max_energy - p.energy_penalty);
        p.energy_penalty = 0;
        p.ended_turn = false;
    }
    
    // Pick random Town Favor every day after the alien wave
    state.active_town_favor = irandom(array_length(state.town_favors) - 1);
    var new_fav = state.town_favors[state.active_town_favor];
    game_log(state, "A new day begins! Town Favor is now " + new_fav.name + " (" + new_fav.desc + ")!");
    
    // Reset turns
    state.current_player_idx = 0;
    state.phase = "player_actions";
    game_log(state, "Round " + string(state.round_number) + " begun! Team ready.");
}

function game_end_current_player_turn(state) {
    // Find next player with energy remaining
    for (var step = 1; step <= state.num_players; step++) {
        var next_p = (state.current_player_idx + step) % state.num_players;
        if (state.players[next_p].energy > 0) {
            state.current_player_idx = next_p;
            game_log(state, "Switched to " + state.players[next_p].name + " (" + string(state.players[next_p].energy) + " Energy).");
            return;
        }
    }
    
    // If no players have energy left, proceed to combat or advance to next day if clear
    game_start_weapons_attack_phase(state);
}

function game_force_start_combat(state) {
    game_start_weapons_attack_phase(state);
}

