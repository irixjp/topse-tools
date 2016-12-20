docker run -d -p 80:80 --name repo irixjp/topse-cloud-repo:mitaka-v1.2
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins-master irixjp/topse-cloud-jenkins2-master:mitaka-v1.0
docker run -d -p 10022:22 --name jenkins-slave  irixjp/topse-cloud-jenkins2-slave:mitaka-v1.0
