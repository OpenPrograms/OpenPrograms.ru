# libqr
A *QR-code generator.*

## Developers
* 1Ridav

## Description

### API
* `qr.encode(data: string): table` — generates a QR-code that decodes to the
  given data. The return value is a matrix of `1`s (black) and `0`s (white).
* `qt.printHalf(data: table)` — draws a QR code on the screen.

### Example
```lua
local qr = require("qr")

local data = qr.encode("Hello there!")

qr.printHalf(data)
```

![Screenshot 1: the result of execution the code above](http://i.imgur.com/WQzGpKS.png)
![Screenshot 2: another QR code](http://i.imgur.com/gDTifCk.png)

## Links
* [The topic on the forums](http://computercraft.ru/topic/878-)
* [Pastebin](http://pastebin.com/Cgf1x9G1)
