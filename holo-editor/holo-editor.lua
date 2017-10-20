--       Hologram Editor v0.7.1
-- 2017 (c) Totoro (aka MoonlightOwl)
--         computercraft.ru

local unicode = require('unicode')
local event = require('event')
local term = require('term')
local fs = require('filesystem')
local shell = require('shell')
local com = require('component')
local gpu = com.gpu

--     Colors     --
local color = {
  back = 0x000000,
  fore = 0xFFFFFF,
  info = 0x335555,
  error = 0xFF3333,
  help = 0x336600,
  gold = 0xFFCC33,
  gray = 0x080808,
  lightgray = 0x333333,
  lightlightgray = 0x666666
}

--     Buttons    --
local keys = {
  BACKSPACE = 14,
  EXIT = 16,
  ENTER = 28,
  ERASER = 41,
  CLEAR = 211
}

--  Localization  --
local loc = {
  FILE_REQUEST = 'Enter file name',
  ERROR_CAPTION = 'Error',
  WARNING_CAPTION = 'Warning',
  DONE_CAPTION = 'Done',
  PROJECTOR_UNAVAILABLE_MESSAGE = 'Projector not found!',
  SAVING_MESSAGE = 'Saving...',
  SAVED_MESSAGE = 'The file was saved!',
  LOADING_MESSAGE = 'Loading...',
  LOADED_MESSAGE = 'Loaded successfully!',
  TOO_LOW_RESOLUTION_ERROR = '[ERROR] Your display/GPU does not support 80×25+ resolution.',
  TOO_LOW_SCREEN_TIER_ERROR = '[ERROR] You can use the Tier 2 GPU, but you need Tier 3 display anyway.',
  FORMAT_READING_ERROR = 'Invalid file format!',
  FILE_NOT_FOUND_ERROR = 'File not found!',
  CANNOT_OPEN_ERROR = 'Cannot open the file!',
  CANNOT_SAVE_ERROR = 'Cannot write to the file!',
  PALETTE_FRAME = 'Palette',
  VIEWPORT_FRAME = 'Projection',
  UTILS_FRAME = 'Management',
  LAYER_LABEL = 'Hologram layer:',
  GHOST_LAYER_LABEL = '\'Ghost\' layer:',
  PROGRAMMERS_LABEL = 'Developers:',
  CONTACT_LABEL = 'Contact:',
  EXIT_LABEL = "Quit: 'Q' or ",
  EXIT_BUTTON = 'Exit',
  REFRESH_BUTTON = 'Refresh',
  TOP_BUTTON = 'Top',
  FRONT_BUTTON = 'Front',
  SIDE_BUTTON = 'Side',
  BELOW_BUTTON = 'Below',
  ABOVE_BUTTON = 'Above',
  CLEAR_BUTTON = 'Clear',
  FILL_BUTTON = 'Fill',
  TO_PROJECTOR = 'To Projector',
  SAVE_BUTTON = 'Save',
  LOAD_BUTTON = 'Load',
  NEW_FILE_BUTTON = 'New file'
}
--      ****      --


-- Try to load a component safely
local function trytofind(name)
  if com.isAvailable(name) then
    return com.getPrimary(name)
  else
    return nil
  end
end

-- Constants --
local OLDWIDTH, OLDHEIGHT = gpu.getResolution()
local WIDTH, HEIGHT = gpu.maxResolution()
local FULLSIZE = true
local HOLOW, HOLOH = 48, 32        -- hologram size
local MENUX = HOLOW*2+5            -- right panel offset
local BUTTONW = 12                 -- standart button width
local GRIDX, GRIDY = 3, 2          -- grid offset
local TOP = { width = HOLOW, height = HOLOW, depth = HOLOH }
local FRONT = { width = HOLOW, height = HOLOH, depth = HOLOW }
local SIDE = { width = HOLOW, height = HOLOH, depth = HOLOW }

-- Interface variables --
local buttons = {}
local textboxes = {}
local repaint = false

-- App state --
local colortable = {}
local hexcolortable = {}
local darkhexcolors = {}
local brush = {color = 1, x = 8, cx = 8, moving = false}
local ghost_layer = 1
local ghost_layer_below = true
local layer = 1
local view = TOP
local running = true

-- Auxiliary functions --
local function rgb2hex(r,g,b)
  return r*65536+g*256+b
end
local function setHexColor(n, r, g, b)
  local hexcolor = rgb2hex(r,g,b)
  hexcolortable[n] = hexcolor
  darkhexcolors[n] = bit32.rshift(bit32.band(hexcolor, 0xfefefe), 1)
end

local _f = gpu.getForeground()
local function foreground(color)
  if color ~= _f then gpu.setForeground(color); _f = color end
end
local _b = gpu.getBackground()
local function background(color)
  if color ~= _b then gpu.setBackground(color); _b = color end
end

-- ========================================= H O L O G R A P H I C S ========================================= --
local holo = {}
local function set(x, y, z, value)
  if holo[x] == nil then holo[x] = {} end
  if holo[x][y] == nil then holo[x][y] = {} end
  holo[x][y][z] = value
