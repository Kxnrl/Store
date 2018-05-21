--
-- WARNING: If some attributes are not set, replace them with "ITEM_NO_{attributes name}"
--

--
--  Add playerskin manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `lvls`,
    `desc`,
    `case`,
    `compose`,
    `1d`,
    `1m`,
    `pm`,
    `model`,
    `arms`,
    `team`,
    `sound`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'playerskin',                               -- force to 'playerskin'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'DEFAULT',                                  -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{Skin level}',                             -- range 1~6 -> look like csgo skin level. 0 = Normal, 6 = Contraband
    '{Item descriptionr in store main menu}',   -- maxlen 128 bytes
    '0',                                        -- 1 = only found in case
    '0',                                        -- 1 = only found in case or compose skin
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{model path}',                             -- e.g. "models/player/custom_player/maoling/hongkai_impact3/kiana/kiana.mdl"
    '{arms model path}',                        -- e.g. "models/player/custom_player/maoling/hongkai_impact3/kiana/kiana_arms.mdl"
    '{CS_TEAM Index}',                          -- 3 = CT, 2 = TE, must be 2~3, if #defind global model, allow both team
    '{Death sound path}'                        -- e.g. "maoling/deathsound/purpleheart.mp3"
);



--
--  Add hat/wings/shield manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `model`,
    `position`,
    `angles`,
    `attachment`,
    `slot`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'hat',                                      -- force to 'hat'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{model path}',                             -- e.g. "models/maoling/wings/kiana/kiana_wings.mdl"
    '{position of player}',                     -- e.g. "-13.500000 1.000000 -5.500000"
    '{angles of player}',                       -- e.g. "0.500000 250.000000 -87.500000"
    '{attachment name}',                        -- e.g. "facemask"
    '{Store unique Slot}'                       -- range 1 ~ 6
);



--
--  Add nadetrail manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `material`,
    `color`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'nadetrail',                                -- force to 'nadetrail'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{material path}',                          -- e.g. "materials/sprites/laserbeam.vmt"
    '{color}'                                   -- RGBA -> e.g. "255 235 205 255"
);



--
--  Add nadeskin manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `model`,
    `grenade`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'nadeskin',                                 -- force to 'nadeskin'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{model path}',                             -- e.g. "models/props/cs_italy/bananna.mdl"
    '{grenade classname}'                       -- RGBA -> e.g. "flashbang"
);



--
--  Add models manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `slot`,
    `model`,
    `worldmodel`,
    `dropmodel`,
    `weapon`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'hat',                                      -- force to 'hat'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{Store unique Slot}'                       -- range 1 ~ 6
    '{view model path}',                        -- e.g. "models/maoling/weapon/overwatch/knife/genji/katana_v.mdl"
    '{world model path}',                       -- e.g. "models/maoling/weapon/overwatch/knife/genji/katana_w.mdl"
    '{drop model path}',                        -- e.g. "models/maoling/weapon/overwatch/knife/genji/katana_d.mdl"
    '{weapon classname}'                        -- e.g. "weapon_knife"
);



--
--  Add sound manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `sound`,
    `shortname`,
    `volume`,
    `cooldown`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'sound',                                    -- force to 'sound'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{sound path}',                             -- e.g. "maoling/store/overwatch/genji.mp3"
    '{shortname displayed in chat}',            -- e.g. "Cheer Sound #1"
    '{volume}',                                 -- range 0.0~1.0
    '{cooldown in seconds}'                     -- cooldown time in second
);



--
--  Add trail manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `slot`,
    `material`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'trail',                                    -- force to 'trail'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{Store unique Slot}',                      -- range 1 ~ 6
    '{material path}'                          -- e.g. "materials/maoling/trails/huaji.vmt"
);



--
--  Add aura/part manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `effect`,
    `model`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    '{type}',                                   -- force to 'part' or 'aure'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{effect name}',                            -- e.g. "materials/maoling/trails/huaji.vmt"
    '{path of particles}'                       -- e.g. "particles/FX.pcf"
);



--
--  Add neon manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `color`,
    `brightness`,
    `distance`,
    `distancefade`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'neon',                                     -- force to 'neon'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{color}',                                  -- RGBA e.g. "59 197 187 233"
    '{intensity of the spotlight}',             -- range 0 ~ 16
    '{light is allowed to cast, in inches}',    -- range 1 ~ 9999
    '{the radius of the light, in inches}'      -- range 1 ~ 9999
);



--
--  Add msgcolor/namecolor manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `color`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    '{type}',                                   -- force to 'msgcolor' or 'namecolor'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{color}'                                   -- colors define in store_stock.inc. e.g. "{blue}"
);



--
--  Add nametag manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `color`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'nametag',                                  -- force to 'nametag'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{tag}'                                     -- tag with color support. e.g. "[{lightblue}_(:з」∠)_{teamcolor}]"
);



--
--  Add pet manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `model`,
    `idle`,
    `run`,
    `death`,
    `position`,
    `angles`,
    `slot`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'nametag',                                  -- force to 'nametag'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{moedl path}',                             -- e.g. "models/maoling/pets/overwatch/genji.mdl"
    '{animation name of idle}',                 -- e.g. "idle"
    '{animation name of run}',                  -- e.g. "running"
    '{animation name of death}',                -- e.g. "dead"
    '{position of player}',                     -- e.g. "-13.500000 1.000000 -5.500000"
    '{angles of player}',                       -- e.g. "0.500000 250.000000 -87.500000"
    '{Store unique Slot}'                       -- range 1 ~ 6
);



--
--  Add weaponskin manually.
--
--  * sql script example *
INSERT INTO `store_item_child`
(
    `parent`,
    `type`,
    `uid`,
    `buyable`,
    `giftablle`,
    `only`,
    `auth`,
    `vip`,
    `name`,
    `1d`,
    `1m`,
    `pm`,
    `weapon`,
    `paint`,
    `seed`,
    `weart`,
    `wearf`,
    `slot`
)
VALUES
(
    '{YOUR PARENT ID FROM store_item_parent}',  -- parten id
    'nametag',                                  -- force to 'nametag'
    '{unique_identifier}',                      -- maxlen 32 bytes
    '1',                                        -- 1 = can buy
    '1',                                        -- 1 = can gift
    '0',                                        -- 1 = not included in opening case system.
    'ITEM_NOT_PERSONAL',                        -- if personal item, set to steamid , e.g. "STEAM_1:1:44083262,"
    '0',                                        -- 1 = free for VIP user
    '{Item name in store main menu}',           -- maxlen 64 bytes
    '{price of 1 day}',                         -- credits
    '{price of 1 month}',                       -- credits
    '{price of permanent}',                     -- credits
    '{weapon classname}',                       -- e.g. "weapon_bayonet"
    '{paint index}',                            -- e.g. "416"
    '{seed index}',                             -- e.g. "416"
    '{wear type}',                              -- range -1 ~ 4, -1 = disable and using wearf value, 0 = fn, 1 = mw, 2 = ft, 3 = ww, 4 = bs
    '{wear value}',                             -- if wear type set to -1, it will work. range 0.0~0.999999
    '{Store unique Slot}'                       -- range 1 ~ 6
);