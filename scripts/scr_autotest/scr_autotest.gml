/// @desc Automated test harness.
/// Launch the game with:  -autotest <scenario>   (e.g. ui_tour, net_host, net_client)
/// Screenshots and logs are written to the game's save folder under "autotest/".
/// When no -autotest argument is present this whole module is inert.

global.at = { active: false };

function autotest_boot() {
    global.at = {
        active: false,
        scenario: "",
        role: "",
        steps: [],
        idx: 0,
        wait: 0,
        frame: 0,
        step_frame: 0,
        shot: "",
        logname: "",
        mouse_x: -1000,
        mouse_y: -1000,
        fps_sum: 0,
        fps_count: 0,
        fps_min: 9999,
        vars: {},
        failures: 0
    };
    for (var i = 0; i < parameter_count(); i++) {
        var p = parameter_string(i);
        if (p == "-autotest" && i + 1 < parameter_count()) {
            global.at.active = true;
            global.at.scenario = parameter_string(i + 1);
        }
    }
    if (!global.at.active) return;

    global.at.logname = "autotest/" + global.at.scenario + ".log";
    // Test runs never leave an error dialog on screen: log the crash and quit
    exception_unhandled_handler(function(ex) {
        autotest_log("CRASH " + string(ex.longMessage));
        autotest_log("AUTOTEST END failures=CRASH");
        return 0;
    });
    var f = file_text_open_write(global.at.logname);
    file_text_close(f);
    autotest_log("AUTOTEST START scenario=" + global.at.scenario + " save=" + game_save_id);
    global.at.steps = autotest_build_scenario(global.at.scenario);
}

function autotest_active() {
    return (variable_global_exists("at") && is_struct(global.at) && global.at.active);
}

function autotest_log(msg) {
    if (!autotest_active()) return;
    var f = file_text_open_append(global.at.logname);
    if (f >= 0) {
        file_text_write_string(f, "[" + string(global.at.frame) + "] " + string(msg));
        file_text_writeln(f);
        file_text_close(f);
    }
    show_debug_message("AUTOTEST: " + string(msg));
}

function autotest_check(cond, label) {
    if (cond) {
        autotest_log("PASS " + label);
    } else {
        global.at.failures++;
        autotest_log("FAIL " + label);
    }
    return cond;
}

function autotest_shot(name) {
    if (!autotest_active()) return;
    global.at.shot = "autotest/" + global.at.scenario + "_" + name + ".png";
}

function autotest_mouse(px, py) {
    if (!autotest_active()) return;
    global.at.mouse_x = px;
    global.at.mouse_y = py;
}

/// @desc Step helper: { wait: frames before running fn, fn: function(state), until: optional function(state)->bool, timeout }
function autotest_step(_wait, _fn, _until = undefined, _timeout = 600) {
    return { wait: _wait, fn: _fn, until: _until, timeout: _timeout, started: false, elapsed: 0 };
}

function autotest_tick(state) {
    if (!autotest_active()) return;
    var at = global.at;
    at.frame++;

    if (at.frame > 30) {
        at.fps_sum += fps_real;
        at.fps_count++;
        at.fps_min = min(at.fps_min, fps);
    }

    if (at.idx >= array_length(at.steps)) return;
    var st = at.steps[at.idx];

    if (st.wait > 0) { st.wait--; return; }

    if (!st.started) {
        st.started = true;
        if (!is_undefined(st.fn)) st.fn(state);
        if (is_undefined(st.until)) { at.idx++; return; }
    }

    if (!is_undefined(st.until)) {
        st.elapsed++;
        if (st.until(state)) {
            at.idx++;
        } else if (st.elapsed > st.timeout) {
            autotest_check(false, "timeout waiting on step " + string(at.idx));
            at.idx++;
        }
    }
}

function autotest_finish() {
    var at = global.at;
    var avg = (at.fps_count > 0) ? (at.fps_sum / at.fps_count) : 0;
    autotest_log("PERF avg_fps_real=" + string(round(avg)) + " min_fps=" + string(at.fps_min));
    autotest_log("AUTOTEST END failures=" + string(at.failures));
    game_end();
}

/// @desc Capture hooks used by the Draw GUI event to save screenshots
function autotest_capture_begin() {
    if (!autotest_active() || global.at.shot == "") return -1;
    var surf = surface_create(1920, 1080);
    surface_set_target(surf);
    draw_clear(c_black);
    return surf;
}

function autotest_capture_end(surf) {
    if (surf == -1) return;
    surface_reset_target();
    surface_save(surf, global.at.shot);
    autotest_log("shot " + global.at.shot);
    global.at.shot = "";
    draw_surface(surf, 0, 0);
    surface_free(surf);
}

// =============================================================================
// SCENARIOS
// =============================================================================
function autotest_build_scenario(name) {
    var s = [];
    switch (name) {
        case "ui_tour":    s = autotest_scenario_ui_tour(); break;
        case "net_host":   s = autotest_scenario_net(true); break;
        case "logic":      s = autotest_scenario_logic(); break;
        case "balance":    s = autotest_scenario_balance(); break;
        case "balance_trace": s = autotest_scenario_balance_trace(); break;
        case "net_client": s = autotest_scenario_net(false); break;
        default:
            autotest_log("Unknown scenario " + name);
            array_push(s, autotest_step(5, function(st) { autotest_finish(); }));
    }
    return s;
}

