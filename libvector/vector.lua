local math = require "math"
local concat = require "table".concat
local format = require "string".format
local setmetatable = setmetatable
local type, error = type, error
local rawset, rawget = rawset, rawget

-- One of those cases where you really miss the "using" keyword.
local pow, sqrt, max, floor, acos, sin, cos, modf, pi = math.pow, math.sqrt, math.max, math.floor, math.acos, math.sin, math.cos, math.modf, math.pi
math = nil

local vector

local function check(o)  -- Vector type check
  local t = type(o)
  if not (t == "table" and o.object == "vector") then
    error("attempt to perform arithmetic on a "..t.." value", 3)
  end
end

local __index = {
  tostring = function(self, f)
    f = type(f) == "number" and f >= 0 and f or 3
    f = "%."..f.."f"
    local r = { }
    for i = 1, self.n do
      local n = self[i]
      r[i] = format(modf(n) == n and "%1d" or f, n)
    end
    return "{"..concat(r, "; ").."}"
  end;

  add = function(a, b)
    check(a)
    check(b)
    local v = { }
    for i = 1, max(a.n, b.n) do
      v[i] = (a[i] or 0) + (b[i] or 0)
    end
    return vector(v)
  end;

  sub = function(a, b)
    check(a)
    check(b)
    local v = { }
    for i = 1, max(a.n, b.n) do
      v[i] = (a[i] or 0) - (b[i] or 0)
    end
    return vector(v)
  end;

  mul = function(a, b)
    local t1 = type(a)
    local t2 = type(b)
    local v = { }
    if t1 == "number" then
      check(b)
      for i = 1, b.n do
        v[i] = b[i] * a
      end
    elseif t2 == "number" then
      check(a)
      for i = 1, a.n do
        v[i] = a[i] * b
      end
    else
      check(a)
      check(b)
      v = a:cross(b)
    end
    return vector(v)
  end;

  div = function(a, b)
    check(a)
    local t = type(b)
    if t ~= "number" then
      error("attempt to perform arithmetic on a "..t.." value", 3)
    end
    local v = { }
    for i = 1, a.n do
      v[i] = a[i] / b
    end
    return vector(v)
  end;

  len = function(self)
    local r = 0
    for i = 1, self.n do
      r = r + pow(self[i], 2)
    end
    return sqrt(r)
  end;

  dot = function(a, b)
    check(a)
    check(b)
    local r = 0
    for i = 1, max(a.n, b.n) do
      r = r + (a[i] or 0) * (b[i] or 0)
    end
    return r
  end;

  cross = function(a, b)
    check(a)
    check(b)
    local v = {
      (a[2] or 0) * (b[3] or 0) - (a[3] or 0) * (b[2] or 0);
      (a[3] or 0) * (b[1] or 0) - (a[1] or 0) * (b[3] or 0);
      (a[1] or 0) * (b[2] or 0) - (a[2] or 0) * (b[1] or 0);
    }
    return vector(v)
  end;

  normalize = function(self)
    return self / #self
  end;

  angle = function(a, b)
    check(a)
    check(b)
    a, b = a:normalize(), b:normalize()
    return acos(a:dot(b))
  end;

  rotate = function(v, g, a, b)
    local r = { }
    local c, s = cos(g), sin(g)
    for i = 1, v.n do
      r[i] = i == a and v[a] * c - v[b] * s or b == i and v[a] * s + v[b] * c or v[i]
    end
    return vector(r)
  end;

  round = function(self, d)
    local v = { }
    d = type(d) == "number" and d or 0.5
    for i = 1, self.n do
      local a, b = modf(self[i])
      v[i] = b < d and a or a + 1
    end
    return vector(v)
  end;

  eq = function(a, b)
    if not (type(a) == "table" and a.object == "vector") or not (type(a) == "table" and a.object == "vector") then
      return false
    end
    local r = true
    for i = 1, max(a.n, b.n) do
      if a[i] ~= b[i] then
        r = false
        break
      end
    end
    return r
  end;

  object = "vector";  -- Object type
}

local meta = {
  __index = __index;
  __tostring = __index.tostring;
  __add = __index.add;
  __sub = __index.sub;
  __mul = __index.mul;
  __div = __index.div;
  __len = __index.len;
  __eq = __index.eq;
  __newindex = function(self, d, n)
    local a = type(d)
    local b = type(n)
    if not (a == "number" and d == floor(d) and d > 0) then
      error("invalid dimension type (signed integer expected, got "..(a == "number" and d ~= floor(d) and "float" or a)..")", 2)
    end
    if b ~= "number" then
      error("invalid coordinate type (number expected, got "..b..")")
    end
    d = floor(d)
    for i = 1, d-1 do
      if not rawget(self, i) then
        rawset(self, i, 0)
      end
    end
    rawset(self, d, n)
    rawset(self, "n", d)
  end;
}

vector = function(v)  -- Creates a new vector
  v.n = #v
  return setmetatable(v, meta)
end

return function(...)  -- The same as above, but with additional checks
  local v = { ... }
  for i=1, #v do
    local t = type(v[i])
    if t ~= "number" then
      error("bad argument #"..i.." (number expected, got "..t..")")
    end
  end
  return vector(v)
end
