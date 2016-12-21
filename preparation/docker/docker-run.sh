# run
docker run -d -p 80:80 \
       --name repo \
       -v /mnt/topse-tools/hands-on:/var/www/html/hands-on \
       -v /mnt/topse-tools/preparation:/var/www/html/preparation \
       irixjp/topse-cloud-repo:mitaka-v1.4

docker run -d -p 8080:8080 -p 50000:50000 --name jenkins-master irixjp/topse-cloud-jenkins2-master:mitaka-v1.0

docker run -d -p 22 --name jenkins-slave  irixjp/topse-cloud-jenkins2-slave:mitaka-v1.2
