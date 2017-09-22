function get_uuid () { cat - | grep " id " | awk '{print $4}'; }

function wait_instance () {
RETVAL=1
while [ "$RETVAL" = 1 ]
do
    echo "#### waiting to boot instance ..."
    sleep 5
    nova show $1 | grep " status " | grep ACTIVE
    RETVAL=$?
done
}

function wait_volume () {
RETVAL=1
while [ "$RETVAL" = 1 ]
do
    echo "#### waiting to create bootable volume ..."
    sleep 5
    cinder show $1 | grep " status " | grep available
    RETVAL=$?
done
}

#echo "## creating image"
#wget http://reposerver/images/CentOS-7-x86_64-GenericCloud.qcow2
# 
#openstack image create \
#          --container-format bare --disk-format qcow2 \
#          --min-disk 10 --min-ram 1024 --public \
#          --file CentOS-7-x86_64-GenericCloud.qcow2 \
#CentOS7
# 
#echo "## creating flavor"
#openstack flavor create --public --id 99 --vcpus 1 --ram 1024 \
#          --disk 10 --ephemeral 0 --swap 0 \
#          my.standard
# 
#echo "## creating public network"
#neutron net-create --router:external public
#neutron subnet-create --name public-subnet \
#        --allocation-pool start=172.16.100.101,end=172.16.100.104 \
#        --disable-dhcp \
#        --gateway 172.16.100.254 \
#        public 172.16.100.0/24
# 
#echo "## creating keypair"
#openstack keypair create temp-key-1 | tee /root/temp-key-1.pem
#chmod 600 /root/temp-key-1.pem
# 
#echo "## creating security group"
#neutron security-group-create open-all --description "allow all communications"
#neutron security-group-rule-create --direction ingress --ethertype IPv4 \
#        --protocol icmp \
#        --remote-ip-prefix 0.0.0.0/0 open-all
#neutron security-group-rule-create --direction ingress --ethertype IPv4 \
#        --protocol tcp --port-range-min 1 --port-range-max 65535 \
#        --remote-ip-prefix 0.0.0.0/0 open-all
#neutron security-group-rule-create --direction ingress --ethertype IPv4 \
#        --protocol udp --port-range-min 1 --port-range-max 65535 \
#        --remote-ip-prefix 0.0.0.0/0 open-all

echo "## creating routers"
#neutron router-create Ext-Router
neutron router-create Closed-Router
#neutron router-gateway-set Ext-Router public

echo "## creating 1st network"
neutron net-create work-net
neutron subnet-create --ip-version 4 --gateway 10.10.10.254 \
        --name work-subnet --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 \
        work-net 10.10.10.0/24
neutron router-interface-add Ext-Router work-subnet

echo "## creating 2nd network"
neutron net-create 2nd-net
neutron subnet-create --ip-version 4 --gateway 10.20.20.254 --name 2nd-subnet --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 2nd-net 10.20.20.0/24
neutron router-interface-add Ext-Router 2nd-subnet
sleep 3

echo "## creating 3rd network"
neutron net-create 3rd-net
neutron subnet-create --ip-version 4 --gateway 10.30.30.254 --name 3rd-subnet 3rd-net 10.30.30.0/24
neutron router-interface-add Closed-Router 3rd-subnet
sleep 3

export MY_WORK_NET=`neutron net-show work-net -c id | get_uuid`
export MY_2ND_NET=`neutron net-show 2nd-net   -c id | get_uuid`
export MY_3RD_NET=`neutron net-show 3rd-net   -c id | get_uuid`
sleep 3

echo "## creating boot volume"
IMAGEID=`openstack image show "CentOS7" | get_uuid`
cinder create --display-name boot-vol --image-id $IMAGEID 10

wait_volume boot-vol

VOLID=`cinder show boot-vol | grep " id " | get_uuid`

echo "## creating snapshot & volume"
cinder snapshot-create --display-name boot-vol-snap $VOLID
SNAPID=`cinder snapshot-show boot-vol-snap | get_uuid`
cinder create --snapshot-id $SNAPID --display-name copy-snap-vol 10


echo "## booting instance"
nova boot --flavor my.standard --image "CentOS7" \
--key-name temp-key-1 --security-groups open-all \
--nic net-id=${MY_WORK_NET} \
test-vm-1
wait_instance test-vm-1

nova boot --flavor my.standard --image "CentOS7" \
--key-name temp-key-1 --security-groups open-all \
--nic net-id=${MY_2ND_NET} --nic net-id=${MY_3RD_NET} \
test-vm-2
wait_instance test-vm-2

nova boot --flavor my.standard --boot-volume $VOLID \
--key-name temp-key-1 --security-groups open-all \
--nic net-id=${MY_3RD_NET} \
test-vm-3
wait_instance test-vm-3

echo "## associating FIP"
export FIP=`nova floating-ip-create public | grep public |grep "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | awk -e '{print $4}'`
nova floating-ip-associate test-vm-1 ${FIP}

export FIP=`nova floating-ip-create public | grep public |grep "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | awk -e '{print $4}'`
nova floating-ip-associate test-vm-2 ${FIP}


echo "#########"
echo "## done !"
echo "#########"

