# geoglasses
*The program that shows ores on the glasses from the OpenGlasses mod.*

![Screenshot 1](http://i.imgur.com/KWqpDr8.png)

## Developers
* electronic\_steve

## Description

### Requirements
* Geolyzer.
* Glasses bridge from OpenGlasses.
* Glasses from that mod.

Geolyzer must be on top of the bridge.

### Syntax
`scan [density] [radius of scan] [search above]`

* `density` — that's a minimum density of blocks that the program will display. 3 by default.
* `radius of scan` — suprising, but this is a radius of scan. 16 by default.
* `search above` — if the value isn't `0`, the program will search for ores above the geolyzer too. 0 by default.

The maximum radius of scan is 18 blocks.

And, by the way, the bridge will eat A LOT of energy.

### Colors
* white: the density is less than 2.
* purple: the density is more than 5.
* green to red: the density is in the range [2, 5].

## Links
* [The topic on the forums](http://computercraft.ru/topic/1628-)
* [Pastebin](http://pastebin.com/kzFvEnNx)
