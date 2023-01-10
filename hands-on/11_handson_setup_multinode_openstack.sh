#!/bin/bash -ex

### install openstack
dnf install -y openstack-packstack

packstack --dry-run --allinone --default-password=password --provision-demo=n --gen-answer-file /root/openstack-answer.txt

crudini --set /root/openstack-answer.txt general CONFIG_NOVA_INSTALL y
crudini --set /root/openstack-answer.txt general CONFIG_GLANCE_INSTALL y
crudini --set /root/openstack-answer.txt general CONFIG_CINDER_INSTALL y
crudini --set /root/openstack-answer.txt general CONFIG_NEUTRON_INSTALL y
crudini --set /root/openstack-answer.txt general CONFIG_HORIZON_INSTALL y
crudini --set /root/openstack-answer.txt general CONFIG_SWIFT_INSTALL y
crudini --set /root/openstack-answer.txt general CONFIG_HEAT_INSTALL n
crudini --set /root/openstack-answer.txt general CONFIG_HEAT_CFN_INSTALL n
crudini --set /root/openstack-answer.txt general CONFIG_AODH_INSTALL n
crudini --set /root/openstack-answer.txt general CONFIG_CEILOMETER_INSTALL n
crudini --set /root/openstack-answer.txt general CONFIG_PROVISION_DEMO n
crudini --set /root/openstack-answer.txt general CONFIG_NEUTRON_METERING_AGENT_INSTALL n
crudini --set /root/openstack-answer.txt general CONFIG_COMPUTE_HOSTS 10.10.10.201,10.10.10.202
crudini --set /root/openstack-answer.txt general CONFIG_NEUTRON_OVN_BRIDGE_MAPPINGS extnet:br-ex
crudini --set /root/openstack-answer.txt general CONFIG_NEUTRON_OVN_EXTERNAL_PHYSNET extnet
crudini --set /root/openstack-answer.txt general CONFIG_NEUTRON_OVN_BRIDGE_IFACES br-ex:eth2
crudini --set /root/openstack-answer.txt general CONFIG_NEUTRON_OVN_TUNNEL_IF eth1
crudini --set /root/openstack-answer.txt general CONFIG_NEUTRON_OVN_TUNNEL_SUBNETS 10.20.20.0/24
crudini --set /root/openstack-answer.txt general CONFIG_CINDER_VOLUMES_SIZE 10G
crudini --set /root/openstack-answer.txt general CONFIG_SWIFT_STORAGE_SIZE 5G

time packstack --answer-file /root/openstack-answer.txt

### openstack setting

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 path_mtu 1400
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_geneve vni_ranges 10:100
crudini --set /etc/cinder/cinder.conf lvm volume_clear none

echo "*         hard    nofile      600000" >> /etc/security/limits.conf
echo "*         soft    nofile      600000" >> /etc/security/limits.conf
echo "root      hard    nofile      600000" >> /etc/security/limits.conf
echo "root      soft    nofile      600000" >> /etc/security/limits.conf
echo "# End of file" >> /etc/security/limits.conf

mkdir /etc/systemd/system/mariadb.service.d/
crudini --set /etc/systemd/system/mariadb.service.d/limits.conf Service LimitNOFILE 600000
systemctl daemon-reload
systemctl restart mariadb

crudini --set /etc/nova/nova.conf libvirt virt_type kvm
crudini --set /etc/nova/nova.conf libvirt cpu_mode host-passthrough
crudini --set /etc/nova/nova.conf vnc enabled true
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://10.10.10.200:6080/vnc_auto.html
crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc keymap ja
crudini --set /etc/nova/nova.conf DEFAULT cpu_allocation_ratio 16
crudini --set /etc/nova/nova.conf DEFAULT ram_allocation_ratio 1.5
crudini --set /etc/nova/nova.conf DEFAULT disk_allocation_ratio 3
crudini --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host true
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address 10.10.10.200

ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf libvirt virt_type kvm'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf libvirt cpu_mode host-passthrough'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf vnc enabled true'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://10.10.10.200:6080/vnc_auto.html'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf vnc keymap ja'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf DEFAULT cpu_allocation_ratio 16'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf DEFAULT ram_allocation_ratio 1.5'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf DEFAULT disk_allocation_ratio 3'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host true'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'crudini --set /etc/nova/nova.conf vnc server_proxyclient_address 10.10.10.201'
ssh -o StrictHostKeyChecking=no root@10.10.10.201 'echo "" >> /etc/nova/migration/identity'

ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf libvirt virt_type kvm'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf libvirt cpu_mode host-passthrough'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf vnc enabled true'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://10.10.10.200:6080/vnc_auto.html'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf vnc keymap ja'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf DEFAULT cpu_allocation_ratio 16'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf DEFAULT ram_allocation_ratio 1.5'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf DEFAULT disk_allocation_ratio 3'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host true'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'crudini --set /etc/nova/nova.conf vnc server_proxyclient_address 10.10.10.202'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'echo "" >> /etc/nova/migration/identity'

ssh -o StrictHostKeyChecking=no root@10.10.10.201 'reboot &'
ssh -o StrictHostKeyChecking=no root@10.10.10.202 'reboot &'
reboot &
