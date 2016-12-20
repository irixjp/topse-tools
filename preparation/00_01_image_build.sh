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


## イメージのビルド
docker build -t irixjp/topse-cloud-repo:mitaka-v1.2 .

## イメージのアップロード
docker login
docker push irixjp/topse-cloud-repo:mitaka-v1.2

## コンテナの起動
docker run -d -p 80:80 \
       --name repo \
       -v /mnt/topse-tools/hands-on:/var/www/html/openstack/tools \
       -v /mnt/topse-tools/preparation:/var/www/html/openstack/prepare \
       irixjp/topse-cloud-repo:mitaka-v1.2

## openstack docker
yum install -y openssh-server policycoreutils
systemctl enable sshd
systemctl start sshd

yum install -y openstack-packstack.noarch

