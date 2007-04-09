----------------------------------------------------------------
-- BUILDER
----------------------------------------------------------------
--
--  Oblige Level Maker (C) 2006,2007 Andrew Apted
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2
--  of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
----------------------------------------------------------------

--[[

class BuildItem
{
   x1,y1,x2,y2 : used area (not including the "walk zone")

   prefab : name    -- for prefabs
   skin
   parm
   dir
OR
   connx  : name  e.g. "stairs"
   dir
OR
   thing  : name
   angle
   options
}

--]]


function copy_block(B, ...)
  local result = copy_table(B)

  result.things = {}
  
  -- copy the overrides and corner adjustments
  for i = 1,9 do
    if B[i] then result[i] = copy_table(B[i]) end
  end

  return result
end

function copy_block_with_new(B, newbie)
  return merge_table(copy_block(B), newbie)
end


function side_to_chunk(side)
  if side == 2 then return 2, 1 end
  if side == 8 then return 2, 3 end
  if side == 4 then return 1, 2 end
  if side == 6 then return 3, 2 end
  error ("side_to_chunk: bad side " .. side)
end

function dir_to_corner(dir, W, H)
  if dir == 1 then return 1,1 end
  if dir == 3 then return W,1 end
  if dir == 7 then return 1,H end
  if dir == 9 then return W,H end
  error ("dir_to_corner: bad dir " .. dir)
end

function chunk_touches_side(kx, ky, side)
  if side == 4 then return kx == 1 end
  if side == 6 then return kx == 3 end
  if side == 2 then return ky == 1 end
  if side == 8 then return ky == 3 end
end

function is_roomy(chunk)
  return chunk and (chunk.kind == "room" or chunk.kind == "link")
end

function random_where(link, border)

  local LINK_WHERES = { 3, 3, 9, 3, 3 }

  if GAME.caps.blocky_doors or
     (link.quest and link.quest.kind == "key") or
     link.cells[1].is_exit or link.cells[2].is_exit
  then
    LINK_WHERES = { 1, 3, 9, 3, 1 }
  end

  for zzz,c in ipairs(link.cells) do
--???    if c.small_exit then return 0 end
  end

  if (link.kind == "door" and rand_odds(4)) or
     (link.kind ~= "door" and rand_odds(15))
  then
    if border.long >= 7 then
--!!!!      return "double";
    end
  end

  if (link.kind == "arch" and rand_odds(33)) or
     (link.kind == "falloff" and rand_odds(99)) or
     (link.kind == "vista" and rand_odds(50))
  then
--!!!!    return "wide";
  end

---???  if link.kind == "falloff" then return 0 end

  return rand_index_by_probs(LINK_WHERES) - 3
end


function show_blocks(cell) -- FIXME
  assert(cell.blocks)
  for y = BH,1,-1 do
    for x = 1,BW do
      local B = cell.blocks[x][y]
      con.printf(B and (B.fragments and "%" or
                      (B.sector and "/" or "#")) or ".")
    end
    con.printf("\n")
  end
end

function show_fragments(block)
  assert(block.fragments)
  for y = FH,1,-1 do
    for x = 1,FW do
      local fg = block.fragments[x][y]
      con.printf(fg and (fg.sector and "/" or "#") or ".")
    end
    con.printf("\n")
  end
end


function fill(p, c, sx, sy, ex, ey, B, B2)
  if sx > ex then sx, ex = ex, sx end
  if sy > ey then sy, ey = ey, sy end
  for x = sx,ex do
    for y = sy,ey do
      assert(valid_block(p, x, y))

      local N = copy_block(B)
      p.blocks[x][y] = N

      if B2 then
        merge_table(N, B2)
      end

      N.mark = N.mark or c.mark
    end
  end
end

function c_fill(p, c, sx, sy, ex, ey, B, B2)

  fill(p,c, c.bx1-1+sx, c.by1-1+sy, c.bx1-1+ex, c.by1-1+ey, B, B2)
end

function gap_fill(p, c, sx, sy, ex, ey, B, B2)
  if sx > ex then sx, ex = ex, sx end
  if sy > ey then sy, ey = ey, sy end
  for x = sx,ex do
    for y = sy,ey do

if not valid_block(p,x,y) then
con.printf("gap_fill: invalid block (%d,%d)  max: (%d,%d)\n", x,y, p.blk_w, p.blk_h)
error("invalid block")
end
      assert(valid_block(p, x, y))

      local X = p.blocks[x][y]

      if not X or not (X.solid or X.f_tex or X.fragments) then
        fill(p,c, x,y, x,y, B, B2)
      end
    end
  end
end

function frag_fill(p, c, sx, sy, ex, ey, F, F2)

  if sx > ex then sx, ex = ex, sx end
  if sy > ey then sy, ey = ey, sy end
  for x = sx,ex do
    for y = sy,ey do
      local bx, fx = div_mod(x, FW)
      local by, fy = div_mod(y, FH)
      
      if not p.blocks[bx][by] then
        p.blocks[bx][by] = {}
      end

      local B = p.blocks[bx][by]
      B.solid = nil

      if not B.fragments then
        B.fragments = array_2D(FW, FH)
      end

      local N = copy_block(F)
      B.fragments[fx][fy] = N

      if F2 then merge_table(N, F2) end

      N.mark = N.mark or c.mark
    end
  end
end


function move_corner(p,c, x,y,corner, dx,dy)

  local B = p.blocks[x][y]
  assert(B)

  if not B[corner] then
    B[corner] = {}
  else
    dx = dx + (B[corner].dx or 0)
    dy = dy + (B[corner].dy or 0)
  end

  B[corner].dx = dx
  B[corner].dy = dy

  -- ensure that the writer doesn't swallow up this block
  -- (which would lose the vertex we want to move)
  B.mark = allocate_mark(p)
end

-- the c_ prefix means (x,y) are cell-relative coords
function c_move_frag_corner(p,c, x,y,corner, dx,dy)

  local bx, fx = div_mod(x, FW)
  local by, fy = div_mod(y, FH)

  local B = p.blocks[c.bx1-1+bx][c.by1-1+by]
  assert(B)
  assert(B.fragments)

  local F = B.fragments[fx][fy]
  assert(F)

  if not F[corner] then
    F[corner] = {}
  else
    dx = dx + (F[corner].dx or 0)
    dy = dy + (F[corner].dy or 0)
  end

  F[corner].dx = dx
  F[corner].dy = dy

  F.mark = allocate_mark(p)
end

 
function scale_block(B, scale)
  -- Note: doesn't set x_offsets
  scale = (scale - 1) * 32
  B[1] = { dx=-scale, dy=-scale }
  B[3] = { dx= scale, dy=-scale }
  B[7] = { dx=-scale, dy= scale }
  B[9] = { dx= scale, dy= scale }
end

function rotate_block(B, d)
  -- Note: doesn't set x_offsets
  B[1] = { dx= 32, dy= -d }
  B[3] = { dx=  d, dy= 32 }
  B[9] = { dx=-32, dy=  d }
  B[7] = { dx= -d, dy=-32 }
end


FAB_DIRECTION_MAP =
{
  [2] = { 1,2,3, 4,5,6, 7,8,9 },
  [8] = { 9,8,7, 6,5,4, 3,2,1 },

  [6] = { 3,6,9, 2,5,8, 1,4,7 },
  [4] = { 7,4,1, 8,5,2, 9,6,3 },

  -- mirror --

  [12] = { 3,2,1, 6,5,4, 9,8,7 },
  [18] = { 7,8,9, 4,5,6, 1,2,3 },

  [16] = { 9,6,3, 8,5,2, 7,4,1 },
  [14] = { 1,4,7, 2,5,8, 3,6,9 },
}

function B_prefab(p,c, fab,skin,parm, model,combo, x,y, dir,mirror_x,mirror_y)

  -- (x,y) is always the block with the lowest coordinate.
  -- dir == 2 is the natural mode, other values rotate it.

  assert(fab and skin and parm and combo)

  local focus = p.blocks[x][y]
  if focus and focus.rmodel then
    focus = focus.rmodel
  else
    focus = model
  end

  parm.floor_h = parm.floor_h or focus.f_h
  parm.ceil_h  = parm.ceil_h  or focus.c_h

  local diff_h = parm.ceil_h - parm.floor_h

  parm.low_h  = parm.low_h  or (parm.floor_h + math.min(64, diff_h * 0.25))
  parm.high_h = parm.high_h or (parm. ceil_h - math.min(64, diff_h * 0.25))
  parm.mid_h  = parm.mid_h  or (parm.floor_h + diff_h * 0.50)

  -- simulate Y mirroring using X mirroring instead
  if mirror_y then
    mirror_x = not mirror_x
    dir = 10-dir
  end

  local long = fab.long
  local deep = fab.deep
  
  if fab.scale ~= 64 then
    long, deep = long*4, deep*4
  end

  local function f_coords(ex, ey)
    if mirror_x then ex = long+1-ex end

        if dir == 8 then ex,ey = long+1-ex, deep+1-ey
    elseif dir == 6 then ex,ey = deep+1-ey, ex
    elseif dir == 4 then ex,ey =        ey, long+1-ex
    end

    if fab.scale == 64 then
      return x + ex - 1, y + ey - 1
    end
  
    local fx = 1 + (x-1)*FW + ex - 1
    local fy = 1 + (y-1)*FH + ey - 1

    return fx, fy
  end

  local function dd_coords(dx, dy)
    if mirror_x then dx = -dx end

        if dir == 8 then return -dx, -dy
    elseif dir == 6 then return -dy,  dx
    elseif dir == 4 then return  dy, -dx
    else return dx, dy -- dir == 2
    end
  end

  local function th_coords(tx, ty)
    local mid_x = long * 8
    local mid_y = deep * 8

    tx, ty = dd_coords(tx - mid_x, ty - mid_y)

    if dir == 4 or dir == 6 then mid_x,mid_y = mid_y,mid_x end

    tx, ty = mid_x + tx, mid_y + ty

    local bx = x + int(tx / 64)
    local by = y + int(ty / 64)

    local dx = (tx % 64) - 32
    local dy = (ty % 64) - 32

    return bx,by, dx,dy
  end


  local function parm_val(key)
    if parm[key] then return parm[key] end
    if skin[key] then return skin[key] end
    if model[key] then return model[key] end

    error("Bad fab/parameters: missing value for " .. key .. " in prefab: " .. fab.name)
  end

  local function what_h_ref(base, rel, h, add)

    local result = base

    if rel then
      if not parm[rel] then
        error("Missing f/c rel value: " .. rel .. " in prefab: " .. fab.name)
      end
      result = parm[rel]
    end

    if add then
      if not skin[add] then
        error("Missing f/c add value: " .. add .. " in prefab: " .. fab.name)
      end
      result = result + skin[add]
    end

    return result + (h or 0)
  end

  local function what_tex(base, key)
    if skin[key] then return skin[key] end
    if parm[key] then return parm[key] end

    if key == "sky" and combo.outdoor then return GAME.SKY_TEX end

    if skin[base]  then return skin[base] end
    if combo[base] then return combo[base] end

    error("Unknown texture ref: " .. key .. " in prefab: " .. fab.name)
  end

  local function what_thing(name)
    if skin[name] then return skin[name] end
    if parm[name] then return parm[name] end

    error("Unknown thing ref: " .. name .. " in prefab: " .. fab.name)
  end

  local function compile_element(elem)

    local sec

    if elem.solid then
      sec = { solid=what_tex("wall", elem.solid) }
    else
      sec = copy_block(focus)

      if elem.f_h or elem.f_tex or elem.l_tex then
        sec.f_h   = what_h_ref(sec.f_h, elem.f_rel, elem.f_h, elem.f_add)
        sec.f_tex = what_tex("floor",elem.f_tex)
        sec.l_tex = what_tex("wall", elem.l_tex)
        sec.l_peg = elem.l_peg
      end

      if elem.c_h or elem.c_tex or elem.u_tex then
        sec.c_h   = what_h_ref(sec.c_h, elem.c_rel, elem.c_h, elem.c_add)
        sec.c_tex = what_tex("ceil", elem.c_tex)
        sec.u_tex = what_tex("wall", elem.u_tex)
        sec.u_peg = elem.u_peg
      end

      sec.x_offset = elem.x_offset
      sec.y_offset = elem.y_offset

      if elem.mark then sec.mark = elem.mark end

      if elem.kind then sec[elem.kind] = parm_val(elem.kind) end
      if elem.tag  then sec[elem.tag]  = parm_val(elem.tag) end

      if elem.kind == "door_kind" then sec.door_dir = parm.door_dir end

      if elem.light then
        sec.light = elem.light
        if type(sec.light) == "string" then sec.light = parm_val(sec.light) end
      end
      if elem.light_add then
        sec.light = sec.light + elem.light_add
      end
    end

    -- handle overrides

    for i = 1,9 do
      local OV = elem[i]
      if OV then
        OV = copy_block(OV)  -- don't modify the prefab!

        if OV.l_tex then OV.l_tex = what_tex("wall", OV.l_tex) end
        if OV.u_tex then OV.u_tex = what_tex("wall", OV.u_tex) end
        if OV.f_tex then OV.f_tex = what_tex("floor", OV.f_tex) end
        if OV.c_tex then OV.c_tex = what_tex("ceil", OV.c_tex) end
        if OV.rail  then OV.rail  = what_tex("rail", OV.rail) end

        if OV.x_offset and type(OV.x_offset) == "string" then OV.x_offset = parm_val(OV.x_offset) end
        if OV.y_offset and type(OV.y_offset) == "string" then OV.y_offset = parm_val(OV.y_offset) end

        if OV.kind then OV.kind = parm_val(OV.kind) end
        if OV.tag  then OV.tag  = parm_val(OV.tag) end

        if OV.dx or OV.dy then
          OV.dx, OV.dy = dd_coords(OV.dx or 0, OV.dy or 0)

          -- ensure that the writer doesn't swallow up the block
          -- (which would lose the vertex we want to move)
          if not sec.mark then
            sec.mark = allocate_mark(p)
          end
        end

        local s_dir = FAB_DIRECTION_MAP[dir + sel(mirror_x,10,0)][i]
        assert(s_dir)

        sec[s_dir] = OV
      end
    end

    return sec
  end

  local ROOM = focus
  local WALL = { solid=what_tex("wall", "wall") }

  -- cache for compiled elements
  local cache = {}

  for ey = 1,deep do for ex = 1,long do
    local fx, fy = f_coords(ex,ey)

    local e = string.sub(fab.structure[deep+1-ey], ex, ex)

    if e == " " then
      -- do nothing
    else
      local sec, elem

      if e == "#" then
        sec = WALL
      elseif e == "." then
        sec = ROOM
      else
        elem = fab.elements[e]

        if not elem then
          error("Unknown element '" .. e .. "' in prefab:" .. fab.name)
        end

        if not cache[e] then
          cache[e] = compile_element(elem)
        end

        sec = cache[e]
      end

      if fab.scale == 64 then
        fill(p,c, fx,fy, fx,fy, sec)
      else
        frag_fill(p,c, fx,fy, fx,fy, sec)
      end

      if elem and elem.thing then
        local bx, by
        if fab.scale == 64 then
          bx,by = fx,fy
        else
          -- FIXME: offsets
          bx = div_mod(fx, FW)
          by = div_mod(fy, FH)
        end

        add_thing(p, c, bx,by, what_thing(elem.thing), false, elem.angle)
      end
    end
  end end

  -- add the final touches: things

  if fab.things then
    for zzz,tdef in ipairs(fab.things) do

      local bx,by, dx,dy = th_coords(tdef.x, tdef.y)

      if tdef.kind ~= "pickup_t" then -- ????
        -- FIXME: blocking
        local th = add_thing(p, c, bx,by, what_thing(tdef.kind), false)

        th.dx = dx
        th.dy = dy
      end

    end
  end
end


