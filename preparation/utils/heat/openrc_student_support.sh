student_num=2836
export OS_TENANT_NAME=tenant-${student_num}
export OS_USERNAME=student-${student_num}
export OS_PASSWORD=pass-${student_num}
export OS_AUTH_URL=http://157.1.141.13:5000/v3
export OS_REGION_NAME=RegionOne
export OS_VOLUME_API_VERSION=2
export OS_IDENTITY_API_VERSION=3
export OS_USER_DOMAIN_NAME=${OS_USER_DOMAIN_NAME:-"Default"}
export OS_PROJECT_DOMAIN_NAME=${OS_PROJECT_DOMAIN_NAME:-"Default"}
export PS1='[\u@\h \W(student-${student_num})]\$ '
