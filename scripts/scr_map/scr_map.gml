/// The map: terrain, lumen fields, crags, path grids, tilemaps and the shroud.

function in_map(_cx, _cy)
{
    return _cx >= 0 && _cy >= 0 && _cx < global.mw && _cy < global.mh;
}

function cell_of(_px)
{
    return floor(_px / CELL);
}

/// Is a cell drawn as rock (desert) or a laterite clearing (forest)? In the forest, thickets stand on grass.
function is_rock(_cx, _cy)
{
    _cx = clamp(_cx, 0, global.mw - 1);
    _cy = clamp(_cy, 0, global.mh - 1);
    if (global.look == "forest") return global.terr[# _cx, _cy] == T_ROCK;
    return global.terr[# _cx, _cy] != T_SAND;
}

/// A rough round patch of terrain.
function map_blob(_cx, _cy, _r, _t)
{
    var _p1 = random(6.28), _p2 = random(6.28);
    var _reach = ceil(_r * 1.5) + 1;
    for (var _i = _cx - _reach; _i <= _cx + _reach; _i++)
    {
        for (var _j = _cy - _reach; _j <= _cy + _reach; _j++)
        {
            if (!in_map(_i, _j)) continue;
            var _a = degtorad(point_direction(_cx, _cy, _i, _j));
            var _rr = _r * (1 + 0.22 * sin(_a * 3 + _p1) + 0.12 * sin(_a * 5 + _p2));
            if (point_distance(_cx, _cy, _i, _j) <= _rr && global.terr[# _i, _j] == T_SAND) global.terr[# _i, _j] = _t;
        }
    }
}

function lumen_field(_cx, _cy, _r)
{
    var _p1 = random(6.28);
    var _reach = ceil(_r * 1.4) + 1;
    for (var _i = _cx - _reach; _i <= _cx + _reach; _i++)
    {
        for (var _j = _cy - _reach; _j <= _cy + _reach; _j++)
        {
            if (!in_map(_i, _j) || global.terr[# _i, _j] != T_SAND) continue;
            var _a = degtorad(point_direction(_cx, _cy, _i, _j));
            var _rr = _r * (1 + 0.3 * sin(_a * 3 + _p1));
            var _d = point_distance(_cx, _cy, _i, _j);
            if (_d <= _rr) global.lumen[# _i, _j] = max(global.lumen[# _i, _j], clamp(round(LUMEN_MAX * (1 - _d / (_rr + 1)) + 70 + random(40)), 40, LUMEN_MAX));
        }
    }
    if (in_map(_cx, _cy) && global.terr[# _cx, _cy] == T_SAND)
    {
        global.isvent[# _cx, _cy] = 1;
        global.lumen[# _cx, _cy] = 0;
        array_push(global.vents, [_cx, _cy]);
    }
}

function far_from(_cx, _cy, _points, _dist)
{
    for (var _k = 0; _k < array_length(_points); _k++)
    {
        if (point_distance(_cx, _cy, _points[_k].cx, _points[_k].cy) < _dist) return false;
    }
    return true;
}

/// Builds the map for mission _m. _bases is an array of {cx, cy}: where each force's base sits.
function map_create(_m, _bases)
{
    var _w = _m.w, _h = _m.h;
    global.mw = _w;
    global.mh = _h;
    global.terr = ds_grid_create(_w, _h);       ds_grid_clear(global.terr, T_SAND);
    global.lumen = ds_grid_create(_w, _h);      ds_grid_clear(global.lumen, 0);
    global.isvent = ds_grid_create(_w, _h);     ds_grid_clear(global.isvent, 0);
    global.bgrid = ds_grid_create(_w, _h);      ds_grid_clear(global.bgrid, noone);
    global.shroud = ds_grid_create(_w, _h);     ds_grid_clear(global.shroud, 0);
    global.vents = [];
    global.lumen_claim = ds_map_create();
    random_set_seed(_m.seed);
    if (_m.layout == "duel")
    {
        map_gen_duel(_m);
        randomize();
        map_build_grids();
        map_build_tiles();
        return;
    }

    // Base plateaus
    for (var _k = 0; _k < array_length(_bases); _k++) map_blob(_bases[_k].cx, _bases[_k].cy, 7.5, T_ROCK);

    // Outcrops, some topped with crags
    repeat (_m.outcrops)
    {
        for (var _try = 0; _try < 30; _try++)
        {
            var _cx = irandom_range(3, _w - 4), _cy = irandom_range(3, _h - 4);
            if (!far_from(_cx, _cy, _bases, 12)) continue;
            var _r = random_range(2.2, 4.8);
            map_blob(_cx, _cy, _r, T_ROCK);
            if (_r > 2.8)
            {
                repeat (irandom_range(1, 3))
                {
                    var _a = random(360), _d = random(_r - 1.6);
                    var _gx = round(_cx + lengthdir_x(_d, _a)), _gy = round(_cy + lengthdir_y(_d, _a));
                    if (in_map(_gx, _gy) && global.terr[# _gx, _gy] == T_ROCK) global.terr[# _gx, _gy] = T_CRAG;
                }
            }
            break;
        }
    }

    // A lumen field near each base, facing the middle of the map, then more around the map
    var _fields = [];
    for (var _k = 0; _k < array_length(_bases); _k++)
    {
        var _b = _bases[_k];
        var _a = point_direction(_b.cx, _b.cy, _w / 2, _h / 2) + random_range(-50, 50);
        for (var _try = 0; _try < 20; _try++)
        {
            var _fx = round(_b.cx + lengthdir_x(11, _a)), _fy = round(_b.cy + lengthdir_y(11, _a));
            if (in_map(_fx, _fy) && global.terr[# _fx, _fy] == T_SAND) break;
            _a += 23;
        }
        lumen_field(_fx, _fy, random_range(3.4, 4.4));
        array_push(_fields, { cx: _fx, cy: _fy });
    }
    var _left = _m.fields - array_length(_bases);
    for (var _try = 0; _try < 200 && _left > 0; _try++)
    {
        var _fx = irandom_range(3, _w - 4), _fy = irandom_range(3, _h - 4);
        if (global.terr[# _fx, _fy] != T_SAND || !far_from(_fx, _fy, _bases, 10) || !far_from(_fx, _fy, _fields, 8)) continue;
        lumen_field(_fx, _fy, random_range(2.6, 4.6));
        array_push(_fields, { cx: _fx, cy: _fy });
        _left--;
    }
    randomize();

    map_build_grids();
    map_build_tiles();
}

// ---------- Duel maps (First Claim): small, turned half way round so both sides get the same ground ----------

/// The cell that (_cx, _cy) maps to on the other half of a duel map.
function duel_mirror_x(_cx) { return global.mw - 1 - _cx; }
function duel_mirror_y(_cy) { return global.mh - 1 - _cy; }

/// The top-left cell of a structure from base_plan, for slot 0 or slot 1.
function duel_plan_cell(_plan_item, _slot)
{
    var _d = global.bdef[$ _plan_item[0]];
    if (_slot == 0) return [_plan_item[1], _plan_item[2]];
    return [global.mw - _plan_item[1] - _d.w, global.mh - _plan_item[2] - _d.h];
}

function duel_home(_m, _slot)
{
    if (_slot == 0) return [_m.home.cx, _m.home.cy];
    return [duel_mirror_x(_m.home.cx), duel_mirror_y(_m.home.cy)];
}

/// Can a vehicle drive from (_ax, _ay) to (_bx, _by)? (A flood fill over the terrain.)
function duel_connected(_ax, _ay, _bx, _by)
{
    var _seen = ds_grid_create(global.mw, global.mh);
    ds_grid_clear(_seen, 0);
    var _q = ds_queue_create();
    ds_queue_enqueue(_q, [_ax, _ay]);
    _seen[# _ax, _ay] = 1;
    var _found = false;
    var _nb = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    while (!ds_queue_empty(_q))
    {
        var _c = ds_queue_dequeue(_q);
        if (_c[0] == _bx && _c[1] == _by) { _found = true; break; }
        for (var _k = 0; _k < 4; _k++)
        {
            var _i = _c[0] + _nb[_k][0], _j = _c[1] + _nb[_k][1];
            if (!in_map(_i, _j) || _seen[# _i, _j] || global.terr[# _i, _j] == T_CRAG) continue;
            _seen[# _i, _j] = 1;
            ds_queue_enqueue(_q, [_i, _j]);
        }
    }
    ds_queue_destroy(_q);
    ds_grid_destroy(_seen);
    return _found;
}

/// The First Claim map: two base plateaus in opposite corners, thickets (crags) that make lanes,
/// and one Orichalcum field in the middle. Everything is generated on one half and copied,
/// turned half way round, onto the other.
function map_gen_duel(_m)
{
    var _w = global.mw, _h = global.mh;
    var _mx = (_w - 1) / 2, _my = (_h - 1) / 2;
    var _zr = _m.zone.r;
    var _home = duel_home(_m, 0);
    var _ok = false;
    for (var _try = 0; _try < 25 && !_ok; _try++)
    {
        ds_grid_clear(global.terr, T_SAND);
        // The base plateau, and a couple of small clearings out on the flanks
        map_blob(_home[0], _home[1], 6, T_ROCK);
        repeat (2)
        {
            var _a = random(360), _d = random_range(8, 12);
            var _px = round(_mx + lengthdir_x(_d, _a)), _py = round(_my + lengthdir_y(_d, _a));
            if (point_distance(_px, _py, _home[0], _home[1]) > 8 && point_distance(_px, _py, _mx, _my) > _zr + 3) map_blob(_px, _py, random_range(1.6, 2.6), T_ROCK);
        }
        // Thickets: clumps and short lines of crag, kept off the bases and the zone
        repeat (9)
        {
            var _tx = irandom_range(1, _w - 2), _ty = irandom_range(1, _h - 2);
            var _len = irandom_range(1, 4), _dir = irandom(3) * 45;
            for (var _s = 0; _s < _len; _s++)
            {
                var _cx = round(_tx + lengthdir_x(_s, _dir)), _cy = round(_ty + lengthdir_y(_s, _dir));
                var _r = random_range(0.8, 1.7);
                for (var _i = floor(_cx - _r); _i <= ceil(_cx + _r); _i++)
                {
                    for (var _j = floor(_cy - _r); _j <= ceil(_cy + _r); _j++)
                    {
                        if (!in_map(_i, _j) || point_distance(_i, _j, _cx, _cy) > _r) continue;
                        if (point_distance(_i, _j, _mx, _my) < _zr + 2.5) continue;
                        if (point_distance(_i, _j, _home[0], _home[1]) < 8.5 || point_distance(_i, _j, duel_mirror_x(_home[0]), duel_mirror_y(_home[1])) < 8.5) continue;
                        global.terr[# _i, _j] = T_CRAG;
                    }
                }
            }
        }
        // Copy the first half onto the second, turned half way round
        for (var _i = 0; _i < _w; _i++)
        {
            for (var _j = 0; _j < _h; _j++)
            {
                if (_j * _w + _i < (_w * _h) div 2) global.terr[# duel_mirror_x(_i), duel_mirror_y(_j)] = global.terr[# _i, _j];
            }
        }
        // The base plan's cells are always rock
        for (var _k = 0; _k < array_length(_m.base_plan); _k++)
        {
            var _it = _m.base_plan[_k], _d2 = global.bdef[$ _it[0]];
            for (var _slot = 0; _slot < 2; _slot++)
            {
                var _c = duel_plan_cell(_it, _slot);
                for (var _i = 0; _i < _d2.w; _i++) for (var _j = 0; _j < _d2.h; _j++) global.terr[# _c[0] + _i, _c[1] + _j] = T_ROCK;
            }
        }
        _ok = duel_connected(_home[0], _home[1], round(_mx), round(_my));
    }
    // The Orichalcum field in the middle, with its vent
    var _cxm = round(_mx), _cym = round(_my);
    for (var _i = _cxm - 3; _i <= _cxm + 3; _i++)
    {
        for (var _j = _cym - 3; _j <= _cym + 3; _j++)
        {
            var _dd = point_distance(_i, _j, _mx, _my);
            if (_dd <= 2.3) global.lumen[# _i, _j] = clamp(round(LUMEN_MAX * (1 - _dd / 3.3) + 70 + random(30)), 60, LUMEN_MAX);
        }
    }
    global.isvent[# _cxm, _cym] = 1;
    global.lumen[# _cxm, _cym] = 0;
    array_push(global.vents, [_cxm, _cym]);
}

function map_build_grids()
{
    global.grid_veh = mp_grid_create(0, 0, global.mw, global.mh, CELL, CELL);
    global.grid_inf = mp_grid_create(0, 0, global.mw, global.mh, CELL, CELL);
    for (var _i = 0; _i < global.mw; _i++)
    {
        for (var _j = 0; _j < global.mh; _j++)
        {
            if (global.terr[# _i, _j] == T_CRAG) mp_grid_add_cell(global.grid_veh, _i, _j);
        }
    }
}

function map_build_tiles()
{
    var _w = global.mw, _h = global.mh;
    var _forest = global.look == "forest";
    global.lay_terrain = layer_create(10000, "Terrain");
    global.tm_terrain = layer_tilemap_create(global.lay_terrain, -HALF, -HALF, _forest ? ts_terrain_forest : ts_terrain, _w + 1, _h + 1);
    for (var _i = 0; _i <= _w; _i++)
    {
        for (var _j = 0; _j <= _h; _j++)
        {
            var _mask = (is_rock(_i - 1, _j - 1) ? 1 : 0) | (is_rock(_i, _j - 1) ? 2 : 0) | (is_rock(_i, _j) ? 4 : 0) | (is_rock(_i - 1, _j) ? 8 : 0);
            var _t;
            if (_mask == 0) _t = choose(1, 1, 1, 17, 18, 19);
            else if (_mask == 15) _t = choose(16, 16, 20, 21, 22);
            else _t = _mask + 1;
            tilemap_set(global.tm_terrain, _t, _i, _j);
        }
    }
    global.lay_lumen = layer_create(9900, "Lumen");
    global.tm_lumen = layer_tilemap_create(global.lay_lumen, 0, 0, ts_lumen, _w, _h);
    global.lay_crag = layer_create(9800, "Crags");
    global.tm_crag = layer_tilemap_create(global.lay_crag, 0, 0, _forest ? ts_crag_forest : ts_crag, _w, _h);
    for (var _i = 0; _i < _w; _i++)
    {
        for (var _j = 0; _j < _h; _j++)
        {
            lumen_tile(_i, _j);
            if (global.terr[# _i, _j] == T_CRAG) tilemap_set(global.tm_crag, 1 + ((_i * 7 + _j * 3) mod 4), _i, _j);
        }
    }
}

function lumen_tile(_cx, _cy)
{
    var _t = 0;
    if (global.isvent[# _cx, _cy]) _t = 7;
    else
    {
        var _a = global.lumen[# _cx, _cy];
        if (_a > 0) _t = ((_a < 110) ? 1 : ((_a < 210) ? 3 : 5)) + ((_cx + _cy) mod 2);
    }
    tilemap_set(global.tm_lumen, _t, _cx, _cy);
    global.minimap_dirty = true;
}

/// Takes up to _amount of lumen from a cell; returns what was taken.
function lumen_take(_cx, _cy, _amount)
{
    var _a = global.lumen[# _cx, _cy];
    var _got = min(_a, _amount);
    if (_got <= 0) return 0;
    var _before = (_a < 110) ? 0 : ((_a < 210) ? 1 : 2);
    _a -= _got;
    global.lumen[# _cx, _cy] = _a;
    var _after = (_a <= 0) ? -1 : ((_a < 110) ? 0 : ((_a < 210) ? 1 : 2));
    if (_after != _before) lumen_tile(_cx, _cy);
    return _got;
}

/// Vents slowly grow new crystals around them.
function lumen_regrow()
{
    for (var _k = 0; _k < array_length(global.vents); _k++)
    {
        if (random(1) > 0.35) continue;
        var _v = global.vents[_k];
        var _cx = _v[0] + irandom_range(-3, 3), _cy = _v[1] + irandom_range(-3, 3);
        if (!in_map(_cx, _cy) || global.terr[# _cx, _cy] != T_SAND || global.isvent[# _cx, _cy] || global.bgrid[# _cx, _cy] != noone) continue;
        var _a = global.lumen[# _cx, _cy];
        if (_a >= LUMEN_MAX) continue;
        global.lumen[# _cx, _cy] = min(LUMEN_MAX, _a + 45);
        lumen_tile(_cx, _cy);
    }
}

function map_destroy()
{
    if (!variable_global_exists("terr") || global.terr == -1) return;
    ds_grid_destroy(global.terr);
    ds_grid_destroy(global.lumen);
    ds_grid_destroy(global.isvent);
    ds_grid_destroy(global.bgrid);
    ds_grid_destroy(global.shroud);
    ds_map_destroy(global.lumen_claim);
    mp_grid_destroy(global.grid_veh);
    mp_grid_destroy(global.grid_inf);
    layer_destroy(global.lay_terrain);
    layer_destroy(global.lay_lumen);
    layer_destroy(global.lay_crag);
    global.terr = -1;
}

/// Is a cell free for this kind of unit ("inf" or "veh")?
function cell_free(_cx, _cy, _kind)
{
    if (!in_map(_cx, _cy)) return false;
    var _g = (_kind == "inf") ? global.grid_inf : global.grid_veh;
    return mp_grid_get_cell(_g, _cx, _cy) == 0;
}

/// The nearest cell to (_cx, _cy) a unit can stand on; _avoid is a ds_map of cells already given out (or -1).
function nearest_free_cell(_cx, _cy, _kind, _avoid)
{
    for (var _r = 0; _r < 14; _r++)
    {
        var _best = -1, _bd = 99999;
        for (var _i = _cx - _r; _i <= _cx + _r; _i++)
        {
            for (var _j = _cy - _r; _j <= _cy + _r; _j++)
            {
                if (max(abs(_i - _cx), abs(_j - _cy)) != _r) continue;
                if (!cell_free(_i, _j, _kind)) continue;
                if (_avoid != -1 && ds_map_exists(_avoid, _j * global.mw + _i)) continue;
                var _d = point_distance(_i, _j, _cx, _cy);
                if (_d < _bd) { _bd = _d; _best = [_i, _j]; }
            }
        }
        if (_best != -1) return _best;
    }
    return [clamp(_cx, 0, global.mw - 1), clamp(_cy, 0, global.mh - 1)];
}

// ---------- Shroud (the player's map is black until seen; it stays revealed) ----------

function shroud_reveal(_cx, _cy, _r)
{
    var _changed = false;
    var _rr = ceil(_r);
    for (var _i = _cx - _rr; _i <= _cx + _rr; _i++)
    {
        for (var _j = _cy - _rr; _j <= _cy + _rr; _j++)
        {
            if (!in_map(_i, _j) || global.shroud[# _i, _j]) continue;
            if (point_distance(_i, _j, _cx, _cy) > _r + 0.3) continue;
            global.shroud[# _i, _j] = 1;
            _changed = true;
            if (surface_exists(global.shroud_surf))
            {
                surface_set_target(global.shroud_surf);
                draw_point_colour(_i + 1, _j + 1, c_white);
                surface_reset_target();
            }
        }
    }
    if (_changed) global.minimap_dirty = true;
}

/// The shroud is a tiny surface (one pixel per cell, with a 1-pixel black border) drawn stretched with filtering, so its edges are soft.
function shroud_surface_check()
{
    if (surface_exists(global.shroud_surf)) return;
    global.shroud_surf = surface_create(global.mw + 2, global.mh + 2);
    surface_set_target(global.shroud_surf);
    draw_clear(c_black);
    for (var _i = 0; _i < global.mw; _i++)
    {
        for (var _j = 0; _j < global.mh; _j++)
        {
            if (global.shroud[# _i, _j]) draw_point_colour(_i + 1, _j + 1, c_white);
        }
    }
    surface_reset_target();
}

function shroud_draw()
{
    shroud_surface_check();
    gpu_set_texfilter(true);
    gpu_set_blendmode_ext(bm_zero, bm_src_colour); // multiply
    draw_surface_ext(global.shroud_surf, -CELL, -CELL, CELL, CELL, 0, c_white, 1);
    gpu_set_blendmode(bm_normal);
    gpu_set_texfilter(false);
}

function seen(_px, _py)
{
    var _cx = clamp(cell_of(_px), 0, global.mw - 1), _cy = clamp(cell_of(_py), 0, global.mh - 1);
    return global.shroud[# _cx, _cy] == 1;
}
