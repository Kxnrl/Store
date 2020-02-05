<?php

namespace Store;

require_once 'Config.php';
require_once 'Exception.php';
require_once 'SteamID.php';

use Kxnrl\DatabaseException;
use Kxnrl\StoreException;
use mysqli;
use \SteamID;

class Store
{
    protected $dbConnection;

    public $parents;
    public $items;
    public $Store;

    public function __construct()
    {
        global $_config;
        $_config['mysql']['port'] = intval($_config['mysql']['port']);
        $this->dbConnection = new mysqli($_config['mysql']['host'], $_config['mysql']['user'], $_config['mysql']['pswd'], $_config['mysql']['name'], $_config['mysql']['port']);

        if ($this->dbConnection->connect_errno) {
            throw new DatabaseException('Failed to connect to database: ' . $this->dbConnection->connect_error);
        }

        if (!$this->dbConnection->set_charset('utf8mb4')) {
            $this->Destroy();
            throw new DatabaseException('Failed to Set SQL chatset to utf8mb4: ' . $this->dbConnection->error);
        }
    }

    public function Destroy()
    {
        $this->dbConnection->close();
    }

    public function getPlayers($sortMode = 0, $desc = false, $limit = 2147483647)
    {
        // sort_by_playerId  = 0;
        // sort_by_credits   = 1;
        // sort_by_firstJoin = 2;
        // sort_by_lastseen  = 3;
        switch($sortMode) 
        {
            case 0: $quota = 'id';                break;
            case 1: $quota = 'credits';           break;
            case 2: $quota = 'date_of_join';      break;
            case 3: $quota = 'date_of_last_join'; break;
            default:  throw new StoreException('Invalid sort mode given: sortMode' . $sortMode);
        }

        $sort = $desc ? "DESC" : "ASC";

        if (!($result = $this->dbConnection->query('SELECT * FROM `store_players` ORDER BY ' . $quota . ' ' . $sort . ' LIMIT ' . $limit . ';'))) {
            throw new DatabaseException('Failed to load players from database: ' . $this->dbConnection->error);
        }

        $players = [];

        while($row = $result->fetch_array(MYSQLI_ASSOC)) {
            $player = [
                'id'        => $row['id'],
                'authId'    => $row['authid'],
                'name'      => $row['name'],
                'credits'   => $row['credits'],
                'firstJoin' => $row['date_of_join'],
                'lastSeen'  => $row['date_of_last_join'],
                'banned'    => $row['ban']
            ];

            $players[] = $player;
        }

        $result->free();

        return $players;
    }

    public function getParents()
    {
        if ($this->parents !== null) {
            return $this->parents;
        }

        if (!($result = $this->dbConnection->query('SELECT * FROM `store_item_parent` ORDER BY `id` ASC;'))) {
            throw new DatabaseException('Failed to load parents from database: ' . $this->dbConnection->error);
        }

        $parents = [];

        while($row = $result->fetch_array(MYSQLI_ASSOC)) {
            $parent = [
                'id'         => $row['id'],
                'name'       => $row['name'],
                'parent'     => $row['parent'],
                'parentName' => intval($row['parent']) == -1 ? 'Category' : $parents[intval($row['parent'])]['name']
            ];

            $parents[] = $parent;
        }

        $result->free();

        $this->parents = $parents;

        return $parents;
    }

    public function getItems()
    {
        if ($this->items !== null) {
            return $this->items;
        }

        $parents = $this->getParents();

        if (!($result = $this->dbConnection->query('SELECT * FROM `store_item_child` ORDER BY `parent` ASC;'))) {
            throw new DatabaseException('Failed to load items from database: ' . $this->dbConnection->error);
        }

        $items = [];

        while($row = $result->fetch_array(MYSQLI_ASSOC)) {
            foreach($row as $r => $w) {
                if (strstr($w, 'ITEM_NO') != false || strstr($w, '0.0 0.0 0.0') != false || is_numeric($r)) {
                    //echo $row['name']." -> ".$r." was not found.\n";
                    unset($row[$r]);
                }
            }

            $row['parentName'] = $parents[intval($row['parent'])]['name'];
            $items[] = $row;
        }

        $result->free();

        $this->items = $items;

        return $items;
    }

