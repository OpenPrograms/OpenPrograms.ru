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

local function create(x,y,z,p)
  if glass.addDot3D then
    -- OpenGlasses 1
    local a = glass.addDot3D()
    a.set3DPos(x + 0.5, y + 0.5, z + 0.5)
    a.setColor(table.unpack(tocolor(p)))
  else
    -- OpenGlasses 2
    local widget = glass.addCube3D()
    widget.addTranslation(x + 0.125, y + 0.125, z + 0.125)
    widget.addScale(0.75, 0.75, 0.75)
    widget.setVisibleThroughObjects(true)

    local color = tocolor(p)
    color[4] = 1

    widget.addColor(table.unpack(color))
  end
end

for x=-size,size do
  for z=-size,size do
    tile=geo.scan(x,z)
    os.sleep(0)
    for Y=-math.min(size,18),math.min(maxY,18) do
      local y=Y+32
      if tile[y]>pl then create(x,Y,z,tile[y]) end
    end
  end
end


print("found objects:", (glass.getObjectCount or glass.getWidgetCount)())
