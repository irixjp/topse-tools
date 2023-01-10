API_ADDRESS=157.1.141.20

USERLIST='0501
0502'

function set_os_auth () {
  unset OS_TENANT_NAME OS_USERNAME OS_PASSWORD OS_AUTH_URL OS_REGION_NAME OS_VOLUME_API_VERSION OS_IDENTITY_API_VERSION OS_USER_DOMAIN_NAME OS_PROJECT_DOMAIN_NAME
  export OS_TENANT_NAME=tenant-${USER_NUM}
  export OS_USERNAME=student-${USER_NUM}
  export OS_PASSWORD=pass-${USER_NUM}
  export OS_AUTH_URL=http://${API_ADDRESS}:5000/v3
  export OS_REGION_NAME=RegionOne
  export OS_VOLUME_API_VERSION=2
  export OS_IDENTITY_API_VERSION=3
  export OS_USER_DOMAIN_NAME=${OS_USER_DOMAIN_NAME:-"Default"}
  export OS_PROJECT_DOMAIN_NAME=${OS_PROJECT_DOMAIN_NAME:-"Default"}
}

function del_stack_ex_console () {
  STACK_IDs=`openstack stack list -f value | grep -v console | awk '{print $1}'`
  if [ "" != "${STACK_IDs}" ]
  then
     for STACK in ${STACK_IDs}
     do
       openstack stack delete --yes --wait ${STACK}
     done
  fi
}

function del_stack_console () {
  STACK_IDs=`openstack stack list -f value | grep console | awk '{print $1}'`
  if [ "" != "${STACK_IDs}" ]
  then
     for STACK in ${STACK_IDs}
     do
       openstack stack delete --yes --wait ${STACK}
     done
  fi
}

function del_neutron_ports () {
  PORT_IDs=`neutron port-list | grep  -e 192.168.199.100 -e 172.16.100.100 | awk '{print $2}'`
  if [ "" != "${PORT_IDs}" ]
  then
     for PORT in ${PORT_IDs}
     do
       neutron port-delete ${PORT}
     done
  fi
}

function del_nova_server_ex_console () {
  SERVER_IDs=`openstack server list -f value | grep -v console | grep -v etherpad | awk '{print $1}'`
  if [ "" != "${SERVER_IDs}" ]
  then
     for SERVER in ${SERVER_IDs}
     do
       nova delete ${SERVER}
     done
  fi
}

function del_floating_ips () {
  FIP_IDs=`neutron floatingip-list | grep 157 | awk '{print $2}'`
  if [ "" != "${FIP_IDs}" ]
  then
     for FIP in ${FIP_IDs}
     do
       neutron floatingip-delete ${FIP}
     done
  fi
}

function del_router_inferface () {
  ROUTER_ID=`neutron router-list | grep Ext-Router | awk '{print $2}'`
  SUBNET_ID=`neutron subnet-list | grep floating-subnet | awk '{print $2}'`
  if [ "" != "${ROUTER_ID}" ] && [ "" != "${SUBNET_ID}" ]
  then
    neutron router-interface-delete ${ROUTER_ID} ${SUBNET_ID}
  fi
}

function del_nova_keypair () {
  KEYPAIR_NAMEs=`openstack keypair list -f value | awk '{print $1}'`
  if [ "" != "${KEYPAIR_NAMEs}" ]
  then
     for KEYPAIR in ${KEYPAIR_NAMEs}
     do
       openstack keypair delete ${KEYPAIR}
     done
  fi
}

function del_floating_net () {
  NET_IDs=`neutron net-list | grep floating-net | awk '{print $2}'`
  if [ "" != "${NET_IDs}" ]
  then
     for NET_ID in ${NET_IDs}
     do
       neutron net-delete ${NET_ID}
     done
  fi
}

for USER_NUM in ${USERLIST}
do
  echo "### ${USER_NUM}"
  set_os_auth
  del_nova_server_ex_console
  del_neutron_ports
  del_floating_ips
  del_router_inferface
  del_stack_ex_console
  del_stack_console
  del_floating_net
  del_nova_keypair
done

