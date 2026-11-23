/// @desc Data structures and definitions for Alien Game

function game_get_map_nodes() {
    var nodes = {};
    
    nodes[$ "forest"] = { id: "forest", name: "Forest", x: 180, y: 170, type: "gather_forest", color: make_color_rgb(46, 125, 50), label: "Forest\n(Wood, Scrap)" };
    nodes[$ "town"] = { id: "town", name: "Town", x: 180, y: 510, type: "town", color: make_color_rgb(216, 112, 147), label: "Town\n(Trade / Sell)" };
    nodes[$ "empty_1"] = { id: "empty_1", name: "Empty 1", x: 380, y: 340, type: "empty", color: make_color_rgb(120, 144, 156), label: "Empty 1\n(Waypoint)" };
    nodes[$ "main_base"] = { id: "main_base", name: "Main Base", x: 740, y: 340, type: "main_base", color: make_color_rgb(33, 150, 243), label: "Main Base\n(Storage)" };
    nodes[$ "workstation"] = { id: "workstation", name: "Workstation", x: 740, y: 150, type: "workstation", color: make_color_rgb(0, 150, 136), label: "Workstation\n(Craft & Repair)" };
    nodes[$ "shop"] = { id: "shop", name: "Shop", x: 740, y: 530, type: "shop", color: make_color_rgb(255, 179, 0), label: "Shop\n(Blueprints)" };
    
    nodes[$ "tower_1"] = { id: "tower_1", name: "Tower 1", x: 570, y: 200, type: "tower", tower_idx: 0, color: make_color_rgb(66, 165, 245), label: "Tower 1" };
    nodes[$ "tower_2"] = { id: "tower_2", name: "Tower 2", x: 910, y: 200, type: "tower", tower_idx: 1, color: make_color_rgb(66, 165, 245), label: "Tower 2" };
    nodes[$ "tower_3"] = { id: "tower_3", name: "Tower 3", x: 910, y: 480, type: "tower", tower_idx: 2, color: make_color_rgb(66, 165, 245), label: "Tower 3" };
    nodes[$ "tower_4"] = { id: "tower_4", name: "Tower 4", x: 570, y: 480, type: "tower", tower_idx: 3, color: make_color_rgb(66, 165, 245), label: "Tower 4" };
    
    nodes[$ "empty_2"] = { id: "empty_2", name: "Empty 2", x: 1090, y: 340, type: "empty", color: make_color_rgb(120, 144, 156), label: "Empty 2\n(Waypoint)" };
    nodes[$ "cave_1"] = { id: "cave_1", name: "Cave 1", x: 1240, y: 340, type: "gather_cave1", color: make_color_rgb(141, 110, 99), label: "Cave 1\n(Stone, Metal)" };
    nodes[$ "cave_2"] = { id: "cave_2", name: "Cave 2", x: 1390, y: 220, type: "gather_cave2", color: make_color_rgb(109, 76, 65), label: "Cave 2\n(Metal, Gems)" };
    nodes[$ "cave_3"] = { id: "cave_3", name: "Cave 3", x: 1410, y: 460, type: "gather_cave3", color: make_color_rgb(78, 52, 46), label: "Cave 3\n(Crystals, Power Gems)" };
    
    return nodes;
}

function game_get_map_edges() {
    return [
        ["forest", "empty_1"],
        ["town", "empty_1"],
        ["empty_1", "main_base"],
        ["main_base", "shop"],
        ["main_base", "workstation"],
        ["main_base", "tower_1"],
        ["main_base", "tower_2"],
        ["main_base", "tower_3"],
        ["main_base", "tower_4"],
        ["main_base", "empty_2"],
        ["empty_2", "cave_1"],
        ["cave_1", "cave_2"],
        ["cave_2", "cave_3"]
    ];
}

