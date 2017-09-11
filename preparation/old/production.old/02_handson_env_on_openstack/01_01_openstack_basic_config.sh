source keystonerc_admin

glance --os-image-api-version 1 image-create \
       --name "CentOS6-1509" \
       --disk-format qcow2 --container-format bare \
       --copy-from http://reposerver/openstack/images/CentOS-6-x86_64-GenericCloud-1509.qcow2 \
       --is-public True --is-protected True \
       --progress

glance --os-image-api-version 1 image-create \
       --name "CentOS7-1509" \
       --disk-format qcow2 --container-format bare \
       --copy-from http://reposerver/openstack/images/CentOS-7-x86_64-GenericCloud-1509.qcow2 \
       --is-public True --is-protected True \
       --progress

glance --os-image-api-version 1 image-create \
       --name "CentOS7-1603" \
       --disk-format qcow2 --container-format bare \
       --copy-from http://reposerver/openstack/images/CentOS-7-x86_64-GenericCloud-1603.qcow2 \
       --is-public True --is-protected True \
       --progress

glance --os-image-api-version 1 image-create \
       --name "Fedora23-20151030" \
       --disk-format qcow2 --container-format bare \
       --copy-from http://reposerver/openstack/images/Fedora-Cloud-Base-23-20151030.x86_64.qcow2 \
       --is-public True --is-protected True \
       --progress

glance --os-image-api-version 1 image-create \
       --name "Student-Console-VM" \
       --disk-format qcow2 --container-format bare \
       --copy-from http://reposerver/openstack/images/Student-Console-CentOS7-Cloud-Base-23-20160423.x86_64.v1.qcow2 \
       --is-public True --is-protected True \
       --progress

glance --os-image-api-version 1 image-create \
       --name "cirros" \
       --disk-format qcow2 --container-format bare \
       --copy-from http://reposerver/openstack/images/cirros-0.3.4-x86_64-disk.qcow2 \
       --is-public True --is-protected True \
       --progress

glance --os-image-api-version 1 image-create \
       --name "CentOS7-Docker" \
       --disk-format qcow2 --container-format bare \
       --copy-from http://reposerver/openstack/images/CentOS-7-201160330-with-docker-v3.qcow2 \
       --is-public True --is-protected True \
       --progress

glance --os-image-api-version 1 image-create \
       --name "CentOS7-Heat" \
       --disk-format qcow2 --container-format bare \
       --copy-from http://reposerver/openstack/images/CentOS-7-201160408-with-heat-v2.qcow2 \
       --is-public True --is-protected True \
       --progress

glance --os-image-api-version 1 image-create \
       --name "Ubuntu14.04_LTS" \
       --disk-format qcow2 --container-format bare \
       --copy-from http://reposerver/openstack/images/trusty-server-cloudimg-amd64-disk1.img \
       --is-public True --is-protected True \
       --progress

glance image-list


nova quota-class-update --instances    5 default
nova quota-class-update --floating_ips 2 default
nova quota-defaults

nova flavor-delete 1
nova flavor-delete 2
nova flavor-delete 3
nova flavor-delete 4
nova flavor-delete 5

nova flavor-create m1.tiny   100 1024 10  1
nova flavor-create m1.small  101 2048 10  1
nova flavor-create m1.medium 102 4096 20  1
nova flavor-create m1.large  103 8192 100 2
nova flavor-create m1.xlarge 104 8192 200 4

nova flavor-list


FIP_START=157.1.205.101
FIP_END=157.1.205.250
FIP_CIDR=157.1.205.0/24
EXT_GW=157.1.205.254

neutron net-create --router:external public
neutron subnet-create --name public-subnet \
  --allocation-pool start=${FIP_START},end=${FIP_END} \
  --disable-dhcp \
  --gateway ${EXT_GW} \
  public ${FIP_CIDR}

