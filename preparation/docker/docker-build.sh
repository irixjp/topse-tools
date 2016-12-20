docker build -t irixjp/topse-cloud-repo:mitaka-v1.2 .
docker tag docker.io/jenkins irixjp/topse-cloud-jenkins2-master:mitaka-v1.0
docker build --build-arg reposerver_ip=172.17.0.2 -t irixjp/topse-cloud-jenkins2-slave:mitaka-v1.0 .

