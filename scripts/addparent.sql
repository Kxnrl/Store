--
--  Add parent manually.
--
--  * sql script example *
INSERT INTO `store_item_parent` VALUES
(
    DEFAULT,
    '{name of parent}',             -- if > -1, display in store main menu.
    '{parent index}'                -- if = -1, display in root of store main menu.
);