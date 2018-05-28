<?php

ini_set("display_errors", 1);
error_reporting(E_ALL & ~E_NOTICE);
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

$file2kv = file_get_contents($path);
$kv2array = vdf_decode($file2kv);

$arr = array();

// load parent
foreach($kv2array['Store'] as $module_name => $module_data)
{
    $arr['name'] = $module_name;
    $arr['parent'] = -1;
    $store[] = $arr;
    
    if(!array_key_exists('type', $module_data))
    {
        $level[0] = count($store)-1;
        foreach($module_data as $parent_name0 => $parent_data0)
        {
            if(!array_key_exists('type', $parent_data0)){

                $level[1] = count($store)-1;
                $arr['name'] = $parent_name0;
                $arr['parent'] = $level[0];
                $store[] = $arr;
                print_r("load {$parent_name0} in {$module_name} at 0\n");

                foreach($parent_data0 as $parent_name1 => $parent_data1)
                {
                    if(!array_key_exists('type', $parent_data1)){
                        
                        $level[2] = count($store)-1;
                        $arr['name'] = $parent_name1;
                        $arr['parent'] = $level[1];
                        $store[] = $arr;
                        print_r("load {$parent_name1} in {$parent_name0} at 1 \n");
                        
                        foreach($parent_data1 as $parent_name2 => $parent_data2)
                        {
                            if(!array_key_exists('type', $parent_data2)){
                                
                                $level[3] = count($store)-1;
                                $arr['id']++;
                                $arr['name'] = $parent_name2;
                                $arr['parent'] = $level[2];
                                $store[] = $arr;
                                print_r("load {$parent_name2} in {$parent_name1} at 2 \n");
                                
                                foreach($parent_data2 as $parent_name3 => $parent_data3)
                                {
                                    if(!array_key_exists('type', $parent_data3)){
                                        
                                        $level[4] = count($store)-1;
                                        $arr['id']++;
                                        $arr['name'] = $parent_name3;
                                        $arr['parent'] = $level[3];
                                        $store[] = $arr;
                                        print_r("load {$parent_name3} in {$parent_name2} at 3 \n");
                                        
                                        foreach($parent_data3 as $parent_name4 => $parent_data4)
                                        {
                                            if(!array_key_exists('type', $parent_data4)){
                                                
                                                $level[5] = count($store)-1;
                                                $arr['id']++;
                                                $arr['name'] = $parent_name4;
                                                $arr['parent'] = $level[4];
                                                $store[] = $arr;
                                                print_r("load {$parent_name4} in {$parent_name3} at 4 \n");
                                                
                                                foreach($parent_data4 as $parent_name5 => $parent_data5)
                                                {
                                                    if(!array_key_exists('type', $parent_data5)){
                                                        
                                                        $level[6] = count($store)-1;
                                                        $arr['id']++;
                                                        $arr['name'] = $parent_name5;
                                                        $arr['parent'] = $level[5];
                                                        $store[] = $arr;
                                                        print_r("load {$parent_name5} in {$parent_name4} at 5 \n");

                                                        foreach($parent_data5 as $parent_name6 => $parent_data6)
                                                        {
                                                            if(!array_key_exists('type', $parent_data6)){
                                                                $arr['id']++;
                                                                $arr['name'] = $parent_name6;
                                                                $arr['parent'] = $level[6];
                                                                $store[] = $arr;
                                                                print_r("load {$parent_name6} in {$parent_name5} at 6 \n");
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

echo "\n";
echo "\n";

print_r("Array of Parent: \n");
print_r($store);

echo "\n";
echo "\n";

mysqli_query($database, "SET NAMES utf8");
mysqli_query($database, "SET sql_mode='NO_AUTO_VALUE_ON_ZERO';");

foreach($store as $key => $val)
{
    $sql = "INSERT INTO `store_item_parent` VALUES ($key, '{$val['name']}', '{$val['parent']}');";
    $result = mysqli_query($database, $sql);
    if(mysqli_affected_rows($database) < 1){
        $err = mysqli_error($database);
        echo "Insert [{$key}]{$val['name']} Failed : {$err} -> {$sql} \n";
    }else{
        echo "Insert [{$key}]{$val['name']} successful.\n";
    }
    usleep(100);
}

?>