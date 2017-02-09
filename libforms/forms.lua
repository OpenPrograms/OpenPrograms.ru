local gpu=require("component").gpu
local isPrimary=require("component").isPrimary
local event=require("event")
local len=require("unicode").len
local sub=require("unicode").sub
local uchar=require("unicode").char
local term=require("term")
local pushSignal=require("computer").pushSignal
local kbd  = require("component").keyboard
local wrap = require("text").wrap
local padRight=require("text").padRight
local isControl= require("keyboard").isControl

local forms={}
local mouseEv={touch=true, scroll=true, drag=true, drop=true}
local activeForm

local TComponent={left=1,top=1, color=0, fontColor=0xffffff, border=0, visible=true, tag=0, type=function() return "unknown" end}
TComponent.__index=TComponent

function TComponent:paint() end

function TComponent:isVisible()
  if not self.visible then return false end
  if self.parent then return self.parent:isVisible()
  else return self==activeForm
  end
end

function TComponent:draw()
  if self.parent then self.X=self.parent.X+self.left-1 self.Y=self.parent.Y+self.top-1
  else self.X=self.left self.Y=self.top end
  gpu.setBackground(self.color)
  gpu.setForeground(self.fontColor)
  local brd=nil
  if self.border==1 then brd={"┌","─","┐","└","│","┘"}
  elseif self.border==2 then brd={"╔","═","╗","╚","║","╝"}
  end
  if brd then
    gpu.set(self.X,self.Y, brd[1]..string.rep(brd[2],self.W-2)..brd[3])
    for i=self.Y+1,self.Y+self.H-2 do
      gpu.set(self.X,i, brd[5]..string.rep(" ",self.W-2)..brd[5])
    end
    gpu.set(self.X,self.Y+self.H-1, brd[4]..string.rep(brd[2],self.W-2)..brd[6])
  else gpu.fill(self.X,self.Y,self.W,self.H," ") end
  self:paint()
  if self.elements then
    for i=1,#self.elements do
      if self.elements[i].visible then self.elements[i]:draw() end
    end
  end
end

function TComponent:redraw() if self:isVisible() then self:draw() end end

function TComponent:makeChild(el)
  if not self.elements then self.elements={} end
  el.parent=self
  table.insert(self.elements,el)
end

function TComponent:mouseEv(ev,x,y,btn,user)
  if self.elements then
    for i=#self.elements,1,-1 do
      local e=self.elements[i]
      if e.visible and e.X and x>=e.X and x<e.X+e.W and y>=e.Y and y<e.Y+e.H then
        e:mouseEv(ev,x,y,btn,user)
        return
      end
    end
  end
  if self[ev] then self[ev](self, x-self.X+1,y-self.Y+1,btn,user) end
end

function TComponent:hide()
  if self.parent then
    self.visible=false
    self.parent:draw()
  else
    gpu.setBackground(0)
    gpu.fill(self.X,self.Y,self.W,self.H," ")
  end
end

function TComponent:show()
  if self.parent then
    self.visible=true
    self.parent:draw()
  else
    self:draw()
  end
end

function TComponent:destruct()
  if self.parent then
    for i=1,#self.parent.elements do
      if self.parent.elements[i]==self then table.remove(self.parent.elements,i) break end
    end
  end
end

function forms.activeForm() return activeForm end

------------------Form------------------
local TForm=setmetatable({type=function() return "Form" end},TComponent)
TForm.__index=TForm

function TForm:isActive() return self==activeForm end

function TForm:setActive()
  if activeForm~=self then
    activeForm=self
    self:show()
  end
end

function forms.addForm()
  local obj={}
  TForm.W, TForm.H=gpu.getResolution()
  return setmetatable(obj,TForm)
end

------------------Button----------------
local TButton=setmetatable({W=10, H=1, color=0x606060, type=function() return "Button" end},TComponent)
TButton.__index=TButton

function TButton:touch(x, y, btn, user)
  if self.onClick and btn==0 then self:onClick(user) end
end

function TButton:paint()
  gpu.set(self.X+(self.W-len(self.caption))/2,self.Y+(self.H-1)/2, self.caption)
end

