source openrc
openstack stack list

neutron net-create floating-net
neutron subnet-create --ip-version 4 \
                          --gateway 172.16.100.254 \
                          --name floating-subnet \
                          --disable-dhcp floating-net 172.16.100.0/24
neutron router-interface-add Ext-Router floating-subnet
neutron net-list
neutron router-port-list Ext-Router --max-width 40

cd ~/
nova keypair-add my-key | tee my-key.pem
chmod 600 my-key.pem

neutron port-create work-net \
                           --security-group open-all \
                           --fixed-ip subnet_id=work-subnet,ip_address=192.168.199.100
neutron port-create floating-net \
                           --security-group open-all \
                           --fixed-ip subnet_id=floating-subnet,ip_address=172.16.100.100 \
                           --fixed-ip subnet_id=floating-subnet,ip_address=172.16.100.101 \
                           --fixed-ip subnet_id=floating-subnet,ip_address=172.16.100.102 \
                           --fixed-ip subnet_id=floating-subnet,ip_address=172.16.100.103 \
                           --fixed-ip subnet_id=floating-subnet,ip_address=172.16.100.104
neutron port-list -c id -c mac_address -c fixed_ips

cd ~/
wget http://reposerver/hands-on/userdata_pre_openstack.txt
vim userdata_pre_openstack.txt

PORTID1=`neutron port-list --fixed-ips ip_address=192.168.199.100 -c id -f csv --quote none | grep -v id`
PORTID2=`neutron port-list --fixed-ips ip_address=172.16.100.100  -c id -f csv --quote none | grep -v id`
echo $PORTID1
echo $PORTID2
cd ~/
nova boot --flavor m1.large --image "CentOS7" \
                              --user-data userdata_pre_openstack.txt \
                              --key-name my-key \
                              --nic port-id=${PORTID1} --nic port-id=${PORTID2} openstack-single

nova list
nova console-log --length 20 openstack-single
ssh -i my-key.pem root@192.168.199.100

hostname
ip addr
yum repolist


cat /sys/module/kvm_intel/parameters/nested
sysctl -n net.ipv4.ip_forward
sysctl -n net.ipv4.conf.all.forwarding


yum install -y openstack-packstack openstack-utils python-netaddr

packstack --dry-run --allinone --default-password='password' \
                                                          --provision-demo=n --gen-answer-file=answer.txt
ll

crudini --set answer.txt general CONFIG_NAGIOS_INSTALL n
crudini --set answer.txt general CONFIG_SWIFT_INSTALL y
crudini --set answer.txt general CONFIG_HEAT_INSTALL y
crudini --set answer.txt general CONFIG_CEILOMETER_INSTALL n
crudini --set answer.txt general CONFIG_KEYSTONE_REGION RegionOne
crudini --set answer.txt general CONFIG_CINDER_VOLUMES_SIZE 30G
crudini --set answer.txt general CONFIG_SWIFT_STORAGE_SIZE 3G
crudini --set answer.txt general CONFIG_NEUTRON_ML2_TYPE_DRIVERS vxlan,flat
crudini --set answer.txt general CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES vxlan
crudini --set answer.txt general CONFIG_NEUTRON_L3_EXT_BRIDGE br-ex
crudini --set answer.txt general CONFIG_LBAAS_INSTALL y
crudini --set answer.txt general CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS extnet1:br-ex
crudini --set answer.txt general CONFIG_NEUTRON_OVS_TUNNEL_IF eth0
setenforce 0

packstack --answer-file=answer.txt

openstack-config --set /etc/cinder/cinder.conf lvm volume_clear none
openstack-config --set /etc/nova/nova.conf DEFAULT api_rate_limit false
openstack-config --set /etc/nova/nova.conf libvirt virt_type kvm
openstack-config --set /etc/nova/nova.conf libvirt cpu_mode host-passthrough
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_host 0.0.0.0
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_port 6080
openstack-config --set /etc/nova/nova.conf vnc enabled true
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://192.168.199.100:6080/vnc_auto.html
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address 192.168.199.100
openstack-config --set /etc/nova/nova.conf vnc vnc_keymap ja
echo "dhcp-option-force=26,1400" > /etc/neutron/dnsmasq-neutron.conf

ip addr show eth0
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth1
DEVICE="eth1"
BOOTPROT="none"
ONBOOT="yes"
TYPE="OVSPort"
DEVICETYPE="ovs"
OVS_BRIDGE="br-ex"
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-ex
DEVICE="br-ex"
BOOTPROT="none"
ONBOOT="yes"
TYPE="OVSBridge"
DEVICETYPE="ovs"
OVSBOOTPROTO="none"
OVSDHCPINTERFACES="eth1"
EOF

reboot

ssh -i my-key.pem root@192.168.199.100
source keystonerc_admin
nova service-list
cinder service-list
neutron agent-list

wget http://reposerver/images/CentOS-7-x86_64-GenericCloud.qcow2
openstack image create \
                                                 --container-format bare --disk-format qcow2 \
                                                 --min-disk 10 --min-ram 1024 --public \
                                                 --file CentOS-7-x86_64-GenericCloud.qcow2 \
                                                 CentOS7
openstack image list
openstack flavor create --public --id 99 --vcpus 1 --ram 1024 \
                                                                   --disk 10 --ephemeral 0 --swap 0 \
                                                                   my.standard
openstack flavor list

openstack keypair create temp-key-1 | tee temp-key-1.pem
chmod 600 temp-key-1.pem
openstack security group create \
                                                  --description "allow all communications" open-all
openstack security group rule create \
                                                  --proto icmp --src-ip 0.0.0.0/0 open-all
openstack security group rule create \
                                                  --proto tcp --src-ip 0.0.0.0/0 --dst-port 1:65535 \
                                                  open-all
openstack security group rule create \
                                                  --proto udp --src-ip 0.0.0.0/0 --dst-port 1:65535 \
                                                  open-all
openstack security group list
openstack security group rule list open-all

neutron net-create public --router:external=True \
                                           --provider:network_type flat \
                                           --provider:physical_network extnet1
neutron subnet-create --name public-subnet \
                                                 --allocation-pool start=172.16.100.101,end=172.16.100.104 \
                                                 --disable-dhcp \
                                                 --gateway 172.16.100.254 \
                                                 public 172.16.100.0/24
neutron router-create Ext-Router
neutron router-gateway-set Ext-Router public
neutron net-create work-net
neutron subnet-create --ip-version 4 --gateway 10.10.10.254 \
                                                 --name work-subnet \
                                                 --dns-nameserver 8.8.8.8 \
                                                 --dns-nameserver 8.8.4.4 \
                                                 work-net 10.10.10.0/24
neutron router-interface-add Ext-Router work-subnet

