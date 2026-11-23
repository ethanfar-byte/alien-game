/// @desc Automated balance playtester.
/// A heuristic bot plays complete local games using the real game rules (game_execute_action,
/// the real combat functions and wave advance). Animations, particles and sound are skipped
/// so a full 20-day campaign resolves in a few milliseconds.
/// Run with:  -autotest balance   (results in %LOCALAPPDATA%\Alien_Game\autotest\balance.log)

global.sim_mode = false;
global.sim_trace = false;

function sim_active() {
    return variable_global_exists("sim_mode") && global.sim_mode;
}

// -----------------------------------------------------------------------------
// MAP HELPERS
// -----------------------------------------------------------------------------
/// @desc [next_node, distance] along the shortest path, or ["", 999]
function sim_path(st, from, to) {
    if (from == to) return [from, 0];
    var prev = {};
    prev[$ from] = "";
    var queue = [from];
    var qi = 0;
    while (qi < array_length(queue)) {
        var cur = queue[qi++];
        if (cur == to) break;
        for (var i = 0; i < array_length(st.edges); i++) {
            var e = st.edges[i];
            var nb = (e[0] == cur) ? e[1] : ((e[1] == cur) ? e[0] : "");
            if (nb != "" && !variable_struct_exists(prev, nb)) { prev[$ nb] = cur; array_push(queue, nb); }
        }
    }
    if (!variable_struct_exists(prev, to)) return ["", 999];
    var dist = 0;
    var node = to;
    var step = to;
    while (prev[$ node] != "") { step = node; node = prev[$ node]; dist++; }
    return [step, dist];
}

/// @desc Move toward target, or perform act when already there. undefined if out of energy.
function sim_go(st, pl, target, act, act_cost) {
    if (pl.node == target) return (pl.energy >= act_cost) ? act : undefined;
    var p = sim_path(st, pl.node, target);
    if (p[0] == "" || pl.energy < game_player_get_move_cost(pl)) return undefined;
    return { a: "move", args: { node: p[0] } };
}

// Expected units per card by gather node (from the deck compositions)
function sim_node_yield() {
    static Y = {
        forest: { wood: 1.6, scrap: 0.33 },
        cave_1: { stone: 1.4, metal: 0.16, crystals: 0.12, power_gem: 0.04 },
        cave_2: { stone: 0.37, metal: 1.05, crystals: 0.15, power_gem: 0.08 },
        cave_3: { stone: 0.04, metal: 0.24, crystals: 1.27, power_gem: 0.12 }
    };
    return Y;
}

// -----------------------------------------------------------------------------
// TEAM PLANNING
// -----------------------------------------------------------------------------
function sim_weapon_value(st, it) {
    switch (it.id) {
        case "turret": return 8;
        case "gatling_gun": return 7;
        case "flamethrower": return 10;
        case "railgun": return 11;
        case "lazer_gun": return 6;
        case "tesla": return 2 + 2 * max(2, array_length(st.active_zone));
        case "cannon": return 9;
        case "shield_generator": return 7;
        case "resource_drone": return (st.round_number <= 10) ? 7 : 3; // 3 free resource cards a day pays off early
        case "plasma_mortar": return 12;
        case "overcharge_pylon": return 5;
        case "energy_pylon": return 3 + game_pylon_bonus(st, 0, 1) * 1.5;
        case "cryo_emitter": return 6;
    }
    return 3;
}

function sim_empty_hardpoints(st) {
    var n = 0;
    for (var t = 0; t < 4; t++) {
        var tw = st.towers[t];
        if (tw.alive && (is_undefined(tw.weapon) || !tw.weapon.alive || tw.weapon.hp <= 0)) n++;
    }
    return n;
}

/// @desc Best blueprint to buy right now: [slot, item, score] or undefined
function sim_real_blueprints(st) {
    var n = 0;
    for (var b = 0; b < array_length(st.blueprints); b++) if (!(st.blueprints[b][$ "starter"] ?? false)) n++;
    return n;
}