function TComponent:addButton(left, top, caption, onClick)
  local obj={left=left, top=top, caption=caption or "Button", onClick=onClick}
  self:makeChild(obj)
  return setmetatable(obj,TButton)
end

------------------Label-----------------
local TLabel=setmetatable({H=1, centered=false, alignRight=false, autoSize=true, type=function() return "Label" end} ,TComponent)
TLabel.__index=TLabel

function TLabel:paint()
 local line
 local value=tostring(self.caption)
 if self.autoSize then
   self.W,self.H=0,0
   for line in value:gmatch("([^\n]+)") do
     self.H=self.H+1
     if len(line)>self.W then self.W=len(line) end
   end
   if self.W<1 then self.W=1 end
   if self.H<1 then self.H=1 end
 end
 for i=0,self.H-1 do
  if not value then break end
  line, value = wrap(value, self.W, self.W)
  if self.centered then gpu.set(self.X+(self.W-len(line))/2,self.Y+i, line)
  else
    if self.alignRight then gpu.set(self.X+self.W-len(line),self.Y+i, line)
    else gpu.set(self.X,self.Y+i, line) end
  end
 end
end

function TComponent:addLabel(left, top, caption)
  local obj={left=left, top=top, caption=caption or "Label"}
  obj.W=len(obj.caption)
  self:makeChild(obj)
  return setmetatable(obj,TLabel)
end

------------------Edit------------------
local TEdit=setmetatable({W=20, H=3, text="", border=1, type=function() return "Edit" end},TComponent)
TEdit.__index=TEdit

function TEdit:paint()
  if type(self.text)=="table" then
    for i=1,self.H-2 do gpu.set(self.X+1,self.Y+i,sub(self.text[i] or "",1,self.W-2)) end
  else gpu.set(self.X+1,self.Y+1, sub(self.text,1,self.W-2))
  end
end

local function editText(text,left,top,W,H)
local running=true
local scrollX, scrollY = 0, 0
local posX, posY =1, 1
local writeText

local function setCursor(nx,ny)
  posX=nx or posX
  posY=ny or posY
  if #text<1 then text[1]="" end
  if posY>#text then posY=#text end
  if posY<1 then posY=1 end
  if posX>len(text[posY])+1 then posX=len(text[posY])+1 end
  if posX<1 then posX=1 end
  local redraw=false
  if posY<=scrollY then scrollY=posY-1 redraw=true end
  if posY>scrollY+H then scrollY=posY-H redraw=true end
  if posX<=scrollX then scrollX=posX-1 redraw=true end
  if posX>scrollX+W then scrollX=posX-W redraw=true end
  if redraw then writeText()
  else term.setCursor(left+posX-scrollX-1, top+posY-scrollY-1) end
end

local function writeLine(n)
  gpu.set(left,top+n-scrollY-1,padRight(sub(text[n] or "",scrollX+1,scrollX+W),W))
end

function writeText()
  for i=1,H do writeLine(i+scrollY) end
  setCursor()
end

local function insert(value)
  if not value or len(value) < 1 then return end
  text[posY]=sub(text[posY],1,posX-1)..value..sub(text[posY],posX)
  writeLine(posY)
  setCursor(posX+len(value))
end

local keys={}
keys[203]=function()    -- Left
  if posX>1 then setCursor(posX-1)
  else if posY>1 then posY=posY-1 setCursor(len(text[posY])+1) end
  end
end
keys[205]=function()   -- Right
  if posX<=len(text[posY]) then setCursor(posX+1)
  else if posY<#text then setCursor(1,posY+1) end
  end
end
keys[199]=function() setCursor(1) end   -- Home
keys[207]=function() setCursor(len(text[posY])+1) end   -- End
keys[211]=function()    -- Del
  if posX<=len(text[posY]) then
    text[posY]=sub(text[posY],1,posX-1)..sub(text[posY],posX+1)
    writeLine(posY)
  else
    if posY<#text then
      text[posY]=text[posY]..text[posY+1]
      table.remove(text,posY+1)
      writeText()
    end
  end
end
keys[14] =function()    -- BackSp
  if posX>1 then
    text[posY]=sub(text[posY],1,posX-2)..sub(text[posY],posX)
    writeLine(posY)
    setCursor(posX-1)
  else
    if posY>1 then
      posX,posY,text[posY-1]=len(text[posY-1])+1,posY-1,text[posY-1]..text[posY]
      table.remove(text,posY+1)
      writeText()
    end
  end
