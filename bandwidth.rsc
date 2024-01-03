# Script for determining the bandwidth of VPN interfaces
# Script uses ideas by druide, Sertik, drPioneer
# https://forummikrotik.ru/viewtopic.php?t=5986
# tested on ROS 6.49.10 & 7.12
# updated 2023/12/29

:do {
    :local user "";
    :local pswd "";
    :local countPing 2;
    :local message "Bandwidth report from '$[system identity get name]':";

    # --------------------------------------------------------------------------------- # digit conversion function via SI-prefix
    :local NumSiPrefix do={
        :local inp [:tonum $1]; :local cnt 0;
        :while ($inp>1000) do={:set $inp ($inp/1000); :set $cnt ($cnt+1)}
        :return ($inp.[:pick [:toarray "Bps,Kbps,Mbps,Gbps,Tbps,Pbps,Ebps,Zbps,Ybps"] $cnt]);
    }

    # ================================================================================= # main body of the script ========================
    :local routeISP [/ip route find];                                                   # gateways information
    :if ($user!="" && $pswd!="" && [:len $routeISP]>0) do={
        :local gwList [:toarray ""]; :local count 0;
        :foreach idEth in=[/interface ethernet find] do={                               # list of ethernet interfaces
            :set ($gwList->$count) [/interface ethernet get $idEth name];
            :set count ($count+1);
        }
        :local ethCount $count;
        :foreach inetGate in=$routeISP do={                                             # enumeration of gateways
            :local gwName [:tostr [/ip route get $inetGate gateway]];
            :if ([:len $gwName]>0) do={
                :local ifaceISP "";                                                     # formation of interface name
                :foreach idName in=[/interface find running=yes] do={
                    :local ifName [/interface get $idName name];
                    :if ([:len [find key=$ifName in=$gwName]]>0) do={:set ifaceISP $ifName}
                }
                :if ([:len $ifaceISP]>0) do={
                    :if ([:len [/interface bridge find name=$ifaceISP]]>0) do={         # checking the interface for entering the Bridge
                        :if ([:find $gwName "%"]>0) do={
                            :set $gwName [:pick $gwName ([:len [:pick $gwName 0 [:find $gwName "%"]]] +1) [:len $gwName]];
                        }
                        :if ($gwName~"((25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)[.]){3}(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)") do={
                            :local mcAddrGate [/ip arp get [find address=$gwName interface=$ifaceISP] mac-address];
                            :if ($mcAddrGate~"([0-9A-F]{2}[:]){5}[0-9A-F]{2}") do={
                                :set ifaceISP [/interface bridge host get [find mac-address=$mcAddrGate] interface];
                            } else={:set ifaceISP ""}
                        } else={:set ifaceISP ""}
                    }
                    :if ([:len $ifaceISP]>0) do={
                        :local checkIf [:len [find key=$ifaceISP in=$gwList]];          # checking the repetition of interface name
                        :if ($checkIf=0) do={
                            :set ($gwList->$count) $ifaceISP;
                            :set count ($count+1);
                            :local remAddr [/ip address get [find interface=$ifaceISP] network];
                            :local locAddr [/ip address get [find interface=$ifaceISP] address];
                            :local chkPing [/ping $remAddr src-address=[:pick $locAddr 0 ([:len $locAddr]-3)] count=$countPing];
                            :if ($chkPing<($countPing/3*2)) do={:set message "$message \r\n'$ifaceISP' is fail, interface not responded.";
                            } else={
                                :local rxSpeed ""; :local txSpeed "";
                                /tool bandwidth-test address=$remAddr duration=5s protocol=tcp user=$user password=$pswd direction=receive  do={:set rxSpeed [$NumSiPrefix [$"rx-total-average"]]}
                                /tool bandwidth-test address=$remAddr duration=5s protocol=tcp user=$user password=$pswd direction=transmit do={:set txSpeed [$NumSiPrefix [$"tx-total-average"]]}
                                :set message "$message\r\n'$ifaceISP' $rxSpeed/$txSpeed (Rx/Tx)";
                            }
                        }
                    }
                }
            }
        }
        :if ($ethCount=$count) do={:set message "$message \r\nNo active VPN-routes"}
    } else={:set message "$message \r\nEmpty variables 'user','pswd' or no active routes"}
    :put $message;                                                                      # output of message
    log warning $message;
} on-error={ :log warning "Error, can't show bandwidth test"}
