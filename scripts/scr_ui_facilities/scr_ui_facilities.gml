/// @desc Facility screens: Blueprint Shop, Town Market and Workshop.
/// Buttons register their gameplay action in state.ui_click_action; input runs it on click.

/// @desc Button that triggers a game action when clicked. Shows why it's disabled on hover.
function ui_action_button(state, bx, by, bw, bh, label, enabled, style, hotkey, action, args, tip_on, tip_off, mx, my) {
    var over = ui_point_in_rect(mx, my, bx, by, bw, bh);
    var hov = ui_draw_button(bx, by, bw, bh, label, enabled, false, mx, my, style, hotkey);
    if (hov) state.ui_click_action = { a: action, args: args };
    if (over) {
        var tip = enabled ? tip_on : tip_off;
        if (tip != "") state.hover_tooltip = tip;
    }
    return hov;
}

/// @desc Resource cost chips (icon + amount, red when short). Returns total width.
function ui_cost_chips(state, cx, cy, cost, order = undefined) {
    if (is_undefined(order)) order = ["gold", "metal", "power_gem", "crystals", "stone", "scrap", "wood"];
    var x0 = cx;
    draw_set_font(fnt_small);
    for (var i = 0; i < array_length(order); i++) {
        var k = order[i];
        if (!variable_struct_exists(cost, k)) continue;
        var need = cost[$ k];
        var have = state.storage[$ k];
        var ok = (have >= need);
        var txt = string(need);
        var w = string_width(txt) + 30;
        ui_box(cx, cy - 11, cx + w, cy + 11, ok ? C_BG1 : make_color_rgb(48, 16, 22), ok ? C_LINE : C_BAD, 11);
        ui_icon_resource(cx + 12, cy, k, 14);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(ok ? C_TEXT : C_BAD);
        draw_text(cx + 22, cy, txt);
        cx += w + 6;
    }
    draw_set_font(fnt_body);
    return cx - x0;
}

/// @desc Shared header: title, subtitle and the "where am I" chips
function ui_facility_header(state, mx0, my0, mw, title, subtitle, accent, at_place, place_name) {
    var pl = game_local_player(state);
    draw_set_color(accent);
    draw_roundrect_ext(mx0 + 28, my0 + 22, mx0 + 32, my0 + 58, 2, 2, false);
    draw_set_font(fnt_h2);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(C_TEXT);
    draw_text(mx0 + 44, my0 + 18, title);
    draw_set_font(fnt_small);
    draw_set_color(C_DIM);
    draw_text(mx0 + 46, my0 + 50, subtitle);

    // Chips row
    var cy = my0 + 96;
    var cx = mx0 + 32;
    var st = at_place ? ("At the " + place_name) : ("Viewing remotely - travel to the " + place_name + " to act");
    cx += ui_pill(cx, cy - 13, st, at_place ? C_GOOD_D : make_color_rgb(70, 48, 12), at_place ? C_GOOD : C_AMBER, at_place ? C_GOOD : C_AMBER, 26) + 8;
    // Gold
    draw_set_font(fnt_bold);
    var gtxt = string(state.storage.gold);
    var gw = string_width(gtxt) + 44;
    ui_box(cx, cy - 13, cx + gw, cy + 13, C_BG1, C_LINE, 13);
    ui_icon_resource(cx + 15, cy, "gold", 16);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_GOLD);
    draw_text(cx + 28, cy, gtxt);
    cx += gw + 8;
    // Energy
    var etxt = string(pl.energy) + "/" + string(pl.max_energy);
    var ew = string_width(etxt) + 44;
    ui_box(cx, cy - 13, cx + ew, cy + 13, C_BG1, C_LINE, 13);
    ui_draw_lightning(cx + 15, cy, 15, pl.energy > 0);
    draw_set_color(C_ENERGY);
    draw_text(cx + 28, cy, etxt);
    cx += ew + 8;
    draw_set_font(fnt_body);
    return cx;
}

