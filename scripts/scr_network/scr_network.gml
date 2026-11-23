/// @desc Local Wi-Fi (LAN) multiplayer.
///
/// Architecture: HOST-AUTHORITATIVE.
///  - The host runs the only copy of the game simulation (decks, shop, aliens, combat dice...).
///  - Clients never mutate gameplay state. Every gameplay input is sent to the host as a
///    request ("req"); the host validates it against the sender's own operative, applies it,
///    then streams a state snapshot ("snap") back to every client.
///  - Visual/audio feedback (floating text, impacts, damage numbers, sounds) produced by the
///    simulation is queued as lightweight "fx" events and shipped with the next snapshot so
///    every screen sees and hears the same thing.
///  - Room discovery uses UDP broadcast beacons; the game itself runs over TCP.

#macro NET_PORT_TCP 6510
#macro NET_PORT_UDP 6511
#macro NET_PROTOCOL 4
#macro NET_MAX_PLAYERS 4

function network_init_manager(state) {
    state.net_username = "Operative" + string(irandom_range(100, 999));
    state.net_mode = "none"; // "none" | "host" | "client"
    state.net_server_socket = -1;
    state.net_client_socket = -1;
    state.net_udp_listener = -1;
    state.net_udp_broadcaster = -1;
    state.net_clients = [];          // Host only: [ { socket, peer, joined, p_idx, name } ]
    state.net_lobby_players = [];    // Roster: [ { name, is_host, character_id, p_idx, ip, peer } ]
    state.net_discovered_rooms = [];
    state.net_my_player_idx = 0;
    state.net_my_peer = 0;
    state.net_next_peer = 1;
    state.net_direct_ip_input = "127.0.0.1";
    state.net_direct_ip_editing = false;
    state.net_username_input = state.net_username;
    state.net_username_editing = false;
    state.net_broadcast_timer = 0;
    state.net_status_message = "";
    state.is_online = false;
    state.is_host = false;
    state.net_error_message = "";
    state.net_error_timer = 0;
    state.net_local_ip = "";
    state.net_host_ip = "";
    // Sync bookkeeping
    state.net_dirty = false;
    state.net_snap_timer = 0;
    state.net_fx_queue = [];
    state.net_snap_seq = 0;
    state.net_last_log_sent = -1;
    state.net_last_popup_seen = -1;
    state.net_last_log_seen = -1;
    state.net_pending_requests = 0;
}

/// @desc Applies network socket configuration (connect timeout so a bad IP doesn't freeze the game)
function network_configure() {
    network_set_config(network_config_connect_timeout, 2500);
}

/// @desc Cleans up all networking sockets safely
function network_cleanup_sockets(state) {
    if (state.net_server_socket >= 0) { network_destroy(state.net_server_socket); state.net_server_socket = -1; }
    if (state.net_client_socket >= 0) { network_destroy(state.net_client_socket); state.net_client_socket = -1; }
    if (state.net_udp_listener >= 0) { network_destroy(state.net_udp_listener); state.net_udp_listener = -1; }
    if (state.net_udp_broadcaster >= 0) { network_destroy(state.net_udp_broadcaster); state.net_udp_broadcaster = -1; }
    state.net_clients = [];
    state.net_mode = "none";
    state.is_online = false;
    state.is_host = false;
    state.net_fx_queue = [];
    state.net_dirty = false;
}

/// @desc Best-effort lookup of this machine's LAN IPv4 address (for the "join by IP" hint)
function network_guess_local_ip() {
    var host = environment_get_variable("COMPUTERNAME");
    if (host == "") return "";
    var ip = network_resolve(host);
    if (is_string(ip) && string_count(".", ip) == 3 && string_pos("127.", ip) != 1) return ip;
    return "";
}

// =============================================================================
// LOBBY: HOSTING, BROWSING, JOINING
// =============================================================================
function network_start_hosting(state) {
    network_cleanup_sockets(state);
    network_configure();

    state.net_server_socket = network_create_server(network_socket_tcp, NET_PORT_TCP, NET_MAX_PLAYERS);
    if (state.net_server_socket < 0) {
        state.net_error_message = "Couldn't open port " + string(NET_PORT_TCP) + " - is another copy of the game already hosting?";
        state.net_error_timer = 240;
        game_play_sfx("error");
        return false;
    }
    state.net_udp_broadcaster = network_create_socket(network_socket_udp);

    state.net_mode = "host";
    state.is_online = true;
    state.is_host = true;
    state.net_my_player_idx = 0;
    state.net_my_peer = 0;
    state.net_next_peer = 1;
    state.net_local_ip = network_guess_local_ip();
    state.net_lobby_players = [
        { name: state.net_username, is_host: true, character_id: "default", p_idx: 0, ip: (state.net_local_ip != "" ? state.net_local_ip : "127.0.0.1"), peer: 0 }
    ];
    state.net_broadcast_timer = 999; // beacon immediately
    ui_transition_to(state, "online_lobby");
    game_play_sfx("click");
    return true;
}

