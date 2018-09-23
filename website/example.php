<?php

require_once 'store.class.php';

use Store\Store;
use Store\Player;

function testStore() {

    try {

        $store = new Store();

        print_r($store->getPlayers(1, true)); print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);
        print_r($store->getParents());        print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);
        print_r($store->getItems());          print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);
        print_r($store->getStore());          print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);

        //$store->Destory();

    } catch (Exception $e) {
        print_r($e);
        exit(0);
    }
}

// 1 & 1946
function testPlayer() {
    
    try {

        $player = new Player('76561198048432253'); // STEAM_1:1:44083262

        print_r("recharge           :" . PHP_EOL); print_r($player->recharge(23333));                                   print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);
        print_r("transfer           :" . PHP_EOL); print_r($player->transfer(1949, 416));                               print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);
        print_r("purchase           :" . PHP_EOL); print_r($player->purchase("skin_lty_normal", 1));                    print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);
        print_r("sellcheck          :" . PHP_EOL); print_r($player->sellcheck("skin_lty_normal", 1));                   print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);
        print_r("selling:           :" . PHP_EOL); print_r($player->selling("skin_lty_normal"));                        print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);
        print_r("checkInventoryItem :" . PHP_EOL); print_r($player->checkInventoryItem());                              print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);
        print_r("gifting            :" . PHP_EOL); print_r($player->gifting("STEAM_0:0:3339246", "skin_haipa_normal")); print_r(PHP_EOL); print_r(PHP_EOL); sleep(2);

        //$player->Destory();

    } catch (Exception $e) {
        print_r($e);
        exit(0);
    }
}

print_r("Start Test Store!"  . PHP_EOL . PHP_EOL . PHP_EOL);

testStore();

print_r("Start Test Player!" . PHP_EOL . PHP_EOL . PHP_EOL);

testPlayer();

