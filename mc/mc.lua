--[[      Midday Commander Color Ver. 1.8 ]]--
--[[ Created by Zer0Galaxy & Neo & Totoro ]]--
--[[              (c)  No rights reserved ]]--

local unicode = require('unicode')
local len=unicode.len
local sub=unicode.sub
local fs = require('filesystem')
local term = require('term')
local shell = require('shell')
local event = require('event')
local com = require('component')
local gpu = com.gpu
local keyboard = require('keyboard')

local colors = {
  white = 0xFFFFFF,
  black = 0x000000,
  blue  = 0x0060A0,
  green = 0x336600,
  orange= 0xffcc33,
  red   = 0xee3b3b
}
local keys = keyboard.keys
local Left,Rght,Active,Find
local wScr, hScr = gpu.maxResolution()
if wScr>80 then wScr,hScr=80,25 end
local cmd, scr, Menu
local NormalCl, PanelCl, DirCl, SelectCl, WindowCl, AlarmWinCl
local xMenu,cmdstr,curpos,work=-1,'',0,true
local Shift,Ctrl,Alt=256,512,1024

local function SetColor(cl)
  gpu.setForeground(cl[1])
  gpu.setBackground(cl[2])
end

local function saveScreen()
  scr={cl={}}
  scr.W,scr.H = gpu.getResolution()
  scr.cl[1]=gpu.getForeground()
  scr.cl[2]=gpu.getBackground()
  scr.posX, scr.posY = term.getCursor()
  for i=1,scr.H do
    scr[i]={}
    local FC,BC
    for j=1,scr.W do
      local c,fc,bc=gpu.get(j,i)
      if fc==FC then fc=nil end
      if bc==BC then bc=nil end
      if fc or bc then
          table.insert(scr[i],{fc=fc,bc=bc,c=""})
        FC,BC=fc or FC, bc or BC
      end
      scr[i][#scr[i]].c=scr[i][#scr[i]].c .. c
    end
  end
  gpu.setResolution(wScr,hScr)
end

local function loadScreen()
  gpu.setResolution(scr.W,scr.H)
  term.setCursorBlink(false)
  for i=1,scr.H do
    local curX=1
    for j=1,#scr[i] do
      if scr[i][j].fc then gpu.setForeground(scr[i][j].fc) end
      if scr[i][j].bc then gpu.setBackground(scr[i][j].bc) end
      gpu.set(curX,i,scr[i][j].c) curX=curX+len(scr[i][j].c)
    end
  end
  SetColor(scr.cl)
  term.setCursor(scr.posX,scr.posY)
  term.setCursorBlink(true)
end

local function ShowCmd()
  SetColor(NormalCl)
  term.setCursor(1, hScr-1)
  term.clearLine()
  term.write(shell.getWorkingDirectory()..'> '..cmdstr)
  term.setCursor(term.getCursor()-curpos, hScr-1)
end

local panel ={wPan=math.ceil(wScr / 2)}
function panel:ShowFirst()
  local p=self.Path..'/'
  if len(p)> self.wPan-6 then p='..'..sub(p,-self.wPan+7) end
  p=' '..p..' '
  gpu.set(self.X, 1,'┌'..string.rep('─',self.wPan-2)..'┐')
  term.setCursor(self.X+(self.wPan-len(p))/2,1)
  if self==Active then
    SetColor(SelectCl)
    term.write(p)
    SetColor(PanelCl)
  else
    term.write(p)
  end
end

function panel:ShowLine(Line)
  term.setCursor(self.X, Line-self.Shift+2)
  term.write('│')
  if self.tFiles[Line]~=nil then
    local Name=self.tFiles[Line]
    if self.tSize[Line]=='DIR' then Name='/'..Name SetColor(DirCl) end
    if len(Name)>self.wPan-4 then Name=sub(Name,1,self.wPan-6)..'..' end
    Name=' '..Name..string.rep(' ',self.wPan-len(Name)-4)..' '
    if self==Active and Line==self.CurLine then SetColor(SelectCl) end
    term.write(Name)
  else
    term.write(string.rep(' ',self.wPan-2))
  end
  SetColor(PanelCl)
  term.write('│')
end

function panel:ShowLines()
  for i=self.Shift, self.Shift+hScr-5 do self:ShowLine(i) end
end

function panel:ShowLast()
  gpu.set(self.X, hScr-2,'└'..string.rep('─',self.wPan-2)..'┘')
  gpu.set(self.X+2, hScr-2, self.tSize[self.CurLine])
end

function panel:Show()
  if self.CurLine>#self.tFiles then self.CurLine=#self.tFiles end
  SetColor(PanelCl)
  self:ShowFirst()
  self:ShowLines()
  self:ShowLast()
end

function panel:GetFiles()
  local Files={}
  for name in fs.list(self.Path) do
    table.insert(Files, name)
  end
  if self.Path=='' then
    self.tFiles={}
    self.tSize={}
  else
    self.tFiles={'..'}
    self.tSize={'DIR'}
  end
  for n,Item in pairs(Files) do
    if Item:sub(-1) == '/' then
      table.insert(self.tFiles,Item)
      table.insert(self.tSize,'DIR')
    end
  end
  for n,Item in pairs(Files) do
    if Item:sub(-1) ~= '/' then
      local sPath=fs.concat(self.Path,Item)
      table.insert(self.tFiles,Item)
      table.insert(self.tSize,fs.size(sPath).." b")
    end
  end
  self:Show()
end

function panel:SetPos(FileName)
  if fs.isDirectory(FileName) then FileName=FileName..'/' end
  self.Path,FileName=FileName:match('(.-)/?([^/]+/?)$')
  shell.setWorkingDirectory(self.Path)
  self.CurLine=1
  self.Shift=1
  self:GetFiles()
  for i=1,#self.tFiles do
    if self.tFiles[i]==FileName then
      self.CurLine=i
      break
    end
  end
  if Active.CurLine>hScr-4 then
    Active.Shift=Active.CurLine-hScr+6
  end
end

function panel:new(x,path)
  local obj={X = x, Path =path, tFiles={}, tSize={}, CurLine=1, Shift=1}
  return setmetatable(obj,{__index=panel})
end

local Fpanel ={wPan=wScr}
setmetatable(Fpanel,{__index=panel})

function Fpanel:new(x,path)
  local obj=panel:new(x,path)
  return setmetatable(obj,{__index=Fpanel})
end

local function FindFile(FileName,Path)
  local Result={}
  local SubDir={}
  for name in fs.list(Path) do
    if string.sub(name, -1) == '/' then
      table.insert(SubDir, Path..name)
      name=name..".."
    end
    if string.match(name, FileName) then
      table.insert(Result, Path..name)
    end
  end
  for i=1,#SubDir do
    local Files = FindFile(FileName,SubDir[i])
    for j=1,#Files do table.insert(Result,Files[j]) end
  end
  return Result
end

function Fpanel:GetFiles()
  local code={{'%.','%%.'},{'*','.-'},{'?','.'}}
  local Templ=self.Path
  for i=1,#code do Templ=Templ:gsub(code[i][1],code[i][2]) end
  self.tFiles=FindFile('^'..Templ..'$','')
  table.insert(self.tFiles,1,'..')
  self.tSize={'DIR'}
  for i=2,#self.tFiles do
    if fs.isDirectory(self.tFiles[i]) then
      self.tSize[i]='DIR'
    else
      self.tSize[i]=tostring(fs.size(self.tFiles[i]))
    end
  end
  self:Show()
end

function Fpanel:ShowFirst()
  local p='Find:'..self.Path
  if len(p)> self.wPan-6 then p='..'..sub(p,-self.wPan+7) end
  p=' '..p..' '
  gpu.set(self.X, 1,'┌'..string.rep('─',self.wPan-2)..'┐')
  SetColor(SelectCl)
  gpu.set(self.X+(self.wPan-len(p))/2,1,p)
  SetColor(PanelCl)
end

local function ShowPanels()
  SetColor(NormalCl)
  term.clear()
  if Active==Find then
    Find:Show()
  else
    Left:GetFiles()
    Rght:GetFiles()
  end
  term.setCursor(xMenu, hScr)
  for i=1,#Menu do
    if #Menu[i]>0 then
      SetColor(NormalCl)
      term.write(' F'..i)
      SetColor(SelectCl)
      term.write(Menu[i])
    end
  end
  term.setCursorBlink(true)
end

local function Dialog(cl,Lines,Str,But)
  SetColor(cl)
  local H=#Lines+3
  local CurBut=1
  if Str then H=H+1 CurBut=0 end
  if not But then But={'Ok'} end
  local function Buttons()
    local Butt=''
    for i=1,#But do
      if i==CurBut then
        Butt=Butt..'['..But[i]..']'
      else
        Butt=Butt..' '..But[i]..' '
      end
    end
    return Butt
  end
  local W=len(Buttons())
  for i=1,#Lines do
    if len(Lines[i])>W then W=len(Lines[i]) end
  end
  if Str and (len(Str)>W) then W=len(Str) end
  W=W+4
  local x= math.ceil((wScr-W)/2)
  local y= math.ceil((hScr-H)/2)+1
  gpu.set(x-1, y, ' ╔'..string.rep('═',W-2)..'╗ ')
  for i=1,#Lines+2 do
    gpu.set(x-1, y+i, ' ║'..string.rep(' ',W-2)..'║ ')
  end
  gpu.set(x-1, y+H-1,' ╚'..string.rep('═',W-2)..'╝ ')
  for i=1,#Lines do
    if Lines.left then gpu.set(x+2, y+i, Lines[i])
    else gpu.set(x+(W-len(Lines[i]))/2, y+i, Lines[i]) end
  end

  while true do
    term.setCursorBlink(CurBut==0)
    term.setCursor(x+(W-len(Buttons()))/2, y+H-2)
    term.write(Buttons())
    if CurBut==0 then
      local S=Str
      if len(S)>W-4 then S='..'..sub(S,-W+6) end
      term.setCursor(x+2, y+H-3)  term.write(S)
    end

    local eventname, _, ch, code = event.pull('key_down')
    if eventname == 'key_down' then
      if code == keys.enter then
        if CurBut==0 then CurBut=1 end
        return But[CurBut],Str
      elseif code == keys.left and CurBut~=0 then
        if CurBut>1 then CurBut=CurBut-1 end
      elseif code == keys.right and CurBut~=0 then
        if CurBut<#But then CurBut=CurBut+1 end
      elseif code == keys.tab then
        if CurBut<#But then CurBut=CurBut+1
        else CurBut=Str and 0 or 1
        end
      elseif code == keys.back and CurBut==0 then
        if #Str>0 then gpu.set(x+1, y+H-3, string.rep(' ',W-2)) Str=sub(Str,1,-2) end
      elseif ch > 0 and CurBut == 0 then
        Str = Str..unicode.char(ch)
      end
    end
  end
end

local function call(func,...)
  local r,e=func(...)
  if not r then Dialog(AlarmWinCl,{e}) end
  return r
end

local function CpMv(func,from,to)
  if fs.isDirectory(from) then
    if not fs.exists(to) then call(fs.makeDirectory,to)  end
    for name in fs.list(from) do
      CpMv(func,fs.concat(from,name),fs.concat(to,name))
    end
    if func==fs.rename then call(fs.remove,from) end
  else
    if fs.exists(to) then
      if Dialog(AlarmWinCl,{'File already exists!',to,'Overwrite it?'},nil,{'Yes','No'})=='Yes' then
        if not call(fs.remove,to) then return end
      end
    end
    call(func,from,to)
  end
end

local function CopyMove(action,func)
  if Active==Find then return end
  Name = ((Active==Rght) and Left or Rght).Path..'/'..cmd
  cmd=Active.Path..'/'..cmd
  local Ok,Name=Dialog(WindowCl,{action,cmd,'to:'},Name,{'<Ok>','Cancel'})
  if Ok=='<Ok>' then
    if cmd==Name then
      Dialog(AlarmWinCl,{'Cannot copy/move file to itself!'})
    else
      CpMv(func, cmd, Name)
    end
  end
  ShowPanels()
end

local eventKey={}
eventKey[keys.up]=function()
  if Active.CurLine>1 then
    local Line=Active.CurLine
    Active.CurLine=Line-1
    if Active.CurLine<Active.Shift then
      Active.Shift=Active.CurLine
      Active:ShowLines()
    else
      Active:ShowLine(Active.CurLine)
      Active:ShowLine(Line)
    end
    Active:ShowLast()
  end
end

eventKey[keys.down]=function()
  if Active.CurLine<#Active.tFiles then
    local Line=Active.CurLine
    Active.CurLine=Active.CurLine+1
    if Active.CurLine>Active.Shift+hScr-5 then
      Active.Shift=Active.CurLine-hScr+5
      Active:ShowLines()
    else
      Active:ShowLine(Active.CurLine)
      Active:ShowLine(Line)
    end
    Active:ShowLast()
  end
end

eventKey[keys.left]=function()
  if curpos<len(cmdstr) then curpos=curpos+1 end
end

eventKey[keys.right]=function()
  if curpos>0 then curpos=curpos-1 end
end

eventKey[keys.tab]=function()
  if Active==Find then return end
  Active = (Active==Rght) and Left or Rght
  shell.setWorkingDirectory(Active.Path)
  ShowPanels()
end

eventKey[keys.enter]=function()
  local function exec(cmd)
    loadScreen() scr=nil
    shell.execute(cmd)
    saveScreen()
    ShowPanels()
  end
  curpos=0
  if cmdstr~='' then
    exec(cmdstr)
    cmdstr=''
    return
  end
  if Active==Find then
    Active=Find.Last
    if cmd~='..' then Active:SetPos("/"..cmd) end
    ShowPanels()
    return
  end
  if Active.tSize[Active.CurLine]=='DIR' then
    if cmd=='..' then  Active:SetPos(Active.Path)
    else  Active:SetPos(shell.resolve(cmd)..'/..')  end
    Active:Show()
  else
    exec(cmd)
  end
end

eventKey[Ctrl+keys.enter]=function()
  cmdstr=cmdstr..cmd..' '
end

eventKey[Alt+keys.enter]=function()
  loadScreen()
  event.pull("key_down")
  gpu.setResolution(wScr,hScr)
  ShowPanels()
end

eventKey[keys.back]=function()
  if cmdstr~='' then
    if curpos==0 then cmdstr=sub(cmdstr,1,-2)
    else cmdstr=sub(cmdstr,1,-2-curpos)..sub(cmdstr,-curpos)
    end
  end
end

eventKey[keys.delete]=function()
  if cmdstr~='' then
    if curpos>0 then
      curpos=curpos-1
      if curpos==0 then
        cmdstr=sub(cmdstr,1,-2)
      else
        cmdstr=sub(cmdstr,1,-2-curpos)..sub(cmdstr,-curpos)
      end
    end
  end
end

eventKey[keys['end']]=function() curpos=0 end

eventKey[keys.home]=function() curpos=len(cmdstr) end

eventKey[keys.f1]=function()
  if Active==Find then return end
  Dialog(SelectCl,{
"Up,Down,Tab- Navigation",
'Enter      - Change dir/run program',
'Ctrl+Enter - Insert into command line',
'Alt+Enter  - Hide panels',
'F1 - This help',
'F4 - Edit file',
'Shift+F4 - Create new file',
'F5 - Copy file/dir',
'F6 - Move file/dir',
'F7 - Create directory',
'Alt+F7 - Find file/dir',
'F8  - Delete file/dir',
'F10 - Exit from MC',left=true})
  ShowPanels()
end

eventKey[keys.f4]=function()
  if Active.tSize[Active.CurLine]=='DIR' then
    Dialog(AlarmWinCl,{'Error!', cmd, 'is not a file'})
  else
    SetColor(NormalCl)
    term.setCursorBlink(false)
    shell.execute('edit '..cmd)
  end
  ShowPanels()
end

eventKey[Shift+keys.f4]=function()
  local Ok,Name=Dialog(WindowCl,{'File name:'},'',{'<Ok>','Cancel'})
  if Ok=='<Ok>' then
    SetColor(NormalCl)
    shell.execute('edit '..Name)
  end
  ShowPanels()
end

eventKey[keys.f5]=function()
  CopyMove('Copy file:',fs.copy)
end

eventKey[keys.f6]=function()
  CopyMove('Move file:',fs.rename)
end

eventKey[keys.f7]=function()
  if Active==Find then return end
  local Ok,Name=Dialog(WindowCl,{'Directory name:'},'',{'<Ok>','Cancel'})
  if Ok=='<Ok>' then
    if Name=='..' or fs.exists(shell.resolve(Name)) then
      ShowPanels()
      Dialog(AlarmWinCl,{' File exists '})
    else
      fs.makeDirectory(shell.resolve(Name))
    end
  end
  ShowPanels()
end

eventKey[Alt+keys.f7]=function()
  local Ok,Name=Dialog(WindowCl,{'Find file/dir:','Use ? and * for any char(s)'},'',{'<Ok>','Cancel'})
  if Ok=='<Ok>' then
    Find.Path=Name
    Find.CurLine=1
    Find.Shift=1
    if Active~=Find then
      Find.Last=Active
      Active=Find
    end
    Find:GetFiles()
  end
  ShowPanels()
end

eventKey[keys.f8]=function()
  if Active==Find then return end
  if Dialog(AlarmWinCl,{'Do you want to delete', cmd..'?'}, nil, {'Yes','No'})=='Yes' then
    call(fs.remove,shell.resolve(cmd))
  end
  ShowPanels()
end

eventKey[keys.f10]=function()
  work=false
end

NormalCl={colors.white,colors.black}
if gpu.getDepth() > 1 then
  PanelCl={colors.white,colors.blue}
  DirCl={colors.orange,colors.blue}
  SelectCl={colors.black,colors.orange}
  WindowCl={colors.white,colors.green}
  AlarmWinCl={colors.white,colors.red}
else
  PanelCl=NormalCl
  DirCl=NormalCl
  SelectCl={colors.black,colors.white}
  WindowCl=NormalCl
  AlarmWinCl=NormalCl
end
if wScr<80 then
  Menu={'Help','','','Edit','Copy','Move','Dir','Del','','Exit'}
else
  Menu={' Help ','','',' Edit ',' Copy ',' Move ',' Dir  ',' Del  ','',' Exit '}
end
for i=1,#Menu do
  if #Menu[i]>0 then xMenu=xMenu+#tostring(i)+len(Menu[i])+2 end
end
xMenu=math.floor((wScr-xMenu) / 2)
Left =panel:new(1,'')
Rght =panel:new(Left.wPan+1,shell.getWorkingDirectory():sub(1,-2))
Find =Fpanel:new(1,'')
Active =Rght

saveScreen()
ShowPanels()
ShowCmd()
while work do
  local eventname, _, char, code, dir = event.pull()
  cmd=Active.tFiles[Active.CurLine]
  if eventname =='key_down' then
    if keyboard.isShiftDown() then code=code+Shift end
    if keyboard.isControlDown() then code=code+Ctrl end
    if keyboard.isAltDown() then code=code+Alt end
    if eventKey[code] ~= nil then
      SetColor(PanelCl)
      eventKey[code]()
      ShowCmd()
    elseif char > 0 then
      if curpos==0 then cmdstr=cmdstr..unicode.char(char)
      else cmdstr=cmdstr:sub(1,-1-curpos)..unicode.char(char)..cmdstr:sub(-curpos)
      end
      ShowCmd()
    end
  end
end
loadScreen()
print('Thank you for using Midday Commander!')
