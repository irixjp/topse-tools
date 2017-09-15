#!/bin/bash -x

cd /root
source ~/keystonerc_admin

USERLIST='29005
29011
29014
29017
29020
29024
29026
29029
29032
29036
29037
29038
29040
29041
29045
2017004'

for i in $USERLIST
do
  openstack project create tenant-${i}
  openstack user create --project tenant-${i} --password pass-${i} student-${i}
  openstack role add --user student-${i} --project tenant-${i} student
  openstack role add --user student-${i} --project tenant-${i} SwiftOperator
  openstack role add --user student-${i} --project tenant-${i} heat_stack_owner
  openstack quota set --instances 5 --floating-ips 2 --ram 40960 --volumes 5 --gigabytes 10 --snapshots 3 --cores 20 --routers 1 tenant-${i}
done