function game_get_resource_definitions() {
    return {
        wood: { name: "Wood", sell_value: 2, color: make_color_rgb(139, 90, 43), icon_char: "W" },
        scrap: { name: "Scrap", sell_value: 1, color: make_color_rgb(176, 120, 80), icon_char: "S" },
        stone: { name: "Stone", sell_value: 3, color: make_color_rgb(140, 140, 140), icon_char: "T" },
        metal: { name: "Metal", sell_value: 4, color: make_color_rgb(180, 200, 215), icon_char: "M" },
        crystals: { name: "Crystals", sell_value: 5, color: make_color_rgb(79, 195, 247), icon_char: "C" },
        power_gem: { name: "Power Gem", sell_value: 8, color: make_color_rgb(224, 64, 251), icon_char: "P" },
        gold: { name: "Gold", sell_value: 1, color: make_color_rgb(255, 215, 0), icon_char: "G" }
    };
}

function game_create_deck(deck_id) {
    var deck = [];
    var add_cards = function(d, card_obj, count) {
        for (var i = 0; i < count; i++) {
            array_push(d, {
                name: card_obj.name,
                type: card_obj.type,
                resource: card_obj[$ "resource"] ?? "",
                amount: card_obj[$ "amount"] ?? 0,
                energy_delta: card_obj[$ "energy_delta"] ?? 0,
                desc: card_obj[$ "desc"] ?? ""
            });
        }
    };
    
    if (deck_id == "forest") {
        add_cards(deck, { name: "Wood x1", type: "resource", resource: "wood", amount: 1 }, 15);
        add_cards(deck, { name: "Wood x2", type: "resource", resource: "wood", amount: 2 }, 12);
        add_cards(deck, { name: "Wood x3", type: "resource", resource: "wood", amount: 3 }, 8);
        add_cards(deck, { name: "Scrap x1", type: "resource", resource: "scrap", amount: 1 }, 6);
        add_cards(deck, { name: "Scrap x3", type: "resource", resource: "scrap", amount: 3 }, 3);
        add_cards(deck, { name: "Bear Encounter", type: "event", energy_delta: -2, desc: "A wild bear attacks! Lose 2 Energy!" }, 2);
        add_cards(deck, { name: "Glowing Mushrooms", type: "event", energy_delta: 2, desc: "Nutritious alien mushrooms! Gain 2 Energy!" }, 4);
    }
    else if (deck_id == "cave_1") {
        add_cards(deck, { name: "Stone x1", type: "resource", resource: "stone", amount: 1 }, 12);
        add_cards(deck, { name: "Stone x2", type: "resource", resource: "stone", amount: 2 }, 10);
        add_cards(deck, { name: "Stone x3", type: "resource", resource: "stone", amount: 3 }, 8);
        add_cards(deck, { name: "Metal x1", type: "resource", resource: "metal", amount: 1 }, 8);
        add_cards(deck, { name: "Crystals x1", type: "resource", resource: "crystals", amount: 1 }, 6);
        add_cards(deck, { name: "Power Gem x1", type: "resource", resource: "power_gem", amount: 1 }, 2);
        add_cards(deck, { name: "Swarm of Bats", type: "event", energy_delta: -1, desc: "Screeching bats disorient you! Lose 1 Energy!" }, 4);
    }
    else if (deck_id == "cave_2") {
        add_cards(deck, { name: "Stone x1", type: "resource", resource: "stone", amount: 1 }, 4);
        add_cards(deck, { name: "Stone x2", type: "resource", resource: "stone", amount: 2 }, 6);
        add_cards(deck, { name: "Metal x1", type: "resource", resource: "metal", amount: 1 }, 12);
        add_cards(deck, { name: "Metal x2", type: "resource", resource: "metal", amount: 2 }, 10);
        add_cards(deck, { name: "Crystals x1", type: "resource", resource: "crystals", amount: 1 }, 8);
        add_cards(deck, { name: "Power Gem x1", type: "resource", resource: "power_gem", amount: 1 }, 5);
        add_cards(deck, { name: "Swarm of Bats", type: "event", energy_delta: -1, desc: "Cave bats ambush! Lose 1 Energy!" }, 5);
    }
    else if (deck_id == "cave_3") {
        add_cards(deck, { name: "Stone x1", type: "resource", resource: "stone", amount: 1 }, 2);
        add_cards(deck, { name: "Metal x1", type: "resource", resource: "metal", amount: 1 }, 4);
        add_cards(deck, { name: "Metal x2", type: "resource", resource: "metal", amount: 2 }, 4);
        add_cards(deck, { name: "Crystals x1", type: "resource", resource: "crystals", amount: 1 }, 12);
        add_cards(deck, { name: "Crystals x2", type: "resource", resource: "crystals", amount: 2 }, 10);
        add_cards(deck, { name: "Crystals x3", type: "resource", resource: "crystals", amount: 3 }, 8);
        add_cards(deck, { name: "Power Gem x1", type: "resource", resource: "power_gem", amount: 1 }, 6);
        add_cards(deck, { name: "Swarm of Bats", type: "event", energy_delta: -1, desc: "Hostile deep bats! Lose 1 Energy!" }, 4);
    }
    
    // Shuffle deck
    for (var i = array_length(deck) - 1; i > 0; i--) {
        var j = irandom(i);
        var temp = deck[i];
        deck[i] = deck[j];
        deck[j] = temp;
    }
    
    return deck;
}

