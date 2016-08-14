# libqr
*QR-code generator.*

## Developers
* 1Ridav

## Description

### API
* `qr.encode(data: string): table` — generates a QR-code that decodes to the given data. The return value is a table of `1` (black) and `0` (white)
* `qt.printHalf(data: table)` — draws the QR code on the screen.

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
