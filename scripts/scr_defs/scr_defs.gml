/// Balance: constants, unit and structure stats, sides and missions.

#macro CELL 32
#macro HALF 16
#macro GUI_W 1280
#macro GUI_H 720
#macro TOP_H 28
#macro SIDE_X 1024
#macro VIEW_W 512
#macro VIEW_H 346
#macro ZOOM 2
#macro T_SAND 0
#macro T_ROCK 1
#macro T_CRAG 2
// "lumen" is the code name for Orichalcum, the crystal resource.
#macro LUMEN_MAX 300
#macro PLAYER 0
#macro DEPTH_BASE 5000

function defs_init()
{
    // Units. Ranges and sight are in cells; speeds in pixels per frame; reload in frames.
    global.udef = {
        trooper:   { name: "Rifle Squad",    kind: "inf", hp: 45,  spd: 0.5,  turn: 360, range: 3,   minr: 0,   dmg: 5,  reload: 32,  weapon: "bullet",    sight: 4, cost: 90,  tech: 1, at: "barracks", needs: [],                    spr: spr_trooper,   tur: -1,                  radius: 4,  squad: 3, cameo: 8,  desc: "Three riflemen. Cheap, quick to train, good against infantry." },
        rocketeer: { name: "Rocket Trooper", kind: "inf", hp: 40,  spd: 0.45, turn: 360, range: 4.5, minr: 0,   dmg: 30, reload: 100, weapon: "rocket",    sight: 5, cost: 120, tech: 2, at: "barracks", needs: ["radar"],             spr: spr_rocketeer, tur: -1,                  radius: 4,  squad: 1, cameo: 9,  desc: "Shoulder rockets. Slow to reload, deadly to vehicles." },
        buggy:     { name: "Dune Raider",    kind: "veh", hp: 130, spd: 1.9,  turn: 7,   range: 3.5, minr: 0,   dmg: 6,  reload: 14,  weapon: "bullet",    sight: 5, cost: 260, tech: 1, at: "factory",  needs: [],                    spr: spr_buggy,     tur: -1,                  radius: 8,  squad: 1, cameo: 10, desc: "A fast four-wheel scout with a machine gun." },
        tank:      { name: "Warden Tank",    kind: "veh", hp: 320, spd: 1.0,  turn: 3,   range: 4.2, minr: 0,   dmg: 28, reload: 64,  weapon: "shell",     sight: 5, cost: 520, tech: 2, at: "factory",  needs: [],                    spr: spr_tank,      tur: spr_tank_turret,     radius: 10, squad: 1, cameo: 11, desc: "The main battle tank. Armoured, with a turning turret." },
        launcher:  { name: "Lancer",         kind: "veh", hp: 160, spd: 0.9,  turn: 3,   range: 8,   minr: 2.5, dmg: 40, reload: 150, weapon: "artillery", sight: 5, cost: 700, tech: 3, at: "factory",  needs: ["radar"],             spr: spr_launcher,  tur: spr_launcher_turret, radius: 10, squad: 1, cameo: 12, desc: "Long-range rocket carrier. Fragile up close." },
        heavy:     { name: "Bastion",        kind: "veh", hp: 600, spd: 0.65, turn: 2,   range: 4.6, minr: 0,   dmg: 34, reload: 80,  weapon: "shell",     sight: 5, cost: 950, tech: 3, at: "factory",  needs: ["radar"],             spr: spr_heavy,     tur: spr_heavy_turret,    radius: 12, squad: 1, cameo: 13, shots: 2, desc: "Heavy twin-cannon tank. Slow and very hard to stop." },
        harvester: { name: "Harvester",      kind: "veh", hp: 500, spd: 0.8,  turn: 3,   range: 0,   minr: 0,   dmg: 0,  reload: 0,   weapon: "",          sight: 3, cost: 650, tech: 1, at: "factory",  needs: ["refinery"],          spr: spr_harvester, tur: -1,                  radius: 13, squad: 1, cameo: 14, desc: "Gathers Orichalcum and brings it to a Refinery." }
    };
    // Structures. Sizes in cells. Power: positive makes, negative uses.
    global.bdef = {
        yard:     { name: "Command Yard",  w: 2, h: 2, hp: 1500, cost: 1000, power: 0,   tech: 9, needs: [],           spr: spr_b_yard,     cameo: 15, sight: 5, desc: "Builds every structure. Protect it." },
        power:    { name: "Power Core",    w: 2, h: 2, hp: 650,  cost: 300,  power: 100, tech: 1, needs: [],           spr: spr_b_power,    cameo: 0,  sight: 3, desc: "Makes 100 power. Low power slows building and turrets." },
        refinery: { name: "Refinery",      w: 3, h: 2, hp: 1000, cost: 900,  power: -30, tech: 1, needs: ["power"],    spr: spr_b_refinery, cameo: 1,  sight: 4, desc: "Turns Orichalcum into credits. Comes with a Harvester." },
        barracks: { name: "Barracks",      w: 2, h: 2, hp: 650,  cost: 300,  power: -15, tech: 1, needs: ["power"],    spr: spr_b_barracks, cameo: 2,  sight: 3, desc: "Trains infantry." },
        factory:  { name: "Motor Works",   w: 3, h: 2, hp: 1100, cost: 800,  power: -30, tech: 1, needs: ["refinery"], spr: spr_b_factory,  cameo: 3,  sight: 3, desc: "Builds vehicles." },
        radar:    { name: "Radar Post",    w: 2, h: 2, hp: 700,  cost: 600,  power: -35, tech: 2, needs: ["factory"],  spr: spr_b_radar,    cameo: 4,  sight: 7, desc: "Turns on the map. Unlocks advanced units." },
        gun:      { name: "Gun Turret",    w: 1, h: 1, hp: 450,  cost: 220,  power: -10, tech: 1, needs: ["barracks"], spr: spr_b_gun,      cameo: 5,  sight: 5, weapon: "shell",  range: 5, dmg: 16, reload: 40, tur: spr_gun_head,    desc: "Short-range cannon turret." },
        rocket:   { name: "Rocket Tower",  w: 1, h: 1, hp: 550,  cost: 450,  power: -25, tech: 2, needs: ["radar"],    spr: spr_b_rocket,   cameo: 6,  sight: 7, weapon: "rocket", range: 7, dmg: 30, reload: 85, tur: spr_rocket_head, desc: "Long-range rocket tower." },
        wall:     { name: "Wall",          w: 1, h: 1, hp: 350,  cost: 25,   power: 0,   tech: 1, needs: ["power"],    spr: spr_b_wall,     cameo: 7,  sight: 1, desc: "Blocks the way. Cheap." }
    };
    global.build_list = ["power", "refinery", "barracks", "factory", "radar", "gun", "rocket", "wall"];
    global.inf_list = ["trooper", "rocketeer"];
    global.veh_list = ["buggy", "tank", "launcher", "heavy", "harvester"];

    // Every faction that can appear on a map. Index = side number (used for colours and names).
    // Blue and Red are the playable sides with full campaigns; Green and the Palatinate appear as
    // AI sides on some maps (later, short campaigns of their own). Missions never name a side by
    // index: they say "player", "opponent" or a side id, and pick alliances per map.
    global.sides = [
        { id: "blue",       name: "Blue",       col: make_colour_rgb(70, 132, 236) },
        { id: "red",        name: "Red",        col: make_colour_rgb(214, 60, 48) },
        { id: "green",      name: "Green",      col: make_colour_rgb(64, 186, 96) },
        { id: "palatinate", name: "Palatinate", col: make_colour_rgb(150, 84, 196) }
    ];
    global.playable = [0, 1];
    global.difficulties = ["Easy", "Normal", "Hard"];
}