end
local function get(x, y, z)
  if holo[x] ~= nil and holo[x][y] ~= nil and holo[x][y][z] ~= nil then
    return holo[x][y][z]
  else
    return 0
  end
end

local writer = {}
function writer:init(file)
  self.buffer = {}
  self.file = file
end
function writer:write(sym)
  table.insert(self.buffer, sym)
  if #self.buffer >= 4 then self:finalize() end
end
function writer:finalize()
  if #self.buffer > 0 then
    local byte = 0
    for i=4, 1, -1 do
      local x = self.buffer[i] or 0
      byte = byte * 4 + x
    end
    self.file:write(string.char(byte))
    self.buffer = {}
  end
end

local function toBinary(x)
  local data = {}
  while x > 0 do
    table.insert(data, x % 2)
    x = math.floor(x / 2)
  end
  return data
end

local function save(filename, compressed)
  -- saving the palette
  local file = io.open(filename, 'wb')
  if file ~= nil then
    for i=1, 3 do
      for c=1, 3 do
        file:write(string.char(colortable[i][c]))
      end
    end
    writer:init(file)
    if compressed then
      local function put(symbol, length)
        if length > 0 then
          writer:write(symbol)
          local l = toBinary(length + 1)
          local lLen = #l
          l[lLen] = nil
          lLen = lLen - 1
          l[1] = l[1] + 2
          for i=lLen, 1, -1 do writer:write(l[i]) end
        end
      end
      local len = 0
      local sym = -1
      -- saving compressed data
      for x=1, HOLOW do
        for y=1, HOLOH do
          for z=1, HOLOW do
            local a = get(x, y, z)
            if sym == a then  -- next symbol of the sequence
              len = len + 1
            else              -- first symbol of the sequence
              put(sym, len)
              len = 1
              sym = a
            end
          end
        end
      end
      put(sym, len)  -- the last sequence
    else
      -- saving the data without compression
      for x=1, HOLOW do
        for y=1, HOLOH do
          for z=1, HOLOW do
            writer:write(get(x, y, z))
          end
        end
      end
    end
    writer:finalize()
    file:close()
    return true
  else
    return false, filename..": "..loc.CANNOT_SAVE_ERROR
  end
end

local reader = {}
function reader:init(file)
  self.buffer = {}
  self.file = file
end
function reader:read()
  local bufferLen = #self.buffer  
  if bufferLen == 0 then
    if not self:fetch() then return nil end
  end
  -- get the last symbol from the buffer
  local sym = self.buffer[bufferLen]
  self.buffer[bufferLen] = nil
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
      self.buffer[4-i] = a   -- writing bytes in reversed order
    end
    return true
  end
end

local function load(filename, compressed)
  local path = shell.resolve(filename, "")
  if path ~= nil then
    file = io.open(filename, 'rb')
    if file ~= nil then
      -- loading the palette
      for i=1, 3 do
        for c=1, 3 do
          colortable[i][c] = string.byte(file:read(1))
        end
        setHexColor(i,colortable[i][1],
                      colortable[i][2],
                      colortable[i][3])
      end
      -- loading the data
      holo = {}
      reader:init(file)
      if compressed then          -- reading compressed data
        local x, y, z = 1, 1, 1
        while true do
          local a = reader:read() -- reading symbol value
          if a == nil then file:close(); return true end
          local len = 1
          while true do           -- reading binary length value
            local b = reader:read()
            if b == nil then
              file:close()
              if a == 0 then return true
              else return false, filename..": "..loc.FORMAT_READING_ERROR end
            end
            local fin = (b > 1)
            if fin then b = b-2 end
            len = bit32.lshift(len, 1)
            len = len + b
            if fin then break end
          end
          len = len - 1
          -- write the sequence
          for i=1, len do
            -- write one voxel
            if a ~= 0 then set(x,y,z, a) end
            -- move the coordinates
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
      else                        -- reading uncompressed data
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
      return false, filename..": "..loc.CANNOT_OPEN_ERROR
    end
  else
    return false, filename..": "..loc.FILE_NOT_FOUND_ERROR
  end
end


-- ============================================== B U T T O N S ============================================== --
local Button = {}
Button.__index = Button
function Button.new(func, x, y, text, fore, back, width, nu)
  self = setmetatable({}, Button)

  self.form = '[ '
  if width == nil then width = 0
    else width = (width - unicode.len(text))-4 end
  for i=1, math.floor(width/2) do
    self.form = self.form.. ' '
  end
  self.form = self.form..text
  for i=1, math.ceil(width/2) do
    self.form = self.form.. ' '
  end
  self.form = self.form..' ]'

  self.func = func

  self.x = math.floor(x); self.y = math.floor(y)
  self.fore = fore
  self.back = back
  self.visible = true

  self.notupdate = nu or false

  return self
end
function Button:draw(fore, back)
  if self.visible then
    local fore = fore or self.fore
    local back = back or self.back
    foreground(fore)
    background(back)
    gpu.set(self.x, self.y, self.form)
  end
