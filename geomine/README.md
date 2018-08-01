# geomine
*A miner that uses the Geolyzer.*

## Developers
* Doob (a.k.a. Log on the oc.cil.li forums)

## Description
This programs uses the geolyzer to mine the ores efficiently.

### Launch
1. Place a robot.
2. Give a mining tool to robot (it's better to use an electric pickaxe or drill).
3. Place a chest and a charger (don't forget to turn the charger on, either
   by screnching it, or by placing a level on the block and flipping it).
4. Run the program (`geomine [columns] [height]`).
   * The `[columns]` argument determines how many 8×8 block columns to dig.
   * `[height]` is the maximum number of blocks by which the robot may descend.
5. Brew a cup of tea, sleep, or watch funny videos, as the robot may take
   several hours to finish.

### Requirements
* Inventory upgrades (the more you have, the less time the robot wastes on going
  back home to unload the inventory).
* An inventory controller upgrade.
* A geolyzer.
* Some tool to use for mining. As said earlier, it's better to use rechargeable
  tools.
* A hover upgrade.

Optional components:

* A crafting upgrade.
* A generator upgrade.
* A chunkloader upgrade.
* A linked card.

### Algorithm
1. The robot scans the 8×8 area in front of it.
2. Then it mines the blocks whose density is in the configured range.
3. If the robot reaches the bedrock level, it returns and proceeds to the next
   column.
4. Otherwise, it descends by a block, and goes back to step 1.
5. If the energy level is low, or the inventory is almost full, or the tool is
   about to break, robot drops the garbage, tries to refuel the internal
   generator (if it was assembled with a generator upgrade), and goes home to
   recharge the tool and drop the loot into the chest.
6. If the robot is built with a crafting upgrade, it packs some items into blocks
   (e.g., redstone, diamonds).
7. If the robot has a cunkloader upgrade, it's turned on when the robot starts
   mining, and turned off when the robot is done.
8. And, finally, if there's a linked card installed, the robot sends status
   messages if:
   * No chest was found.
   * The chest is full.
   * The block robot tries to mine is indestructable.
   * The program finishes.

## Links
* [The topic on the forums](http://computercraft.ru/topic/1510-)
* [Pastebin](http://pastebin.com/eFkAZP0u)
