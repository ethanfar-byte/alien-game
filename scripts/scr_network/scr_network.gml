/// @desc Network manager for Local WiFi Multiplayer
// Handles LAN discovery via UDP beacons, TCP lobby rooms, and turn/action sync

#macro NET_PORT_TCP 6510
#macro NET_PORT_UDP 6511

function network_init_manager(state) {
    state.net_username = "Operative" + string(irandom_range(100, 999));
    state.net_mode = "none"; // "none" | "host" | "client"
    state.net_server_socket = -1;
    state.net_client_socket = -1;
    state.net_udp_listener = -1;
    state.net_udp_broadcaster = -1;
    state.net_clients = [];          // Host only: [ { socket, username, character_id, p_idx } ]
    state.net_lobby_players = [];    // Room roster: [ { name, is_host, character_id, p_idx, ip } ]
    state.net_discovered_rooms = []; // Browser: [ { ip, port, room_name, host_name, players, max_players, last_seen } ]
    state.net_my_player_idx = 0;
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
}

/// @desc Cleans up all networking sockets safely
function network_cleanup_sockets(state) {
    if (state.net_server_socket >= 0) {
        network_destroy(state.net_server_socket);
        state.net_server_socket = -1;
    }
    if (state.net_client_socket >= 0) {
        network_destroy(state.net_client_socket);
        state.net_client_socket = -1;
    }
    if (state.net_udp_listener >= 0) {
        network_destroy(state.net_udp_listener);
        state.net_udp_listener = -1;
    }
    if (state.net_udp_broadcaster >= 0) {
        network_destroy(state.net_udp_broadcaster);
        state.net_udp_broadcaster = -1;
    }
    state.net_clients = [];
    state.net_mode = "none";
    state.is_online = false;
    state.is_host = false;
}

/// @desc Starts hosting a public room on local WiFi
function network_start_hosting(state) {
    network_cleanup_sockets(state);
    
    // Create TCP Server for game & lobby (up to 4 clients)
    state.net_server_socket = network_create_server(network_socket_tcp, NET_PORT_TCP, 4);
    if (state.net_server_socket < 0) {
        state.net_error_message = "Failed to bind TCP port " + string(NET_PORT_TCP) + ". Is another instance hosting?";
        state.net_error_timer = 180;
        return false;
    }
    
    // Create UDP broadcaster socket for LAN room discovery
    state.net_udp_broadcaster = network_create_socket(network_socket_udp);
    
    state.net_mode = "host";
    state.is_online = true;
    state.is_host = true;
    state.net_my_player_idx = 0;
    
    // Initialize lobby players list with Host as Player 1
    state.net_lobby_players = [
        {
            name: state.net_username,
            is_host: true,
            character_id: "default",
            p_idx: 0,
            ip: "127.0.0.1"
        }
    ];
    
    state.net_broadcast_timer = 0;
    state.screen = "online_lobby";
    game_play_sfx("click");
    return true;
}

/// @desc Starts browsing for rooms on local WiFi via UDP beacon listener
function network_start_browsing(state) {
    network_cleanup_sockets(state);
    
    state.net_discovered_rooms = [];
    // Listen for room beacons on UDP port
    state.net_udp_listener = network_create_server(network_socket_udp, NET_PORT_UDP, 10);
    
    // Also create UDP socket to send discovery ping probe across the subnet
    state.net_udp_broadcaster = network_create_socket(network_socket_udp);
    network_broadcast_udp(state.net_udp_broadcaster, NET_PORT_UDP, { type: "room_ping" });
    
    state.screen = "online_browser";
    state.net_status_message = "Scanning local Wi-Fi subnet for rooms...";
    game_play_sfx("click");
    return true;
}

/// @desc Connects client socket to host at IP address
function network_connect_to_room(state, target_ip, target_port = NET_PORT_TCP) {
    network_cleanup_sockets(state);
    
    state.net_client_socket = network_create_socket(network_socket_tcp);
    if (state.net_client_socket < 0) {
        state.net_error_message = "Failed to create network socket.";
        state.net_error_timer = 180;
        return false;
    }
    
    var res = network_connect(state.net_client_socket, target_ip, target_port);
    if (res < 0) {
        state.net_error_message = "Could not connect to host at " + target_ip + ":" + string(target_port);
        state.net_error_timer = 180;
        network_cleanup_sockets(state);
        return false;
    }
    
    state.net_mode = "client";
    state.is_online = true;
    state.is_host = false;
    state.net_status_message = "Connecting to host...";
    
    // Send join request packet
    network_send_json(state.net_client_socket, {
        type: "join_request",
        username: state.net_username,
        character_id: "default"
    });
    
    state.screen = "online_lobby";
    game_play_sfx("click");
    return true;
}

