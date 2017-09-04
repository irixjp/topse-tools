# Some materials of Cloud infrastructure design and deployment course

# Requirement

必要パッケージ
```
yum install -y epel-release
yum install -y qemu-kvm libvirt virt-manager virt-install \
               libguestfs libguestfs-tools \
               docker \
               screen tmux jq ansible git
```

ディレクトリの設定
```
mv /var/lib/docker /mnt
ln -s /mnt/docker /var/lib/docker
rm -Rf /var/lib/docker/*

mv /var/lib/libvirt/images /mnt
ln -s /mnt/images /var/lib/libvirt/images
```

300GBのイメージまで作れるようにする（デフォ10GB）
```
vi /etc/sysconfig/docker-storage
DOCKER_STORAGE_OPTIONS="-g /mnt/docker --storage-opt=dm.basesize=300G"
```

Nested KVMの有効化
```
echo "options kvm_intel nested=1" > /etc/modprobe.d/kvm-nested.conf
modprobe -r kvm_intel
modprobe kvm_intel
```

```
systemctl stop firewalld
systemctl disable firewalld
systemctl enable docker
systemctl start  docker

reboot
```

# Preparation

リポジトリコンテナの起動
```
git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2017-02
git checkout -b ${BRANCH_NAME} remotes/origin/${BRANCH_NAME}

mkdir -p /mnt/dvd

docker pull irixjp/topse-cloud-repo:newton-v1.0
docker run -d -p 80:80 \
       --name repo \
       -v /mnt/topse-tools/hands-on:/var/www/html/hands-on \
       -v /mnt/topse-tools/preparation:/var/www/html/preparation \
       -v /mnt/dvd:/var/www/html/dvd \
       irixjp/topse-cloud-repo:newton-v1.0

cd /mnt
curl -O localhost/images/Cent7-Mini.iso
mount -o loop /mnt/Cent7-Mini.iso /mnt/dvd/

docker stop repo; docker start repo
```

各ノードとの疎通確認
```
cd /mnt/topse-tools/preparation/01_openstack_base_env
ansible allnode -i ansible_hosts -u sysuser -m ping
```