function network_start_browsing(state) {
    network_cleanup_sockets(state);
    network_configure();
    state.net_discovered_rooms = [];
    state.net_udp_listener = network_create_server(network_socket_udp, NET_PORT_UDP, 10);
    if (state.net_udp_listener < 0) {
        state.net_status_message = "Room auto-discovery unavailable (UDP " + string(NET_PORT_UDP) + " busy). Use Direct IP.";
    } else {
        state.net_status_message = "Scanning your local network for rooms...";
    }
    ui_transition_to(state, "online_browser");
    return true;
}

function network_connect_to_room(state, target_ip, target_port = NET_PORT_TCP) {
    network_cleanup_sockets(state);
    network_configure();

    state.net_client_socket = network_create_socket(network_socket_tcp);
    if (state.net_client_socket < 0) {
        state.net_error_message = "Failed to create network socket.";
        state.net_error_timer = 240;
        return false;
    }
    var res = network_connect(state.net_client_socket, target_ip, target_port);
    if (res < 0) {
        state.net_error_message = "No room answered at " + target_ip + ". Check the IP and that you're on the same Wi-Fi.";
        state.net_error_timer = 300;
        network_cleanup_sockets(state);
        network_start_browsing(state);
        game_play_sfx("error");
        return false;
    }
    state.net_mode = "client";
    state.is_online = true;
    state.is_host = false;
    state.net_host_ip = target_ip;
    state.net_lobby_players = [];
    state.net_status_message = "Connecting to host...";
    network_send_json(state.net_client_socket, {
        type: "join_request",
        protocol: NET_PROTOCOL,
        username: state.net_username
    });
    ui_transition_to(state, "online_lobby");
    game_play_sfx("click");
    return true;
}

/// @desc Leave the current room (client) or close it (host) and go back to the browser
function network_leave_room(state) {
    if (state.is_host) {
        network_broadcast_to_all_clients(state, { type: "room_closed", reason: "The host closed the room." });
    }
    network_cleanup_sockets(state);
    state.net_lobby_players = [];
    network_start_browsing(state);
}

// =============================================================================
// LOW LEVEL SEND HELPERS
// =============================================================================
function network_send_json(sock, struct_data) {
    if (sock < 0) return false;
    var json_str = json_stringify(struct_data);
    var buf = buffer_create(string_byte_length(json_str) + 1, buffer_fixed, 1);
    buffer_write(buf, buffer_string, json_str);
    var res = network_send_packet(sock, buf, buffer_tell(buf));
    buffer_delete(buf);
    return (res >= 0);
}

function network_broadcast_udp(sock, port, struct_data) {
    if (sock < 0) return false;
    var json_str = json_stringify(struct_data);
    var buf = buffer_create(string_byte_length(json_str) + 1, buffer_fixed, 1);
    buffer_write(buf, buffer_string, json_str);
    network_send_broadcast(sock, port, buf, buffer_tell(buf));
    buffer_delete(buf);
    return true;
}

function network_broadcast_to_all_clients(state, struct_data, exclude_socket = -1) {
    if (!state.is_host) return;
    // Serialize once, send to everyone
    var json_str = json_stringify(struct_data);
    var buf = buffer_create(string_byte_length(json_str) + 1, buffer_fixed, 1);
    buffer_write(buf, buffer_string, json_str);
    var sz = buffer_tell(buf);
    for (var i = 0; i < array_length(state.net_clients); i++) {
        var cl = state.net_clients[i];
        if (cl.socket != exclude_socket && cl.socket >= 0 && cl.joined) {
            network_send_packet(cl.socket, buf, sz);
        }
    }
    buffer_delete(buf);
}

function network_broadcast_lobby(state) {
    network_broadcast_to_all_clients(state, { type: "lobby", lobby: state.net_lobby_players });
}

