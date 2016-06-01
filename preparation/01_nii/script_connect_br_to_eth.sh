#!/bin/bash

NIC=eth2


HWADDR=""
HWADDR=`grep "HWADDR" /etc/sysconfig/network-scripts/ifcfg-${NIC}`
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-${NIC}
DEVICE="${NIC}"
DEVICETYPE="ovs"
TYPE="OVSPort"
OVS_BRIDGE="br-ex"
ONBOOT="yes"
NM_CONTROLLED="no"
${HWADDR:?"error"}

EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-ex
DEVICE="br-ex"
DEVICETYPE="ovs"
TYPE="OVSBridge"
BOOTPROTO="static"
IPADDR="157.1.205.2"
NETMASK="255.255.255.0"
GATEWAY="157.1.205.254"
DNS1=136.187.17.3
DNS2=157.1.24.201
ONBOOT="yes"
NM_CONTROLLED="no"

EOF
