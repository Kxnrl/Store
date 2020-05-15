CREATE TABLE `store_players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `authid` varchar(32) NOT NULL,
  `name` varchar(64) NOT NULL,
  `credits` int(11) NOT NULL,
  `date_of_join` int(11) NOT NULL,
  `date_of_last_join` int(11) NOT NULL,
  `ban` int(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `authid` (`authid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4;


CREATE TABLE `store_opencase` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) unsigned NOT NULL DEFAULT '0',
  `unique` varchar(255) NOT NULL DEFAULT 'ERROR',
  `days` int(11) NOT NULL DEFAULT '0',
  `date` int(11) NOT NULL DEFAULT '0',
  `handle` varchar(16) NOT NULL DEFAULT 'ERROR',
  `type` tinyint(3) NOT NULL DEFAULT '1',
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4;


CREATE TABLE `store_newlogs` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `store_id` int(11) unsigned NOT NULL DEFAULT '0',
  `credits` int(11) NOT NULL DEFAULT '0',
  `difference` int(11) NOT NULL DEFAULT '0',
  `reason` varchar(256) NOT NULL DEFAULT 'unknown reason',
  `timestamp` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4;


CREATE TABLE `store_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `type` varchar(16) NOT NULL,
  `unique_id` varchar(32) NOT NULL DEFAULT '',
  `date_of_purchase` int(11) unsigned NOT NULL DEFAULT '0',
  `date_of_expiration` int(11) unsigned NOT NULL DEFAULT '0',
  `price_of_purchase` int(11) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `p` (`player_id`,`type`,`unique_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4;


CREATE TABLE `store_item_parent` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) DEFAULT NULL,
  `parent` tinyint(3) NOT NULL DEFAULT '-1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4;


