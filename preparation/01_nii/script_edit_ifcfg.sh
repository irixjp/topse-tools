#!/bin/bash

NIC=""
MAC=""

ip link show em2
ret=$?
if [ $ret == 0 ]; then
    NIC=em2
fi

ip link show em4
ret=$?
if [ $ret == 0 ]; then
    NIC=em4
fi

ETH1MAC=`ip link show ${NIC:?"error: not set NIC device"} | grep link/ether | sed -E "s@.*link/ether\s(\S+)(\s.*|$)@\1@g" | tr a-z A-Z`

cat << __EOF__ > /etc/sysconfig/network-scripts/ifcfg-eth1
DEVICE=eth1
BOOTPROTO=none
ONBOOT=no
HWADDR=${ETH1MAC:?"error: not set MAC address"}
__EOF__
