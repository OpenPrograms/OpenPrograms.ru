# geomine
*A miner that uses Geolyzer.*

## Developers
* Doob (a.k.a. Log on the oc.cil.li forums)

## Description
This programs uses the Geolyzer to effectively mine the ores.

### Launch
1. Place a robot.
2. Give a mining tool to robot (it's better to use some electric pickaxe or drill).
3. Place a chest and a charger (don't forget to turn it on, either by screnching, or by placing and flipping a lever).
4. Run the program (`geomine [columns] [height]`). The `[columns]` is the amount of 8×8 columns from bedrock to the starting level. `[height]` is the max amount of blocks that robot may descend.
5. Make a tea, sleep, or do something else. It may takes several hours to completely mine all the ores out.

### Requirements
* Inventory upgrades (the more you have, the less time will be spent on returning back to the starting location to unload the inventory).
* Inventory controller upgrade.
* Geolyzer.
* Some tool to use for mining. As said earlier, it's better to have rechargeable tools.
* Hover upgrade.

Additional components:

* Crafting upgrade.
* Generator upgrade.
* Chunkloader upgrade.
* Linked card.

### Algorithm
* Robot scans the squares 8×8, descending.
* Mines the blocks that have a density in the set range.
* When the robot reaches the bedrock, it returns back and goes to the next column.
* When the energy level is low, or the inventory is almost full, or the tool is about to break, robot drops the garbage, tries to refuel the internal generator (if there was a generator upgrade), and returns back to the starting position to recharge the tool and drop the loot into the chest.
* If there is a crafting upgrade in the robot, it will first compress some resources into blocks (e.g., redstone, lapis, diamonds).
* If the robot has the cunkloader upgrade, it will be turned on when the robots starts mining, and turned off when the robot is done.
* And, finally, if there's a linked card installed, the robot will send status messages when:
  * No chest was found.
  * The chest is full.
  * The block robot tries to mine, is indestructable, and is not a bedrock.
  * The robot is done mining.

## Links
* [The topic on the forums](http://computercraft.ru/topic/1510-)
* [Pastebin](http://pastebin.com/eFkAZP0u)
