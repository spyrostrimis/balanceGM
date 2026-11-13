/// First Claim rules: the Orichalcum zone in the middle of the map, capture and hold, how it is
/// drawn (world, minimap, HUD), and the AI that fights for it.
///
/// Capture: an alliance whose units are the only ones in the zone for zone.capture seconds takes it.
///   Both sides in the zone (or nobody) puts the capture bar back to zero.
/// Hold: the owner then needs zone.hold seconds with no enemy unit in the zone. Any enemy unit in the
///   zone resets the hold timer. The owner does not have to stay; only enemies matter.
/// Win: hold it, or destroy every enemy unit. Lose: the enemy holds it, or your army is gone.
/// Structures don't count either way. Sides are compared by alliance (team.ally), not by team.

function claim_init(_m)
{
    var _cx = round((global.mw - 1) / 2), _cy = round((global.mh - 1) / 2);
    var _z = {
        cx: _cx, cy: _cy, x: _cx * CELL + HALF, y: _cy * CELL + HALF, r: _m.zone.r,
        cells: ds_grid_create(global.mw, global.mh), list: [],
        owner: -1, cap_ally: -1, cap_t: 0, hold_t: 0,
        cap_need: _m.zone.capture * 60, hold_need: _m.zone.hold * 60,
        contested: false, present: [], counts: {}
    };
    ds_grid_clear(_z.cells, 0);
    for (var _i = 0; _i < global.mw; _i++)
    {
        for (var _j = 0; _j < global.mh; _j++)
        {
            if (point_distance(_i, _j, _cx, _cy) > _z.r || global.terr[# _i, _j] == T_CRAG) continue;
            _z.cells[# _i, _j] = 1;
            array_push(_z.list, [_i, _j]);
        }
    }
    global.claim = _z;
}

function claim_free()
{
    if (global.claim == undefined) return;
    ds_grid_destroy(global.claim.cells);
    global.claim = undefined;
}

function in_zone(_px, _py)
{
    var _cx = cell_of(_px), _cy = cell_of(_py);
    return in_map(_cx, _cy) && global.claim.cells[# _cx, _cy] == 1;
}

/// The name and colour of an alliance: those of its first team (in First Claim, one side each).
function ally_team(_ally)
{
    for (var _t = 0; _t < array_length(global.teams); _t++) if (global.teams[_t].ally == _ally) return global.teams[_t];
    return global.teams[0];
}

function ally_units(_ally)
{
    var _n = 0;
    for (var _t = 0; _t < array_length(global.teams); _t++) if (global.teams[_t].ally == _ally) _n += global.teams[_t].units;
    return _n;
}

/// One frame of the zone rules.
function claim_step()
{
    var _z = global.claim;
    var _me = global.teams[PLAYER].ally;
    var _counts = {};
    var _present = [];
    with (obj_unit)
    {
        if (!in_zone(x, y)) continue;
        var _a = global.teams[team].ally;
        var _k = string(_a);
        if (!variable_struct_exists(_counts, _k)) { _counts[$ _k] = 0; array_push(_present, _a); }
        _counts[$ _k]++;
    }
    _z.counts = _counts;
    _z.present = _present;
    var _n = array_length(_present);

    // Capture
    _z.contested = _n >= 2;
    if (_n == 1 && _present[0] != _z.owner)
    {
        var _a2 = _present[0];
        if (_z.cap_ally != _a2) { _z.cap_ally = _a2; _z.cap_t = 0; }
        _z.cap_t++;
        if (_z.cap_t >= _z.cap_need)
        {
            _z.owner = _a2;
            _z.cap_ally = -1;
            _z.cap_t = 0;
            _z.hold_t = 0;
            global.minimap_dirty = true;
            if (_a2 == _me) { msg("The Orichalcum is ours! Keep every enemy out of the ring for " + string(_z.hold_need div 60) + " seconds."); play("complete"); }
            else { msg("The enemy has taken the Orichalcum! Get into the ring to reset their hold."); play("alarm", 0.8); }
        }
    }
    else
    {
        _z.cap_t = 0;
        _z.cap_ally = -1;
    }

    // Hold
    if (_z.owner >= 0)
    {
        var _enemy_in = false;
        for (var _k2 = 0; _k2 < _n; _k2++) if (_present[_k2] != _z.owner) _enemy_in = true;
        if (_enemy_in)
        {
            if (_z.hold_t > 30)
            {
                if (_z.owner == _me) { msg("Enemy in the ring: our hold timer is back to zero!"); play("alarm", 0.6); }
                else { msg("We are in the ring: their hold is broken."); play("ready"); }
            }
            _z.hold_t = 0;
        }
        else
        {
            _z.hold_t++;
            if (_z.hold_t >= _z.hold_need)
            {
                var _won = _z.owner == _me;
                mission_end(_won, _won ? "You held the Orichalcum field." : "The enemy held the Orichalcum field.");
            }
        }
    }
}

/// Armies wiped out (checked twice a second).
function claim_check_end()
{
    var _me = global.teams[PLAYER].ally;
    if (ally_units(_me) == 0) { mission_end(false, "Your army has been destroyed."); return; }
    var _foes = 0;
    for (var _t = 0; _t < array_length(global.teams); _t++) if (global.teams[_t].ally != _me) _foes += global.teams[_t].units;
    if (_foes == 0) mission_end(true, "The enemy army has been destroyed.");
}

// ---------- Drawing ----------

function claim_colour(_ally)
{
    return (_ally < 0) ? make_colour_rgb(250, 226, 130) : ally_team(_ally).col;
}

/// The ring on the ground (drawn by obj_ground, under the units).
function claim_draw_world()
{
    var _z = global.claim;
    if (_z == undefined) return;
    var _col = claim_colour(_z.owner);
    var _pulse = 0.5 + 0.5 * sin(global.ui_t / 9);
    if (_z.contested) _col = ((global.ui_t div 12) mod 2 == 0) ? make_colour_rgb(255, 80, 60) : c_white;
    else if (_z.cap_ally >= 0) _col = merge_colour(_col, claim_colour(_z.cap_ally), _pulse);
    // A light tint over the zone, and its edge
    draw_set_alpha(0.1 + 0.05 * _pulse);
    draw_set_colour(_col);
    for (var _k = 0; _k < array_length(_z.list); _k++)
    {
        var _c = _z.list[_k];
        draw_rectangle(_c[0] * CELL, _c[1] * CELL, _c[0] * CELL + CELL - 1, _c[1] * CELL + CELL - 1, false);
    }
    draw_set_alpha(0.9);
    for (var _k = 0; _k < array_length(_z.list); _k++)
    {
        var _c = _z.list[_k];
        var _x1 = _c[0] * CELL, _y1 = _c[1] * CELL, _x2 = _x1 + CELL, _y2 = _y1 + CELL;
        if (!in_map(_c[0], _c[1] - 1) || _z.cells[# _c[0], _c[1] - 1] == 0) draw_line_width(_x1, _y1, _x2, _y1, 2);
        if (!in_map(_c[0], _c[1] + 1) || _z.cells[# _c[0], _c[1] + 1] == 0) draw_line_width(_x1, _y2, _x2, _y2, 2);
        if (!in_map(_c[0] - 1, _c[1]) || _z.cells[# _c[0] - 1, _c[1]] == 0) draw_line_width(_x1, _y1, _x1, _y2, 2);
        if (!in_map(_c[0] + 1, _c[1]) || _z.cells[# _c[0] + 1, _c[1]] == 0) draw_line_width(_x2, _y1, _x2, _y2, 2);
    }
    draw_set_alpha(1);
    // A claim flag on the vent: white while nobody holds it
    var _fx = _z.x + 7, _fy = _z.y - 2;
    draw_set_colour(c_black);
    draw_line_width(_fx, _fy, _fx, _fy - 26, 2);
    var _fc = claim_colour(_z.owner);
    var _wave = sin(global.ui_t / 7) * 2;
    draw_triangle_colour(_fx + 1, _fy - 26, _fx + 17, _fy - 21 + _wave, _fx + 1, _fy - 16, _fc, _fc, _fc, false);
    // Capture progress: an arc round the field in the capturing side's colour
    var _p = (_z.cap_ally >= 0) ? _z.cap_t / _z.cap_need : 0;
    if (_p > 0)
    {
        draw_set_colour(claim_colour(_z.cap_ally));
        var _rr = 3 * CELL, _steps = ceil(48 * _p);
        for (var _s = 0; _s < _steps; _s++)
        {
            var _a1 = 90 - _s / 48 * 360, _a2 = 90 - (_s + 1) / 48 * 360;
            draw_line_width(_z.x + lengthdir_x(_rr, _a1), _z.y + lengthdir_y(_rr, _a1), _z.x + lengthdir_x(_rr, _a2), _z.y + lengthdir_y(_rr, _a2), 3);
        }
    }
    draw_set_colour(c_white);
}

/// The zone on the minimap (called from ui_minimap with its scale and offset).
function claim_draw_minimap(_ox, _oy, _s)
{
    var _z = global.claim;
    if (_z == undefined) return;
    var _col = _z.contested ? (((global.ui_t div 12) mod 2 == 0) ? make_colour_rgb(255, 80, 60) : c_white) : claim_colour(_z.owner);
    var _mx = _ox + (_z.cx + 0.5) * _s, _my = _oy + (_z.cy + 0.5) * _s;
    draw_set_colour(_col);
    draw_circle(_mx, _my, (_z.r + 0.5) * _s, true);
    draw_circle(_mx, _my, (_z.r + 0.5) * _s - 1, true);
    draw_set_alpha(0.25 + 0.15 * sin(global.ui_t / 9));
    draw_circle(_mx, _my, (_z.r + 0.5) * _s, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}

function secs(_frames)
{
    return string(floor(_frames / 60));
}

/// The status banner over the top of the battlefield.
function claim_draw_hud()
{
    var _z = global.claim;
    if (_z == undefined) return;
    var _me = global.teams[PLAYER].ally;
    var _w = 420, _x = (SIDE_X - _w) div 2, _y = TOP_H + 6;
    ui_panel(_x, _y, _x + _w, _y + 62, 0.85);
    ui_text(_x + 12, _y + 8, "ORICHALCUM FIELD", UI_AMBER, global.f_small);
    var _own_txt = (_z.owner < 0) ? "Unclaimed" : ("Held by " + ally_team(_z.owner).name + ((_z.owner == _me) ? " (you)" : ""));
    ui_text(_x + _w - 12, _y + 6, _own_txt, claim_colour(_z.owner), global.f_ui, fa_right);

    var _bx = _x + 12, _by = _y + 30, _bw = _w - 24;
    var _line = "", _col = UI_DIM, _frac = 0;
    if (_z.contested)
    {
        _line = "CONTESTED: both sides in the ring";
        _col = ((global.ui_t div 15) mod 2 == 0) ? make_colour_rgb(255, 110, 80) : UI_TEXT;
        _frac = 0;
    }
    else if (_z.cap_ally >= 0)
    {
        var _ct = ally_team(_z.cap_ally);
        _line = ((_z.cap_ally == _me) ? "Capturing" : (_ct.name + " capturing")) + "   " + secs(_z.cap_t) + " / " + secs(_z.cap_need) + " s";
        _col = _ct.col;
        _frac = _z.cap_t / _z.cap_need;
    }
    else if (_z.owner >= 0)
    {
        var _enemy_in = false;
        for (var _k = 0; _k < array_length(_z.present); _k++) if (_z.present[_k] != _z.owner) _enemy_in = true;
        _line = (_z.owner == _me ? "Hold: keep enemies out   " : "Enemy hold: get into the ring!   ") + secs(_z.hold_t) + " / " + secs(_z.hold_need) + " s";
        _col = claim_colour(_z.owner);
        _frac = _z.hold_t / _z.hold_need;
    }
    else
    {
        _line = "Stand in the ring alone for " + secs(_z.cap_need) + " s to take it";
        _col = UI_DIM;
    }
    ui_bar(_bx, _by, _bw, 10, _frac, (_z.cap_ally >= 0) ? claim_colour(_z.cap_ally) : claim_colour(_z.owner));
    ui_text(_x + _w / 2, _by + 13, _line, _col, global.f_small, fa_center);
}

/// The sidebar panel that replaces the build queues in First Claim.
function claim_draw_sidebar()
{
    var _z = global.claim;
    var _x = MM_X, _y = TAB_Y, _w = 240;
    draw_set_colour(make_colour_rgb(22, 20, 18));
    draw_rectangle(_x, _y, _x + _w, INFO_Y - 10, false);
    draw_set_colour(UI_EDGE);
    draw_rectangle(_x, _y, _x + _w, INFO_Y - 10, true);
    ui_text(_x + 10, _y + 8, string_upper(global.mission.title), UI_AMBER, global.f_ui);
    ui_text(_x + 10, _y + 30, "No building. No reinforcements.", UI_DIM, global.f_small);
    var _rows = [
        "Take: be the only side in the ring for " + secs(_z.cap_need) + " s.",
        "Hold: then " + secs(_z.hold_need) + " s with no enemy in the ring. You may leave; an enemy entering resets it.",
        "Or destroy every enemy unit. Structures don't count."
    ];
    draw_set_font(global.f_small);
    draw_set_colour(UI_TEXT);
    var _ty = _y + 56;
    for (var _k = 0; _k < array_length(_rows); _k++)
    {
        draw_text_ext(_x + 10, _ty, _rows[_k], 16, _w - 20);
        _ty += string_height_ext(_rows[_k], 16, _w - 20) + 6;
    }
    _ty += 6;
    ui_text(_x + 10, _ty, "ARMIES", UI_AMBER, global.f_small);
    _ty += 20;
    for (var _t = 0; _t < array_length(global.teams); _t++)
    {
        var _tm = global.teams[_t];
        draw_set_colour(_tm.col);
        draw_rectangle(_x + 10, _ty + 3, _x + 20, _ty + 15, false);
        var _in = _z.counts[$ string(_tm.ally)] ?? 0;
        ui_text(_x + 28, _ty, _tm.name + ((_t == PLAYER) ? " (you)" : ""), UI_TEXT, global.f_small);
        ui_text(_x + _w - 10, _ty, string(_tm.units) + " units" + ((_in > 0) ? ("  (" + string(_in) + " in ring)") : ""), UI_TEXT, global.f_small, fa_right);
        _ty += 22;
    }
    draw_set_colour(c_white);
}

// ---------- AI ----------

/// The First Claim AI: gather just outside the ring, push in together, then hold it.
/// It goes in at once whenever the enemy is capturing or holding the field.
function ai_zone_create(_t, _diff)
{
    var _tm = global.teams[_t], _z = global.claim;
    var _hx = _tm.home_cx * CELL + HALF, _hy = _tm.home_cy * CELL + HALF;
    var _dir = point_direction(_z.x, _z.y, _hx, _hy);
    var _sd = (_z.r + 2.5) * CELL;
    var _c = nearest_free_cell(cell_of(_z.x + lengthdir_x(_sd, _dir)), cell_of(_z.y + lengthdir_y(_sd, _dir)), "veh", -1);
    return {
        kind: "zone", diff: _diff, phase: "gather",
        stage_x: _c[0] * CELL + HALF, stage_y: _c[1] * CELL + HALF,
        start: global.frame + [10, 3, 1][_diff] * 60,     // a moment before it moves out
        gather_max: [0, 20, 30][_diff] * 60,               // how long it waits to gather (Easy doesn't)
        gather_frac: [0, 0.7, 0.9][_diff],                  // how much of the army must be at the staging point
        every: [3, 1, 1][_diff],                            // Easy thinks every 1.5 s, the others twice a second
        tick: 0, gather_end: 0
    };
}

/// Sends one unit somewhere with an attack-move (it fights whatever it meets on the way).
function ai_amove(_u, _px, _py, _role)
{
    with (_u)
    {
        ai_role = _role;
        order = "amove";
        amove_x = _px;
        amove_y = _py;
        amove_resume = false;
        unit_path_to(_px, _py);
    }
}

/// A zone cell to stand on, leaning towards our own side of the ring. Holders bunch up near the
/// middle, so the whole group fights whoever comes in.
function ai_zone_spot(_ai, _holding)
{
    var _z = global.claim;
    if (_holding)
    {
        var _c0 = nearest_free_cell(_z.cx + irandom_range(-2, 2), _z.cy + irandom_range(-2, 2), "inf", -1);
        return [_c0[0] * CELL + HALF + random_range(-8, 8), _c0[1] * CELL + HALF + random_range(-8, 8)];
    }
    var _a = _z.list[irandom(array_length(_z.list) - 1)], _b = _z.list[irandom(array_length(_z.list) - 1)];
    var _da = point_distance(_a[0] * CELL, _a[1] * CELL, _ai.stage_x, _ai.stage_y), _db = point_distance(_b[0] * CELL, _b[1] * CELL, _ai.stage_x, _ai.stage_y);
    var _c = (_da < _db) ? _a : _b;
    return [_c[0] * CELL + HALF + random_range(-6, 6), _c[1] * CELL + HALF + random_range(-6, 6)];
}

function ai_zone_step(_t)
{
    var _tm = global.teams[_t], _ai = _tm.ai, _z = global.claim;
    if (_z == undefined || global.frame < _ai.start) return;
    _ai.tick++;
    if (_ai.tick mod _ai.every != 0) return;
    var _me = _tm.ally;

    // Look at the field
    var _army = [], _str = 0, _estr = 0, _foes_in = 0, _fx = 0, _fy = 0;
    with (obj_unit)
    {
        var _v = def.cost * hp / maxhp;
        if (team == _t) { array_push(_army, id); _str += _v; }
        else if (hostile(team, _t))
        {
            _estr += _v;
            if (in_zone(x, y)) { _foes_in++; _fx += x; _fy += y; }
        }
    }
    var _n = array_length(_army);
    if (_n == 0) return;
    var _urgent = (_z.owner >= 0 && _z.owner != _me) || (_z.cap_ally >= 0 && _z.cap_ally != _me) || _foes_in > 0;
    var _mine_in = _z.counts[$ string(_me)] ?? 0;

    // Phase changes
    if (_ai.phase == "gather")
    {
        var _at = 0;
        for (var _k = 0; _k < _n; _k++) if (point_distance(_army[_k].x, _army[_k].y, _ai.stage_x, _ai.stage_y) < 3.5 * CELL) _at++;
        if (_ai.gather_end == 0) _ai.gather_end = global.frame + _ai.gather_max;
        if (_urgent || _at >= _n * _ai.gather_frac || global.frame >= _ai.gather_end) _ai.phase = "push";
    }
    else if (!_urgent && _mine_in == 0 && _z.owner != _me && _str < _estr * 0.8 && _ai.gather_max > 0)
    {
        // Beaten back and outnumbered, with nothing to defend right now: regroup first.
        _ai.phase = "gather";
        _ai.gather_end = global.frame + _ai.gather_max;
    }

    // Orders
    for (var _k = 0; _k < _n; _k++)
    {
        var _u = _army[_k];
        if (_u.target != noone && instance_exists(_u.target)) continue; // busy fighting
        if (_ai.phase == "gather")
        {
            if (_u.ai_role != "stage" || (_u.order == "idle" && point_distance(_u.x, _u.y, _ai.stage_x, _ai.stage_y) > 4 * CELL))
                ai_amove(_u, _ai.stage_x + random_range(-40, 40), _ai.stage_y + random_range(-40, 40), "stage");
            continue;
        }
        if (_foes_in > 0)
        {
            // Enemies in the ring: go at them together. (Holders wait in the ring rather than walk out to a waiting enemy.)
            var _ex = _fx / _foes_in, _ey = _fy / _foes_in;
            if (_u.ai_role != "foe" || point_distance(_u.amove_x, _u.amove_y, _ex, _ey) > 3 * CELL || _u.order == "idle")
                ai_amove(_u, _ex + random_range(-20, 20), _ey + random_range(-20, 20), "foe");
            continue;
        }
        // Into the ring (to take it, or to stand in it so the enemy can't).
        var _holding = _z.owner == _me;
        var _placed = in_zone(_u.x, _u.y) && (!_holding || point_distance(_u.x, _u.y, _z.x, _z.y) < 3 * CELL);
        if (_placed && _u.order == "idle") { _u.ai_role = "zone"; continue; }
        if (_u.ai_role != "zone" || _u.order == "idle")
        {
            var _p = ai_zone_spot(_ai, _holding);
            ai_amove(_u, _p[0], _p[1], "zone");
        }
    }
}