end
keys[15] =function() insert("  ") end   -- Tab

local function onKeyDown(char, code)
  if keys[code] then keys[code]()
  else if not isControl(char) then insert(uchar(char)) end
  end
end

local function onClipboard(value)
end

local function onClick(x,y)
  if x>=left and x<left+W and y>=top and y<top+H then
    setCursor(x+scrollX-left+1,y+scrollY-top+1)
  else running=false
  end
end

local function onScroll(direction)
end

if type(text)=="table" then
  keys[68] =function() running=false end   -- F10
  keys[200]=function() setCursor(posX,posY-1) end   -- Up
  keys[208]=function() setCursor(posX,posY+1) end   -- Down
  keys[28] =function()   -- Enter
    local n=len(text[posY]:match("^%s*"))
    table.insert(text,posY+1,string.rep(" ",n)..sub(text[posY],posX))
    text[posY]=sub(text[posY],1,posX-1)
    posX,posY=n+1,posY+1
    writeText()
  end
else
  posX=len(text)+1
  text={tostring(text)}
  keys[28] =function() running=false end   -- Enter
end
term.setCursorBlink(true)
writeText()
local event, address, arg1, arg2, arg3
while running do
  event, address, arg1, arg2, arg3 = term.pull()
  if type(address) == "string" and isPrimary(address) then
    term.setCursorBlink(false)
    if event == "key_down" then onKeyDown(arg1, arg2)
    elseif event == "clipboard" then onClipboard(arg1)
    elseif event == "touch" or event == "drag" then onClick(arg1, arg2)
    elseif event == "scroll" then onScroll(arg3)
    end
    term.setCursorBlink(true)
  end
end
if event=="touch" then pushSignal( event, address, arg1, arg2, arg3 ) end
term.setCursorBlink(false)
return text[1]
end

function TEdit:touch(x, y, btn, user)
  if btn==0 then
    gpu.setBackground(self.color)
    gpu.setForeground(self.fontColor)
    if type(self.text)=="table" then editText(self.text,self.X+1,self.Y+1,self.W-2,self.H-2)
    else self.text=editText(self.text,self.X+1,self.Y+1,self.W-2,1)    end
    self:draw()
    if self.onEnter then self:onEnter(user) end
  end
end

function TComponent:addEdit(left, top, onEnter)
  local obj={left=left, top=top, onEnter=onEnter}
  self:makeChild(obj)
  return setmetatable(obj,TEdit)
end

------------------Frame-----------------
local TFrame=setmetatable({W=20, H=10, border=1, type=function() return "Frame" end},TComponent)
TFrame.__index=TFrame

function TComponent:addFrame(left, top, border)
  local obj={left=left, top=top, border=border}
  self:makeChild(obj)
  return setmetatable(obj,TFrame)
end

------------------List------------------
local TList=setmetatable({W=20, H=10, border=2, selColor=0x0000ff, sfColor=0xffff00, shift=0, index=0,
  type=function() return "List" end},TComponent)
TList.__index=TList

function TList:paint()
  local b= self.border==0 and 0 or 1
  for i=1,self.H-2*b do
    if i+self.shift==self.index then gpu.setForeground(self.sfColor) gpu.setBackground(self.selColor) end
    gpu.set(self.X+b,self.Y+i+b-1, padRight(sub(self.lines[i+self.shift] or "",1,self.W-2*b),self.W-2*b))
    if i+self.shift==self.index then gpu.setForeground(self.fontColor) gpu.setBackground(self.color) end
  end
end

function TList:clear()
  self.shift=0 self.index=0 self.lines={} self.items={}
  self:redraw()
end

function TList:insert(pos,line,item)
  if type(pos)~="number" then pos,line,item=#self.lines+1,pos,line end
  table.insert(self.lines,pos,line)
  table.insert(self.items,pos,item or false)
  if self.index<1 then self.index=1 end
  if pos<self.shift+self.H-1 then self:redraw() end
end