end
function Button:click(x, y)
  if self.visible then
    if y == self.y then
      if x >= self.x and x < self.x+unicode.len(self.form) then
        self:draw(self.back, self.fore)
        local data = self.func()
        if not self.notupdate then self:draw() end
        return true, data
      end
    end
  end
  return false
end

local function buttonNew(buttons, func, x, y, text, fore, back, width, notupdate)
  local button = Button.new(func, x, y, text, fore, back, width, notupdate)
  table.insert(buttons, button)
  return button
end
local function buttonsDraw(buttons)
  local buttonsLen = #buttons
  for i=1, buttonsLen do
    buttons[i]:draw()
  end
end
local function buttonsClick(buttons, x, y)
  local buttonsLen = #buttons
  for i=1, buttonsLen do
    local ok, data = buttons[i]:click(x, y)
    if ok then return data end
  end
  return nil
end


-- ============================================ T E X T B O X E S ============================================ --
local Textbox = {}
Textbox.__index = Textbox
function Textbox.new(validator, func, x, y, width, value, defValue)
  self = setmetatable({}, Textbox)
  self.x = math.floor(x); self.y = math.floor(y)
  self.width = width or BUTTONW
  self.valueWidth = self.width - 3
  self.form = '>' .. string.rep(' ', self.width - 1)
  self.validator = validator
  self.func = func
  self.value = tostring(value)
  self.defValue = tostring(defValue)
  self.visible = true
  self.active = false
  return self
end
function Textbox:renderForm()
  foreground(color.fore)
  background(self.active and color.info or color.lightgray)
  gpu.set(self.x, self.y, self.form)
end
function Textbox:renderValue(value)
  foreground(color.fore)
  background(self.active and color.info or color.lightgray)
  local value = value or self.value
  if unicode.len(value) > self.valueWidth then
    value = string.sub(value, -self.valueWidth)
  end
  if self.active then value = value .. '_' end
  gpu.set(self.x+2, self.y, tostring(value))
end
function Textbox:draw()
  if self.visible then
    self:renderForm()
    if not self.active and (unicode.len(self.value) == 0) then
      self:renderValue(self.defValue)
    else
      self:renderValue()
    end
  end
end
function Textbox:click(x, y)
  if self.visible then
    if y == self.y then
      if x >= self.x and x < self.x+self.width then
        -- textbox captures the "focus"
        self.active = true
        self:draw()
        local value = self.value
        while true do
          local name, a, char, code = event.pull()
          if name == 'key_down' then
            if char > 30 then
              local letter = unicode.char(char)
              value = value .. letter
              self:renderValue(value)
            elseif code == keys.BACKSPACE then
              if unicode.len(value) > 0 then
                value = unicode.sub(value, 1, -2)
                self:renderForm()
                self:renderValue(value)
              end
            elseif code == keys.ENTER then break end
          elseif name == 'touch' then break end
        end
        -- textbox loses the "focus"
        self.active = false
        if self.validator(value) then
          self.value = value
          self.func(value)
        end
        self:draw()
        return true
      end
    end
  end
  return false
end

local function textboxNew(textboxes, validator, func, x, y, width, value, defValue)
  textbox = Textbox.new(validator, func, x, y, width, value, defValue)
  table.insert(textboxes, textbox)
  return textbox
end
local function textboxesDraw(textboxes)
  local textboxesLen = #textboxes
  for i=1, textboxesLen do
    textboxes[i]:draw()
  end
end
local function textboxesClick(textboxes, x, y)
  local textboxesLen = #textboxes
  for i=1, textboxesLen do
    textboxes[i]:click(x, y)
  end
end


-- ============================================= G R A P H I C S ============================================= --
local gridLine1, gridLine2, gridLine1s, gridLine2s = nil, nil, nil, nil
local strLine = "+"
local colorCursorY, colorCursorWidth = 8, 8
local function initGraphics()
  -- grid prefabs
  if FULLSIZE then gridLine1 = string.rep("██  ", HOLOW/2)
  else
    gridLine1 = string.rep("▀", HOLOW/2)
    gridLine2 = string.rep("▄", HOLOW/2)
    gridLine1s = string.rep("▀", HOLOH/2)
    gridLine2s = string.rep("▄", HOLOH/2)
  end
  -- lines prefabs
  for i=1, WIDTH do
    strLine = strLine..'-'
  end
  -- palette cursor params
  if not FULLSIZE then
    colorCursorY, colorCursorWidth = 1, 7
  end
end

-- draw a line
local function line(x1, x2, y)
  gpu.set(x1,y,string.sub(strLine, 1, x2-x1))
  gpu.set(x2,y,'+')
end

-- draw a frame
local function frame(x1, y1, x2, y2, caption, nobottom)
  line(x1, x2, y1)
  if not nobottom then line(x1, x2, y2) end
  if caption ~= nil then
    gpu.set(x1 + math.ceil((x2-x1)/2) - math.ceil(unicode.len(caption)/2), y1, caption)
  end
end