/// @desc Sends a JSON struct over a given TCP socket
function network_send_json(sock, struct_data) {
    if (sock < 0) return false;
    var json_str = json_stringify(struct_data);
    var buf = buffer_create(string_byte_length(json_str) + 4, buffer_grow, 1);
    buffer_write(buf, buffer_string, json_str);
    var res = network_send_packet(sock, buf, buffer_tell(buf));
    buffer_delete(buf);
    return (res >= 0);
}

/// @desc Sends a JSON broadcast packet over UDP
function network_broadcast_udp(sock, port, struct_data) {
    if (sock < 0) return false;
    var json_str = json_stringify(struct_data);
    var buf = buffer_create(string_byte_length(json_str) + 4, buffer_grow, 1);
    buffer_write(buf, buffer_string, json_str);
    network_send_broadcast(sock, port, buf, buffer_tell(buf));
    buffer_delete(buf);
    return true;
}

/// @desc Broadcasts a JSON message from host to all connected clients
function network_broadcast_to_all_clients(state, struct_data, exclude_socket = -1) {
    if (!state.is_host) return;
    for (var i = 0; i < array_length(state.net_clients); i++) {
        var cl = state.net_clients[i];
        if (cl.socket != exclude_socket && cl.socket >= 0) {
            network_send_json(cl.socket, struct_data);
        }
    }
}

/// @desc Broadcasts an in-game action across the local WiFi
function network_broadcast_action(state, action_type, payload = {}) {
    if (!state.is_online) return;
    
    var msg = {
        type: action_type,
        sender_idx: state.net_my_player_idx,
        payload: payload
    };
    
    if (state.is_host) {
        // Host broadcasts to all clients
        network_broadcast_to_all_clients(state, msg);
    } else {
        // Client sends to host
        network_send_json(state.net_client_socket, msg);
    }
}

/// @desc Step event updates for network beacon broadcasting and discovery pruning
function network_step_update(state) {
    // Error notification timer
    if (variable_struct_exists(state, "net_error_timer") && state.net_error_timer > 0) {
        state.net_error_timer--;
    }
    
    // Host: broadcast UDP room beacon every 45 frames (~0.75s) while in lobby
    if (state.net_mode == "host" && state.screen == "online_lobby") {
        state.net_broadcast_timer++;
        if (state.net_broadcast_timer >= 45) {
            state.net_broadcast_timer = 0;
            if (state.net_udp_broadcaster >= 0) {
                var p_count = array_length(state.net_lobby_players);
                network_broadcast_udp(state.net_udp_broadcaster, NET_PORT_UDP, {
                    type: "room_beacon",
                    room_name: state.net_username + "'s Defense Outpost",
                    host_name: state.net_username,
                    players: p_count,
                    max_players: 4,
                    port: NET_PORT_TCP
                });
            }
        }
    }
    
    // Browser: prune discovered rooms that haven't beaconed for > 6 seconds
    if (state.screen == "online_browser") {
        var now = current_time;
        for (var r = array_length(state.net_discovered_rooms) - 1; r >= 0; r--) {
            if (now - state.net_discovered_rooms[r].last_seen > 6000) {
                array_delete(state.net_discovered_rooms, r, 1);
            }
        }
    }
}

