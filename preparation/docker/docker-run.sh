# run
docker run -d -p 80:80 \
       --name repo \
       -v /mnt/topse-tools/hands-on:/var/www/html/hands-on \
       -v /mnt/topse-tools/preparation:/var/www/html/preparation \
       irixjp/topse-cloud-repo:mitaka-v1.4

docker run -d -p 8080:8080 -p 50000:50000 --name jenkins-master irixjp/topse-cloud-jenkins2-master:mitaka-v1.0

docker run -d -p 22 --name jenkins-slave  irixjp/topse-cloud-jenkins2-slave:mitaka-v1.2


docker run -it --rm \
       -e "OS_AUTH_URL=http://192.168.100.100:5000/v2.0" \
       -e "OS_REGION_NAME=RegionOne" \
       -e "OS_TENANT_NAME=admin" \
       -e "OS_USERNAME=admin" \
       -e "OS_PASSWORD=password" \
       -add-host reposerver:172.17.0.2 \
       irixjp/topse-cloud-tempest:mitaka-v1.0