/// How much of a weapon's damage gets through each kind of armour.
function dmg_mod(_weapon, _armor)
{
    switch (_weapon)
    {
        case "bullet":    return (_armor == "inf") ? 1.0 : ((_armor == "veh") ? 0.3 : 0.2);
        case "shell":     return (_armor == "inf") ? 0.55 : ((_armor == "veh") ? 1.0 : 0.8);
        case "rocket":    return (_armor == "inf") ? 0.4 : ((_armor == "veh") ? 1.2 : 0.9);
        case "artillery": return (_armor == "inf") ? 1.0 : ((_armor == "veh") ? 0.8 : 1.2);
    }
    return 1;
}

/// The side number for a side id ("blue", "red", "green", "palatinate"), or -1.
function side_find(_id)
{
    for (var _k = 0; _k < array_length(global.sides); _k++) if (global.sides[_k].id == _id) return _k;
    return -1;
}

/// The main rival of a playable side: the other playable side (Blue <-> Red).
function side_opponent(_side)
{
    var _i = array_get_index(global.playable, _side);
    if (_i < 0) return global.playable[0];
    return global.playable[(_i + 1) mod array_length(global.playable)];
}

/// Who a mission force is: "player", "opponent" (the player's rival) or a side id.
function side_resolve(_who)
{
    if (_who == "player") return global.player_side;
    if (_who == "opponent") return side_opponent(global.player_side);
    return side_find(_who);
}

