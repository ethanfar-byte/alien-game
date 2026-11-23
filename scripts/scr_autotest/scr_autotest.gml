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
    array_push(s, autotest_step(2, function(st) { autotest_mouse(-1000, -1000); ui_transition_to(st, "local_setup"); st.setup_player_count = 3; st.setup_player_classes = [1, 2, 4, 0]; }));
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
        autotest_check(st.toast_is_error, "illegal move shows private error toast");
    }));
    array_push(s, shot("05_board_moved", 40));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "shop" }; }));
    array_push(s, shot("06_shop"));
    array_push(s, autotest_step(2, function(st) {
        var gold0 = st.storage.gold;
        game_do(st, "buy", { slot: 0 });
        autotest_check(array_length(st.blueprints) == 1 && st.storage.gold < gold0, "bought blueprint");
        st.modal = { type: "town" };
    }));
    array_push(s, shot("07_town"));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "repair" }; }));
    array_push(s, shot("08_workstation"));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "settings" }; }));
    array_push(s, shot("09_settings"));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "pause" }; }));
    array_push(s, shot("10_pause"));
    array_push(s, autotest_step(2, function(st) { st.modal = { type: "help" }; }));
    array_push(s, shot("11_help"));
    array_push(s, autotest_step(2, function(st) { st.modal = undefined;
        var cat = game_get_weapon_catalog();
        var picks = ["turret", "cannon", "tesla", "flamethrower"];
        for (var t = 0; t < 4; t++) {
            var it = undefined;
            for (var c = 0; c < array_length(cat); c++) if (cat[c].id == picks[t]) it = cat[c];
            var w = { catalog_id: it.id, name: it.name, hp: it.hp, max_hp: it.hp, damage: it.damage, bonus_damage: 0, ability: it.ability, target_count: it.target_count, splash_count: 0, splash_dmg: 0, cooldown: 0, cost_res: it.cost_res, power_gem_used: false, disabled: false, stationed_tower: t, alive: true };
            st.towers[t].weapon = w;
            array_push(st.weapons, w);
        }
        st.towers[1].hp = 6;
        game_spawn_alien(st, "drone", "active");
        game_spawn_alien(st, "armorback", "active");
        game_spawn_alien(st, "acid_spitter", "active");
        game_spawn_alien(st, "goliath", "active");
        game_spawn_alien(st, "leech", "spawn");
        game_spawn_alien(st, "scout", "spawn");
        game_spawn_alien(st, "alien_queen", "spawn");
        game_log(st, "[CHAT] Player 2: Heads up, big one on the east side.");
        autotest_mouse(560, 1000);
    }));
    array_push(s, shot("12_board_threats", 30));
    array_push(s, autotest_step(2, function(st) { autotest_mouse(-1000, -1000); game_do(st, "begin_defense", {}); }));
    array_push(s, autotest_step(170, function(st) { autotest_check(st.phase == "combat_weapons", "defense phase started"); autotest_mouse(1060, 300); }));
    array_push(s, shot("13_combat_start", 10));
    array_push(s, autotest_step(2, function(st) { game_do(st, "combat_fire", { tower: 0, target: 3 }); }));
    array_push(s, shot("14_combat_projectile", 10));
    array_push(s, autotest_step(1, undefined, function(st) { return array_length(st.combat_player_projectiles) == 0; }, 300));
    array_push(s, shot("15_combat_damage_numbers", 3));
    array_push(s, autotest_step(2, function(st) { game_do(st, "combat_tesla", { tower: 2 }); }));
    array_push(s, shot("15b_tesla", 6));
    array_push(s, autotest_step(20, function(st) { autotest_mouse(-1000, -1000); game_do(st, "combat_skip", {}); }));
    array_push(s, shot("16_combat_aliens", 50));
    array_push(s, autotest_step(1, undefined, function(st) { return st.combat_subphase == "combat_concluded" || st.phase == "game_over"; }, 1500));
    array_push(s, shot("17_combat_concluded", 20));
    array_push(s, autotest_step(2, function(st) { game_do(st, "combat_conclude", {}); }));
    array_push(s, autotest_step(30, function(st) { autotest_check(st.phase == "player_actions" && st.round_number == 2, "next day after combat"); }));
    array_push(s, shot("18_next_day", 5));
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
    array_push(s, autotest_step(2, function(st) { st.is_host = false; st.screen = "title"; }));
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
