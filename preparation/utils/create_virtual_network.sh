#!/bin/bash

function gen_mac () {
    python macgen.py
}

MAC=`gen_mac`

UUID=`uuidgen`

cat << _EOF_ > virbr100.xml
<network>
  <name>virbr100</name>
  <uuid>${UUID}</uuid>
  <forward mode='nat'/>
  <bridge name='virbr100' stp='on' delay='0'/>
  <mac address='${MAC}'/>
  <ip address='192.168.100.254' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.201' end='192.168.100.249'/>
    </dhcp>
  </ip>
</network>
_EOF_