/// @desc Visits every screen and modal and captures screenshots.
/// Convention: a step either changes state OR captures a shot; captures come after a settle wait.
function autotest_scenario_ui_tour() {
    var s = [];
    var shot = function(_name, _wait = 20) {
        return autotest_step(_wait, method({ n: _name }, function(st) { autotest_shot(n); }));
    };
    array_push(s, autotest_step(40, function(st) { autotest_mouse(300, 455); }));
    array_push(s, shot("01_title", 30));
    array_push(s, autotest_step(2, function(st) { autotest_mouse(-1000, -1000); ui_transition_to(st, "local_setup"); }));
    array_push(s, shot("02a_local_setup_default", 20));
    array_push(s, autotest_step(2, function(st) { autotest_check(st.setup_player_count == 1, "squad size defaults to 1 player"); st.setup_player_count = 3; st.setup_player_classes = [1, 2, 4, 0]; }));
    array_push(s, shot("02_local_setup", 30));
    array_push(s, autotest_step(2, function(st) {
        input_launch_local(st);
        st.storage.gold = 25; st.storage.wood = 6; st.storage.metal = 5; st.storage.stone = 4; st.storage.crystals = 3; st.storage.scrap = 4; st.storage.power_gem = 2;
    }));
    array_push(s, shot("03_board_banner", 40));
    array_push(s, autotest_step(200, function(st) { autotest_mouse(740, 530); }));
    array_push(s, shot("04_board_hover", 10));
    array_push(s, autotest_step(2, function(st) {
        autotest_mouse(-1000, -1000);
        autotest_check(game_do(st, "move", { node: "shop" }), "move to shop via dispatcher");
        autotest_check(!game_do(st, "move", { node: "cave_3" }), "illegal move rejected");
    }));
    array_push(s, shot("05_board_at_shop", 40));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "shop" }; autotest_mouse(1100, 820); }));
    array_push(s, shot("06_shop", 25));
    array_push(s, autotest_step(2, function(st) {
        autotest_mouse(-1000, -1000);
        var gold0 = st.storage.gold;
        game_do(st, "buy", { slot: 0 });
        autotest_check(array_length(st.blueprints) == 2 && st.storage.gold < gold0, "bought blueprint (plus the starter)");
        st.players[st.current_player_idx].node = "town";
        st.market_cart = { wood: 4, crystals: 2, power_gem: 1 };
        st.modal = { type: "town" };
        autotest_mouse(1340, 545);
    }));
    array_push(s, shot("07_market", 25));
    array_push(s, autotest_step(2, function(st) {
        var pl = st.players[st.current_player_idx];
        pl.node = "workstation";
        var cat = game_get_weapon_catalog();
        for (var i = 3; i < 6; i++) array_push(st.blueprints, { catalog_id: cat[i].id, name: cat[i].name, hp: cat[i].hp, damage: cat[i].damage, cost_res: cat[i].cost_res, ability: cat[i].ability, target_count: cat[i].target_count, splash_count: 0, splash_dmg: 0 });
        st.towers[2].alive = false; st.towers[2].hp = 0;
        st.towers[1].hp = 6;
        st.modal = { type: "repair" };
        autotest_mouse(1500, 650);
    }));
    array_push(s, shot("08_workshop", 25));
    array_push(s, autotest_step(2, function(st) { autotest_mouse(-1000, -1000); st.towers[2].alive = true; st.towers[2].hp = 10; st.modal = { type: "settings" }; }));
    array_push(s, shot("09_settings"));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "pause" }; }));
    array_push(s, shot("10_pause"));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "help" }; }));
    array_push(s, shot("11_help"));
    array_push(s, autotest_step(2, function(st) { st.modal = undefined;
        var pl = st.players[st.current_player_idx];
        pl.node = "forest";
        pl.anim_x = st.nodes.forest.x; pl.anim_y = st.nodes.forest.y;
        var cat = game_get_weapon_catalog();
        var picks = ["turret", "railgun", "plasma_mortar", "tesla"];
        for (var t = 0; t < 4; t++) {
            var it = undefined;
            for (var c = 0; c < array_length(cat); c++) if (cat[c].id == picks[t]) it = cat[c];
            var w = { catalog_id: it.id, name: it.name, hp: it.hp, max_hp: it.hp, damage: it.damage, bonus_damage: 0, ability: it.ability, target_count: it.target_count, splash_count: 0, splash_dmg: 0, cooldown: 0, cost_res: it.cost_res, power_gem_used: false, disabled: false, stationed_tower: t, alive: true };
            st.towers[t].weapon = w;
            array_push(st.weapons, w);
        }
        game_spawn_alien(st, "drone", "active");
        game_spawn_alien(st, "armorback", "active");
        game_spawn_alien(st, "drone", "active");
        game_spawn_alien(st, "acid_spitter", "active");
        game_spawn_alien(st, "goliath", "active");
        game_spawn_alien(st, "leech", "spawn");
        game_spawn_alien(st, "scout", "spawn");
        game_log(st, "[CHAT] Player 2: Heads up, big one on the east side.");
        autotest_mouse(560, 1000);
    }));
    array_push(s, shot("12_board_threats", 30));
    array_push(s, autotest_step(2, function(st) {
        autotest_mouse(-1000, -1000);
        var pl = st.players[st.current_player_idx];
        pl.node = "tower_1"; pl.energy = 9;
        autotest_check(game_do(st, "volley_start", {}) && st.phase == "combat_weapons", "Fire opens the attack screen (volley)");
        autotest_mouse(1060, 300);
    }));
    array_push(s, shot("12b_volley", 30));
    array_push(s, autotest_step(2, function(st) { autotest_mouse(-1000, -1000); game_do(st, "combat_fire", { tower: 0, target: 1 }); game_do(st, "combat_fire", { tower: 0, target: 1 }); }));
    array_push(s, shot("12c_volley_fired", 40));
    array_push(s, autotest_step(1, undefined, function(st) { return st.phase == "player_actions"; }, 600));
    array_push(s, autotest_step(2, function(st) { autotest_check(st.phase == "player_actions", "volley returns to the base");
        var pl = st.players[st.current_player_idx]; pl.node = "forest"; pl.energy = 9; }));
array_push(s, autotest_step(2, function(st) { autotest_mouse(-1000, -1000); game_do(st, "begin_defense", {}); }));
    array_push(s, autotest_step(170, function(st) { autotest_check(st.phase == "combat_weapons", "defense phase started"); autotest_mouse(1060, 300); }));
    array_push(s, shot("13_combat_start", 10));
    array_push(s, autotest_step(2, function(st) { autotest_mouse(760, 280); }));
    array_push(s, shot("13b_alien_hover", 12));
    array_push(s, autotest_step(2, function(st) { autotest_check(string_pos("Armorback", st.tip_last ?? "") > 0, "hovering an alien on the attack screen explains it"); autotest_mouse(400, 1032); }));
    array_push(s, shot("13c_no_board_hover", 12));
    array_push(s, autotest_step(2, function(st) { autotest_check((st.tip_last ?? "") == "" || string_pos("Armorback", st.tip_last) > 0 || st.hover_tooltip == "", "board hover tips are hidden behind the attack screen"); autotest_mouse(1060, 300); }));
