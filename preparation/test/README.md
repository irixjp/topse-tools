テスト環境の整備
```
bash ./create_virtual_network.sh
virsh net-define ./virbr100.xml
virsh net-start virbr100
```

```
cd /mnt/topse-tools/preparation/test
ansible localhost -i etc/ansible_hosts -u root -m ping

chmod 600 ansible_key
export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i etc/ansible_hosts -u root 01_create_instances.yaml
ansible-playbook -i etc/ansible_hosts -u root --private-key=ansible_key 02_pre-configuration.yaml
ansible-playbook -i etc/ansible_hosts -u root --private-key=ansible_key 03_reboot.yaml
ansible-playbook -i etc/ansible_hosts -u root --private-key=ansible_key 04_test-pre-configurations.yaml
ansible-playbook -i etc/ansible_hosts -u root --private-key=ansible_key 05_install-openstack.yaml
ansible-playbook -i etc/ansible_hosts -u root --private-key=ansible_key 06_reboot.yaml
```

構築環境での確認
```
ssh -o "StrictHostKeyChecking=no" root@192.168.100.100 -i /mnt/topse-tools/preparation/test/ansible_key
git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2017-02
git checkout -b ${BRANCH_NAME} remotes/origin/${BRANCH_NAME}

cd ~/
source keystonerc_admin

cd ~/topse-tools/preparation/test/
heat stack-create --poll -f 07_heat_basic_setting.yaml default

openstack quota set --instances 500 --floating-ips 100 --ram 819200 --volumes 100 --gigabytes 300 --cores 300 topse01
openstack quota set --instances 5 --floating-ips 2 --ram 40960 --volumes 10 --gigabytes 10 --cores 20 topse02

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

glance --os-image-api-version 1 image-create \
--name "CentOS7" \
--disk-format qcow2 --container-format bare \
--copy-from http://reposerver/images/CentOS-7-x86_64-GenericCloud.qcow2 \
--is-public True --is-protected True \
--progress

openstack image list
```

リソース作成テスト1
```
source openrc_teacher01
heat stack-create --poll -f test_default.yaml -P "password=password" -P "reposerver=157.1.141.21" test_console

source ../../hands-on/support.sh
get_heat_output test_console floating_ip

ssh centos@console

git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2017-02
git checkout -b ${BRANCH_NAME} remotes/origin/${BRANCH_NAME}

cd preparation/test/
source openrc_teacher01
source ../../handson/support.sh
```

リソース作成テスト2
```
CLUSTER=3
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.tiny" test_massive1
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.small" test_massive2
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.medium" test_massive3
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.large" test_massive4
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.xlarge" test_massive5

nova list

heat stack-delete -y test_massive1
heat stack-delete -y test_massive2
heat stack-delete -y test_massive3
heat stack-delete -y test_massive4
heat stack-delete -y test_massive5
```

リソース作成テスト3
```
repo=`get_reposerver`; echo $repo
heat stack-create --poll -f test_cluster.yaml -P "reposerver=${repo}" test_cluster

URL=`get_heat_output test_cluster lburl`; echo $URL
for i in `seq 1 20`; do curl $URL; sleep 1; done

heat stack-update -f test_cluster.yaml -P "reposerver=${repo}" -P cluster_size=6 test_cluster
heat stack-list
for i in `seq 1 60`; do curl $URL; sleep 1; done

heat stack-delete -y test_cluster
```

リソース作成テスト4
```
heat stack-create -f test_simple_server.yaml -P "flavor=m1.tiny" test_update_stack
heat stack-list

heat stack-update -f test_simple_server.yaml -P "flavor=m1.small" test_update_stack
nova list

heat stack-update -f test_simple_server.yaml -P "flavor=m1.medium" test_update_stack
nova list

heat stack-delete -y test_update_stack

heat stack-delete -y test_console
```
