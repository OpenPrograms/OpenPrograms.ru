-- lava runner by electronic_steve. 
local event = require "event"
local com   = require "component"
local term  = require "term"
local gpu   = com.gpu
local config={graphics_mode=1,timer=5,render_radius=5}
local screen={config.render_radius*2+1,config.render_radius+1}
local quad={{1,-1},{1,0},{1,1},{0,1},{-1,1},{-1,0},{-1,-1},{0,-1}}
local mquad={{0,-1},{1,0},{0,1},{-1,0}}
local amquad={{-1,-1},{1,1},{1,-1},{-1,1}}
local old={bg=0,fg=0}
local images={
  [-5]  ={"()","()","()"},
  [-4]  ={"..","..",".."},
  [-3]  ={"░░","░░","░░"},
  [-2]  ={"▓▓","▓▓","▓▓"},
  [-1]  ={"  ","  ","  "},
  [0]   ={"ER","ER","ER"},
  [1]   ={"◀▶","██","██"},
  [2]   ={"◥◤","██","▀▀"},
  [3]   ={"◀█","██"," █"},
  [4]   ={"◥█","██","▀█"},
  [5]   ={"◢◣","██","▄▄"},
  [6]   ={"██","██","██"},
  [7]   ={"◢█","██","▄█"},
  [8]   ={"██","██","██"},
  [9]   ={"█▶","██","█ "},
  [10]  ={"█◤","██","█▀"},
  [11]  ={"██","██","██"},
  [12]  ={"██","██","██"},
  [13]  ={"█◣","██","█▄"},
  [14]  ={"██","██","██"},
  [15]  ={"██","██","██"},
  [16]  ={"██","██","██"},
}

local colors={
  [0]  =0xffffff,
  [-4] =0x222222,
  [-2] =0xff0000,
  [-3] =0xff0000,
  [-5] =0xffffff,
  [-6] =0xff0000,
}

for i=1,16 do 
  colors[i]=0x222222
end

local keys={
  --[[A]]   [30]=function() move(4) end,
  --[[W]]   [17]=function() move(1) end,
  --[[D]]   [32]=function() move(2) end,
  --[[S]]   [31]=function() move(3) end,
  --[[TAB]] [15]=function() config.graphics_mode=looper(1,config.graphics_mode+1,3) end,
}

event.shouldInterrupt = function()  return false end
gpu.setResolution(config.render_radius*4+2,config.render_radius*2+1)
term.clear()

function move(id)
  local lx,ly=map.player.x+mquad[id][1],map.player.y+mquad[id][2] local tile=map:get(lx,ly) if tile.type==-1 then map.player.x=lx map.player.y=ly end map:lava_update()
end

function looper(min,n,max) 
  if n>max then n=n%max end
  if n<min then n=(n-min)%max+min end
  local J=math.abs(math.modf((n-min)/max))
  return n,J
end