// =============================================================================
// BLUEPRINT SHOP
// =============================================================================
function ui_draw_shop(state, mx, my, mx0, my0, mw, mh) {
    var pl = game_local_player(state);
    var at_shop = (pl.node == "shop");
    var cost_e = game_task_cost(pl);
    var can_act = at_shop && state.phase == "player_actions" && !(state.is_online && pl.ended_turn);
    ui_facility_header(state, mx0, my0, mw, "BLUEPRINT SHOP", "Buy weapon blueprints with Gold, then forge them onto a tower at the Workshop.", C_AMBER, at_shop, "Shop");

    // Reroll (row below the title, never under the close button)
    var rr_w = 250;
    var can_reroll = can_act && state.storage.gold >= state.shop_reroll_cost;
    ui_action_button(state, mx0 + mw - 32 - rr_w, my0 + 80, rr_w, 34, "Reroll offers  -  " + string(state.shop_reroll_cost) + "g", can_reroll, "default", "", "reroll", {},
        "Swap all three offers. The price rises by 2g each time and resets after 3 days without a reroll.",
        at_shop ? ("Need " + string(state.shop_reroll_cost) + " Gold to reroll.") : "Travel to the Shop to reroll.", mx, my);

    var gap = 20;
    var cw = floor((mw - 64 - 2 * gap) / 3);
    var cy0 = my0 + 132;
    var ch = mh - 132 - 56;
    for (var i = 0; i < 3; i++) {
        var cx = mx0 + 32 + i * (cw + gap);
        var item = (i < array_length(state.shop_available_items)) ? state.shop_available_items[i] : undefined;
        if (is_undefined(item)) {
            ui_box(cx, cy0, cx + cw, cy0 + ch, C_BG1, C_LINE, 12);
            draw_set_font(fnt_h3); draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(C_FAINT);
            draw_text(cx + cw * 0.5, cy0 + ch * 0.5, "SOLD OUT");
            continue;
        }
        var hov = ui_point_in_rect(mx, my, cx, cy0, cw, ch);
        var lift = ui_anim("shopcard" + string(i) + item.id, hov ? 1 : 0, 0.25);
        var y0 = cy0 - lift * 4;
        var affordable = state.storage.gold >= item.cost_gold;
        ui_shadow(cx, y0, cx + cw, y0 + ch, 12, 0.4 + lift * 0.3);
        ui_box(cx, y0, cx + cw, y0 + ch, ui_col_mix(C_RAISED, C_HOVER, lift * 0.6), ui_col_mix(C_LINE, C_AMBER, lift), 12);

        // Art panel
        ui_box(cx + 12, y0 + 12, cx + cw - 12, y0 + 128, make_color_rgb(14, 18, 28), undefined, 10);
        ui_glow(cx + cw * 0.5, y0 + 70, 90, C_WEAPON, 0.18 + lift * 0.12);
        ui_icon_weapon(cx + cw * 0.5, y0 + 70, item.id, 74, C_WEAPON);
        // Price tag
        draw_set_font(fnt_h3);
        var price = string(item.cost_gold) + "g";
        var pw = string_width(price) + 40;
        ui_box(cx + cw - 20 - pw, y0 + 20, cx + cw - 20, y0 + 50, make_color_rgb(60, 44, 10), affordable ? C_GOLD : C_BAD, 15);
        ui_icon_resource(cx + cw - 20 - pw + 15, y0 + 35, "gold", 16);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(affordable ? C_GOLD : C_BAD);
        draw_text(cx + cw - 20 - pw + 28, y0 + 34, price);

        // Name + stats
        draw_set_font(fnt_h2);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(C_TEXT);
        draw_text(cx + 18, y0 + 140, item.name);
        var sy = y0 + 184;
        var stats = [["HP", string(item.hp), C_WEAPON], ["DMG", (item.damage > 0) ? string(item.damage) : "-", C_AMBER], ["TARGETS", (item.target_count >= 99) ? "ALL" : ((item.target_count > 0) ? string(item.target_count) : "-"), C_ACCENT]];
        var sw = floor((cw - 36 - 16) / 3);
        for (var k = 0; k < 3; k++) {
            var sx = cx + 18 + k * (sw + 8);
            ui_box(sx, sy, sx + sw, sy + 46, C_BG1, C_LINE, 8);
            draw_set_font(fnt_h3); draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(stats[k][2]);
            draw_text(sx + sw * 0.5, sy + 16, stats[k][1]);
            draw_set_font(fnt_small);
            draw_set_color(C_FAINT);
            draw_text(sx + sw * 0.5, sy + 36, stats[k][0]);
        }
        // Ability
        draw_set_font(fnt_body);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(C_DIM);
        draw_text_ext(cx + 18, sy + 60, item.ability, -1, cw - 36);
        // Forge materials
        var my_mat = y0 + ch - 118;
        ui_section_label(cx + 18, my_mat, "Forge materials (Workshop)");
        ui_cost_chips(state, cx + 18, my_mat + 26, item.cost_res);

        // Buy
        var lbl = "Buy blueprint";
        if (!at_shop) lbl = "Travel to the Shop";
        else if (!affordable) lbl = "Need " + string(item.cost_gold - state.storage.gold) + " more gold";
        else if (pl.energy < cost_e) lbl = "Need " + string(cost_e) + " energy";
        var can_buy = can_act && affordable && pl.energy >= cost_e;
        ui_action_button(state, cx + 14, y0 + ch - 64, cw - 28, 50, lbl, can_buy, "amber", "", "buy", { slot: i },
            "Buy the " + item.name + " blueprint for " + string(item.cost_gold) + " Gold (" + string(cost_e) + " energy). A new offer replaces it.",
            "", mx, my);
    }
    draw_set_font(fnt_small);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_FAINT);
    draw_text(mx0 + 32, my0 + mh - 26, string(array_length(state.shop_deck)) + " blueprints left in the deck   -   owned blueprints: " + string(array_length(state.blueprints)));
    draw_set_font(fnt_body);
}

