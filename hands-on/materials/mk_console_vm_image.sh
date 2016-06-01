

wget http://reposerver/openstack/tools/materials/userdata_student_console.txt
nova boot --flavor m1.tiny \
     --image CentOS7-1603 \
     --security-groups sg-for-console \
     --key my-key-99 \
     --nic net-id=e98444df-292d-4ffe-bef8-7ac41fc70bc5 \
     --user-data userdata_student_console.txt \
     console

nova image-create console console-image
glance image-download --file centos7-xrdp.qcow2 --progress console-image
glance image-delete console-image
nova delete console


