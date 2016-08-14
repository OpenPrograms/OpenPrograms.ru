# libthread
*A thread library that's simple to use.*

## Developers
* Zer0Galaxy

## Description

### API
* `thread.init()` — **MUST BE CALLED** first before calling other functions of the library.
* `thread.create(f: function, ...)` — convert a function to a thread that starts immediately. You can provide the arguments that will be passed to the function.
* `thread.kill(thread: thread)` — kills a thread.
* `thread.killAll()` — kills all threads but the main one.
* `thread.waitForAll()` — waits until the end of all child threads. All child threads are killed when the main one dies, so you should call this function in the end of your progarm to give the child threads a chance to end correctly.

### Example
```lua
local thread = require("thread")
-- Initialize the library
thread.init()

-- Function that prints the string several times with the 1-second interval.
local function foo(str,n)
  for i = 1, n do
    print(str)
    os.sleep(1)
  end
end

-- Create two threads with different parameters
thread.create(foo, "AAA", 5)
thread.create(foo, "BBB", 7)

-- Wait until the child threads die.
thread.waitForAll()
```

![Screenshot 1: the result of executing the code above](http://computercraft.ru/uploads/monthly_04_2015/post-7-0-53646300-1427986494.png)

## Links
[The topic on the forums](http://computercraft.ru/topic/634-)
[Pastebin](http://pastebin.com/E0SzJcCx)
