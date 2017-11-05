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
$parent = array();

$result = mysqli_query($database, "SELECT * FROM store_item_parent");
while($row = mysqli_fetch_array($result))
{
    $parent[] = $row;
    unset($row);
}
unset($result);

$result = mysqli_query($database, "SELECT * FROM store_item_child ORDER BY parent ASC");
while($row = mysqli_fetch_array($result))
{
    foreach($parent as $k => $v)
    {
        if($v['id'] == $row['parent'])
            $row['catelogy'] = $v['name'];
    }
    
    if(!isset($row['catelogy']))
        echo $row['name']." has not found parent\n";
    
    $store[] = $row;
    unset($row);
}
unset($result);

echo "\n";
echo "\n";

$items = array();
$delet = array();
$result = mysqli_query($database, "SELECT * FROM store_items ORDER BY unique_id, type ASC");
while($row = mysqli_fetch_array($result))
{
    foreach($store as $k => $v)
    {
        if($v['uid'] == $row['unique_id'])
            $row['name'] = $v['name'];
    }
    
    if(!isset($row['name'])){
        echo $row['id'].". '".$row['unique_id']."' has not found in child\n";
        $items[] = $row;
        
        $fp = fopen( __DIR__ . "/errorlog.php", "a");
        fputs($fp, "<?PHP exit;?>    ");
        fputs($fp, "DELETE id=".$row['id']." player_id=".$row['id']." type=".$row['type']." unique_id=".$row['unique_id']." date_of_purchase=".$row['date_of_purchase']." date_of_expration=".$row['date_of_expration']." price_of_purchase=".$row['price_of_purchase']." FROM store_items");
        fputs($fp, "\n");
        fclose($fp);
        $delet[] = $row['id'];
    }
    
    unset($row);
}

echo "\n";
echo "\n";

foreach($delet as $key => $values)
{
    mysqli_query($database, "DELETE FROM store_items WHERE id=".$values.";");
}

?>