// =============================================================================
// TOWN MARKET (sell cart)
// =============================================================================
/// @desc Units, gold, trades and energy for the current sell cart
function ui_market_cart_totals(state, pl) {
    var cart = state.market_cart;
    var defs = game_get_resource_definitions();
    var fav = state.town_favors[state.active_town_favor];
    var keys = ["wood", "scrap", "stone", "metal", "crystals", "power_gem"];
    var units = 0, gold = 0;
    for (var i = 0; i < 6; i++) {
        var n = cart[$ keys[i]] ?? 0;
        units += n;
        gold += n * (defs[$ keys[i]].sell_value + ((fav.resource == keys[i]) ? fav.bonus_gold : 0));
    }
    var trades = ceil(units / 3);
    return { units: units, gold: gold, trades: trades, energy: trades * game_task_cost(pl) };
}

function ui_draw_market(state, mx, my, mx0, my0, mw, mh) {
    var pl = game_local_player(state);
    var at_town = (pl.node == "town");
    var cost_e = game_task_cost(pl);
    var can_act = at_town && state.phase == "player_actions" && !(state.is_online && pl.ended_turn);
    if (!is_struct(state[$ "market_cart"])) state.market_cart = {};
    ui_facility_header(state, mx0, my0, mw, "TOWN MARKET", "Pick what to sell with + and -. Each trade sells up to 3 items (mix freely) for " + string(cost_e) + " energy.", make_color_rgb(236, 140, 176), at_town, "Town");

    var fav = state.town_favors[state.active_town_favor];
    var fy = my0 + 128;
    ui_box(mx0 + 32, fy, mx0 + mw - 32, fy + 50, make_color_rgb(44, 34, 14), C_AMBER, 10);
    draw_set_color(C_AMBER);
    draw_set_font(fnt_h3);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_text(mx0 + 52, fy + 25, "★  TODAY'S FAVOR: " + string_upper(fav.name));
    draw_set_font(fnt_body);
    draw_set_color(C_TEXT);
    draw_set_halign(fa_right);
    draw_text(mx0 + mw - 52, fy + 25, fav.desc + "  -  the favor changes every day");

    var res = ["wood", "scrap", "stone", "metal", "crystals", "power_gem"];
    var defs = game_get_resource_definitions();
    var gap = 16;
    var tw = floor((mw - 64 - 2 * gap) / 3);
    var gy0 = fy + 66;
    var bar_h = 64;
    var th = floor((my0 + mh - 32 - bar_h - 16 - gy0 - gap) / 2);
    for (var i = 0; i < 6; i++) {
        var k = res[i];
        var tx = mx0 + 32 + (i mod 3) * (tw + gap);
        var ty = gy0 + (i div 3) * (th + gap);
        var have = state.storage[$ k];
        var n = clamp(state.market_cart[$ k] ?? 0, 0, have);
        state.market_cart[$ k] = n;
        var bonus = (fav.resource == k) ? fav.bonus_gold : 0;
        var each = defs[$ k].sell_value + bonus;
        var picked = n > 0;
        var glow = ui_anim("mk_" + k, picked ? 1 : 0, 0.25);
        ui_box(tx, ty, tx + tw, ty + th, ui_col_mix((bonus > 0) ? make_color_rgb(36, 30, 18) : C_RAISED, make_color_rgb(20, 44, 34), glow * 0.7), picked ? C_GOOD : ((bonus > 0) ? C_AMBER : C_LINE), 12);
        ui_glow(tx + 40, ty + 40, 40, ui_resource_color(k), 0.15);
        ui_icon_resource(tx + 40, ty + 40, k, 36);
        draw_set_font(fnt_h3);
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(C_TEXT);
        draw_text(tx + 72, ty + 28, defs[$ k].name);
        draw_set_font(fnt_small);
        draw_set_color(have > 0 ? C_DIM : C_FAINT);
        draw_text(tx + 72, ty + 52, string(have - n) + " left in storage");
        draw_set_font(fnt_h2);
        draw_set_halign(fa_right);
        draw_set_color(bonus > 0 ? C_AMBER : C_GOLD);
        draw_text(tx + tw - 16, ty + 30, string(each) + "g");
        draw_set_font(fnt_small);
        draw_set_color(C_FAINT);
        draw_text(tx + tw - 16, ty + 54, (bonus > 0) ? ("each  (+" + string(bonus) + " favor)") : "each");

        // - [count] +   ... subtotal
        var cy = ty + th - 54;
        ui_action_button(state, tx + 16, cy, 44, 40, "-", n > 0, "default", "", "@cart", { res: k, d: -1 }, "Take one " + defs[$ k].name + " out of the sale.", "", mx, my);
        ui_box(tx + 66, cy, tx + 132, cy + 40, C_BG0, picked ? C_GOOD : C_LINE, 6);
        draw_set_font(fnt_h3);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(picked ? c_white : C_FAINT);
        draw_text(tx + 99, cy + 20, string(n));
        ui_action_button(state, tx + 138, cy, 44, 40, "+", n < have, "default", "", "@cart", { res: k, d: 1 }, "Add one " + defs[$ k].name + " to the sale.", (have == 0) ? ("No " + defs[$ k].name + " in storage.") : "That's all of it.", mx, my);
        ui_action_button(state, tx + 188, cy, 56, 40, "All", have > 0 && n < have, "ghost", "", "@cart", { res: k, d: 999 }, "Add every " + defs[$ k].name + " in storage.", "", mx, my);
        draw_set_font(fnt_h3);
        draw_set_halign(fa_right);
        draw_set_color(picked ? C_GOOD : C_FAINT);
        draw_text(tx + tw - 16, cy + 20, picked ? ("+" + string(n * each) + "g") : "-");
    }

    // Summary bar
    var T = ui_market_cart_totals(state, pl);
    var by = my0 + mh - 32 - bar_h;
    var enough = pl.energy >= T.energy;
    ui_box(mx0 + 32, by, mx0 + mw - 32, by + bar_h, C_BG1, (T.units > 0) ? (enough ? C_GOOD : C_BAD) : C_LINE, 12);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    if (T.units == 0) {
        draw_set_font(fnt_body);
        draw_set_color(C_FAINT);
        draw_text(mx0 + 56, by + bar_h * 0.5, "Nothing picked yet - use + to add items to the sale.");
    } else {
        var sx = mx0 + 56;
        draw_set_font(fnt_bold);
        draw_set_color(C_TEXT);
        var t1 = "Selling " + string(T.units) + " item" + ((T.units == 1) ? "" : "s");
        draw_text(sx, by + bar_h * 0.5, t1);
        sx += string_width(t1) + 26;
        ui_icon_resource(sx, by + bar_h * 0.5, "gold", 22);
        draw_set_font(fnt_h2);
        draw_set_color(C_GOLD);
        draw_text(sx + 18, by + bar_h * 0.5, "+" + string(T.gold));
        sx += 18 + string_width("+" + string(T.gold)) + 30;
        ui_draw_lightning(sx, by + bar_h * 0.5, 20, true);
        draw_set_color(enough ? C_ENERGY : C_BAD);
        var t2 = string(T.energy) + " energy";
        draw_text(sx + 16, by + bar_h * 0.5, t2);
        sx += 16 + string_width(t2) + 18;
        draw_set_font(fnt_small);
        draw_set_color(enough ? C_FAINT : C_BAD);
        var hint_w = (mx0 + mw - 32 - 16 - 230 - 10 - 110 - 14) - sx;
        draw_text(sx, by + bar_h * 0.5, ui_fit_text(string(T.trades) + " trade" + ((T.trades == 1) ? "" : "s") + " of up to 3  -  you have " + string(pl.energy) + (enough ? "" : "  -  too many items"), hint_w));
    }
    var sell_ok = can_act && T.units > 0 && enough;
    var why = !at_town ? "Travel to Town to sell." : ((T.units == 0) ? "Pick something to sell first." : ("Need " + string(T.energy) + " energy - you have " + string(pl.energy) + "."));
    ui_action_button(state, mx0 + mw - 32 - 16 - 230, by + 10, 230, bar_h - 20, (T.units > 0) ? ("Sell for " + string(T.gold) + "g") : "Sell", sell_ok, "success", "Enter", "@sell_cart", {},
        "Sell everything picked for " + string(T.gold) + " Gold (" + string(T.energy) + " energy).", why, mx, my);
    ui_action_button(state, mx0 + mw - 32 - 16 - 230 - 10 - 110, by + 10, 110, bar_h - 20, "Clear", T.units > 0, "ghost", "", "@cart_clear", {}, "Empty the sale.", "", mx, my);
    draw_set_font(fnt_body);
}

