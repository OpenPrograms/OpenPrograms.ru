local node, h_min, h_max = 9, 1.7, 51
local computer, component = require('computer'), require('component')
local IC, g, R = component.inventory_controller, component.geolyzer, component.robot
local x, y, z, d, a_dr, x_dr, z_dr, x1, z1 = 0, 0, 0, nil, 1, 0, 0, 0, 0
local tWorld = {x = {}, y = {}, z = {}}
local GS, IS, tg, p, height, tTest, bedrock, x_f, y_f, z_f, gen, xS, yS, zS, D0, D1, ind, sb, cb, Hm = IC.getStackInInternalSlot, R.inventorySize, 0, 1, 64
local tWaste = {
  'cobblestone',
  'sandstone',
  'stone',
  'dirt',
  'grass',
  'gravel',
  'sand',
  'end_stone',
  'hardened_clay',
  'mossy_cobblestone',
  'planks',
  'fence',
  'torch',
  'nether_brick',
  'nether_brick_fence',
  'nether_brick_stairs',
  'netherrack',
  'soul_sand'
}

local function report(msg)
  print(msg)
  if component.isAvailable('tunnel') then
    component.tunnel.send(msg)
  end
end

local function compass()
  local tCmps = {{-1, 0}, {0, -1}, {1, 0}, [0] = {0, 1}}
  while not d do
    for c = 0, 3 do
      R.swing(3)
      if g.scan(tCmps[c][1], tCmps[c][2], 0, 1, 1, 1, true)[1] == 0 and R.place(3) then
        if g.scan(tCmps[c][1], tCmps[c][2], 0, 1, 1, 1, true)[1] > 0 then
          d = c
          return
        end
      end
    end
    R.turn(true)
  end
end

local function delta(xD, yD, zD)
  xS, yS, zS, D0, D1, ind = 0, 0, 0, math.huge, math.huge, 0
  for bl = 1, #tWorld.x do
    xS, yS, zS = tWorld.x[bl], tWorld.y[bl], tWorld.z[bl]
    if xS < xD then xS = xD - xS else xS = xS - xD end
    if yS < yD then yS = yD - yS else yS = yS - yD end
    if zS < zD then zS = zD - zS else zS = zS - zD end
    D0 = xS + yS + zS
    if D0 < D1 then
      D1 = D0
      ind = bl
    end
  end
  return ind
end

local tMove = {
  function() x, x1 = x - 1, x1 - 1 end,
  function() z, z1 = z - 1, z1 - 1 end,
  function() x, x1 = x + 1, x1 + 1 end,
  [0] = function() z, z1 = z + 1, z1 + 1 end
}

local function move(side)
  R.swing(0)
  sb, cb = R.swing(side)
  if not sb and cb == 'block' then
    tWorld.x, tWorld.y, tWorld.z = {}, {}, {}
    move(1)
    report('ERROR: PZ!')
    Hm()
  else
    while R.swing(side) do
    end
  end
  if R.move(side) then
    if side == 0 then
      y = y - 1
    elseif side == 1 then
      y = y + 1
    elseif side == 3 then
      tMove[d]()
    end
  end
  if #tWorld.z ~= 0 then
    for m = 1, #tWorld.z do
      if x == tWorld.x[m] and y == tWorld.y[m] and z == tWorld.z[m] then
        table.remove(tWorld.x, m)
        table.remove(tWorld.y, m)
        table.remove(tWorld.z, m)
        break
      end
    end
  end
end

local function turn(cc)
  if not cc then
    cc = false
  end
  if R.turn(cc) then
    if cc then
      d = (d + 1) % 4
    else
      d = (d - 1) % 4
    end
  end
end

local function spiral(node_t)
  a_dr, x_dr, z_dr = 1, 0, 0
  while true do
    for i = 1, a_dr do
      if a_dr % 2 == 0 then
        x_dr = x_dr + 1
      else
        x_dr = x_dr - 1
      end
      node_t = node_t - 1
      if node_t == 0 then
        return
      end
    end
    for i = 1, a_dr do
      if a_dr % 2 == 0 then
        z_dr = z_dr + 1
      else
        z_dr = z_dr - 1
      end
      node_t = node_t - 1
      if node_t == 0 then
        return
      end
    end
    a_dr = a_dr + 1
  end
end

local function sturn(dT)
  while d ~= dT do
    turn((dT - d) % 4 == 1)
  end
end

local function gotot(xt, yt, zt)
  while y ~= yt do
    if y < yt then
      move(1)
    elseif y > yt then
      move(0)
    end
  end
  if x < xt and d ~= 3 then
    sturn(3)
  elseif x > xt and d ~= 1 then
    sturn(1)
  end
  while x ~= xt do
    move(3)
  end
  if z < zt and d ~= 0 then
    sturn(0)
  elseif z > zt and d ~= 2 then
    sturn(2)
  end
  while z ~= zt do
    move(3)
  end
end

local function scan(sy)
  tTest = g.scan(-x1, -z1, sy, 8, 8, 1, true)
  p = 1
  for sz = -z1, 7-z1 do
    for sx = -x1, 7-x1 do
      if tTest[p] >= h_min and tTest[p] <= h_max then
        if sy == 0 and sz == z1 and sx == x1 then
        else
          table.insert(tWorld.x, x+sx)
          table.insert(tWorld.y, y+sy)
          table.insert(tWorld.z, z+sz)
        end
      elseif tTest[p] < -0.3 then
        tWorld.x, tWorld.y, tWorld.z = {}, {}, {}
        bedrock = y
        return false
      end
      p = p + 1
    end
  end