/// @desc Alive towers that are empty or only carry a Makeshift Cannon
function sim_upgradeable_slots(st) {
    var n = 0;
    for (var t = 0; t < 4; t++) {
        var tw = st.towers[t];
        if (!tw.alive) continue;
        if (is_undefined(tw.weapon) || !tw.weapon.alive || tw.weapon.hp <= 0 || tw.weapon.catalog_id == "makeshift_cannon") n++;
    }
    return n;
}

function sim_desired_item(st) {
    if (sim_real_blueprints(st) >= sim_upgradeable_slots(st)) return undefined;
    var best = undefined;
    for (var i = 0; i < array_length(st.shop_available_items); i++) {
        var it = st.shop_available_items[i];
        if (!is_struct(it)) continue;
        var mats = 0;
        var keys = variable_struct_get_names(it.cost_res);
        for (var k = 0; k < array_length(keys); k++) mats += it.cost_res[$ keys[k]] * ((keys[k] == "power_gem") ? 4 : 1);
        var sc = sim_weapon_value(st, it) / (it.cost_gold + 1.2 * mats);
        if (is_undefined(best) || sc > best[2]) best = [i, it, sc];
    }
    return best;
}

/// @desc Resources the team still needs (owned blueprints, planned purchase, a pending rebuild)
function sim_reserved(st) {
    var res = { wood: 0, scrap: 0, stone: 0, metal: 0, crystals: 0, power_gem: 0 };
    for (var b = 0; b < array_length(st.blueprints); b++) {
        if ((st.blueprints[b][$ "starter"] ?? false) && sim_empty_hardpoints(st) == 0) continue;
        var c = st.blueprints[b].cost_res;
        var ks = variable_struct_get_names(c);
        for (var k = 0; k < array_length(ks); k++) res[$ ks[k]] += c[$ ks[k]];
    }
    var want = sim_desired_item(st);
    // Only earmark the next purchase's materials once we can actually afford it
    if (!is_undefined(want) && st.storage.gold >= want[1].cost_gold) {
        var c2 = want[1].cost_res;
        var ks2 = variable_struct_get_names(c2);
        for (var k = 0; k < array_length(ks2); k++) res[$ ks2[k]] += c2[$ ks2[k]];
    }
    for (var t = 0; t < 4; t++) {
        if (!st.towers[t].alive && !(st.towers[t][$ "rebuilt"] ?? false)) {
            res.metal += 15; res.power_gem += 5;
            break;
        }
    }
    // keep a little repair stock
    res.metal += 2; res.stone += 1; res.wood += 1;
    return res;
}

function sim_surplus_value(st, reserved) {
    var defs = game_get_resource_definitions();
    var keys = ["wood", "scrap", "stone", "metal", "crystals", "power_gem"];
    var v = 0;
    for (var i = 0; i < 6; i++) v += max(0, st.storage[$ keys[i]] - reserved[$ keys[i]]) * defs[$ keys[i]].sell_value;
    return v;
}

function sim_pick_target(st) {
    var best = 0, best_score = -999;
    for (var a = 0; a < array_length(st.active_zone); a++) {
        var al = st.active_zone[a];
        if (!al.alive) continue;
        var s = al.damage * 3 - al.hp * 0.3;
        if (al.catalog_id == "scout") s += 1000;
        if (al.catalog_id == "alien_queen" || al.catalog_id == "hatcher" || al.catalog_id == "screamer") s += 6;
        if (s > best_score) { best_score = s; best = a; }
    }
    return best;
}

function sim_claim(st, key, p) {
    var c = st.sim.claims[$ key];
    if (is_undefined(c) || c == p) { st.sim.claims[$ key] = p; return true; }
    return false;
}

