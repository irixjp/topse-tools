TOPSE「クラウド基盤構築演習」環境構築方法
=========

研究クラウド側のイメージ
------------

`centos7-image_20170519` を使用してベアメタルインスタンス `c20.m128.d1500` を起動する。

利用するサーバーの種類

- リポジトリ・演習素材配布サーバー 1台
- コントローラー 1台
- コンピュート N台

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2       1.4T  1.2G  1.4T   1% /           ← データは全部ここにいれておく
devtmpfs         63G     0   63G   0% /dev
tmpfs            63G     0   63G   0% /dev/shm
tmpfs            63G   18M   63G   1% /run
tmpfs            63G     0   63G   0% /sys/fs/cgroup
/dev/sda3       362G   33M  362G   1% /mnt
tmpfs            13G     0   13G   0% /run/user/1000
```


準備 - テスト環境の構築(リポジトリサーバー)
------------

### 最新課・必要パッケージのインストール

```
yum update -y
yum install -y epel-release
yum install -y qemu-kvm libvirt virt-manager virt-install \
               libguestfs libguestfs-tools \
               yum-utils device-mapper-persistent-data lvm2 \
               screen tmux jq ansible git
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce
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

### 認証キーの作成

```
cd preparation/utils
rm -f ansible*
ssh-keygen -f ansible_key -P '' -t rsa
```

### リポジトリコンテナの起動

```
docker run -d -p 80:80 \
       --name repo \
       -v /mnt/topse-tools/hands-on:/var/www/html/hands-on \
       -v /mnt/topse-tools/preparation:/var/www/html/preparation \
       -v /mnt/dvd:/var/www/html/dvd \
       irixjp/topse-cloud-repo:newton-v2.0

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

OpenStackのデプロイ
------------
リポジトリサーバで root ユーザで以下のコマンドを実行する。

```
ansible-playbook -i production site.yml
```

構築したOpenStack環境の確認
------------

コントローラノードにログインして以下を実施。

```
sudo su -
cd ~/
git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2018-01
git checkout -b ${BRANCH_NAME} remotes/origin/${BRANCH_NAME}

cd ~/
source keystonerc_admin

nova service-list
cinder service-list
#heat service-list
openstack orchestration service list
neutron agent-list

cd ~/topse-tools/preparation/test/
heat stack-create --poll -f 07_heat_basic_setting.yaml default

openstack quota set --instances 500 --floating-ips 100 --ram 819200 --volumes 100 --gigabytes 300 --cores 300 --ports 300 topse01
openstack quota set --instances 5 --floating-ips 2 --ram 40960 --volumes 10 --gigabytes 10 --cores 20 topse02

nova flavor-delete 1
nova flavor-delete 2
nova flavor-delete 3
nova flavor-delete 4
nova flavor-delete 5

nova flavor-create m1.tiny   100 1024 10  1
nova flavor-create m1.small  101 2048 10  1
nova flavor-create m1.medium 102 4096 20  1
nova flavor-create m1.large  103 8192 100 2
nova flavor-create m1.xlarge 104 8192 200 4

glance --os-image-api-version 1 image-create \
--name "CentOS7" \
--disk-format qcow2 --container-format bare \
--copy-from http://reposerver/images/CentOS-7-x86_64-GenericCloud.qcow2 \
--is-public True --is-protected True \
--progress

#glance --os-image-api-version 1 image-create \
#--name "Docker" \
#--disk-format qcow2 --container-format bare \
#--copy-from http://reposerver/images/Docker.qcow2 \
#--is-public True --is-protected True \
#--progress

openstack image list
```

リソース作成テスト1

```
source openrc_teacher01
heat stack-create --poll -f test_default.yaml -P "password=password" -P "reposerver=157.1.141.26" test_console

CONSOLE=`heat output-show test_console console | python -c "import json,sys; print json.load(sys.stdin).get('floating_ip')"`; echo $CONSOLE

ssh centos@${CONSOLE}

git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2017-02
git checkout -b ${BRANCH_NAME} remotes/origin/${BRANCH_NAME}

cd preparation/test/
source openrc_teacher01
source ../../hands-on/support.sh
```