end

local function fullness()
  local item
  for slot = 1, IS() do
    if R.count(slot) > 0 then
      if not item then
        item = GS(slot).size
      else
        item = item + GS(slot).size
      end
    end
  end
  if item then
    return item/(IS()*64)
  else
    return 0
  end
end

local function packer()
  if component.isAvailable('crafting') then
    local tCrafting, tBlocks = {1, 2, 3, 5, 6, 7, 9, 10, 11}, {'redstone', 'coal', 'dye', 'diamond', 'emerald'}
    local function clear_table()
      for slot = 1, 9 do
        if R.count(tCrafting[slot]) > 0 then
          R.select(tCrafting[slot])
          for slot1 = 4, IS()-1 do
            if slot1 == 4 or slot1 == 8 or slot1 > 11 then
              R.transferTo(slot1, 64)
            end
          end
        end
      end
    end
    for slot = IS(), 1, -1 do
      for slot1 = 1, slot-1 do
        if R.count(slot) > 0 then
          item = GS(slot)
          item1 = GS(slot1)
          if not item1 or item.name == item1.name and item.maxSize-item.size ~= 0 then
            R.select(slot)
            R.transferTo(slot1, 64)
          end
        end
      end
    end
    for i = 1, #tBlocks do
      clear_table()
      for slot = 4, IS() do
        if slot == 4 or slot == 8 or slot > 11 then
          if R.count(slot) >= 9 then
            if GS(slot).name == 'minecraft:'..tBlocks[i] then
              R.select(slot)
              while R.count() > 0 do
                for slot1 = 1, 9 do
                  R.transferTo(tCrafting[slot1], 1)
                end
              end
            end
          end
        end
      end
      component.crafting.craft(64)
    end
  end
end

local function dropping(cont)
  local function isWaste(n)
    for w = 1, #tWaste do
      if n == 'minecraft:'..tWaste[w] then
        return true
      end
    end
  end
  local function drop()
    for slot = 1, IS() do
      if R.count(slot) > 0 then
        R.select(slot)
        if isWaste(GS(slot).name) then
          R.drop(0)
        else
          if cont then
            if not R.drop(3) then
              report('ERROR: SPACE?')
              while not R.drop(3) do
                os.sleep(10)
              end
            end
          end
        end
      end
    end
  end
  local s_cont
  if cont then
    for side = 0, 3 do
      if IC.getInventorySize(3) and IC.getInventorySize(3) > 1 then
        s_cont = true
        drop()
        break
      end
      turn()
    end
    if not s_cont then
      report('ERROR: CHEST?!')
      os.sleep(30)
      dropping(true)
    end
  else
    drop()
  end
end

Hm = function()
  gotot(0, -1, 0)
  move(1)
  packer()
  dropping(true)
  local status = 0
  for side = 0, 3 do
    if IC.getInventorySize(3) and IC.getInventorySize(3) == 1 then
      while status == 0 do
        if R.durability() ~= 1 then
          IC.equip()
          R.drop(3)
          os.sleep(30)
          R.suck(3)
          IC.equip()
        else
          status = 1
        end
      end
      break
    end
    turn()
  end
end

local function recovery()
  x_f, y_f, z_f = x, y, z
  Hm()
  move(0)
  gotot(x_f, y_f, z_f)
end

local function CL(set)
  if component.isAvailable('chunkloader') then
    component.chunkloader.setActive(set)
  end
end

local function state()
  if fullness() > 0.95 then
    dropping()
    packer()
    if fullness() > 0.95 then
      recovery()
    end
  end
  if R.durability() < 0.1 then
    recovery()
  end
  if computer.energy()/computer.maxEnergy() < 0.2 then
    if component.isAvailable('generator') then
      for slot = 1, IS() do
        if component.generator.insert(64) then
          gen = true
          os.sleep(30)
          break
        end
      end
      if gen then
        gen = nil
      else
        recovery()
      end
    else
      recovery()
    end
  end
end

local tArgs = {...}
if tArgs[1] then
  node = tonumber(tArgs[1])
end
if tArgs[2] then
  height = tonumber(tArgs[2])
end

CL(true)
local test_time = computer.uptime()
move(0)
compass()
for n = 1, node do
  while not bedrock do
    scan(-1)
    if #tWorld.x ~= 0 then
      while #tWorld.x ~= 0 do
        tg = delta(x, y, z)
        gotot(tWorld.x[tg], tWorld.y[tg], tWorld.z[tg])
      end
    else
      if not bedrock then
        move(0)
      end
    end
    state()
    if y == height then
      bedrock = y
    end
  end
  state()
  if n ~= node then
    spiral(n)
    gotot(x_dr*8, math.abs(bedrock)+y-1, z_dr*8)
    x1, z1 = 0, 0
    bedrock = nil
  end
end
Hm()
CL(false)
local min, sec = math.modf((computer.uptime()-test_time)/60)
report('Done: '.. min ..' min. '.. math.ceil(sec*60) ..' sec.')