/// @desc Host: private message to one operative (e.g. "not enough energy" for a rejected request)
function network_host_send_notice(state, p_idx, text) {
    for (var c = 0; c < array_length(state.net_clients); c++) {
        var cl = state.net_clients[c];
        if (cl.joined && cl.p_idx == p_idx) {
            network_send_json(cl.socket, { type: "notice", text: text });
            return;
        }
    }
}

/// @desc Client: sends a gameplay request to the host
function network_send_request(state, action, args) {
    if (state.net_client_socket < 0) return;
    state.net_pending_requests++;
    network_send_json(state.net_client_socket, { type: "req", a: action, args: args });
}

// =============================================================================
// STEP: BEACONS, DISCOVERY PRUNING, SNAPSHOT STREAMING
// =============================================================================
function network_step_update(state) {
    if (state.net_error_timer > 0) state.net_error_timer--;

    // Host: UDP room beacon (~2x per second) while in the lobby
    if (state.net_mode == "host" && state.screen == "online_lobby") {
        state.net_broadcast_timer++;
        if (state.net_broadcast_timer >= 30 && state.net_udp_broadcaster >= 0) {
            state.net_broadcast_timer = 0;
            network_broadcast_udp(state.net_udp_broadcaster, NET_PORT_UDP, {
                type: "room_beacon",
                protocol: NET_PROTOCOL,
                room_name: state.net_username + "'s Outpost",
                host_name: state.net_username,
                players: array_length(state.net_lobby_players),
                max_players: NET_MAX_PLAYERS,
                port: NET_PORT_TCP
            });
        }
    }

    // Browser: prune rooms that stopped beaconing
    if (state.screen == "online_browser") {
        for (var r = array_length(state.net_discovered_rooms) - 1; r >= 0; r--) {
            if (current_time - state.net_discovered_rooms[r].last_seen > 4000) {
                array_delete(state.net_discovered_rooms, r, 1);
            }
        }
    }

    // Host: stream state snapshots during a match
    if (state.net_mode == "host" && state.screen == "game") {
        state.net_snap_timer++;
        var in_combat = (state.phase == "combat_weapons" || state.phase == "combat_aliens");
        var animating = in_combat && (array_length(state.combat_player_projectiles) > 0 || array_length(state.combat_projectiles) > 0 || state.combat_subphase == "alien_attacks");
        var interval = animating ? 3 : 2;
        if ((state.net_dirty || array_length(state.net_fx_queue) > 0 || animating) && state.net_snap_timer >= interval) {
            network_host_send_snapshot(state);
        } else if (state.net_snap_timer >= 90) {
            network_host_send_snapshot(state); // heartbeat
        }
    }
}

function network_host_send_snapshot(state) {
    var include_logs = (state.log_counter != state.net_last_log_sent);
    var snap = net_snapshot_build(state, include_logs);
    snap.type = "snap";
    snap.fx = state.net_fx_queue;
    network_broadcast_to_all_clients(state, snap);
    state.net_fx_queue = [];
    state.net_last_log_sent = state.log_counter;
    state.net_dirty = false;
    state.net_snap_timer = 0;
}

// =============================================================================
// ASYNC NETWORK EVENT
// =============================================================================
function network_handle_async(state, load_map) {
    var net_type = load_map[? "type"];
    var sock_id = load_map[? "id"];
    var ip_from = load_map[? "ip"] ?? "127.0.0.1";

    switch (net_type) {
        case network_type_connect: {
            if (!state.is_host) break;
            var new_socket = load_map[? "socket"];
            if (array_length(state.net_lobby_players) >= NET_MAX_PLAYERS || state.screen == "game") {
                network_send_json(new_socket, { type: "join_reject", reason: (state.screen == "game") ? "That mission is already in progress." : "That room is full (4/4)." });
                break;
            }
            array_push(state.net_clients, { socket: new_socket, peer: state.net_next_peer, joined: false, p_idx: -1, name: "", ip: ip_from });
            state.net_next_peer++;
            break;
        }

        case network_type_disconnect: {
            var dis_socket = load_map[? "socket"];
            if (state.is_host) {
                network_host_on_client_lost(state, dis_socket);
            } else if (state.net_mode == "client") {
                network_client_lost_host(state, "Lost connection to the host.");
            }
            break;
        }

        case network_type_data: {
            var buf = load_map[? "buffer"];
            if (is_undefined(buf)) break;
            buffer_seek(buf, buffer_seek_start, 0);
            var raw_str = buffer_read(buf, buffer_string);
            var msg = undefined;
            try { msg = json_parse(raw_str); } catch (e) { break; }
            if (!is_struct(msg) || !variable_struct_exists(msg, "type")) break;

            if (state.is_host) network_host_on_message(state, sock_id, ip_from, msg);
            else network_client_on_message(state, sock_id, ip_from, msg);
            break;
        }
    }
}

