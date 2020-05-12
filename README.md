# Store

|Build Status|Download|
|---|---
|[![Build Status](https://travis-ci.com/Kxnrl/Store.svg?branch=master)](https://travis-ci.com/Kxnrl/Store) |[![Download](https://static.kxnrl.com/images/web/buttons/download.png)](https://build.kxnrl.com/Store/)  
  
  
A sourcemod in-game Store system. 
  
  
  
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
  * Skin ( Core included ) - Custom player skin and arms. (death sound and firstperson-death support)
  * Hats ( Core included ) - Allow player wear hat/glass/facemask/shield/wing.
  * trail ( Core included ) - Create a material trail that follow the player.
* Pets ( optional ) - Create a pet that follow the player.
* WeaponSkin ( optional ) - Allow use valve weaon skin and knife skin. ***Will trigger GSLT ban***
* DefaultSkin (Optional) - Set player skin if player does not equip player skin. ***Requires Skin module***
  
  
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
* [Download](https://build.kxnrl.com/Store/) latest build.
* Extract all files on disk.
* Upload to server following folders: 
  * addons 
  * models ( optional )
  * materials ( optional )
  * particles ( optional )
  * sound ( optional )
* Selete store_(GameMode).smx, and rename it to store.smx, others must be deleted. ***install 1 only***
* Import SQL table to your database. ( SQL scripts: addons/sourcemod/configs/database.sql )
* If you upgrade from original zeph store: 
  - Add "uid" key for each item in 'addons/sourcemod/configs/items.txt'.  
  - Upload 'addons/sourcemod/configs/items.txt' to your web host.  
  - Upload 'utils/insertParent.php', 'utils/insertItem.php', 'utils/loaditem.php', 'utils/kvphp.php' to your web host.  
  - Import parent data to your database. ( exec: php insertParent.php or goto: yourwebserver/insertParent.php )
  - Import item data to your database. ( exec: php insertItem.php or goto: yourwebserver/insertItem.php )
  - Check item validate ( exec: php loaditem.php or goto: yourwebserver/loaditem.php )
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
  
  
### How to upgrade store from zephyrus store
* Delete your old store database table, but keep store_players and store_items.  
* Run SQL command before install our store.  
``` SQL
ALTER TABLE `store_players` ADD `ban` int(1) unsigned NOT NULL DEFAULT '0';  
```
* Install our store follow install guide, but DON'T create new store_players and store_items tables. 
* Uninstall zephyrus store plugins, if you want you use modules, keep these plugins.  
  
  
### How to define new game mode
* Add definetion after line 
``` sourcepawn
#define <Compile_Environment>
```
e.g. "//GM_BR -> battle royole server"
* Enable module you want
``` sourcepawn
// Module Skin
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/modules/skin.sp"
#endif
```
to
``` sourcepawn
// Module Skin
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH || defined GM_BR
#include "store/modules/skin.sp"
#endif
``` 
  
  
### How to add item or parent manually  
* Add Parent -> 'utils/addparent.sql'
* Add Item -> 'utils/additem.sql'
  
  
### For developer
* utils/additem.sql -> Add item via SQL command.
* utils/addparent.sql -> Add parent via SQL command.
* utils/insertItem.php -> Import items from items.txt.
* utils/insertParent.php -> Import parents from items.txt.
* utils/loaditem.php -> Verify items in SQL database.
* website/config.php -> Configs of website API.
* website/example.php -> An example of website-API.
* website/store.class.php -> Store web-API.
  
  
### Database Fields
- store_player
  * id -> Store Id -> int32
  * authid -> Steam Id 2 replace with STEAM_X: -> string (32)
  * name -> Player steam nick name -> string (32)
  * credits -> Player credits in back -> int32
  * date_of_join -> Date of player first join server -> int32
  * date_of_last_join -> Date of player last seen -> int32
  * ban -> Banning State -> bit 0/1
- store_opencase
  * Id -> Case Id -> int32
  * player_id -> Store Id of player -> uint32
  * unique -> Item Unique Id of item that player found in case -> string (32)
  * days -> Article validity period -> int32
  * date -> Time stamp -> int32
  * handle -> Player handle after opening case -> 'add' or 'sell' -> string (32)
  * type -> Type of case -> uint (3)
- store_newlogs
  * Id -> Logging Id -> int32
  * store_id -> Store Id of player -> uint32
  * credits -> Credits after changing -> int32
  * difference -> Amount of credits to change -> int32
  * reason -> Reson of chaning credis -> string (256)
  * timestamp -> Time stamp -> uint32
- store_items
  * id -> Item Id -> int32
  * player_id -> Item owner Store Id -> int32
  * type -> Type set of Item -> string (32)
  * unique_id -> Item Unique Id -> string (32)
  * date_of_purchase -> Time stamp of player purchased item date -> uint32
  * date_of_expiration -> Time stamp of expiration -> uint32
  * price_of_purchase -> Price of purchasing item -> uint32
- store_equipment
  * player_id -> Player Store Id -> uint32
  * type -> Type set of item -> string (32)
  * unique_id -> Item Unique Id -> string (32)
  * slot -> slot of Item -> uint (3)
- store_item_parent
  * id -> Category Id -> int32
  * name -> Category name -> string (32)
  * parent -> Parent category Id -> uint (3)
- store_item_child
  * parent -> Item of category Id -> uint (3)
  * type -> Type set of Item -> string (32)
  * uid -> Item Unique Id -> string (32)
  * buyable -> Allow buy this Item -> bit 0/1
  * giftable -> Allow gift this Item -> bit 0/1
  * only -> Disallow purchase/open case/compose/selling/Vip -> bit 0/1
  * auth -> Auth Id of this Item (If not null, item is personal item) -> string (128)
  * vip -> Vip Item -> bit 0/1
  * name -> Item name -> string (32)
  * lvls -> Item level (only for playerskin) -> int (2)
  * desc -> Item description -> string (32)
  * case -> Open case -> int (3) -1~2  // -1 == remove from case | 0 = all case+ | 1 = adv case+ | 2 = ult case+
  * compose -> Disallow purchase, compose acquisition -> bit 0/1
  * 1d -> Price of 1 day -> uint32 // 0 to disallow
  * 1m -> Price of 1 month -> uint32 // 0 to disallow
  * pm -> Price of permanent -> uint32 // 0 to disallow | if 1d/1m/pm = 0 Item is free
  * model -> Item attribute -> string (192)
  * arms -> Item attribute -> string (192)
  * team -> Item attribute -> uint (2)
  * sound -> Item attribute -> string (192)
  * position -> Item attribute -> string (64)
  * angles -> Item attribute -> string (64)
  * attachment -> Item attribute -> string (32)
  * slot -> Item attribute -> uint (2)
  * material -> Item attribute -> string (192)
  * color -> Item attribute -> string (32)
  * grenade -> Item attribute -> string (32)
  * shortname -> Item attribute -> string (32)
  * volume -> Item attribute -> float (2,1)
  * cooldown -> Item attribute -> uint (3)
  * worldmodel -> Item attribute -> string (192)
  * dropmodel -> Item attribute -> string (192)
  * weapon -> Item attribute -> string (32)
  * effect -> Item attribute -> string (32)
  * brightness -> Item attribute -> uint (2)
  * distance -> Item attribute -> uint (3)
  * distancefade -> Item attribute -> uint (3)
  * tag -> Item attribute -> string (32)
  * idle -> Item attribute -> string (32)
  * run -> Item attribute -> string (32)
  * death -> Item attribute -> string (32)
  * seed -> Item attribute -> uint (5)
  * weart -> Item attribute -> uint (3)
  * paint -> Item attribute -> uint (5)
  * wearf -> Item attribute -> float (7,6)
  
  
### License  
* SourceMod plugins license under GPLv3 License.  
* Shell, SQL and PHP scripts license under MIT License.  
* any other file :  Non-commercial use.  
  
  
### Special Thanks
[shanapu](https://github.com/shanapu "GitHub")  
[zipcore](https://github.com/zipcore "GitHub")  
  
  
### Credits:  
- Original Store: [Zephyrus](https://github.com/dvarnai "GitHub")  
- FPVM_Interface: [franug](https://github.com/Franc1sco "GitHub")  
- Chat-Processor: [Drixevel](https://github.com/Drixevel "GitHub")  
- FirstPersonDeath: [Eun](https://forums.alliedmods.net/member.php?u=102471 "AlliedModders")  
- Spec Target Fix: [shufen](https://github.com/Xectali "GitHub")  
- Mirror mode: [franug](https://github.com/Franc1sco "GitHub") 
- Weapon Skin: [kaganus](https://github.com/kaganus "GitHub") 
  
  
#### Any other questions
* [Steam](https://steamcommunity.com/profiles/76561198048432253/)
* [Telegram](https://t.me/Kxnrl)
  
  
#### Donate
* [Steam Trade Offer](https://steamcommunity.com/tradeoffer/new/?partner=88166525&token=lszXBJeY)
* **AliPay**: h673321480[AT]163.com
* **Paypal**: 673321480[AT]qq.com