function game_get_weapon_catalog() {
    return [
        {
            id: "turret",
            name: "Turret",
            hp: 12,
            damage: 4,
            cost_gold: 7,
            cost_res: { metal: 3, wood: 2 },
            ability: "Attacks 2 aliens instead of 1.",
            target_count: 2
        },
        {
            id: "flamethrower",
            name: "Flamethrower",
            hp: 8,
            damage: 3,
            cost_gold: 8,
            cost_res: { scrap: 3, metal: 2, wood: 1 },
            ability: "Attacks 3 aliens. Hit aliens take +1 dmg from other weapons this turn.",
            target_count: 3
        },
        {
            id: "railgun",
            name: "Railgun",
            hp: 8,
            damage: 20,
            cost_gold: 18,
            cost_res: { metal: 5, power_gem: 3 },
            ability: "Attacks every other wave. Overkill damage carries over to another alien.",
            target_count: 1,
            cooldown_wave: 2
        },
        {
            id: "lazer_gun",
            name: "Lazer Gun",
            hp: 10,
            damage: 3,
            cost_gold: 12,
            cost_res: { metal: 4, crystals: 3 },
            ability: "Every time this attacks, its damage increases by +1 permanently.",
            target_count: 1
        },
        {
            id: "tesla",
            name: "Tesla",
            hp: 6,
            damage: 2,
            cost_gold: 11,
            cost_res: { metal: 3, crystals: 2, power_gem: 1 },
            ability: "Hits all aliens. Hit aliens do 1 less damage on their next attack.",
            target_count: 99
        },
        {
            id: "cannon",
            name: "Cannon",
            hp: 10,
            damage: 9,
            cost_gold: 6,
            cost_res: { stone: 4, metal: 2 },
            ability: "Attacks 1 alien with heavy kinetic damage.",
            target_count: 1
        },
        {
            id: "shield_generator",
            name: "Shield Generator",
            hp: 15,
            damage: 0,
            cost_gold: 10,
            cost_res: { stone: 2, metal: 3, crystals: 2 },
            ability: "Absorbs damage meant for weapons or base. Deals 4 dmg to all aliens when broken.",
            target_count: 0
        },
        {
            id: "resource_drone",
            name: "Resource Drone",
            hp: 5,
            damage: 0,
            cost_gold: 14,
            cost_res: { scrap: 4, crystals: 2, power_gem: 1 },
            ability: "Gathers 1 random Forest or Cave 1 card when used each turn.",
            target_count: 0
        },
        {
            id: "plasma_mortar",
            name: "Plasma Mortar",
            hp: 8,
            damage: 7,
            cost_gold: 13,
            cost_res: { metal: 4, crystals: 2, power_gem: 1 },
            ability: "Deals 7 damage to primary target, and 3 damage to two additional aliens.",
            target_count: 1,
            splash_count: 2,
            splash_dmg: 3
        },
        {
            id: "overcharge_pylon",
            name: "Overcharge Pylon",
            hp: 6,
            damage: 0,
            cost_gold: 17,
            cost_res: { crystals: 3, metal: 2, power_gem: 2 },
            ability: "Buffs 2 weapons for +3 base damage this wave; manual reuse cost reduced from 2 to 1 energy.",
            target_count: 0
        },
        {
            id: "energy_pylon",
            name: "Energy Pylon",
            hp: 7,
            damage: 0,
            cost_gold: 12,
            cost_res: { crystals: 2, wood: 2, power_gem: 1 },
            ability: "Every turn, all players get +1 extra energy. Cannot attack.",
            target_count: 0
        },
        {
            id: "cryo_emitter",
            name: "Cryo Emitter",
            hp: 10,
            damage: 3,
            cost_gold: 10,
            cost_res: { metal: 2, stone: 3, crystals: 1 },
            ability: "Freezes an alien. Frozen aliens deal 0 damage on their next attack.",
            target_count: 1
        }
    ];
}