function network_host_find_client(state, sock) {
    for (var c = 0; c < array_length(state.net_clients); c++) {
        if (state.net_clients[c].socket == sock) return c;
    }
    return -1;
}

function network_host_reindex_lobby(state) {
    for (var lp = 0; lp < array_length(state.net_lobby_players); lp++) {
        state.net_lobby_players[lp].p_idx = lp;
    }
}

function network_host_on_client_lost(state, sock) {
    var ci = network_host_find_client(state, sock);
    if (ci < 0) return;
    var cl = state.net_clients[ci];
    array_delete(state.net_clients, ci, 1);
    if (!cl.joined) return;

    if (state.screen == "game") {
        // Mid-mission: the operative stays on the board but is marked offline and can't hold up the squad
        if (cl.p_idx >= 0 && cl.p_idx < state.num_players) {
            var pl = state.players[cl.p_idx];
            pl.disconnected = true;
            pl.ended_turn = true;
            pl.energy = 0;
            game_log(state, pl.name + " lost connection. Their operative will stand by.");
            state.net_dirty = true;
            if (state.phase == "player_actions" && game_check_all_players_ready(state)) {
                game_online_all_ready(state);
            }
        }
    } else {
        for (var lp = 0; lp < array_length(state.net_lobby_players); lp++) {
            if (state.net_lobby_players[lp].peer == cl.peer) { array_delete(state.net_lobby_players, lp, 1); break; }
        }
        network_host_reindex_lobby(state);
        network_broadcast_lobby(state);
        state.net_status_message = cl.name + " left the room.";
    }
}

function network_client_lost_host(state, reason) {
    var was_in_game = (state.screen == "game");
    network_cleanup_sockets(state);
    state.net_error_message = reason;
    state.net_error_timer = 300;
    state.modal = undefined;
    if (was_in_game) {
        game_reset_match(state);
    }
    network_start_browsing(state);
    game_play_sfx("error");
}

// -----------------------------------------------------------------------------
// HOST MESSAGE HANDLING
// -----------------------------------------------------------------------------
function network_host_on_message(state, sock, ip_from, msg) {
    var t = msg.type;

    // UDP traffic is ignored by the host (it only sends beacons)
    if (t == "room_beacon") return;

    var ci = network_host_find_client(state, sock);
    if (ci < 0) return;
    var cl = state.net_clients[ci];

    if (t == "join_request") {
        var proto = msg[$ "protocol"] ?? 0;
        if (proto != NET_PROTOCOL) {
            network_send_json(sock, { type: "join_reject", reason: "Version mismatch - make sure everyone runs the same build of the game." });
            return;
        }
        if (state.screen == "game") {
            network_send_json(sock, { type: "join_reject", reason: "That mission is already in progress." });
            return;
        }
        if (array_length(state.net_lobby_players) >= NET_MAX_PLAYERS) {
            network_send_json(sock, { type: "join_reject", reason: "That room is full (4/4)." });
            return;
        }
        var nm = string_copy(string_trim(string(msg[$ "username"] ?? "Operative")), 1, 14);
        if (nm == "") nm = "Operative";
        // Avoid duplicate callsigns so the squad can tell everyone apart
        var base_nm = nm; var dup_n = 2; var clash = true;
        while (clash) {
            clash = false;
            for (var lp = 0; lp < array_length(state.net_lobby_players); lp++) {
                if (string_lower(state.net_lobby_players[lp].name) == string_lower(nm)) { clash = true; break; }
            }
            if (clash) { nm = string_copy(base_nm, 1, 12) + string(dup_n); dup_n++; }
        }
        cl.joined = true;
        cl.name = nm;
        array_push(state.net_lobby_players, { name: nm, is_host: false, character_id: "default", p_idx: array_length(state.net_lobby_players), ip: ip_from, peer: cl.peer });
        network_send_json(sock, { type: "join_accept", peer: cl.peer, lobby: state.net_lobby_players, host_name: state.net_username });
        network_broadcast_lobby(state);
        state.net_status_message = nm + " joined the room.";
        game_play_sfx("join");
        return;
    }

    if (!cl.joined) return;

    if (t == "lobby_char") {
        if (state.screen != "online_lobby") return;
        var req_cid = string(msg[$ "character_id"] ?? "default");
        var my_lp = -1;
        for (var lp = 0; lp < array_length(state.net_lobby_players); lp++) if (state.net_lobby_players[lp].peer == cl.peer) my_lp = lp;
        if (my_lp >= 0 && network_class_available(state, req_cid, my_lp)) {
            state.net_lobby_players[my_lp].character_id = req_cid;
        }
        // Always answer with the authoritative roster (rejections snap the client back)
        network_broadcast_lobby(state);
        return;
    }

    if (t == "req") {
        if (state.screen != "game") return;
        if (cl.p_idx < 0 || cl.p_idx >= state.num_players) return;
        var a = string(msg[$ "a"] ?? "");
        var args = msg[$ "args"] ?? {};
        if (!is_struct(args)) args = {};
        game_execute_action(state, cl.p_idx, a, args);
        // Even a rejected request gets a fresh snapshot so the client UI stays truthful
        state.net_dirty = true;
        return;
    }
}

