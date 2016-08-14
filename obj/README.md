# OBJ
*A library that provides functions to draw .obj 3D-models on the OpenGlasses' glasses.*

The `obj` format is one of the most popular format of 3D-model files. Almost every 3D modelling software supports this format. Besides of that, a lot of 3D-models can be found on the internet.

## Developers
* Totoro (a.k.a. MoonlightOwl)

## Description

Using a simple API, you can do something like this:

![Screenshot 1: The skull 3D-model](https://lh3.googleusercontent.com/-WcuSQWZ7hCQ/VeGOQHneL9I/AAAAAAAABHc/dUt_JiOU1DE/s912-Ic42/2015-08-29_12.46.39.png)
![Screenshot 2: The plane 3D-model](https://lh3.googleusercontent.com/-2M1dCbZpoW8/VeGcXo2vzOI/AAAAAAAABJQ/dPnfVnYdaHo/s912-Ic42/2015-08-29_13.46.28.png)

Unfortunately, the draw speed on OpenGlasses' glasses is *incredibly* slooooooow, and the more polygons a model has, the longer time it will take to draw a model. The skull on screenshot above consists of 9000 polygons, and needs ~5 minutes to draw it.

Moreover, if the amount of polygons is a lot, the model will flicker. That's because the glasses bridge will use an incredible amount of energy.

### API
* `load(filename: string)` — loads a model from the given file, including the `.obj` extension.
* `draw(glasses: table)` — draws a model. The argument is a proxy of OpenGlasses's glasses bridge.
* `setPosition(x: number, y: number, z: number)` — sets the position of a model, relative to the glasses bridge.
* `setScale(s: number)` — sets the scale of 3D-model. `1` is the model's original scale.
* `setColor(r: number, g: number, b: number)` — sets the colors of a 3D-model. The values must be in the range [0, 1].
* `getPosition(): table` — returns the position of a 3D-model: `{x, y, z}`.
* `getScale(): number` — returns the scale of a 3D-model.
* `getColor(): table` — returns the color of a 3D-model: `{r, g, b}`.
* `getVertexNum(): number` — returns the amount of vertexes in the model.
* `getPolyNum(): number` — returns the amount of polygons in the model.

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
![Screenshot 3: The wolf 3D-model](https://lh3.googleusercontent.com/-0fUNmPMpD8Y/VeGeWk0sAEI/AAAAAAAABJs/EjKCFqsI-XQ/s912-Ic42/2015-08-29_13.57.50.png)

## Links
* [The topic on the forums](http://computercraft.ru/topic/1103-)
* [Pastebin](http://pastebin.com/JyK7KTCQ)