--
-- Build a stair
--
-- (bx,by) is the lowest left corner (cf. B_prefab)
--
-- Z is the starting height
--
function B_stair(p,c, rmodel, bx,by, dir, long, deep, step)

  local dx, dy = dir_to_delta(dir)
  local ax, ay = dir_to_across(dir)

  if (dir == 2 or dir == 4) then
    bx,by = bx-(deep-1)*dx, by-(deep-1)*dy
  end

  local fx = (bx - 1) * FW + 1
  local fy = (by - 1) * FH + 1

  if (dir == 4) then fx = fx + FW - 1 end
  if (dir == 2) then fy = fy + FH - 1 end

  local zx = ax * (long*4-1)
  local zy = ay * (long*4-1)

  local z = rmodel.f_h

  -- first step is always raised off the ground
  if step > 0 then z = z + step end

  local out_dir = sel(step < 0, dir, 10-dir)

  local xo_dir1 = rotate_cw90(dir)
  local xo_dir2 = rotate_ccw90(dir)

  for i = 1,deep*4 do

    local sec = ---??? copy_block_with_new(c.rmodel, -- !!!!
    {
      rmodel = rmodel,

      f_h   = z,
      f_tex = c.combo.step_floor or rmodel.f_tex,
      l_tex = rmodel.l_tex,

      [out_dir] = { l_tex=c.combo.step, l_peg="top" },

      [xo_dir1] = { x_offset= i*16 },
      [xo_dir2] = { x_offset=-i*16 },
    }

    frag_fill(p,c, fx, fy, fx+zx, fy+zy, sec)

    fx = fx + dx
    fy = fy + dy
    z  = z  + step
  end
end


--
-- Build a lift
--
-- Z is the starting height
--
function B_lift(p,c, rmodel, bx,by, z, dir, long, deep)

  local dx, dy = dir_to_delta(dir)
  local ax, ay = dir_to_across(dir)

  if (dir == 2 or dir == 4) then
    bx,by = bx-(deep-1)*dx, by-(deep-1)*dy
  end

  local LIFT = ---??? copy_block_with_new(c.rmodel,
  {
    rmodel = rmodel,

    f_h = z,
    f_tex = c.combo.lift_floor or GAME.mats.LIFT.floor,
    l_tex = c.combo.lift or GAME.mats.LIFT.wall,

    lift_kind = 123,  -- 62 for slower kind
    lift_walk = 120,  -- 88 for slower kind

    tag = allocate_tag(p),

    [2] = { l_peg="top" }, [4] = { l_peg="top" },
    [6] = { l_peg="top" }, [8] = { l_peg="top" },
  }

  fill(p,c, bx, by,
       bx + (long-1) * ax + (deep-1) * dx,
       by + (long-1) * ay + (deep-1) * dy, LIFT)
end



function B_double_pedestal(p, c, bx, by, base, ped_info, overrides)
 
  local OUTER =
  {
    f_h   = ped_info.h + base.f_h,
    f_tex = ped_info.floor,
    l_tex = ped_info.wall,
    light = ped_info.light,

    c_h   = c.rmodel.c_h - ped_info.h,
    c_tex = ped_info.floor,
    u_tex = ped_info.wall,

    kind  = ped_info.glow and 8 -- GLOW TYPE  (FIXME)
  }

  local INNER =
  {
    f_h   = ped_info.h2 + base.f_h,
    f_tex = ped_info.floor2,
    l_tex = ped_info.wall2,
    light = ped_info.light2,

    c_h   = c.rmodel.c_h - ped_info.h2,
    c_tex = ped_info.floor2,
    u_tex = ped_info.wall2,

    kind = ped_info.glow2 and 8 -- GLOW TYPE  (FIXME)
  }

  if c.combo.outdoor then
    OUTER.c_h   = c.rmodel.c_h
    OUTER.c_tex = c.rmodel.c_tex

    INNER.c_h   = c.rmodel.c_h
    INNER.c_tex = c.rmodel.c_tex
  end

  assert((OUTER.c_h - OUTER.f_h) >= 64)
  assert((INNER.c_h - INNER.f_h) >= 64)

  local fx = (bx - 1) * FW
  local fy = (by - 1) * FH

  frag_fill(p,c, fx+1,fy+1, fx+4,fy+4, OUTER, overrides)

  if ped_info.rotate2 then
    frag_fill(p,c, fx+2,fy+2, fx+2,fy+2, INNER)

    c_move_frag_corner(p,c, fx+2,fy+2, 1, 16, -6)
    c_move_frag_corner(p,c, fx+2,fy+2, 3, 22, 16)
    c_move_frag_corner(p,c, fx+2,fy+2, 7, -6,  0)
    c_move_frag_corner(p,c, fx+2,fy+2, 9,  0, 22)
  else
    frag_fill(p,c, fx+2,fy+2, fx+3,fy+3, INNER)
  end
end


function cage_select_height(p,c, kind, rail, floor_h, ceil_h)

  if c[kind] and c[kind].z >= floor_h and rand_odds(80) then
    return c[kind].z, c[kind].open_top
  end
  
  local open_top = false

  if rail.h < 72 then open_top = true end
  if ceil_h >= floor_h + 256 then open_top = true end
  if dual_odds(c.outdoor, 50, 10) then open_top = true end

  local z1 = floor_h + 32
  local z2 = math.min(floor_h + 128, ceil_h - 16 - rail.h)

  local r = con.random() * 100
      if r < 16 then z2 = z1
  elseif r < 50 then z1 = z2
  end

  z1 = (z1+z2)/2

  if not c[kind] then
    c[kind] = { z=z1, open_top=open_top }
  end

  return (z1+z2)/2, open_top
end

function B_pillar_cage(p,c, theme, kx,ky, bx,by)

  local K = c.chunks[kx][ky]

  local rail
  if K.rmodel.c_h < K.rmodel.f_h+192 then
    rail = GAME.rails["r_1"]  -- FIXME: want "short" rail
  else
    rail = get_rand_rail()
  end
  assert(rail)

  local kind = sel(kx==2 and ky==2, "middle_cage", "pillar_cage")

  local z, open_top = cage_select_height(p,c, kind, rail, K.rmodel.f_h,K.rmodel.c_h)

  if kx==2 and ky==2 and dual_odds(c.theme.outdoor, 90, 20) then
    open_top = true
  end

  local CAGE = copy_block_with_new(K.rmodel,
  {
    f_h   = z,
    f_tex = theme.floor,
    l_tex = theme.wall,
    u_tex = theme.wall,
    rail  = rail.wall,
    is_cage = true,
  })

  if not open_top then
    CAGE.c_h = CAGE.f_h + rail.h
    CAGE.c_tex = theme.ceil
    CAGE.light = 192  -- FIXME: from CAGE theme
  end

--  if K.dud_chunk and (c.theme.outdoor or not c.sky_light) then
--    rotate_block(CAGE,32)
--  end

  fill(p,c, bx,by, bx,by, CAGE)

  local spot = {c=c, x=bx, y=by}
  if kx==2 and ky==2 then spot.different = true end

  add_cage_spot(p,c, spot)
end


--
-- Build a hidden monster closet
--
function B_monster_closet(p,c, K,kx,ky, z, tag)

  local bx, by = K.x1, K.y1

  local INNER = copy_block_with_new(c.rmodel,
  {
    f_h = z,

    --!! c_tex = c.combo.arch_ceil or c.rmodel.f_tex,

    l_tex = c.combo.void,
    u_tex = c.combo.void,

    is_cage = true,
  })

  local OUTER = copy_block_with_new(INNER,
  {
    c_h   = INNER.f_h,
    c_tex = c.combo.arch_ceil or INNER.f_tex,
    tag   = tag,
  })

  local fx = (bx - 1) * FW
  local fy = (by - 1) * FH

  frag_fill(p,c, fx+1,fy+1, fx+3*FW,fy+3*FH, OUTER);
  frag_fill(p,c, fx+2,fy+2, fx+3*FW-1,fy+3*FH-1, INNER)

  return { c=c, x=bx, y=by, double=true, dx=32, dy=32 }
end


--
-- Build a scenic vista!
--
-- c is the cell the walks out into the vista.
-- The other cell actually contains the vista.
-- 
-- The 'kind' can be: "solid", "frame", "open", "wire" OR "fall_over".
--
function B_vista(p, src,dest, x1,y1, x2,y2, side, b_combo,kind)

  local ROOM
  
  if kind == "solid" then
    ROOM = copy_block(src.rmodel)
  else
    ROOM = copy_block(dest.rmodel)
  end

  ROOM.f_h   = src.rmodel.f_h
  ROOM.f_tex = src.rmodel.f_tex
  ROOM.l_tex = b_combo.wall
  ROOM.u_tex = b_combo.wall

  ROOM.light = (src.rmodel.light + dest.rmodel.light) / 2

  if kind == "solid" then
    local h = rand_index_by_probs { 20, 80, 20, 40 }

    ROOM.c_h = ROOM.f_h + 96 + (h-1)*32

    if ROOM.c_h > dest.sky_h then
       ROOM.c_h = math.max(dest.sky_h, ROOM.f_h + 96)
    end
  end


  local LEDGE = copy_block(ROOM)

  if kind ~= "fall_over" then
    LEDGE.f_h = ROOM.f_h + 32
    LEDGE.impassible = true
  end

  if kind == "solid" then
    LEDGE.c_h = math.min(ROOM.c_h - 24, ROOM.f_h + 96)
  
  elseif kind == "frame" then
    LEDGE.c_h = ROOM.c_h - 24
    LEDGE.c_tex = b_combo.ceil
  end


  local ax,ay = dir_to_across(side)

  local fx1 = (x1 - 1) * FW + 1
  local fy1 = (y1 - 1) * FH + 1

  local fx2 = x2 * FW
  local fy2 = y2 * FH

  local px1,py1, px2,py2 = side_coords(side,    fx1,fy1, fx2,fy2)
  local wx1,wy1, wx2,wy2 = side_coords(10-side, fx1,fy1, fx2,fy2)


  if kind == "wire" or kind == "fall_over" then

    local rail = get_rand_rail()

    local curved = rand_odds(90)

    local cv_x1,cv_y1, cv_x2,cv_y2 = side_coords(side, x1,y1, x2,y2)
    local cv_dir1,cv_dir2

        if side == 2 then cv_dir1,cv_dir2 = 1,3
    elseif side == 4 then cv_dir1,cv_dir2 = 1,7
    elseif side == 6 then cv_dir1,cv_dir2 = 3,9
    elseif side == 8 then cv_dir1,cv_dir2 = 7,9
    end

    for x = x1,x2 do
      for y = y1,y2 do

        local overrides = {}

        if kind == "wire" then
          if x == x1 then overrides[4] = { rail=rail.wall, impassible=true } end
          if x == x2 then overrides[6] = { rail=rail.wall, impassible=true } end
          if y == y1 then overrides[2] = { rail=rail.wall, impassible=true } end
          if y == y2 then overrides[8] = { rail=rail.wall, impassible=true } end

          -- don't block the entryway
          overrides[10-side] = nil
        end

        -- curve ball!
        if curved then
          local dx,dy = dir_to_delta(10-side)
          if (x == cv_x1 and y == cv_y1) then
            -- 48 is the magical distance to align the railing
            overrides[cv_dir1] = { dx=(dx*48), dy=(dy*48) }
            overrides.mark = allocate_mark(p)
          end
          if (x == cv_x2 and y == cv_y2) then
            overrides[cv_dir2] = { dx=(dx*48), dy=(dy*48) }
            overrides.mark = allocate_mark(p)
          end
        end

        fill(p,src, x,y, x,y, ROOM, overrides)
      end
    end

  else -- solid, frame, open or fall_over

    frag_fill(p,src, fx1,fy1, fx2,fy2, LEDGE)
    frag_fill(p,src, fx1+1,fy1+1, fx2-1,fy2-1, ROOM)

    --- walkway ---

    frag_fill(p,src, wx1+ax,wy1+ay, wx2-ax,wy2-ay, ROOM)
  end


  --- pillars ---
  if kind == "solid" or kind == "frame" then

    local support = b_combo.wall  -- FIXME: "SUPPORT2"
    
    frag_fill(p,src, px1,py1, px1,py1, { solid=support })
    frag_fill(p,src, px2,py2, px2,py2, { solid=support })


    if false then  -- FIXME
      px1 = int((px1+wx1)/2)
      py1 = int((py1+wy1)/2)
      px2 = int((px2+wx2)/2)
      py2 = int((py2+wy2)/2)

      frag_fill(p,src, px1,py1, px1,py1, { solid=support })
      frag_fill(p,src, px2,py2, px2,py2, { solid=support })
    end
  end 


  -- FIXME !!! add spots to room
  -- return { c=src, x=x1+dx, y=y1+dy, double=true, dx=32, dy=32 }
end


function B_exit_elevator(p, c, x, y, side)

  fab = PREFABS["WOLF_ELEVATOR"]
  assert(fab)
  local parm =
  {
    door_kind = "door_elevator", door_dir = side,
  }
  local skin =
  {
    elevator = 21, front = 14,
  }

  local dir = 10-side
  -- FIXME: generalise this
  if side == 2 then x=x-1
  elseif side == 8 then x=x-1; y=y-fab.deep+1
  elseif side == 4 then y=y-1
  elseif side == 6 then x=x-fab.deep+1; y=y-1
  end

  B_prefab(p, c, fab, skin, parm, c.rmodel,c.combo, x, y, dir)
end


----------------------------------------------------------------

SKY_LIGHT_FUNCS =
{
  all      = function(kx,ky, x,y) return true end,
  middle   = function(kx,ky, x,y) return kx==2 and ky==2 end,
  pillar   = function(kx,ky, x,y) return not (kx==2 and ky==2) end,

--  pillar_2 = function(kx,ky, x,y) return kx==2 and ky==2 end,

  double_x = function(kx,ky, x,y) return (x % 2) == 0 end,
  double_y = function(kx,ky, x,y) return (y % 2) == 0 end,

  triple_x = function(kx,ky, x,y) return (x % 3) == 2 end,
  triple_y = function(kx,ky, x,y) return (y % 3) == 2 end,

  holes_2 = function(kx,ky, x,y) return (x % 2) == 0 and (y % 2) == 0 end,
  holes_3 = function(kx,ky, x,y) return (x % 3) == 2 and (y % 3) == 2 end,

  boggle = function(kx,ky, x,y)
    return not ((x % 3) == 2 or (y % 3) == 2) end,

  pin_hole = function(kx,ky, x,y)
    return kx==2 and ky==2 and (x % 3 )== 2 and (y % 3) == 2 end,

  cross_1 = function(kx,ky, x,y)
    return (kx==2 and (x % 3) == 2) or 
           (ky==2 and (y % 3) == 2) end,

  cross_2 = function(kx,ky, x,y)
    return (kx==2 and ky==2) and
      ((x % 3) == 2 or (y % 3) == 2) end,

  pieces_1 = function(kx,ky, x,y)
    return (kx~=2 and ky==2 and (y%3)==2) or
           (kx==2 and ky~=2 and (x%3)==2) end,

  pieces_2 = function(kx,ky, x,y)
    return (kx~=2 and ky==2 and (x%3)==2) or
           (kx==2 and ky~=2 and (y%3)==2) end,

  weird = function(kx,ky, x,y)
    return (kx==2 or ky==2) and not (kx==2 and ky==2) and
      ((x % 3) == 2 or (y % 3) == 2) end,

--  cross = function(kx,ky, x,y) return kx==2 or  ky==2 end,
--  hash  = function(kx,ky, x,y)
--    return (kx==2 or ky==2) and not
--      ((x % 3) == 1 or (y % 3) == 1) end,
}

function random_sky_light()
  local names = {}
  for kind,func in pairs(SKY_LIGHT_FUNCS) do
    table.insert(names,kind)
  end
  return rand_element(names)
end


----------------------------------------------------------------


function setup_rmodel(p, c)

  c.rmodel =
  {
    f_h=c.floor_h,
    f_tex=c.combo.floor,
    l_tex=c.combo.wall,

    c_h=c.ceil_h,
    c_tex=c.combo.ceil,
    u_tex=c.combo.wall,

    light=c.light,

    floor_code=c.floor_code,
  }

  if c.combo.outdoor then
    c.rmodel.c_tex = GAME.SKY_TEX
  end

  if not c.rmodel.light then
    c.rmodel.light = sel(c.combo.outdoor, 192, 144)
  end

  c.mark = allocate_mark(p)
end

function make_chunks(p)

  local K_BORD_PROBS = { 0, 60, 90, 15, 5, 1 }

  local function decide_chunk_sizes(total)
    assert(total >= 3)

    if total <  6 then return 1, total-2, 1 end
    if total == 6 then return 2, 2, 2 end

    local L, M, R

    repeat
        L = rand_index_by_probs(K_BORD_PROBS)
        R = rand_index_by_probs(K_BORD_PROBS)
        M = total - L - R
    until M >= 2 and M <= 6

    return L, M, R
  end

  local function create_chunks(c)

    local cell_w = c.bx2 - c.bx1 + 1
    local cell_h = c.by2 - c.by1 + 1

    assert(cell_w >= GAME.cell_min_size)
    assert(cell_h >= GAME.cell_min_size)

    c.chunks = array_2D(3, 3)

    -- decide depths of each side
    local L, M, R = decide_chunk_sizes(cell_w)
    local B, N, T = decide_chunk_sizes(cell_h)

    -- actually create the chunks

    for kx = 1,3 do for ky = 1,3 do
       local w  = sel(kx == 1, L, sel(kx == 2, M, R))
       local h  = sel(ky == 1, B, sel(ky == 2, N, T))

       local dx = sel(kx == 1, 0, sel(kx == 2, L, L+M))
       local dy = sel(ky == 1, 0, sel(ky == 2, B, B+N))

       c.chunks[kx][ky] =
       {
         kx=kx, ky=ky, w=w, h=h,

         x1 = c.bx1 + dx,
         y1 = c.by1 + dy,
         x2 = c.bx1 + dx + w-1,
         y2 = c.by1 + dy + h-1,

         kind="empty"
       }
    end end
  end
  
  local function count_empty_chunks(c)
    local count = 0
    for kx = 1,3 do
      for ky = 1,3 do
        if not c.chunks[kx][ky] then
          count = count + 1
        end
      end
    end
    return count
  end


  local function set_link_coords(c, side, link)
    
    local D = c.border[side]
    assert(D)

    assert(link.long <= D.long)

    if link.where == "double" or link.where == "wide" or
       link.long == D.long
    then
      link.x1, link.y1 = D.x1, D.y1
      link.x2, link.y2 = D.x2, D.y2

      return
    end

    local diff = D.long - link.long
    local pos

        if link.where == -2 then pos = 0
    elseif link.where == -1 then pos = int((diff+2)/4)
    elseif link.where ==  0 then pos = int(diff / 2)
    elseif link.where ==  1 then pos = diff - int((diff+2)/4)
    elseif link.where ==  2 then pos = diff
    else
      error("Bad where value: " .. tostring(link.where))
    end

    if link.where == 0 and (diff % 2) == 1 and (side < 5) then
      pos = pos + 1
    end

    local ax, ay = dir_to_across(side)

    link.x1 = D.x1 + pos * ax
    link.y1 = D.y1 + pos * ay

--con.printf("link_L:%d border_L:%d  where:%d -> pos:%d..%d\n",
--link.long, D.long, link.where, pos, pos + link.long - 1)

    pos = pos + link.long - 1

    link.x2 = D.x1 + pos * ax
    link.y2 = D.y1 + pos * ay

--con.printf("BORDER: (%d,%d) .. (%d,%d)\n", D.x1, D.y1, D.x2, D.y2)
--con.printf("LINK:   (%d,%d) .. (%d,%d)\n", link.x1, link.y1, link.x2, link.y2)

    assert(link.x1 >= D.x1); assert(link.y1 >= D.y1)
    assert(link.x2 <= D.x2); assert(link.y2 <= D.y2)
  end

  local function overlaps_chunk(K, x1,y1, x2,y2)

    if x2 < K.x1 or x1 > K.x2 then return false end
    if y2 < K.y1 or y1 > K.y2 then return false end

    return true
  end
  
  local function alloc_door_spot(c, side, link)

    local clasher
    local dx,dy = dir_to_delta(side)

    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]

      if overlaps_chunk(K, link.x1-dx, link.y1-dy, link.x2-dx, link.y2-dy) then

        if K.kind == "link" then
          clasher = K.link

        else
          K.kind = "link"
          K.link = link
        end
      end 
    end end

    return clasher

--[[ OLDIES BUT GOODIES...

    -- figure out which chunks are needed

    local kx, ky = side_to_chunk(side)
    local ax, ay = dir_to_across(side)

    assert(not c.chunks[kx][ky].link)

    if link.where == "double" then
      table.insert(coords, {x=kx+ax, y=ky+ay})
      table.insert(coords, {x=kx-ax, y=ky-ay})
      
      local no_void = c.closet[2] or c.closet[4] or c.closet[6] or c.closet[8]

      -- what shall we put in-between?
      local r = con.random() * 100
      local K
      if r < 40 then
        c.chunks[kx][ky] = new_chunk(c, kx,ky, "link",link)
      elseif r < 80 or no_void then
        c.chunks[kx][ky] = new_chunk(c, kx,ky, "room")
      else
        c.chunks[kx][ky] = new_chunk(c, kx,ky, "void")
      end

    elseif link.where == "wide" then
      table.insert(coords, {x=kx+ax, y=ky+ay})
      table.insert(coords, {x=kx   , y=ky   })
      table.insert(coords, {x=kx-ax, y=ky-ay})

    else
      local d_pos = where_to_block(link.where, link.long)
      -- FIXME DUPLICATED SHITE
      local d_min, d_max = 1, BW - (link.long-1)
      if (d_pos < d_min) then d_pos = d_min end
      if (d_pos > d_max) then d_pos = d_max end

      local j1 = int((d_pos - 1) / JW)
      local j2 = int((d_pos - 1 + link.long-1) / JW)
      
      for j = j1,j2 do
        assert (0 <= j and j < KW)
        table.insert(coords,
          { x = kx-ax + ax * j, y = ky-ay + ay * j })
      end

    end

    -- now check for clashes
    local has_clash = false

    for zzz,loc in ipairs(coords) do

      kx, ky = loc.x, loc.y
      assert (1 <= kx and kx <= KW)
      assert (1 <= ky and ky <= KH)

      if c.chunks[kx][ky] then
        -- do c.chunks[kx][ky] = { link="#" }; return true end
        has_clash = true
        c.chunks.clasher = c.chunks[kx][ky]
      else
        c.chunks[kx][ky] = new_chunk(c, kx,ky, "link",link )
      end
    end
    return not has_clash
--]]
  end

  local function clear_link_allocs(c)
    c.got_links = nil

    for kx = 1,3 do for ky = 1,3 do
      c.chunks[kx][ky].kind  = "empty"
    end end
  end

  local function alloc_link_chunks(c, loop)

    -- last time was successful, nothing to do
    if c.got_links then return true end

    for side,L in pairs(c.link) do

      local clash_L = alloc_door_spot(c, side, L)

      if clash_L then

        con.debugf("CLASH (%d,%d) -> (%d,%d)  L:%s/%s  K:%s/%s\n",
          clash_L.cells[1].x, clash_L.cells[1].y,
          clash_L.cells[2].x, clash_L.cells[2].y,
          L.kind, L.where, clash_L.kind, clash_L.where)

        -- be fair about which link we will blame
        if rand_odds(50) then
          L = clash_L

          for i = 2,8,2 do
            if c.link[i] == L then
              side = i
              break
            end
          end
        end

        assert(c.link[side] == L)

        local other = link_other(L, c)

        -- reset the allocation in the offending cells
        clear_link_allocs(c)
        clear_link_allocs(other)

        -- choose a new place
        L.where = random_where(L, c.border[side])
        set_link_coords(c, side, L)

        if loop >= 512 then

          -- Emergency!! our options are to:
          --   1. reorganise chunks
          --   2. make links narrower
          --   3. remove falloffs/vistas

          if (loop % 8) < 3 then
            create_chunks(c)
          elseif (loop % 8) < 6 then
            L.long = 2
          elseif (L.kind == "vista") or (L.kind == "falloff") then
            c.link[side] = nil
            other.link[10-side] = nil
          end
        end

        return false
      end
    end

    c.got_links = true

    return true
  end


  local function add_travel_chunks(c)

    -- give each chunk a travel ID.  Touching chunks can
    -- merge the id's (choose lowest value).  After some
    -- iterations, the existence of multiple IDS means that
    -- we need to add extra chunks.

    -- These are shuffled to give better randomness of the
    -- grow algorithm.  They are re-used for efficiency.
    local SIDES  = { 2,4,6,8 }
    local KX_MAP = { 1,2,3 }
    local KY_MAP = { 1,2,3 }

    local function init()
      local chunk_list = {}
      
      for kx = 1,3 do for ky = 1,3 do
        local K = c.chunks[kx][ky]
        K.travel_id = ky*10 + kx
        if K.kind ~= "empty" then
          table.insert(chunk_list, { x=kx,y=ky })
        end
      end end
      
      return chunk_list
    end
    
    local function merge()
      for loop=1,12 do
        for kx = 1,3 do for ky = 1,3 do
          for side = 6,8,2 do
            local dx, dy = dir_to_delta(side)
            local nx, ny = kx+dx, ky+dy

            if valid_chunk(nx,ny) then
              local K1 = c.chunks[kx][ky]
              local K2 = c.chunks[nx][ny]

              if K1.kind ~= "empty" and K2.kind ~= "empty" then
                K1.travel_id = math.min(K1.travel_id, K2.travel_id)
                K2.travel_id = K1.travel_id
              end
            end
          end
        end end
      end
    end

    local function has_islands()
      local last
      for kx = 1,3 do for ky = 1,3 do
        local K = c.chunks[kx][ky]
        if K.kind == "empty" then
          -- skip it
        elseif not last then last = K
        elseif K.travel_id ~= last.travel_id then 
          return true
        end
      end end
      return false
    end

    local function grow(chunk_list)
      
      local function grow_a_pair(K, N, bridge)

        assert(N.kind == "empty")

        if N.kx==2 and N.ky==2 and rand_odds(50) then
          N.kind = "room"
        elseif K.kind == "vista" then
          if bridge and bridge.link and bridge.kind ~= "vista" then
            N.kind = "link"
            N.link = bridge.link
          else
            N.kind = "room"
          end
        else
          assert(K.kind == "link" or K.kind == "room")
          N.kind = K.kind
          N.link = K.link
        end

        table.insert(chunk_list, { x=N.kx, y=N.ky })
      end

      -- look for the optimal solution: a "bridge" between two
      -- different groups.  Do it by studying the empty chunks.

      rand_shuffle(SIDES)
      rand_shuffle(KX_MAP)
      rand_shuffle(KY_MAP)

      for ix=1,3 do for iy=1,3 do
        local kx,ky = KX_MAP[ix], KY_MAP[iy]
        local K = c.chunks[kx][ky]

        if K.kind == "empty" then
          local last_K

          for zzz,side in ipairs(SIDES) do
            local N = chunk_neighbour(c, K, side)
            local dx,dy = dir_to_delta(side)

            if N and N.kind ~= "empty" then
              if not last_K then
                last_K = N
              elseif N.travel_id ~= last_K.travel_id then
                -- FOUND ONE !!
                con.debugf("Found travel bridge @ (%d,%d) [%d,%d]^%d\n", c.x,c.y, kx,ky,side)
                if rand_odds(50) then
                  grow_a_pair(last_K, K, N)
                else
                  grow_a_pair(N, K, last_K)
                end
                return true
              end
            end

          end
        end
      end end

      -- failing that, grow a chunk at random

      for i = 1,#chunk_list do

        local kx,ky = chunk_list[i].x, chunk_list[i].y
        local K1 = c.chunks[kx][ky]
        assert(K1 and K1.kind ~= "empty")

        for zzz,side in ipairs(SIDES) do
          local dx,dy = dir_to_delta(side)
          if valid_chunk(kx+dx, ky+dy) then
            local K2 = c.chunks[kx+dx][ky+dy]
            assert(K2)
        
            if K2.kind == "empty" then
              grow_a_pair(K1, K2)
              return true
            end

          end
        end

        -- try next chunk in list...
      end

      error("add_travel_chunks: grow failed!")
    end

    --- add_travel_chunks ---

    if c.scenic then return end

    do
      local MID = c.chunks[2][2]

      if MID.kind == "empty" and not c.hallway and
         (c == p.quests[1].first or c == c.quest.last or rand_odds(25*0)) --!!!!!!!
      then
        MID.kind = "room"
      end
    end
 
    chunk_list = init()

    assert(#chunk_list >= 1)

    merge()

    for loop=1,99 do
      if not has_islands() then break end
      
      rand_shuffle(chunk_list)
      rand_shuffle(SIDES)
      
      grow(chunk_list)
      merge()
    end
  end


  local function chunk_similar(k1, k2)
    assert(k1 and k2)
    if k1.void and k2.void then return true end
    if k1.room and k2.room then return true end
    if k1.cage and k2.cage then return true end
    if k1.liquid and k2.liquid then return true end
    if k1.link and k2.link then return k1.link == k2.link end
    return false
  end

  local BIG_CAGE_ADJUST = { less=50, normal=75, more=90 }

  local function try_flush_side(c)

    -- select a side
    local side = rand_irange(1,4) * 2
    local x1, y1, x2, y2 = side_coords(side, 1,1, 3,3)

    local common
    local possible = true

    for x = x1,x2 do
      for y = y1,y2 do
        if not possible then break end
        
        local K = c.chunks[x][y]

        if not K then
          -- continue
        elseif K.vista then
          possible = false
        elseif not common then
          common = K
        elseif not chunk_similar(common, K) then
          possible = false
        end
      end
    end

    if not (possible and common) then return end

    if not p.coop then
      -- let user adjustment parameters control whether closets and
      -- cages are made bigger.
      if common.closet and not rand_odds(BIG_CAGE_ADJUST[settings.traps]) then
        return
      end
      if common.cage and not rand_odds(BIG_CAGE_ADJUST[settings.mons]) then
        return
      end
    end

    for kx = x1,x2 do
      for ky = y1,y2 do
        if not c.chunks[kx][ky] then
          c.chunks[kx][ky] = copy_chunk(c, kx, ky, common)
        end
      end
    end
  end

  local function try_grow_room(c)
    local kx, ky

    repeat
      kx, ky = rand_irange(1,3), rand_irange(1,3)
    until c.chunks[kx][ky] and c.chunks[kx][ky].room

    local dir_order = { 2,4,6,8 }
    rand_shuffle(dir_order)

    for zzz,dir in ipairs(dir_order) do
      local nx,ny = dir_to_delta(dir)
      nx, ny = kx+nx, ky+ny

      if valid_chunk(nx, ny) then
        if not c.chunks[nx][ny] then
          c.chunks[nx][ny] = new_chunk(c, nx, ny, "room")
          return -- SUCCESS --
        end
      end
    end
  end

  local function try_add_special(c, kind)
    
    if kind == "liquid" then
      if not c.liquid then return end
      if c.is_exit and rand_odds(98) then return end
    end

    -- TODO: more cage themes...
    if kind == "cage" then
      if not GAME.mats.CAGE then return end
      if c.scenic then return end
    end

    local posits = {}

    for kx = 1,3 do
      for ky = 1,3 do
        if not c.chunks[kx][ky] then
          -- make sure cage has a walkable neighbour
          for dir = 2,8,2 do
            local nx,ny = dir_to_delta(dir)
            nx, ny = kx+nx, ky+ny

            if valid_chunk(nx, ny) and c.chunks[nx][ny] and
               (c.chunks[nx][ny].room or c.chunks[nx][ny].link)
            then
              table.insert(posits, {x=kx, y=ky})
              break;
            end
          end
        end
      end
    end

    if #posits == 0 then return end

    local p = rand_element(posits)

    c.chunks[p.x][p.y] = new_chunk(c, p.x, p.y, kind)
  end

  local function add_closet_chunks(c)
    if not c.quest.closet then return end

    local closet = c.quest.closet

    for idx,place in ipairs(closet.places) do
      if place.c == c then

        -- !!! FIXME: determine side _HERE_ (not in planner)
        local kx,ky = side_to_chunk(place.side)

        if c.chunks[kx][ky] then
          con.printf("WARNING: monster closet stomped a chunk!\n")
          con.printf("CELL (%d,%d)  CHUNK (%d,%d)\n", c.x, c.y, kx, ky)
          con.printf("%s\n", table_to_str(c.chunks[kx][ky], 2))

          show_chunks(p)
        end

        con.debugf("CLOSET CHUNK @ (%d,%d) [%d,%d]\n", c.x, c.y, kx, ky)

        local K = new_chunk(c, kx,ky, "void")
        K.closet = true
        K.place = place

        c.chunks[kx][ky] = K
      end
    end
  end

  local function grow_small_exit(c)
    assert(c.entry_dir)
    local kx,ky = side_to_chunk(10 - c.entry_dir)

    if c.chunks[kx][ky] then
      con.printf("WARNING: small_exit stomped a chunk!\n")
    end

    local r = con.random() * 100

    if r < 2 then
      c.chunks[kx][ky] = new_chunk(c, kx,ky, "room")
    elseif r < 12 then
      c.chunks[kx][ky] = new_chunk(c, kx,ky, "cage")
      c.smex_cage = true
    end

    void_it_up(c)
  end

  local function add_dm_exit(c)

    if c.chunks[1][3] then
      con.printf("WARNING: deathmatch exit stomped a chunk!\n")
    end

    local K = new_chunk(c, 1,3, "void")
    K.dm_exit = true
    K.dir = 2

    c.chunks[1][3] = K

    if not c.chunks[1][2] then
      c.chunks[1][2] = new_chunk(c, 1,2, "room")
    end
  end

  local function flesh_out_cell(c)
    
    if p.deathmatch and c.x == 1 and c.y == p.h then
      add_dm_exit(c)
    end

    -- possibilities:
    --   (a) fill unused chunks with void
    --   (b) fill unused chunks with room
    --   (c) fill unused chunk from nearby ledge

    -- FIXME get probabilities from theme
    local kinds = { "room", "void", "flush", "cage", "liquid" }
    local probs = { 60, 10, 97, 5, 70 }

    if not c.combo.outdoor then probs[2] = 15 end

    if settings.mons == "less" then probs[4] = 3.2 end
    if settings.mons == "more" then probs[4] = 7.5 end

    if p.deathmatch then probs[4] = 0 end

    if c.scenic then probs[2] = 2; probs[4] = 0 end

    -- special handling for hallways...
    if c.hallway then
      if rand_odds(probs[4]) then
        try_add_special(c, "cage")
      end
      void_it_up(c)
    end

    if c.small_exit then
      grow_small_exit(c)
    end

    if c.scenic and c.vista_from then
      -- Bleh...
      if c.liquid and rand_odds(75) then
        void_it_up(c, "liquid")
      else
        void_it_up(c, "room")
      end
    end

    while count_empty_chunks(c) > 0 do

      local idx = rand_index_by_probs(probs)
      local kind = kinds[idx]

      if kind == "room" then
        try_grow_room(c)
      elseif kind == "void" then
        void_it_up(c)
      elseif kind == "flush" then
        try_flush_side(c)
      else
        try_add_special(c, kind)
      end
    end
  end


  local function setup_chunk_rmodels(c)

    local empties = {}
    local SIDES   = { 2,4,6,8 }

    local function gunk_pass(K)
      for zzz,side in ipairs(SIDES) do

        local N = chunk_neighbour(c, K, side)
        if N and N.rmodel and N.kind ~= "vista" then

          K.rmodel = copy_table(N.rmodel)
-- [[ !!!!
          if K.kind == "empty" then
            K.kind = N.kind
            K.link = N.link
          end
--]]
          return
        end
      end
    end

    --- STEP 1: setup known chunks
 
    local highest
 
    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]
      assert(K)

      if K.kind == "empty" then
        table.insert(empties, K)

      elseif K.kind == "vista" then
        -- fixed up later

      else -- "room", "link" etc..
        K.rmodel = copy_table(c.rmodel)

        if K.link then
          local other = link_other(K.link, c)

          if K.link.build == c or K.link.kind == "falloff" then
            -- no change
          else
            K.rmodel.f_h = other.rmodel.f_h
            K.rmodel.c_h = math.max(c.rmodel.c_h, other.rmodel.c_h)
          end
        end

        if not highest or highest.f_h < K.rmodel.f_h then
          highest = K.rmodel
        end

        if K.kind == "liquid" then -- FIXME
          K.rmodel.f_h   = K.rmodel.f_h - 12
          K.rmodel.f_tex = c.liquid.floor
        end
      end
    end end

    --- STEP 2: setup empty chunks

    -- none at all ? (Scenic cells)
    if not highest then
      highest = c.rmodel
      while #empties > 0 do
        local K = table.remove(empties)
        K.rmodel = copy_table(highest)
        K.kind = "room"
      end
    end

    while #empties > 0 do
      rand_shuffle(empties)
      rand_shuffle(SIDES)

      local K = table.remove(empties, 1)

      gunk_pass(K)

      if not K.rmodel then  -- try again later
        assert(#empties > 0)
        table.insert(empties, K)
      end
    end

    -- STEP 3: setup vistas, remembering the "empty" rmodel

    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]
      assert(K)

      if K.kind == "vista" then
        local other = link_other(K.link, c)

        K.ground_model = copy_table(highest)
        K.rmodel = copy_table(other.rmodel)
      end
    end end

--[[
    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]
      K.rmodel.light =
       sel(kx==2 and ky==2, 176,
        sel(kx==2 or ky==2, 144, 112))
    end end
--]]

    -- fix c_min and c_max values
    c.c_min =  99999
    c.c_max = -99999

    local M_min =  99999
    local M_max = -99999

    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]

      c.c_min = math.min(c.c_min, K.rmodel.c_h)
      c.c_max = math.max(c.c_max, K.rmodel.c_h)

      if (kx==2) or (ky==2) then
        M_min = math.min(M_min, K.rmodel.c_h)
        M_max = math.max(M_max, K.rmodel.c_h)
      end
    end end

    -- raise middle ceiling to match highest neighbour
    if not c.combo.outdoor then
      local mid_K = c.chunks[2][2]

      if M_max - M_min >= 48 then
        mid_K.rmodel.c_h = (M_min + M_max) / 2
      else
        mid_K.rmodel.c_h = M_max
      end
    end
  end

  local function mark_vista_chunks(c)

    -- mark the chunks containing the intruder
    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]
      if K.link and K.link.kind == "vista" and c == K.link.vista_dest then
        K.kind = "vista"
      end
    end end
  end

  local function create_huge_vista(c)

    if c.chunks[2][2].kind ~= "empty" then return end

