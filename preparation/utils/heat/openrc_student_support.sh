OPENSTACK_API_HOST=X.X.X.X
STUDENT_NUM=YYYY

export OS_AUTH_URL=http://${OPENSTACK_API_HOST}:5000/v3
export OS_PROJECT_NAME="tenant-${STUDENT_NUM}"
export OS_USERNAME="student-${STUDENT_NUM}"
export OS_PASSWORD="pass-${STUDENT_NUM}"
export OS_REGION_NAME="RegionOne"
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_ID="default"
export OS_INTERFACE=public
export OS_IDENTITY_API_VERSION=3

if [ -z "$OS_USER_DOMAIN_NAME" ]; then unset OS_USER_DOMAIN_NAME; fi
if [ -z "$OS_PROJECT_DOMAIN_ID" ]; then unset OS_PROJECT_DOMAIN_ID; fi
if [ -z "$OS_REGION_NAME" ]; then unset OS_REGION_NAME; fi

unset OS_TENANT_ID
unset OS_TENANT_NAME
unset OS_SERVICE_TOKEN

export PS1='[\u@\h \W(student-${STUDENT_NUM:?})]\$ '
