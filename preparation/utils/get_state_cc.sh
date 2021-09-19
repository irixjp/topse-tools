#!/bin/bash
ROOT_DIR=/root/ovn
EXEC_DATE=`date '+%Y%m%d%H%M%S'`

if [ "$1" = "" ]
then
    echo "no argument"
    exit 1
fi

COMMAND_NAME=$1

mkdir -p ${ROOT_DIR}
POSTFIX=_${HOSTNAME}_${EXEC_DATE}_${COMMAND_NAME}.txt

function exec_get_info () {
   for ((i = 0; i < ${#COMMANDS[@]}; i++))
   do
     COMMAND_STR=`echo "${COMMANDS[$i]}" | sed -e 's/ /_/g'`
     eval "${COMMANDS[$i]}" > ${ROOT_DIR}/${COMMAND_STR}${POSTFIX}

   done
}

COMMANDS=(
  "ovs-vsctl show"
  "ovs-ofctl show br-ex"
  "ovs-ofctl show br-int"
  "ovs-ofctl dump-flows br-ex"
  "ovs-ofctl dump-flows br-int"
  "ovn-nbctl list Logical_Switch"
  "ovn-nbctl list Logical_Switch_Port"
  "ovn-nbctl list ACL"
  "ovn-nbctl list Address_Set"
  "ovn-nbctl list Logical_Router"
  "ovn-nbctl list Logical_Router_Port"
  "ovn-nbctl list Gateway_Chassis"
  "ovn-sbctl list Chassis"
  "ovn-sbctl list Encap"
  "ovn-nbctl list Address_Set"
  "ovn-sbctl lflow-list"
  "ovn-sbctl list Multicast_Group"
  "ovn-sbctl list Datapath_Binding"
  "ovn-sbctl list Port_Binding"
  "ovn-sbctl list MAC_Binding"
  "ovn-sbctl list Gateway_Chassis"
  )

exec_get_info
