#!/bin/bash -ex

curl -O reposerver/hands-on/ovn_get_state_cc.sh
chmod +x ovn_get_state_cc.sh

./ovn_get_state_cc.sh initial_state

source keystonerc_admin

# flavor
openstack flavor create --public --id 99 --vcpus 1 --ram 1024 --disk 10 --ephemeral 0 --swap 0 my.standard

# public network
openstack network create public --external --provider-network-type flat --provider-physical-network extnet
sleep 3 && ./ovn_get_state_cc.sh initial_state create_public_network

# public subnet
openstack subnet create public-subnet --network public --ip-version 4 --subnet-range 10.30.30.0/24 --gateway 10.30.30.254 --no-dhcp --allocation-pool start=10.30.30.160,end=10.30.30.180
sleep 3 && ./ovn_get_state_cc.sh initial_state create_public_subnet

# image
curl -O http://reposerver/images/cirros-0.5.2-x86_64-disk.img
openstack image create --container-format bare --disk-format qcow2 --min-disk 1 --min-ram 1024 --public --file cirros-0.5.2-x86_64-disk.img cirros

# security group
openstack security group create --description "allow all communications" open-all
sleep 3 && ./ovn_get_state_cc.sh create_secgrp
openstack security group rule create open-all --protocol tcp --dst-port 1:65535 --remote-ip 0.0.0.0/0
sleep 3 && ./ovn_get_state_cc.sh add_tcp_rules
openstack security group rule create open-all --protocol udp --dst-port 1:65535 --remote-ip 0.0.0.0/0
sleep 3 && ./ovn_get_state_cc.sh add_udp_rules
openstack security group rule create open-all --protocol icmp --remote-ip 0.0.0.0/0
sleep 3 && ./ovn_get_state_cc.sh add_icmp_rule

# Router
openstack router create Ext-Router
sleep 3 && ./ovn_get_state_cc.sh create_ext_router
openstack router create Closed-Router
sleep 3 && ./ovn_get_state_cc.sh create_closed_router

openstack router set Ext-Router --external-gateway public
sleep 3 && ./ovn_get_state_cc.sh connect_ext_router_to_public

# internal network
openstack network create 1st-net
sleep 3 && ./ovn_get_state_cc.sh create_1st_net
openstack subnet create 1st-subnet --network 1st-net --ip-version 4 --subnet-range 10.77.77.0/24 --gateway 10.77.77.254 --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4
sleep 3 && ./ovn_get_state_cc.sh create_1st_subnet

openstack network create 2nd-net
sleep 3 && ./ovn_get_state_cc.sh create_2nd_net
openstack subnet create 2nd-subnet --network 2nd-net --ip-version 4 --subnet-range 10.88.88.0/24 --gateway 10.88.88.254 --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4
sleep 3 && ./ovn_get_state_cc.sh create_2nd_subnet

openstack network create 3rd-net
sleep 3 && ./ovn_get_state_cc.sh create_3rd_net
openstack subnet create 3rd-subnet --network 3rd-net --ip-version 4 --subnet-range 10.99.99.0/24 --gateway 10.99.99.254
sleep 3 && ./ovn_get_state_cc.sh create_3rd_subnet

openstack router add subnet Ext-Router 1st-subnet
sleep 3 && ./ovn_get_state_cc.sh connect_ext_router_to_1st_net
openstack router add subnet Ext-Router 2nd-subnet
sleep 3 && ./ovn_get_state_cc.sh connect_ext_router_to_2nd_net
openstack router add subnet Closed-Router 3rd-subnet
sleep 3 && ./ovn_get_state_cc.sh connect_closed_router_to_3rd_net

# port
openstack port create port77-11 --network 1st-net --security-group open-all --fixed-ip subnet=1st-subnet,ip-address=10.77.77.11
sleep 3 && ./ovn_get_state_cc.sh create_port77_11
openstack port create port88-22 --network 2nd-net --security-group open-all --fixed-ip subnet=2nd-subnet,ip-address=10.88.88.22
sleep 3 && ./ovn_get_state_cc.sh create_port88_22
openstack port create port99-22 --network 3rd-net --security-group open-all --fixed-ip subnet=3rd-subnet,ip-address=10.99.99.22
sleep 3 && ./ovn_get_state_cc.sh create_port99_22
openstack port create port99-33 --network 3rd-net --security-group open-all --fixed-ip subnet=3rd-subnet,ip-address=10.99.99.33
sleep 3 && ./ovn_get_state_cc.sh create_port99_33

