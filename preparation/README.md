TOPSE「クラウド基盤構築演習」環境構築方法
=========

準備 - テスト環境の構築(リポジトリサーバー)
------------

### 最新化

```
yum update -y
reboot
```

### 必要パッケージのインストール

```
yum install -y epel-release
yum install -y qemu-kvm libvirt virt-manager virt-install \
               libguestfs libguestfs-tools \
               yum-utils device-mapper-persistent-data lvm2 \
               screen tmux jq ansible git
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce
```

### ディレクトリの設定

```
mv /var/lib/docker /mnt
ln -s /mnt/docker /var/lib/docker
rm -Rf /var/lib/docker/*

mv /var/lib/libvirt/images /mnt
ln -s /mnt/images /var/lib/libvirt/images
```

### 300GBのイメージまで作れるようにする（デフォ10GB）

現在 (20180311) 最新の Docker CE では、overlayfs2 がデフォルトで使用されるため以下の設定は不要のはず。

```
vi /etc/sysconfig/docker-storage
DOCKER_STORAGE_OPTIONS="-g /mnt/docker --storage-opt=dm.basesize=300G"
```

### Nested KVMの有効化

```
echo "options kvm_intel nested=1" > /etc/modprobe.d/kvm-nested.conf
modprobe -r kvm_intel
modprobe kvm_intel
```

### サービスの設定と再起動

```
systemctl stop firewalld
systemctl disable firewalld
systemctl enable docker
systemctl start  docker

reboot
```

### マテリアルの取得

```
cd /mnt
git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2018-01
git checkout -b ${BRANCH_NAME} remotes/origin/${BRANCH_NAME}

mkdir -p /mnt/dvd
```

### テスト用仮想ネットワークの作成

```
cd topse-tools/preparation/utils
bash ./create_virtual_network.sh
virsh net-define ./virbr100.xml
virsh net-start virbr100
virsh net-autostart virbr100
```

### 認証キーの作成

```
cd topse-tools/preparation/utils
rm -f ansible*
ssh-keygen -f ansible_key -P '' -t rsa
```

### リポジトリコンテナの起動

```
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

### 各ノードのSSHD設定

リポジトリサーバから各 OpenStack ホストに ssh できるようにする。

```
# sysuser ユーザで実行
ssh-keygen -t rsa

# root ユーザで実行
ssh-keygen -t rsa
```

sysuser / root 2つのユーザの各`~/.ssh/id_rsa.pub`の内容を 両方共各 OpenStack ホストの`~/.ssh/authorized_keys`に追記する。

リポジトリサーバから各 OpenStack ホストに root で ssh ログインできるように設定する。

```
ansible openstack-all -f 10 -i production -u sysuser -b -K -m ping
ansible openstack-all -i production -u sysuser -b -K -m shell -a 'cat /home/sysuser/.ssh/authorized_keys >> /root/.ssh/authorized_keys'
ansible openstack-all -i production -u sysuser -b -K -m shell -a "sed -i -e 's/^PermitRootLogin no$/PermitRootLogin yes/g' /etc/ssh/sshd_config; systemctl restart sshd"
ansible openstack-all -f 10 -i production -u root -m ping

ansible openstack-all -i production -u root -m shell -a 'top -b -n 1 | grep kipmi'

ansible openstack-all -i production -u root -m shell -a 'echo 100 > /sys/module/ipmi_si/parameters/kipmid_max_busy_us'
```

使い方
------------

