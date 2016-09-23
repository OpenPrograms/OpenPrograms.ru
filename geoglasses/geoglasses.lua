local com=require("component")

local arg={...}
local glass=com.glasses
glass.removeAll()
local geo=   com.geolyzer

local size=tonumber(arg[2]) or 16
local pl=tonumber(arg[1] or 3)
local minpl = 2
local maxpl = 5

local maxY
if (tonumber(arg[3]) or 0)==0 then maxY=1 else maxY=size end

local function tocolor(pl)
  local color = (pl-minpl)/maxpl
  if color<0 then
    return {1,1,1}
  elseif color>1 then
    return {1,0,1}
  else
    return {color,1-color,0}
  end
end

function create(x,y,z,p)
  local a=glass.addDot3D()
  a.set3DPos(x,y,z)
  a.setColor(table.unpack(tocolor(p)))
end

for x=-size,size do
  for z=-size,size do
    tile=geo.scan(x,z)
    os.sleep(0)
    for Y=-math.min(size,18),math.min(maxY,18) do
      local y=Y+32
      if tile[y]>pl then create(x+0.5,Y+0.5,z+0.5,tile[y]) end
    end
  end
end
print("found objects:", glass.getObjectCount())
