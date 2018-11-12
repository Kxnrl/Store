<?php

namespace Kxnrl;

class DatabaseException extends \Exception
{
    function  __construct($message) {

        parent::__construct($message);

        if(!file_exists(__DIR__ . "/errorlog_dbi.php")) {
            $fp = fopen(__DIR__ . "/errorlog_dbi.php", "a+");
            fputs($fp, "<?PHP http_response_code(404); ?>" . PHP_EOL);
            fclose($fp);
        }

        $fp = fopen(__DIR__ . "/errorlog_dbi.php", "a+");
        fputs($fp, "===========================[" . date("Y-m-d H:i:s", time()) . "]===========================" . PHP_EOL);
        fputs($fp, "Message: " . $message . PHP_EOL);
        fputs($fp, "Stack Trace: ". PHP_EOL . $this->getTraceAsString(). PHP_EOL);
        fclose($fp);
    }
}

class StoreException extends \Exception
{
    function  __construct($message) {

        parent::__construct($message);

        if(!file_exists(__DIR__ . "/errorlog_fnc.php")) {
            $fp = fopen(__DIR__ . "/errorlog_fnc.php", "a+");
            fputs($fp, "<?PHP http_response_code(404); ?>" . PHP_EOL);
            fclose($fp);
        }

        $fp = fopen(__DIR__ . "/errorlog_fnc.php", "a+");
        fputs($fp, "===========================[" . date("Y-m-d H:i:s", time()) . "]===========================" . PHP_EOL);
        fputs($fp, "Message: " . $message . PHP_EOL);
        fputs($fp, "Stack Trace: ". PHP_EOL . $this->getTraceAsString(). PHP_EOL);
        fclose($fp);
    }
}

?>