-- draw a grid
local function drawGrid(x, y)
  foreground(color.gray)
  background(color.back)
  gpu.fill(0, y, MENUX, HOLOW, ' ')
  if FULLSIZE then
    for i = 0, view.height - 1 do
      gpu.set(x + (i%2)*2, y + i, gridLine1)
    end
    if view.height + y < HEIGHT then
      foreground(color.fore)
      line(1, MENUX-1, y+HOLOH)
    end
  else
    for i = 0, view.height - 1 do
      if view == TOP then
        if i%2 == 0 then gpu.set(x + i, y, gridLine1, true)
        else gpu.set(x+i, y, gridLine2, true) end
      else
        if i%2 == 0 then gpu.set(x + i, y, gridLine1s, true)
        else gpu.set(x+i, y, gridLine2s, true) end
      end
    end
  end
end

-- draw a colored rectangle
local function drawRect(x, y, fill)
  foreground(color.fore)
  background(color.gray)
  gpu.set(x, y,   "╓──────╖")
  gpu.set(x, y+1, "║      ║")
  gpu.set(x, y+2, "╙──────╜")
  foreground(fill)
  gpu.set(x+2, y+1, "████")
end
local function drawSmallRect(x, y, fill)
  foreground(color.fore)
  gpu.set(x, y,   "╓─────╖")
  gpu.set(x, y+1, "║     ║")
  gpu.set(x, y+2, "╙─────╜")
  foreground(fill)
  gpu.set(x+2, y+1, "███")
end

-- draw palette selection menu
local function drawPaletteFrame()
  foreground(color.fore)
  background(color.back)
  if FULLSIZE then
    frame(MENUX, 3, WIDTH-2, 16, "[ "..loc.PALETTE_FRAME.." ]", true)
    for i=0, 3 do
      drawRect(MENUX+1+i*colorCursorWidth, 5, hexcolortable[i])
    end
    foreground(0xFF0000); gpu.set(MENUX+1, 10, "R:")
    foreground(0x00FF00); gpu.set(MENUX+1, 11, "G:")
    foreground(0x0000FF); gpu.set(MENUX+1, 12, "B:")
  else
    for i=0, 3 do
      drawSmallRect(MENUX+1+i*colorCursorWidth, 2, hexcolortable[i])
    end
    foreground(0xFF0000); gpu.set(MENUX+1, 5, "R:")
    foreground(0x00FF00); gpu.set(MENUX+11, 5, "G:")
    foreground(0x0000FF); gpu.set(MENUX+21, 5, "B:")
  end
end
-- draw and move palette selector
local function drawColorCursor(force)
  if force or brush.moving then
    foreground(color.fore)
    background(color.back)
    if FULLSIZE then gpu.set(MENUX+2+brush.cx, colorCursorY, "      ")
    else gpu.set(MENUX+2+brush.cx, colorCursorY, "-----") end

    if brush.moving then
      if brush.x ~= brush.color * colorCursorWidth then brush.x = brush.color*colorCursorWidth end
      if brush.cx < brush.x then brush.cx = brush.cx + 1
      elseif brush.cx > brush.x then brush.cx = brush.cx - 1
      else brush.moving = false end
    end

    if FULLSIZE then
      background(color.lightgray)
      gpu.set(MENUX+2+brush.cx, colorCursorY, ":^^^^:")
    else gpu.set(MENUX+2+brush.cx, colorCursorY, ":vvv:") end
  end
end
local function drawLayerFrame()
  foreground(color.fore)
  background(color.back)
  if FULLSIZE then
    frame(MENUX, 16, WIDTH-2, 28, "[ "..loc.VIEWPORT_FRAME.." ]", true)
    gpu.set(MENUX+13, 18, loc.LAYER_LABEL)
    gpu.set(MENUX+1, 23, loc.GHOST_LAYER_LABEL)
  else
    gpu.set(MENUX+1, 8, loc.LAYER_LABEL)
  end
end
local function drawUtilsFrame()
  foreground(color.fore)
  background(color.back)
  frame(MENUX, 28, WIDTH-2, 36, "[ "..loc.UTILS_FRAME.." ]")
end

