# A Deadtalk Plugin for CS:GO
### Status: Working
![Github All Releases](https://img.shields.io/github/downloads/bazooka-codes/csgo-deadtalk-plugin/total)

Deadtalk is a function in which dead players can talk to all other dead players in server including the other team's dead players, while the living players cannot hear them. The only custom dependency is interrogate.inc, from my other plugin, so that interrogations do not break deadtalk. This plugin contains two seperate running versions of deadtalk. The first and named just "deadtalk" runs as would be expected where the entire server either has deadtalk or doesn't. I also developed another version named "deadtalk_player" which allows players to turn deadtalk on or off. The preference will save using clientprefs, and has notifications baked in. With this version, dead players in deadtalk will not be able to hear those dead with deadtalk disabled and vice versa. The player-based version will be less used, but since I developed it, I will let the option to you if you want to use it.

## Releases
This plugin has multiple versions that operate differently, if the current version does not fit your specifications, check the releases for different versions. I will consider modifications if you contact me personally.

## WiT Gaming Version
This version incorporates specifically requested features and options to correspond to WiT Gaming CS:GO community servers. This means that some functionality may be unwanted for general use, so use the general-use version. If you would like to incorporate your own branding, options, and features: get in contact with me through pull request or email: bazookaforreal@gmail.com.

## Compilation
Compiles normally using the Sourcemod compiler, within the scripting directory, but must include Multicolors and interrogate.inc within the includes directory. 

  Both download and online compiler can be found here: https://www.sourcemod.net/compiler.php
  Multicolors can be found here: https://github.com/Bara/Multi-Colors or included