array_push(s, autotest_step(2, function(st) { autotest_mouse(-1000, -1000); game_do(st, "combat_fire", { tower: 1, target: 2 }); }));
    array_push(s, shot("14_railgun_pierce", 30));
    array_push(s, autotest_step(30, function(st) { game_do(st, "combat_fire", { tower: 2, target: 1 }); }));
    array_push(s, shot("15_mortar_splash", 30));
    array_push(s, autotest_step(40, function(st) { game_do(st, "combat_tesla", { tower: 3 }); }));
    array_push(s, shot("15b_tesla", 6));
    array_push(s, autotest_step(40, function(st) { game_do(st, "combat_skip", {}); }));
    array_push(s, shot("16_incoming_fire_banner", 20));
    array_push(s, autotest_step(1, undefined, function(st) { return st.combat_subphase == "combat_concluded" || st.phase == "game_over"; }, 1500));
    array_push(s, shot("17_combat_concluded", 20));
    array_push(s, autotest_step(2, function(st) { game_do(st, "combat_conclude", {}); }));
    array_push(s, autotest_step(30, function(st) { autotest_check(st.phase == "player_actions" && st.round_number == 2, "next day after combat"); }));
    array_push(s, shot("18_next_day_warning", 5));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "alien_inspect", alien: game_spawn_alien(st, "goliath", "spawn") }; }));
    array_push(s, shot("19_alien_inspect"));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "game_over" }; st.phase = "game_over"; }));
    array_push(s, shot("20_game_over"));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "victory" }; st.phase = "victory"; }));
    array_push(s, shot("21_victory"));
    array_push(s, autotest_step(2, function(st) { st.modal = undefined; st.phase = "player_actions"; ui_transition_to(st, "online_username"); }));
    array_push(s, shot("22_online_username", 30));
    array_push(s, autotest_step(2, function(st) { st.screen = "online_browser";
        st.net_discovered_rooms = [{ ip: "192.168.1.42", port: 6510, room_name: "Nova Outpost", host_name: "Nova", players: 2, max_players: 4, last_seen: current_time + 100000, compatible: true }];
    }));
    array_push(s, shot("23_online_browser"));
    array_push(s, autotest_step(2, function(st) { st.screen = "online_lobby"; st.is_host = true;
        st.net_lobby_players = [
            { name: "Nova", is_host: true, character_id: "engineer", p_idx: 0, ip: "192.168.1.42", peer: 0 },
            { name: "Rook", is_host: false, character_id: "scout", p_idx: 1, ip: "192.168.1.50", peer: 1 }
        ];
    }));
    array_push(s, shot("24_online_lobby"));
    array_push(s, autotest_step(2, function(st) { st.is_host = false; st.screen = "title"; global.at.gallery = true; }));
    array_push(s, shot("25_weapon_icons", 5));
    array_push(s, autotest_step(2, function(st) { global.at.gallery = false; }));
    array_push(s, autotest_step(10, function(st) { autotest_finish(); }));
    return s;
}