/// A mission value that may differ by the player's side: a plain value, or a struct keyed by side id.
function by_side(_v)
{
    if (is_struct(_v)) return _v[$ global.sides[global.player_side].id];
    return _v;
}

// Missions. Each force is one side on the map: side ("player", "opponent" or a side id) and ally
// (forces with the same ally number fight together). The player's force becomes team 0.
//   rules "claim": take and hold the Orichalcum zone, or wipe out the enemy army (scr_claim).
//   rules "destroy": destroy every enemy structure.
// layout "duel": a small mirrored map for two forces (slot 0 bottom-left, slot 1 top-right),
// with a base built from base_plan; layout "random": the older generated maps with Command Yards.
function missions_init()
{
    global.missions = [
        {
            id: "claim", title: "First Claim", campaign: true, needs: "",
            rules: "claim", build: false, layout: "duel",
            w: 33, h: 33, seed: 2026, tech: 1, credits: 0,
            look: { blue: "forest", red: "desert" }, pic: { blue: 0, red: 1 },
            zone: { r: 3.6, capture: 10, hold: 60 },
            // [type, cell x, cell y] for slot 0; slot 1 gets the same base turned half way round.
            base_plan: [["power", 4, 25], ["radar", 4, 28], ["gun", 8, 22], ["wall", 7, 22], ["wall", 9, 22], ["gun", 11, 26], ["wall", 11, 25], ["wall", 11, 27]],
            home: { cx: 7, cy: 26 },
            forces: [
                { side: "player", ally: 0, slot: 0, units: ["trooper", "trooper", "trooper", "buggy"] },
                { side: "opponent", ally: 1, slot: 1, units: ["trooper", "trooper", "trooper", "buggy"], ai: "zone" }
            ],
            speaker: { blue: "RELAY: BLUE FIELD COMMANDER", red: "RELAY: RED FIELD COMMANDER" },
            brief: {
                blue: "Ten years of running, Commander. Tonight we stop.\n\nUnder this canopy lies an Orichalcum seam the regime has not taken yet. Whoever holds it can pay for ships, for arms, for an army worth the name. Red's survey team found it too: they came down on the far side of the forest within the hour.\n\nThe drop brought what it could: three rifle squads, one Dune Raider and a post with two guns. No factory, no reinforcements. Every soldier you lose is gone, so spend them like your own blood.\n\nThe field is in the clearing at the centre. Stand there alone for ten seconds to plant our claim, then keep every Red soldier out of the ring for one full minute. Or finish their landing party to the last soldier. The prince is watching this one. So am I.",
                red: "Commander. The survey is confirmed: one Orichalcum field, in the basin between the ridges. The only one on this world.\n\nThe exiles have found it too; their landing party set down across the basin within the hour. A pretender with a treasury becomes a war. A pretender without one stays a rumour. Deny him.\n\nYou have three rifle squads, one Dune Raider and a forward post with two guns. There will be no resupply. Command judges its officers by what they do with what they are given.\n\nOccupy the field alone for ten seconds to plant our marker. Then hold it: one minute with no exile inside the ring. Or destroy their landing party entirely. Order is not given, Commander. It is taken."
            },
            objective: "Take the Orichalcum field and hold it for 60 seconds, or destroy the enemy army.",
            kit_title: "YOUR FORCES",
            unlocks: "3 Rifle Squads, 1 Dune Raider. A post with a Power Core, a Radar and 2 Gun Turrets. No building, no reinforcements."
        },
        {
            id: "ridge", title: "Hold the Ridge", campaign: false, needs: "claim",
            rules: "destroy", build: true, layout: "random",
            w: 64, h: 64, seed: 9917, tech: 2, credits: 2000, fields: 9, outcrops: 11,
            look: "desert", pic: 2,
            forces: [
                { side: "player", ally: 0, cx: 10, cy: 53, yard: true, units: ["trooper", "buggy", "buggy", "tank"] },
                { side: "opponent", ally: 1, cx: 53, cy: 11, yard: true, ai: "waves",
                  base: ["power", "refinery", "barracks", "power", "factory", "gun", "gun", "radar"],
                  order: ["power", "refinery", "barracks", "power", "factory", "gun", "gun", "radar", "power", "rocket", "gun", "refinery"],
                  units: ["tank", "tank", "trooper", "trooper", "buggy", "rocketeer"],
                  mix: { trooper: 3, rocketeer: 2, buggy: 2, tank: 4 },
                  first_wave: 240, wave_every: 150, wave: 4, wave_grow: 2, wave_max: 12, credits: 1500 }
            ],
            speaker: "K-7  FIELD ADVISOR",
            brief: "{opponent} wants the ridge fields for itself. Their base sits across the valley, behind a line of turrets.\n\nBuild a base, harvest the Orichalcum, hold your fields, then go and take theirs. The Radar Post, the Rocket Tower and the Warden tank are ready.\n\nDestroy every {opponent} structure.",
            objective: "Destroy all enemy structures.",
            kit_title: "EQUIPMENT",
            unlocks: "Base building. Radar Post, Rocket Tower, Rocket Trooper, Warden Tank."
        },
        {
            id: "ashfall", title: "Ashfall", campaign: false, needs: "claim",
            rules: "destroy", build: true, layout: "random",
            w: 72, h: 72, seed: 31337, tech: 3, credits: 2500, fields: 12, outcrops: 14,
            look: "desert", pic: 3,
            forces: [
                { side: "player", ally: 0, cx: 10, cy: 61, yard: true, units: ["tank", "tank", "trooper", "trooper", "buggy"] },
                { side: "opponent", ally: 1, cx: 61, cy: 10, yard: true, ai: "waves",
                  base: ["power", "refinery", "barracks", "power", "factory", "gun", "rocket", "radar", "gun"],
                  order: ["power", "refinery", "barracks", "power", "factory", "radar", "gun", "rocket", "power", "gun", "rocket", "refinery", "power"],
                  units: ["tank", "tank", "launcher", "trooper", "rocketeer", "heavy"],
                  mix: { trooper: 2, rocketeer: 2, buggy: 1, tank: 4, launcher: 2, heavy: 2 },
                  first_wave: 270, wave_every: 150, wave: 5, wave_grow: 2, wave_max: 14, credits: 2000 },
                { side: "green", ally: 1, cx: 61, cy: 58, yard: true, ai: "waves",
                  base: ["power", "refinery", "barracks", "factory", "gun", "power", "gun"],
                  order: ["power", "refinery", "barracks", "factory", "power", "gun", "gun", "radar", "rocket", "power"],
                  units: ["tank", "buggy", "buggy", "trooper", "trooper"],
                  mix: { trooper: 3, rocketeer: 1, buggy: 3, tank: 3, launcher: 1 },
                  first_wave: 330, wave_every: 170, wave: 4, wave_grow: 2, wave_max: 12, credits: 1500 }
            ],
            speaker: "K-7  FIELD ADVISOR",
            brief: "Ashfall. Two camps are closing in on us from the east: {opponent}, and Green, whose merchant lords have decided this week that {opponent} pays better.\n\nThe Lancer rocket carrier and the Bastion heavy tank are ready. Use the Lancers from behind your tanks.\n\nBreak both bases, Commander. Then this sector is ours.",
            objective: "Destroy all structures of both enemy camps.",
            kit_title: "EQUIPMENT",
            unlocks: "Everything, including the Lancer and the Bastion."
        }
    ];
}

function mission_index_of(_id)
{
    for (var _k = 0; _k < array_length(global.missions); _k++) if (global.missions[_k].id == _id) return _k;
    return -1;
}

/// Progress is kept per mission and side: "claim_blue" and so on.
function progress_key(_m_index, _side)
{
    return global.missions[_m_index].id + "_" + global.sides[_side].id;
}

function mission_won(_m_index, _side)
{
    return global.done[$ progress_key(_m_index, _side)] ?? false;
}

/// A mission is open when the mission it needs has been won with either playable side.
function mission_open(_m_index)
{
    var _need = global.missions[_m_index].needs;
    if (_need == "") return true;
    var _n = mission_index_of(_need);
    for (var _k = 0; _k < array_length(global.playable); _k++) if (mission_won(_n, global.playable[_k])) return true;
    return false;
}