local function mainScreen()
  foreground(color.fore)
  background(color.back)
  term.clear()
  frame(1,1, WIDTH, HEIGHT, "{ Hologram Editor }", not FULLSIZE)
  -- "canvas"
  drawGrid(GRIDX, GRIDY)

  drawPaletteFrame()
  drawLayerFrame()
  drawUtilsFrame()

  drawColorCursor(true)
  buttonsDraw(buttons)
  textboxesDraw(textboxes)

  -- "about"
  foreground(color.info)
  background(color.gray)
  if FULLSIZE then
    gpu.set(MENUX+3, HEIGHT-11, "   Hologram Editor  v0.7.1   ")
    foreground(color.fore)
    gpu.set(MENUX+3, HEIGHT-10, "            * * *            ")
    gpu.set(MENUX+3, HEIGHT-8,  "  Totoro  (aka MoonlightOwl) ")
    gpu.set(MENUX+3, HEIGHT-7,  "            * * *            ")
    gpu.set(MENUX+3, HEIGHT-5,  "       computercraft.ru      ")
    foreground(color.lightlightgray)
    gpu.set(MENUX+3, HEIGHT-9,  " "..loc.PROGRAMMERS_LABEL..string.rep(' ', 28-unicode.len(loc.PROGRAMMERS_LABEL)))
    gpu.set(MENUX+3, HEIGHT-6,  " "..loc.CONTACT_LABEL..string.rep(' ', 28-unicode.len(loc.CONTACT_LABEL)))
    foreground(color.fore)
    background(color.back)
    gpu.set(MENUX+1, HEIGHT-2, loc.EXIT_LABEL)
  else
    gpu.set(MENUX+1, HEIGHT-2,  "  Totoro  computercraft.ru  ")
    foreground(color.fore)
    background(color.back)
    gpu.set(MENUX+1, HEIGHT, loc.EXIT_LABEL)
  end
end


-- ============================================= M E S S A G E S ============================================= --
local function showMessage(text, caption, textcolor)
  local caption = '[ '..caption..' ]'
  local x = MENUX/2 - unicode.len(text)/2 - 4
  local y = HEIGHT/2 - 2
  foreground(color.fore)
  background(color.back)
  gpu.fill(x, y, unicode.len(text)+9, 5, ' ')
  frame(x, y, x+unicode.len(text)+8, y+4, caption)
  foreground(textcolor)
  gpu.set(x+4,y+2, text)
  -- "canvas" must be rerendered
  repaint = true
end


-- =============================================== L A Y E R S =============================================== --
local function project(x, y, layer, view)
  if view == TOP then
    return x, layer, y
  elseif view == FRONT then
    return x, HOLOH-y+1, layer
  else
    return layer, HOLOH-y+1, x
  end
end
local function getVoxelColor(x, y, z, grid)
  local voxel = get(x, y, z)
  if voxel ~= 0 then return hexcolortable[voxel]
  elseif grid then return color.gray
  else return color.back end
end
local function drawVoxel(sx, sy, nogrid)
  if FULLSIZE then
    local voxel = get(project(sx, sy, layer, view))
    local dx = (GRIDX-2) + sx*2
    local dy = (GRIDY-1) + sy
    if voxel ~= 0 then
      foreground(hexcolortable[voxel])
      gpu.set(dx, dy, "██")
    else
      local ghost = get(project(sx, sy, ghost_layer, view))
      if ghost ~= 0 then
        foreground(darkhexcolors[ghost])
        gpu.set(dx, dy, "░░")
      elseif not nogrid then
        if (sx+sy)%2 == 0 then foreground(color.gray)
        else foreground(color.back) end
        gpu.set(dx, dy, "██")
      end
    end
  else
    local sxUp, syUp = sx, sy
    if syUp%2 == 0 then syUp = syUp-1 end
    local sxDown, syDown = sxUp, syUp + 1
    local dx, dy = (GRIDX-1) + sxUp, (GRIDY-1) + math.ceil(syUp/2)
    local a, b, c = project(sxUp, syUp, layer, view)
    foreground(getVoxelColor(a, b, c, ((sxUp+syUp)%2 == 0)))
    a, b, c = project(sxDown, syDown, layer, view)
    background(getVoxelColor(a, b, c, ((sxDown+syDown)%2 == 0)))
    gpu.set(dx, dy, "▀")
  end
end

function drawLayer()
  drawGrid(GRIDX, GRIDY)
  local step
  if FULLSIZE then step = 1 else step = 2 end
  for x = 1, view.width do
    for y = 1, view.height, step do drawVoxel(x, y, true) end
  end
  -- no need to rerender the screen
  repaint = false
end
local function fillLayer(value)
  local value = value or brush.color
  for x = 1, view.width do
    for y = 1, view.height do
      local vx, vy, vz = project(x, y, layer, view)
      set(vx, vy, vz, value)
    end
  end
  drawLayer()
end
local function clearLayer()
  fillLayer(0)
end


-- ==================================== G U I   F U N C T I O N A L I T Y ==================================== --
local function exit() running = false end

local function nextGhost()
  if ghost_layer_below then
    ghost_layer_below = false
    if ghost_layer < view.depth then
      ghost_layer = layer + 1
    else ghost_layer = view.depth end
    drawLayer()
  else
    if ghost_layer < view.depth then
      ghost_layer = ghost_layer + 1
      drawLayer()
    end
  end
  tb_ghostlayer.value = '>'; tb_ghostlayer:draw()
end
local function prevGhost()
  if not ghost_layer_below then
    ghost_layer_below = true
    if layer > 1 then
      ghost_layer = layer - 1
    else ghost_layer = 1 end
    drawLayer()
  else
    if ghost_layer > 1 then
      ghost_layer = ghost_layer - 1
      drawLayer()
    end
  end
  tb_ghostlayer.value = '<'; tb_ghostlayer:draw()
end
local function setGhostLayer(value)
  local n = tonumber(value)
  if n == nil or n < 1 or n > view.depth then return false end
  ghost_layer = n
  drawLayer()
  return true