    public function getStore()
    {
        if ($this->Store !== null) {
            return $this->Store;
        }

        if (!($result = $this->dbConnection->query('SELECT * FROM `store_item_parent` ORDER BY `id` ASC;'))) {
            throw new DatabaseException('Failed to load parents from database: ' . $this->dbConnection->error);
        }

        $store  = [];
        $parent = [];

        while($row = $result->fetch_array(MYSQLI_ASSOC)) {
            $parent[] = $row;
        }

        $result->free();

        if (!($result = $this->dbConnection->query('SELECT * FROM `store_item_child` ORDER BY `parent` ASC;'))) {
            throw new DatabaseException('Failed to load items from database: ' . $this->dbConnection->error);
        }

        while($row = $result->fetch_array(MYSQLI_ASSOC)) {
            foreach ($parent as $k => $v) {
                if ($v['id'] == $row['parent']) {
                    $row['catelogy'] = $v['name'];
                }
            }

            foreach ($row as $r => $w) {
                if (strstr($w, 'ITEM_NO') != false || strstr($w, '0.0 0.0 0.0') != false || is_numeric($r)) {
                    //echo $row['name']." -> ".$r." was not found.\n";
                    unset($row[$r]);
                }
            }

            if (!isset($row['catelogy'])) {
                echo $row['name'] . " has not found parent\n";
            }

            $store[] = $row;
        }

        $result->free();

        $this->Store = $store;

        return $store;
    }
}

class Player extends Store
{
    public $playerId;
    public $playerCredits;