/// @desc Two-instance LAN test. Run one copy with "-autotest net_host" and another with "-autotest net_client".
/// Both log PASS/FAIL checks and a state DIGEST at shared sync points; the digests must match.
function autotest_scenario_net(is_host) {
    var s = [];
    var shot = function(_name, _wait = 20) {
        return autotest_step(_wait, method({ n: _name }, function(st) { autotest_shot(n); }));
    };
    var log_has = function(st, txt) {
        for (var i = 0; i < min(12, array_length(st.action_logs)); i++) if (string_pos(txt, st.action_logs[i]) > 0) return true;
        return false;
    };
    global.at.vars.log_has = log_has;

    if (is_host) {
        array_push(s, autotest_step(20, function(st) {
            st.net_username = "HostAlpha";
            autotest_check(network_start_hosting(st), "host opened TCP server");
        }));
        array_push(s, autotest_step(1, undefined, function(st) { return array_length(st.net_lobby_players) >= 2; }, 1800));
        array_push(s, autotest_step(1, function(st) { autotest_check(array_length(st.net_lobby_players) == 2 && st.net_lobby_players[1].name == "ClientBeta", "client joined host lobby"); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.net_lobby_players[1].character_id == "scout"; }, 900));
        array_push(s, autotest_step(1, function(st) {
            autotest_check(st.net_lobby_players[1].character_id == "scout", "client class change accepted by host");
            network_lobby_change_character(st, "scout"); // duplicate class must be refused
        }));
        array_push(s, autotest_step(5, function(st) {
            autotest_check(st.net_lobby_players[0].character_id == "default", "host prevented duplicate class");
            network_lobby_change_character(st, "engineer");
        }));
        array_push(s, shot("lobby", 20));
        array_push(s, autotest_step(5, function(st) {
            network_host_start_mission(st);
            autotest_check(st.screen == "game" && st.num_players == 2, "host launched mission");
        }));
        array_push(s, shot("game_start", 40));
        array_push(s, autotest_step(1, undefined, function(st) { return st.players[1].node == "cave_1"; }, 1200));
        array_push(s, autotest_step(1, function(st) { autotest_check(st.players[1].node == "cave_1", "client movement executed by host"); }));
        array_push(s, autotest_step(1, undefined, function(st) { return global.at.vars.log_has(st, "ClientBeta drew") || global.at.vars.log_has(st, "ClientBeta:"); }, 900));
        array_push(s, autotest_step(1, function(st) {
            autotest_check(global.at.vars.log_has(st, "ClientBeta"), "client gather executed by host");
            autotest_check(game_do(st, "move", { node: "workstation" }), "host move");
        }));
        array_push(s, autotest_step(90, function(st) { game_do(st, "chat", { text: "SYNC-1" }); }));
        array_push(s, autotest_step(45, function(st) { autotest_log("DIGEST 1 " + autotest_digest(st)); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.players[1].ended_turn; }, 1800));
        array_push(s, shot("client_ready", 10));
        array_push(s, autotest_step(5, function(st) { game_do(st, "end_turn", {}); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.round_number == 2 && st.phase == "player_actions"; }, 600));
        array_push(s, autotest_step(1, function(st) {
            autotest_check(st.round_number == 2, "day advanced once the whole squad was ready");
            // Combat setup: mount a turret on tower 1 and put hostiles at the walls
            var cat = game_get_weapon_catalog();
            var it = cat[0];
            var w = { catalog_id: it.id, name: it.name, hp: it.hp, max_hp: it.hp, damage: it.damage, bonus_damage: 0, ability: it.ability, target_count: it.target_count, splash_count: 0, splash_dmg: 0, cooldown: 0, cost_res: it.cost_res, power_gem_used: false, disabled: false, stationed_tower: 0, alive: true };
            st.towers[0].weapon = w;
            array_push(st.weapons, w);
            game_spawn_alien(st, "drone", "active");
            game_spawn_alien(st, "scout", "active");
            st.net_dirty = true;
        }));
        array_push(s, autotest_step(60, function(st) { game_do(st, "chat", { text: "SYNC-2" }); }));
        array_push(s, autotest_step(45, function(st) { autotest_log("DIGEST 2 " + autotest_digest(st)); }));
        array_push(s, autotest_step(30, function(st) { game_do(st, "end_turn", {}); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.phase == "combat_weapons" || st.phase == "combat_aliens"; }, 1800));
        array_push(s, autotest_step(1, function(st) { autotest_check(st.phase == "combat_weapons" || st.phase == "combat_aliens", "squad entered defense phase"); }));
        array_push(s, shot("combat", 30));
        array_push(s, autotest_step(1, undefined, function(st) { return st.round_number == 3 && st.phase == "player_actions"; }, 3000));
        array_push(s, autotest_step(1, function(st) { autotest_check(st.round_number == 3, "client-driven combat resolved and day 3 began"); }));
        array_push(s, autotest_step(60, function(st) { game_do(st, "chat", { text: "SYNC-3" }); }));
        array_push(s, autotest_step(45, function(st) { autotest_log("DIGEST 3 " + autotest_digest(st)); }));
        array_push(s, shot("day3", 5));
        array_push(s, autotest_step(1, undefined, function(st) { return st.players[1][$ "disconnected"] ?? false; }, 1800));
        array_push(s, autotest_step(1, function(st) {
            autotest_check(st.players[1][$ "disconnected"] ?? false, "host marked departed client as offline");
            autotest_check(st.players[1].ended_turn, "offline operative no longer blocks the squad");
        }));
        array_push(s, shot("client_left", 20));
        array_push(s, autotest_step(5, function(st) { autotest_finish(); }));
    } else {
        array_push(s, autotest_step(40, function(st) {
            st.net_username = "ClientBeta";
            network_start_browsing(st);
        }));
        array_push(s, autotest_step(1, undefined, function(st) { return array_length(st.net_discovered_rooms) > 0; }, 900));
        array_push(s, shot("browser", 5));
        array_push(s, autotest_step(1, function(st) {
            var found = array_length(st.net_discovered_rooms) > 0;
            autotest_check(found, "room discovered via UDP broadcast");
            if (found) network_connect_to_room(st, st.net_discovered_rooms[0].ip, st.net_discovered_rooms[0].port);
            else network_connect_to_room(st, "127.0.0.1", NET_PORT_TCP);
        }));
        array_push(s, autotest_step(1, undefined, function(st) { return array_length(st.net_lobby_players) >= 2; }, 900));
        array_push(s, autotest_step(1, function(st) {
            autotest_check(array_length(st.net_lobby_players) == 2 && st.net_my_player_idx == 1, "joined lobby as operative 2");
            network_lobby_change_character(st, "scout");
        }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.net_lobby_players[1].character_id == "scout" && st.net_lobby_players[0].character_id == "engineer"; }, 900));
        array_push(s, autotest_step(1, function(st) { autotest_check(st.net_lobby_players[0].character_id == "engineer", "host class change replicated to client"); }));
        array_push(s, shot("lobby", 10));
        array_push(s, autotest_step(1, undefined, function(st) { return st.screen == "game"; }, 1800));
        array_push(s, autotest_step(1, function(st) {
            autotest_check(st.screen == "game", "mission started on client");
            autotest_check(st.num_players == 2 && st.players[0].name == "HostAlpha" && st.players[1].name == "ClientBeta", "roster replicated");
            autotest_check(st.players[1].character.id == "scout" && game_local_player_idx(st) == 1, "client controls its own scout");
        }));
        array_push(s, shot("game_start", 30));
        array_push(s, autotest_step(5, function(st) { game_do(st, "move", { node: "empty_2" }); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.players[1].node == "empty_2"; }, 300));
        array_push(s, autotest_step(30, function(st) { autotest_check(st.players[1].node == "empty_2", "move round-trip through host"); game_do(st, "move", { node: "cave_1" }); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.players[1].node == "cave_1"; }, 300));
        array_push(s, autotest_step(30, function(st) { global.at.vars.e0 = st.players[1].energy; game_do(st, "gather", {}); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.players[1].energy < global.at.vars.e0; }, 300));
        array_push(s, autotest_step(30, function(st) {
            autotest_check(st.players[1].energy < global.at.vars.e0, "gather round-trip through host");
            st.toast_is_error = false;
            game_do(st, "move", { node: "town" });
        }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.toast_is_error; }, 180));
        array_push(s, autotest_step(1, function(st) {
            autotest_check(st.toast_is_error, "illegal move rejected with a private notice");
            autotest_check(!global.at.vars.log_has(st, "not connected"), "rejection kept out of the shared squad log");
        }));
        array_push(s, shot("game_actions", 10));
        array_push(s, autotest_step(1, undefined, function(st) { return global.at.vars.log_has(st, "SYNC-1"); }, 1800));
        array_push(s, autotest_step(30, function(st) { autotest_log("DIGEST 1 " + autotest_digest(st)); }));
        array_push(s, autotest_step(70, function(st) { game_do(st, "end_turn", {}); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.round_number == 2 && st.phase == "player_actions"; }, 1800));
        array_push(s, autotest_step(1, function(st) { autotest_check(st.round_number == 2, "client saw the new day"); }));
        array_push(s, autotest_step(1, undefined, function(st) { return global.at.vars.log_has(st, "SYNC-2"); }, 1800));
        array_push(s, autotest_step(30, function(st) {
            autotest_log("DIGEST 2 " + autotest_digest(st));
            autotest_check(array_length(st.active_zone) == 2 && !is_undefined(st.towers[0].weapon), "host-side changes replicated (aliens + weapon)");
        }));
        array_push(s, autotest_step(70, function(st) { game_do(st, "end_turn", {}); }));
        array_push(s, autotest_step(1, undefined, function(st) { return !is_undefined(st.modal) && st.modal.type == "tactical_combat"; }, 1800));
        array_push(s, autotest_step(1, function(st) { autotest_check(!is_undefined(st.modal) && st.modal.type == "tactical_combat", "combat view opened on client"); }));
        array_push(s, autotest_step(60, function(st) {
            var tgt = 0;
            for (var a = 0; a < array_length(st.active_zone); a++) if (st.active_zone[a].catalog_id == "scout") tgt = a;
            global.at.vars.hp_before = 0;
            for (var a = 0; a < array_length(st.active_zone); a++) global.at.vars.hp_before += st.active_zone[a].hp;
            game_do(st, "combat_fire", { tower: 0, target: tgt });
        }));
        array_push(s, shot("combat_fire", 12));
        array_push(s, autotest_step(80, function(st) {
            var hp_now = 0;
            for (var a = 0; a < array_length(st.active_zone); a++) hp_now += st.active_zone[a].hp;
            autotest_check(hp_now < global.at.vars.hp_before || array_length(st.active_zone) < 2, "client shot damaged an alien");
            if (array_length(st.active_zone) > 0) game_do(st, "combat_fire", { tower: 0, target: 0 });
        }));
        array_push(s, autotest_step(90, function(st) { game_do(st, "combat_skip", {}); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.combat_subphase == "combat_concluded"; }, 2400));
        array_push(s, shot("combat_end", 20));
        array_push(s, autotest_step(5, function(st) { game_do(st, "combat_conclude", {}); }));
        array_push(s, autotest_step(1, undefined, function(st) { return st.round_number == 3 && st.phase == "player_actions"; }, 600));
        array_push(s, autotest_step(1, function(st) { autotest_check(st.round_number == 3 && is_undefined(st.modal), "client concluded combat; day 3 began"); }));
        array_push(s, autotest_step(1, undefined, function(st) { return global.at.vars.log_has(st, "SYNC-3"); }, 1800));
        array_push(s, autotest_step(30, function(st) { autotest_log("DIGEST 3 " + autotest_digest(st)); }));
        array_push(s, shot("day3", 5));
        array_push(s, autotest_step(30, function(st) { network_leave_room(st); }));
        array_push(s, autotest_step(30, function(st) { autotest_check(st.screen == "online_browser" && !st.is_online, "client left cleanly"); autotest_finish(); }));
    }
    return s;
}

