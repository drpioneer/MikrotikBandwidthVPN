# Script for determining the bandwidth of VPN interfaces by drPioneer
# https://forummikrotik.ru/viewtopic.php?t=5986
# tested on ROS 6.49
# updated 2021/10/26

:do {   
    :local  localUser "login";
    :local  localPass "password";
    :local  nameVPN   "VPN";
    :local  countPing 2;
    :local  message   "Bandwidth test:";
    if ($localUser != "" && $localPass != "" && $nameVPN != "") do={
        :foreach activeVPN in=[ /ip address find interface~$nameVPN; ] do={
            :do {
                :local remoteAddress [ /ip address get $activeVPN network; ];
                :local localAddress  [ /ip address get $activeVPN address; ];
                :local interfaceVPN  [ /ip address get $activeVPN interface; ];
                :local checkPing     [ /ping $remoteAddress src-address=[ :pick $localAddress 0 ([ :len $localAddress ] - 3)] count=$countPing; ];
                :if ($checkPing < ($countPing / 3*2)) do={ :set message ("$message \r\n'$interfaceVPN' is fail, interface not responded.");
                } else={
                    :local rxSpeed 0;
                    :local txSpeed 0;
                    /tool bandwidth-test address=$remoteAddress duration=5s protocol=tcp user=$localUser password=$localPass direction=receive  do={ :set rxSpeed ([$"rx-total-average"]); }
                    /tool bandwidth-test address=$remoteAddress duration=5s protocol=tcp user=$localUser password=$localPass direction=transmit do={ :set txSpeed ([$"tx-total-average"]); }
                    :local simpleMbRxReport ($rxSpeed / 1000000);
                    :local simpleMbTxReport ($txSpeed / 1000000);
                    :local lowMbRxReport  ((($rxSpeed - ($simpleMbRxReport * 1000000)) * 1000000) / 1000);
                    :local lowMbTxReport  ((($txSpeed - ($simpleMbTxReport * 1000000)) * 1000000) / 1000);
                    :local mbRxReport ("$simpleMbRxReport.$[:pick $lowMbRxReport 0 2]");
                    :local mbTxReport ("$simpleMbTxReport.$[:pick $lowMbTxReport 0 2]");
                    :set message ("$message \r\n'$interfaceVPN' Rx/Tx: $mbRxReport/$mbTxReport Mbps");
                } 
            } on-error={ :set message ("$message \r\nScript error. Not found some $nameVPN interfaces."); } 
        } 
    } else={ :set message ("$message \r\nScript error. Something went wrong."); }
    :put $message;
    log warning $message;
} on-error={ :log warning ("Script error. Couldn't show the bandwidth test."); }