function network_class_available(state, cid, my_lp) {
    if (cid == "default") return true;
    var classes = game_get_character_classes();
    var exists = false;
    for (var c = 0; c < array_length(classes); c++) if (classes[c].id == cid) exists = true;
    if (!exists) return false;
    for (var lp = 0; lp < array_length(state.net_lobby_players); lp++) {
        if (lp != my_lp && state.net_lobby_players[lp].character_id == cid) return false;
    }
    return true;
}

// -----------------------------------------------------------------------------
// CLIENT MESSAGE HANDLING
// -----------------------------------------------------------------------------
function network_client_on_message(state, sock, ip_from, msg) {
    var t = msg.type;

    if (t == "room_beacon") {
        if (state.screen != "online_browser") return;
        var proto = msg[$ "protocol"] ?? 0;
        var found = false;
        for (var r = 0; r < array_length(state.net_discovered_rooms); r++) {
            var rm = state.net_discovered_rooms[r];
            if (rm.ip == ip_from && rm.port == msg.port) {
                rm.room_name = msg.room_name; rm.host_name = msg.host_name;
                rm.players = msg.players; rm.max_players = msg.max_players;
                rm.last_seen = current_time; rm.compatible = (proto == NET_PROTOCOL);
                found = true;
                break;
            }
        }
        if (!found) {
            array_push(state.net_discovered_rooms, {
                ip: ip_from, port: msg.port, room_name: msg.room_name, host_name: msg.host_name,
                players: msg.players, max_players: msg.max_players, last_seen: current_time, compatible: (proto == NET_PROTOCOL)
            });
            game_play_sfx("hover", 0.6);
        }
        return;
    }

    if (state.net_mode != "client" || sock != state.net_client_socket) return;

    switch (t) {
        case "join_accept":
            state.net_my_peer = msg.peer;
            state.net_lobby_players = msg.lobby;
            network_client_sync_my_index(state);
            state.net_status_message = "Connected to " + string(msg[$ "host_name"] ?? "host") + "'s room.";
            game_play_sfx("join");
            break;
        case "join_reject":
            network_client_lost_host(state, msg[$ "reason"] ?? "The host rejected the connection.");
            break;
        case "room_closed":
            network_client_lost_host(state, msg[$ "reason"] ?? "The host closed the room.");
            break;
        case "lobby":
            state.net_lobby_players = msg.lobby;
            network_client_sync_my_index(state);
            break;
        case "start":
            state.net_lobby_players = msg.lobby;
            network_client_sync_my_index(state);
            game_reset_match(state);
            state.net_last_log_seen = -1;
            state.net_last_popup_seen = -1;
            net_snapshot_apply(state, msg.snap);
            ui_transition_to(state, "game");
            state.modal = undefined;
            game_play_sfx("wave");
            break;
        case "snap":
            if (state.screen == "game") {
                state.net_pending_requests = 0;
                net_snapshot_apply(state, msg);
                var fx = msg[$ "fx"];
                if (is_array(fx)) {
                    for (var i = 0; i < array_length(fx); i++) game_fx_apply(state, fx[i]);
                }
            }
            break;
        case "notice":
            state.toast_message = string(msg[$ "text"] ?? "");
            state.toast_timer = 150;
            state.toast_is_error = true;
            game_play_sfx("error");
            break;
        case "return_lobby":
            state.net_lobby_players = msg.lobby;
            network_client_sync_my_index(state);
            state.modal = undefined;
            game_reset_match(state);
            ui_transition_to(state, "online_lobby");
            break;
    }
}