// -----------------------------------------------------------------------------
// THE BOT: chooses one action for operative p (undefined = done for today)
// -----------------------------------------------------------------------------
function sim_bot_choose(st, p) {
    var pl = st.players[p];
    if (pl.energy <= 0) return undefined;
    var task = game_task_cost(pl);
    var mc = game_player_get_move_cost(pl);
    var act;
    var threats = array_length(st.active_zone);
    var ti = game_player_tower_idx(pl);
    var logistics = (p == 0) || (st.num_players == 1);

    // 1. Already on an armed tower with hostiles at the walls: fire
    if (ti >= 0 && threats > 0) {
        var tw = st.towers[ti];
        if (!is_undefined(tw.weapon) && tw.weapon.alive && tw.weapon.damage > 0 && tw.manual_cooldown <= 0 && pl.energy >= game_fire_cost(st, pl)) {
            return { a: "manual_fire", args: { target: sim_pick_target(st) } };
        }
    }

    // 2. Rebuild a fallen tower
    for (var t = 0; t < 4; t++) {
        if (!logistics && pl.node != "workstation") break;
        if (!st.towers[t].alive && !(st.towers[t][$ "rebuilt"] ?? false) && game_storage_has(st, game_tower_rebuild_cost()) && sim_claim(st, "ws", p)) {
            act = sim_go(st, pl, "workstation", { a: "rebuild_tower", args: { tower: t } }, task);
            if (!is_undefined(act)) return act;
        }
    }

    // 3a. Upgrade: no empty hardpoint, but a real blueprint is ready -> dismantle a Makeshift Cannon
    if (logistics && sim_empty_hardpoints(st) == 0) {
        for (var b = 0; b < array_length(st.blueprints); b++) {
            if ((st.blueprints[b][$ "starter"] ?? false) || !game_storage_has(st, st.blueprints[b].cost_res)) continue;
            for (var t = 0; t < 4; t++) {
                var twm = st.towers[t];
                if (twm.alive && !is_undefined(twm.weapon) && twm.weapon.alive && twm.weapon.catalog_id == "makeshift_cannon") {
                    act = sim_go(st, pl, twm.node_id, { a: "dismantle", args: {} }, task);
                    if (!is_undefined(act)) return act;
                }
            }
            break;
        }
    }
    // 3. Forge an owned blueprint onto an empty hardpoint (healthiest tower first, real blueprints before the starter)
    var bp_order = [];
    for (var b = 0; b < array_length(st.blueprints); b++) if (!(st.blueprints[b][$ "starter"] ?? false)) array_push(bp_order, b);
    for (var b = 0; b < array_length(st.blueprints); b++) if (st.blueprints[b][$ "starter"] ?? false) array_push(bp_order, b);
    for (var bo = 0; bo < array_length(bp_order); bo++) {
        var b = bp_order[bo];
        if (!logistics && pl.node != "workstation") break;
        if (!game_storage_has(st, st.blueprints[b].cost_res)) continue;
        var bt = -1, bhp = -1;
        for (var t = 0; t < 4; t++) {
            var tw2 = st.towers[t];
            if (tw2.alive && (is_undefined(tw2.weapon) || !tw2.weapon.alive || tw2.weapon.hp <= 0) && tw2.hp > bhp) { bhp = tw2.hp; bt = t; }
        }
        if (bt >= 0 && sim_claim(st, "ws", p)) {
            act = sim_go(st, pl, "workstation", { a: "craft_bp", args: { bp: b, tower: bt } }, task);
            if (!is_undefined(act)) return act;
        }
    }

    // 4. Emergency repairs only (tower at 40% or less) - economy comes first
    var danger = threats + array_length(st.spawn_zone);
    var reserved0 = sim_reserved(st);
    for (var t = 0; t < 4; t++) {
        if (!logistics && pl.node != "workstation") break;
        var tw3 = st.towers[t];
        if (!tw3.alive || danger == 0 || tw3.hp > tw3.max_hp * 0.4) continue;
        var missing = tw3.max_hp - tw3.hp;
        // Don't eat metal that's earmarked for a blueprint unless the tower is in real trouble
        var spare_metal = st.storage.metal > reserved0.metal || tw3.hp <= tw3.max_hp * 0.4;
        var can3 = (st.storage.metal >= 1 && spare_metal) || (st.storage.scrap >= 1 && st.storage.stone >= 1);
        if (missing >= 3 && can3 && sim_claim(st, "ws", p)) {
            act = sim_go(st, pl, "workstation", { a: "repair_tower", args: { tower: t, method: "metal_or_scrap_stone" } }, task);
            if (!is_undefined(act)) return act;
        }
        if (missing >= 1 && tw3.hp <= tw3.max_hp * 0.6 && st.storage.stone >= 1 && st.storage.wood >= 1 && sim_claim(st, "ws", p)) {
            act = sim_go(st, pl, "workstation", { a: "repair_tower", args: { tower: t, method: "stone_wood" } }, task);
            if (!is_undefined(act)) return act;
        }
    }

    // 5. Buy the best blueprint we can afford
    var want = sim_desired_item(st);
    if (logistics && !is_undefined(want) && st.storage.gold >= want[1].cost_gold && sim_claim(st, "shop", p)) {
        act = sim_go(st, pl, "shop", { a: "buy", args: { slot: want[0] } }, task);
        if (!is_undefined(act)) return act;
    }

    // 6. Late game: reinforce the weakest tower with spare riches
    if (logistics && st.round_number >= 10 && is_undefined(want) && game_storage_has(st, game_tower_reinforce_cost()) && sim_claim(st, "ws", p)) {
        var rt = -1, rhp = 999;
        for (var t = 0; t < 4; t++) if (st.towers[t].alive && st.towers[t].max_hp < rhp) { rhp = st.towers[t].max_hp; rt = t; }
        if (rt >= 0) {
            act = sim_go(st, pl, "workstation", { a: "reinforce_tower", args: { tower: rt } }, task);
            if (!is_undefined(act)) return act;
        }
    }

    // 7. Sell surplus when we're short of gold for the next purchase
    var reserved = sim_reserved(st);
    var gold_goal = is_undefined(want) ? 0 : want[1].cost_gold;
    var surplus = sim_surplus_value(st, reserved);
    if (logistics && ((st.storage.gold < gold_goal && surplus >= min(8, gold_goal - st.storage.gold)) || surplus >= 30)) {
        if (sim_claim(st, "town", p)) {
            if (pl.node == "town") {
                if (pl.energy < task) return undefined;
                // Fill a cart with the most valuable surplus, as many items as our energy can trade
                var defs = game_get_resource_definitions();
                var fav = st.town_favors[st.active_town_favor];
                var keys = ["power_gem", "crystals", "metal", "stone", "wood", "scrap"];
                var slots = floor(pl.energy / task) * 3;
                var order = [];
                for (var i = 0; i < 6; i++) array_push(order, [keys[i], defs[$ keys[i]].sell_value + ((fav.resource == keys[i]) ? fav.bonus_gold : 0)]);
                array_sort(order, function(a1, b1) { return b1[1] - a1[1]; });
                var cart = {};
                var units = 0;
                for (var i = 0; i < 6 && units < slots; i++) {
                    var k = order[i][0];
                    var spare = max(0, st.storage[$ k] - reserved[$ k]);
                    var take = min(spare, slots - units);
                    if (take > 0) { cart[$ k] = take; units += take; }
                }
                // Don't burn a trade on a lone low-value item
                if (units > 0) return { a: "sell_cart", args: { cart: cart } };
            } else {
                act = sim_go(st, pl, "town", undefined, task);
                if (!is_undefined(act)) return act;
            }
        }
    }

    // 7b. Routine repairs once the shopping is done
    var danger1 = threats + array_length(st.spawn_zone);
    var reserved1 = sim_reserved(st);
    for (var t = 0; t < 4; t++) {
        if (!logistics && pl.node != "workstation") break;
        var tw5 = st.towers[t];
        if (!tw5.alive || danger1 == 0) continue;
        var missing5 = tw5.max_hp - tw5.hp;
        // Don't eat metal that's earmarked for a blueprint unless the tower is in real trouble
        var spare_metal5 = st.storage.metal > reserved1.metal || tw5.hp <= tw5.max_hp * 0.4;
        var can5 = (st.storage.metal >= 1 && spare_metal5) || (st.storage.scrap >= 1 && st.storage.stone >= 1);
        if (missing5 >= 3 && can5 && sim_claim(st, "ws", p)) {
            act = sim_go(st, pl, "workstation", { a: "repair_tower", args: { tower: t, method: "metal_or_scrap_stone" } }, task);
            if (!is_undefined(act)) return act;
        }
        if (missing5 >= 1 && tw5.hp <= tw5.max_hp * 0.6 && st.storage.stone >= 1 && st.storage.wood >= 1 && sim_claim(st, "ws", p)) {
            act = sim_go(st, pl, "workstation", { a: "repair_tower", args: { tower: t, method: "stone_wood" } }, task);
            if (!is_undefined(act)) return act;
        }
    }

    // 8. Head to a nearby armed tower to shoot when aliens are at the walls
    if (threats > 0) {
        for (var t = 0; t < 4; t++) {
            var tw4 = st.towers[t];
            if (!tw4.alive || is_undefined(tw4.weapon) || !tw4.weapon.alive || tw4.weapon.damage <= 0 || tw4.manual_cooldown > 0) continue;
            var pth = sim_path(st, pl.node, tw4.node_id);
            if (pth[1] == 1 && pl.energy >= mc + game_fire_cost(st, pl) && sim_claim(st, "fire" + string(t), p)) return { a: "move", args: { node: pth[0] } };
        }
    }

    // 9. Gather: what we're short of, or whatever sells best nearby
    var Y = sim_node_yield();
    var defs2 = game_get_resource_definitions();
    var nodes = ["forest", "cave_1", "cave_2", "cave_3"];
    var best_node = "", best_score = -999;
    for (var n = 0; n < 4; n++) {
        var yl = Y[$ nodes[n]];
        var ks = variable_struct_get_names(yl);
        var need_score = 0, value_score = 0;
        for (var k = 0; k < array_length(ks); k++) {
            var r = ks[k];
            var deficit = max(0, reserved[$ r] - st.storage[$ r]);
            need_score += min(deficit, 3) * yl[$ r] * ((r == "power_gem") ? 4 : 1);
            value_score += yl[$ r] * defs2[$ r].sell_value;
        }
        var dist = sim_path(st, pl.node, nodes[n])[1];
        var nsc = need_score * 3 + value_score * 0.4 - dist * mc * 0.9 + ((pl.node == nodes[n]) ? 3 : 0);
        if (nsc > best_score) { best_score = nsc; best_node = nodes[n]; }
    }
    if (best_node != "") {
        act = sim_go(st, pl, best_node, { a: "gather", args: {} }, task);
        if (!is_undefined(act)) return act;
    }
    return undefined;
}

