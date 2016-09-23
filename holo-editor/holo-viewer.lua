--      Hologram Viewer v0.70
-- by NEO, Totoro (aka MoonlightOwl)
-- 11/12/2014, all right reserved =)
--        computercraft.ru

local fs = require('filesystem')
local com = require('component')
local args = { ... }

-- ================================ H O L O G R A M S   S T U F F ================================ --
-- loading add. components
function trytofind(name)
  if com.isAvailable(name) then
    return com.getPrimary(name)
  else
    return nil
  end
end

-- constants
HOLOH = 32
HOLOW = 48

-- hologram vars
holo = {}
colortable = {{},{},{}}
hexcolortable = {}
proj_scale = 1.0

function set(x, y, z, value)
  if holo[x] == nil then holo[x] = {} end
  if holo[x][y] == nil then holo[x][y] = {} end
  holo[x][y][z] = value
end
function get(x, y, z)
  if holo[x] ~= nil and holo[x][y] ~= nil and holo[x][y][z] ~= nil then
    return holo[x][y][z]
  else
    return 0
  end
end
function rgb2hex(r,g,b)
  return r*65536+g*256+b
end


local reader = {}
function reader:init(file)
  self.buffer = {}
  self.file = file
end
function reader:read()
  if #self.buffer == 0 then
    if not self:fetch() then return nil end
  end
  local sym = self.buffer[#self.buffer]
  self.buffer[#self.buffer] = nil
  return sym
end
function reader:fetch()
  self.buffer = {}
  local char = file:read(1)
  if char == nil then return false
  else
    local byte = string.byte(char)
    for i=0, 3 do
      local a = byte % 4
      byte = math.floor(byte / 4)
      self.buffer[4-i] = a
    end
    return true
  end
end

local function loadHologram(filename)
  if filename == nil then
    error("[ERROR] Incorrect filename.")
  end

  local compressed
  if string.sub(filename, -4) == '.3dx' then
    compressed = true
  elseif string.sub(filename, -3) == '.3d' then
    compressed = false
  else
    error("[ERROR] No file extension given.")
  end

  if fs.exists(filename) then
    file = io.open(filename, 'rb')
    if file ~= nil then
      for i=1, 3 do
        for c=1, 3 do
          colortable[i][c] = string.byte(file:read(1))
        end
        hexcolortable[i] = rgb2hex(colortable[i][1], colortable[i][2], colortable[i][3])
      end
      holo = {}
      reader:init(file)
      if compressed then
        local x, y, z = 1, 1, 1
        while true do
          local a = reader:read()
          if a == nil then file:close(); return true end
          local len = 1
          while true do
            local b = reader:read()
            if b == nil then
              file:close()
              if a == 0 then return true
              else error("[ERROR] Bad file format.") end
            end
            local fin = (b > 1)
            if fin then b = b-2 end
            len = bit32.lshift(len, 1)
            len = len + b
            if fin then break end
          end
          len = len - 1
          for i=1, len do
            if a ~= 0 then set(x,y,z, a) end
            z = z+1
            if z > HOLOW then
              y = y+1
              if y > HOLOH then
                x = x+1
                if x > HOLOW then file:close(); return true end
                y = 1
              end
              z = 1
            end
          end
        end
      else
        for x=1, HOLOW do
          for y=1, HOLOH do
            for z=1, HOLOW do
              local a = reader:read()
              if a ~= 0 and a ~= nil then
                set(x,y,z, a)
              end
            end
          end
        end
      end
      file:close()
      return true
    else
      error("[ERROR] Could not open the file: "..filename.."!")
    end
  else
      error("[ERROR] File not found: "..filename.."!")
  end
end

function scaleHologram(scale)
  if scale == nil or scale<0.33 or scale>4 then
    error("[ERROR] The scale of hologram must be a number in the range [0.33, 4]")
  end
  proj_scale = scale
end

function drawHologram()
  -- check hologram projector availability
  h = trytofind('hologram')
  if h ~= nil then
    local depth = h.maxDepth()
    -- clear projector
    h.clear()
    -- set projector scale
    h.setScale(proj_scale)
    -- send palette
    if depth == 2 then
      for i=1, 3 do
        h.setPaletteColor(i, hexcolortable[i])
      end
    else
      h.setPaletteColor(1, hexcolortable[1])
    end
    -- send voxel array
    for x=1, HOLOW do
      for y=1, HOLOH do
        for z=1, HOLOW do
          n = get(x,y,z)
          if n ~= 0 then
            if depth == 2 then
              h.set(x,y,z,n)
            else
              h.set(x,y,z,1)
            end
          end
        end
      end
    end
    print("Done.")
  else
    error("[ERROR] Hologram Projector not found.")
  end
end
-- =============================================================================================== --

-- Main part
loadHologram(args[1])

if args[2] ~= nil then
  scaleHologram(tonumber(args[2]))
end

drawHologram()