    public function __construct($userId)
    {
        parent::__construct();

        if (!is_numeric($userId) || $userId >= 76561100000000000) {
            try {
                $CSteamID = new SteamID($userId);
                $steam2Id = str_replace(['STEAM_0:', 'STEAM_1:'], '', $CSteamID->RenderSteam2());
            } catch(InvalidArgumentException $e) {
                $this->Destroy();
                throw new StoreException('Invalid SteamId: ' . $userId);
            }

            if (!($result = $this->dbConnection->query("SELECT `id`,`credits` FROM `store_players` WHERE `authid` = '$steam2Id' LIMIT 1;"))) {
                throw new DatabaseException('Failed to load playerId from database: ' . $this->dbConnection->error);
            }

            if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
                throw new DatabaseException('Failed to fetch playerId from array.' . "SELECT `id`,`credits` FROM `store_players` WHERE `authid` = '$steam2Id' LIMIT 1;");
            }

            $this->playerId = $row['id'];
            $this->playerCredits = $row['credits'];

            if ($this->playerId < 0) {
                throw new StoreException('Invalid store playerId: ' . $this->playerId);
            }

            $result->free();
        }
    }

    public function Destroy()
    {
        parent::Destroy();
    }

    public function recharge($credits)
    {
        if (!($result = $this->dbConnection->query("CALL `store_recharge` ('" . $this->playerId . "', '" . $credits . "');"))) {
            throw new DatabaseException("Failed to query from database: " . $this->dbConnection->error);
        }

        if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
            throw new DatabaseException('Failed to fetch from sql query: ' . $this->dbConnection->error);
        }

        $result->free();
        $this->dbConnection->next_result();

        if ($row['errCode'] < 0) {
            throw new StoreException('Failed to handle recharging -> errCode: ' . $row['errCode'] . '  errMsgs: ' . $row['errMsgs']);
        }

        $this->playerCredits += $credits;

        return $this->playerCredits;
    }

    public function transfer($userId, $credits)
    {
        if (!is_numeric($userId) || $userId >= 76561100000000000) {

            $CSteamID = new SteamID($userId);
            $steam2Id = str_replace(['STEAM_0:', 'STEAM_1:'], "", $CSteamID->RenderSteam2());

            if (!($result = $this->dbConnection->query("SELECT `id`,`credits` FROM `store_players` WHERE `authid` = '" . $steam2Id . "' LIMIT 1;"))) {
                throw new DatabaseException('Failed to load playerId from database: ' . $this->dbConnection->error);
            }

            if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
                throw new DatabaseException('Failed to fetch playerId from array.');
            }

            $result->free();

            $playerId = $row['id'];
            $playerCredits = $row['credits'];

            if ($playerId < 0) {
                throw new StoreException('Invalid store playerId: ' . $playerId);
            }
        } else {
            $playerId = $userId;
        }

        if (!($result = $this->dbConnection->query("CALL `store_transfer` ('" . $this->playerId . "', '" . $playerId . "', '" . $credits . "');"))) {
            throw new DatabaseException('Failed to query from database: ' . $this->dbConnection->error);
        }

        if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
            throw new DatabaseException('Failed to fetch from sql query: ' . $this->dbConnection->error);
        }

        if ($row['errCode'] != 0) {
            throw new StoreException('Failed to handle transferring -> errCode: ' . $row['errCode'] . '  errMsgs: ' . $row['errMsgs']);
        }

        $result->free();
        $this->dbConnection->next_result();

        $this->playerCredits = $row['playerCredits'];
        
        return $row['targetCredits'];
    }

    public function purchase($unique_id, $Purchase_Type = 0, $vip = false)
    {
        // validating item id?
        if (!($result = $this->dbConnection->query("SELECT * FROM `store_item_child` WHERE `uid` = '" . $unique_id . "';")) || !($row = $result->fetch_array(MYSQLI_ASSOC))) {
            throw new DatabaseException('Failed to query from database: ' . $this->dbConnection->error);
        }

        $result->free();

        $price = 999999999;
        $expir = time();

        // Purchase_1D = 0;
        // Purchase_1M = 1;
        // Purchase_PM = 2;
        switch($Purchase_Type)
        {
            case 0: $price = $row['1d']; $expir += 86400;   break;
            case 1: $price = $row['1m']; $expir += 2592000; break;
            case 2: $price = $row['pm']; $expir = 0;        break;
            default: throw new StoreException('Wrong value -> date of purchase');
        }

        if (strcmp($row['auth'], 'ITEM_NOT_PERSONAL') != 0) {
            throw new StoreException('Wrong item to purchase: this item is personal exclusivity item.');
        }

        if ($row['vip'] != 0 && !$vip) {
            throw new StoreException('Wrong item to purchase: this item is vip exclusivity item.');
        }

        if ($row['buyable'] == 0) {
            throw new StoreException('Wrong item to purchase: this item is not purchasable.');
        }

        if ($this->playerCredits < $price) {
            throw new StoreException('You have no enough credits to purchase this item -> '. $row['name']);
        }

        $type = $row['type'];

        if (!($result = $this->dbConnection->query("CALL `store_purchase` ('" . $this->playerId . "', '" . $type . "', '" . $unique_id . "', '" . $price . "', '" . $expir . "');"))) {
            throw new DatabaseException('Failed to query from database: ' . $this->dbConnection->error);
        }

        if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
            throw new DatabaseException('Failed to fetch from sql query: ' . $this->dbConnection->error);
        }

        if ($row['errCode'] != 0) {
            throw new StoreException('Failed to handle purchasing -> errCode: ' . $row['errCode'] . '  errMsgs: ' . $row['errMsgs']);
        }

        $result->free();
        $this->dbConnection->next_result();

        $this->playerCredits = $row['myMoney'];

        return $row['itemIdx'];
    }

    public function sellcheck($unique_id)
    {
        $quota = is_numeric($unique_id) ? 'id' : 'unique_id';

        if (!($result = $this->dbConnection->query("SELECT * FROM `store_items` WHERE `player_id` = '" . $this->playerId . "' AND `" . $quota . "` = '" . $unique_id . "' LIMIT 1;"))) {
            throw new DatabaseException('Failed to load itemIndex from database: ' . $this->dbConnection->error);
        }

        if ($result->num_rows == 0) {
            throw new StoreException('Player has not this item -> ' . $unique_id);
        }

        if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
            throw new DatabaseException('Failed to fetch itemIndex from array.');
        }

        global $_config;
        $_config['store']['selling']['poundage'] = floatval($_config['store']['selling']['poundage']);

        if ($_config['store']['selling']['poundage'] > 1.0) {
            $_config['store']['selling']['poundage'] = 1.0;
        }

        if ($_config['store']['selling']['poundage'] < 0.0) {
            $_config['store']['selling']['poundage'] = 0.0;
        }

        if ($row['date_of_expiration'] == 0) {
            $price = $row['price_of_purchase'] * (1.0 - $_config['store']['selling']['poundage']);
        } else {
            if ($row['date_of_expiration'] < time()) {
                throw new StoreException();
            }

            $price = (int)((((float)$row['date_of_expiration'] - (float)time())/((float)$row['date_of_expiration'] - (float)$row['date_of_purchase'])) * $row['price_of_purchase'] * (1.0 - $_config['store']['selling']['poundage']));

            if ($price < 0) {
                throw new StoreException('Something went wrong?');
            }
        }

        $result->free();

        return [
            'itemId' => $row['id'],
            'unique' => $row['unique_id'],
            'price' => $price,
            'poundage' => $row['price_of_purchase'] - $price,
        ];
    }

    public function selling($uid)
    {
        $arr = $this->sellcheck($uid);

        if (!is_numeric($uid)) {
            $uid = $arr['itemId'];
        }

        $price = $arr['price'];

        if (!($result = $this->dbConnection->query("CALL `store_selling` ('" . $this->playerId . "', '" . $uid . "', '" . $price . "');"))) {
            throw new DatabaseException('Failed to query from database: ' . $this->dbConnection->error);
        }

        if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
            throw new DatabaseException('Failed to fetch from sql query: ' . $this->dbConnection->error);
        }

        if ($row['errCode'] != 0) {
            throw new StoreException('Failed to handle selling -> errCode: ' . $row['errCode'] . '  errMsgs: ' . $row['errMsgs']);
        }

        $result->free();
        $this->dbConnection->next_result();

        $this->playerCredits = $row['myMoney'];

        return $this->playerCredits;
    }

    public function checkInventoryItem()
    {
        if (!($result = $this->dbConnection->query("SELECT * FROM `store_items` WHERE `player_id` = '" . $this->playerId . "';"))) {
            throw new DatabaseException('Failed to load itemIndex from database: ' . $this->dbConnection->error);
        }

        $array = [];

        while($row = $result->fetch_array(MYSQLI_ASSOC)) {
            $array[] = $row;
        }

        $result->free();

        return $array;
    }

    private function giftcheck($itemId)
    {
        if (!($result = $this->dbConnection->query("SELECT `uid`, `name`, `giftable`, `auth`, `vip` FROM `store_item_child` WHERE `uid` = (SELECT `unique_id` FROM `store_items` WHERE `id` = '" . $itemId . "') LIMIT 1;"))) {
            throw new DatabaseException('Failed to load item data from database: ' . $this->dbConnection->error);
        }

        if ($result->num_rows == 0) {
            throw new StoreException('ItemId is invalid.');
        }

        if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
            throw new DatabaseException('Failed to fetch playerId from array.');
        }

        $result->free();

        return $row;
    }

    private function hasItem($userId, $unique_id)
    {
        $quota = is_numeric($unique_id) ? 'id' : 'unique_id';

        if (!($result = $this->dbConnection->query("SELECT * FROM `store_items` WHERE `player_id` = '" . $userId . "' AND `" . $quota . "` = '" . $unique_id . "' LIMIT 1;"))) {
            throw new DatabaseException('Failed to load itemIndex from database: ' . $this->dbConnection->error);
        }

        $has = $result->num_rows > 0;
        $result->free();

        return $has;
    }

    public function gifting($userId, $itemId)
    {
        if (!is_numeric($userId) || $userId >= 76561100000000000) {
            $CSteamID = new SteamID($userId);
            $steam2Id = str_replace(['STEAM_0:', 'STEAM_1:'], '', $CSteamID->RenderSteam2());

            if (!($result = $this->dbConnection->query("SELECT `id`,`credits` FROM `store_players` WHERE `authid` = '" . $steam2Id . "' LIMIT 1;"))) {
                throw new DatabaseException('Failed to load playerId from database: ' . $this->dbConnection->error);
            }
            
            if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
                throw new DatabaseException('Failed to fetch playerId from array.');
            }

            $result->free();

            $playerId = $row['id'];
            $playerCredits = $row['credits'];

            if ($playerId < 0) {
                throw new StoreException('Invalid store playerId: ' . $playerId);
            }
        } else {
            $playerId = $userId;
        }
 
        $arr = $this->sellcheck($itemId);

        if (!is_numeric($itemId)) {
            $itemId = $arr['itemId'];
        }

        $chk = $this->giftcheck($itemId);
        if (strcmp($chk['auth'], 'ITEM_NOT_PERSONAL') != 0) {
            throw new StoreException('This item is not giftable: [' . $chk['name'] . '](' . $chk['uid'] . ')');
        }

        if ($chk['vip'] != 0) {
            throw new StoreException('This item is vip exclusivity item: [' . $chk['name'] . '](' . $chk['uid'] . ')');
        }

        if ($chk['giftable'] != 1) {
            throw new StoreException('This item is not giftable: [' . $chk['name'] . '](' . $chk['uid'] . ')');
        }

        if ($this->hasItem($playerId, $chk['uid'])) {
            throw new StoreException('Target player already has this item: [' . $chk['name'] . '](' . $chk['uid'] . ')');
        }

        if (!($result = $this->dbConnection->query("CALL `store_gifting` ('" . $this->playerId . "', '" . $playerId . "', '" . $itemId . "', '" . $arr['poundage'] . "');"))) {
            throw new DatabaseException('Failed to query from database: ' . $this->dbConnection->error);
        }

        if (!($row = $result->fetch_array(MYSQLI_ASSOC))) {
            throw new DatabaseException('Failed to fetch from sql query: ' . $this->dbConnection->error);
        }

        $result->free();
        $this->dbConnection->next_result();

        if ($row['errCode'] != 0) {
            throw new StoreException('Failed to handle gifting -> errCode: ' . $row['errCode'] . '  errMsgs: ' . $row['errMsgs']);
        }

        return [
            'itemName' => $row['itemShortName'],
            'itemUId' => $row['itemUniqueId']
        ];
    }
}
