DROP PROCEDURE IF EXISTS `store_recharge`;
CREATE PROCEDURE `store_recharge`
(
IN
    userId INT(11),
    amount INT(11)
)

SQL SECURITY INVOKER BEGIN

    DECLARE errCode INT(11)     DEFAULT -1;
    DECLARE errMsgs VARCHAR(32) DEFAULT NULL;
    DECLARE myMoney INT(11)     DEFAULT -1;

    DECLARE EXIT handler FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            GET DIAGNOSTICS CONDITION 1
            errCode = RETURNED_SQLSTATE, errMsgs = MESSAGE_TEXT;
            SELECT errCode, errMsgs, myMoney;
        END;

    START TRANSACTION;

        /* UPDATE credits */
        UPDATE  `store_players`
        SET     `credits` = `credits` + amount
        WHERE   `id` = userId;

        IF (ROW_COUNT() <> 0) THEN
            
            /* REFRESHING */
            SET myMoney = (SELECT `credits` FROM `store_players` WHERE `id` = userId);

            /* LOGGING */
            INSERT INTO `store_newlogs`
            VALUES (DEFAULT, userId, myMoney, amount, 'recharge from website', UNIX_TIMESTAMP());

            /* Set callback */
            SET errCode = 0;

        ELSE 

            /* Telling failure */
            SET errCode = -1;
            SET errMsgs = "Failed to update player credits in table 'store_players'.";

        END IF;

    COMMIT;

    SELECT errCode, errMsgs, myMoney;

END;

DROP PROCEDURE IF EXISTS `store_transfer`;
CREATE PROCEDURE `store_transfer`
(
IN
    player INT(11),
    target INT(11),
    amount INT(11)
)

SQL SECURITY INVOKER BEGIN

    DECLARE errCode       INT(11)     DEFAULT -1;
    DECLARE errMsgs       VARCHAR(32) DEFAULT NULL;
    DECLARE playerCredits INT(11)     DEFAULT -1;
    DECLARE targetCredits INT(11)     DEFAULT -1;

    DECLARE EXIT handler FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            GET DIAGNOSTICS CONDITION 1
            errCode = RETURNED_SQLSTATE, errMsgs = MESSAGE_TEXT;
            SELECT errCode, errMsgs, playerCredits, targetCredits;
        END;

    START TRANSACTION;

        /* UPDATE credits */
        UPDATE  `store_players`
        SET     `credits` = `credits` - amount
        WHERE   `id` = player;

        IF (ROW_COUNT() > 0) THEN

            /* TARGETTING */
            UPDATE  `store_players`
            SET     `credits` = `credits` + amount
            WHERE   `id` = target;

            /* REFRESHING */
            SET playerCredits = (SELECT `credits` FROM `store_players` WHERE `id` = player);
            SET targetCredits = (SELECT `credits` FROM `store_players` WHERE `id` = target);

            /* LOGGING player */
            INSERT INTO `store_newlogs`
            VALUES (DEFAULT, player, playerCredits, CONCAT('-', amount), CONCAT('transfer', ' ' ,'To',   ' ', target), UNIX_TIMESTAMP());

            /* LOGGING target */
            INSERT INTO `store_newlogs`
            VALUES (DEFAULT, target, targetCredits, CONCAT('+', amount), CONCAT('transfer', ' ' ,'From', ' ', player), UNIX_TIMESTAMP());

            /* Set callback */
            SET errCode = 0;

        ELSE 

            /* Telling failure */
            SET errCode = -1;
            SET errMsgs = "Failed to update player credits in table 'store_players'.";

        END IF;

    COMMIT;

    SELECT errCode, errMsgs, playerCredits, targetCredits;

END;

DROP PROCEDURE IF EXISTS `store_purchase`;
CREATE PROCEDURE `store_purchase`
(
IN
    userId INT(11),
    typeId VARCHAR(32),
    uniqueId VARCHAR(32),
    price INT(11),
    expiration INT(11)
)

SQL SECURITY INVOKER BEGIN

    DECLARE errCode INT(11)     DEFAULT -1;
    DECLARE errMsgs VARCHAR(32) DEFAULT NULL;
    DECLARE logCost INT(11)     DEFAULT -1;
    DECLARE myMoney INT(11)     DEFAULT -1;
    DECLARE itemIdx INT(11)     DEFAULT -1;
    DECLARE itemsrt VARCHAR(32) DEFAULT "ITEM_SHORtNAME";

    DECLARE EXIT handler FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            GET DIAGNOSTICS CONDITION 1
            errCode = RETURNED_SQLSTATE, errMsgs = MESSAGE_TEXT;
            SELECT errCode, errMsgs, logCost, myMoney, itemIdx, itemsrt;
        END;

    START TRANSACTION;

        SET logCost = (SELECT `credits` FROM `store_players` WHERE `id` = userId);

        /* UPDATE credits */
        UPDATE  `store_players`
        SET     `credits` = `credits` - price
        WHERE   `id` = userId;

        IF (ROW_COUNT() > 0) THEN
            
            /* REFRESHING */
            SET myMoney = (SELECT `credits` FROM `store_players` WHERE `id` = userId);
            SET logCost = logCost - myMoney;

            /* INSERT item */
            INSERT INTO `store_items`
            VALUES (DEFAULT, userId, typeId, uniqueId, UNIX_TIMESTAMP(), expiration, price);

            /* Load item */
            SET itemsrt = (SELECT `name` FROM `store_item_child` WHERE `uid` = uniqueId);

            /* GET item index */
            SET itemIdx = LAST_INSERT_ID();

            /* LOGGING */
            INSERT INTO `store_newlogs`
            VALUES (DEFAULT, userId, myMoney, CONCAT('-', price), CONCAT('purchase item', ' ', '[', itemsrt, ']', '(', uniqueId, ')'), UNIX_TIMESTAMP());

            /* Set callback */
            SET errCode = 0;
        ELSE 

            /* Tell failure */
            SET errCode = -1;
            SET errMsgs = "Failed to update player credits in table 'store_players'.";

        END IF;

    COMMIT;

    SELECT errCode, errMsgs, logCost, myMoney, itemIdx, itemsrt;