/// @desc Handles all async networking events from obj_game Other_68 event
function network_handle_async(state, load_map) {
    var net_type = load_map[? "type"];
    var sock_id = load_map[? "id"];
    var ip_from = load_map[? "ip"] ?? "127.0.0.1";
    var port_from = load_map[? "port"] ?? NET_PORT_TCP;
    
    switch (net_type) {
        // -------------------------------------------------------------
        // CLIENT CONNECTED TO HOST
        // -------------------------------------------------------------
        case network_type_connect: {
            if (state.is_host) {
                var new_socket = load_map[? "socket"];
                // If room is already full (max 4 players), reject
                if (array_length(state.net_lobby_players) >= 4 || state.screen == "game") {
                    network_send_json(new_socket, {
                        type: "join_reject",
                        reason: (state.screen == "game") ? "Game is already in progress" : "Room is full (4/4 players)"
                    });
                    return;
                }
                
                // Track connected client socket
                array_push(state.net_clients, {
                    socket: new_socket,
                    username: "Operative",
                    character_id: "default",
                    p_idx: array_length(state.net_lobby_players)
                });
            }
            break;
        }
        
        // -------------------------------------------------------------
        // CLIENT DISCONNECTED
        // -------------------------------------------------------------
        case network_type_disconnect: {
            var dis_socket = load_map[? "socket"];
            if (state.is_host) {
                // Find and remove client
                var rem_idx = -1;
                for (var c = 0; c < array_length(state.net_clients); c++) {
                    if (state.net_clients[c].socket == dis_socket) {
                        rem_idx = c;
                        break;
                    }
                }
                if (rem_idx >= 0) {
                    var p_rem_idx = state.net_clients[rem_idx].p_idx;
                    array_delete(state.net_clients, rem_idx, 1);
                    
                    // Remove from lobby roster
                    for (var lp = 0; lp < array_length(state.net_lobby_players); lp++) {
                        if (state.net_lobby_players[lp].p_idx == p_rem_idx) {
                            array_delete(state.net_lobby_players, lp, 1);
                            break;
                        }
                    }
                    // Re-index remaining players
                    for (var lp = 0; lp < array_length(state.net_lobby_players); lp++) {
                        state.net_lobby_players[lp].p_idx = lp;
                    }
                    for (var c = 0; c < array_length(state.net_clients); c++) {
                        state.net_clients[c].p_idx = c + 1;
                    }
                    
                    // Broadcast updated lobby roster
                    network_broadcast_to_all_clients(state, {
                        type: "lobby_update",
                        lobby_players: state.net_lobby_players
                    });
                }
            } else if (state.net_mode == "client" && sock_id == state.net_client_socket) {
                // Disconnected from host
                state.net_error_message = "Disconnected from host.";
                state.net_error_timer = 180;
                network_cleanup_sockets(state);
                state.screen = "online_browser";
            }
            break;
        }
        
        // -------------------------------------------------------------
        // DATA PACKET RECEIVED
        // -------------------------------------------------------------
        case network_type_data: {
            var buf = load_map[? "buffer"];
            if (is_undefined(buf)) return;
            
            buffer_seek(buf, buffer_seek_start, 0);
            var raw_str = buffer_read(buf, buffer_string);
            
            var msg = undefined;
            try {
                msg = json_parse(raw_str);
            } catch (e) {
                return;
            }
            if (is_undefined(msg) || !variable_struct_exists(msg, "type")) return;
            
            var m_type = msg.type;
            
            // 1. UDP LAN Room Discovery
            if (m_type == "room_beacon") {
                if (state.screen == "online_browser") {
                    var found = false;
                    for (var r = 0; r < array_length(state.net_discovered_rooms); r++) {
                        var rm = state.net_discovered_rooms[r];
                        if (rm.ip == ip_from && rm.port == msg.port) {
                            rm.room_name = msg.room_name;
                            rm.host_name = msg.host_name;
                            rm.players = msg.players;
                            rm.max_players = msg.max_players;
                            rm.last_seen = current_time;
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        array_push(state.net_discovered_rooms, {
                            ip: ip_from,
                            port: msg.port,
                            room_name: msg.room_name,
                            host_name: msg.host_name,
                            players: msg.players,
                            max_players: msg.max_players,
                            last_seen: current_time
                        });
                    }
                }
            }
            else if (m_type == "room_ping") {
                // Another machine is searching for rooms; respond if we are hosting
                if (state.net_mode == "host" && state.screen == "online_lobby" && state.net_udp_broadcaster >= 0) {
                    network_broadcast_udp(state.net_udp_broadcaster, NET_PORT_UDP, {
                        type: "room_beacon",
                        room_name: state.net_username + "'s Defense Outpost",
                        host_name: state.net_username,
                        players: array_length(state.net_lobby_players),
                        max_players: 4,
                        port: NET_PORT_TCP
                    });
                }
            }
            
            // 2. Client Join Request (Received by Host)
            else if (m_type == "join_request") {
                if (state.is_host) {
                    var assigned_idx = array_length(state.net_lobby_players);
                    if (assigned_idx >= 4) {
                        network_send_json(sock_id, { type: "join_reject", reason: "Room is full (4/4 players)" });
                        return;
                    }
                    
                    var new_player = {
                        name: msg.username,
                        is_host: false,
                        character_id: msg.character_id ?? "default",
                        p_idx: assigned_idx,
                        ip: ip_from
                    };
                    array_push(state.net_lobby_players, new_player);
                    
                    // Update client record
                    for (var c = 0; c < array_length(state.net_clients); c++) {
                        if (state.net_clients[c].socket == sock_id) {
                            state.net_clients[c].username = msg.username;
                            state.net_clients[c].character_id = msg.character_id ?? "default";
                            state.net_clients[c].p_idx = assigned_idx;
                            break;
                        }
                    }
                    
                    // Send accept to joining client
                    network_send_json(sock_id, {
                        type: "join_accept",
                        your_idx: assigned_idx,
                        lobby_players: state.net_lobby_players
                    });
                    
                    // Broadcast updated lobby to all clients
                    network_broadcast_to_all_clients(state, {
                        type: "lobby_update",
                        lobby_players: state.net_lobby_players
                    });
                    
                    game_play_sfx("click");
                }
            }
            
            // 3. Join Accept (Received by Client)
            else if (m_type == "join_accept") {
                if (!state.is_host) {
                    state.net_my_player_idx = msg.your_idx;
                    state.net_lobby_players = msg.lobby_players;
                    state.screen = "online_lobby";
                    state.net_status_message = "Connected to room!";
                    game_play_sfx("click");
                }
            }
            
            // 4. Join Reject (Received by Client)
            else if (m_type == "join_reject") {
                state.net_error_message = msg.reason ?? "Join rejected by host.";
                state.net_error_timer = 180;
                network_cleanup_sockets(state);
                state.screen = "online_browser";
                game_play_sfx("error");
            }
            
            // 5. Lobby Roster Update
            else if (m_type == "lobby_update") {
                state.net_lobby_players = msg.lobby_players;
            }
            
            // 6. Character / Role Selection Changed in Lobby (No duplicates for non-default)
            else if (m_type == "update_character") {
                if (state.is_host) {
                    var sender_idx = msg.sender_idx;
                    var req_cid = msg.character_id;
                    if (sender_idx >= 0 && sender_idx < array_length(state.net_lobby_players)) {
                        var taken = false;
                        if (req_cid != "default") {
                            for (var op = 0; op < array_length(state.net_lobby_players); op++) {
                                if (op != sender_idx && state.net_lobby_players[op].character_id == req_cid) {
                                    taken = true;
                                    break;
                                }
                            }
                        }
                        if (!taken) {
                            state.net_lobby_players[sender_idx].character_id = req_cid;
                            network_broadcast_to_all_clients(state, {
                                type: "lobby_update",
                                lobby_players: state.net_lobby_players
                            });
                        }
                    }
                }
            }
            
            // 7. Host Launched Mission (Start Game)
            else if (m_type == "start_mission") {
                var p_count = array_length(msg.lobby_players);
                // Reconfigure local game state for multiplayer session
                state.setup_player_count = p_count;
                state.setup_player_names = [];
                state.setup_player_classes = [];
                
                var char_classes = game_get_character_classes();
                for (var p = 0; p < p_count; p++) {
                    var pl = msg.lobby_players[p];
                    array_push(state.setup_player_names, pl.name);
                    
                    // Match character class index
                    var c_idx = 0;
                    for (var ci = 0; ci < array_length(char_classes); ci++) {
                        if (char_classes[ci].id == pl.character_id) { c_idx = ci; break; }
                    }
                    array_push(state.setup_player_classes, c_idx);
                }
                
                game_apply_setup_roster(state);
                state.screen = "game";
                state.modal = undefined;
                game_play_sfx("click");
                game_log(state, "Cooperative strike team deployed via Wi-Fi Network! (" + string(p_count) + " Operatives)");
            }
            
            // -------------------------------------------------------------
            // IN-GAME ACTION SYNCHRONIZATION
            // -------------------------------------------------------------
            else if (string_pos("action_", m_type) == 1) {
                // If host received action from client, apply and relay to other clients
                if (state.is_host) {
                    network_broadcast_to_all_clients(state, msg, sock_id);
                }
                
                network_execute_remote_action(state, msg);
            }
            
            break;
        }
    }
}

/// @desc Executes an action received from the local WiFi network
function network_execute_remote_action(state, msg) {
    var a_type = msg.type;
    var p_idx = msg.sender_idx;
    var pld = msg.payload;
    
    // Only apply if in-game
    if (state.screen != "game") return;
    
    if (a_type == "action_move") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            game_player_move(state, state.players[p_idx], pld.node);
        }
    }
    else if (a_type == "action_gather") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            game_player_gather(state, state.players[p_idx]);
        }
    }
    else if (a_type == "action_craft") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            game_player_craft_blueprint(state, state.players[p_idx], pld.bp_idx, pld.target_tower);
        }
    }
    else if (a_type == "action_trade") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            game_player_town_trade(state, state.players[p_idx], pld.resource, pld.count);
        }
    }
    else if (a_type == "action_repair_tower") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            game_player_repair_tower(state, state.players[p_idx], pld.tower_idx, pld.method);
        }
    }
    else if (a_type == "action_repair_weapon") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            game_player_repair_weapon(state, state.players[p_idx], pld.tower_idx, "recipe_resource", pld.res_choice);
        }
    }
    else if (a_type == "action_shop_buy") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            game_player_buy_blueprint(state, state.players[p_idx], pld.item_idx);
        }
    }
    else if (a_type == "action_shop_reroll") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            game_reroll_shop(state, state.players[p_idx], false);
        }
    }
    else if (a_type == "action_end_turn") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            state.players[p_idx].ended_turn = true;
            state.players[p_idx].energy = 0;
            game_log(state, state.players[p_idx].name + " ended their turn.");
            if (game_check_all_players_ready(state)) {
                state.phase = "combat_weapons";
                game_start_weapons_attack_phase(state);
            }
        }
    }
    else if (a_type == "action_fire_weapon") {
        state.combat_selected_tower = pld.tower_idx;
        game_combat_fire_tower_at_alien(state, pld.target_idx);
    }
    else if (a_type == "action_conclude_combat") {
        state.modal = undefined;
        if (state.phase != "game_over") {
            game_advance_wave_phase(state);
        }
    }
    else if (a_type == "action_chat") {
        var chat_str = "[CHAT] " + string(pld.sender) + ": " + string(pld.text);
        game_log(state, chat_str);
        game_play_sfx("coin");
    }
    else if (a_type == "action_player_turn_done") {
        if (p_idx >= 0 && p_idx < state.num_players) {
            state.players[p_idx].ended_turn = true;
            game_log(state, state.players[p_idx].name + " is ready for defense phase.");
            if (game_check_all_players_ready(state)) {
                state.phase = "combat_weapons";
                game_start_weapons_attack_phase(state);
            }
        }
    }
}

