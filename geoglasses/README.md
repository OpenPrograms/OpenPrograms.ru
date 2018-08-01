# geoglasses
*The program that shows ores on the glasses from the OpenGlasses mod.*

![Screenshot 1](http://i.imgur.com/KWqpDr8.png)

## Developers
* electronic\_steve

## Description

### Requirements
* Geolyzer.
* Glasses bridge from OpenGlasses.
* Glasses themselves.

Geolyzer must be on top of the bridge.

### Syntax
`scan [density] [radius of scan] [search above]`

* `density` — a minimum density of blocks that the program will display.
  \(Default: 3.\)
* `radius of scan` — a radius of scan. (Default: 16.)
* `search above` controls whether the program should also search for ores above
  the geolyzer.

The maximum radius of scan is 18 blocks.

And, by the way, the bridge eats lots of energy. Consider connecting more
capacitors and power convertors if the computer runs out of energy.

### Colors
* white: the density is less than 2.
* purple: the density is more than 5.
* green to red: 2 <= the density <= 5.

## Links
* [The topic on the forums](http://computercraft.ru/topic/1628-)
* [Pastebin](http://pastebin.com/kzFvEnNx)
