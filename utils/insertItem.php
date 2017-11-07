<?php

ini_set("display_errors", 1);
require_once(__DIR__ . "/kvphp.php");

$path = __DIR__ . "/items.txt";

if(!file_exists($path)){
    die("file doesnt exists!");
}

$db_user = "";
$db_pswd = "";
$db_host = "";
$db_name = "";

$database = mysqli_connect($db_host, $db_user, $db_pswd, $db_name);

$store = array();
$items = array();

$file2kv = file_get_contents($path);
$kv2array = vdf_decode($file2kv);

foreach($kv2array['Store'] as $module_name => $module_data)
{
    foreach($module_data as $parent_name => $parent_data)
    {
        foreach($parent_data as $data_1_key => $data_1_value)
        {
            if(array_key_exists('type', $data_1_value)){
                $data['name'] = $data_1_key;
                $data['module'] = $module_name;
                $data['parent'] = $parent_name;
                foreach($data_1_value as $key => $value)
                {
                    if(!is_array($value)){
                        if($key == 'price'){
                            $data['永久'] = $value;
                        }else{
                            $data[$key] = $value;
                        }
                    }elseif($key == 'Plans'){
                        foreach($value as $plan_name => $plan_data)
                        {
                            $data[$plan_name] = $plan_data['price'];
                        }
                    }else{
                        print_r("can not load ".$data['name']." \n");
                        print_r($data_1_value);
                        print_r("\n");
                    }
                }
                $items[$module_name][$parent_name][$data['name']] = $data;
                $escape = array();
                $escape['parent'] = mysqli_real_escape_string($database, $parent_name);
                $escape['type'] = mysqli_real_escape_string($database, $data['type']);
                $escape['uid'] = mysqli_real_escape_string($database, $data['uid']);
                $escape['buyable'] = isset($data['buyable']) ? $data['buyable'] : 1;
                $escape['giftable'] = isset($data['giftable']) ? $data['giftable'] : 1;
                $escape['only'] = isset($data['only']) ? $data['only'] : 0;
                $escape['auth'] = mysqli_real_escape_string($database, isset($data['auth']) ? $data['auth'] : "ITEM_NOT_PERSONAL");
                $escape['vip'] = isset($data['vip']) ? $data['vip'] : 0;
                $escape['name'] = mysqli_real_escape_string($database, isset($data['name']) ? $data['name'] : "ITEM_UNNAMED");
                $escape['lvls'] = isset($data['lvls']) ? $data['lvls'] : 0;
                $escape['desc'] = mysqli_real_escape_string($database, isset($data['desc']) ? $data['desc'] : "ITEM_NO_DESC");
                $escape['case'] = isset($data['case']) ? $data['case'] : 0;
                $escape['compose'] = isset($data['compose']) ? $data['compose'] : 0;
                $escape['1d'] = isset($data['1天']) ? $data['1天'] : 0;
                $escape['1m'] = isset($data['1月']) ? $data['1月'] : 0;
                $escape['pm'] = isset($data['永久']) ? $data['永久'] : 0;
                $escape['model'] = mysqli_real_escape_string($database, isset($data['model']) ? $data['model'] : "ITEM_NO_MODEL");
                $escape['arms'] = mysqli_real_escape_string($database, isset($data['arms']) ? $data['arms'] : "ITEM_NO_ARMS");
                $escape['team'] = isset($data['team']) ? $data['team'] : 0;
                $escape['sound'] = mysqli_real_escape_string($database, isset($data['sound']) ? $data['sound'] : "ITEM_NO_SOUND");
                $escape['position'] = mysqli_real_escape_string($database, isset($data['position']) ? $data['position'] : "0.0 0.0 0.0");
                $escape['angles'] = mysqli_real_escape_string($database, isset($data['angles']) ? $data['angles'] : "0.0 0.0 0.0");
                $escape['attachment'] = mysqli_real_escape_string($database, isset($data['attachment']) ? $data['attachment'] : "ITEM_NO_ATTACHMENT");
                $escape['slot'] = isset($data['slot']) ? $data['slot'] : 0;
                $escape['material'] = mysqli_real_escape_string($database, isset($data['material']) ? $data['material'] : "ITEM_NO_MATERIAL");
                $escape['color'] = mysqli_real_escape_string($database, isset($data['color']) ? $data['color'] : "ITEM_NO_COLOR");
                $escape['grenade'] = mysqli_real_escape_string($database, isset($data['grenade']) ? $data['grenade'] : "ITEM_NO_GRENADE");
                $escape['shortname'] = mysqli_real_escape_string($database, isset($data['shortname']) ? $data['shortname'] : "ITEM_NO_SHORTNAME");
                $escape['volume'] = isset($data['volume']) ? $data['volume'] : 1.0;
                $escape['cooldown'] = isset($data['cooldown']) ? $data['cooldown'] : 60;
                $escape['worldmodel'] = mysqli_real_escape_string($database, isset($data['worldmodel']) ? $data['worldmodel'] : "ITEM_NO_WORLDMODEL");
                $escape['dropmodel'] = mysqli_real_escape_string($database, isset($data['dropmodel']) ? $data['dropmodel'] : "ITEM_NO_DROPMODEL");
                $escape['weapon'] = mysqli_real_escape_string($database, isset($data['weapon']) ? $data['weapon'] : "ITEM_NO_ENTITY");
                $escape['effect'] = mysqli_real_escape_string($database, isset($data['effect']) ? $data['effect'] : "ITEM_NO_ID");
                $escape['brightness'] = isset($data['brightness']) ? $data['brightness'] : 5;
                $escape['distance'] = isset($data['distance']) ? $data['distance'] : 150;
                $escape['distancefade'] = isset($data['distancefade']) ? $data['distancefade'] : 50;
                $escape['tag'] = mysqli_real_escape_string($database, isset($data['tag']) ? $data['tag'] : "ITEM_NO_TAG");
                $sql = "INSERT INTO store_item_child VALUES ((SELECT id FROM store_item_parent WHERE name = '".$escape['parent']."'), '".$escape['type']."', '".$escape['uid']."', ".$escape['buyable'].", ".$escape['giftable'].", ".$escape['only'].", '".$escape['auth']."', ".$escape['vip'].", '".$escape['name']."', '".$escape['lvls']."', '".$escape['desc']."', ".$escape['case'].", ".$escape['compose'].", '".$escape['1d']."', '".$escape['1m']."', '".$escape['pm']."', '".$escape['model']."', '".$escape['arms']."', '".$escape['team']."', '".$escape['sound']."', '".$escape['position']."', '".$escape['angles']."', '".$escape['attachment']."', '".$escape['slot']."', '".$escape['material']."', '".$escape['color']."', '".$escape['grenade']."', '".$escape['shortname']."', '".$escape['volume']."', '".$escape['cooldown']."', '".$escape['worldmodel']."', '".$escape['dropmodel']."', '".$escape['weapon']."', '".$escape['effect']."', '".$escape['brightness']."', '".$escape['distance']."', '".$escape['distancefade']."', '".$escape['tag']."')";
                $result = mysqli_query($database, $sql);
                if(mysqli_affected_rows($database) < 1){
                    echo "Insert Failed: ".mysqli_error($database)." -> ".$sql."\n";
                }
            }else{
                foreach($data_1_value as $data_2_key => $data_2_value)
                {
                    if(array_key_exists('type', $data_2_value)){
                        $data['name'] = $data_2_key;
                        $data['module'] = $module_name;
                        $data['parent'] = $parent_name." -> ".$data_1_key;
                        foreach($data_2_value as $key => $value)
                        {
                            if(!is_array($value)){
                                if($key == 'price'){
                                    $data['永久'] = $value;
                                }else{
                                    $data[$key] = $value;
                                }
                            }elseif($key == 'Plans'){
                                foreach($value as $plan_name => $plan_data)
                                {
                                    $data[$plan_name] = $plan_data['price'];
                                }
                            }else{
                                print_r("can not load ".$data['name']." \n");
                                print_r($data_2_value);
                                print_r("\n");
                            }
                        }
                        $items[$module_name][$parent_name][$data_1_key][$data['name']] = $data;
                        $escape = array();
                        $escape['parent'] = mysqli_real_escape_string($database, $data_1_key);
                        $escape['type'] = mysqli_real_escape_string($database, $data['type']);
                        $escape['uid'] = mysqli_real_escape_string($database, $data['uid']);
                        $escape['buyable'] = isset($data['buyable']) ? $data['buyable'] : 1;
                        $escape['giftable'] = isset($data['giftable']) ? $data['giftable'] : 1;
                        $escape['only'] = isset($data['only']) ? $data['only'] : 0;
                        $escape['auth'] = mysqli_real_escape_string($database, isset($data['auth']) ? $data['auth'] : "ITEM_NOT_PERSONAL");
                        $escape['vip'] = isset($data['vip']) ? $data['vip'] : 0;
                        $escape['name'] = mysqli_real_escape_string($database, isset($data['name']) ? $data['name'] : "ITEM_UNNAMED");
                        $escape['lvls'] = isset($data['lvls']) ? $data['lvls'] : 0;
                        $escape['desc'] = mysqli_real_escape_string($database, isset($data['desc']) ? $data['desc'] : "ITEM_NO_DESC");
                        $escape['case'] = isset($data['case']) ? $data['case'] : 0;
                        $escape['compose'] = isset($data['compose']) ? $data['compose'] : 0;
                        $escape['1d'] = isset($data['1天']) ? $data['1天'] : 0;
                        $escape['1m'] = isset($data['1月']) ? $data['1月'] : 0;
                        $escape['pm'] = isset($data['永久']) ? $data['永久'] : 0;
                        $escape['model'] = mysqli_real_escape_string($database, isset($data['model']) ? $data['model'] : "ITEM_NO_MODEL");
                        $escape['arms'] = mysqli_real_escape_string($database, isset($data['arms']) ? $data['arms'] : "ITEM_NO_ARMS");
                        $escape['team'] = isset($data['team']) ? $data['team'] : 0;
                        $escape['sound'] = mysqli_real_escape_string($database, isset($data['sound']) ? $data['sound'] : "ITEM_NO_SOUND");
                        $escape['position'] = mysqli_real_escape_string($database, isset($data['position']) ? $data['position'] : "0.0 0.0 0.0");
                        $escape['angles'] = mysqli_real_escape_string($database, isset($data['angles']) ? $data['angles'] : "0.0 0.0 0.0");
                        $escape['attachment'] = mysqli_real_escape_string($database, isset($data['attachment']) ? $data['attachment'] : "ITEM_NO_ATTACHMENT");
                        $escape['slot'] = isset($data['slot']) ? $data['slot'] : 0;
                        $escape['material'] = mysqli_real_escape_string($database, isset($data['material']) ? $data['material'] : "ITEM_NO_MATERIAL");
                        $escape['color'] = mysqli_real_escape_string($database, isset($data['color']) ? $data['color'] : "ITEM_NO_COLOR");
                        $escape['grenade'] = mysqli_real_escape_string($database, isset($data['grenade']) ? $data['grenade'] : "ITEM_NO_GRENADE");
                        $escape['shortname'] = mysqli_real_escape_string($database, isset($data['shortname']) ? $data['shortname'] : "ITEM_NO_SHORTNAME");
                        $escape['volume'] = isset($data['volume']) ? $data['volume'] : 1.0;
                        $escape['cooldown'] = isset($data['cooldown']) ? $data['cooldown'] : 60;
                        $escape['worldmodel'] = mysqli_real_escape_string($database, isset($data['worldmodel']) ? $data['worldmodel'] : "ITEM_NO_WORLDMODEL");
                        $escape['dropmodel'] = mysqli_real_escape_string($database, isset($data['dropmodel']) ? $data['dropmodel'] : "ITEM_NO_DROPMODEL");
                        $escape['weapon'] = mysqli_real_escape_string($database, isset($data['weapon']) ? $data['weapon'] : "ITEM_NO_ENTITY");
                        $escape['effect'] = mysqli_real_escape_string($database, isset($data['effect']) ? $data['effect'] : "ITEM_NO_ID");
                        $escape['brightness'] = isset($data['brightness']) ? $data['brightness'] : 5;
                        $escape['distance'] = isset($data['distance']) ? $data['distance'] : 150;
                        $escape['distancefade'] = isset($data['distancefade']) ? $data['distancefade'] : 50;
                        $escape['tag'] = mysqli_real_escape_string($database, isset($data['tag']) ? $data['tag'] : "ITEM_NO_TAG");
                        $sql = "INSERT INTO store_item_child VALUES ((SELECT id FROM store_item_parent WHERE name = '".$escape['parent']."'), '".$escape['type']."', '".$escape['uid']."', ".$escape['buyable'].", ".$escape['giftable'].", ".$escape['only'].", '".$escape['auth']."', ".$escape['vip'].", '".$escape['name']."', '".$escape['lvls']."', '".$escape['desc']."', ".$escape['case'].", ".$escape['compose'].", '".$escape['1d']."', '".$escape['1m']."', '".$escape['pm']."', '".$escape['model']."', '".$escape['arms']."', '".$escape['team']."', '".$escape['sound']."', '".$escape['position']."', '".$escape['angles']."', '".$escape['attachment']."', '".$escape['slot']."', '".$escape['material']."', '".$escape['color']."', '".$escape['grenade']."', '".$escape['shortname']."', '".$escape['volume']."', '".$escape['cooldown']."', '".$escape['worldmodel']."', '".$escape['dropmodel']."', '".$escape['weapon']."', '".$escape['effect']."', '".$escape['brightness']."', '".$escape['distance']."', '".$escape['distancefade']."', '".$escape['tag']."')";
                        $result = mysqli_query($database, $sql);
                        if(mysqli_affected_rows($database) < 1){
                            echo "Insert Failed: ".mysqli_error($database)." -> ".$sql."\n";
                        }
                    }else{
                        foreach($data_2_value as $data_3_key => $data_3_value)
                        {
                            if(array_key_exists('type', $data_3_value)){
                                $data['name'] = $data_3_key;
                                $data['module'] = $module_name;
                                $data['parent'] = $parent_name." -> ".$data_1_key." -> ".$data_2_key;
                                foreach($data_3_value as $key => $value)
                                {
                                    if(!is_array($value)){
                                        if($key == 'price'){
                                            $data['永久'] = $value;
                                        }else{
                                            $data[$key] = $value;
                                        }
                                    }elseif($key == 'Plans'){
                                        foreach($value as $plan_name => $plan_data)
                                        {
                                            $data[$plan_name] = $plan_data['price'];
                                        }
                                    }else{
                                        print_r("can not load ".$data['name']." \n");
                                        print_r($data_3_value);
                                        print_r("\n");
                                    }
                                }
                                $items[$module_name][$parent_name][$data_1_key][$data_2_key][$data['name']] = $data;
                                $escape = array();
                                $escape['parent'] = mysqli_real_escape_string($database, $data_2_key);
                                $escape['type'] = mysqli_real_escape_string($database, $data['type']);
                                $escape['uid'] = mysqli_real_escape_string($database, $data['uid']);
                                $escape['buyable'] = isset($data['buyable']) ? $data['buyable'] : 1;
                                $escape['giftable'] = isset($data['giftable']) ? $data['giftable'] : 1;
                                $escape['only'] = isset($data['only']) ? $data['only'] : 0;
                                $escape['auth'] = mysqli_real_escape_string($database, isset($data['auth']) ? $data['auth'] : "ITEM_NOT_PERSONAL");
                                $escape['vip'] = isset($data['vip']) ? $data['vip'] : 0;
                                $escape['name'] = mysqli_real_escape_string($database, isset($data['name']) ? $data['name'] : "ITEM_UNNAMED");
                                $escape['lvls'] = isset($data['lvls']) ? $data['lvls'] : 0;
                                $escape['desc'] = mysqli_real_escape_string($database, isset($data['desc']) ? $data['desc'] : "ITEM_NO_DESC");
                                $escape['case'] = isset($data['case']) ? $data['case'] : 0;
                                $escape['compose'] = isset($data['compose']) ? $data['compose'] : 0;
                                $escape['1d'] = isset($data['1天']) ? $data['1天'] : 0;
                                $escape['1m'] = isset($data['1月']) ? $data['1月'] : 0;
                                $escape['pm'] = isset($data['永久']) ? $data['永久'] : 0;
                                $escape['model'] = mysqli_real_escape_string($database, isset($data['model']) ? $data['model'] : "ITEM_NO_MODEL");
                                $escape['arms'] = mysqli_real_escape_string($database, isset($data['arms']) ? $data['arms'] : "ITEM_NO_ARMS");
                                $escape['team'] = isset($data['team']) ? $data['team'] : 0;
                                $escape['sound'] = mysqli_real_escape_string($database, isset($data['sound']) ? $data['sound'] : "ITEM_NO_SOUND");
                                $escape['position'] = mysqli_real_escape_string($database, isset($data['position']) ? $data['position'] : "0.0 0.0 0.0");
                                $escape['angles'] = mysqli_real_escape_string($database, isset($data['angles']) ? $data['angles'] : "0.0 0.0 0.0");
                                $escape['attachment'] = mysqli_real_escape_string($database, isset($data['attachment']) ? $data['attachment'] : "ITEM_NO_ATTACHMENT");
                                $escape['slot'] = isset($data['slot']) ? $data['slot'] : 0;
                                $escape['material'] = mysqli_real_escape_string($database, isset($data['material']) ? $data['material'] : "ITEM_NO_MATERIAL");
                                $escape['color'] = mysqli_real_escape_string($database, isset($data['color']) ? $data['color'] : "ITEM_NO_COLOR");
                                $escape['grenade'] = mysqli_real_escape_string($database, isset($data['grenade']) ? $data['grenade'] : "ITEM_NO_GRENADE");
                                $escape['shortname'] = mysqli_real_escape_string($database, isset($data['shortname']) ? $data['shortname'] : "ITEM_NO_SHORTNAME");
                                $escape['volume'] = isset($data['volume']) ? $data['volume'] : 1.0;
                                $escape['cooldown'] = isset($data['cooldown']) ? $data['cooldown'] : 60;
                                $escape['worldmodel'] = mysqli_real_escape_string($database, isset($data['worldmodel']) ? $data['worldmodel'] : "ITEM_NO_WORLDMODEL");
                                $escape['dropmodel'] = mysqli_real_escape_string($database, isset($data['dropmodel']) ? $data['dropmodel'] : "ITEM_NO_DROPMODEL");
                                $escape['weapon'] = mysqli_real_escape_string($database, isset($data['weapon']) ? $data['weapon'] : "ITEM_NO_ENTITY");
                                $escape['effect'] = mysqli_real_escape_string($database, isset($data['effect']) ? $data['effect'] : "ITEM_NO_ID");
                                $escape['brightness'] = isset($data['brightness']) ? $data['brightness'] : 5;
                                $escape['distance'] = isset($data['distance']) ? $data['distance'] : 150;
                                $escape['distancefade'] = isset($data['distancefade']) ? $data['distancefade'] : 50;
                                $escape['tag'] = mysqli_real_escape_string($database, isset($data['tag']) ? $data['tag'] : "ITEM_NO_TAG");
                                $sql = "INSERT INTO store_item_child VALUES ((SELECT id FROM store_item_parent WHERE name = '".$escape['parent']."'), '".$escape['type']."', '".$escape['uid']."', ".$escape['buyable'].", ".$escape['giftable'].", ".$escape['only'].", '".$escape['auth']."', ".$escape['vip'].", '".$escape['name']."', '".$escape['lvls']."', '".$escape['desc']."', ".$escape['case'].", ".$escape['compose'].", '".$escape['1d']."', '".$escape['1m']."', '".$escape['pm']."', '".$escape['model']."', '".$escape['arms']."', '".$escape['team']."', '".$escape['sound']."', '".$escape['position']."', '".$escape['angles']."', '".$escape['attachment']."', '".$escape['slot']."', '".$escape['material']."', '".$escape['color']."', '".$escape['grenade']."', '".$escape['shortname']."', '".$escape['volume']."', '".$escape['cooldown']."', '".$escape['worldmodel']."', '".$escape['dropmodel']."', '".$escape['weapon']."', '".$escape['effect']."', '".$escape['brightness']."', '".$escape['distance']."', '".$escape['distancefade']."', '".$escape['tag']."')";
                                $result = mysqli_query($database, $sql);
                                if(mysqli_affected_rows($database) < 1){
                                    echo "Insert Failed: ".mysqli_error($database)." -> ".$sql."\n";
                                }
                            }else{
                                print_r("can not load ".$data['name']." \n");
                                print_r($parent_data);
                                print_r($data_1_value);
                                print_r($data_2_value);
                                print_r($data_3_value);
                                print_r("\n");
                            }
                        }
                    }
                }
            }
            if(isset($store[$data['type']][$data['name']])){
                print_r($data['name']." is already exists!\n");
                print_r($data);
            }else{
                $store[$data['type']][$data['name']] = $data;
            }

            unset($data);
        }
    }
}

echo "\n";
echo "\n";

print_r($store);
?>