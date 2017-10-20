local computer = require("computer")
computer.SingleThread = computer.pullSignal
local thread = {}

local mainThread
local timeouts

local function MultiThread( _timeout )
  if coroutine.running() == mainThread then
    local mintime = _timeout or math.huge
    local co=next(timeouts)
    while co do
      if coroutine.status( co ) == "dead" then
        timeouts[co],co = nil,next(timeouts,co)
      else
        if timeouts[co] < mintime then mintime=timeouts[co] end
        co=next(timeouts,co)
      end
    end
    if not next(timeouts) then
      computer.pullSignal = computer.SingleThread
      computer.pushSignal("AllThreadsDead")
    end
    local event = {computer.SingleThread(mintime)}
    local ok, param
    for co in pairs(timeouts) do
      ok, param = coroutine.resume( co, table.unpack(event) )
      if not ok then timeouts = {} error( param )
      else timeouts[co] = param or math.huge end
    end
    return table.unpack(event)
  else
    return coroutine.yield( _timeout )
  end
end

function thread.init()
  mainThread = coroutine.running()
  timeouts = {}
end

function thread.create(f,...)
  computer.pullSignal = MultiThread
  local co = coroutine.create(f)
  timeouts[co] = math.huge
  local ok, param = coroutine.resume( co, ... )
  if not ok then timeouts = {} error( param )
  else timeouts[co] = param or math.huge end
  return co
end

function thread.kill(co)
  timeouts[co] = nil
end

function thread.killAll()
  timeouts = {}
  computer.pullSignal = computer.SingleThread
end

function thread.waitForAll()
  repeat
  until MultiThread() == "AllThreadsDead"
end
-------------------------------------------------------------------------------
return thread