-- карта.
local empty_tile={type="none"}
local map_meta={
  generate=function(self,size,N)
    self.player.level=self.player.level+1
    self.timer=config.timer
    self.tiles={}
    size=size or 10
    N=N or 3
    for X=1,N do 
      local x,y=0,0
      for Y=1,size do
        p={}
        for i=1,4 do 
          local t=self:get(x+mquad[i][1],y+mquad[i][2]).type
          if t=="none" or t==-1  then table.insert(p,i) end
        end 
        if #p>0 then
        local id = math.random(1,#p)
          x=x+mquad[id][1]
          y=y+mquad[id][2]
          self.player.x=x
          self.player.y=y
          self:set(x,y,{type=-1})
        end
      end
    end
    for _,i in pairs(self:get_all(-1)) do
      local x,y,tile=i[1],i[2],i[3]
      for i=1,8 do 
        local X,Y=x+quad[i][1],y+quad[i][2]
        if self:get(X,Y).type=="none"  then self:set(X,Y,{type=0}) end
      end
    end
    for _,i in pairs(self:get_all(0)) do 
      local x,y,tile=i[1],i[2],i[3]
      local imgid=1
      for i=1,4 do 
        local X,Y=x+mquad[i][1],y+mquad[i][2]
        if self:get(X,Y).type==0 then 
          imgid=imgid+2^(i-1)
        end
      end

      self:get(x,y).alt_type=imgid
    end
    local winer={0,0,0}
    for _,i in pairs(self:get_all(-1)) do 
      local x,y,tile=i[1],i[2],i[3]
      local dist=math.sqrt((self.player.x-x)^2+(self.player.y-y)^2)^0.5
      if winer[1]<dist then winer={dist,x,y} end
    end
    self:set(winer[2],winer[3],{type=-1,alt_type=-5})
  end,
  set=function(self,x,y,tile)
    if self.tiles[x] then self.tiles[x][y]=tile else self.tiles[x]={[y]=tile} end
  end,
  get=function(self,x,y)
    if self.tiles[x] then return self.tiles[x][y] or empty_tile else return empty_tile end
  end,
  get_all=function(self,filt)
    local out={}
    for x,tbl in pairs(self.tiles) do 
      for y,tile in pairs(tbl) do 
        if filt then 
          if tile.type==filt then
            table.insert(out,{x,y,tile})
          end
        else 
          table.insert(out,{x,y,tile})
        end
      end
    end
    return out
  end,
  lava_update=function(self)
    if self.timer==0 then self:set(self.tx,self.ty,{type=-3}) elseif self.timer==config.timer then self.tx,self.ty=self.player.x,self.player.y end
    if self.timer~=-1 then self.timer=self.timer-1 end
    for _,body in pairs(self:get_all(-3)) do 
      for i=1,4 do 
        local x,y=body[1]+mquad[i][1],body[2]+mquad[i][2]
        local tile=self:get(x,y)
        if tile.type==-1 then self:set(x,y,{type=-3}) else if tile.type~=-3 then tile.bg=colors[-6] self:set(x,y,tile) end end
      end
      self:set(body[1],body[2],{type=-2})
    end
    if self:get(self.player.x,self.player.y).type==-3 then gpu.setResolution(gpu.maxResolution()) term.clear() print("ты сгорел в лаве на "..self.player.level.." уровне пещер.")  os.exit() end
  end,
  update=function(self)
    if  self:get(self.player.x,self.player.y).alt_type==-5 then 
      self.player.x,self.player.y=nil,nil
      local p=self.player
      self:generate(5*(math.min(self.player.level,5)),math.min(self.player.level,3)*2)
      self.player=p
      self:draw()
    end
    local tile=self:get(self.player.x,self.player.y)
    if tile.type==-1 then tile.alt_type=-4 self:set(self.player.x,self.player.y,tile) end
    _,_,_,code=event.pull("key_down")
    if code==16 then gpu.setResolution(gpu.maxResolution()) term.clear() print("ты вышел на "..self.player.level.." уровне  пещер.")  os.exit() else if keys[code] then keys[code]() end end
  end,
  draw=function(self,ox,oy)
    term.clear()
    for rx=-config.render_radius,config.render_radius do 
      for ry=-config.render_radius,config.render_radius do 
        local X,Y=map.player.x+rx,map.player.y+ry
        local dx,dy=rx*2+screen[1],ry+screen[2]
        local tile=map:get(X,Y)
        if tile.type~="none" then
          if tile.bg then setbg(tile.bg) end
          if tile.alt_type then
            if colors[tile.alt_type] then setfg(colors[tile.alt_type]) end
            gpu.set(dx,dy,images[tile.alt_type][config.graphics_mode])
          else
            if colors[tile.type] then setfg(colors[tile.type]) end
            gpu.set(dx,dy,images[tile.type][config.graphics_mode])
          end
          setbg(0)
        end
      end
    end
    gpu.setForeground(0xff0000) 
    gpu.set(screen[1],screen[2],"@@")
    gpu.setForeground(0xFFFFFF) 
    old.fg=0xFFFFFF
  end,
  delete=function(self,x,y)
    self.tiles[x][y]=nil
  end,
  delete_all=function(self,filt)
    for x,tbl in pairs(self) do 
      for y,tile in pairs(tbl) do 
        if filt then 
          if tile.type==filt then
            self.tiles[x][y]=nil
          end
        else 
          self.tiles[x][y]=nil
        end
      end
    end
  end
} map_meta.__index=map_meta
function setfg(x)
  if x~=old.fg then gpu.setForeground(x) old.fg=x end
end
function setbg(x)
  if x~=old.bg then gpu.setBackground(x) old.bg=x end
end
function create_map(size,N)
  local map=setmetatable({tiles={},player={level=0,r=5,x=0,y=0},timer=config.timer,tx=0,ty=0},map_meta)
  map:generate(size,N)
  return map
end 

map=create_map(5,4)
while true do
  os.sleep(0)
  map:draw() map:update()
end
