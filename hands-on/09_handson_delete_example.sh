#!/bin/bash -ex

source keystonerc_admin

openstack server delete test-vm-1 test-vm-2 test-vm-3
sleep 3
openstack port delete port77-11 port88-22 port99-22 port99-33
sleep 3
openstack volume delete clone-boot-vol
sleep 3
openstack volume snapshot delete boot-vol-snap
sleep 3
openstack volume delete boot-vol

openstack keypair delete key-temp

openstack router remove subnet Ext-Router 1st-subnet
openstack router remove subnet Ext-Router 2nd-subnet
openstack router remove subnet Closed-Router 3rd-subnet

openstack router unset Ext-Router --external-gateway

FIPs=`openstack floating ip list -f value -c ID`
for FIP in ${FIPs:?}
do
    openstack floating ip delete ${FIP:?}
done

openstack network delete public
openstack network delete 1st-net
openstack network delete 2nd-net
openstack network delete 3rd-net

openstack router delete Ext-Router
openstack router delete Closed-Router

openstack security group delete open-all

openstack image delete cirros
openstack flavor delete my.standard

openstack server list
openstack image list
openstack flavor list
openstack network list
openstack subnet list
openstack router list
openstack security group list
openstack security group rule list
openstack volume list
openstack volume snapshot list
openstack port list

echo "### done ###"

