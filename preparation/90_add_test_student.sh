#!/bin/bash -x

cd /root
source ~/keystonerc_admin

USERLIST='0000
9999'

openstack role create student

for i in $USERLIST
do
  openstack project create tenant-${i}
  openstack user create --project tenant-${i} --password pass-${i} student-${i}
  openstack role add --user student-${i} --project tenant-${i} student
  openstack role add --user student-${i} --project tenant-${i} SwiftOperator
  openstack role add --user student-${i} --project tenant-${i} heat_stack_owner
  openstack role add --user admin        --project tenant-${i} admin
  openstack quota set --instances 5 --floating-ips 2 --ram 40960 --volumes 5 --gigabytes 10 --snapshots 3 --cores 20 --routers 1 tenant-${i}
done