function network_client_sync_my_index(state) {
    for (var lp = 0; lp < array_length(state.net_lobby_players); lp++) {
        if (state.net_lobby_players[lp].peer == state.net_my_peer) {
            state.net_my_player_idx = lp;
            return;
        }
    }
}

// =============================================================================
// LOBBY ACTIONS
// =============================================================================
function network_lobby_change_character(state, new_char_id) {
    var my_idx = state.net_my_player_idx;
    if (state.is_host) {
        if (my_idx >= 0 && my_idx < array_length(state.net_lobby_players) && network_class_available(state, new_char_id, my_idx)) {
            state.net_lobby_players[my_idx].character_id = new_char_id;
            network_broadcast_lobby(state);
        }
    } else {
        // Optimistic local update; the host's roster reply is authoritative
        if (my_idx >= 0 && my_idx < array_length(state.net_lobby_players)) {
            state.net_lobby_players[my_idx].character_id = new_char_id;
        }
        network_send_json(state.net_client_socket, { type: "lobby_char", character_id: new_char_id });
    }
}

/// @desc Host launches the mission (2-4 operatives)
function network_host_start_mission(state) {
    if (!state.is_host) return false;
    var p_count = array_length(state.net_lobby_players);
    if (p_count < 2) {
        state.net_error_message = "At least 2 operatives are needed to launch an online mission.";
        state.net_error_timer = 180;
        return false;
    }

    // Fresh match, roster taken from the lobby
    game_reset_match(state);
    var char_classes = game_get_character_classes();
    state.setup_player_count = p_count;
    state.setup_player_names = [];
    state.setup_player_classes = [];
    for (var p = 0; p < p_count; p++) {
        var pl = state.net_lobby_players[p];
        array_push(state.setup_player_names, pl.name);
        var c_idx = 0;
        for (var ci = 0; ci < array_length(char_classes); ci++) if (char_classes[ci].id == pl.character_id) { c_idx = ci; break; }
        array_push(state.setup_player_classes, c_idx);
        // Bind each connected socket to its operative index for the whole mission
        for (var c = 0; c < array_length(state.net_clients); c++) {
            if (state.net_clients[c].peer == pl.peer) state.net_clients[c].p_idx = p;
        }
    }
    game_apply_setup_roster(state);
    state.storage.gold = game_starting_gold(p_count);
    state.net_my_player_idx = 0;
    game_log(state, "Strike team deployed over the local network (" + string(p_count) + " operatives). Good luck!");

    var snap = net_snapshot_build(state, true);
    network_broadcast_to_all_clients(state, { type: "start", lobby: state.net_lobby_players, snap: snap });
    state.net_last_log_sent = state.log_counter;
    state.net_fx_queue = [];

    ui_transition_to(state, "game");
    state.modal = undefined;
    game_play_sfx("wave");
    return true;
}

/// @desc Host sends everyone back to the lobby after a match ends
function network_host_return_to_lobby(state) {
    if (!state.is_host) return;
    game_reset_match(state);
    state.modal = undefined;
    network_broadcast_to_all_clients(state, { type: "return_lobby", lobby: state.net_lobby_players });
    ui_transition_to(state, "online_lobby");
}

// =============================================================================
// SNAPSHOTS
// =============================================================================
function net_weapon_index(state, w) {
    if (is_undefined(w)) return -1;
    for (var i = 0; i < array_length(state.weapons); i++) if (state.weapons[i] == w) return i;
    return -1;
}