/// @desc Changes character selection for local player in online lobby
function network_lobby_change_character(state, new_char_id) {
    var my_idx = state.net_my_player_idx;
    if (my_idx >= 0 && my_idx < array_length(state.net_lobby_players)) {
        state.net_lobby_players[my_idx].character_id = new_char_id;
    }
    
    if (state.is_host) {
        // Broadcast updated lobby to all clients
        network_broadcast_to_all_clients(state, {
            type: "lobby_update",
            lobby_players: state.net_lobby_players
        });
    } else {
        // Send to host
        network_send_json(state.net_client_socket, {
            type: "update_character",
            sender_idx: my_idx,
            character_id: new_char_id
        });
    }
}

/// @desc Host triggers game start once at least 1 other player has joined (2-4 players)
function network_host_start_mission(state) {
    if (!state.is_host) return false;
    var p_count = array_length(state.net_lobby_players);
    if (p_count < 2) {
        state.net_error_message = "Minimum 2 players required to launch mission.";
        state.net_error_timer = 180;
        return false;
    }
    
    // Broadcast start_mission packet with full roster
    var msg = {
        type: "start_mission",
        lobby_players: state.net_lobby_players
    };
    network_broadcast_to_all_clients(state, msg);
    
    // Setup local game
    state.setup_player_count = p_count;
    state.setup_player_names = [];
    state.setup_player_classes = [];
    
    var char_classes = game_get_character_classes();
    for (var p = 0; p < p_count; p++) {
        var pl = state.net_lobby_players[p];
        array_push(state.setup_player_names, pl.name);
        
        var c_idx = 0;
        for (var ci = 0; ci < array_length(char_classes); ci++) {
            if (char_classes[ci].id == pl.character_id) { c_idx = ci; break; }
        }
        array_push(state.setup_player_classes, c_idx);
    }
    
    game_apply_setup_roster(state);
    state.screen = "game";
    state.modal = undefined;
    game_play_sfx("click");
    game_log(state, "Cooperative strike team deployed via Wi-Fi Network! (" + string(p_count) + " Operatives)");
    return true;
}
