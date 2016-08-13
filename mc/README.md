# Midday Commander
*A file manager utility for OpenComputers.*

For those who are not experienced with command-line interfaces, Midday Commander, a (or even the?) file manager was created.

## Developers
* Zer0Galaxy (aka Dimus) — the computercraft version of the program.
* NEO (a.k.a. Avaja) — the file search algorithm.
* Totoro (also known as MoonlightOwl) — the OpenComputers port.

## Description
The programs supports any screens with any color depth or resolution.

![Screenshot 1](http://computercraft.ru/uploads/monthly_04_2016/post-7-0-02123500-1459869189.png)
![Screenshot 2](http://computercraft.ru/uploads/monthly_04_2016/post-7-0-87499400-1459869194.png)

It even can be run on robots.

The basis of the GUI is a well-known Linux program, Midnight Commander, and, of course, Norton Commander.

The GUI of the program has two panels: left and right ones. Each one lists files and directories that are stored on the computer's HDDs or floppies. The directories have `/` at the end of their's names, and are listed at the top of the lists.

Below, there's a command prompt, and the list of the actions that can be invoked by pressing a corresponding functional (`Fx`) key.

Use arrow keys to navigate through the files, and pressing the `Tab` key moves the focus to another panel. The `Enter` key is used to run a program, or go to directory. To run a program, and pass some arguments, hold `Ctrl`, and press `Enter`. The name of program will be copied to the command prompt. Type the arguments, and press `Enter`.

Also, you can press `Alt` + `Enter` to hide MC.

## Actions

`F1` — show help.
![Screenshot 3: The help window](http://computercraft.ru/uploads/monthly_04_2016/post-7-0-29338700-1459869245.png)

`F4` — open an editor with the selected file.

`Shift` + `F4` — create a new file.
![Screenshot 4: The "Create new file" dialog](http://computercraft.ru/uploads/monthly_04_2016/post-7-0-43233500-1459869281.png)

`F5` — copy a selected file to the another panel's current directory. You can copy under another name if you want so.
![Screenshot 5: The "Copy the file" dialog](http://computercraft.ru/uploads/monthly_04_2016/post-7-0-47155500-1459869311.png)

`F6` — move a selected file.

`F7` — create a new directory.

`Alt` + `F7` — search for a file or directory.
![Screenshot 6: The "Search" dialog](http://computercraft.ru/uploads/monthly_04_2016/post-7-0-58966600-1459869362.png)
![Screenshot 7: The "Search results" dialog](http://computercraft.ru/uploads/monthly_04_2016/post-7-0-58966600-1459869362.png)

You can use `?` and `*` masks.

* `?` means "any character".
* `*` means "0 or more characters"

For example, to search for all files that start with `m`, you can use the `m*` pattern.

![Screenshot 8: The pattern search demonstration](http://computercraft.ru/uploads/monthly_04_2016/post-7-0-27811400-1459869378.png)

`F8` — remove a file or directory. You'll be asked for a confirmation before removing. Use the `Tab` key to select the `No` button.
![Screenshot 9: The "Remove the file" dialog](http://computercraft.ru/uploads/monthly_04_2016/post-7-0-34415400-1459869339.png)

`F10` — exit.

## Links
[The topic on the forums](http://computercraft.ru/topic/940-)
[Pastebin](http://pastebin.com/kE3jp6nD)