end
local function moveGhost()
  if ghost_layer_below then
    if layer > 1 then ghost_layer = layer - 1
    else ghost_layer = 1 end
  else
    if layer < view.depth then ghost_layer = layer + 1
    else ghost_layer = view.depth end
  end
end

local function nextLayer()
  if layer < view.depth then
    layer = layer + 1
    tb_layer.value = layer
    tb_layer:draw()
    moveGhost()
    drawLayer()
  end
end
local function prevLayer()
  if layer > 1 then
    layer = layer - 1
    tb_layer.value = layer
    tb_layer:draw()
    moveGhost()
    drawLayer()
  end
end
local function setLayer(value)
  local n = tonumber(value)
  if n == nil or n < 1 or n > view.depth then return false end
  layer = n
  moveGhost()
  drawLayer()
  tb_layer.value = layer
  tb_layer:draw()
  return true
end

local function setFilename(str)
  return str ~= nil and str ~= '' and unicode.len(str) < 30
end

local function changeColor(rgb, value)
  if value == nil then return false end
  n = tonumber(value)
  if n == nil or n < 0 or n > 255 then return false end
  -- saving data to the table
  colortable[brush.color][rgb] = n
  setHexColor(brush.color, colortable[brush.color][1],
                           colortable[brush.color][2],
                           colortable[brush.color][3])
  -- refresh colors palette
  drawPaletteFrame()
  return true
end
local function changeRed(value) return changeColor(1, value) end
local function changeGreen(value) return changeColor(2, value) end
local function changeBlue(value) return changeColor(3, value) end

local function moveSelector(num)
  if num == 0 and brush.color ~= 0 then
    tb_red.visible = false
    tb_green.visible = false
    tb_blue.visible = false
    background(color.back)
    if FULLSIZE then
      gpu.fill(MENUX+3, 10, 45, 3, ' ')
    else
      gpu.set(MENUX+3, 5, '      ')
      gpu.set(MENUX+13, 5, '      ')
      gpu.set(MENUX+23, 5, '      ')
    end
  elseif num ~= 0 and brush.color == 0 then
    tb_red.visible = true; tb_red:draw()
    tb_green.visible = true; tb_green:draw()
    tb_blue.visible = true; tb_blue:draw()
  end
  brush.color = num
  brush.moving = true
  tb_red.value = colortable[num][1]; tb_red:draw()
  tb_green.value = colortable[num][2]; tb_green:draw()
  tb_blue.value = colortable[num][3]; tb_blue:draw()
end

local function setView(value, norefresh)
  view = value
  if layer > view.depth then layer = view.depth end
  if not norefresh then drawLayer() end
end
local function setTopView(norefresh) setView(TOP, norefresh) end
local function setFrontView() setView(FRONT) end
local function setSideView() setView(SIDE) end

local function drawHologram()
  -- check for a projector availability
  local projector = trytofind('hologram')
  if projector ~= nil then
    local depth = projector.maxDepth()
    -- clean him up
    projector.clear()
    -- send the palette
    if depth == 2 then
      for i=1, 3 do
        projector.setPaletteColor(i, hexcolortable[i])
      end
    else
      projector.setPaletteColor(1, hexcolortable[1])
    end
    -- send the data
    for x=1, HOLOW do
      for y=1, HOLOH do
        for z=1, HOLOW do
          n = get(x,y,z)
          if n ~= 0 then
            if depth == 2 then
              projector.set(x,y,z,n)
            else
              projector.set(x,y,z,1)
            end
          end
        end
      end
    end
  else
    showMessage(loc.PROJECTOR_UNAVAILABLE_MESSAGE, loc.ERROR_CAPTION, color.error)
  end
end

local function newHologram()
  holo = {}
  drawLayer()
end

local function saveHologram()
  local filename = tb_file.value
  if filename ~= loc.FILE_REQUEST then
    -- show a warning
    showMessage(loc.SAVING_MESSAGE, loc.WARNING_CAPTION, color.gold)
    local compressed = true
    -- add our 'brand' file extensions =)
    if string.sub(filename, -3) == '.3d' then compressed = false
    elseif string.sub(filename, -4) ~= '.3dx' then
      filename = filename..'.3dx'
    end
    -- save
    local ok, message = save(filename, compressed)
    if ok then
      showMessage(loc.SAVED_MESSAGE, loc.DONE_CAPTION, color.gold)
    else
      showMessage(message, loc.ERROR_CAPTION, color.error)
    end
  end
end

