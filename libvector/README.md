# libvector

This library provides mathematical vectors with unlimited amount of dimensions.

## Authors
* Ktlo

## Description
The library returns the function that's called like this: `vector(x: number, y: number, z: number, ...)`.

A vector stores dimensions (and corresponding values) in a table. Each vector also has the `n` field, the amount of dimensions.

```lua
local vector = require("vector")
local a = vector(1, 5, 89, 6)
print(a.n)
--> 4
```

All methods create a new vector instead of overriding the old one.

### Arithmetic operations
```lua
local vector = require("vector")
local a = vector(5, 8, 9)
local b = vector(78, 3, -13, 56)

print(a + b)
--> {83; 11; -4; 56}

print(a - b)
--> {-73; 5; 22; -56}

print(a * 8)  -- we could also write this as 8 * a
--> {40; 64; 72}

print(b / 42)
--> {1.857; 0.071; -0.310; 1.333}

print(a * b)  -- cross product
--> {-131; 767; -609}

print(a == b)
--> false

print(#a, #b)  -- vector lengths
--> 13.038404810405 96.943282387177
```

### Methods
* `vector:tostring([precision: number])` — the same as `tostring(vector)`, but also accepts the optional decimal precision (3 by default).
* `vector:add(vector2: table): table` — the same as `vector + vector2`.
* `vector:sub(vector2: table): table` — the same as `vector - vector2`.
* `vector:mul(vector2: table): table` — the same as `vector * vector2`.
* `vector:div(number: number): table` — the same as `vector / number`.
* `vector:len(): number` — the same as `#vector`.
* `vector:dot(vector2: table): number` — the dot product.
* `vector:cross(vector2: table): table` — the cross product.
* `vector:normalize(): table` — returns the normalized vector.
* `vector:angle(vector2: table): number` — returns the angle between vectors (in radians).
* `vector:round(): table` — rounds the vector.
* `vector:eq(vector2: table): boolean` — the same as `vector == vector2`.

## Links
* [**Pastebin**](http://pastebin.com/mdfDvmps)
* [The topic on the Russian forums](http://computercraft.ru/topic/1106-)
