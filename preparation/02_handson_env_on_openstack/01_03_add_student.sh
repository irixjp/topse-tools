#!/bin/bash -x

USERLIST='12345678
48156104
48156106
48156216
48136617
48156630
48166102
48166111
48166114
48166121
48166128
48166133
48166215
48166301
48166303
48166314
48166323
48166324
48166333
48166401
48166405
48166406
48166409
48166412
48166421
48166423
48166425
48166433
48166434
48166436
48166437
48166439
48166440
48166451
48166454
48166504
48166508
48166511
48166516
48166519
48166520
48166525
48166527
48166534
48166536
48156636
48156639
48166601
48166603
48166606
48166610
48166613
48166614
48166615
48166617
48166619
48166621
48166623
48166624
48166627
48166628
48166630
48166631
48166633
48147412
48157306
48167416
47156803'

for i in $USERLIST
do

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

done