// -----------------------------------------------------------------------------
// COMBAT (instant resolution with the real damage functions)
// -----------------------------------------------------------------------------
function sim_resolve_combat(st) {
    if (st.phase == "combat_weapons" && st.combat_subphase == "player_weapons") {
        for (var t = 0; t < 4; t++) {
            if (st.tower_weapon_used[t]) continue;
            var w = st.towers[t].weapon;
            if (is_undefined(w)) { st.tower_weapon_used[t] = true; continue; }
            if (w.catalog_id == "tesla") {
                st.combat_selected_tower = t;
                game_combat_discharge_tesla(st);
            } else {
                while (st.tower_weapon_shots[t] > 0 && array_length(st.active_zone) > 0) {
                    game_apply_weapon_damage(st, w, sim_pick_target(st));
                    st.tower_weapon_shots[t]--;
                }
                st.tower_weapon_used[t] = true;
            }
            if (st.combat_subphase != "player_weapons") break;
        }
        if (st.combat_subphase == "player_weapons") {
            if (array_length(st.active_zone) == 0) { st.combat_subphase = "combat_concluded"; }
            else game_start_alien_attack_phase(st);
        }
    }
    if (st.combat_subphase == "alien_attacks") {
        var guard = 0;
        while (guard++ < 200 && st.phase != "game_over") {
            if (!game_spawn_next_alien_projectile(st)) break;
            for (var i = 0; i < array_length(st.combat_projectiles); i++) {
                game_apply_projectile_impact(st, st.combat_projectiles[i]);
                if (st.phase == "game_over") break;
            }
            st.combat_projectiles = [];
        }
        // All towers dead after the last impact?
        var any = false;
        for (var t = 0; t < 4; t++) if (st.towers[t].alive) any = true;
        if (!any) st.phase = "game_over";
    }
    if (st.phase != "game_over") {
        st.combat_subphase = "combat_concluded";
        game_combat_conclude(st);
    }
}

