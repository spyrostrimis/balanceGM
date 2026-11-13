# Editing GameMaker project files

Do not make changes to `.yy` or `.yyp` files yourself.
It's very hard to correctly edit these manually!
You MUST use commands exposed by the `gamemaker-resource-tool` MCP server.

# GameMaker Language (GML) Guidance

Make changes to `.gml` files using your built-in tools, if you so wish.

## GML Naming conventions

- Use `snake_case` for all variables and functions
- Prefix local variables with `_` (e.g., `var _temp_value`, `var _effect`)
- Prefix resource names based on their type, e.g. obj_player, spr_player, etc.

## GML reserved names

Your own names must avoid clashing with these:

- `score`, `lives`, `health`
- Position: `x`, `y`
- Sprite: `sprite_index`, `image_index`, `image_speed`, `image_xscale`, `image_yscale`, `image_angle`, `image_alpha`, `image_blend`
- Physics: `speed`, `direction`, `friction`, `gravity`, `gravity_direction`
- Collision: `bbox_left`, `bbox_right`, `bbox_top`, `bbox_bottom`
- Instance: `id`, `object_index`, `layer`, `depth`, `visible`, `persistent`

## Modern idiomatic GML

GML has support for **structs** (dynamic objects similar to JavaScript).

```gml
var _mystruct =
{
    a : 20,
    b : "Hello World"
};

// There is support for constructor functions and methods tied to the struct too
function Vector2(_x, _y) constructor
{
    x = _x;
    y = _y;

    static Add = function(_vec2)
    {
        x += _vec2.x;
        y += _vec2.y;
    }
}

v2 = new Vector2(10, 10);
```

GML *script* files now requires one or more function definitions

```gml
// in move script
function move(spd, dir)
{
    speed = spd;
    direction = dir;
}

```

## Library Functions

- Prefer `instance_create_layer()` over deprecated `instance_create()`

# Running / debugging games

To help users debug and play games you can make use of:

```
npx @gamemaker/gm-cli compile --errors-only
npx @gamemaker/gm-cli run --errors-only
```

# This project: Balance

A real-time strategy game made in GameMaker, the user's tribute to *Dune II* (their
favourite game), in an original world. Project file `Balance.yyp`; save folder
`%LOCALAPPDATA%\Balance`. Repo: spyrostrimis/balanceGM.

**Story, factions and heroes: [docs/LORE.md](docs/LORE.md)** — read it before naming or
writing anything in the game. Factions are provisionally Blue, Red, Green and the
Palatinate/Clergy; names, insignia, units and mechanics are still open.

Tools: GameMaker LTS runtime 2026.0.0.23, gm-cli 2.4.1
(`npx @gamemaker/gm-cli compile|run|resourcetool script|manual read`).

## Where we are
Playable sides are **Blue and Red**: the player picks one on the title screen, the AI plays
the other. Green and the Palatinate are defined (name, colour) for later maps.
- **Mission 1, First Claim** (both campaigns start here): a 33×33 mirrored duel map. Blue
  plays it on a tropical forest planet, Red on a desert planet. Each side has 3 Rifle Squads,
  a Dune Raider and a small base (Power Core, Radar, 2 Gun Turrets, walls); no building, no
  reinforcements. The only Orichalcum is a field in the middle inside a capture ring: 10 s
  alone in the ring takes it, then 60 s with no enemy in the ring wins (an enemy entering
  resets the hold). Wiping out the enemy army also wins. A zone AI gathers, pushes and holds.
- **Skirmishes** Hold the Ridge and Ashfall (the old base-building missions with the wave
  AI) are locked until First Claim is won with either side. They predate the lore.
- Units, structures and the base-building rules still predate the lore. "Lumen" is the code
  name of the resource; players see "Orichalcum".
Don't take a feature for done because it compiles — ask the user to play it, and say
exactly what to look for.

## Working rules (from the user)
- Commit straight to `main`, no branches or pull requests unless asked.
- Start the game for the user with `npx @gamemaker/gm-cli run` as a **background** command
  while developing, so crash reports (`FATAL ERROR`, `ERROR in action`) reach you when the
  process exits; then fix them.
- Never inject mouse or keyboard input into the user's desktop (it once clicked into their
  video player). Test with the self-test mode below instead.
- Keep names, art and characters original; *Dune II* (Westwood/Electronic Arts) is the
  inspiration only.

## Code map
- `scripts/scr_defs` — macros (CELL 32, GUI 1280×720, TOP_H 28, SIDE_X 1024, VIEW 512×346,
  ZOOM 2, terrain types, LUMEN_MAX 300, PLAYER 0, DEPTH_BASE 5000), `global.udef` (unit
  stats), `global.bdef` (building stats), `dmg_mod`, `global.sides` (blue, red, green,
  palatinate) and `global.playable`, `side_resolve`/`side_opponent`/`by_side`, missions
  and progress (`progress_key`, `mission_open`).
