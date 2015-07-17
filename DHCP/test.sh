#!/bin/sh

. ../common/procedures.sh

pcs="FIX PC1 PC2"
err=0

eid=`imunes -b DHCP.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

./start_dhcp $eid
if [ $? -ne 0 ]; then
    echo "********** START_DHCP ERROR **********"
    pcs=""
    err=1
fi

for pc in $pcs; do
    pingCheck $pc@$eid 10.0.2.2
    err=$?
    if [ $err -ne 0 ]; then
        break
    fi

    ip_addr=`getNodeIP $pc@$eid eth0`
    echo $ip_addr | grep -q "10.0.0."
    if [ $? -ne 0 ]; then
        echo "********** IFCONFIG ERROR **********"
        err=1
        break
    fi
done

if [ $err -eq 0 ]; then
    netDump PC3@$eid eth0 'port 67 and not arp or port 68 and not arp'
    if [ $? -eq 0 ]; then
        sleep 2
        if test `uname -s` == "Linux"; then
            himage -b PC3@$eid dhclient eth0
            sleep 3
        else
            himage PC3@$eid dhclient eth0
        fi
        if [ $? -eq 0 ]; then
            sleep 2
            readDump PC3@$eid eth0
            err=$?
        else
            echo "********** DHCLIENT ERROR **********"
            err=1
        fi
    else
        err=1
    fi
fi

imunes -b -e $eid

thereWereErrors $err

