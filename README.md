# OpenComputers Brewing Automation
A lua script that works in Minecraft's OpenComputers mod and helps with brewing automation.

This script was specifically developed for Enigmatica 2 Expert: Extended modpack v.1.26.0 by Krutoy242:
https://github.com/Krutoy242/Enigmatica2Expert-Extended

In this case the relevant version of Minecraft is 1.12.2 and OpenComputers is OpenComputers-MC1.12.2-1.8.3+274990f

<h3><strong>This script relies on Thaumcraft's elements readout to distinguish between potions <br> and likely will not work outside of the E2E:E modpack!!! </strong></h3>

# How to Install:
Download latest release folder. From .zip file extract contents of filesystem folder to the filesystem containing OpenOS on your ingame computer in minecraft.

To locate this folder you have to go to instances, a particular instance you use, then \saves\"save name"\opencomputers\"filesystem folder"

# How to use in game:

## Setup:
Build a computer and connect sevveral blocks to it in the following pattern using cables:

__|T| I |  
|A|B|T|O|

As seen from the side, where:
T - Transposer from Open Computers  
A - Adapter from OpenCOmputers  
I - Input Inventory  
O - OutputInventory  
B - Brewing stand

## Edit the files:
There several files that should be edited prior to runnig the script:  

### Recipes
*data\recipes.txt* - edit to add new recipe. the entry should be done like this:  

**Potion Name**,**Starter Potion Name**, **Alchimia Lvl for Starter Potion**,**Ingredient**

for example:  
Splash Potion of Healing,Potion of Healing,5,Gunpowder  

**Potion Name** can be anything you want as long as you recognize it  
**Starter Potion Name** is the Minecraft ingame name for the bottle you put at the bottom slots of brewing stand  
**Alchimia Lvl for Starter Potion** is th elevel of alchimia element of your starter potion. Fow water bottle use -1  
**Ingredient** is the ingrefient you put in the top slot of brewing stand  

If you add a custom potion make sure you add all the recipes of the starter potiosn as well down to the wate bottle as a starter potion.

Currently the list contains everything needed to brew the Splash Potion of Healing of the second level.

### PotionLib.lua
*lib\potionLib.lua* - edit the line  
*local ingredientChestSide = N* 
and change the number N to corresponding OpenComputers side to tell the direction that transposer above the brewing stand should use for the input chest  

### AutoBrew.lua
*home\AutoBrew.lua* - edit the lines  
*local inputSide = potionLib.findInventorySideByName(potionLib.invTransposer,"InputContainerName")*  
*local outputSide = potionLib.findInventorySideByName(potionLib.invTransposer,"OutputContainerName")*  

to the component name as seen by OpenComputers in game. To do that list the components before component is hooked up, then put the inventory down next to the transposer and list components again.
the script currently works only if two names are different, so use different component names for input and output  

## Running the script

Fill the brewing stand with blaze powder, fill the input inventory with required starter potions and ingredients and run:  

*autoBrew.lua*  from home directory

The script will ask you severla things:

1. A number corresponding to the potion you want to brew
2. A starter Potion to start with (this will be water if starting from scratch)
3. How many times to perform brewing operation. You will get 3x number of potions.

Your potions will be deposited into the output container once the script is finished.












