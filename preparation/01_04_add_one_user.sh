#!/bin/bash -x

i=$1

keystone tenant-create --name tenant-${i}
keystone user-create   --name student-${i} --pass "pass-${i}"
keystone user-role-add --user student-${i} --tenant tenant-${i} --role student
keystone user-role-add --user student-${i} --tenant tenant-${i} --role SwiftOperator
keystone user-role-add --user student-${i} --tenant tenant-${i} --role heat_stack_owner

tenant=`openstack project show -f value -c id tenant-${i}`

cinder quota-update --gigabytes 10 $tenant
cinder quota-update --volumes    5 $tenant
cinder quota-update --snapshots  3 $tenant
cinder quota-show $tenant

neutron quota-update --tenant_id $tenant -- --floatingip 2 --router 1

