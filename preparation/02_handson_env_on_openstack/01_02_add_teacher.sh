##
## !! put password !!
##

## for running tools
keystone tenant-create --name topse01

keystone role-create   --name teacher
keystone user-create   --name teacher01 --pass ''
keystone user-role-add --user teacher01 --tenant topse01 --role teacher
keystone user-role-add --user teacher01 --tenant topse01 --role SwiftOperator
keystone user-role-add --user teacher01 --tenant topse01 --role heat_stack_owner

cinder quota-update --gigabytes 10 teacher01
cinder quota-update --volumes    5 teacher01
cinder quota-update --snapshots  3 teacher01
cinder quota-show teacher01
neutron quota-update --tenant_id teacher01 -- --floatingip 2 --router 1


## for checking environemnt
keystone tenant-create --name topse02
keystone user-create   --name teacher02 --pass ''
keystone user-role-add --user teacher02 --tenant topse02 --role teacher
keystone user-role-add --user teacher02 --tenant topse02 --role SwiftOperator
keystone user-role-add --user teacher02 --tenant topse02 --role heat_stack_owner

cinder quota-update --gigabytes 100 teacher02
cinder quota-update --volumes    10 teacher02
cinder quota-update --snapshots  10 teacher02
cinder quota-show teacher02

tenant=$(openstack project list | awk '/topse02/ {print $2}')

nova quota-update --instances 300  $tenant
nova quota-update --cores 1200     $tenant
nova quota-update --ram 5120000    $tenant
neutron quota-update --tenant_id $tenant -- --floatingip 100 --router 100 --network 100 --port 1000

## for student role
keystone role-create --name student