// -----------------------------------------------------------------------------
// ONE FULL GAME
// -----------------------------------------------------------------------------
function sim_play_game(n_players, mods = {}) {
    // Random squad: unique specialists, Survivor allowed for anyone
    var pool = [1, 2, 3, 4, 5];
    var classes = [];
    for (var p = 0; p < n_players; p++) {
        if (irandom(5) == 0 || array_length(pool) == 0) { array_push(classes, 0); continue; }
        var pick = irandom(array_length(pool) - 1);
        array_push(classes, pool[pick]);
        array_delete(pool, pick, 1);
    }
    var names = ["Bot A", "Bot B", "Bot C", "Bot D"];
    global.sim_mode = true;
    var st = game_init_state(n_players, classes, names);
    st.screen = "game";
    st.modal = undefined;
    st.sim = { claims: {} };
    st.storage.gold += mods[$ "gold"] ?? 0;
    var free_turrets = mods[$ "turrets"] ?? 0;
    if (free_turrets > 0) {
        var it = game_get_weapon_catalog()[0];
        for (var ft = 0; ft < free_turrets; ft++) {
            var tix = (ft == 0) ? 0 : 2;
            var fw = { catalog_id: it.id, name: it.name, hp: it.hp, max_hp: it.hp, damage: it.damage, bonus_damage: 0, ability: it.ability, target_count: it.target_count, splash_count: 0, splash_dmg: 0, cooldown: 0, cost_res: it.cost_res, power_gem_used: false, disabled: false, stationed_tower: tix, alive: true };
            st.towers[tix].weapon = fw;
            array_push(st.weapons, fw);
        }
    }
    var extra_energy = mods[$ "energy"] ?? 0;
    var rec = { n: n_players, classes: "", won: false, day: 1, towers: 4, first_loss: -1, forged: 0, bought: 0, rebuilds: 0, reinforces: 0, sold_gold: 0, peak_aliens: 0, forged_ids: {}, hp: array_create(41, -1), walls: array_create(41, -1), weps: array_create(41, -1), kills: 0 };
    var cls = game_get_character_classes();
    for (var p = 0; p < n_players; p++) rec.classes += ((p > 0) ? "/" : "") + cls[classes[p]].name;

    var guard = 0;
    var last_round = 0;
    while (guard++ < 6000) {
        if (st.phase == "victory") { rec.won = true; break; }
        if (st.phase == "game_over") break;
        if (st.round_number > 40) break;
        if (st.phase == "player_actions") {
            if (st.round_number != last_round) {
                last_round = st.round_number;
                st.sim.claims = {};
                if (extra_energy > 0) for (var pe = 0; pe < st.num_players; pe++) st.players[pe].energy += extra_energy;
            }
            for (var p = 0; p < st.num_players; p++) {
                st.current_player_idx = p;
                var g2 = 0;
                while (g2++ < 40 && st.phase == "player_actions") {
                    var act = sim_bot_choose(st, p);
                    if (is_undefined(act)) break;
                    var gold0 = st.storage.gold;
                    var ok = game_execute_action(st, p, act.a, act.args);
                    if (global.sim_trace) autotest_log("  d" + string(st.round_number) + " P" + string(p) + " @" + st.players[p].node + " e" + string(st.players[p].energy) + " " + act.a + " " + json_stringify(act.args) + (ok ? "" : " FAILED: " + ((array_length(st.action_logs) > 0) ? st.action_logs[0] : "")) + " | gold " + string(st.storage.gold) + " wd" + string(st.storage.wood) + " sc" + string(st.storage.scrap) + " st" + string(st.storage.stone) + " mt" + string(st.storage.metal) + " cr" + string(st.storage.crystals) + " pg" + string(st.storage.power_gem) + " bp" + string(array_length(st.blueprints)));
                    if (!ok) break;
                    if (act.a == "craft_bp") {
                        rec.forged++;
                        var fw = st.towers[real(act.args[$ "tower"] ?? 0)].weapon;
                        if (!is_undefined(fw)) rec.forged_ids[$ fw.catalog_id] = (rec.forged_ids[$ fw.catalog_id] ?? 0) + 1;
                    }
                    else if (act.a == "buy") rec.bought++;
                    else if (act.a == "rebuild_tower") rec.rebuilds++;
                    else if (act.a == "reinforce_tower") rec.reinforces++;
                    else if (act.a == "trade" || act.a == "sell_cart") rec.sold_gold += st.storage.gold - gold0;
                }
                if (st.phase != "player_actions") break;
            }
            var dn = min(40, st.round_number);
            rec.peak_aliens = max(rec.peak_aliens, array_length(st.active_zone));
            rec.walls[dn] = array_length(st.active_zone);
            var wc = 0;
            for (var t = 0; t < 4; t++) if (st.towers[t].alive && !is_undefined(st.towers[t].weapon) && st.towers[t].weapon.alive) wc++;
            rec.weps[dn] = wc;
            if (st.phase == "player_actions") game_begin_defense(st);
        }
        if (st.phase == "combat_weapons" || st.phase == "combat_aliens") {
            var before = array_length(st.active_zone);
            sim_resolve_combat(st);
        }
        // End-of-day bookkeeping (recorded against the day that just ended)
        var hp = 0, alive = 0;
        for (var t = 0; t < 4; t++) if (st.towers[t].alive) { hp += st.towers[t].hp; alive++; }
        var ended = (st.phase == "game_over" || st.phase == "victory") ? st.round_number : st.round_number - 1;
        if (ended >= 1 && ended <= 40) rec.hp[ended] = hp;
        if (alive < 4 && rec.first_loss < 0) rec.first_loss = ended;
    }
    var alive_end = 0;
    for (var t = 0; t < 4; t++) if (st.towers[t].alive) alive_end++;
    rec.towers = alive_end;
    rec.day = rec.won ? game_final_day(st) : st.round_number;
    global.sim_mode = false;
    return rec;
}