- **Missions** never name a side by index. Each has `forces`: `side` is `"player"`,
  `"opponent"` (the other playable side) or a side id, and `ally` groups forces that fight
  together (per-map alliances; `hostile(a, b)` in `scr_game` compares `team.ally`). The
  player's force is always team 0. Values that differ by side (`look`, `pic`, `brief`,
  `speaker`) are structs keyed by side id, read with `by_side`. `layout` "duel" (mirrored
  map + `base_plan`) or "random" (old generator + Command Yards); `rules` "claim" or
  "destroy"; `build: false` hides the build queues.
- `scr_map` (generation incl. `map_gen_duel`, tilemaps per `global.look` — desert or
  forest tilesets, shroud, `nearest_free_cell`), `scr_claim` (First Claim: zone rules,
  zone drawing on map/minimap/HUD/sidebar, the zone AI `ai_zone_step`), `scr_units` (paths,
  `unit_step`, harvester state machine, `deal_damage`), `scr_buildings` (`can_place`,
  `place_building`, turrets, sell), `scr_production` (teams: `ally`, `home_cx/cy`),
  `scr_ai` (the wave AI of the skirmishes), `scr_game` (mission flow, orders, input,
  self-test), `scr_ui` (title, briefing, sidebar, minimap, pause/end, cursor,
  window-size buttons), `scr_fx`, `scr_sfx` (sound made in code).
- Objects: `obj_game` (Create, Step, Draw, Draw GUI, Post Draw, CleanUp), `obj_unit`,
  `obj_building`, `obj_proj`, `obj_ground`.
- Display: the world draws into a 512×346 application surface, scaled up in Post Draw
  (`global.view_s/view_ox/view_oy`); the GUI is laid out at 1280×720 with
  `display_set_gui_maximise`. Team colours: shader `sh_team` swaps magenta for the side
  colour. Shroud: a one-pixel-per-cell surface drawn with a multiply blend and linear
  filtering. Pathing: `mp_grid`, separate vehicle and infantry grids (crags block vehicles).

## Self-test
Set `BALANCE_TEST=1|2|3` (mission), optionally `BALANCE_TEST_SIDE=blue|red` and
`BALANCE_TEST_FRAMES=N` before `gm-cli run`: the game plays that mission by itself at high
speed, saves screenshots and a log to `%LOCALAPPDATA%\Balance`, then quits. In First Claim
the player's side is played by the zone AI too. Look at the screenshots — that's how to
check visuals without the user. The self-test doesn't save progress or settings.
`BALANCE_TEST_ENEMY_DELAY=N` holds the opponent AI back N seconds, so the capture, hold
and hold-reset path gets exercised (with ~45 the player takes the ring, then Red arrives).

## Art pipeline
Art is drawn in code: `art_src/make_art.js` (terrain pixel by pixel, the rest as SVG
rendered with sharp) writes `art_src/png/<sprite>/<i>.png` + `manifest.json`.
- `node art_src/make_art.js <path to sharp>` — sharp was found at
  `C:/Users/PC/AppData/Local/npm-cache/_npx/32026684e21afda6/node_modules/sharp`
  (npx cache; reinstall if it's gone).
- `node art_src/import_art.js --refresh [spr_...]` — copies new frames over existing
  sprites and refreshes the tileset images (`tilesets/ts_*/output_tileset.png`); no `.yy`
  changes.
- `node art_src/import_art.js [spr_...] > import.txt` then
  `npx @gamemaker/gm-cli resourcetool script import.txt` — creates new sprites.

Forest look: `spr_terrain_forest`/`ts_terrain_forest` (jungle floor and laterite clearings)
and `spr_crag_forest`/`ts_crag_forest` (thickets), same tile layout as the desert sheets.

## Gotchas met so far
- In the Bash tool, a heredoc containing an apostrophe fails to parse; write scripts to a
  file instead.
- Tilesets created by the resource tool had `out_columns`/`tile_count` 0 and no output
  image: set them with RESOURCE SET (borders 0) and copy the PNG to `output_tileset.png`.
- A room's default Background layer hid the world — it was deleted.
- `view_camera[0]` is set every step.
- `resize_window` and `executable_name` options are read-only in the resource tool; the
  user can turn on drag-resizing in the IDE (Game Options → Windows).
- The file sandbox only allows writing in the save area; `screen_save` crops, so screenshots
  are taken from a surface.
- Instances can vanish between frames: check `instance_exists` before using a stored id
  (two crashes came from this: cursor hover and selling).
