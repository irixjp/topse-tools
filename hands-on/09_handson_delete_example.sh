function get_uuid () { cat - | grep " id " | awk '{print $4}'; }
function grep_ip () { grep "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+"; }

nova delete test-vm-1 test-vm-2 test-vm-3

FIPs=`nova floating-ip-list | grep_ip | awk '{print $2}'`
for i in ${FIPs}
do
    nova floating-ip-delete ${i}
done

neutron router-interface-delete Closed-Router 3rd-subnet
neutron router-interface-delete Ext-Router 2nd-subnet
neutron router-interface-delete Ext-Router work-subnet
neutron router-gateway-clear Ext-Router public
neutron router-delete Ext-Router
neutron router-delete Closed-Router
neutron net-delete 2nd-net
neutron net-delete 3rd-net
neutron net-delete work-net
neutron net-delete public
neutron security-group-delete open-all

nova keypair-delete temp-key-1
rm -f /root/temp-key-1.pem

openstack image delete CentOS7
rm -f /root/CentOS-7-x86_64-GenericCloud.qcow2

openstack flavor delete 99
