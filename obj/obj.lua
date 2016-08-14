--    OBJ model library 1.0
--    ---------------------
-- by Totoro (computercraft.ru)

local obj = {}
local vertex = {}
local faces = {}

local color = {r = 1, g = 0, b = 0}
local position = {x = 0, y = 0, z = 0}
local scale = 1.0

local function getVertex(data)
  return tonumber(data:match("(-?%d+)/"))
end

obj.load = function(filename)
  file = io.open(filename, "r")
  if file ~= nil then
    vertex = {}

    for line in file:lines() do
      if line ~= nil and line ~= '' then
        local key, a, b, c, d = line:match("(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s*(%S*)")

        -- load vertex data / skip normals and textures
        if key == 'v' then
          local x, y, z = tonumber(a), tonumber(b), tonumber(c)
          table.insert(vertex, {x,y,z})

        -- load faces data
        elseif key == 'f' then
          local v1, v2, v3 = getVertex(a), getVertex(b), getVertex(c)
          if v1 < 0 then
            local len = #vertex + 1
            v1, v2, v3 = len + v1, len + v2, len + v3
          end
          table.insert(faces, {vertex[v1], vertex[v2], vertex[v3]})
        end
      end
    end
    file:close()
  else
    error("[OBJ.load] File not found!")
  end
end

obj.setColor = function(r, g, b)
  color.r = r; color.g = g; color.b = b
end
obj.setPosition = function(x, y, z)
  position.x = x; position.y = y; position.z = z
end
obj.setScale = function(s)
  scale = s
end

obj.getColor = function()
  return {color.r, color.g, color.b}
end
obj.getPosition = function()
  return {position.x, position.y, position.z}
end
obj.getScale = function()
  return scale
end

obj.draw = function(glasses)
  local count = 0
  for n, face in pairs(faces) do
    local triangle = glasses.addTriangle3D()
    triangle.setVertex(1, face[1][1]*scale + position.x, face[1][2]*scale + position.y, face[1][3]*scale + position.z)
    triangle.setVertex(2, face[2][1]*scale + position.x, face[2][2]*scale + position.y, face[2][3]*scale + position.z)
    triangle.setVertex(3, face[3][1]*scale + position.x, face[3][2]*scale + position.y, face[3][3]*scale + position.z)
    triangle.setColor(color.r, color.g, color.b)
    ---
    count = count + 1
    if count > 50 then count = 0; os.sleep(0.1) end
  end
end

obj.getVertexNum = function()
  return #vertex
end
obj.getPolyNum = function()
  return #faces
end

return obj