END;

DROP PROCEDURE IF EXISTS `store_selling`;
CREATE PROCEDURE `store_selling`
(
IN
    userId INT(11),
    itemId INT(11),
    pPrice INT(11)
)

SQL SECURITY INVOKER BEGIN

    DECLARE errCode INT(11)     DEFAULT -1;
    DECLARE errMsgs VARCHAR(32) DEFAULT NULL;
    DECLARE myMoney INT(11)     DEFAULT -1;
    DECLARE itemUid VARCHAR(32) DEFAULT "ITEM_ERROR";
    DECLARE itemsrt VARCHAR(32) DEFAULT "ITEM_SHORtNAME";

    DECLARE EXIT handler FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            GET DIAGNOSTICS CONDITION 1
            errCode = RETURNED_SQLSTATE, errMsgs = MESSAGE_TEXT;
            SET errCode = -2;
            SELECT errCode, errMsgs, myMoney, itemUid, itemsrt;
        END;

    START TRANSACTION;

        /* Check item */
        SET itemUid = (SELECT `unique_id` FROM `store_items` WHERE `id` = itemId);

        /* UPDATE credits */
        UPDATE  `store_players`
        SET     `credits` = `credits` + pPrice
        WHERE   `id` = userId;

        IF (ROW_COUNT() > 0) THEN

            /* Remove item */
            DELETE FROM `store_items` WHERE `id` = itemId;

            /* Load item */
            SET itemsrt = (SELECT `name` FROM `store_item_child` WHERE `uid` = itemUid);

            /* REFRESHING */
            SET myMoney = (SELECT `credits` FROM `store_players` WHERE `id` = userId);

            /* LOGGING */
            INSERT INTO `store_newlogs`
            VALUES (DEFAULT, userId, myMoney, CONCAT('+', pPrice), CONCAT('selling item', ' ', '[', itemsrt, ']', '(', itemUid, ')'), UNIX_TIMESTAMP());

            /* Set callback */
            SET errCode = 0;

        ELSE 

            /* Tell failure */
            SET errCode = -1;
            SET errMsgs = "Failed to update player credits in table 'store_players'.";

        END IF;
        
    COMMIT;

    SELECT errCode, errMsgs, myMoney, itemUid, itemsrt;

END;

DROP PROCEDURE IF EXISTS `store_gifting`;
CREATE PROCEDURE `store_gifting`
(
IN
    player INT(11),
    target INT(11),
    itemId INT(11),
    crFees INT(11)
)

SQL SECURITY INVOKER BEGIN

    DECLARE errCode       INT(11)     DEFAULT -1;
    DECLARE errMsgs       VARCHAR(32) DEFAULT NULL;
    DECLARE playerCredits INT(11)     DEFAULT -1;
    DECLARE targetCredits INT(11)     DEFAULT -1;
    DECLARE itemUniqueId  VARCHAR(32) DEFAULT "ITEM_ERROR";
    DECLARE itemShortName VARCHAR(32) DEFAULT "ITEM_SHORtNAME";

    DECLARE EXIT handler FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            GET DIAGNOSTICS CONDITION 1
            errCode = RETURNED_SQLSTATE, errMsgs = MESSAGE_TEXT;
            SELECT errCode, errMsgs, itemUniqueId, itemShortName, crFees, target, itemId;
        END;

    START TRANSACTION;

        /* Update item */
        UPDATE `store_items` SET `player_id` = target WHERE `id` = itemId;

        IF (ROW_COUNT() > 0) THEN

            /* Update poundage */
            UPDATE  `store_players`
            SET     `credits` = `credits` - crFees
            WHERE   `id` = player;

            /* REFRESHING */
            SET playerCredits = (SELECT `credits`   FROM `store_players`    WHERE  `id` = player);
            SET targetCredits = (SELECT `credits`   FROM `store_players`    WHERE  `id` = target);
            SET itemUniqueId  = (SELECT `unique_id` FROM `store_items`      WHERE  `id` = itemId);
            SET itemShortName = (SELECT `name`      FROM `store_item_child` WHERE `uid` = itemUniqueId);

            /* LOGGING */
            INSERT INTO `store_newlogs`
            VALUES (DEFAULT, player, playerCredits, CONCAT('-', crFees), CONCAT('gifting item', ' ', '[', itemShortName, ']', '(', itemUniqueId, ')', ' ', 'To',   ' ', target), UNIX_TIMESTAMP());

            INSERT INTO `store_newlogs`
            VALUES (DEFAULT, target, targetCredits,                   0, CONCAT('gifting item', ' ', '[', itemShortName, ']', '(', itemUniqueId, ')', ' ', 'From', ' ', player), UNIX_TIMESTAMP());

            /* Set callback */
            SET errCode = 0;

        ELSE 

            /* Tell failure */
            SET errCode = -1;
            SET errMsgs = "Failed to update index of player in table 'store_items'.";

        END IF;
        
    COMMIT;

    SELECT errCode, errMsgs, itemUniqueId, itemShortName, crFees, target, itemId;

END;