/// @desc Serializes every piece of gameplay state the clients need to render the match
function net_snapshot_build(state, include_logs) {
    var players = [];
    for (var p = 0; p < state.num_players; p++) {
        var pl = state.players[p];
        array_push(players, {
            id: pl.id, name: pl.name, character_idx: pl.character_idx, color: pl.color,
            energy: pl.energy, max_energy: pl.max_energy, energy_penalty: pl.energy_penalty,
            node: pl.node, ended_turn: pl.ended_turn, backpack: pl.backpack,
            disconnected: pl[$ "disconnected"] ?? false
        });
    }
    var towers = [];
    for (var t = 0; t < 4; t++) {
        var tw = state.towers[t];
        array_push(towers, { hp: tw.hp, max_hp: tw.max_hp, alive: tw.alive, rebuilt: tw[$ "rebuilt"] ?? false, manual_cooldown: tw.manual_cooldown, manual_powers_this_turn: tw.manual_powers_this_turn, w: net_weapon_index(state, tw.weapon) });
    }
    var pproj = [];
    for (var i = 0; i < array_length(state.combat_player_projectiles); i++) {
        var pp = state.combat_player_projectiles[i];
        array_push(pproj, { tower_idx: pp.tower_idx, target_idx: pp.target_idx, target_uid: pp.target_uid, damage: pp.damage, progress: pp.progress, speed: pp.speed, catalog_id: pp.catalog_id });
    }
    var aproj = [];
    for (var i = 0; i < array_length(state.combat_projectiles); i++) {
        var pr = state.combat_projectiles[i];
        array_push(aproj, { alien_idx: pr.alien_idx, target_tower_idx: pr.target_tower_idx, damage: pr.damage, progress: pr.progress, speed: pr.speed, is_acid_spitter: pr.is_acid_spitter, skips_weapon: pr.skips_weapon, alien_catalog_id: pr.alien.catalog_id });
    }
    state.net_snap_seq += 1;
    var snap = {
        seq: state.net_snap_seq,
        round_number: state.round_number,
        phase: state.phase,
        endless_mode: state.endless_mode,
        num_players: state.num_players,
        players: players,
        towers: towers,
        weapons: state.weapons,
        storage: state.storage,
        blueprints: state.blueprints,
        shop_items: state.shop_available_items,
        shop_deck_count: array_length(state.shop_deck),
        shop_reroll_cost: state.shop_reroll_cost,
        days_without_reroll: state.days_without_reroll,
        rerolled_this_day: state.rerolled_this_day,
        active_town_favor: state.active_town_favor,
        spawn_zone: state.spawn_zone,
        active_zone: state.active_zone,
        log_counter: state.log_counter,
        popup: { seq: state.popup_seq, title: state.turn_popup_title, msg: state.turn_popup_message, color: state.turn_popup_color, timer: state.turn_popup_timer },
        combat: {
            subphase: state.combat_subphase,
            reason: state.combat_concluded_reason,
            speed_2x: state.combat_speed_2x,
            shots: state.tower_weapon_shots,
            max_shots: state.tower_weapon_max_shots,
            used: state.tower_weapon_used,
            selected: state.combat_selected_tower,
            volley_tower: is_undefined(state[$ "volley"]) ? -1 : state.volley.tower,
            pproj: pproj,
            aproj: aproj
        }
    };
    if (include_logs) {
        var n = min(80, array_length(state.action_logs));
        var logs = array_create(n);
        array_copy(logs, 0, state.action_logs, 0, n);
        snap.logs = logs;
    }
    return snap;
}