/// @desc Order-stable fingerprint of the gameplay state (identical on host and clients when in sync)
function autotest_digest(st) {
    var keys = ["wood", "scrap", "stone", "metal", "crystals", "power_gem", "gold"];
    var parts = [string(st.round_number), st.phase];
    for (var k = 0; k < array_length(keys); k++) array_push(parts, keys[k] + "=" + string(st.storage[$ keys[k]]));
    for (var p = 0; p < st.num_players; p++) {
        var pl = st.players[p];
        array_push(parts, pl.name + "@" + pl.node + ":" + string(pl.energy) + (pl.ended_turn ? "R" : ""));
    }
    for (var t = 0; t < 4; t++) {
        var tw = st.towers[t];
        array_push(parts, "T" + string(t) + ":" + string(tw.hp) + (tw.alive ? "" : "X") + ":" + (is_undefined(tw.weapon) ? "-" : (tw.weapon.name + string(tw.weapon.hp))));
    }
    for (var a = 0; a < array_length(st.active_zone); a++) array_push(parts, "A" + string(st.active_zone[a].uid) + ":" + st.active_zone[a].catalog_id + ":" + string(st.active_zone[a].hp));
    for (var a = 0; a < array_length(st.spawn_zone); a++) array_push(parts, "S" + string(st.spawn_zone[a].uid) + ":" + st.spawn_zone[a].catalog_id);
    for (var i = 0; i < array_length(st.shop_available_items); i++) array_push(parts, "shop:" + (is_struct(st.shop_available_items[i]) ? st.shop_available_items[i].id : "-"));
    array_push(parts, "bp:" + string(array_length(st.blueprints)));
    array_push(parts, "fav:" + string(st.active_town_favor));
    array_push(parts, "log:" + ((array_length(st.action_logs) > 0) ? st.action_logs[0] : ""));
    var joined = "";
    for (var i = 0; i < array_length(parts); i++) joined += parts[i] + "|";
    return md5_string_utf8(joined) + "  " + string_copy(joined, 1, 400);
}