--    if rand_odds(75) then return end

    local vista_x, vista_y

    local side_vistas   = 0
    local corner_vistas = 0

    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]
      if K.kind == "vista" then
        vista_x, vista_y = kx, ky
        if kx==2 or ky==2 then
          side_vistas = side_vistas + 1
        else
          corner_vistas = corner_vistas + 1
        end
      end
    end end

    if side_vistas ~= 1 or corner_vistas > 0 then return end

    con.debugf("Making HUGE VISTA @ (%d,%d)\n", c.x, c.y);

    local K = c.chunks[vista_x][vista_y]
    assert(K and K.kind == "vista")

    local N = c.chunks[2][2]

    N.kind  = "vista"
    N.link  = K.link

    K.link.huge = true
  end

  local function add_vista_environs(c)

    -- make sure the vista(s) have something to see

    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]
      if K.kind == "vista" then
        for nx = kx-1,kx+1 do for ny = ky-1,ky+1 do
          local N = valid_chunk(nx, ny) and c.chunks[nx][ny]
          if N and N.kind == "empty" then
            N.kind = "room"
          end
        end end
      end
    end end
  end

  local function add_stairs(c)

    --> result: certain chunks have a "stair_dir" field.
    -->         Direction to neighbour chunk.  Stair/Lift will
    -->         be built inside that chunk.

    local function init_connx()

      for kx = 1,3 do for ky = 1,3 do
        local K = c.chunks[kx][ky]
        assert(K)

        K.stair = {}

        if K.kind == "room" or K.kind == "link" or K.kind == "liquid" then
          K.connect_id = ky*10 + kx
        end
      end end
    end

    local function is_fully_connected()
      local last
      for kx = 1,3 do for ky = 1,3 do
        local K = c.chunks[kx][ky]
        if not K.connect_id then
          -- skip it
        elseif not last then last = K
        elseif K.connect_id ~= last.connect_id then 
          return false
        end
      end end
      return true
    end

    local function merge_connx()

      local function are_connected(K, N, dir)
        if math.abs(K.rmodel.f_h - N.rmodel.f_h) <= 16 then
          return true
        end
        if K.stair[dir] then return true end
        return false
      end

      for loop = 1,12 do
        for kx = 1,3 do for ky = 1,3 do
          local K1 = c.chunks[kx][ky]
          for dir = 6,8,2 do
            local dx,dy = dir_to_delta(dir)
            if valid_chunk(kx+dx,ky+dy) then
              local K2 = c.chunks[kx+dx][ky+dy]
              if K1.connect_id and K2.connect_id and are_connected(K1,K2, dir) then
                K1.connect_id = math.min(K1.connect_id, K2.connect_id)
                K2.connect_id = K1.connect_id
              end
            end
          end
        end end
      end
    end

    local function add_one_stair()

      -- find the best chunk pair to use

      local best_diff = 999999
      local coords = {}

      for kx = 1,3 do for ky = 1,3 do
        local K = c.chunks[kx][ky]

          for side = 6,8,2 do
            local dx,dy = dir_to_delta(side)

            if valid_chunk(kx+dx, ky+dy) then
              local N = c.chunks[kx+dx][ky+dy]
              if K.connect_id and N.connect_id and K.connect_id ~= N.connect_id then

                local diff = math.abs(K.rmodel.f_h - N.rmodel.f_h)
                assert(diff > 16)

                if diff < best_diff then
                  -- clear out the previous (worse) results
                  coords = {}
                  best_diff = diff
                end

                if diff == best_diff then
                  table.insert(coords, { x=kx, y=ky, side=side, K=K, N=N })
                end
            end
          end
        end
      end end

      if #coords == 0 then
        error("Cannot find stair position!")
      end

      rand_shuffle(coords)

      local loc = coords[1]

      local K1, K2, dir = loc.K, loc.N, loc.side

      assert(K1 and not K1.stair[dir])
      assert(K2 and not K2.stair[10-dir])

      local STAIR =
      {
        k1 = K1, k2 = K2, dir = dir, build = k1
      }

      K1.stair[dir] = STAIR
      K2.stair[10-dir] = STAIR
    end

    local function shuffle_stair_builds()
      for kx=1,3 do for ky=1,3 do
        local K = c.chunks[kx][ky]
        for side=6,8,2 do
          local stair = K.stair[side]
          if stair then
            local chance = 50

            local deep1 = sel(side==6, stair.k1.w, stair.k1.h)
            local deep2 = sel(side==6, stair.k2.w, stair.k2.h)

            if deep1 > deep2 then chance = 90 end
            if deep1 < deep2 then chance = 10 end

            stair.build = rand_sel(chance, stair.k1, stair.k2)
          end
        end
      end end
    end

    local function select_stair_spots()
      for kx=1,3 do for ky=1,3 do
        local K = c.chunks[kx][ky]
        K.stair_dir = nil  

        for side=2,8,2 do
          local stair = K.stair[side]
          if stair and stair.build == K then
            if K.stair_dir then
              return false, K --FAIL--
            end
            K.stair_dir = side
          end
        end
      end end

      return true --OK--
    end

    local function modify_clasher(clasher)
      assert(clasher)

      local bad_stairs = {}

      for kx=1,3 do for ky=1,3 do
        local K = c.chunks[kx][ky]
        for side=6,8,2 do
          local stair = K.stair[side]
          if stair and (stair.k1 == clasher or stair.k2 == clasher) then
            table.insert(bad_stairs, stair)
          end
        end
      end end

      assert(#bad_stairs >= 2)

      -- be fair and pick one at random
      local stair = rand_element(bad_stairs)
      
      stair.build = sel(stair.build == stair.k1, stair.k2, stair.k1)
    end


    --- add_stairs ---

    init_connx()

    for loop=1,99 do
      merge_connx()
      if is_fully_connected() then break end
con.debugf("CONNECT CHUNKS @ (%d,%d) loop: %d\n", c.x, c.y, loop)
      add_one_stair()
    end 

    shuffle_stair_builds()

    for loop=1,99 do
      local able,clasher = select_stair_spots()
      if able then break end
con.debugf("SELECT STAIR SPOTS @ (%d,%d) loop: %d\n", c.x, c.y, loop);
      if loop==99 then
        error("Failed to select stair spots")
      end
      modify_clasher(clasher)
    end
  end

  local function good_Q_spot(c) -- REMOVE (use block-based alloc)

    assert(not p.deathmatch)

    local function k_dist(kx,ky)
      local side = c.entry_dir or c.exit_dir or 2

      if side==4 then return kx-1  end
      if side==6 then return 3-kx end
      if side==2 then return ky-1  end
      if side==8 then return 3-ky end
    end

---##  local in_x, in_y = side_to_chunk(c.entry_dir or c.exit_dir)

    local best_x, best_y
    local best_score = -10

    for kx = 1,3 do
      for ky = 1,3 do
        if c.chunks[kx][ky] and
           not (c.chunks[kx][ky].void or c.chunks[kx][ky].cage or
                c.chunks[kx][ky].quest or c.chunks[kx][ky].vista)
        then
          local score = k_dist(kx, ky)
          score = score + con.random() * 0.5
          if c.chunks[kx][ky].rmodel.f_h == c.rmodel.f_h then score = score + 1.7 end

          if score > best_score then
            best_score = score
            best_x, best_y = kx,ky
          end
        end
      end
    end

---##  if not best_x then error("NO FREE SPOT!") end

    return best_x, best_y
  end

  --==-- make_chunks --==--

  for zzz,cell in ipairs(p.all_cells) do
    create_chunks(cell)
  end

  for zzz,cell in ipairs(p.all_cells) do
    for side = 2,8,2 do
      local L = cell.link[side]
      if L and not L.where then
        L.where = random_where(L, cell.border[side])
        set_link_coords(cell, side, L)
      end
    end
  end


  -- allocate chunks based on entry/exit locations

  local clashes

  for loop=1,(512+80) do 
    clashes = 0

    for zzz,cell in ipairs(p.all_cells) do
      if not alloc_link_chunks(cell, loop) then
        clashes = clashes + 1
      end
    end

    con.debugf("MAKING CHUNKS: %d clashes (loop %d)\n", clashes, loop)

    if clashes == 0 then break end
  end

  if clashes > 0 then
    -- Shit!
    error("Unable to allocate link chunks!")
  end

  -- secondly, determine main walk areas

  for zzz,cell in ipairs(p.all_cells) do

    mark_vista_chunks(cell)
    create_huge_vista(cell)

    add_travel_chunks(cell)

    setup_chunk_rmodels(cell)
    
    add_vista_environs(cell)

--!!!!    add_important_chunks(cell)

--????  flesh_out_cell(cell)  

    add_stairs(cell)
  end
end


function setup_borders_and_corners(p)

  -- for each border and corner: decide on the type, the combo,
  -- and which cell is ultimately responsible for building it.

  local function border_combo(cells)
    assert(#cells >= 1)

    if #cells == 1 then return cells[1].combo end

    for zzz,c in ipairs(cells) do
      if c.is_exit then return c.combo end
    end

--[[    for zzz,c in ipairs(cells) do
      if c.scenic == "solid" then return c.combo end
    end
--]]
    local combos = {}
    local hall_num = 0

    for zzz,c in ipairs(cells) do
      if c.hallway then hall_num = hall_num + 1 end
      table.insert(combos, c.combo)
    end
  
    -- when some cells are hallways and some are not, we
    -- upgrade the hallways to their "outer" combo.

    if (hall_num > 0) and (#cells - hall_num > 0) then
      for idx = 1,#combos do
        if cells[idx].hallway then
          combos[idx] = cells[idx].quest.combo
        end
      end
    end

    -- when some cells are outdoor and some are indoor,
    -- remove the outdoor combos from consideration.

    local out_num = 0

    for zzz,T in ipairs(combos) do
      if T.outdoor then out_num = out_num + 1 end
    end
    
    if (out_num > 0) and (#combos - out_num > 0) then
      for idx = #combos,1,-1 do
        if combos[idx].outdoor then
          table.remove(combos, idx)
        end
      end
    end

    if #combos >= 2 then
      table.sort(combos, function(t1, t2) return t1.mat_pri < t2.mat_pri end)
    end

    return combos[1]
  end


  local function border_kind(c1, c2, side, link)

    if not c2 or c2.is_depot then
      if c1.combo.outdoor and GAME.caps.sky then return "sky" end
      return "solid"
    end

    if c1.scenic == "solid" or c2.scenic == "solid" then
      return "solid"
    end

    if c1.hallway or c2.hallway then return "solid" end

    -- TODO: sometimes allow it
    if c1.is_exit or c2.is_exit then return "solid" end

    if not GAME.caps.heights then return "solid" end

    if c1.border[side].window then return "window" end

    -- fencing anyone?   (move tests into Planner???)
    local diff_h = math.min(c1.ceil_h, c2.ceil_h) - math.max(c1.f_max, c2.f_max)

    if (c1.combo.outdoor == c2.combo.outdoor) and diff_h > 64 and
       (not c1.is_exit  and not c2.is_exit) and
       (not c1.is_depot and not c2.is_depot) and
       not (link and link.kind == "vista")
    then
      if c1.scenic or c2.scenic then
        return "fence"
      end

      if dual_odds(c1.combo.outdoor, 60, 7) then
        return "fence"
      end
    end
 
    return "solid"
  end

  local function init_border(c, side)

    local D = c.border[side]
    if D.build then return end -- already done

    -- which cell actually builds the border is arbitrary, unless
    -- there is a link with the other cell
    local link = c.link[side]
    D.build = (link and link.build) or c

    local other = neighbour_by_side(p,c, side)

    -- vistas are an extension to the original room
    if link and link.kind == "vista" then
      D.combo = sel(D.build.hallway, D.build.quest.combo, D.build.combo)
    else
      D.combo = border_combo(D.cells)
    end

    D.kind = border_kind (c, other, side, link)
  end

  local function init_corner(c, side)

    local E = c.corner[side]
    if E.build then return end -- already done

    E.build = c
    E.combo = border_combo(E.cells)
    E.kind  = "solid"
  end

  --- setup_borders_and_corners ---

  for zzz,c in ipairs(p.all_cells) do

    for side = 1,9 do
      if c.border[side] then init_border(c, side) end
    end
    for side = 1,9,2 do
      if c.corner[side] then init_corner(c, side) end
    end
  end
end

function build_borders(p)

  local c

  local function build_door( link, side  )

    local D = c.border[side]

    local door_info = GAME.doors[link.wide_door]
    assert(door_info)
    door_info = copy_table(door_info)

    local parm =
    {
      door_top = link.build.rmodel.f_h + door_info.h,
      door_kind = 1, tag = 0,
    }

    if dual_odds(p.deathmatch, 80, 15) and not link.is_exit then
      parm.door_kind = 117 -- Blaze
    end

    if link.quest and link.quest.kind == "key" then

      door_info = GAME.key_doors[link.quest.item]
      assert(door_info)

      parm =
      {
        door_top = link.build.rmodel.f_h + door_info.h,
        door_kind = 1,
        tag = 0,
      }

      parm.door_kind = sel(p.coop, door_info.kind_once, door_info.kind_rep)

      -- FIXME: heretic statues !!!

    elseif link.quest and link.quest.kind == "switch" then

      door_info = GAME.switches[link.quest.item].door
      assert(door_info)

      parm =
      {
        door_top = link.build.rmodel.f_h + door_info.h,
        door_kind = 0,
        tag = link.quest.tag + 1,
      }

    elseif link.is_exit then
      door_info = GAME.key_doors["ex_tech"]

      parm =
      {
        door_top = link.build.rmodel.f_h + door_info.h,
        door_kind = 1,
        tag = 0,
      }
    end

    if not door_info.prefab then print(table_to_str(door_info)) end
    assert(door_info.prefab)

    local fab = PREFABS[door_info.prefab]
    assert(fab)

    B_prefab(p,c, fab, door_info.skin, parm, link.build.rmodel,D.combo, link.x1, link.y1, side)
  end

  local function blocky_door( link, side, double_who )
    local D = c.border[side]

    local bit
    if link.quest and link.quest.kind == "key" then
      bit = GAME.key_doors[link.quest.item]
      assert(bit)
      assert(bit.kind_rep)
    end

    -- door sides
    local side_tex
    local ax,ay = dir_to_across(side)
    
    if bit and bit.lock_side then
      side_tex = bit.lock_side
    elseif not bit and D.combo.door_side then
      side_tex = D.combo.door_side
    end

    if side_tex then
      gap_fill(p, c, link.x1-ax, link.y1-ay, link.x1+ax, link.y1+ay,
        { solid=side_tex })
    end
    
    p.blocks[link.x1][link.y1] =
    {
      f_tex = 0,
      door_kind = (bit and bit.kind_rep) or "door",
      door_dir  = side,
      blocked = true,
    }

    con.debugf("BUILT BLOCK DOOR @ (%d,%d)\n", link.x1, link.y1)
  end

  local function build_real_link(link, side, double_who)

    local D = c.border[side]
    assert(D)

if GAME.caps.elevator_exits and link.is_exit then
local other = link_other(link, c)
B_exit_elevator(p, other, link.x1, link.y1, side)
return
end

    if GAME.caps.blocky_doors then

      if link.kind == "door" then
        blocky_door( link, side, double_who )
        return
      end

      if link.kind == "arch" then
        gap_fill(p,c, link.x1,link.y1, link.x2,link.y2, D.build.rmodel)
        return
      end

      error("Cannot build: " .. link.kind)
    end

    if link.kind == "door" then
      build_door( link, side )
      return
    end

if true then
local fab = "ARCH" -- rand_element { "ARCH", "ARCH_ARCHED", "ARCH_TRUSS", "ARCH_BEAMS", "ARCH_RUSSIAN", "ARCH_CURVY" }
if link.long <= 2 then fab = "ARCH_NARROW" end
fab = PREFABS[fab]
assert(fab)
local parm =
{
  door_top = math.min(link.build.rmodel.c_h-32, link.build.floor_h+128),
  door_kind = 1, tag = 0,

  frame_c = D.combo.floor
}
local skin =
{
--  wall="ROCK1", ceil="RROCK13", -- floor="RROCK13",
  beam_w  = "WOOD1", beam_c = "FLAT5_2",
}
if link.kind == "vista" then
  skin.floor = link.vista_src.rmodel.f_tex
end

B_prefab(p,c, fab, skin, parm, link.build.rmodel,D.combo, link.x1, link.y1, side)
return
end


do
gap_fill(p, c, link.x1, link.y1, link.x2, link.y2,
copy_block_with_new(link.build.rmodel,
{ f_tex = "NUKAGE1" }))
return
end

---- OLD STUFF FROM HERE (Need to MERGE IT) --------

    -- DIR here points to center of current cell
    local dir = 10-side  -- FIXME: remove

    assert (link.build == c)

    local other = link_other(link, c)
    assert(other)


    local b_combo = D.combo

    local x, y
    local dx, dy = dir_to_delta(dir)
    local ax, ay = dir_to_across(dir)

    local long = link.long or 2

    local d_min = 1
    local d_max = BW

    local d_pos
    
    if link.where == "wide" then
      d_pos = d_min + 1
      long  = d_max - d_min - 1
    else
      d_pos = where_to_block(where, long) --!!!!! MOVE
      d_max = d_max - (long-1)

      if (d_pos < d_min) then d_pos = d_min end
      if (d_pos > d_max) then d_pos = d_max end
    end

        if side == 2 then x,y = d_pos, 1
    elseif side == 8 then x,y = d_pos, BH
    elseif side == 4 then x,y =  1, d_pos
    elseif side == 6 then x,y = BW, d_pos
    end

    x = D.x1
    y = D.y1

    if (link.kind == "arch" or link.kind == "falloff") then

      local ex, ey = x + ax*(long-1), y + ay*(long-1)
      local tex = b_combo.wall

      -- sometimes leave it empty
      if D.kind == "wire" then link.arch_rand = link.arch_rand * 4 end

      if link.kind == "arch" and link.where ~= "wide" and
        c.combo.outdoor == other.combo.outdoor and
        ((c.combo.outdoor and link.arch_rand < 50) or
         (not c.combo.outdoor and link.arch_rand < 10))
      then
        local sec = copy_block(c.rmodel)
sec.f_tex = "FWATER1"
        sec.l_tex = tex
        sec.u_tex = tex
        fill(p,c, x, y, ex, ey, sec)
        return
      end

      local arch = copy_block(c.rmodel)
      arch.c_h = math.min(c.ceil_h-32, other.ceil_h-32, c.floor_h+128)
      arch.f_tex = c.combo.arch_floor or c.rmodel.f_tex
      arch.c_tex = c.combo.arch_ceil  or arch.f_tex
arch.f_tex = "TLITE6_6"

      if (arch.c_h - arch.f_h) < 64 then
        arch.c_h = arch.f_h + 64
      end

      if c.hallway and other.hallway then
        arch.light = (c.rmodel.light + other.rmodel.light) / 2.0
      elseif c.combo.outdoor then
        arch.light = arch.light - 32
      else
        arch.light = arch.light - 16
      end

      local special_arch

      if link.where == "wide" and GAME.mats.ARCH and rand_odds(70) then
        special_arch = true

        arch.c_h = math.max(arch.c_h, c.ceil_h - 48)
        arch.c_tex = GAME.mats.ARCH.ceil

        tex = GAME.mats.ARCH.wall

        fill(p,c, x, y, ex+ax, ey+ay, { solid=tex })
      end

      arch.l_tex = tex
      arch.u_tex = tex

      fill(p,c, x, y, ex+ax, ey+ay, { solid=tex })
      fill(p,c, x+ax, y+ay, ex, ey, arch)

      if link.block_sound then
        -- FIXME block_sound(p, c, x,y, ex,ey, 1)
      end

      -- pillar in middle of special arch
      if link.where == "wide" then
        long = int((long-1) / 2)
        x, y  = x+long*ax,  y+long*ay
        ex,ey = ex-long*ax, ey-long*ay

        if x == ex and y == ey then
          fill(p,c, x, y, ex, ey, { solid=tex })
        end
      end

    elseif link.kind == "door" and link.is_exit and not link.quest then

      B_exit_door(p,c, c.combo, link, x, y, c.floor_h, dir)

    elseif link.kind == "door" and link.quest and link.quest.kind == "switch" and
       GAME.switches[link.quest.item].bars
    then
      local info = GAME.switches[link.quest.item]
      local sec = copy_block_with_new(c.rmodel,
      {
        f_tex = b_combo.floor,
        c_tex = b_combo.ceil,
      })

      if not (c.combo.outdoor and other.combo.outdoor) then
        sec.c_h = sec.c_h - 32
        while sec.c_h > (sec.c_h+sec.f_h+128)/2 do
          sec.c_h = sec.c_h - 32
        end
        if b_combo.outdoor then sec.c_tex = b_combo.arch_ceil or sec.f_tex end
      end

      local bar = link.bar_size
      local tag = link.quest.tag + 1

      B_bars(p,c, x,y, math.min(dir,10-dir),long, bar,bar*2, info, sec,b_combo.wall, tag,true)

    elseif link.kind == "door" then

      local kind = link.wide_door

      if c.quest == other.quest
        and link.door_rand < sel(c.combo.outdoor or other.combo.outdoor, 10, 20)
      then
        kind = link.narrow_door
      end

      local info = GAME.doors[kind]
      assert(info)

      local door_kind = 1
      local tag = nil
      local key_tex = nil


      B_door(p, c, link, b_combo, x, y, c.floor_h, dir,
             1 + int(info.w / 64), 1, info, door_kind, tag, key_tex)
    else
      error("build_link: bad kind: " .. tostring(link.kind))
    end

  end

  local function build_link(side)

    local link = c.link[side]
    if not (link and link.build == c) then return end

    if GAME.doors then
      link.narrow_door = random_door_kind(64)
      link.wide_door   = random_door_kind(128)
    end
    link.block_sound = rand_odds(90)
    link.bar_size    = rand_index_by_probs { 20,90 }
    link.arch_rand   = con.random() * 100
    link.door_rand   = con.random() * 100

    if link.where == "double" then
      local awh = rand_irange(2,3)
      build_real_link(link, side, 1)
      build_real_link(link, side, 2)
    else
      build_real_link(link, side, 0)
    end
  end

  local function build_corner(side)

    local E = c.corner[side]
    if not E then return end
    if E.build ~= c then return end

    -- handle outside corners
    local out_num = 0
    local f_max = -99999

    for zzz,c in ipairs(E.cells) do
      if c.combo.outdoor then out_num = out_num + 1 end
      f_max = math.max(c.f_max, f_max)
    end

    -- FIXME: determine corner_kind (like border_kind)
    if E.kind == "sky" then

      local CORN = copy_block_with_new(E.cells[1].rmodel,
      {
        f_h = f_max + 64,
        f_tex = E.combo.floor,
        l_tex = E.combo.wall,
      })

      -- crappy substitute to using a real sky corner
      if out_num < 4 then CORN.c_h = CORN.f_h + 1 end

      if CORN.f_h < CORN.c_h then
        gap_fill(p,c, E.bx, E.by, E.bx, E.by, CORN)
        return
      end
    end

    gap_fill(p,c, E.bx, E.by, E.bx, E.by, { solid=E.combo.wall })
  end

  local function build_sky_border(side, x1,y1, x2,y2)

    local WALL =
    {
      f_h = c.f_max + 48,
      f_tex = c.rmodel.f_tex,
      l_tex = c.rmodel.l_tex,

      c_h = c.rmodel.c_h,
      c_tex = c.rmodel.c_tex,
      u_tex = c.rmodel.u_tex,

      light = c.rmodel.light,
    }

    local BEHIND =
    {
      f_h = c.f_min - 512,
      c_h = c.f_min - 508,
      f_tex = c.rmodel.f_tex,
      c_tex = c.rmodel.c_tex,
      l_tex = c.rmodel.l_tex,
      u_tex = c.rmodel.u_tex,
      light = c.rmodel.light,
    }

    local ax1, ay1, ax2, ay2 = side_coords(10-side, 1,1, FW,FH)

    for x = x1,x2 do for y = y1,y2 do

      local B = p.blocks[x][y]

      -- overwrite a 64x64 block, but not a fragmented one
      if (not B) or (not B.fragments) then

        local fx = (x - 1) * FW
        local fy = (y - 1) * FH

        frag_fill(p,c, fx+  1, fy+  1, fx+ FW, fy+ FH, BEHIND)
        frag_fill(p,c, fx+ax1, fy+ay1, fx+ax2, fy+ay2, WALL)
      end

    end end
  end

  local function build_sky_corner(x, y, wx, wy)

    local WALL =
    {
      f_h = c.f_max + 48, c_h = c.rmodel.c_h,
      f_tex = c.rmodel.f_tex, c_tex = c.rmodel.c_tex,
      light = c.rmodel.light,
      l_tex = c.rmodel.l_tex,
      u_tex = c.rmodel.u_tex,
    }

    local BEHIND =
    {
      f_h = c.f_min - 512, c_h = c.f_min - 508,
      f_tex = c.rmodel.f_tex, c_tex = c.rmodel.c_tex,
      light = c.rmodel.light,
      l_tex = c.rmodel.l_tex,
      u_tex = c.rmodel.u_tex,
    }

    if not p.blocks[x][y] then

      local fx = (x - 1) * FW
      local fy = (y - 1) * FH

      frag_fill(p,c, fx+ 1, fy+ 1, fx+FW, fy+FH, BEHIND)
      frag_fill(p,c, fx+wx, fy+wy, fx+wx, fy+wy, WALL)
    end
  end

  local function build_fence(side, x1,y1, x2,y2, other, what, b_combo)

    local D = c.border[side]

--?? local f_min, f_max = border_floor_range(other, side)
    local fence_h = math.max(c.f_max, other.f_max)

    -- Wire fences
    if GAME.caps.rails and rand_odds(30) and (x1~=x2 or y1~=y2) then
      local def = GAME.sc_fabs["fence_MIDBARS3"] -- FIXME: not hard-code
      assert(def)

      local fab = non_nil(PREFABS[def.prefab])
      local parm = { low_h = fence_h }

      if rand_odds(33) then parm.low_h = parm.low_h + 48 end

      local dir = 10-side
      if ((dir % 2) == 1) then
        dir = sel(x1 == x2, 4, 2)  -- not quite right...
      end

      for x = x1,x2 do for y = y1,y2 do
        local B = p.blocks[x][y]
        if not B then
          B_prefab(p,c, fab,def.skin,parm, c.rmodel,D.combo, x,y,dir)
        end
      end end

      -- FIXME: sound blocking
      return
    end

    -- FIXME: "castley" fences

    local FENCE = copy_block_with_new(c.rmodel,
    {
      f_h = fence_h,
      f_tex = b_combo.floor,
      l_tex = b_combo.void,
    })

    FENCE.f_h = FENCE.f_h + 48+16*rand_irange(0,2)

    if c.scenic or other.scenic then FENCE.impassible = true end

    if rand_odds(95) then FENCE.block_sound = 2 end

    gap_fill(p,c, x1,y1, x2,y2, FENCE)
  end

  local function build_window(side)

    local D = c.border[side]

    if not (D and D.window and D.build == c) then return end

    local link = c.link[side]
    local other = neighbour_by_side(p,c,side)

    local b_combo = D.combo

    local WINDOW = 
    {
      f_h = math.max(c.f_max, other.f_max) + 32,
      c_h = math.min(c.rmodel.c_h, other.rmodel.c_h) - 32,

      f_tex = b_combo.floor,
      c_tex = b_combo.ceil,

      l_tex = b_combo.wall,
      u_tex = b_combo.wall,

      light = c.rmodel.light,
    }

--if (side%2)==1 then WINDOW.light=255; WINDOW.kind=8 end

    if other.scenic then WINDOW.impassible = true end

    WINDOW.light = WINDOW.light - 16
    WINDOW.c_tex = b_combo.arch_ceil or WINDOW.f_tex

    local x = D.x1
    local y = D.y1

    local ax, ay = dir_to_across(D.side)

    while x <= D.x2 and y <= D.y2 do
      gap_fill(p,c, x, y, x, y, WINDOW)
      x, y = x+ax, y+ay
    end

--[[ GOOD OLD STUFF

    -- cohabitate nicely with doors
    local min_x, max_x = 1, BW

    if link then
      if link.where == "double" then return end
      if link.where == "wide"   then return end

      local l_long = link.long or 2
      local l_pos = where_to_block(link.where, l_long)
      if l_pos > (BW+1)/2 then
        max_x = l_pos - 2
      else
        min_x = l_pos + l_long + 1
      end

    elseif c.vista[side] then
      if rand_odds(50) then
        max_x = 3
      else
        min_x = BW-3+1
      end
    end

    local dx, dy = dir_to_delta(D.side)

    local x, y = side_coords(side, 1,1, BW,BH)

    x = c.bx1-1 + x+dx
    y = c.by1-1 + y+dy


    local long  = rand_index_by_probs { 30, 90, 10, 3 }
    local step  = long + rand_index_by_probs { 90, 30, 4 }
    local first = -1 + rand_index_by_probs { 90, 90, 30, 5, 2 }

    local bar, bar_step
    local bar_chance

    if D.kind == "fence" then
      bar_chance = 0.1
    else
      bar_chance = 10 + math.min(long,4) * 15
    end

    if rand_odds(bar_chance) then
      if long == 1 then bar = 1
      else bar = rand_index_by_probs { 90, 30 }
      end
      if bar > 1 then bar_step = 2 * bar
      else bar_step = 2 * rand_index_by_probs { 40, 80 }
      end
    end

    -- !!! FIXME: test crud
    if not bar and D.kind ~= "fence" then
      -- FIXME: choose window rail
      sec[side] = { rail = GAME.rails["r_2"].wall }
    end

    for d_pos = first, BW-long, step do
      local wx, wy = x + ax*d_pos, y + ay*d_pos

      if (d_pos+1) >= min_x and (d_pos+long) <= max_x then
        if bar then
          B_bars(p,c, wx,wy, math.min(side,10-side),long, bar,bar_step, GAME.mats.METAL, sec,b_combo.wall)
        else
          gap_fill(p,c, wx,wy, wx+ax*(long-1),wy+ay*(long-1), sec)
        end
      end
    end
--]]
  end

  local function build_one_border(side)

    local D = c.border[side]
    if not D then return end
    if D.build ~= c then return end

    local link = c.link[side]
    local other = neighbour_by_side(p, c, side)

    local what = D.kind
    assert(what)

    local b_combo = D.combo
    assert(b_combo)

    local x1,y1, x2,y2 = D.x1, D.y1, D.x2, D.y2

    if what == "fence" then
      build_fence(side, x1,y1, x2,y2, other, what, b_combo)

    elseif what == "window" then
      build_window(side)

    elseif what == "sky" then
      build_sky_border(D.side, x1,y1, x2,y2)

    else -- solid
      gap_fill(p,c, x1,y1, x2,y2, { solid=b_combo.wall })
    end

      -- handle the corner (check adjacent side)
--[[ FIXME !!!!! "sky"
      for cr = 1,2 do
        local nb_side = 2
        if side == 2 or side == 8 then nb_side = 4 end
        if cr == 2 then nb_side = 10 - nb_side end

        local NB = neighbour_by_side(p, c, nb_side)

        local cx, cy = corn_x1, corn_y1
        if cr == 2 then cx, cy = corn_x2, corn_y2 end

        if NB then
          local NB_link = NB.link[side]
          local NB_other = neighbour_by_side(p, NB, side)

          if false then --!!!!! FIXME what_border_type(NB, NB_link, NB_other, side) == "sky" then
            build_sky_border(side, cx, cy, cx, cy)
          end
        else
          local wx, wy

          if cx < BW/2 then wx = FW else wx = 1 end
          if cy < BH/2 then wy = FH else wy = 1 end

          build_sky_corner(cx, cy, wx, wy)
        end
      end
--]]
  end


  --== build_borders ==--

  for zzz,cell in ipairs(p.all_cells) do

    c = cell

    for side = 1,9,2 do
      build_corner(side)
      build_one_border(side)
    end

    for side = 2,8,2 do
      build_link(side)
      build_one_border(side)
    end
  end
end


----------------------------------------------------------------

function build_maze(p, c, x1,y1, x2,y2)
  -- FIXME
end

function build_grotto(p, c, x1,y1, x2,y2)
  
  local ROOM = c.rmodel
  local WALL = { solid=c.combo.wall }

  for y = y1+1, y2-1, 2 do
    for x = x1+1+(int(y/2)%2)*2, x2-3, 4 do
      gap_fill(p,c, x-2,y, x-2,y, WALL)
      gap_fill(p,c, x+2,y, x+2,y, WALL)

      local ax, ay = dir_to_across(rand_sel(50, 2, 4))
      gap_fill(p,c, x-ax,y-ay, x+ax,y+ay, WALL)
    end
  end

  gap_fill(p,c, x1,y1, x2-3,y2-1, ROOM)
end

function build_pacman_level(p, c)

  local function free_spot(bx, by)
    local B = p.blocks[bx][by]
    return B and not B.solid and not B.has_blocker and
           (not B.things or table_empty(B.things))
  end

  local function solid_spot(bx, by)
    local B = p.blocks[bx][by]
    return B and B.solid
  end

  local PACMAN_MID_FABS  = { "WOLF_PACMAN_MID_1", "WOLF_PACMAN_MID_2", "WOLF_PACMAN_MID_3" }
  local PACMAN_CORN_FABS = { "WOLF_PACMAN_CORN_1", "WOLF_PACMAN_CORN_2", "WOLF_PACMAN_CORN_3" }
 
  local mid_fab = PREFABS[rand_element(PACMAN_MID_FABS)]
  assert(mid_fab)

  local mid_x = 32 - int(mid_fab.long/2)
  local mid_y = 30 - int(mid_fab.deep/2)

  local top_fab = PREFABS[rand_element(PACMAN_CORN_FABS)]
  local bot_fab = PREFABS[rand_element(PACMAN_CORN_FABS)]
  assert(top_fab and bot_fab)

  local top_flip = rand_odds(50)
  local bot_flip = not top_flip

  -- !!!! FIXME: move skin into x_wolf.lua
  local combo = GAME.combos[rand_sel(50,"BLUE_STONE","BLUE_BRICK")]
  assert(combo)

  local skin =
  {
    ghost_w = GAME.combos[rand_sel(50,"RED_BRICK","GRAY_STONE")].wall,

    dot_t = rand_sel(50,"chalice","cross"),

    treasure1 = "bible",
    treasure2 = "crown",

    blinky = "blinky",
    clyde = "clyde",
    inky = "inky",
    pinky = "pinky",
    first_aid = "first_aid",
  }
  local parm =
  {
  }

  B_prefab(p,c, mid_fab,skin,parm, c.rmodel,combo, mid_x-2, mid_y, 2, false)

  B_prefab(p,c, top_fab,skin,parm, c.rmodel,combo, mid_x-10, mid_y+16, 2,false,top_flip)
  B_prefab(p,c, top_fab,skin,parm, c.rmodel,combo, mid_x+10, mid_y+16, 2,true, top_flip)

  B_prefab(p,c, bot_fab,skin,parm, c.rmodel,combo, mid_x-10, mid_y-12, 2,false,bot_flip)
  B_prefab(p,c, bot_fab,skin,parm, c.rmodel,combo, mid_x+10, mid_y-12, 2,true, bot_flip)

  B_exit_elevator(p,c, mid_x+19, mid_y+28, 2)

  gap_fill(p,c, 2,2, 63,63, { solid=combo.wall })
  
  -- player spot
  local px
  local py = rand_irange(mid_y-11, mid_y-3)
  local p_ang = 0

  for x = mid_x-7,mid_x+12 do
    if free_spot(x, py) then
      px = x
      if solid_spot(x+1, py) or solid_spot(x+2,py) then
        p_ang = 90
        if solid_spot(x,py+1) or solid_spot(x,py+2) then p_ang = 270 end
      end
      break;
    end 
  end

  if not px then error("Could not find spot for pacman!") end

  add_thing(p, c, px, py, "player1", true, p_ang)
end

----------------------------------------------------------------


function build_cell(p, c)
 
  local function player_angle(kx, ky)

    if c.exit_dir then
      return dir_to_angle(c.exit_dir)
    end

    -- when in middle of room, find an exit to look at
    if (kx==2 and ky==2) then
      for i = 1,20 do
        local dir = rand_irange(1,4)*2
        if c.link[dir] then
          return dir_to_angle(dir)
        end
      end

      return rand_irange(1,4)*2
    end

    return delta_to_angle(2-kx, 2-ky)
  end

  local function decide_void_pic(p, c)
    if c.combo.pic_wd and rand_odds(60) then
      c.void_pic = { wall=c.combo.pic_wd, w=128, h=c.combo.pic_wd_h or 128 }
      c.void_cut = 1
      return

    elseif not c.combo.outdoor and rand_odds(25) then
      c.void_pic = get_rand_wall_light()
      c.void_cut = rand_irange(3,4)
      return

    else
      c.void_pic = get_rand_pic()
      c.void_cut = 1
    end
  end


  local function chunk_pair(cell, other, side,n)
    local cx,cy, ox,oy
    
        if side == 2 then cx,cy,ox,oy = n,1,n,3
    elseif side == 8 then cx,cy,ox,oy = n,3,n,1
    elseif side == 4 then cx,cy,ox,oy = 1,n,3,n
    elseif side == 6 then cx,cy,ox,oy = 3,n,1,n
    end

    return cell.chunks[cx][cy], other.chunks[ox][oy]
  end


  local function position_sp_stuff(c)

    if c == p.quests[1].first then
      local kx, ky = good_Q_spot(c, true)
      if not kx then error("NO FREE SPOT for Player!") end
      c.chunks[kx][ky].player=true
    end

    if c == c.quest.last then
      local can_vista = (c.quest.kind == "key") or
              (c.quest.kind == "weapon") or (c.quest.kind == "item")
      local kx, ky = good_Q_spot(c, can_vista)
      if not kx then error("NO FREE SPOT for Quest Item!") end
      c.chunks[kx][ky].quest=true

      --[[ NOT NEEDED?
      if p.coop and (c.quest.kind == "weapon") then
        local total = rand_index_by_probs { 10, 50, 90, 50 }
        for i = 2,total do
          local kx, ky = good_Q_spot(c)
          if kx then c.chunks[kx][ky].quest=true end
        end
      end
      --]]
    end
  end


  local function OLD_build_chunk(kx, ky)

    local function link_is_door(c, side)
      return c.link[side] and c.link[side].kind == "door"
    end

    local function add_overhang_pillars(c, K, kx, ky, sec, l_tex, u_tex)
      local basex = K.x1
      local basey = K.y1

      sec = copy_block(sec)
      sec.l_tex = l_tex
      sec.u_tex = u_tex
      
      for side = 1,9,2 do
        if side ~= 5 then
          local jx, jy = dir_to_corner(side, JW, JH)
          local fx, fy = dir_to_corner(side, FW, FH)

          local bx, by = (basex + jx-1), (basey + jy-1)

          local pillar = true

          if (bx ==  1 and link_is_door(c, 4)) or
             (bx == BW and link_is_door(c, 6)) or
             (by ==  1 and link_is_door(c, 2)) or
             (by == BH and link_is_door(c, 8))
          then
            pillar = false
          end

          -- FIXME: interact better with stairs/lift

          jx,jy = (bx - 1)*FW, (by - 1)*FH

          frag_fill(p,c, jx+1, jy+1, jx+FW, jy+FH, sec)

          if pillar then
            frag_fill(p,c, jx+fx, jy+fy, jx+fx, jy+fy, { solid=K.sup_tex})
          end
        end
      end
    end


    local function wall_switch_dir(kx, ky, entry_dir)
      if not entry_dir then
        entry_dir = rand_irange(1,4)*2
      end
      
      if kx==2 and ky==2 then
        return entry_dir
      end

      if kx==2 then return sel(ky < 2, 8, 2) end
      if ky==2 then return sel(kx < 2, 6, 4) end

      return entry_dir
    end


    ---=== OLD_build_chunk ===---

    local K = c.chunks[kx][ky]
    assert(K)



    if K.void then
      --!!! TEST CRAP
      gap_fill(p,c, K.x1, K.y1, K.x2, K.y2, c.rmodel)
      do return end

      if K.closet then
        con.debugf("BUILDING CLOSET @ (%d,%d)\n", c.x, c.y)

        table.insert(K.place.spots,
          B_monster_closet(p,c, K,kx,ky, c.floor_h + 0,
            c.quest.closet.door_tag))

      elseif K.dm_exit then
        B_deathmatch_exit(p,c, K,kx,ky,K.dir)

      elseif GAME.pics and not c.small_exit
          and rand_odds(sel(c.combo.outdoor, 10, sel(c.hallway,20, 50)))
      then
        if not c.void_pic then decide_void_pic(p, c) end
        local pic,cut = c.void_pic,c.void_cut

        if not c.quest.image and (p.deathmatch or
             (c.quest.mini and rand_odds(33)))
        then
          pic = GAME.images[1]
          cut = 1
          c.quest.image = "pic"
        end

        B_void_pic(p,c, K,kx,ky, pic,cut)

      else
        gap_fill(p,c, K.x1, K.y1, K.x2, K.y2, { solid=c.combo.void })
      end
      return
    end -- K.void

    if K.cage then
      B_big_cage(p,c, GAME.mats.CAGE, K,kx,ky)
      return
    end



    local bx = K.x1 + 1
    local by = K.y1 + 1
    
    if K.player then
      local angle = player_angle(kx, ky)
      local offsets = sel(rand_odds(50), {1,3,7,9}, {2,4,6,8})
      if p.coop then
        for i = 1,4 do
          local dx,dy = dir_to_delta(offsets[i])
          if settings.game == "plutonia" then
            B_double_pedestal(p,c, bx+dx,by+dy, K.rmodel, GAME.special_ped)
          else
            B_pedestal(p, c, bx+dx, by+dy, K.rmodel, GAME.pedestals.PLAYER)
          end
          add_thing(p, c, bx+dx, by+dy, "player" .. tostring(i), true, angle)
          c.player_pos = {x=bx+dx, y=by+dy}
        end
      else
        if settings.game == "plutonia" then
          B_double_pedestal(p,c, bx,by, K.rmodel, GAME.special_ped)
        else
          B_pedestal(p, c, bx, by, K.rmodel, GAME.pedestals.PLAYER)
        end
        add_thing(p, c, bx, by, sel(p.deathmatch, "dm_player", "player1"), true, angle)
        c.player_pos = {x=bx, y=by}

      end

    elseif K.dm_weapon then
      B_pedestal(p, c, bx, by, K.rmodel, GAME.pedestals.WEAPON)
      add_thing(p, c, bx, by, K.dm_weapon, true)

    elseif K.quest then

      if c.quest.kind == "key" or c.quest.kind == "weapon" or c.quest.kind == "item" then
        B_pedestal(p, c, bx, by, K.rmodel, GAME.pedestals.QUEST)

        -- weapon and keys are non-blocking, but we don't want
        -- a monster sitting on top of our quest item (especially
        -- when it has a pedestal).
        add_thing(p, c, bx, by, c.quest.item, true)

      elseif c.quest.kind == "switch" then
        local info = GAME.switches[c.quest.item]
        assert(info.switch)
        local kind = 103; if info.bars then kind = 23 end
        if rand_odds(40) then
          local side = wall_switch_dir(kx, ky, c.entry_dir)
          B_wall_switch(p,c, bx,by, K.rmodel.f_h, side, 2, info, kind, c.quest.tag + 1)
        else
          B_pillar_switch(p,c, K,bx,by, info,kind, c.quest.tag + 1)
        end

      elseif c.quest.kind == "exit" then
        assert(c.combo.switch)

        local side = wall_switch_dir(kx, ky, c.entry_dir)

        if settings.game == "plutonia" then
          B_double_pedestal(p,c, bx,by, K.rmodel, GAME.special_ped,
            { walk_kind = 52 }) -- FIXME "exit_W1"

        elseif c.small_exit and not c.smex_cage and rand_odds(80) then
          if c.combo.flush then
            B_flush_switch(p,c, bx,by, K.rmodel.f_h,side, c.combo.switch, 11)
          else
            B_wall_switch(p,c, bx,by, K.rmodel.f_h,side, 3, c.combo.switch, 11)
          end

          -- make the area behind the switch solid
          local x1, y1 = K.x1, K.y1
          local x2, y2 = K.x2, K.y2
              if side == 4 then x1 = x1+2
          elseif side == 6 then x2 = x2-2
          elseif side == 2 then y1 = y1+2
          elseif side == 8 then y2 = y2-2
          else   error("Bad side for small_exit switch: " .. side)
          end

          gap_fill(p,c, x1,y1, x2,y2, { solid=c.combo.wall })
          
        elseif c.combo.hole_tex and rand_odds(75) then
          B_exit_hole(p,c, K,kx,ky, c.rmodel)
          return
        elseif rand_odds(85) then
          B_floor_switch(p,c, bx,by, K.rmodel.f_h, side, c.combo.switch, 11)
        else
          B_pillar_switch(p,c, K,bx,by, c.combo.switch, 11)
        end
      end
    end -- if K.player | K.quest etc...


    ---| fill in the rest |---

    local sec = copy_block(K.rmodel)

    local surprise = c.quest.closet or c.quest.depot

    if K.quest and surprise and c == surprise.trigger_cell then

      sec.mark = allocate_mark(p)
      sec.walk_kind = 2
      sec.walk_tag  = surprise.door_tag
    end

    if K.liquid then  -- FIXME: put into setup_chunk_rmodels
      sec.kind = c.liquid.sec_kind
    end

    if K.player then

      sec.near_player = true;
      if not sec.kind then
        sec.kind = 9  -- FIXME: "secret"
      end

      if settings.mode == "coop" and settings.game == "plutonia" then
        sec.light = GAME.special_ped.coop_light
      end
    end

    -- TEST CRUD : overhangs
    if rand_odds(9) and c.combo.outdoor
      and (sec.c_h - sec.f_h <= 256)
      and not (c.quest.kind == "exit" and c.along == #c.quest.path-1)
      and not K.stair_dir
    then

      K.overhang = true

      if not c.overhang then
        local name
        name, c.overhang = rand_table_pair(GAME.hangs)
      end
      local overhang = c.overhang

      K.sup_tex = overhang.thin

      sec.c_tex = overhang.ceil
      sec.u_tex = overhang.upper

      sec.c_h = sec.c_h - (overhang.h or 24)
      sec.light = sec.light - 48
    end

    -- TEST CRUD : crates
    if not c.scenic and not K.stair_dir
      and GAME.crates
      and dual_odds(c.combo.outdoor, 20, 33)
      and (not c.hallway or rand_odds(25))
      and (not c.exit or rand_odds(50))
    then
      K.crate = true
      if not c.crate_combo then
        c.crate_combo = get_rand_crate()
      end
    end

    -- TEST CRUD : pillars
    if not K.crate and not c.scenic and not K.stair_dir
      and dual_odds(c.combo.outdoor, 12, 25)
      and (not c.hallway or rand_odds(15))
      and (not c.exit or rand_odds(22))
    then
      K.pillar = true
    end

    --FIXME: very cruddy check...
    if c.is_exit and chunk_touches_side(kx, ky, c.entry_dir) then
      K.crate  = nil
      K.pillar = nil
    end

    -- TEST CRUD : sky lights
    if c.sky_light then
      if kx==2 and ky==2 and c.sky_light.pattern == "pillar" then
        K.pillar = true
      end

      K.sky_light_sec = copy_block(sec)
      K.sky_light_sec.c_h   = sel(c.sky_light.is_sky, c.sky_h, sec.c_h + c.sky_light.h)
      K.sky_light_sec.c_tex = sel(c.sky_light.is_sky, GAME.SKY_TEX, c.sky_light.light_info.floor)
      K.sky_light_sec.light = 176
      K.sky_light_utex = c.sky_light.light_info.side

      -- make sure sky light doesn't come down too low
      K.sky_light_sec.c_h = math.max(K.sky_light_sec.c_h,
        sel(c.sky_light.is_sky, c.c_max+16, c.c_min))
    end
 
    ---- Chunk Fill ----

    local l_tex = c.rmodel.l_tex

    do
      assert(sec)

      if K.overhang then
        add_overhang_pillars(c, K, kx, ky, sec, sec.l_tex, sec.u_tex)
      end

      if K.sky_light_sec then
        local x1,y1,x2,y2 = K.x1,K.y1,K.x2,K.y2
        if kx==1 then x1=x1+1 end
        if kx==3 then x2=x2-1 end
        if ky==1 then y1=y1+1 end
        if ky==3 then y2=y2-1 end

        local func = SKY_LIGHT_FUNCS[c.sky_light.pattern]
        assert(func)

        local BB = copy_block(K.sky_light_sec)
        BB.l_tex = sec.l_tex
        BB.u_tex = K.sky_light_utex or sec.u_tex

        for x = x1,x2 do for y = y1,y2 do
          if func(kx,ky, x,y) then
            gap_fill(p,c, x,y, x,y, BB)
          end
        end end
      end

      -- get this *after* doing sky lights
      local blocked = p.blocks[K.x1+1][K.y1+1] --!!!

      if K.crate and not blocked then
        local combo = c.crate_combo
        if not c.quest.image and not c.quest.mini and
           (not p.image or rand_odds(11))
        then
          combo = GAME.images[2]
          c.quest.image = "crate"
          p.image = true
        end
        B_crate(p,c, combo, sec, kx,ky, K.x1+1,K.y1+1)
        blocked = true
      end

      if K.pillar and not blocked then

        -- TEST CRUD
        if rand_odds(22) and GAME.mats.CAGE and not p.deathmatch
          and K.rmodel.c_h >= K.rmodel.f_h + 128
        then
          B_pillar_cage(p,c, GAME.mats.CAGE, kx,ky, K.x1+1,K.y1+1)
        else
          B_pillar(p,c, c.combo, kx,ky, K.x1+1,K.y1+1)
        end
        blocked = true
      end

---###      sec.l_tex = l_tex
---###      sec.u_tex = u_tex

      gap_fill(p,c, K.x1, K.y1, K.x2, K.y2, sec)

      if not blocked and c.combo.scenery and not K.stair_dir and
         (dual_odds(c.combo.outdoor, 37, 22)
          or (c.scenic and rand_odds(51)))
      then
--!!!!!        p.blocks[K.x1+1][K.y1+1].has_scenery = true
        local th = add_thing(p, c, K.x1+1, K.y1+1, c.combo.scenery, true)
        if c.scenic then
          th.dx = rand_irange(-64,64)
          th.dy = rand_irange(-64,64)
        end
      end
    end

  end

  local function decide_sky_lights(c)
    if not c.combo.outdoor and not c.is_exit and not c.hallway
       and GAME.lights and rand_odds(70)
    then
      c.sky_light =
      {
        h  = 8 * rand_irange(2,4),
        pattern = random_sky_light(),
        is_sky = rand_odds(33),
        light_info = get_rand_light()
      }
      if not c.sky_light.is_sky and rand_odds(80) then
        c.sky_light.h = - c.sky_light.h
      end
    end
  end

  local function void_up_chunk(c, K)

    --!!!!!! TESTING
    if c.combo.decorate and not c.scenic and K.kind == "void" and
      (K.x2 > K.x1 or rand_odds(50)) and  -- FIXME: better randomness
      (K.y2 > K.y1 or rand_odds(50)) and
      rand_odds(65)
    then
      local dec_tex = c.combo.decorate
      if type(dec_tex) == "table" then
        dec_tex = rand_element(dec_tex)
      end
      gap_fill(p, c, K.x1,K.y1, K.x1,K.y1, { solid=dec_tex })
      gap_fill(p, c, K.x2,K.y2, K.x2,K.y2, { solid=dec_tex })
    end

    gap_fill(p, c, K.x1,K.y1, K.x2,K.y2, { solid=c.combo.void })
  end

  local function reclaim_areas(c)

    local function try_reclaim_side(K, dir)

      -- Requirements
      --  (a) start side must be against solid wall (empty chunk)
      --  (b) don't move if side neighbours have stairs
      --  (c) never fill chunk completely (leave 1 block free)
      --  (d) never fill over a "walk=4" block
      --  (e) choose side that gives greatest depth

      local N = chunk_neighbour(c, K, 10-dir)

      if N and N.kind ~= "empty" then return end

      local S1 = chunk_neighbour(c, K, rotate_cw90(dir))
      if S1 and S1.stair_dir and
         math.min(S1.stair_dir, 10-S1.stair_dir) == math.min(dir,10-dir)
      then return end

      local S2 = chunk_neighbour(c, K, rotate_ccw90(dir))
      if S2 and S2.stair_dir and
         math.min(S2.stair_dir, 10-S2.stair_dir) == math.min(dir,10-dir)
      then return end

      local dx,dy = dir_to_delta(dir)
      local ax,ay = dir_to_across(dir)

      local long = K.x2 - K.x1 + 1
      local deep = K.y2 - K.y1 + 1

      if (dir == 4) or (dir == 6) then
        long,deep = deep,long
      end

      local sx1,sy1, sx2,sy2 = side_coords(10-dir, K.x1,K.y1, K.x2,K.y2)

      local function test_line(h)
        for w = 0,long-1 do
          local x = sx1 + h*dx + w*ax
          local y = sy1 + h*dy + w*ay

          assert(valid_cell_block(c, x, y))
          local B = p.blocks[x][y]

          if B.walk or B.solid or B.fragments then
            return false
          end
        end

        return true --OK--
      end

      --> try_reclaim_side -->

      local h = 0

      while (h < deep-1) and test_line(h) do
        h = h + 1
      end

      if h == 0 then return end --FAIL--

      if K.r_deep and (h < K.r_deep or (h == K.r_deep and rand_odds(50))) then
        return --FAIL--
      end

      K.r_deep = h
      K.r_long = long
      K.r_dir  = dir

      K.rx1 = sx1
      K.ry1 = sy1
      K.rx2 = sx1 + (K.r_deep-1)*dx + (K.r_long-1)*ax
      K.ry2 = sy1 + (K.r_deep-1)*dy + (K.r_long-1)*ay

      return true --SUCCESS--
    end
    

    local function try_reclaim_corner(K, x_dir, y_dir)

      -- a reclaimed side trumps a corner
      if K.r_dir and (K.r_dir % 2) == 0 then return end

      local corn
      if x_dir == 4 then
        corn = sel(y_dir == 2, 9, 3)
      else
        corn = sel(y_dir == 2, 7, 1)
      end

      local max_w = K.x2 - K.x1 + 1
      local max_h = K.y2 - K.y1 + 1

      do
        -- allow neighbour chunks to have an reclaim area,
        -- limiting long/deep accordingly.

        local function try_side(side, perp_dir)
          local N = chunk_neighbour(c, K, side)

          if not N then return true end
          if N.kind == "empty" then return true end

          if not N.r_dir then return false end
          if N.r_dir ~= perp_dir then return false end
          
          if side==4 or side==6 then
            max_h = math.min(max_h, N.ry2 - N.ry1 + 1)
          else
            max_w = math.min(max_w, N.rx2 - N.rx1 + 1)
          end

          return true --OK--
        end

        if not try_side(10-x_dir, y_dir) then return end
        if not try_side(10-y_dir, x_dir) then return end
      end

      local cx,cy = corner_coords(corn, K.x1,K.y1,K.x2,K.y2)

      local dx = sel(x_dir==4, -1, 1)
      local dy = sel(y_dir==2, -1, 1)

      local function overlaps_stair(x1,y1, x2,y2)
        if not K.stair_x1 then return false end

        if x2 < K.stair_x1 or x1 > K.stair_x2 then return false end
        if y2 < K.stair_y1 or y1 > K.stair_y2 then return false end

        return true
      end
      
      local function test_block(rx1,ry1, rx2,ry2)

        -- input coordinates are relative to corner block,
        -- convert them to absolute coordinates.
        x1,y1 = cx + rx1*dx, cy + ry1*dy
        x2,y2 = cx + rx2*dx, cy + ry2*dy

        if x1 > x2 then x1,x2 = x2,x1 end
        if y1 > y2 then y1,y2 = y2,y1 end

        -- make sure it doesn't touch the chunk's stair
        if overlaps_stair(x1-1, y1-1, x2+1, y2+1) then
          return false --FAIL--
        end

        for x = x1,x2 do for y = y1,y2 do
if not valid_cell_block(c,x,y) then
con.printf("CELL (%d,%d) .. (%d,%d)\n", c.bx1,c.by1,c.bx2,c.by2)
con.printf("CHUNK (%d,%d) .. (%d,%d)\n", K.x1,K.y1, K.x2,K.y2)
con.printf("BLOCK RANGE w:%d-%d h:%d-%d (%d,%d)..(%d,%d)\n", x1,x2, y1,y2, x1,y1, x2,y2)
con.printf("cx:%d cy:%d dx:%d dy:%d\n", cx,cy, dx,dy)
end
          assert(valid_cell_block(c, x, y))
          local B = p.blocks[x][y]

          if B.walk or B.solid or B.fragments then
            return false --FAIL--
          end
        end end

        return true --OK--
      end

      --> try_reclaim_corner -->

      if not test_block(0,0, 0,0) then
        return --FAIL--
      end

      -- find largest rectangle
      local w, h = 1, 1
      local grow_w, grow_h = true,true

      while grow_w or grow_h do
        if grow_w and (not grow_h or rand_odds(50)) then

          if w+1 < max_w and test_block(w,0, w,h-1) then
            w = w + 1
          else
            grow_w = false
          end
        else
          assert(grow_h)

          if h+1 < max_h and test_block(0,h, w-1,h) then
            h = h + 1
          else
            grow_h = false
          end
        end
      end

      -- if a corner was already reclaimed, choose greatest area
      -- TODO: keep both if they don't overlap

      if K.r_dir then
        local area = w * h
        local r_area = K.r_long * K.r_deep
        if (area < r_area) or (area == r_area and rand_odds(50)) then
          return --FAIL--
        end
      end

      K.r_long = w
      K.r_deep = h
      K.r_dir  = 10-corn

      K.rx1 = cx
      K.ry1 = cy
      K.rx2 = cx + (K.r_long-1)*dx
      K.ry2 = cy + (K.r_deep-1)*dy

      if K.rx1 > K.rx2 then K.rx1, K.rx2 = K.rx2, K.rx1 end
      if K.ry1 > K.ry2 then K.ry1, K.ry2 = K.ry2, K.ry1 end

      return true --SUCCESS--
    end
    
    ---== reclaim_areas ==---

    -- choose reclaim direction for central chunks.
    -- By limiting them to a single direction, we prevent the
    -- chance of two neighbouring chunks cutting off the path
    -- (because the opposite sides were reclaimed).
    --
    -- pass #2 is special, if no claims occurred for X or Y
    -- direction in pass #1, then try the opposite way.

    local mid_x_dir = rand_sel(50, 4, 6)
    local mid_y_dir = rand_sel(50, 2, 8)

    if c.link[4] and not c.link[6] then mid_x_dir = 4 end
    if c.link[6] and not c.link[4] then mid_x_dir = 6 end

    if c.link[2] and not c.link[8] then mid_y_dir = 2 end
    if c.link[8] and not c.link[2] then mid_y_dir = 8 end

    local got_x = false
    local got_y = false

    for pass = 1,3 do
      for kx = 1,3 do for ky = 1,3 do
        local K = c.chunks[kx][ky]
        if is_roomy(K) then
          local x_dir = sel(kx==1, 6, sel(kx==3, 4, mid_x_dir))
          local y_dir = sel(ky==1, 8, sel(ky==3, 2, mid_y_dir))

          if pass == 1 then
            if try_reclaim_side(K, x_dir) then got_x = true end
            if try_reclaim_side(K, y_dir) then got_y = true end

          elseif pass == 2 then
            if not got_x then try_reclaim_side(K, 10-x_dir) end
            if not got_y then try_reclaim_side(K, 10-y_dir) end

          elseif pass == 3 then
            try_reclaim_corner(K, 4, 2)
            try_reclaim_corner(K, 4, 8)
            try_reclaim_corner(K, 6, 2)
            try_reclaim_corner(K, 6, 8)
          end
        end
      end end  -- for kx for ky
    end -- for pass
  end

  local function get_vista_coords(c, side, link, other)

    local x1, y1, x2, y2

    for kx = 1,3 do for ky = 1,3 do
      local K = other.chunks[kx][ky]
      if K.kind == "vista" and K.link == link then
        if not x1 then
          x1,y1, x2,y2 = K.x1,K.y1, K.x2,K.y2
        else
          x1 = math.min(x1, K.x1)
          y1 = math.min(y1, K.y1)
          x2 = math.max(x2, K.x2)
          y2 = math.max(y2, K.y2)
        end
      end
    end end

con.printf("get_vista_coords @ (%d,%d) --> (%d,%d)\n",
c.x, c.y, other.x, other.y)
    if not x1 then error("missing vista chunks!?!?") end

    return x1,y1, x2,y2
  end
  
  local function vista_gap_fill(c, side, link, other)

    for kx = 1,3 do for ky = 1,3 do
      local K = other.chunks[kx][ky]
      if K.kind == "vista" and K.link == link then
        assert(K.ground_model)
---###  gap_fill(p,c, K.x1,K.y1, K.x2,K.y2, K.ground_model)
        for x = K.x1,K.x2 do for y = K.y1,K.y2 do
          p.blocks[x][y].rmodel = K.ground_model
        end end
      end
    end end
  end

  local function vista_jiggle_link(c, side, L, other, x1,y1, x2,y2)
    local D = c.border[side]

con.printf("\n vista_jiggle_link:\n")
con.printf("  new size: (%d,%d) .. (%d,%d)\n", x1,y1, x2,y2)
con.printf("  link coords: (%d,%d) .. (%d,%d)\n", L.x1,L.y1, L.x2,L.y2)
con.printf("  boorder cds: (%d,%d) .. (%d,%d)\n\n", D.x1,D.y1, D.x2,D.y2)

    local dir

    if side == 4 or side == 6 then

          if L.y1 < y1 then dir = 8
      elseif L.y2 > y2 then dir = 2
      else return -- no problem --
      end

      if dir == 8 and L.y2 < D.y2 then
        L.y1, L.y2 = L.y1+1, L.y2+1
        return
      end

      if dir == 2 and L.y1 > D.y1 then
        L.y1, L.y2 = L.y1-1, L.y2-1
        return
      end

      -- unable to move link, backup plan: shorten it
      L.long = math.max(L.long-1, 2)

      if dir == 8 then L.y1 = L.y1+1 end

    else  -- side == 2 or side == 8

          if L.x1 < x1 then dir = 6
      elseif L.x2 > x2 then dir = 4
      else return -- no problem --
      end

      if dir == 6 and L.x2 < D.x2 then
        L.x1, L.x2 = L.x1+1, L.x2+1
        return
      end

      if dir == 4 and L.x1 > D.x1 then
        L.x1, L.x2 = L.x1-1, L.x2-1
        return
      end

      -- unable to move link, backup plan: shorten it
      L.long = math.max(L.long-1, 2)

      if dir == 6 then L.x1 = L.x1+1 end
    end
  end
 
  local SHALLOW_PROBS = { 0, 1, 20, 50, 90 }
  local SHALLOW_DBLS  = { 0, 0,  1, 15, 30 }

  local function build_one_vista(c, side, link)

    local other = neighbour_by_side(p, c, side)

    -- fixme: this code designed for opposite build site
    c,other,side = other,c,10-side


    local kind = "open"
    local diff_h = c.floor_h - other.floor_h

    if diff_h >= 48 and rand_odds(50) then kind = "wire" end

    if not c.combo.outdoor then
      local space_h = other.ceil_h - c.floor_h
      local r = con.random() * 100

      if space_h >= 96 and space_h <= 256 and r < 15 then
        kind = "frame"
      elseif r < 60 then
        kind = "solid"
      end
    end

    if link.fall_over then kind = "fall_over" end

    local x1,y1, x2,y2 = get_vista_coords(c, side, link, other)
    local sx,sy, ex,ey = x1,y1, x2,y2

    local long = x2 - x1 + 1
    local deep = y2 - y1 + 1

    if (side == 4) or (side == 6) then
      long,deep = deep,long
    end

    assert(long >= 1 and deep >= 1)

    -- make some vistas more shallow
    if deep > 5 or rand_odds(SHALLOW_PROBS[deep]) then
      local qty = 1
      if deep > 5 or rand_odds(SHALLOW_DBLS[deep]) then qty = 2 end

          if side == 2 then y1 = y1+qty
      elseif side == 8 then y2 = y2-qty
      elseif side == 4 then x1 = x1+qty
      elseif side == 6 then x2 = x2-qty
      end
    end

    -- don't touch the sides of the cell
    -- ALSO: don't go past the corner of the source cell
    if (side == 2) or (side == 8) then
      if x1 == other.bx1 then x1 = x1+1 end
      if x2 == other.bx2 then x2 = x2-1 end

      x1 = math.max(x1, c.bx1-1)
      x2 = math.min(x2, c.bx2+1)
    else
      if y1 == other.by1 then y1 = y1+1 end
      if y2 == other.by2 then y2 = y2-1 end

      y1 = math.max(y1, c.by1-1)
      y2 = math.min(y2, c.by2+1)
    end

    assert(x2 >= x1 and y2 >= y1)

    link.vista_x1 = x1; link.vista_y1 = y1
    link.vista_x2 = x2; link.vista_y2 = y2

    if sx ~= x1 or sy ~= y1 or ex ~= x2 or ey ~= y2 then
      vista_gap_fill(c, side, link, other)
      vista_jiggle_link(c, side, link, other, x1,y1, x2,y2)
con.printf("  link coords now: (%d,%d) .. (%d,%d)\n", link.x1,link.y1, link.x2,link.y2)
    end

con.debugf("  COORDS: (%d,%d) .. (%d,%d)  size:%dx%d\n", x1,y1, x2,y2, long,deep)
con.debugf("  CELL:   (%d,%d) .. (%d,%d)\n", c.bx1,c.by1, c.bx2,c.by2)

    B_vista(p, link.vista_src, link.vista_dest, x1,y1, x2,y2, side, c.border[side].combo or c.combo, kind)
  end

  local function build_vistas(c)
    for side = 2,8,2 do
      local L = c.link[side]
      if L and L.kind == "vista" and L.vista_dest == c then
        build_one_vista(c, side, L)
      end
    end
  end


  local function mark_walkable(c, walk, x1,y1, x2,y2)
    assert(x2 >= x1 and y2 >= y1)
    assert(c.bx1 <= x1 and x2 <= c.bx2)
    assert(c.by1 <= y1 and y2 <= c.by2)

    for x = x1,x2 do for y = y1,y2 do
      local B = p.blocks[x][y]
      assert(B)

      if not B.walk or walk > B.walk then
        B.walk = walk
      end
    end end
  end

  local function mark_link_walks(c)
    
    -- FIXME: many improvements here!
    --   (a) fence borders: walk 3
    --   (b) doors: second square away = walk 2
    --   (c) next to walls and dropoffs: walk 1
 
    for side = 2,8,2 do
      local dx,dy = dir_to_delta(10-side) -- inwards

      local L = c.link[side]
      if L and not (L.kind == "vista" and L.vista_dest == c) then
        mark_walkable(c, 4, L.x1+dx, L.y1+dy, L.x2+dx, L.y2+dy)
      end

      local D = c.border[side]
      if D and D.kind == "window" then
--!!!!!!        mark_walkable(c, 1, D.x1+dx, D.y1+dy, D.x2+dx, D.y2+dy)
      end
    end
  end

  local function mark_vista_walks(c)

    for side = 2,8,2 do
      local L = c.link[side]
      if L and L.kind == "vista" and L.vista_dest == c then
        
        assert(L.vista_x1)

        -- surrounding coordinates
        local x1,y1 = L.vista_x1, L.vista_y1
        local x2,y2 = L.vista_x2, L.vista_y2

        if side == 2 or side == 8 then
          x1,x2 = x1-1, x2+1
        else
          y1,y2 = y1-1, y2+1
        end

            if side == 2 then y2=y2+1
        elseif side == 8 then y1=y1-1
        elseif side == 4 then x2=x2+1
        elseif side == 6 then x1=x1-1
        end

        for dir = 2,8,2 do
          if dir ~= side then
            mark_walkable(c, 3, side_coords(dir, x1,y1, x2,y2))
          end
        end
      end
    end
  end

  local function stair_depths(diff_h)
    diff_h = math.abs(diff_h)

    local low = 1
    if diff_h >= 72  then low = 2 end
    if diff_h >= 168 then low = 3 end
    if diff_h >= 264 then low = 4 end
    
    local high = 1
    if diff_h >= 48  then high = 2 end
    if diff_h >= 96  then high = 3 end
    if diff_h >= 144 then high = 4 end

    return low,high
  end

  local function sort_stair_chunks(c)

    -- Requirements:
    --   That chunks with 'stair_dir' field are placed _after_ the
    --   chunk pointed to.

    -- Algorithm:
    --   (a) give each chunk a unique ID
    --   (b) let low IDs "flow down" stair directions
    --   (c) repeat step (b) many times until stable
    --   (d) sort chunks into ascending ID numbers
    --
    -- NOTE: cyclic references prevent it from becoming truly
    --       stable. We ignore this problem (should be rare).

    local ids = {}
    rand_shuffle(ids, 3*3)

    local result = {}

    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]
      K.sort_id = table.remove(ids, 1)
      table.insert(result, K)
    end end

    for loop = 1,10 do
      for kx = 1,3 do for ky = 1,3 do
        local K = c.chunks[kx][ky]
        if K.stair_dir then
          local dx,dy = dir_to_delta(K.stair_dir)
          local J = c.chunks[kx+dx][ky+dy]
          if K.sort_id < J.sort_id then
            K.sort_id, J.sort_id = J.sort_id, K.sort_id
          end
        end
       end end 
    end

    table.sort(result, function(k1,k2) return k1.sort_id < k2.sort_id end)

-- con.printf("RESULT = \n%s\n", table_to_str(result,2))
    return result
  end

  local function find_stair_loc(K, behind_K,side1_K,side2_K, max_walk, min_deep,want_deep)

    -- Requirements:
    --   (a) blocks which stair will occupy are empty
    --   (b) blocks vor und hinter the stair are walkable
    --
    -- Preferences:
    --   (c) depth >= min_deep
    --   (d) width at least 2 blocks
    --   (e) prefer away from side edges

    local in_dir = 10-K.stair_dir
    local dx,dy = dir_to_delta(in_dir)
    local ax,ay = dir_to_across(in_dir)

    local x1,y1, x2,y2 = side_coords(K.stair_dir, K.x1,K.y1, K.x2,K.y2)

    local long = K.x2 - K.x1 + 1
    local deep = K.y2 - K.y1 + 1 

    if (K.stair_dir==4 or K.stair_dir==6) then
      long,deep = deep,long
    end

    local function check_stair_pos(pos, w)

      local x, y = x1 + ax*pos, y1 + ay*pos
      assert(K.x1 <= x and x <= K.x2)
      assert(K.y1 <= y and y <= K.y2)

      for h = want_deep,1,-1 do
        local able = true

        local sx, sy = x1 + ax*pos, y1 + ay*pos
        local ex, ey = sx + (h-1)*dx + (w-1)*ax, sy + (h-1)*dy + (w-1)*ay

        local st_x1 = math.min(sx,ex)
        local st_y1 = math.min(sy,ey)
        local st_x2 = math.max(sx,ex)
        local st_y2 = math.max(sy,ey)

        if h >= deep or
           (ex < K.x1 or ex > K.x2) or
           (ey < K.y1 or ey > K.y2)
        then
          able = false
        else

          assert(K.x1 <= st_x1 and st_x2 <= K.x2)
          assert(K.y1 <= st_y1 and st_y2 <= K.y2)

          -- first: check stair itself
          for qx = st_x1,st_x2 do for qy = st_y1,st_y2 do
            local B = p.blocks[qx][qy]
            assert(B)
            if (B.walk and B.walk > max_walk) or not is_roomy(B.chunk) then
              able = false
            end
          end end

          -- second: check walkable ends
          for i = 0,w-1 do
            local qx, qy = sx + i*ax -   dx, sy + i*ay -   dy
            local rx, ry = sx + i*ax + h*dx, sy + i*ay + h*dy

            assert(c.bx1 <= qx and qx <= c.bx2)
            assert(c.by1 <= qy and qy <= c.by2)

            if not (c.bx1 <= rx and rx <= c.bx2 and
                    c.by1 <= ry and ry <= c.by2)
            then
              able = false

            elseif behind_K and behind_K.stair_dir and
               (behind_K.x1 <= rx and rx <= behind_K.x2) and
               (behind_K.y1 <= ry and ry <= behind_K.y2)
            then
              able = false

            else
              local B1 = p.blocks[qx][qy]
              local B2 = p.blocks[rx][ry]
              assert(B1)
              assert(B2)

              if (B1.solid or B1.f_tex) or not is_roomy(B1.chunk) or
                 (B2.solid or B2.f_tex) or not is_roomy(B2.chunk)
              then
                able = false
              end
            end
          end
        end

        if able then
          local info = { x=x, y=y, sx=st_x1,sy=st_y1,ex=st_x2,ey=st_y2, pos=pos, long=w, deep=h, score=0 }

          if h == want_deep then info.score = 400
          elseif h >= min_deep then info.score = 200
          end

          if not (pos == 0 and side1_K and side1_K.stair_dir) and
             not (pos+w == long and side2_K and side2_K.stair_dir)
          then
            info.score = info.score + 100
          end

          info.score = info.score + math.min(w-1,4) * 10

          -- deadlock breaker
          info.score = info.score + con.random()

          return info
        end          
      end

      return nil
    end

    -- find_stair_loc --

    local best

    for pos = 0,long-1 do
      for w = 1,long-pos do
        info = check_stair_pos(pos, w)
        if info and (not best or info.score > best.score) then
          best = info
        end
      end
    end

    return best
  end
  
  local function put_in_stair(c, mode, K,J, x,y, long,deep)

    local dir = K.stair_dir
    local dx,dy = dir_to_delta (K.stair_dir)
    local ax,ay = dir_to_across(K.stair_dir)

    local ex = x + ax*(long-1) + ay*(deep-1)
    local ey = y + ax*(deep-1) + ay*(long-1)

    local diff_h = K.rmodel.f_h - J.rmodel.f_h
    local max_fh = math.max(K.rmodel.f_h, J.rmodel.f_h)

    local step = -diff_h / (deep * 4)
    
con.debugf("Putting in Stair: (%d,%d)..(%d,%d) dir:%d size:%dx%d\n", x,y, ex,ey, dir, long, deep)

    if mode == "stair" then
      B_stair(p,c, K.rmodel, x,y, dir, long,deep, step)

    elseif mode == "lift" then
      B_lift(p,c, K.rmodel, x,y, max_fh, dir, long, deep)

    else
      error("put_in_stair: unknown mode: " .. tostring(mode))
    end

    -- reserve space vor und hinter the staircase

    mark_walkable(c, 4, side_coords(   dir, x-ay,y-ax, ex+ay,ey+ax))
    mark_walkable(c, 4, side_coords(10-dir, x-ay,y-ax, ex+ay,ey+ax))

    -- mark stair for reclaim_areas() to avoid

    if not K.stair_x1 then
      K.stair_x1 = x
      K.stair_y1 = y
      K.stair_x2 = ex
      K.stair_y2 = ey
    else
      -- compute union of areas
      K.stair_x1 = math.min(K.stair_x1, x)
      K.stair_y1 = math.min(K.stair_y1, y)
      K.stair_x2 = math.max(K.stair_x2, ex)
      K.stair_y2 = math.max(K.stair_y2, ey)
    end
  end

  local function build_stair_chunk(c, K)

    local kx,ky = K.kx, K.ky
    local dx,dy = dir_to_delta(K.stair_dir)
    local ax,ay = dir_to_across(K.stair_dir)

    assert(1<=kx+dx and kx+dx<=3)
    assert(1<=ky+dy and ky+dy<=3)

    local J = c.chunks[kx+dx][ky+dy]
    local diff_h = K.rmodel.f_h - J.rmodel.f_h

    local behind_K
    if (1<=kx-dx and kx-dx<=3) and
       (1<=ky-dy and ky-dy<=3)
    then
      behind_K = c.chunks[kx-dx][ky-dy]
    end

    local function side_is_bad(dir)
      local kdx,kdy = dir_to_delta(dir)
      local nx,ny   = kx+kdx, ky+kdy
      if nx<1 or nx>3 or ny<1 or ny>3 then return nil end
      local N = c.chunks[nx][ny]
      if not N.stair_dir then return nil end
      if N.stair_dir ~= (10-dir) then return nil end
      return N
    end
    
    local side1_K, side2_K

    if K.stair_dir==2 or K.stair_dir==8 then
      side1_K = side_is_bad(4)
      side2_K = side_is_bad(6)
    else
      side1_K = side_is_bad(2)
      side2_K = side_is_bad(8)
    end

con.debugf("Building stair @ (%d,%d) chunk [%d,%d] dir:%d\n", c.x, c.y, kx,ky, K.stair_dir)
con.debugf("  Chunk: (%d,%d)..(%d,%d)\n", K.x1,K.y1, K.x2,K.y2)

    local info
    for max_walk = 1,3 do
      info = find_stair_loc(K, behind_K,side1_K,side2_K, max_walk,
                            stair_depths(diff_h))
      if info then break; end
    end

    if not info then
      -- Fuck!
      show_cell_blocks(p,c)
      con.printf("Error in Cell (%d,%d) Chunk [%d,%d] dir:%d\n",
          c.x, c.y, K.kx, K.ky, K.stair_dir)
      error("Unable to find stair position!")
    end

    local x, y = info.sx, info.sy
    local long, deep = info.long, info.deep

    local diff_h = K.rmodel.f_h - J.rmodel.f_h
    local step   = -diff_h / (deep * 4)

    local prefer_stairs = c.room_type.prefer_stairs or
       c.quest.level_theme.prefer_stairs or GAME.caps.prefer_stairs
    
    local max_step = sel(GAME.caps.prefer_stairs, 24, 16) --????

    -- decide whether to make a staircase or a lowering platform
    local mode = "lift"

    if math.abs(step) <= max_step then
      if prefer_stairs then
        mode = "stair"
      elseif math.abs(diff_h) <= 32 then
        mode = "stair"
      elseif math.abs(diff_h) >= 224 then
        mode = "lift"
      else
        prob = (math.abs(diff_h) - 28) / 2
        mode = rand_sel(prob, "lift", "stair")
      end
    end

    if mode == "lift" then
      
      -- limit width to reasonable values (128 or 256 units)
          if long == 3 then long = 2
      elseif long >= 5 and rand_odds(95) then
        local pos = int( (long - 4 + rand_irange(0,1)) / 2)
        x, y = x + pos*ax, y + pos*ay
        long = 4
      end

      -- limit depth to reasonable values
      local lift_h = deep

      if long == 1 then
        lift_h = 1
      elseif lift_h >= 2 and rand_odds(95) then
        lift_h = rand_sel(66, 2, 1)
      end

      if lift_h ~= deep then
        if K.stair_dir == 8 or K.stair_dir == 6 then
          x,y = x + (deep-lift_h)*dx, y + (deep-lift_h)*dy
        end
        deep = lift_h
      end

    else
      assert(mode == "stair")

      -- sometimes make stairs narrow, or even split into two pieces

      local NARROW_PROBS = { 0, 0, 0, 40, 70, 70, 70, 70 }
      local SPLIT_PROBS  = { 0, 0, 2, 20, 75, 90, 95, 99 }

      while rand_odds(NARROW_PROBS[math.min(long,8)]) do
        -- don't always centre the new stair
        local centre = rand_index_by_probs({ 10,90,10 }) - 1
        x, y = x + ax*centre, y + ay*centre
        long = long - 2
  con.printf("MAKING STAIR NARROWER @ (%d,%d) : new size %dx%d\n", c.x,c.y, long,deep)
      end

      if rand_odds(SPLIT_PROBS[math.min(long,8)]) then
        local split_w, gap_w

        repeat
          split_w = rand_index_by_probs { 10, 60, 90 }
          gap_w   = long - split_w*2
        until gap_w >= 1

        long = split_w
  con.printf("SPLITTING STAIR @ (%d,%d) : new size %dx%d\n", c.x,c.y, long,deep)

        put_in_stair(c, mode, K,J, x,y, long,deep)
        x,y = x + (long+gap_w)*ax, y + (long+gap_w)*ay
      end
    end

    put_in_stair(c, mode, K,J, x,y, long,deep)
  end


  local function build_stairs(c)

    local chunk_list = sort_stair_chunks(c)
    
    for i = 1,#chunk_list do
      local K = chunk_list[i]
      if K.stair_dir then
        build_stair_chunk(c, K)
      end
    end
  end


  ---=== build_cell ===---

  if c.scenic == "solid" then
    fill(p,c, c.bx1, c.by1, c.bx2, c.by2, { solid=c.combo.void })
    return
  end

  -- elevator exits are done in build_link   FIXME: CHANGE
  if GAME.caps.elevator_exits and c.is_exit then return end

  decide_sky_lights(c)

  build_vistas(c)

  mark_link_walks(c)
  mark_vista_walks(c)

  build_stairs(c)

--!!!!!  reclaim_areas(c)
end


function tizzy_up_room(p, c)

  local function block_is_free(B)
    if not B.chunk then return false end
    if B.solid or B.f_tex or B.fragments then return false end
    return true
  end

  local function block_is_used(B)
    if B.solid or B.f_tex or B.fragments then return true end
    return false
  end

  local function verify_inner(c, fab, max_walk, x1,y1, x2,y2)
    assert(valid_cell_block(c,x1,y1))
    assert(valid_cell_block(c,x2,y2))

    local f_h, c_h

    for x = x1,x2 do for y = y1,y2 do
      local B = p.blocks[x][y]
      assert(B)

      if not block_is_free(B) then return false end

      if not f_h then
        f_h = B.chunk.rmodel.f_h
        c_h = B.chunk.rmodel.c_h

        local h = c_h - f_h
        if fab.height_range then
          if h < fab.height_range[1] or h > fab.height_range[2] then
            return false
          end
        end
      else
        if B.chunk.rmodel.f_h ~= f_h and fab.region ~= "ceiling" then
          return false
        end

        if B.chunk.rmodel.c_h ~= c_h and fab.region ~= "floor" then
          return false
        end
      end

      if B.walk and B.walk >= max_walk then return false end
    end end

    return true, f_h
  end

  local function verify_outer(c, f_h, x1,y1, x2,y2)
    if not valid_cell_block(c,x1,y1) then return false end
    if not valid_cell_block(c,x2,y2) then return false end
    
    for x = x1,x2 do for y = y1,y2 do
      local B = p.blocks[x][y]
      if not (B.walk or block_is_free(B)) then return false end
      if B.chunk.rmodel.f_h ~= f_h then return false end
    end end

    return true --OK--
  end

  local function verify_wall(c, f_h, x1,y1, x2,y2)
    for x = x1,x2 do for y = y1,y2 do
      if valid_cell_block(c, x, y) then
        local B = p.blocks[x][y]
        if block_is_free(B) then
          return (B.chunk.rmodel.f_h >= f_h + 80)
        end
      else
        -- "border" block is fine
      end
    end end

    return true --OK--
  end
  
  local function verify_island_spot(c, f_h, x1,y1, x2,y2)
   
    -- oooo
    -- oIIo
    -- oIIo
    -- oooo

    if not verify_outer(c, f_h, side_coords(2, x1-1,y1-1, x2+1,y2+1)) or
       not verify_outer(c, f_h, side_coords(4, x1-1,y1-1, x2+1,y2+1)) or
       not verify_outer(c, f_h, side_coords(6, x1-1,y1-1, x2+1,y2+1)) or
       not verify_outer(c, f_h, side_coords(8, x1-1,y1-1, x2+1,y2+1))
    then
      return false
    end

    return true --OK--
  end

  local function verify_wall_extend(c, f_h, dir, x1,y1, x2,y2)

    -- WWWW
    -- oIIo
    -- oIIo
    -- oooo

    if not verify_wall(c, f_h, side_coords(10-dir, x1-1,y1-1, x2+1,y2+1)) then
      return false
    end

    if not verify_outer(c, f_h, side_coords(dir, x1-1,y1-1, x2+1,y2+1)) then
      return false
    end

    local ex1,ey1, ex2,ey2 = x1,y1, x2,y2
    local edir

    if dir == 2 or dir == 8 then
      edir,ex1,ex2 = 4,ex1-1,ex2+1
    else
      edir,ey1,ey2 = 2,ey1-1,ey2+1
    end

    if not verify_outer(c, f_h, side_coords(edir,    ex1,ey1, ex2,ey2)) or
       not verify_outer(c, f_h, side_coords(10-edir, ex1,ey1, ex2,ey2))
    then
      return false
    end

    return true --OK--
  end

---  local function verify_corner_extend(c, f_h, dir, x1,y1, x2,y2)
---
---    local nb_dir = rotate_cw90(dir)
---
---    -- Xooo
---    -- WIIo
---    -- WIIo
---    -- WWWX
---
---    -- FIXME !!!
---
---    return false --FAIL--
---  end

  local function fab_check_position(c, fab, max_walk, dir1, dir2, x1,y1, x2,y2)

    assert(x1 <= x2 and y1 <= y2)

    if not valid_cell_block(c,x1,y1) then return false end
    if not valid_cell_block(c,x2,y2) then return false end

    local able, f_h = verify_inner(c, fab, max_walk, x1,y1, x2,y2)

    if not able then return false end

    if (not fab.add_mode or fab.add_mode == "island") then
      if verify_island_spot(c, f_h, x1,y1, x2,y2) then
        return true, "island", rand_sel(50, dir1, dir2)
      end
    end

    if (not fab.add_mode or fab.add_mode == "wall") then

      if verify_wall_extend(c, f_h, dir1, x1,y1, x2,y2) then
        return true, "wall", dir1
      
      elseif dir1 ~= dir2 and
        verify_wall_extend(c, f_h, dir2, x1,y1, x2,y2)
      then
        return true, "wall", dir2
      end
--[[
        for g_dir = 2,8,2 do
          local sx,sy, ex,ey = side_coords(10-g_dir, x1-1,y1-1, x2+1,y2+1)

          if verify_wall(c, f_h, sx,sy, ex,ey) then
            if verify_wall_extend(c, f_h, g_dir, x1,y1, x2,y2) then
              return true, "wall", g_dir
            end

            break; -- can never have more than one wall
          end
        end
--]]
    end

    return false --FAIL--
  end

  local function try_one_fab_loc(c, fab, max_walk, dir, x, y)
    local long = fab.long
    local deep = fab.deep

    if dir==4 or dir==6 then deep,long = long,deep end

    local able, g_mode, g_dir =
        fab_check_position(c, fab, max_walk, dir or 2, dir or 8, x,y, x+long-1, y+deep-1)

    if able then return true, g_dir end

    if not dir then
      long,deep = deep,long
      local able, g_mode, g_dir =
          fab_check_position(c, fab, max_walk, 4, 6, x,y, x+long-1, y+deep-1)

      if able then return true, g_dir end
    end
  end

  local function find_fab_loc(c, fab, walk1,walk2, dir)

    if not c.fab_spots then
      c.fab_spots = {}
      for x = c.bx1,c.bx2 do for y = c.by1,c.by2 do
        table.insert(c.fab_spots, {x=x, y=y})
      end end
    end

    for max_walk = walk1,walk2 do

      rand_shuffle(c.fab_spots)

      for zzz,spot in ipairs(c.fab_spots) do
        local x = spot.x
        local y = spot.y

        local able, g_dir = try_one_fab_loc(c, fab, max_walk, dir, x, y)

        if able then return x, y, g_dir end
      end
    end

    return nil, nil --FAIL--
  end

  local function find_emergency_loc(c, dir)

    rand_shuffle(c.fab_spots)

    for zzz,spot in ipairs(c.fab_spots) do
      local x = spot.x
      local y = spot.y
      local B = p.blocks[x][y]

      if B and block_is_free(B) and is_roomy(B.chunk) and not B.has_blocker then
        return x,y, dir or (rand_irange(1,4)*2)
      end
    end
  end

  local function fab_mark_walkable(c, x, y, dir, long,deep, walk)

    if dir==4 or dir==6 then long,deep = deep,long end

    local x1,y1 = x, y
    local x2 = x1 + long-1
    local y2 = y1 + deep-1

    assert(x1 <= x2 and y1 <= y2)
    assert(c.bx1 <= x1 and x2 <= c.bx2)
    assert(c.by1 <= y1 and y2 <= c.by2)

    for x = x1-1,x2+1 do for y = y1-1,y2+1 do
      if (x == x1-1 or x == x2+1 or y == y1-1 or y == y2+1) and
         valid_cell_block(c, x, y)
      then
        local B = p.blocks[x][y]
        
        if (B.walk and walk > B.walk) or block_is_free(B) then
          B.walk = walk
        end
      end
    end end
  end


  local function add_object(c, name, must_put)

    local x,y,dir
    
    -- try a vista (FIXME: not good way to do this)
    for side = 2,8,2 do
      local L = c.link[side]
      if L and L.kind == "vista" and not L.vista_got_obj then
        assert(L.vista_x1)

        x = int((L.vista_x1 + L.vista_x2)/2)
        y = int((L.vista_y1 + L.vista_y2)/2)
        dir = side

        L.vista_got_obj = true

        add_thing(p, c, x, y, name, true)
        return
      end
    end

    local fab = PREFABS["PLAIN"]
    assert(fab)

    if not x then x,y,dir = find_fab_loc(c, fab, 0, sel(must_put,3,2)) end

    if not x and must_put then
      x,y,dir = find_emergency_loc(c)
    end
    if not x then
      show_cell_blocks(p,c)
      con.printf("Could not find place for: %s\n", name)
--!!!!!!      error("Could not find place for: " .. name)
      return
    end
con.printf("add_object @ (%d,%d)\n", x, y)
    gap_fill(p,c, x,y, x,y, p.blocks[x][y].chunk.rmodel, { light=255, kind=8 })
    add_thing(p, c, x, y, name, true)
    fab_mark_walkable(c, x, y, 8, 1,1, 4)
  end

  local function add_player(c, name)
    add_object(c, name, "must")
  end

  local function add_dm_weapon(c)
    add_object(c, choose_dm_thing(GAME.dm.weapons, true))
  end

  local function add_switch(c)

    local info

    if c.is_exit then
      info = c.combo
    else
      info = GAME.switches[c.quest.item]
      if not info then
        error("Missing switch: " .. tostring(c.quest.item))
      end
    end
    assert(info)
    assert(info.switch)

    local fab = PREFABS[info.switch.prefab]
    assert(fab)

    local x,y,dir = find_fab_loc(c, fab, 0,3)
    if not x then
      show_cell_blocks(p,c)
      con.printf("Could not find place for SWITCH: %s %dx%d\n", fab.name, fab.long, fab.deep)
--!!!!!!      error("Could not find place for switch!");
      return
    end

    local skin = info.switch.skin
    local parm = { }
    
    if not c.is_exit then 
      parm.tag = c.quest.tag + 1
    end

---###    skin = { switch_w=info.switch, wall=info.wall, side_w=info.wall,
---###             beam_w="WOOD1", beam_f="FLAT5_2",
---###             lite_w="LITE5", frame_c=c.combo.floor,
---###           }
---###    parm.kind = info.kind_once

---### if not parm.kind then con.printf("INFO = %s\n", table_to_str(info)) end
---###    assert(parm.kind)

---###    if false then -- floor switch / niche switch
---###      local tex_h = 128  -- FIXME: assumption !!!
---###      parm.switch_h = c.rmodel.f_h + 72  -- TINY = 40
---###      parm.x_offset = 0
---###      parm.y_offset = tex_h - 72  -- TINY = 64
---###    end

    B_prefab(p,c, fab,skin,parm, p.blocks[x][y].chunk.rmodel,c.combo, x, y, dir)

    fab_mark_walkable(c, x,y, dir, fab.long,fab.deep, 4)
  end

  local function add_ceiling_beams(c) -- TEST JUNK
    local dir = 8

    for y = c.by1+1, c.by2-1, 2 do
      for x = c.bx1, c.bx2 do
        local B = p.blocks[x][y]
        if not B.c_tex and B.chunk then
          B.c_tex = "CEIL5_2"
          B.u_tex = "METAL"
          B.c_h   = B.chunk.rmodel.c_h - 20
        end
      end
    end
  end

  local function add_prefab(c)

    local name = rand_element
    {
      "billboard_NAZI",
      "billboard_lit_SHAWN",
      "billboard_stilts4_WREATH",
      "billboard_stilts_FLAGGY",

      "wall_lamp_RED_TORCH",
      "wall_lamp_GREEN_TORCH",
      "wall_lamp_BLUE_TORCH",
      "wall_pic_TV",
      "wall_pic_2S_EAGLE",
      "wall_pic_4S_ADOLF",

      "pillar_light1_METAL",
      "pillar_rnd_sm_POIS",
      "pillar_rnd_med_COMPSTA",
      "pillar_rnd_bg_COMPSTA",

      "statue_tech1",
      "ground_light_SILVER",
      "drinks_bar_WOOD_POTION",

      "crate_CRATE1",
      "crate_CRATE2",
      "crate_WOODSKUL",
      "crate_TV",
      "crate_rotnar_SILVER",
      "crate_rotate_CRATE1",
      "crate_rotate_CRATE2",

      "crate_triple_A",
      "crate_triple_B",
      "crate_jumble",

      "cage_pillar_METAL",
      "cage_small_METAL",
      "cage_large_METAL",
      "cage_medium_METAL",

      "cage_large_liq_NUKAGE",
      "cage_medium_liq_BLOOD",
      "cage_medium_liq_LAVA",

      "skylight_mega_METAL",
      "skylight_mega_METALWOOD",
      "skylight_cross_sm_METAL",
      "statue_tech2",
      "launch_pad_sml_S",
      "launch_pad_big_H",
      "launch_pad_med_F",
      "liquid_pickup_NUKAGE",

      "machine_pump1",
      "comp_tall_STATION1",
      "comp_tall_STATION2",
      "comp_thin_STATION1",
      "comp_thin_STATION2",
      "comp_desk_EW8",
      "comp_desk_EW2",
      "comp_desk_NS6",
      "comp_desk_USHAPE1",
      "comp_desk_USHAPE2",

      "pedestal_PLAYER",
      "pedestal_KEY",
      "pedestal_WEAPON",

    }
    local def = GAME.sc_fabs[name]
    assert(def)
    local fab = PREFABS[def.prefab]
    assert(fab)
    assert(def.skin)

    if fab.environment then
      if fab.environment == "indoor" and c.combo.outdoor then return end
      if fab.environment == "outdoor" and not c.combo.outdoor then return end
    end

---###    if fab.height_range then
---###      local h = c.ceil_h - c.floor_h
---###      if h < fab.height_range[1] or h > fab.height_range[2] then return end
---###    end

    local x,y,dir = find_fab_loc(c, fab, 0,2, def.force_dir)
    if not x then return end

con.printf("@ add_prefab: %s  dir:%d\n", name, dir)

    local parm = {

             y_offset = 0,

             cage_base_h = c.rmodel.f_h + 64,

             door_top_h  = c.rmodel.f_h + 72,

           }

    local mirror
    if fab.mirror then mirror = rand_odds(50) end

    B_prefab(p,c, fab, def.skin, parm, p.blocks[x][y].chunk.rmodel,c.combo, x, y, dir, mirror)

    fab_mark_walkable(c, x,y, dir, fab.long,fab.deep, 4)
  end

  local function add_scenery(c)

    -- choose kind: prefabs | scenery items

    if GAME.sc_fabs and rand_odds(60) then
      add_prefab(c)
      return
    end

    -- select type of item
    -- FIXME: use multiple times

    local item
    if c.combo.scenery and rand_odds(30) then
      item = c.combo.scenery
      if type(item) == "table" then
        item = rand_element(item)
      end
      assert(item)
    end

    if not item and c.room_type and c.room_type.scenery and rand_odds(80) then
      item = rand_key_by_probs(c.room_type.scenery)
      assert(item)
    end

    if not item and c.quest.level_theme and c.quest.level_theme.general_scenery and rand_odds(30) then
      item = rand_key_by_probs(c.quest.level_theme.general_scenery)
      assert(item)
    end

    if not item and GAME.scenery and rand_odds(1) then
      item = rand_table_pair(GAME.scenery)
    end

    if not item then return end

    local info = GAME.scenery[item]
    if not info then error("Missing info for item: " .. item) end

    local fab = PREFABS[info.prefab or "PLAIN"]
    assert(fab)

    local x,y,dir = find_fab_loc(c, fab, 0,2)
    if not x then return end

con.debugf("add_scenery : %s\n", item)
    gap_fill(p,c, x,y, x,y, p.blocks[x][y].chunk.rmodel)
    local th = add_thing(p, c, x, y, item, true)

    -- when there is wriggle room, use it!
    if info.r < 30 then
      local gap = 30 - info.r
      
      th.dx = rand_irange(-gap,gap)
      th.dy = rand_irange(-gap,gap)
    end

    fab_mark_walkable(c, x, y, 8, 1,1, 4)
  end


  --====| tizzy_up_room |====--


  -- the order here is important, earlier items may cause
  -- later items to no longer fit.

  -- PLAYERS
  if not p.deathmatch and c == p.quests[1].first then
    for i = 1,sel(settings.mode == "coop",4,1) do
      add_player(c, "player" .. tostring(i))
    end

  elseif p.deathmatch and (c.require_player or rand_odds(50)) then
    add_player(c, "dm_player")
  end

  if p.deathmatch and c.x==2 and not p.have_sp_player then
    add_player(c, "player1")
    p.have_sp_player = true
  end

  -- QUEST ITEM
  if not p.deathmatch and c == c.quest.last then
    if (c.quest.kind == "key") or
       (c.quest.kind == "weapon") or
       (c.quest.kind == "item")
    then
      add_object(c, c.quest.item, "must")

    elseif (c.quest.kind == "switch") or
           (c.quest.kind == "exit")
    then
      add_switch(c)
    end
  elseif p.deathmatch and (c.require_weapon or rand_odds(75)) then
    add_dm_weapon(c)
  end

  -- TODO: 'room switch'

  if p.deathmatch then
    -- secondary DM PLAYER
    if rand_odds(30) then
      add_object(c, "dm_player")
    end
    -- secondary DM WEAPON
    if rand_odds(15) then
      add_dm_weapon(c)
    end
  end

  -- SCENERY
  for loop = 1,1 do
    add_scenery(c)
  end
end


function build_rooms(p)

  local function create_blocks(p, c)
    
    for kx=1,3 do for ky=1,3 do
      local K = c.chunks[kx][ky]
      for x = K.x1,K.x2 do for y = K.y1,K.y2 do
        p.blocks[x][y] = { chunk = K }
      end end
    end end
  end
  
  local function GAP_FILL_ROOM(p, c)
    
    local function gap_fill_block(B)
      if B.solid then return end

      local model = B.rmodel or (B.chunk and B.chunk.rmodel) or c.rmodel

      -- floor
      if not B.f_tex then
        B.f_tex = model.f_tex
        B.f_h   = model.f_h
        B.l_tex = model.l_tex
        B.floor_code = model.floor_code
      end

      -- ceiling
      if not B.c_tex then
        B.c_tex = model.c_tex
        B.c_h   = model.c_h
        B.u_tex = model.u_tex
      end

      -- lighting
      if not B.light then
        B.light = model.light
      end
    end

    -- GAP_FILL_ROOM --

    for x = c.bx1,c.bx2 do for y = c.by1,c.by2 do
      local B = p.blocks[x][y]

      if B.fragments then
        for fx = 1,FW do for fy = 1,FH do
          local F = B.fragments[fx][fy]
          gap_fill_block(B.fragments[fx][fy])
        end end
      else
        gap_fill_block(B)

        if B.walk then
--        add_thing(p, c, x, y, "candle", false)
        end
      end
    end end
  end

  local function build_void_space(c)

    for kx = 1,3 do for ky = 1,3 do
      local K = c.chunks[kx][ky]
      if K.kind == "empty" then
--!!!        void_up_chunk(c, K)
        gap_fill(p, c, K.x1,K.y1, K.x2,K.y2,
          c.rmodel, { f_h=c.f_max+32, f_tex="NUKAGE" })
      elseif K.r_deep then
        gap_fill(p, c, K.rx1,K.ry1, K.rx2,K.ry2,
          c.rmodel, { f_h=c.f_max+32, f_tex="FWATER1" })
--!!!        { solid=c.combo.void })
---     { solid=sel(K.r_dir==2 or K.r_dir==8, "CRACKLE2",
---        sel((K.r_dir % 2) == 1, "SFALL1", "COMPBLUE")) })
      end
    end end
  end



  -- build_rooms --

  for zzz,cell in ipairs(p.all_cells) do
    create_blocks(p, cell)
  end

  for zzz,cell in ipairs(p.all_cells) do
    build_cell(p, cell)
  end

  for zzz,cell in ipairs(p.all_cells) do
    build_void_space(cell)
  end

  for zzz,cell in ipairs(p.all_cells) do
    tizzy_up_room(p, cell)
  end

  for zzz,cell in ipairs(p.all_cells) do
    GAP_FILL_ROOM(p, cell)
  end
end

function build_depots(p)

  local function build_one_depot(p, c)

    setup_rmodel(p, c)

    c.bx1 = BORDER_BLK + (c.x-1) * (BW+1) + 1
    c.by1 = BORDER_BLK + (c.y-1) * (BH+1) + 1

    c.bx2 = c.bx1 + BW - 1
    c.by2 = c.by1 + BW - 1

    local depot = c.quest.depot
    assert(depot)

    local places = depot.places
    assert(#places >= 2)
    assert(#places <= 4)

    local start = p.quests[1].first
  --!!!!
  --[[
    assert(start.player_pos)
    local player_B = p.blocks[start.player_pos.x][start.player_pos.y]
  --]] local player_B = start.rmodel

    -- check for double pedestals (Plutonia)
    if player_B.fragments then
      player_B = player_B.fragments[1][1]
    end
    assert(player_B)
    assert(player_B.f_h)

    local sec = { f_h = player_B.f_h, c_h = player_B.f_h + 128,
                  f_tex = c.rmodel.f_tex, c_tex = c.rmodel.c_tex,
                  l_tex = c.combo.void,  u_tex = c.combo.void,
                  light = 0
                }

    mon_sec = copy_block(sec)
    mon_sec[8] = { block_mon=true }

    door_sec = copy_block(sec)
    door_sec.c_h = door_sec.f_h
    door_sec.tag = depot.door_tag

    tele_sec = copy_block(sec)
    tele_sec.walk_kind = 126

    local m1,m2 = 1,4
    local t1,t2 = 6,BW

    -- mirror the room horizontally
    if c.x > start.x then
      m1,m2, t1,t2 = t1,t2, m1,m2
    end

    for y = 1,#places do
      c_fill(p, c, 1,y*2-1, BW,y*2, mon_sec, { mark=y })
      places[y].spots = rectangle_to_spots(c, c.bx1-1+m1, c.by1-1+y*2-1,
            c.bx1-1+m1+0, c.by1-1+y*2)

      for x = t1,t2 do
        local t = 1 + ((x + y) % #places)
        c_fill(p, c, x,y*2-1, x,y*2, tele_sec, { mark=x*10+y, walk_tag=places[t].tag})
      end
    end

    -- door separating monsters from teleporter lines
    c_fill(p, c, 5,1, 5,2*#places, door_sec)

    -- bottom corner block is same sector as player start,
    -- to allow sound to wake up these monsters.
    c_fill(p, c, m1,1, m1,1, copy_block(player_B), { same_sec=player_B })

    -- put a border around the room
    gap_fill(p, c, c.bx1-1, c.by1-1, c.bx2+1, c.by2+1, { solid=c.combo.wall })
  end

  --- build_depots ---

  for zzz,cell in ipairs(p.all_depots) do
    build_one_depot(p, cell)
  end
end


function build_level(p)

  for zzz,cell in ipairs(p.all_cells) do
    setup_rmodel(p, cell)
  end

if string.find(p.lev_name, "L10") then
build_pacman_level(p, p.quests[1].first);
return
end

  make_chunks(p)
  con.ticker()

  show_chunks(p)

  setup_borders_and_corners(p)

  build_rooms(p)
  con.ticker()

  build_borders(p)
  con.ticker()

  build_depots(p)
  con.ticker()

  con.progress(25); if con.abort() then return end
 
  if p.deathmatch then
    deathmatch_through_level(p)
  else
    battle_through_level(p)
  end

  con.progress(40); if con.abort() then return end
end