// -----------------------------------------------------------------------------
// SCENARIO
// -----------------------------------------------------------------------------
function autotest_scenario_balance() {
    var s = [];
    global.at.vars.bal = {
        variants: [
            { name: "CURRENT RULES", games: 100, mods: {} }
        ],
        v: 0, n: 1, results: []
    };
    array_push(s, autotest_step(5, function(st) {
        autotest_log("BALANCE PLAYTEST - heuristic bot, random unique classes, real game rules");
        autotest_log("GAME n | squad | result | day reached | towers left | first tower lost | blueprints bought | forged | rebuilds | reinforces | gold from sales | peak aliens at walls");
    }));
    array_push(s, autotest_step(1, undefined, function(st) {
        var B = global.at.vars.bal;
        if (B.v >= array_length(B.variants)) return true;
        var V = B.variants[B.v];
        if (B.n == 1 && array_length(B.results) == 0) autotest_log("=== " + V.name + " ===");
        for (var k = 0; k < 3; k++) {
            var r = sim_play_game(B.n, V.mods);
            array_push(B.results, r);
            if (B.v == 0) autotest_log("GAME " + string(r.n) + "P | " + r.classes + " | " + (r.won ? "WIN " : "LOSS") + " | day " + string(r.day) + " | towers " + string(r.towers) + " | first loss " + ((r.first_loss < 0) ? "-" : string(r.first_loss)) + " | bought " + string(r.bought) + " | forged " + string(r.forged) + " | rebuilds " + string(r.rebuilds) + " | reinforces " + string(r.reinforces) + " | sold " + string(r.sold_gold) + "g | peak " + string(r.peak_aliens));
            if (array_length(B.results) >= V.games) {
                sim_log_summary(V.name, B.n, B.results);
                B.results = [];
                B.n++;
                if (B.n > 4) { B.n = 1; B.v++; }
                break;
            }
        }
        return false;
    }, 30000));
    array_push(s, autotest_step(1, function(st) { autotest_finish(); }));
    return s;
}

