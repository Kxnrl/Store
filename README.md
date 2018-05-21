# Store

**stable** : [![Build Status](https://img.shields.io/travis/Kxnrl/Store/master.svg?style=flat-square)](https://travis-ci.org/Kxnrl/Store?branch=master)

[![Download](https://csgogamers.com/static/image/download.png)](https://plugins.csgogamers.com/Store/)

This is a Redux version fully rewrite from [ZephStore](https://github.com/dvarnai/store-plugin/)
  
  
  
### Modules and Features:
* Chat ( Core included )  - Process player name tag, name color, chat color.
* Grenade ( Core included ) - When player throw a grenade, set nade model or add trail.
* Model ( Core included ) - Allow player use custom weapon instead of valve's model.
* VIP ( Core included ) - NOT effective, only add to store menu.
* TPMode ( Core included ) - Allow player change to third-person or mirror mode.
* Spray ( Core included ) - Allow player spray paint on object surface.
* Sound ( Core included ) - Allow player trigger server to broadcast a sound.
* Player ( Core included ) - NOT effective, is a base framework.
  * Aura ( Core included ) - Create a aura that follow the player.
  * Part ( Core included ) - Create a particle trail that follow the player.
  * None ( Core included ) - Create a neon effect that follow the player.
  * Skin ( Core included ) - Allow player use custom skin and custom arms. (death sound and firstperson-death support)
  * Hats ( Core included ) - Allow player wear hat/glass/facemask/shield/wing.
  * trail ( Core included ) - Create a material trail that follow the player.
* Pets ( optional ) - Create a pet that follow the player.
* WeaponSkin ( optional ) - Allow use valve weaon skin and knife skin. ***Will trigger GSLT ban***
  
  
### Commands:
* **sm_store** - Open store menu. [alias: ***buyammo1***/***sm_shop***/***sm_shop***]
* **sm_inv** - Open store menu as inventory mode. [alias: ***sm_inventory***]
* **sm_credits** - Show my credits to all players.
* **sm_hide** - Toggle -> hide all hats/pets/trails/neons, it will release your FPS. [alias: ***sm_hideneon***/***sm_hidetrail***]
* **cheer** - Trigger -> server play sound. [alias: ***sm_cheer***]
* **sm_crpb** - Toggle -> block cheer sound.
* **spray** - Trigger -> spary paint.
* **sm_tp** - Toggle -> third-person mode or first-person mode.
* **sm_seeme** - Toggle -> mirror mode or normal mode.
* **sm_arms** - (administator command) Fix player's arms.
  
  
### How to install
* Download latest build from https://plugins.csgogamers.com/Store/
* Extract all files on disk.
* Upload to server following folders: 
  * addons 
  * models ( optional )
  * materials ( optional )
  * particles ( optional )
  * sound ( optional )
* Import SQL table to your database. ( SQL scripts: addons/sourcemod/configs/database.sql )
* If you upgrade from original zeph store: 
  - Add "uid" key for each item in 'addons/sourcemod/configs/items.txt'.  
  - Upload 'addons/sourcemod/configs/items.txt' to your web host.  
  - Upload 'utils/insertitem.php', 'utils/loaditem.php', 'utils/kvphp.php' to your web host.  
  - Import item data to your database ( tools: utils/insertitem.php )
  - Check item validate ( tools: utils/loaditem.php )
* make sure your database.cfg ( path: addons/sourcemod/configs/database.cfg )
``` keyvalues
"csgo"
{
    "driver"    "mysql" // mysql support only
    "host"      "<HOSTNAME>"
    "database"  "<DATABASE>"
    "user"      "<USERNAME>"
    "pass"      "<PASSWORD>"
    "port"      "<PORT>"
}
```
* Start your server and check error logs
  
  
### How to add item or parent manually  
* Add Parent -> 'utils/addparent.sql'
* Add Item -> 'utils/additem.sql'
  
  
### License  
* SourceMod plugins license under GPLv3 License.  
* Shell, SQL and PHP scripts license under MIT License.  
* any other file :  you only can use WITHOUT commercial.  
  
  
### Special Thanks
[shanapu](https://github.com/shanapu "GitHub")  
[zipcore](https://github.com/zipcore "GitHub")  
  
  
### Credits:  
- Original Edition: [Zephyrus](https://github.com/dvarnai "GitHub")  
- FPVM_Interface: [franug](https://github.com/Franc1sco "GitHub")  
- Chat-Processor: [Drixevel](https://github.com/Drixevel "GitHub")  
- FirstPersonDeath: [Eun](https://forums.alliedmods.net/member.php?u=102471 "AlliedModders")  
- Spec Target Fix: [shufen](https://github.com/Xectali "GitHub")  
- Mirror mode: [franug](https://github.com/Franc1sco "GitHub") 
  
  
#### Any other questions
* **Steam** : https://steamcommunity.com/profiles/76561198048432253/
* **Telegram** : https://t.me/Kxnrl
  
  
#### Donate
* **Steam**: [Trade Offer](https://steamcommunity.com/tradeoffer/new/?partner=88166525&token=lszXBJeY)
* **AliPay**: h673321480[AT]163.com
