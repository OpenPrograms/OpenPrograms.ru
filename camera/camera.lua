local component = require('component')
local term = require('term')
local event = require('event')
local camera = component.camera
local gpu = component.gpu

local tDiamondZ = {
  {0.04, 1},
  {0.036, 0.9},
  {0.032, 0.8},
  {0.028, 0.7},
  {0.024, 0.6},
  {0.02, 0.5},
  {0.016, 0.4},
  {0.012, 0.3},
  {0.008, 0.2},
  {0.004, 0.1}
}

local tGoldZ = {
  {0.08, 1},
  {0.072, 0.9},
  {0.064, 0.8},
  {0.056, 0.7},
  {0.48, 0.6},
  {0.04, 0.5},
  {0.032, 0.4},
  {0.024, 0.3},
  {0.016, 0.2},
  {0.008, 0.1}
}

local color_gray = {
  0x000000,
  0x111111,
  0x222222,
  0x333333,
  0x444444,
  0x555555,
  0x666666,
  0x777777,
  0x888888,
  0x999999,
  0xAAAAAA,
  0xBBBBBB,
  0xCCCCCC,
  0xDDDDDD,
  0xEEEEEE,
  0xFFFFFF
}

local color_gold = {
  0x000000,
  0x0000FF,
  0x00AAAA,
  0x00FFFF,
  0x008800,
  0x00FF00,
  0xFFFF00,
  0xAAAA00,
  0xFF0000
}

local color_rainbow = {
  0x000000,
  0x000040,
  0x000080,
  0x002480,
  0x0000BF,
  0x0024BF,
  0x002400,
  0x004900,
  0x006D00,
  0x009200,
  0x00B600,
  0x33DB00,
  0x99FF00,
  0xCCFF00,
  0xFFDB00,
  0xFFB600,
  0xFF9200,
  0xFF6D00,
  0xFF4900,
  0xFF2400,
  0xFF0000
}

function render(size, zoom, color, side)
  local tbl = {}
  if side == 'up' then
    look = camera.distanceUp
  elseif side == 'down' then
    look = camera.distanceDown
  else
    look = camera.distance
  end
  term.clear()
  term.setCursor(1,1)
  local yp = 1
  local colorLen = #color
  for j = -zoom, zoom, size do
    for i = zoom, -zoom, -size do
      local d = look(i, 0-j)
      local a = 1
      if d>0 then
        a = 2+((colorLen-1)-math.min(colorLen-1, (d/1.2)))
      end
      gpu.setForeground(color[math.floor(a)])
      term.write('██')
    end
    yp=yp+1
    term.setCursor(1,yp)
  end
end

fgrnd = gpu.getForeground()
xres, yres = gpu.getResolution()
term.clear()

print('Usage:\n[z] - zoom in\n[c] - zoom out\n[backspace] - reset zoom\n[x] - switch to the advanced graphics mode\n (correctly works only on T3 screen and graphics card)\n[q] - quit\nPresss any key to continue.')

if gpu.maxResolution() == 160 then
  clr = color_gray
  zoom = tDiamondZ
  gpu.setResolution(99, 50)
elseif gpu.maxResolution() == 80 then
  clr = color_gold
  zoom = tGoldZ
  gpu.setResolution(52, 26)
else
  print('Используемое устройство вывода не поддерживается.')
  os.exit()
end

local zm = 1
while true do
  _, _ , _, code, _, _ = event.pull('key_down')
  if code == 44 then
    zm = zm+1
    if zm > #zoom then
      zm = 1
    end
  elseif code == 46 then
    zm = zm-1
    if zm < 1 then
      zm = 1
    end
  elseif code == 45 then
    clr = color_rainbow
  elseif code == 14 then
    zm = 1
  elseif code == 16 then
    gpu.setForeground(fgrnd)
    gpu.setResolution(xres, yres)
    term.clear()
    os.exit()
  end
  render(zoom[zm][1], zoom[zm][2], clr)
end