function sim_log_summary(vname, n, R) {
    var wins = 0, day_sum = 0, fl_sum = 0, fl_n = 0, tw_sum = 0, forged = 0, bought = 0, sold = 0, rebuilds = 0, peak = 0;
    var loss_days = array_create(41, 0);
    var hp_sum = array_create(41, 0), hp_n = array_create(41, 0);
    var wl_sum = array_create(41, 0), wl_n = array_create(41, 0);
    var wp_sum = array_create(41, 0), wp_n = array_create(41, 0);
    for (var i = 0; i < array_length(R); i++) {
        var r = R[i];
        if (r.won) wins++; else loss_days[min(40, r.day)]++;
        day_sum += r.day; tw_sum += r.towers; forged += r.forged; bought += r.bought; sold += r.sold_gold; rebuilds += r.rebuilds; peak += r.peak_aliens;
        if (r.first_loss > 0) { fl_sum += r.first_loss; fl_n++; }
        for (var d = 1; d <= 20; d++) {
            // a lost game counts as 0 tower HP for the remaining days so the curve isn't survivor-biased
            var hv = r.hp[d];
            if (hv < 0 && !r.won && d > r.day) hv = 0;
            if (hv >= 0) { hp_sum[d] += hv; hp_n[d]++; }
            if (r.walls[d] >= 0) { wl_sum[d] += r.walls[d]; wl_n[d]++; }
            if (r.weps[d] >= 0) { wp_sum[d] += r.weps[d]; wp_n[d]++; }
        }
    }
    var g = max(1, array_length(R));
    autotest_log("SUMMARY [" + vname + "] " + string(n) + "P: win " + string(round(wins / g * 100)) + "% (" + string(wins) + "/" + string(g) + ") | avg day reached " + string_format(day_sum / g, 1, 1)
        + " | first tower lost day " + ((fl_n > 0) ? string_format(fl_sum / fl_n, 1, 1) : "-")
        + " | towers left " + string_format(tw_sum / g, 1, 2) + " | blueprints bought " + string_format(bought / g, 1, 1) + " forged " + string_format(forged / g, 1, 1)
        + " | gold from sales " + string(round(sold / g)) + " | peak aliens " + string_format(peak / g, 1, 1) + " | rebuilds " + string(rebuilds));
    var fsum = {};
    for (var i = 0; i < array_length(R); i++) {
        var fk = variable_struct_get_names(R[i].forged_ids);
        for (var k = 0; k < array_length(fk); k++) fsum[$ fk[k]] = (fsum[$ fk[k]] ?? 0) + R[i].forged_ids[$ fk[k]];
    }
    var fl = "", fk2 = variable_struct_get_names(fsum);
    array_sort(fk2, true);
    for (var k = 0; k < array_length(fk2); k++) fl += " " + fk2[k] + ":" + string_format(fsum[$ fk2[k]] / g, 1, 2);
    autotest_log("FORGED [" + vname + "] " + string(n) + "P per game:" + fl);
    var ld = "";
    for (var d = 1; d <= 40; d++) if (loss_days[d] > 0) ld += " d" + string(d) + ":" + string(loss_days[d]);
    autotest_log("LOSSDAYS [" + vname + "] " + string(n) + "P:" + ((ld == "") ? " none" : ld));
    var c1 = "", c2 = "", c3 = "";
    for (var d = 1; d <= 20; d++) {
        c1 += ((d > 1) ? "," : "") + ((hp_n[d] > 0) ? string(round(hp_sum[d] / hp_n[d])) : "-");
        c2 += ((d > 1) ? "," : "") + ((wl_n[d] > 0) ? string_format(wl_sum[d] / wl_n[d], 1, 1) : "-");
        c3 += ((d > 1) ? "," : "") + ((wp_n[d] > 0) ? string_format(wp_sum[d] / wp_n[d], 1, 1) : "-");
    }
    autotest_log("TOWERHP [" + vname + "] " + string(n) + "P days1-20: " + c1);
    autotest_log("ALIENS  [" + vname + "] " + string(n) + "P days1-20: " + c2);
    autotest_log("WEAPONS [" + vname + "] " + string(n) + "P days1-20: " + c3);
}

/// @desc Single traced game for debugging the bot: -autotest balance_trace
function autotest_scenario_balance_trace() {
    var s = [];
    array_push(s, autotest_step(5, function(st) {
        global.sim_trace = true;
        var r = sim_play_game(3);
        global.sim_trace = false;
        autotest_log("RESULT " + (r.won ? "WIN" : "LOSS") + " day " + string(r.day));
        autotest_finish();
    }));
    return s;
}
