#!/bin/bash -ex

curl -O reposerver/hands-on/ovn_exec_and_take_results.sh
curl -O reposerver/hands-on/ovn_get_state_cc.sh
curl -O reposerver/hands-on/ovn_get_state_com.sh

chmod +x ovn_exec_and_take_results.sh
chmod +x ovn_get_state_cc.sh
chmod +x ovn_get_state_com.sh

scp -p ovn_get_state_com.sh root@10.10.10.201:/root
scp -p ovn_get_state_com.sh root@10.10.10.202:/root

sleep 3 && ./ovn_exec_and_take_results.sh initial_state > /dev/null

source keystonerc_admin

openstack flavor create --public --id 99 --vcpus 1 --ram 1024 --disk 10 --ephemeral 0 --swap 0 my.standard

openstack network create public --external --provider-network-type flat --provider-physical-network extnet
sleep 3 && ./ovn_exec_and_take_results.sh create_public_network > /dev/null

openstack subnet create public-subnet --network public --ip-version 4 --subnet-range 10.30.30.0/24 --gateway 10.30.30.254 --no-dhcp --allocation-pool start=10.30.30.210,end=10.30.30.230
sleep 3 && ./ovn_exec_and_take_results.sh create_public_subnet > /dev/null

curl -O http://reposerver/images/cirros-0.5.2-x86_64-disk.img
openstack image create --container-format bare --disk-format qcow2 --min-disk 1 --min-ram 1024 --public --file cirros-0.5.2-x86_64-disk.img cirros

openstack role create student

for i in 001 002
do
    openstack project create tenant-${i}
    openstack user create --project tenant-${i} --password pass-${i} student-${i}
    openstack role add --user student-${i} --project tenant-${i} student
    openstack quota set --instances 50 --cores 512 --ram 512000 tenant-${i}
done

unset OS_USERNAME
unset OS_PASSWORD
unset OS_REGION_NAME
unset OS_AUTH_URL
unset OS_PROJECT_NAME
unset OS_USER_DOMAIN_NAME
unset OS_PROJECT_DOMAIN_NAME
unset OS_IDENTITY_API_VERSION

STUDENT_NUM=001
cat << EOF > openrc_student001
unset OS_USERNAME
unset OS_PASSWORD
unset OS_REGION_NAME
unset OS_AUTH_URL
unset OS_PROJECT_NAME
unset OS_USER_DOMAIN_NAME
unset OS_PROJECT_DOMAIN_NAME
unset OS_IDENTITY_API_VERSION

export OS_AUTH_URL=http://10.10.10.200:5000/v3
export OS_PROJECT_NAME="tenant-${STUDENT_NUM}"
export OS_USERNAME="student-${STUDENT_NUM}"
export OS_PASSWORD="pass-${STUDENT_NUM}"
export OS_REGION_NAME="RegionOne"
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_ID="default"
export OS_INTERFACE=public
export OS_IDENTITY_API_VERSION=3
export PS1='[\u@\h \W(student-001)]\$ '
EOF

STUDENT_NUM=002
cat << EOF > openrc_student002
unset OS_USERNAME
unset OS_PASSWORD
unset OS_REGION_NAME
unset OS_AUTH_URL
unset OS_PROJECT_NAME
unset OS_USER_DOMAIN_NAME
unset OS_PROJECT_DOMAIN_NAME
unset OS_IDENTITY_API_VERSION

export OS_AUTH_URL=http://10.10.10.200:5000/v3
export OS_PROJECT_NAME="tenant-${STUDENT_NUM}"
export OS_USERNAME="student-${STUDENT_NUM}"
export OS_PASSWORD="pass-${STUDENT_NUM}"
export OS_REGION_NAME="RegionOne"
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_ID="default"
export OS_INTERFACE=public
export OS_IDENTITY_API_VERSION=3
export PS1='[\u@\h \W(student-002)]\$ '
EOF

### student001
source openrc_student001
openstack security group create --description "allow all communications" open-all
sleep 3 && ./ovn_exec_and_take_results.sh create_secgrp_001 > /dev/null
openstack security group rule create open-all --protocol tcp --dst-port 1:65535 --remote-ip 0.0.0.0/0
sleep 3 && ./ovn_exec_and_take_results.sh add_tcp_rules_001 > /dev/null
openstack security group rule create open-all --protocol udp --dst-port 1:65535 --remote-ip 0.0.0.0/0
sleep 3 && ./ovn_exec_and_take_results.sh add_udp_rules_001 > /dev/null
openstack security group rule create open-all --protocol icmp --remote-ip 0.0.0.0/0
sleep 3 && ./ovn_exec_and_take_results.sh add_icmp_rule_001 > /dev/null

openstack router create Ext-Router
sleep 3 && ./ovn_exec_and_take_results.sh create_ext_router_001 > /dev/null
openstack router set Ext-Router --external-gateway public
sleep 3 && ./ovn_exec_and_take_results.sh connect_ext_router_to_public_001 > /dev/null

openstack network create work-net
sleep 3 && ./ovn_exec_and_take_results.sh create_work_net_001 > /dev/null
openstack subnet create work-subnet --network work-net --ip-version 4 --subnet-range 10.99.99.0/24 --gateway 10.99.99.254 --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4
sleep 3 && ./ovn_exec_and_take_results.sh create_work_subnet_001 > /dev/null
openstack network list
openstack subnet list

openstack router add subnet Ext-Router work-subnet
sleep 3 && ./ovn_exec_and_take_results.sh connect_ext_router_to_work_net_001 > /dev/null

openstack keypair create key-student001 | tee key-student001.pem
chmod 600 key-student001.pem

### student002
source openrc_student002
openstack security group create --description "allow all communications" open-all
sleep 3 && ./ovn_exec_and_take_results.sh create_secgrp_002 > /dev/null
openstack security group rule create open-all --protocol tcp --dst-port 1:65535 --remote-ip 0.0.0.0/0
sleep 3 && ./ovn_exec_and_take_results.sh add_tcp_rules_002 > /dev/null
openstack security group rule create open-all --protocol udp --dst-port 1:65535 --remote-ip 0.0.0.0/0
sleep 3 && ./ovn_exec_and_take_results.sh add_udp_rules_002 > /dev/null
openstack security group rule create open-all --protocol icmp --remote-ip 0.0.0.0/0
sleep 3 && ./ovn_exec_and_take_results.sh add_icmp_rule_002 > /dev/null

openstack router create Ext-Router
sleep 3 && ./ovn_exec_and_take_results.sh create_ext_router_002 > /dev/null
openstack router set Ext-Router --external-gateway public
sleep 3 && ./ovn_exec_and_take_results.sh connect_ext_router_to_public_002 > /dev/null

openstack network create work-net
sleep 3 && ./ovn_exec_and_take_results.sh create_work_net_002 > /dev/null
openstack subnet create work-subnet --network work-net --ip-version 4 --subnet-range 10.99.99.0/24 --gateway 10.99.99.254 --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4
sleep 3 && ./ovn_exec_and_take_results.sh create_work_subnet_002 > /dev/null
openstack network list
openstack subnet list

openstack router add subnet Ext-Router work-subnet
sleep 3 && ./ovn_exec_and_take_results.sh connect_ext_router_to_work_net_002 > /dev/null

openstack keypair create key-student002 | tee key-student002.pem
chmod 600 key-student002.pem