/// @desc Client: replaces local gameplay state with the host's snapshot while preserving local animation state
function net_snapshot_apply(state, snap) {
    var classes = game_get_character_classes();
    state.round_number = snap.round_number;
    state.phase = snap.phase;
    state.endless_mode = snap.endless_mode;

    // Players (keep pawn animation fields; animate moves that happened on the host)
    var np = snap.num_players;
    if (array_length(state.players) != np) {
        state.setup_player_count = np;
        state.setup_player_names = [];
        state.setup_player_classes = [];
        for (var p = 0; p < np; p++) {
            array_push(state.setup_player_names, snap.players[p].name);
            array_push(state.setup_player_classes, snap.players[p].character_idx);
        }
        game_apply_setup_roster(state);
    }
    state.num_players = np;
    for (var p = 0; p < np; p++) {
        var sp = snap.players[p];
        var pl = state.players[p];
        var old_node = pl.node;
        pl.name = sp.name;
        pl.character_idx = sp.character_idx;
        pl.character = classes[sp.character_idx % array_length(classes)];
        pl.color = sp.color;
        pl.energy = sp.energy;
        pl.max_energy = sp.max_energy;
        pl.energy_penalty = sp.energy_penalty;
        pl.ended_turn = sp.ended_turn;
        pl.backpack = sp.backpack;
        pl.disconnected = sp.disconnected;
        if (sp.node != old_node && variable_struct_exists(state.nodes, sp.node)) {
            pl.node = sp.node;
            game_player_anim_move(state, pl, old_node, sp.node);
        }
    }

    // Weapons & towers (tower.weapon must reference the same struct as in state.weapons)
    state.weapons = snap.weapons;
    for (var t = 0; t < 4; t++) {
        var st = snap.towers[t];
        var tw = state.towers[t];
        tw.hp = st.hp; tw.max_hp = st.max_hp; tw.alive = st.alive; tw.rebuilt = st[$ "rebuilt"] ?? false;
        tw.manual_cooldown = st.manual_cooldown; tw.manual_powers_this_turn = st.manual_powers_this_turn;
        tw.weapon = (st.w >= 0 && st.w < array_length(state.weapons)) ? state.weapons[st.w] : undefined;
    }

    state.storage = snap.storage;
    state.blueprints = snap.blueprints;
    state.shop_available_items = snap.shop_items;
    for (var i = 0; i < array_length(state.shop_available_items); i++) {
        if (!is_struct(state.shop_available_items[i])) state.shop_available_items[i] = undefined;
    }
    state.shop_deck = array_create(snap.shop_deck_count, 0);
    state.shop_reroll_cost = snap.shop_reroll_cost;
    state.days_without_reroll = snap.days_without_reroll;
    state.rerolled_this_day = snap.rerolled_this_day;
    state.active_town_favor = snap.active_town_favor;

    // Aliens: keep per-alien visual flash timers across snapshots
    var flashes = {};
    for (var a = 0; a < array_length(state.active_zone); a++) {
        var al = state.active_zone[a];
        if ((al[$ "flash"] ?? 0) > 0) flashes[$ string(al.uid)] = al.flash;
    }
    state.spawn_zone = snap.spawn_zone;
    state.active_zone = snap.active_zone;
    for (var a = 0; a < array_length(state.active_zone); a++) {
        var fl = flashes[$ string(state.active_zone[a].uid)];
        if (!is_undefined(fl)) state.active_zone[a].flash = fl;
    }

    // Logs & toast for new entries
    if (variable_struct_exists(snap, "logs")) {
        state.action_logs = snap.logs;
        state.action_log_cache_dirty = true;
    }
    if (snap.log_counter != state.net_last_log_seen) {
        if (state.net_last_log_seen >= 0 && array_length(state.action_logs) > 0) {
            state.toast_message = state.action_logs[0];
            state.toast_timer = 180;
            state.toast_is_error = false;
        }
        state.net_last_log_seen = snap.log_counter;
        state.log_counter = snap.log_counter;
    }

    // Turn popup / banner
    var pop = snap.popup;
    if (pop.seq != state.net_last_popup_seen) {
        if (state.net_last_popup_seen >= 0 || pop.timer > 0) {
            state.turn_popup_title = pop.title;
            state.turn_popup_message = pop.msg;
            state.turn_popup_color = pop.color;
            state.turn_popup_timer = pop.timer;
        }
        state.net_last_popup_seen = pop.seq;
        state.popup_seq = pop.seq;
    }

    // Combat
    var cb = snap.combat;
    state.combat_subphase = cb.subphase;
    state.combat_concluded_reason = cb.reason;
    state.combat_speed_2x = cb.speed_2x;
    state.tower_weapon_shots = cb.shots;
    state.tower_weapon_max_shots = cb.max_shots;
    state.tower_weapon_used = cb.used;
    state.combat_selected_tower = cb.selected;
    var vt_snap = cb[$ "volley_tower"] ?? -1;
    state.volley = (vt_snap >= 0) ? { tower: vt_snap } : undefined;
    state.combat_player_projectiles = cb.pproj;
    // Rebuild alien projectiles with a lightweight alien stub for rendering
    state.combat_projectiles = [];
    for (var i = 0; i < array_length(cb.aproj); i++) {
        var pr = cb.aproj[i];
        pr.alien = { catalog_id: pr.alien_catalog_id, name: "", uid: -1 };
        array_push(state.combat_projectiles, pr);
    }

    // Modals follow the authoritative phase
    var in_combat = (state.phase == "combat_weapons" || state.phase == "combat_aliens");
    if (state.phase == "game_over") {
        if (is_undefined(state.modal) || state.modal.type != "game_over") state.modal = { type: "game_over" };
    } else if (state.phase == "victory") {
        if (is_undefined(state.modal) || state.modal.type != "victory") state.modal = { type: "victory" };
    } else if (in_combat) {
        if (is_undefined(state.modal) || (state.modal.type != "tactical_combat" && state.modal.type != "settings" && state.modal.type != "pause" && state.modal.type != "help")) {
            state.modal = { type: "tactical_combat" };
        }
    } else if (!is_undefined(state.modal) && (state.modal.type == "tactical_combat" || state.modal.type == "game_over" || state.modal.type == "victory")) {
        state.modal = undefined;
    }
}