// =============================================================================
// WORKSHOP
// =============================================================================
function ui_workshop_layout(mx0, my0, mw, mh) {
    return { lx: mx0 + 32, lw: 560, ly: my0 + 160, lh: mh - 160 - 30, rx: mx0 + 612, rw: mw - 612 - 32 };
}

function ui_draw_workshop(state, mx, my, mx0, my0, mw, mh) {
    var pl = game_local_player(state);
    var at_ws = (pl.node == "workstation");
    var cost_e = game_task_cost(pl);
    var can_act = at_ws && state.phase == "player_actions" && pl.energy >= cost_e && !(state.is_online && pl.ended_turn);
    var not_here = "Travel to the Workstation first.";
    var no_energy = "Need " + string(cost_e) + " energy.";
    var gate = !at_ws ? not_here : no_energy;
    var eng = (pl.character.id == "engineer") ? 1 : 0;
    ui_facility_header(state, mx0, my0, mw, "WORKSHOP", "Forge blueprints onto towers, repair the base and fortify it." + (eng ? "  Engineer bonus: repairs restore +1 HP." : ""), C_ACCENT, at_ws, "Workstation");
    var Lw = ui_workshop_layout(mx0, my0, mw, mh);

    // ---------------- Left: blueprints ----------------
    ui_section_label(Lw.lx, Lw.ly - 18, "Blueprints owned (" + string(array_length(state.blueprints)) + ")");
    var view_h = Lw.lh;
    var nbp = array_length(state.blueprints);
    state.workstation_bp_thumb_hover = false;
    if (nbp == 0) {
        ui_box(Lw.lx, Lw.ly, Lw.lx + Lw.lw, Lw.ly + view_h, C_BG1, C_LINE, 12);
        ui_icon_weapon(Lw.lx + Lw.lw * 0.5, Lw.ly + view_h * 0.5 - 50, "turret", 64, C_FAINT);
        draw_set_font(fnt_h3); draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_set_color(C_DIM);
        draw_text(Lw.lx + Lw.lw * 0.5, Lw.ly + view_h * 0.5 + 10, "No blueprints yet");
        draw_set_font(fnt_body);
        draw_set_color(C_FAINT);
        draw_text_ext(Lw.lx + Lw.lw * 0.5, Lw.ly + view_h * 0.5 + 44, "Buy them at the Shop with Gold, then come back here to forge them onto a tower.", -1, Lw.lw - 80);
    } else {
        var card_h = 176, card_gap = 10;
        var total = nbp * (card_h + card_gap) - card_gap;
        var max_scroll = max(0, total - view_h);
        state.workstation_bp_max_scroll = max_scroll;
        state.workstation_bp_scroll_y = clamp(state.workstation_bp_scroll_y, 0, max_scroll);
        var sy = ui_anim("ws_scroll", state.workstation_bp_scroll_y, 0.3);
        var surf_w = Lw.lw, surf_h = view_h;
        if (is_undefined(state[$ "workstation_bp_surf"]) || !surface_exists(state.workstation_bp_surf)) state.workstation_bp_surf = surface_create(surf_w, surf_h);
        else if (surface_get_width(state.workstation_bp_surf) != surf_w || surface_get_height(state.workstation_bp_surf) != surf_h) { surface_free(state.workstation_bp_surf); state.workstation_bp_surf = surface_create(surf_w, surf_h); }
        var in_view = ui_point_in_rect(mx, my, Lw.lx, Lw.ly, Lw.lw, view_h);
        var lmx = in_view ? mx - Lw.lx : -9999;
        var lmy = in_view ? my - Lw.ly : -9999;
        var inner_w = (max_scroll > 0) ? surf_w - 16 : surf_w;
        surface_set_target(state.workstation_bp_surf);
        draw_clear_alpha(c_black, 0);
        for (var b = 0; b < nbp; b++) {
            var bp = state.blueprints[b];
            var by = b * (card_h + card_gap) - sy;
            if (by + card_h < 0 || by > surf_h) continue;
            var mats_ok = game_storage_has(state, bp.cost_res);
            var is_starter = bp[$ "starter"] ?? false;
            var starter_col = make_color_rgb(205, 140, 70);
            ui_box(0, by, inner_w, by + card_h, is_starter ? make_color_rgb(34, 28, 22) : C_RAISED, is_starter ? starter_col : (mats_ok ? C_LINE_HI : C_LINE), 12);
            if (is_starter) {
                draw_set_color(starter_col);
                draw_roundrect_ext(1, by + 1, inner_w - 1, by + card_h - 1, 12, 12, true);
                ui_pill(inner_w - 176, by + 12, "STARTER - REUSABLE", make_color_rgb(60, 40, 18), starter_col, starter_col, 22);
            }
            ui_box(10, by + 10, 86, by + 86, make_color_rgb(14, 18, 28), undefined, 10);
            ui_icon_weapon(48, by + 50, bp.catalog_id, 50, C_WEAPON);
            draw_set_font(fnt_h3); draw_set_halign(fa_left); draw_set_valign(fa_top);
            draw_set_color(C_TEXT);
            draw_text(100, by + 12, bp.name);
            draw_set_font(fnt_small);
            draw_set_color(C_FAINT);
            draw_text(100, by + 38, string(bp.hp) + " HP   -   " + ((bp.damage > 0) ? string(bp.damage) + " DMG" : "support") + "   -   " + ((bp.target_count >= 99) ? "hits all" : ((bp.target_count > 0) ? string(bp.target_count) + " target" + ((bp.target_count > 1) ? "s" : "") : "no attack")));
            ui_cost_chips(state, 100, by + 72, bp.cost_res);
            // Mount buttons
            var mbw = floor((inner_w - 20 - 24) / 4);
            for (var t = 0; t < 4; t++) {
                var tw = state.towers[t];
                var occupied = !is_undefined(tw.weapon) && tw.weapon.alive && tw.weapon.hp > 0;
                var ok = can_act && mats_ok && tw.alive && !occupied;
                var lbl = "Tower " + string(t + 1);
                if (!tw.alive) lbl = "T" + string(t + 1) + " lost";
                else if (occupied) lbl = "T" + string(t + 1) + " full";
                var why = !tw.alive ? ("Tower " + string(t + 1) + " is destroyed.") : (occupied ? ("Tower " + string(t + 1) + " already has a " + tw.weapon.name + " - demolish it there first (you get materials back).") : (!mats_ok ? "Missing materials in storage." : gate));
                ui_action_button(state, 10 + t * (mbw + 8), by + card_h - 56, mbw, 44, lbl, ok, is_starter ? "amber" : "primary", "", "craft_bp", { bp: b, tower: t },
                    "Forge the " + bp.name + " onto Tower " + string(t + 1) + " (" + string(cost_e) + " energy)." + (is_starter ? " You keep this blueprint." : ""), why, lmx, lmy);
            }
        }
        surface_reset_target();
        draw_surface(state.workstation_bp_surf, Lw.lx, Lw.ly);
        if (max_scroll > 0) {
            var tx = Lw.lx + Lw.lw - 8;
            draw_set_color(C_BG1);
            draw_roundrect_ext(tx, Lw.ly, tx + 6, Lw.ly + view_h, 3, 3, false);
            var th = max(40, view_h * view_h / total);
            var thy = Lw.ly + (state.workstation_bp_scroll_y / max_scroll) * (view_h - th);
            var thov = point_in_rectangle(mx, my, tx - 6, thy, tx + 12, thy + th);
            state.workstation_bp_thumb_hover = thov;
            state.workstation_bp_usable_track = max(1, view_h - th);
            draw_set_color((thov || state.workstation_bp_drag) ? C_ACCENT : C_LINE_HI);
            draw_roundrect_ext(tx, thy, tx + 6, thy + th, 3, 3, false);
        }
    }

    // ---------------- Right: fabrication ----------------
    var rx = Lw.rx, rw = Lw.rw;
    var fy = Lw.ly;
    ui_section_label(rx, fy - 18, "Fabrication");
    ui_box(rx, fy, rx + rw, fy + 64, C_RAISED, C_LINE, 12);
    ui_icon_resource(rx + 30, fy + 32, "metal", 30);
    draw_set_font(fnt_bold); draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_set_color(C_TEXT);
    draw_text(rx + 56, fy + 20, "Forge Metal");
    ui_cost_chips(state, rx + 56, fy + 44, { stone: 1, scrap: 1 });
    var fm_ok = can_act && state.storage.stone >= 1 && state.storage.scrap >= 1;
    ui_action_button(state, rx + rw - 170, fy + 12, 158, 40, "Forge  " + string(cost_e) + "E", fm_ok, "primary", "C", "craft_metal", {},
        "Turn 1 Stone + 1 Scrap into 1 Metal.", (state.storage.stone < 1 || state.storage.scrap < 1) ? "Need 1 Stone and 1 Scrap in storage." : gate, mx, my);

    // ---------------- Right: towers ----------------
    var ty0 = fy + 98;
    ui_section_label(rx, ty0 - 18, "Towers & mounted weapons");
    var row_h = 112, row_gap = 8;
    var rb_cost = game_tower_rebuild_cost();
    var rf_cost = game_tower_reinforce_cost();
    for (var t = 0; t < 4; t++) {
        var tw = state.towers[t];
        var ry = ty0 + t * (row_h + row_gap);
        ui_box(rx, ry, rx + rw, ry + row_h, tw.alive ? C_RAISED : make_color_rgb(30, 14, 20), tw.alive ? C_LINE : C_BAD_D, 12);
        draw_set_font(fnt_bold); draw_set_halign(fa_left); draw_set_valign(fa_middle);
        draw_set_color(tw.alive ? C_TEXT : C_BAD);
        draw_text(rx + 16, ry + 20, "TOWER " + string(t + 1));
        if (tw[$ "rebuilt"] ?? false) { draw_set_font(fnt_small); draw_set_color(C_FAINT); draw_text(rx + 100, ry + 21, "rebuilt"); }
        if (!tw.alive) {
            var can_rb = can_act && !(tw[$ "rebuilt"] ?? false) && game_storage_has(state, rb_cost);
            if (tw[$ "rebuilt"] ?? false) {
                draw_set_font(fnt_body);
                draw_set_color(C_FAINT);
                draw_text(rx + 16, ry + 64, "Destroyed again - a tower can only be rebuilt once.");
            } else {
                ui_cost_chips(state, rx + 16, ry + 62, rb_cost);
                ui_action_button(state, rx + rw - 190, ry + 42, 176, 44, "Rebuild  " + string(cost_e) + "E", can_rb, "success", "", "rebuild_tower", { tower: t },
                    "Raise Tower " + string(t + 1) + " from the ruins at full integrity. Each tower can only be rebuilt once.",
                    game_storage_has(state, rb_cost) ? gate : ("Rebuilding needs " + game_cost_string(rb_cost) + "."), mx, my);
            }
            continue;
        }
        var hp_col = (tw.hp / tw.max_hp > 0.5) ? C_TOWER : ((tw.hp / tw.max_hp > 0.25) ? C_WARN : C_BAD);
        ui_bar(rx + 110, ry + 14, rw - 200, 12, tw.hp / tw.max_hp, hp_col, tw.max_hp);
        draw_set_font(fnt_small); draw_set_halign(fa_right);
        draw_set_color(hp_col);
        draw_text(rx + rw - 16, ry + 20, string(tw.hp) + "/" + string(tw.max_hp));
        // Repair / reinforce buttons
        var full = tw.hp >= tw.max_hp;
        var bw = floor((rw - 32 - 16) / 3);
        var by = ry + 38;
        var r1_ok = can_act && !full && state.storage.stone >= 1 && state.storage.wood >= 1;
        ui_action_button(state, rx + 16, by, bw, 34, "+" + string(1 + eng) + " HP", r1_ok, "default", "", "repair_tower", { tower: t, method: "stone_wood" },
            "Patch Tower " + string(t + 1) + " with 1 Stone + 1 Wood.", full ? "Already at full integrity." : ((state.storage.stone < 1 || state.storage.wood < 1) ? "Needs 1 Stone + 1 Wood." : gate), mx, my);
        var r3_have = state.storage.metal >= 1 || (state.storage.scrap >= 1 && state.storage.stone >= 1);
        var r3_ok = can_act && !full && r3_have;
        ui_action_button(state, rx + 16 + bw + 8, by, bw, 34, "+" + string(3 + eng) + " HP", r3_ok, "default", "", "repair_tower", { tower: t, method: "metal_or_scrap_stone" },
            "Fortify Tower " + string(t + 1) + " with 1 Metal (or 1 Scrap + 1 Stone).", full ? "Already at full integrity." : (!r3_have ? "Needs 1 Metal, or 1 Scrap + 1 Stone." : gate), mx, my);
        var rf_ok = can_act && game_storage_has(state, rf_cost);
        ui_action_button(state, rx + 16 + 2 * (bw + 8), by, bw, 34, "+5 Max HP", rf_ok, "primary", "", "reinforce_tower", { tower: t },
            "Reinforce Tower " + string(t + 1) + ": +5 max integrity for " + game_cost_string(rf_cost) + ".",
            game_storage_has(state, rf_cost) ? gate : ("Reinforcing needs " + game_cost_string(rf_cost) + "."), mx, my);
        // Mounted weapon
        var w = tw.weapon;
        var wy = ry + 92;
        if (is_undefined(w) || !w.alive) {
            draw_set_font(fnt_small); draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(C_FAINT);
            draw_text(rx + 16, wy, "No weapon mounted");
        } else {
            ui_icon_weapon(rx + 26, wy, w.catalog_id, 18, C_WEAPON);
            draw_set_font(fnt_small); draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_set_color(C_TEXT);
            draw_text(rx + 42, wy, w.name);
            ui_bar(rx + 190, wy - 3, 120, 7, w.hp / max(1, w.max_hp), C_WEAPON);
            draw_set_color(C_WEAPON);
            draw_text(rx + 318, wy, string(w.hp) + "/" + string(w.max_hp));
            var wfull = w.hp >= w.max_hp;
            var has_mat = false;
            var rn = variable_struct_get_names(w.cost_res);
            for (var q = 0; q < array_length(rn); q++) if (state.storage[$ rn[q]] >= 1) has_mat = true;
            ui_action_button(state, rx + rw - 150, wy - 14, 136, 28, "Repair +" + string(2 + eng), can_act && !wfull && has_mat, "default", "", "repair_weapon", { tower: t },
                "Repair the " + w.name + " using 1 of its blueprint materials.", wfull ? "Weapon is at full health." : (!has_mat ? "Needs 1 of its blueprint materials in storage." : gate), mx, my);
        }
    }
    draw_set_font(fnt_body);
}
