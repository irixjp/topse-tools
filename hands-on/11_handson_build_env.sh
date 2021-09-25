#!/bin/bash -ex

source keystonerc_admin

openstack flavor create --public --id 99 --vcpus 1 --ram 1024 --disk 10 --ephemeral 0 --swap 0 my.standard

openstack network create public --external --provider-network-type flat --provider-physical-network extnet
openstack subnet create public-subnet --network public --ip-version 4 --subnet-range 10.30.30.0/24 --gateway 10.30.30.254 --no-dhcp --allocation-pool start=10.30.30.210,end=10.30.30.230

openstack role create student

curl -O http://reposerver/images/cirros-0.5.2-x86_64-disk.img
openstack image create --container-format bare --disk-format qcow2 --min-disk 1 --min-ram 1024 --public --file cirros-0.5.2-x86_64-disk.img cirros


for i in 001 002
do
    openstack project create tenant-${i}
    openstack user create --project tenant-${i} --password pass-${i} student-${i}
    openstack role add --user student-${i} --project tenant-${i} student
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
openstack security group rule create open-all --protocol tcp --dst-port 1:65535 --remote-ip 0.0.0.0/0
openstack security group rule create open-all --protocol udp --dst-port 1:65535 --remote-ip 0.0.0.0/0
openstack security group rule create open-all --protocol icmp --remote-ip 0.0.0.0/0

openstack router create Ext-Router
openstack router set Ext-Router --external-gateway public

openstack network create work-net
openstack subnet create work-subnet --network work-net --ip-version 4 --subnet-range 10.99.99.0/24 --gateway 10.99.99.254 --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4
openstack network list
openstack subnet list

openstack router add subnet Ext-Router work-subnet

openstack keypair create key-student001 | tee key-student001.pem
chmod 600 key-student001.pem

### student002
source openrc_student002
openstack security group create --description "allow all communications" open-all
openstack security group rule create open-all --protocol tcp --dst-port 1:65535 --remote-ip 0.0.0.0/0
openstack security group rule create open-all --protocol udp --dst-port 1:65535 --remote-ip 0.0.0.0/0
openstack security group rule create open-all --protocol icmp --remote-ip 0.0.0.0/0

openstack router create Ext-Router
openstack router set Ext-Router --external-gateway public

openstack network create work-net
openstack subnet create work-subnet --network work-net --ip-version 4 --subnet-range 10.99.99.0/24 --gateway 10.99.99.254 --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4
openstack network list
openstack subnet list

openstack router add subnet Ext-Router work-subnet

openstack keypair create key-student002 | tee key-student002.pem
chmod 600 key-student002.pem