/// @desc Rules checks for the balance / mechanics changes
function autotest_scenario_logic() {
    var s = [];
    array_push(s, autotest_step(10, function(st) {
        // Audio: every sound asset is found and actually plays
        var missing = "";
        var nm = game_sfx_names();
        for (var i = 0; i < array_length(nm); i++) if ((global.sfx_sounds[$ nm[i]] ?? -1) == -1) missing += nm[i] + " ";
        nm = game_music_names();
        for (var i = 0; i < array_length(nm); i++) if ((global.music_sounds[$ nm[i]] ?? -1) == -1) missing += nm[i] + " ";
        autotest_check(missing == "", "all sound assets found" + ((missing == "") ? "" : (" (missing: " + missing + ")")));
        var ti = audio_play_sound(global.sfx_sounds[$ "click"], 10, false, 0.01);
        autotest_check(audio_is_playing(ti), "a sound effect plays");
        autotest_log("audio: music=" + global.music.cur + " inst=" + string(global.music.inst) + " playing=" + string(global.music.inst != -1 && audio_is_playing(global.music.inst)) + " gain=" + string((global.music.inst != -1) ? audio_sound_get_gain(global.music.inst) : -1) + " sfx_vol=" + string(st.settings.sfx_volume) + " music_vol=" + string(st.settings.music_volume) + " master=" + string(audio_get_master_gain(0)));
        autotest_check(game_final_day(st) == 20, "campaign is 20 days");
        st.num_players = 1;
        autotest_check(game_pylon_bonus(st, 0, 1) == 5, "pylon solo +5");
        st.num_players = 2;
        autotest_check(game_pylon_bonus(st, 0, 1) == 2 && game_pylon_bonus(st, 1, 1) == 2, "pylon duo +2 each");
        st.num_players = 3;
        st.pylon_rotation = 4;
        var b = [game_pylon_bonus(st, 0, 1), game_pylon_bonus(st, 1, 1), game_pylon_bonus(st, 2, 1)];
        autotest_check(b[0] == 1 && b[1] == 2 && b[2] == 1, "pylon trio +1 each, rotating +2 (day 4 -> operative 2)");
        st.pylon_rotation = 5;
        autotest_check(game_pylon_bonus(st, 2, 1) == 2 && game_pylon_bonus(st, 1, 1) == 1, "pylon trio rotation advances");
        st.num_players = 4;
        autotest_check(game_pylon_bonus(st, 3, 1) == 1, "pylon squad +1 each");
        st.setup_player_count = 2;
        st.setup_player_classes = [2, 0];
        game_reset_match(st);
        game_apply_setup_roster(st);
        st.screen = "game";
    }));
    // Railgun split both ways
    array_push(s, autotest_step(5, function(st) {
        st.active_zone = [];
        game_spawn_alien(st, "drone", "active"); game_spawn_alien(st, "drone", "active"); game_spawn_alien(st, "drone", "active");
        var w = { catalog_id: "railgun", name: "Railgun", damage: 20, bonus_damage: 0, hp: 8, max_hp: 8, alive: true };
        var dy0 = array_length(st.dying_aliens);
        game_apply_weapon_damage(st, w, 1);
        autotest_check(array_length(st.active_zone) == 2 && st.active_zone[0].hp == 3 && st.active_zone[1].hp == 4, "railgun overkill 11 split 6 left / 5 right");
        autotest_check(array_length(st.dying_aliens) == dy0 + 1, "killed alien plays a death animation");
        autotest_check(array_length(st.combat_arcs) >= 2, "pierce arcs shown to both neighbours");
        // Funnel: only one neighbour
        st.active_zone = [];
        game_spawn_alien(st, "drone", "active"); game_spawn_alien(st, "drone", "active");
        w.damage = 12;
        game_apply_weapon_damage(st, w, 0);
        autotest_check(array_length(st.active_zone) == 1 && st.active_zone[0].hp == 6, "railgun overkill funnels to the only neighbour");
        // Plasma mortar splash to left and right
        st.active_zone = [];
        for (var i = 0; i < 4; i++) game_spawn_alien(st, "drone", "active");
        var m = { catalog_id: "plasma_mortar", name: "Plasma Mortar", damage: 7, bonus_damage: 0, hp: 8, max_hp: 8, alive: true };
        var arcs0 = array_length(st.combat_arcs);
        game_apply_weapon_damage(st, m, 1);
        autotest_check(st.active_zone[0].hp == 6 && st.active_zone[1].hp == 2 && st.active_zone[2].hp == 6 && st.active_zone[3].hp == 9, "mortar: 7 primary, 3 to left and right neighbours");
        autotest_check(array_length(st.combat_arcs) == arcs0 + 2, "mortar lobs shown");
        st.active_zone = [];
    }));
    // Workshop: forge metal location, rebuild once, reinforce
    array_push(s, autotest_step(5, function(st) {
        var pl = st.players[0];
        pl.energy = 9;
        st.storage.stone = 2; st.storage.scrap = 2;
        pl.node = "main_base";
        autotest_check(!game_do(st, "craft_metal", {}), "forge metal refused outside the Workstation");
        pl.node = "workstation";
        autotest_check(game_do(st, "craft_metal", {}) && st.storage.metal == 1, "forge metal at the Workstation");
        var t0 = st.towers[0];
        t0.alive = false; t0.hp = 0;
        st.storage.gold = 50; st.storage.power_gem = 4; st.storage.metal = 10;
        autotest_check(game_do(st, "rebuild_tower", { tower: 0 }) && t0.alive && t0.hp == t0.max_hp && t0.rebuilt, "rebuild fallen tower");
        autotest_check(st.storage.gold == 0 && st.storage.power_gem == 0 && st.storage.metal == 0, "rebuild costs 50g, 4 gems, 10 metal");
        t0.alive = false; t0.hp = 0;
        st.storage.gold = 50; st.storage.power_gem = 4; st.storage.metal = 10;
        autotest_check(!game_do(st, "rebuild_tower", { tower: 0 }) && !t0.alive, "a tower can only be rebuilt once");
        var t1 = st.towers[1];
        st.storage.gold = 45; st.storage.power_gem = 3; st.storage.metal = 10;
        autotest_check(game_do(st, "reinforce_tower", { tower: 1 }) && t1.max_hp == 15 && t1.hp == 15, "reinforce +5 max HP");
        autotest_check(!game_do(st, "reinforce_tower", { tower: 1 }), "reinforce needs 45g, 3 gems, 10 metal");
    }));
    // Starter blueprint + Hatcher
    array_push(s, autotest_step(5, function(st) {
        var fresh = game_init_state(2);
        autotest_check(array_length(fresh.blueprints) == 1 && fresh.blueprints[0].name == "Makeshift Cannon" && fresh.blueprints[0].starter, "missions start with the Makeshift Cannon blueprint");
        var in_shop = false;
        var cat = game_get_weapon_catalog();
        for (var c = 0; c < array_length(cat); c++) if (cat[c].id == "makeshift_cannon") in_shop = true;
        autotest_check(!in_shop, "Makeshift Cannon is never sold in the shop");
        var pl = st.players[0];
        pl.node = "workstation"; pl.energy = 9;
        st.blueprints = [game_get_starter_blueprint()];
        for (var t = 0; t < 4; t++) st.towers[t].weapon = undefined;
        st.storage.stone = 6; st.storage.wood = 4; st.storage.scrap = 2;
        for (var t = 0; t < 4; t++) { st.towers[t].alive = true; st.towers[t].hp = st.towers[t].max_hp; }
        autotest_check(game_do(st, "craft_bp", { bp: 0, tower: 0 }) && !is_undefined(st.towers[0].weapon) && st.towers[0].weapon.name == "Makeshift Cannon", "forge the Makeshift Cannon");
        autotest_check(array_length(st.blueprints) == 1, "the starter blueprint is kept after forging");
        autotest_check(game_do(st, "craft_bp", { bp: 0, tower: 1 }), "it can be forged again");
        autotest_check(st.towers[0].weapon.hp == 4 && st.towers[0].weapon.damage == 5, "weak cannon: 4 HP, 5 damage");
        st.active_zone = []; st.spawn_zone = [];
        game_spawn_alien(st, "hatcher", "active");
        var before = array_length(st.active_zone);
        game_advance_wave_phase(st);
        autotest_check(array_length(st.active_zone) == before + 1, "a Hatcher spawns 1 Hatchling on its first day");
        st.spawn_zone = [];
        var before2 = array_length(st.active_zone);
        game_advance_wave_phase(st);
        autotest_check(array_length(st.active_zone) == before2 + 2, "then 2 Hatchlings every day after");
        st.spawn_zone = [];
        st.active_zone = [];
        st.phase = "player_actions";
    }));
    // Manual fire with picked targets
    array_push(s, autotest_step(5, function(st) {
        var pl = st.players[0];
        st.phase = "player_actions";
        for (var t = 0; t < 4; t++) { st.towers[t].alive = true; st.towers[t].hp = st.towers[t].max_hp; st.towers[t].manual_cooldown = 0; st.towers[t].manual_powers_this_turn = 0; }
        var cat = game_get_weapon_catalog();
        var it = cat[0]; // turret: 4 damage, 2 shots
        st.towers[0].weapon = { catalog_id: it.id, name: it.name, hp: it.hp, max_hp: it.hp, damage: it.damage, bonus_damage: 0, ability: it.ability, target_count: it.target_count, splash_count: 0, splash_dmg: 0, cooldown: 0, cost_res: it.cost_res, power_gem_used: false, disabled: false, stationed_tower: 0, alive: true };
        st.active_zone = []; st.spawn_zone = [];
        var a1 = game_spawn_alien(st, "drone", "active");
        var a2 = game_spawn_alien(st, "drone", "active");
        var a3 = game_spawn_alien(st, "drone", "active");
        pl.node = "tower_1"; pl.energy = 9;
        autotest_check(game_do(st, "manual_fire", { targets: [a3.uid, a1.uid] }), "manual fire with two picked targets");
        autotest_check(a3.hp == 5 && a1.hp == 5 && a2.hp == 9, "turret's two shots hit exactly the picked aliens");
        st.towers[0].manual_cooldown = 0;
        autotest_check(game_do(st, "manual_fire", { targets: [a2.uid] }) && a2.hp == 1, "one pick: both shots hit that alien");

        // Day-time volley opens the attack screen and resolves shots like the night defense
        st.towers[0].manual_cooldown = 0; st.towers[0].manual_powers_this_turn = 0;
        st.active_zone = [];
        var v1 = game_spawn_alien(st, "drone", "active");
        var v2 = game_spawn_alien(st, "drone", "active");
        pl.energy = 9;
        autotest_check(game_do(st, "volley_start", {}) && st.phase == "combat_weapons" && st.modal.type == "tactical_combat" && st.tower_weapon_shots[0] == 2, "manual fire opens the attack screen with the turret's 2 shots");
        autotest_check(pl.energy == 9 - game_fire_cost(st, pl), "volley costs the fire Energy");
        game_do(st, "combat_fire", { tower: 0, target: 1 });
        game_do(st, "combat_fire", { tower: 0, target: 1 });
        for (var k = 0; k < 200 && st.phase != "player_actions"; k++) game_combat_update(st);
        autotest_check(st.phase == "player_actions" && is_undefined(st[$ "volley"]) && v2.hp == 1 && v1.hp == 9, "volley shots land, then the squad is back at the base (no alien retaliation)");

        // A manual Tesla shocks everything, and the shock carries into the night's attack
        var cat2 = game_get_weapon_catalog();
        var tz = undefined;
        for (var c = 0; c < array_length(cat2); c++) if (cat2[c].id == "tesla") tz = cat2[c];
        st.towers[1].weapon = { catalog_id: tz.id, name: tz.name, hp: tz.hp, max_hp: tz.hp, damage: tz.damage, bonus_damage: 0, ability: tz.ability, target_count: tz.target_count, splash_count: 0, splash_dmg: 0, cooldown: 0, cost_res: tz.cost_res, power_gem_used: false, disabled: false, stationed_tower: 1, alive: true };
        st.active_zone = [];
        var s1 = game_spawn_alien(st, "drone", "active");
        var s2 = game_spawn_alien(st, "armorback", "active");
        pl.node = "tower_2"; pl.energy = 9;
        autotest_check(game_do(st, "volley_start", {}), "Tesla volley opens");
        autotest_check(game_do(st, "combat_tesla", { tower: 1 }) && s1.tesla_weakened && s2.tesla_weakened && s1.hp < 9, "manual Tesla hits every alien and shocks them");
        for (var k = 0; k < 200 && st.phase != "player_actions"; k++) game_combat_update(st);
        autotest_check(st.phase == "player_actions", "Tesla volley closes");
        game_begin_defense(st);
        autotest_check(s1.tesla_weakened && s2.tesla_weakened, "the shock is still on the aliens when the night's defense starts");
        st.phase = "player_actions"; st.modal = undefined; st.active_zone = [];

        // Standing down before firing refunds the Energy
        var s3 = game_spawn_alien(st, "drone", "active");
        pl.node = "tower_1"; pl.energy = 9; st.towers[0].manual_cooldown = 0; st.towers[0].manual_powers_this_turn = 0;
        game_do(st, "volley_start", {});
        game_do(st, "combat_skip", {});
        autotest_check(st.phase == "player_actions" && pl.energy == 9 && st.towers[0].manual_powers_this_turn == 0, "standing down without firing refunds the Energy");
        st.active_zone = [];

        // Resource Drone: 3 resource cards every morning
        var dr = undefined;
        for (var c = 0; c < array_length(cat2); c++) if (cat2[c].id == "resource_drone") dr = cat2[c];
        autotest_check(dr.cost_gold == 10 && is_undefined(dr.cost_res[$ "power_gem"]), "Resource Drone is cheaper (10 gold, no Power Gem)");
        var old_w = st.weapons;
        st.weapons = [{ catalog_id: "resource_drone", alive: true }];
        var tot0 = 0; var rk = variable_struct_get_names(st.storage);
        for (var r = 0; r < array_length(rk); r++) if (rk[r] != "gold") tot0 += st.storage[$ rk[r]];
        game_advance_wave_phase(st);
        var tot1 = 0;
        for (var r = 0; r < array_length(rk); r++) if (rk[r] != "gold") tot1 += st.storage[$ rk[r]];
        autotest_check(tot1 >= tot0 + 3, "Resource Drone brings back at least 3 resources a day");
        st.weapons = old_w;
        st.phase = "player_actions";

        // Gatling Gun: 5 shots of 1 damage
        var gg = undefined;
        for (var c = 0; c < array_length(cat2); c++) if (cat2[c].id == "gatling_gun") gg = cat2[c];
        autotest_check(!is_undefined(gg) && gg.damage == 1 && gg.hp == 12 && gg.cost_gold == 6, "Gatling Gun in the catalog: 1 damage, 12 HP, 6 gold");
        st.towers[0].weapon = { catalog_id: gg.id, name: gg.name, hp: gg.hp, max_hp: gg.hp, damage: gg.damage, bonus_damage: 0, ability: gg.ability, target_count: gg.target_count, splash_count: 0, splash_dmg: 0, cooldown: 0, cost_res: gg.cost_res, power_gem_used: false, disabled: false, stationed_tower: 0, alive: true };
        st.towers[0].manual_cooldown = 0; st.towers[0].manual_powers_this_turn = 0;
        st.active_zone = [];
        var gh = game_spawn_alien(st, "hatchling", "active");
        var gd = game_spawn_alien(st, "drone", "active");
        pl.node = "tower_1"; pl.energy = 9;
        autotest_check(game_do(st, "volley_start", {}) && st.tower_weapon_shots[0] == 5, "Gatling volley has 5 shots");
        game_do(st, "combat_fire", { tower: 0, target: 0 });
        game_do(st, "combat_fire", { tower: 0, target: 0 });
        for (var g = 0; g < 3; g++) game_do(st, "combat_fire", { tower: 0, target: 1 });
        for (var k = 0; k < 200 && st.phase != "player_actions"; k++) game_combat_update(st);
        autotest_check(!gh.alive && gd.hp <= 6 && gd.hp >= 5 && st.phase == "player_actions", "Gatling: 2 shots kill a Hatchling, the rest hit the Drone");

        // Flat 5-gold reroll
        pl.node = "shop"; pl.energy = 9; st.storage.gold = 10;
        autotest_check(game_do(st, "reroll", {}) && game_do(st, "reroll", {}) && st.storage.gold == 0 && st.shop_reroll_cost == 5, "shop rerolls cost a flat 5 Gold");
        autotest_check(!game_do(st, "reroll", {}), "reroll refused without 5 Gold");

        // Demolish: 75% of materials at full health, scaled by health
        var tcat = undefined;
        for (var c = 0; c < array_length(cat2); c++) if (cat2[c].id == "turret") tcat = cat2[c];
        st.towers[0].weapon = { catalog_id: tcat.id, name: tcat.name, hp: 12, max_hp: 12, damage: tcat.damage, bonus_damage: 0, ability: tcat.ability, target_count: 2, splash_count: 0, splash_dmg: 0, cooldown: 0, cost_res: { metal: 4, wood: 4 }, power_gem_used: false, disabled: false, stationed_tower: 0, alive: true };
        st.storage.metal = 0; st.storage.wood = 0;
        pl.node = "tower_1"; pl.energy = 9;
        autotest_check(game_do(st, "dismantle", {}) && is_undefined(st.towers[0].weapon) && st.storage.metal == 3 && st.storage.wood == 3, "demolish at full health returns 75% (4 Metal + 4 Wood -> 3 + 3)");
        st.towers[0].weapon = { catalog_id: tcat.id, name: tcat.name, hp: 6, max_hp: 12, damage: tcat.damage, bonus_damage: 0, ability: tcat.ability, target_count: 2, splash_count: 0, splash_dmg: 0, cooldown: 0, cost_res: { metal: 8, wood: 4 }, power_gem_used: false, disabled: false, stationed_tower: 0, alive: true };
        st.storage.metal = 0; st.storage.wood = 0;
        autotest_check(game_do(st, "dismantle", {}) && st.storage.metal == 3 && st.storage.wood == 2, "demolish at half health returns 37.5% (8 Metal + 4 Wood -> 3 + 2)");
        st.active_zone = [];
        st.phase = "player_actions";
    }));
    // Starting gold and the sell cart
    array_push(s, autotest_step(5, function(st) {
        autotest_check(game_starting_gold(1) == 0 && game_starting_gold(2) == 5 && game_starting_gold(3) == 10 && game_starting_gold(4) == 15, "starting gold 0 / 5 / 10 / 15");
        var fresh = game_init_state(3);
        autotest_check(fresh.storage.gold == 10, "a new 3-operative mission starts with 10 gold");
        var pl = st.players[0];
        pl.node = "town";
        pl.energy = 9;
        st.active_town_favor = 2; // metal favor: wood and stone sell at base price
        st.storage.wood = 4; st.storage.stone = 3; st.storage.gold = 0;
        var e0 = pl.energy;
        autotest_check(game_do(st, "sell_cart", { cart: { wood: 4, stone: 3 } }), "sell a mixed cart");
        autotest_check(st.storage.gold == 4 * 2 + 3 * 3 && st.storage.wood == 0 && st.storage.stone == 0, "cart pays every item (17 gold)");
        autotest_check(e0 - pl.energy == 3 * game_task_cost(pl), "7 items = 3 trades of up to 3");
        st.storage.metal = 9; pl.energy = 2;
        autotest_check(!game_do(st, "sell_cart", { cart: { metal: 9 } }) && st.storage.metal == 9, "cart refused without enough energy");
    }));
    // Morning warning when something reaches the walls
    array_push(s, autotest_step(5, function(st) {
        st.active_zone = []; st.spawn_zone = [];
        game_spawn_alien(st, "scout", "spawn");
        game_advance_wave_phase(st);
        autotest_check(string_pos("1 new hostile", st.turn_popup_message) > 0 && string_pos("reached the walls", st.turn_popup_message) > 0 && string_pos("Scout", st.turn_popup_message) == 0, "day banner warns how many new hostiles reached the walls (no names)");
        autotest_log("banner: " + st.turn_popup_title + " | " + st.turn_popup_message);
        st.turn_popup_timer = 0;
        // No weapons: defense goes straight to the alien turn, which must wait for its banner
        for (var t = 0; t < 4; t++) st.towers[t].weapon = undefined;
        st.phase = "player_actions";
        game_begin_defense(st);
        autotest_check(st.combat_subphase == "alien_attacks" && st.turn_popup_timer > 0, "alien turn announced with a banner");
    }));
    array_push(s, autotest_step(30, function(st) {
        autotest_check(st.alien_attack_idx == 0 && array_length(st.combat_projectiles) == 0, "aliens hold fire while the banner is up");
    }));
    array_push(s, autotest_step(1, undefined, function(st) { return st.alien_attack_idx > 0 || st.combat_subphase == "combat_concluded"; }, 400));
    array_push(s, autotest_step(1, function(st) {
        autotest_check(st.turn_popup_timer <= 0, "aliens attacked only after the banner cleared");
        autotest_finish();
    }));
    return s;
}