local function loadHologram()
  local filename = tb_file.value
  if filename ~= loc.FILE_REQUEST then
    -- show a warning
    showMessage(loc.LOADING_MESSAGE, loc.WARNING_CAPTION, color.gold)
    local compressed = nil
    -- add our 'brand' file extensions =)
    if string.sub(filename, -3) == '.3d' then compressed = false
    elseif string.sub(filename, -4) == '.3dx' then compressed = true end
    -- load
    local ok, message = nil, nil
    if compressed ~= nil then
      ok, message = load(filename, compressed)
    else
      -- if no file extension vas specified, try both alternately
      ok, message = load(filename..'.3dx', true)
      if not ok then
        ok, message = load(filename..'.3d', false)
      end
    end
    if ok then
      -- refresh textboxes
      tb_red.value = colortable[brush.color][1]; tb_red:draw()
      tb_green.value = colortable[brush.color][2]; tb_green:draw()
      tb_blue.value = colortable[brush.color][3]; tb_blue:draw()
      -- refresh the palette
      drawPaletteFrame()
      -- reset the viewport
      setTopView(true)
      setLayer(1)
    else
      showMessage(message, loc.ERROR_CAPTION, color.error)
    end
  end
end


-- =========================================== M A I N   C Y C L E =========================================== --
-- initialization
-- check screen resolution; you must have tier 2/3 GPU and tier 3 monitor to work
if HEIGHT < HOLOW/2 then
  error(loc.TOO_LOW_RESOLUTION_ERROR)
elseif HEIGHT < HOLOW+2 then
  com.screen.setPrecise(true)
  if not com.screen.isPrecise() then error(loc.TOO_LOW_SCREEN_TIER) end
  FULLSIZE = false
  MENUX = HOLOW + 2
  color.gray = color.lightgray
  GRIDX = 1
  GRIDY = 2
  BUTTONW = 9
else
  com.screen.setPrecise(false)
  WIDTH = HOLOW*2 + 40
  HEIGHT = HOLOW + 2
end
gpu.setResolution(WIDTH, HEIGHT)
foreground(color.fore)
background(color.back)

-- set default palette
colortable = {{255, 0, 0}, {0, 255, 0}, {0, 102, 255}}
colortable[0] = {0, 0, 0}  -- eraser
for i=0, 3 do setHexColor(i, colortable[i][1], colortable[i][2], colortable[i][3]) end

initGraphics()

-- generate interface
if FULLSIZE then
  buttonNew(buttons, exit, WIDTH-BUTTONW-2, HEIGHT-2, loc.EXIT_BUTTON, color.back, color.error, BUTTONW, true)
  buttonNew(buttons, drawLayer, MENUX+11, 14, loc.REFRESH_BUTTON, color.back, color.gold, BUTTONW)
  buttonNew(buttons, prevLayer, MENUX+1, 19, '-', color.fore, color.info, 5)
  buttonNew(buttons, nextLayer, MENUX+7, 19, '+', color.fore, color.info, 5)
  buttonNew(buttons, setTopView, MENUX+1, 21, loc.TOP_BUTTON, color.fore, color.info, 10)
  buttonNew(buttons, setFrontView, MENUX+12, 21, loc.FRONT_BUTTON, color.fore, color.info, 10)
  buttonNew(buttons, setSideView, MENUX+24, 21, loc.SIDE_BUTTON, color.fore, color.info, 9)

  buttonNew(buttons, prevGhost, MENUX+1, 24, loc.BELOW_BUTTON, color.fore, color.info, 6)
  buttonNew(buttons, nextGhost, MENUX+10, 24, loc.ABOVE_BUTTON, color.fore, color.info, 6)

  buttonNew(buttons, clearLayer, MENUX+1, 26, loc.CLEAR_BUTTON, color.fore, color.info, BUTTONW)
  buttonNew(buttons, fillLayer, MENUX+2+BUTTONW, 26, loc.FILL_BUTTON, color.fore, color.info, BUTTONW)

  buttonNew(buttons, drawHologram, MENUX+9, 30, loc.TO_PROJECTOR, color.back, color.gold, 16)
  buttonNew(buttons, saveHologram, MENUX+1, 33, loc.SAVE_BUTTON, color.fore, color.help, BUTTONW)
  buttonNew(buttons, loadHologram, MENUX+8+BUTTONW, 33, loc.LOAD_BUTTON, color.fore, color.info, BUTTONW)
  buttonNew(buttons, newHologram, MENUX+1, 35, loc.NEW_FILE_BUTTON, color.fore, color.info, BUTTONW)
else
  buttonNew(buttons, exit, WIDTH-BUTTONW-1, HEIGHT, loc.EXIT_BUTTON, color.back, color.error, BUTTONW, true)
  buttonNew(buttons, drawLayer, MENUX+9, 6, loc.REFRESH_BUTTON, color.back, color.gold, BUTTONW)
  buttonNew(buttons, prevLayer, MENUX+1, 9, '-', color.fore, color.info, 5)
  buttonNew(buttons, nextLayer, MENUX+7, 9, '+', color.fore, color.info, 5)
  buttonNew(buttons, setTopView, MENUX+1, 11, loc.TOP_BUTTON, color.fore, color.info, 8)
  buttonNew(buttons, setFrontView, MENUX+10, 12, loc.FRONT_BUTTON, color.fore, color.info, 8)
  buttonNew(buttons, setSideView, MENUX+20, 13, loc.SIDE_BUTTON, color.fore, color.info, 8)

  buttonNew(buttons, clearLayer, MENUX+1, 15, loc.CLEAR_BUTTON, color.fore, color.info, BUTTONW)
  buttonNew(buttons, fillLayer, MENUX+14, 15, loc.FILL_BUTTON, color.fore, color.info, BUTTONW)

  buttonNew(buttons, drawHologram, MENUX+7, 17, loc.TO_PROJECTOR, color.back, color.gold, 16)
  buttonNew(buttons, saveHologram, MENUX+1, 20, loc.SAVE_BUTTON, color.fore, color.help, BUTTONW)
  buttonNew(buttons, loadHologram, MENUX+16, 20, loc.LOAD_BUTTON, color.fore, color.info, BUTTONW)
  buttonNew(buttons, newHologram, MENUX+1, 21, loc.NEW_FILE_BUTTON, color.fore, color.info, BUTTONW)
