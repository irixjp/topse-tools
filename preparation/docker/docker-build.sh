# prepare
yum install -y docker

## NIIサーバーは /mnt に大容量領域がマウントされるため（変更不可）
mv /var/lib/docker /mnt
ln -s /mnt/docker /var/lib/docker
rm -Rf /var/lib/docker/*

## 100GBのイメージまで作れるようにする（デフォ10GB）
vi /etc/sysconfig/docker-storage
-----
DOCKER_STORAGE_OPTIONS="-g /mnt/docker --storage-opt=dm.basesize=100G"
-----

systemctl enable docker
systemctl start  docker


# build
docker build -t irixjp/topse-cloud-repo:mitaka-v1.2 .
docker tag docker.io/jenkins irixjp/topse-cloud-jenkins2-master:mitaka-v1.0
docker build --build-arg reposerver_ip=172.17.0.2 -t irixjp/topse-cloud-jenkins2-slave:mitaka-v1.0 .

