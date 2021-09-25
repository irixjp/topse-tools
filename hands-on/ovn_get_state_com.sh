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
  )

exec_get_info