function TList:sort(comp)
  comp=comp or function(list,i,j) return list.lines[j]<list.lines[i] end
  for i=1,#self.lines-1 do
    for j=i+1,#self.lines do
      if comp(self,i,j) then
        if self.index==i then self.index=j
        elseif self.index==j then self.index=i end
        self.lines[i],self.lines[j]=self.lines[j],self.lines[i]
        self.items[i],self.items[j]=self.items[j],self.items[i]
      end
    end
  end
  self:redraw()
end

function TList:touch(x, y, btn, user)
  local b= self.border==0 and 0 or 1
  if x>b and x<=self.W-b and y>b and y<=self.H-b and btn==0 then
    local i=self.shift+y-b
    if self.index~=i and self.lines[i] then
      self.index=i
      self:redraw()
      if self.onChange then self:onChange(self.lines[i],self.items[i],user) end
    end
  end
end

function TList:scroll(x, y, sh, user)
  local b= self.border==0 and 0 or 1
  self.shift=self.shift-sh
  if self.shift>#(self.lines)-self.H+2*b then self.shift=#(self.lines)-self.H+2*b end
  if self.shift<0 then self.shift=0 end
  self:redraw()
end

function TComponent:addList(left, top, onChange)
  local obj={left=left, top=top, lines={}, items={}, onChange=onChange}
  self:makeChild(obj)
  return setmetatable(obj,TList)
end

local work
local TInvisible=setmetatable({W=10, H=3, border=2, draw=function() end},TComponent)
TInvisible.__index=TInvisible
------------------Event-----------------
local TEvent=setmetatable({type=function() return "Event" end},TInvisible)
TEvent.__index=TEvent

function TEvent:run()
  if self.onEvent then forms.listen(self.eventName, self.onEvent) end
end

function TEvent:stop()
  forms.ignore(self.eventName, self.onEvent)
end

function TComponent:addEvent(eventName, onEvent)
  local obj={eventName=eventName, onEvent=onEvent}
  self:makeChild(obj)
  setmetatable(obj,TEvent)
  obj:run()
  return obj
end

------------------Timer-----------------
local TTimer=setmetatable({Enabled=true, type=function() return "Timer" end},TInvisible)
TTimer.__index=TTimer

function TTimer:run()
  self.Enabled=nil
  if self.onTime then
    self.timerId=event.timer(self.interval,
    function ()
      if self.Enabled and work then
        self.onTime(self)
      else
        self:stop()
      end
    end,
    math.huge
    )
  end
end
function TTimer:stop()
  self.Enabled=false
  event.cancel(self.timerId)
end

function TComponent:addTimer(interval, onTime)
  local obj={interval=interval, onTime=onTime}
  self:makeChild(obj)
  setmetatable(obj,TTimer)
  obj:run()
  return obj
end

local listeners={}

function forms.listen(name, callback)
  checkArg(1, name, "string")
  checkArg(2, callback, "function")
  if listeners[name] then
    for i = 1, #listeners[name] do
      if listeners[name][i] == callback then
        return false
      end
    end
  else
    listeners[name] = {}
  end
  table.insert(listeners[name], callback)
  return true
end

function forms.ignore(name, callback)
  checkArg(1, name, "string")
  checkArg(2, callback, "function")
  if listeners[name] then
    for i = 1, #listeners[name] do
      if listeners[name][i] == callback then
        table.remove(listeners[name], i)
        if #listeners[name] == 0 then
          listeners[name] = nil
        end
        return true
      end
    end
  end
  return false
end

function forms.ignoreAll()
  listeners={}
end
----------------------------------------

function forms.run(form)
  work=true
  local Fc, Bc = gpu.getForeground(), gpu.getBackground()
  activeForm=form
  activeForm:draw()
  while work do
    local ev,adr,x,y,btn,user=event.pull()
    if mouseEv[ev] and adr==gpu.getScreen() then activeForm:mouseEv(ev,x,y,btn,user) end
    if listeners[ev] then
      for i=1,#listeners[ev] do listeners[ev][i](ev,adr,x,y,btn,user) end
    end
    if listeners[""] then
      for i=1,#listeners[""] do listeners[""][i](ev,adr,x,y,btn,user) end
    end
  end
  gpu.setForeground(Fc)
  gpu.setBackground(Bc)
  forms.ignoreAll()
end

function forms.stop()
  work=false
end

return forms
