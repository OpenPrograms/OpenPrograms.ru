# libforms
*A lightweight, yet powerful, GUI library.*

## Developers
* Zer0Galaxy

## Description
First, you need to `require` the library:
```lua
local forms = require("forms")
```

The library has three functions:

* `addForm()` — creates a new form.
* `run(form)` — starts the main loop, setting the given form as an active one.
* `stop()` — ends the main loop.

### Form
Can be created with the following command:

```lua
local Form = forms.addForm()
```

Basically, the form is a space on the screen where the GUI objects are put. If the form is active, its objects become responsive to mouse events. You can have multiple forms, but only one can be active at the moment.

By default, the form uses the whole screen. You can change this:

```lua
Form.W = 31     -- width
Form.H = 7      -- height
Form.left = 10  -- offset from the left
Form.top = 5    -- offset from the top
```

Besides `left`, `top`, `W`, and `H`, the form also has the following properties:

* `border` — controls whether to show the border.
  * `0` — no border [default]
  * `1` — single border
  * `2` — double border
* `color` — the background of the form (`0x000000` by default).
* `fontColor` — the color of the borders (`0xffffff` by default).

It also has the following methods:

* `setActive()` — makes the form active, and redraws it.
* `isActive()` — returns `true` is the form is active.
* `redraw()` — redraws the form forcefully, if it's active.
* `addButton(left: number, top: number, caption: string, onClick: function)` — adds a button on the form.
* `addLabel(left: number, top: number, caption: string)` — adds a label on the form.
* `addEdit(left: number, top: number, onEnter: string)` — adds a text field on the form.
* `addFrame(left: number, top: number, border: number)` — adds a frame.
* `addList(left: number, top: number, onChange: function)` — adds a list of items.
* `addEvent(eventName: string, onEvent: function)` — adds an event listener.
* `addTimer(interval: number, callback: function)` — adds a timer.

Since the form is an object, it's methods should be called using the colon:

```lua
Form:setActive()
```

Other GUI objects have all the properties and the methods of the form, except `isActive()` and `setActive()`.

### Button
Can be created using the following command:

```lua
Button = Form:addButton(left: number, top: number, caption: string, onClick: function)
```

It creates a button and returns its object.

**NOTE:** the `forms.addForm` is called using a dot, `Form:addButton` is called using a colon, as `forms` is a library, but `Form` is an object!

Arguments:

* `left`, `top` — the offsets, relative to the parent object.
* `caption` — a text on the button.
* `onClick` — a click handler.

When the button is clicked, the `onClick` handler is called. A button object is passed as an argument.

Properties of the button:

* `W` — the button's width `[10]`.
* `H` — the height of button `[1]`.
* `border` — the border `[0]`.
* `color` — the color of button `[0x606060]`.
* `fontColor` — the color of the text on button, and the button's border `[0xffffff]`.
* `visible` — has the value of `false` when the button is hidden `[true]`.
* `X`, `Y` — the absolute coordinates of the top-left corner of the button (i.e., relative to the screen).

Methods:

* `hide()` — hides the button.
* `show()` — shows the button.
* `isVisible()` — returns `true` if the button is not hidden, and the parent object is active.
* `redraw()` — redraw the button.

The GUI objects can be created not only on the form, but on other objects! For example, the button can be created on the frame, and the label can be created on the button. The child object will move, hide and show with its parent object.

### Label
Can be created using the following command:

```lua
Label = Form:addLabel(left: number, top: number, caption: string)
```

The command creates a label on the form, and returns the label object.

Arguments:

* `left`, `top` — the offsets, relative to the parent object.
* `caption` — the text of the label.

The properties and the methods of the label are the same as the button's ones.

### Text field
Can be created using the following command:

```lua
TextField = Form:addEdit(left: number, top: number, onEnter: function)
```

The text field allows to type a line of text.

Arguments:

* `left`, `top` — the offsets, relative to the parent object.
* `onEnter` — the handler.

The object switches to the input mode after clicking on it. The mode switches back to regular when the `Enter` key is pressed. Then, the handler is called, if given.

The methods and properties are the same the button's ones. There's also an additional property:

* `text` — the text typed in the text field.

### Frame
```lua
Frame = Form:addFrame(left: number, top: number, border: number)
```

The frame doesn't do anything.

Arguments:

* `left`, `top` — the offsets, relative to the parent object.
* `border` — the border.

The methods and the arguments are the same as the button's ones.

### List
```lua
List = Form:addList(left: number, top: number, onChange: function)
```

The list is... a list of items. It can have multiple items of different types, like Lua tables. Every item of the list has a text that will be shown in the list.

Arguments:

* `left`, `top` — the offsets, relative to the parent object.
* `onChange` — the handler that's called when a user selects an item.

Properties:

* `W` — the width of the list `[20]`.
* `H` — the height of the list `[10]`.
* `border` — the border `[2]`.
* `color` — the color `[0x000000]`.
* `fontColor` — the color of the text and the border `[0xffffff]`.
* `selCol` — the color of selected item `[0x0000ff]`.
* `selFont` — the color of the text of selected item `[0xffff00]`.
* `index` — the index of selected item.
* `items` — the table that contains the items.
* `lines` — the table that contains the lines (the text that's shown) of the corresponding element of the `items` table.
* `visible` — has the `false` value if the list is hidden, and `true` otherwise `[true]`.
* `X`, `Y` — the absolute coordinates of the top-left corder of the list (i.e., relative to the screen).

In addition to the methods of the button, the list also has:

* `clear()` — clears the list.
* `insert([pos: number, ]line: string, item)` — inserts an item and corresponding text into the list.
* `sort([comp: function])` — sorts the list. If the function is given, it's called with the list table and two indexes of the list passed as arguments. It must return `true` if the values should be swapped. If the function isn't given, the list is sorted in alphabetical order.

### Event listener
```lua
Event = Form:addEvent(eventName: string, onEvent: function)
```
Works exactly the same, as `event.listen`, but the listener works only in the main loop.

### Timer
```lua
Timer = Form:addTimer(interval: number, callback: function)
```

Calls the callback function with the given interval.

Arguments:

* `interval` — the interval, in seconds.
* `callback` — the function that's called.

Methods of the timer:

* `stop()` — pauses the timer.
* `start()` — starts the timer.

## Links
[The topic on the forums](http://computercraft.ru/topic/1016-)
[Pastebin](http://pastebin.com/iKzRve2g)