PORTID77_11=`openstack port list --fixed-ip ip-address=10.77.77.11 -c id -f value`
PORTID88_22=`openstack port list --fixed-ip ip-address=10.88.88.22 -c id -f value`
PORTID99_22=`openstack port list --fixed-ip ip-address=10.99.99.22 -c id -f value`
PORTID99_33=`openstack port list --fixed-ip ip-address=10.99.99.33 -c id -f value`

# volume
openstack volume create --size 1 --image cirros boot-vol

BOOT_VOL_STAT=`openstack volume show boot-vol -f json | jq -r .status`
RETVAL=1
while [ "$RETVAL" = 1 ]
do
    echo "#### waiting to create boot volume ..."
    if [ ${BOOT_VOL_STAT:?} == "available" ]; then
        RETVAL=0
        echo done
    else
        sleep 5
        BOOT_VOL_STAT=`openstack volume show boot-vol -f json | jq -r .status`
    fi
done

openstack volume snapshot create --volume boot-vol boot-vol-snap
sleep 5
openstack volume create --snapshot boot-vol-snap clone-boot-vol

# keypair
openstack keypair create key-temp | tee key-temp.pem
chmod 600 key-temp.pem

# instance
openstack server create test-vm-1 --flavor my.standard --image "cirros" --key-name key-temp --nic port-id=${PORTID77_11}
INSTANCE_STAT=`openstack server show test-vm-1 -f json | jq -r .status`
RETVAL=1
while [ "$RETVAL" = 1 ]
do
    echo "#### waiting to create instance ..."
    if [ ${INSTANCE_STAT:?} == "ACTIVE" ]; then
        RETVAL=0
        echo done
    else
        sleep 5
        INSTANCE_STAT=`openstack server show test-vm-1 -f json | jq -r .status`
    fi
done
sleep 3 && ./ovn_get_state_cc.sh create_test_vm_1

openstack server create test-vm-2 --flavor my.standard --image "cirros" --key-name key-temp --nic port-id=${PORTID88_22} --nic port-id=${PORTID99_22}
INSTANCE_STAT=`openstack server show test-vm-2 -f json | jq -r .status`
RETVAL=1
while [ "$RETVAL" = 1 ]
do
    echo "#### waiting to create instance ..."
    if [ ${INSTANCE_STAT:?} == "ACTIVE" ]; then
        RETVAL=0
        echo done
    else
        sleep 5
        INSTANCE_STAT=`openstack server show test-vm-2 -f json | jq -r .status`
    fi
done
sleep 3 && ./ovn_get_state_cc.sh create_test_vm_2

openstack server create test-vm-3 --flavor my.standard --key-name key-temp --volume boot-vol --nic port-id=${PORTID99_33}
INSTANCE_STAT=`openstack server show test-vm-3 -f json | jq -r .status`
RETVAL=1
while [ "$RETVAL" = 1 ]
do
    echo "#### waiting to create instance ..."
    if [ ${INSTANCE_STAT:?} == "ACTIVE" ]; then
        RETVAL=0
        echo done
    else
        sleep 5
        INSTANCE_STAT=`openstack server show test-vm-3 -f json | jq -r .status`
    fi
done
sleep 3 && ./ovn_get_state_cc.sh create_test_vm_3

openstack server list

# floating ip
FIP1=`openstack floating ip create public -f json | jq -r .floating_ip_address`
sleep 3 && ./ovn_get_state_cc.sh create_fip_${FIP1:?}
FIP2=`openstack floating ip create public -f json | jq -r .floating_ip_address`
sleep 3 && ./ovn_get_state_cc.sh create_fip_${FIP2:?}

openstack server add floating ip test-vm-1 ${FIP1:?}
sleep 3 && ./ovn_get_state_cc.sh assoc_fip_${FIP1:?}
openstack server add floating ip test-vm-2 ${FIP2:?}
sleep 3 && ./ovn_get_state_cc.sh assoc_fip_${FIP2:?}

# output
openstack server list
openstack network list
openstack subnet list
openstack router list
openstack volume list
openstack volume snapshot list

echo "##########"
echo "## done ##"
echo "##########"

