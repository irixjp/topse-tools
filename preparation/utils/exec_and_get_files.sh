#!/bin/bash
ROOT_DIR=/root/ovn
STORE_DIR=/root/ovn_state

if [ "$1" = "" ]
then
    echo "no argument"
    exit 1
fi

COMMAND_NAME=$1

mkdir -p ${STORE_DIR}

ssh root@192.168.122.100 /root/get_state_cc.sh  ${COMMAND_NAME}
ssh root@192.168.122.101 /root/get_state_com.sh ${COMMAND_NAME}
ssh root@192.168.122.102 /root/get_state_com.sh ${COMMAND_NAME}
ssh root@192.168.122.103 /root/get_state_com.sh ${COMMAND_NAME}

scp root@192.168.122.100:${ROOT_DIR}/* ${STORE_DIR}
scp root@192.168.122.101:${ROOT_DIR}/* ${STORE_DIR}
scp root@192.168.122.102:${ROOT_DIR}/* ${STORE_DIR}
scp root@192.168.122.103:${ROOT_DIR}/* ${STORE_DIR}

ssh root@192.168.122.100 rm -rf /root/ovn/*
ssh root@192.168.122.101 rm -rf /root/ovn/*
ssh root@192.168.122.102 rm -rf /root/ovn/*
ssh root@192.168.122.103 rm -rf /root/ovn/*