function game_create_shop_deck() {
    var catalog = game_get_weapon_catalog();
    var deck = [];
    for (var i = 0; i < array_length(catalog); i++) {
        var it = catalog[i];
        array_push(deck, {
            id: it.id,
            catalog_id: it.id,
            name: it.name,
            hp: it.hp,
            damage: it.damage,
            cost_gold: it.cost_gold,
            cost_res: it.cost_res,
            ability: it.ability,
            target_count: it.target_count,
            splash_count: it[$ "splash_count"] ?? 0,
            splash_dmg: it[$ "splash_dmg"] ?? 0
        });
    }
    // Shuffle deck
    for (var i = array_length(deck) - 1; i > 0; i--) {
        var j = irandom(i);
        var tmp = deck[i];
        deck[i] = deck[j];
        deck[j] = tmp;
    }
    return deck;
}

function game_get_alien_catalog() {
    return {
        // Tier 1
        scout: { name: "Scout", tier: 1, hp: 4, damage: 1, ability: "Must be killed before other aliens can be targeted." },
        acid_spitter: { name: "Acid Spitter", tier: 1, hp: 5, damage: 2, ability: "Deals double damage to weapons." },
        hatcher: { name: "Hatcher", tier: 1, hp: 7, damage: 1, ability: "If alive at end of turn, spawns 2 Hatchlings (2 HP, 1 Dmg)." },
        drone: { name: "Drone", tier: 1, hp: 9, damage: 3, ability: "None." },
        drooper: { name: "Drooper", tier: 1, hp: 6, damage: 1, ability: "Hits all 4 towers/weapons simultaneously." },
        hatchling: { name: "Hatchling", tier: 1, hp: 2, damage: 1, ability: "Spawned by Hatcher." },
        
        // Tier 2
        armorback: { name: "Armorback", tier: 2, hp: 12, damage: 3, ability: "All damage this unit takes is reduced by 1." },
        leech: { name: "Leech", tier: 2, hp: 8, damage: 2, ability: "When attacking, heals 2 HP (can exceed max HP)." },
        saboteur: { name: "Saboteur", tier: 2, hp: 10, damage: 4, ability: "When killed, deals 2 damage back to the weapon that killed it." },
        screamer: { name: "Screamer", tier: 2, hp: 15, damage: 2, ability: "Increases damage of every other alien by +1." },
        the_syphon: { name: "The Syphon", tier: 2, hp: 14, damage: 2, ability: "When attacking, causes a random player to lose 1 energy next turn." },
        
        // Tier 3
        goliath: { name: "Goliath", tier: 3, hp: 35, damage: 7, ability: "Ignores weapons (except Shield) and attacks a tower directly." },
        emp_weaver: { name: "EMP Weaver", tier: 3, hp: 20, damage: 4, ability: "Disables the highest-damage weapon while alive." },
        broodlord: { name: "Broodlord", tier: 3, hp: 25, damage: 5, ability: "When drawn, immediately draws and spawns two Tier 1 aliens." },
        apex_predator: { name: "Apex Predator", tier: 3, hp: 40, damage: 8, ability: "Cannot take more than 10 damage from a single attack." },
        alien_queen: { name: "Alien Queen", tier: 3, hp: 50, damage: 0, ability: "Does not attack; summons a Tier 1 and a Tier 2 alien (+3 HP) each turn." }
    };
}

