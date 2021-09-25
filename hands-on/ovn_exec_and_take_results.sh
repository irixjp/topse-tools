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

ssh root@10.10.10.200 /root/ovn_get_state_cc.sh  ${COMMAND_NAME}
ssh root@10.10.10.201 /root/ovn_get_state_com.sh ${COMMAND_NAME}
ssh root@10.10.10.202 /root/ovn_get_state_com.sh ${COMMAND_NAME}

scp root@10.10.10.200:${ROOT_DIR}/* ${STORE_DIR}
scp root@10.10.10.201:${ROOT_DIR}/* ${STORE_DIR}
scp root@10.10.10.202:${ROOT_DIR}/* ${STORE_DIR}

ssh root@10.10.10.200 rm -rf /root/ovn/*
ssh root@10.10.10.201 rm -rf /root/ovn/*
ssh root@10.10.10.202 rm -rf /root/ovn/*