CREATE TABLE `store_equipment` (
  `player_id` int(11) NOT NULL,
  `type` varchar(16) NOT NULL,
  `unique_id` varchar(128) NOT NULL DEFAULT '',
  `slot` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`player_id`,`type`,`slot`),
  KEY `key` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `store_item_child` (
  `parent` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '!parent!',
  `type` varchar(32) NOT NULL DEFAULT 'ITEM_ERROR' COMMENT '!type!',
  `uid` varchar(32) NOT NULL DEFAULT 'ITEM_ERROR',
  `buyable` bit(1) NOT NULL DEFAULT b'1' COMMENT '!buyable!',
  `giftable` bit(1) NOT NULL DEFAULT b'1' COMMENT '!giftable!',
  `only` bit(1) NOT NULL DEFAULT b'0' COMMENT '!only!',
  `auth` varchar(128) NOT NULL DEFAULT 'ITEM_NOT_PERSONAL' COMMENT '!personal!',
  `vip` bit(1) NOT NULL DEFAULT b'0' COMMENT '!vip!',
  `name` varchar(32) NOT NULL DEFAULT 'ITEM_UNNAMED' COMMENT '菜单显示的名字',
  `lvls` tinyint(2) NOT NULL DEFAULT '0' COMMENT 'playerskin level',
  `desc` varchar(32) NOT NULL DEFAULT 'ITEM_NO_DESC' COMMENT 'playerskin desc',
  `case` tinyint(3) NOT NULL DEFAULT '0' COMMENT 'playerskin open case only',
  `compose` bit(1) NOT NULL DEFAULT b'0' COMMENT 'playerskin compose only',
  `1d` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'credits/day',
  `1m` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'credits/month',
  `pm` varchar(255) NOT NULL DEFAULT '100000' COMMENT 'credits/perment',
  `model` varchar(192) NOT NULL DEFAULT 'ITEM_NO_MODEL' COMMENT 'playerskin|hat|nadeskin|vwmodel|pets',
  `arms` varchar(192) NOT NULL DEFAULT 'ITEM_NO_ARMS' COMMENT 'playerskin',
  `team` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT 'playerskin',
  `sound` varchar(192) NOT NULL DEFAULT 'ITEM_NO_SOUND' COMMENT 'playerskin|sound',
  `position` varchar(64) NOT NULL DEFAULT '0.0 0.0 0.0' COMMENT 'hat|pets',
  `angles` varchar(64) NOT NULL DEFAULT '0.0 0.0 0.0' COMMENT 'hat|pets',
  `attachment` varchar(32) NOT NULL DEFAULT 'ITEM_NO_ATTACHMENT' COMMENT 'hat',
  `slot` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT 'hat|vwmodel|weaponskin',
  `material` varchar(192) NOT NULL DEFAULT 'ITEM_NO_MATERIAL' COMMENT 'nadetrail|trail|spray',
  `color` varchar(32) NOT NULL DEFAULT 'ITEM_NO_COLOR' COMMENT 'nadetrail|trail|namecolor|msgcolor|neon',
  `grenade` varchar(32) NOT NULL DEFAULT 'ITEM_NO_GRENADE' COMMENT 'nadeskin',
  `shortname` varchar(32) NOT NULL DEFAULT 'ITEM_NO_SHORTNAME' COMMENT 'sound',
  `volume` float(2,1) unsigned NOT NULL DEFAULT '1.0' COMMENT 'sound',
  `cooldown` tinyint(3) unsigned NOT NULL DEFAULT '60' COMMENT 'sound',
  `worldmodel` varchar(192) NOT NULL DEFAULT 'ITEM_NO_WORLDMODEL' COMMENT 'vwmodel',
  `dropmodel` varchar(192) NOT NULL DEFAULT 'ITEM_NO_DROPMODEL' COMMENT 'vwmodel',
  `weapon` varchar(32) NOT NULL DEFAULT 'ITEM_NO_ENTITY' COMMENT 'vwmodel|weaponskin',
  `effect` varchar(32) NOT NULL DEFAULT 'ITEM_NO_EFFECT' COMMENT 'arua|particle',
  `brightness` tinyint(2) unsigned NOT NULL DEFAULT '5' COMMENT 'neon',
  `distance` tinyint(3) unsigned NOT NULL DEFAULT '150' COMMENT 'neon',
  `distancefade` tinyint(3) unsigned NOT NULL DEFAULT '50' COMMENT 'neon',
  `tag` varchar(32) NOT NULL DEFAULT 'ITEM_NO_TAG' COMMENT 'nametag',
  `idle` varchar(32) NOT NULL DEFAULT 'ITEM_NO_IDLE' COMMENT 'pet',
  `run` varchar(32) NOT NULL DEFAULT 'ITEM_NO_RUN' COMMENT 'pet',
  `death` varchar(32) NOT NULL DEFAULT 'ITEM_NO_DEATH' COMMENT 'pet',
  `seed` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT 'weaponskin',
  `weart` tinyint(3) NOT NULL DEFAULT '-1' COMMENT 'weaponskin',
  `paint` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT 'weaponskin',
  `wearf` float(7,6) unsigned NOT NULL DEFAULT '0.01' COMMENT 'weaponskin',
  PRIMARY KEY (`type`,`uid`),
  KEY `p` (`parent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- if u upgrade from 2.0, exec this in your database
ALTER TABLE `store_item_child`
ADD `idle` varchar(32) NOT NULL DEFAULT 'ITEM_NO_IDLE' COMMENT 'pet',
ADD `run` varchar(32) NOT NULL DEFAULT 'ITEM_NO_RUN' COMMENT 'pet',
ADD `death` varchar(32) NOT NULL DEFAULT 'ITEM_NO_DEATH' COMMENT 'pet',
ADD `seed` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT 'weaponskin',
ADD `weart` tinyint(3) NOT NULL DEFAULT '-1' COMMENT 'weaponskin',
ADD `paint` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT 'weaponskin',
ADD `wearf` float(7,6) unsigned NOT NULL DEFAULT '0.01' COMMENT 'weaponskin';

-- if u upgrade from 2.2
ALTER TABLE `store_item_child`
MODIFY `case` TINYINT(2) DEFAULT 0 NOT NULL;

-- upgrade 2.3 pet
ALTER TABLE `store_item_child` ADD COLUMN `scale` FLOAT(4,2) unsigned NOT NULL DEFAULT '1.0' COMMENT 'pet' AFTER `death`;
ALTER TABLE `store_item_child` ADD COLUMN `idle2` varchar(32) NOT NULL DEFAULT 'ITEM_NO_IDLE2' COMMENT 'pet' AFTER `idle`;
ALTER TABLE `store_item_child` ADD COLUMN `spawn` varchar(32) NOT NULL DEFAULT 'ITEM_NO_SPAWN' COMMENT 'pet' AFTER `idle2`;

CREATE TABLE `store_compose` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `store_id` int(11) unsigned NOT NULL,
  `selected_item` varchar(32) NOT NULL,
  `item1` varchar(32) NOT NULL,
  `item2` varchar(32) NOT NULL,
  `result` tinyint(3) unsigned NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;