function game_get_alien_tier_pool(tier) {
    if (tier == 1) return ["scout", "acid_spitter", "hatcher", "drone", "drooper"];
    if (tier == 2) return ["armorback", "leech", "saboteur", "screamer", "the_syphon"];
    if (tier == 3) return ["goliath", "emp_weaver", "broodlord", "apex_predator", "alien_queen"];
    return ["drone"];
}

function game_get_waves() {
    return [
        [],                 // Wave 1 (Grace)
        [],                 // Wave 2 (Grace)
        [1],                // Wave 3
        [],                 // Wave 4
        [1],                // Wave 5
        [1, 1],             // Wave 6
        [1, 1, 1],          // Wave 7
        [1, 1, 1, 1],       // Wave 8
        [2, 2],             // Wave 9
        [2, 1, 1],          // Wave 10
        [2, 2, 1],          // Wave 11
        [2, 2, 2],          // Wave 12
        [2, 2, 2, 1],       // Wave 13
        [3, 3],             // Wave 14
        [3, 2, 2],          // Wave 15
        [3, 3, 2],          // Wave 16
        [3, 3, 3]           // Wave 17 (Final main wave)
    ];
}

function game_get_character_classes() {
    return [
        {
            id: "default",
            name: "Survivor",
            role: "Default Operative",
            bonus_energy: 0,
            desc: "Standard Base Energy (Move costs 2 Energy). Balanced operative with standard equipment.",
            perk_tag: "Standard Base"
        },
        {
            id: "scout",
            name: "Scout",
            role: "Mobility & Recon",
            bonus_energy: 1,
            desc: "+1 Base Energy. High mobility (Move costs 1 Energy instead of 2); gathering, trading, weapons, crafting & repairs cost 2 Energy.",
            perk_tag: "+1 Base Energy | 1E Move | 2E Tasks"
        },
        {
            id: "engineer",
            name: "Combat Engineer",
            role: "Fortification & Crafting",
            bonus_energy: 0,
            desc: "Standard Base Energy (Move costs 2 Energy). Repairs restore +1 extra HP. Can craft Metal with greater efficiency.",
            perk_tag: "Standard Base | Repair +1 HP"
        },
        {
            id: "miner",
            name: "Cavern Miner",
            role: "Excavation Specialist",
            bonus_energy: -1,
            desc: "-1 Base Energy (Move costs 2 Energy). Immune to Bat energy loss. 25% chance to extract bonus mineral.",
            perk_tag: "-1 Base Energy | Bat Immunity"
        },
        {
            id: "gunner",
            name: "Gunner",
            role: "Heavy Artillery",
            bonus_energy: -1,
            desc: "-1 Base Energy (Move costs 2 Energy). Weapon specialist: firing mounted tower weapons costs only 1 Energy instead of 2.",
            perk_tag: "-1 Base Energy | 1E Fire Cost"
        },
        {
            id: "pathfinder",
            name: "Pathfinder",
            role: "Field Recon",
            bonus_energy: -1,
            desc: "-1 Base Energy. Field Recon: Moving costs only 1 Energy (instead of default 2); standard parameters for all other actions.",
            perk_tag: "-1 Base Energy | 1E Move"
        }
    ];
}

function game_get_town_favors() {
    return [
        { id: "wood", name: "Wood Favor", desc: "+1 Extra Gold per Wood sold", bonus_gold: 1, resource: "wood" },
        { id: "stone", name: "Stone Favor", desc: "+1 Extra Gold per Stone sold", bonus_gold: 1, resource: "stone" },
        { id: "metal", name: "Metal Favor", desc: "+1 Extra Gold per Metal sold", bonus_gold: 1, resource: "metal" },
        { id: "crystals", name: "Crystal Favor", desc: "+2 Extra Gold per Crystal sold", bonus_gold: 2, resource: "crystals" },
        { id: "power_gem", name: "Power Gem Favor", desc: "+4 Extra Gold per Power Gem sold", bonus_gold: 4, resource: "power_gem" }
    ];
}

