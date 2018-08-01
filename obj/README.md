# OBJ
*A library that provides functions to draw .obj 3D models on the OpenGlasses'
glasses.*

The `obj` format is one of the most popular format of 3D model files.
Almost every 3D modelling software supports it. Besides, a lot of 3D models
can be found on the internet.

## Developers
* Totoro (a.k.a. MoonlightOwl)

## Description
Using the API you can do something like this:

![Screenshot 1: The skull 3D model](https://lh3.googleusercontent.com/-WcuSQWZ7hCQ/VeGOQHneL9I/AAAAAAAABHc/dUt_JiOU1DE/s912-Ic42/2015-08-29_12.46.39.png)
![Screenshot 2: The plane 3D model](https://lh3.googleusercontent.com/-2M1dCbZpoW8/VeGcXo2vzOI/AAAAAAAABJQ/dPnfVnYdaHo/s912-Ic42/2015-08-29_13.46.28.png)

Unfortunately, the draw speed on OpenGlasses' glasses is *incredibly* slow,
and the more polygons a model has, the longer time it takes to draw a model.
The skull on screenshot above consists of 9000 polygons,
and needs ~5 minutes to draw it.

Moreover, if there's a lot of polygons, the model may flicker. That's because
the glasses bridge uses an enormous amount of energy. Fortunately, this can be
easily resolved by connecting more capacitors and power converters
to your OC network.

### API
* `load(filename: string)` — loads a model from the given file,
  specified with the `.obj` extension.
* `draw(glasses: table)` — draws a model. The argument is a proxy to the
  OpenGlasses's glasses bridge.
* `setPosition(x: number, y: number, z: number)` — sets the position of a model
   relative to the glasses bridge.
* `setScale(s: number)` — sets the scale of the 3D model. `1` is the model's
  original scale.
* `setColor(r: number, g: number, b: number)` — sets the colors of the 3D model.
  The values must be normed (0 <= value <= 1).
* `getPosition(): table` — returns the position of the model: `{x, y, z}`.
* `getScale(): number` — returns the scale of the model.
* `getColor(): table` — returns the color of the model: `{r, g, b}`.
* `getVertexNum(): number` — returns the number of verteces in the model.
* `getPolyNum(): number` — returns the number of polygons in the model.

### Code example
```lua
local obj = require('obj')
local com = require('component')
local glasses = com.glasses

glasses.removeAll()

obj.load('wolf.obj')
obj.setScale(0.01)
obj.setPosition(0, 0, 5)
obj.setColor(1, 1, 1)
obj.draw(glasses)

print('Vertexes: '..obj.getVertexNum(), 'Polygons: '..obj.getPolyNum())
```

Here's the result:
![Screenshot 3: The wolf 3D model](https://lh3.googleusercontent.com/-0fUNmPMpD8Y/VeGeWk0sAEI/AAAAAAAABJs/EjKCFqsI-XQ/s912-Ic42/2015-08-29_13.57.50.png)

## Links
* [The topic on the forums](http://computercraft.ru/topic/1103-)
* [Pastebin](http://pastebin.com/JyK7KTCQ)
