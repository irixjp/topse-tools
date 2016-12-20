yum install -y qemu-kvm libvirt virt-manager virt-install pykickstart

ksvalidator simple-centos7-ks.cfg

virsh destroy test-rdo-cc
virsh destroy test-rdo-compute
virsh undefine test-rdo-cc --remove-all-storage
virsh undefine test-rdo-compute --remove-all-storage

qemu-img create -f qcow2 /var/lib/libvirt/images/test-rdo-cc.qcow2 100G
qemu-img create -f qcow2 /var/lib/libvirt/images/test-rdo-compute.qcow2 100G

virt-install \
  --name=test-rdo-cc \
  --virt-type kvm --hvm \
  --accelerate \
  --nographics --noautoconsole \
  --vcpus=2 \
  --ram=8192 \
  --disk /var/lib/libvirt/images/test-rdo-cc.qcow2,format=qcow2 \
  --network network=default \
  --location=http://ftp.iij.ad.jp/pub/linux/centos/7/os/x86_64/ \
  --initrd-inject simple-centos7-ks.cfg \
  --extra-args='inst.ks=file:/simple-centos7-ks.cfg console=tty0 console=ttyS0,115200n8 serial'

virt-install \
  --name=test-rdo-compute \
  --virt-type kvm --hvm \
  --accelerate \
  --nographics --noautoconsole \
  --vcpus=2 \
  --ram=8192 \
  --disk /var/lib/libvirt/images/test-rdo-compute.qcow2,format=qcow2 \
  --network network=default \
  --location=http://ftp.iij.ad.jp/pub/linux/centos/7/os/x86_64/ \
  --initrd-inject simple-centos7-ks.cfg \
  --extra-args='inst.ks=file:/simple-centos7-ks.cfg console=tty0 console=ttyS0,115200n8 serial'

systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network

/etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
TYPE=Ethernet
BOOTPROTO=dhcp
ONBOOT=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
EOF

packstack \
--default-password=passwd \
--gen-answer-file=answer.txt \
--allinone

packstack --answer-file=answer.txt