end

local function isNumber(value)
  return tonumber(value) ~= nil
end
local function correctLayer(value)
  local n = tonumber(value)
  return n ~= nil and n > 0 and n <= view.depth
end

tb_red, tb_green, tb_blue, tb_layer, tb_ghostlayer, tb_file = nil, nil, nil, nil, nil, nil
if FULLSIZE then
  tb_red = textboxNew(textboxes, isNumber, changeRed, MENUX+5, 10, WIDTH-MENUX-7, '255')
  tb_green = textboxNew(textboxes, isNumber, changeGreen, MENUX+5, 11, WIDTH-MENUX-7, '0')
  tb_blue = textboxNew(textboxes, isNumber, changeBlue, MENUX+5, 12, WIDTH-MENUX-7, '0')
  tb_layer = textboxNew(textboxes, correctLayer, setLayer, MENUX+13, 19, WIDTH-MENUX-15, '1')
  tb_ghostlayer = textboxNew(textboxes, correctLayer, setGhostLayer, MENUX+19, 24, WIDTH-MENUX-21, '')
  tb_file = textboxNew(textboxes, function() return true end, setFilename, MENUX+1, 32, WIDTH-MENUX-3, '', loc.FILE_REQUEST)
else
  tb_red = textboxNew(textboxes, isNumber, changeRed, MENUX+3, 5, 6, '255')
  tb_green = textboxNew(textboxes, isNumber, changeGreen, MENUX+13, 5, 6, '0')
  tb_blue = textboxNew(textboxes, isNumber, changeBlue, MENUX+23, 5, 6, '0')
  tb_layer = textboxNew(textboxes, correctLayer, setLayer, MENUX+13, 9, WIDTH-MENUX-14, '1')
  tb_file = textboxNew(textboxes, function() return true end, setFilename, MENUX+1, 19, WIDTH-MENUX-2, '', loc.FILE_REQUEST)
end

mainScreen()
moveSelector(1)

local function delay(active) if active then return 0.02 else return 2.0 end end

while running do
  local name, add, x, y, button = event.pull(delay(brush.moving))

  if name == 'key_down' then
    -- if 'Q' was pressed - the quit app
    if y == keys.EXIT then
      exit()
    elseif y == keys.ERASER then
      moveSelector(0)
    elseif y >= 2 and y <= 4 then
      moveSelector(y - 1)
    elseif y == keys.CLEAR then
      clearLayer()
    end
  elseif name == 'touch' or name == 'drag' then
  -- rerender the screen after message box
    if repaint then drawLayer()
    else
      if name == 'touch' then
        -- check the GUI
        buttonsClick(buttons, math.ceil(x), math.ceil(y))
        textboxesClick(textboxes, math.ceil(x), math.ceil(y))
        -- select a color
        if x > MENUX+1 and x < MENUX+37 then
          if FULLSIZE then
            if y > 4 and y < 8 then
              moveSelector(math.floor((x-MENUX-1)/colorCursorWidth))
            end
          else
            if y > 1 and y < 4 and x < WIDTH-2 then
              moveSelector(math.floor((x-MENUX-1)/colorCursorWidth))
            end
          end
        end
      end

      -- "render"
      local dx, dy
      if FULLSIZE then
        if x >= GRIDX and x < GRIDX + view.width*2 then
          if y >= GRIDY and y < GRIDY + view.height then
            dx, dy = math.floor((x-GRIDX)/2)+1, math.floor(y-GRIDY+1)
          end
        end
      else
        if x >= (GRIDX - 1) and x <= GRIDX + view.width then
          if y >= (GRIDY - 1) and y <= GRIDY + view.height/2 then
            dx, dy = math.floor(x - GRIDX + 2), math.floor((y - GRIDY + 1) * 2) + 1
          end
        end
      end
      if dx ~= nil then
        local a, b, c = project(dx, dy, layer, view)
        if button == 0 then set(a, b, c, brush.color)
        else set(a, b, c, 0) end
        drawVoxel(dx, dy)
      end
    end
  end

  drawColorCursor()
end

-- finalization
foreground(0xFFFFFF)
background(0x000000)
gpu.setResolution(OLDWIDTH, OLDHEIGHT)
term.clear()
