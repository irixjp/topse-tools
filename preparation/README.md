TOPSE「クラウド基盤構築演習」環境構築方法
=========

研究クラウド側のイメージ
------------

`centos7-image_20170519` を使用してベアメタルインスタンス `c20.m128.d1500` を起動する。

* 2018/6/20 に確認したところ、イメージが `centos7-image_20180403` になっており、newton が動かない模様。

利用するサーバーの種類

- リポジトリ・演習素材配布サーバー 1台（作業の前半はここで実施）
- コントローラー 1台（作業の後半はここから実施）
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


準備 - テスト環境の構築(リポジトリサーバーで実施する)
------------

全て `root` で実施

### 最新化・必要パッケージのインストール

```
yum install -y tmux
yum update -y
yum install -y epel-release
yum install -y qemu-kvm libvirt virt-manager virt-install \
               libguestfs libguestfs-tools \
               yum-utils device-mapper-persistent-data lvm2 \
               jq ansible git vim
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

BRANCH_NAME=2019-02
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
IMAGE_VERSION=newton-v2.0
docker run -d -p 80:80 \
       --name repo \
       -v /mnt/topse-tools/hands-on:/var/www/html/hands-on \
       -v /mnt/topse-tools/preparation:/var/www/html/preparation \
       -v /mnt/dvd:/var/www/html/dvd \
       irixjp/topse-cloud-repo:${IMAGE_VERSION}

cd /mnt
curl -O localhost/images/Cent7-Mini.iso
mount -o loop /mnt/Cent7-Mini.iso /mnt/dvd/

docker stop repo; docker start repo
```

### 各ノードのSSHD設定

リポジトリサーバから各 OpenStack ホストに ssh できるようにする。

```
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```

上記の公開鍵を全OpenStackノードのログインユーザーの`~/.ssh/authorized_keys`に追記する。

以下はユーザー `centos` の例（一般ユーザーは何でも良い）

* 2018.6.20 追記
演習サーバーの設定が変わったようで、初回のログイン時にパスワードの変更を要求される（空にできない）。同じ状況の場合は、 ansible コマンドに -K をつけて、sudo 時のパスワードを入力する。

```
# インベントリにホストを設定
cd /mnt/topse-tools/preparation/
vim production

# 接続確認
ansible openstack-all --private-key ~/.ssh/id_rsa -f 10 -u centos -b -m ping -o

# root の authorized_key にコピー
ansible openstack-all -u centos -b -m shell -a 'cat /home/centos/.ssh/authorized_keys > /root/.ssh/authorized_keys' -o

# root ログインを有効化
ansible openstack-all -u centos -b -m shell -a "sed -i -e 's/^PermitRootLogin no$/PermitRootLogin yes/g' /etc/ssh/sshd_config; systemctl restart sshd" -o

# root での接続テスト
ansible openstack-all -f 10 -u root -m ping -o
```


### Gen3でのネットワーク対応

cloud-init が起動のたびにNIC設定を初期化するので無効化しておく。

```
ansible openstack-all -u root -m shell -a 'ls -l /var/lib/cloud/scripts/per-boot/set_network.sh' -o
ansible openstack-all -u root -m shell -a 'rm -Rf /var/lib/cloud/scripts/per-boot/set_network.sh' -o
```

### DNSが eno3 の DHCP に上書きされるので、無効にしておく（eno2 のDNSを使う）

```
ansible openstack-all -u root -m shell -a 'echo PEERDNS=no >> /etc/sysconfig/network-scripts/ifcfg-eno3' -o
ansible openstack-all -u root -m shell -a 'cat /etc/sysconfig/network-scripts/ifcfg-eno3' -o
```


### kipmi が CPU100%になる場合のワークアラウンド

```
# プロセス/CPUの確認
ansible openstack-all -u root -m shell -a 'top -b -n 1 | grep kipmi'
ansible openstack-all -u root -m shell -a 'vmstat 1 10'

# もし100%だったら実行
ansible openstack-all -u root -m shell -a 'echo 100 > /sys/module/ipmi_si/parameters/kipmid_max_busy_us'
```


OpenStackのデプロイ
------------
リポジトリサーバーから `root` で作業する。

### 事前の確認

- リポジトリサーバーのIPアドレスを記入 → `group_vars/all`
- OpenStack に設定する admin パスワードを記入 → `group_vars/all`
- OpenStackノードのIPアドレスの記入 → `production`
- NIC の名前を記入 → `group_vars/production`
- コントローラーのIPアドレスを記入 → `utils/ifcfg-br-ex-eno2.cfg.j2`


### 構築の実行

`-f` で台数分以上にFORKさせる（早く終る

一発で終わらせる場合（非推奨）
```
FORK=20

cd /mnt/topse-tools/preparation/
ansible-playbook -f ${FORK:?} site.yml
```

もし個別のステップを実行する場合には以下のようにする(手間がかかるがこっちがおすすめ
```
FORK=20

cd /mnt/topse-tools/preparation/
ansible-playbook -f ${FORK:?} 01_pre_connection_test.yml
ansible-playbook -f ${FORK:?} 02_requirements_setup.yml
ansible-playbook -f ${FORK:?} 03_reboot.yml

# ここで少しCPUとI/Oの様子を見る
ansible openstack-all -f ${FORK:?} -u root -m shell -a 'vmstat 1 10'

ansible-playbook -f ${FORK:?} 04_test_requiremetns.yml
ansible-playbook -f ${FORK:?} 05_packstack.yml

# 後述するMariaDBの対策を実施する

ansible-playbook -f ${FORK:?} 06_reboot.yml

# 後述するSELinuxの無効化を行う

#ここで少しCPUとI/Oの様子を見る
ansible openstack-all -f ${FORK:?} -u root -m shell -a 'vmstat 1 10'
```

* yum update 後にリブートすると、起動後に5分程度重い処理が走っているので注意。


### MariaDB がエラーになる問題の対処

コントローラーノードで実行

参考: https://www.tuxfixer.com/mariadb-high-cpu-usage-in-openstack-pike/#more-3897
```
# CPU が 100% で張り付く
   PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
  2431 mysql     20   0 20.783g 388552  12680 R 100.0  0.3  16:08.93 mysqld

# エラーログが出る
cat /var/log/mariadb/mariadb.log | grep Error
2018-07-03  0:30:43 139644361763008 [ERROR] Error in accept: Bad file descriptor
2018-07-03  0:30:43 139644361763008 [ERROR] Error in accept: Bad file descriptor
2018-07-03  0:30:43 139644361763008 [ERROR] Error in accept: Bad file descriptor
2018-07-03  0:30:43 139644361763008 [ERROR] Error in accept: Bad file descriptor
2018-07-03  0:30:43 139644361763008 [ERROR] Error in accept: Bad file descriptor
```

```
# ulimit の増加
vim /etc/security/limits.conf
---
*         hard    nofile      600000
*         soft    nofile      600000
root      hard    nofile      600000
root      soft    nofile      600000
---

# mariadb Limits の増加
mkdir /etc/systemd/system/mariadb.service.d/
vim /etc/systemd/system/mariadb.service.d/limits.conf
---
[Service]
LimitNOFILE=600000
---

systemctl daemon-reload
systemctl restart mariadb

mysql -u root
show variables like 'open_files_limit';

ansible-playbook -f ${FORK:?} 06_reboot.yml
```


### SELinux が有効だと、Resize/Migration が失敗する。

ワークアラウンド、リブートすると無効になる。

```bash
ansible openstack-all -u root -m shell -a 'setenforce 0' -o
```



構築したOpenStack環境の基礎設定
------------

コントローラノードにログインして以下を実施。

### 状態の確認（エラーがなければOK）

```
sudo -i
cd ~/
git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2019-02
git checkout -b ${BRANCH_NAME} remotes/origin/${BRANCH_NAME}

cd ~/
source keystonerc_admin

nova service-list
cinder service-list
openstack orchestration service list
neutron agent-list
```

### 基本設定の投入

`topse-tools/preparation/utils/heat/heat_basic_setting.yaml` で Floating IPのレンジをとパスワードを設定しておく。

```
cd ~/topse-tools/preparation/utils/heat
heat stack-create --poll -f heat_basic_setting.yaml default
```

### クォータ、フレーバー、イメージの設定

```
# テスト用テナント
openstack quota set --instances 1000 --floating-ips 100 --ram 8192000 --volumes 100 --gigabytes 300 --cores 1000 --ports 1000 topse01

# 演習用のユーティリティ提供テナント
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

cd ~/
curl -o CentOS-7-x86_64-GenericCloud.qcow2 http://reposerver/images/CentOS-7-x86_64-GenericCloud.qcow2
openstack image create --disk-format qcow2 --container-format bare \
                       --file CentOS-7-x86_64-GenericCloud.qcow2 \
                       --protected --public \
                       CentOS7

openstack image list
```


環境のテスト
------------

### リソース作成テスト1

- 作成したコンソールサーバーへログインできればOK。

`openrc_teacher01` `openrc_teacher02` のエンドポイント、パスワードを設定しておく。

テストを実行するコンソールサーバーを起動する。

```
cd ~/topse-tools/preparation/utils/heat
source openrc_teacher01
nova list

# 環境に合わせて変更
HEAT_PASSWD=password
HEAT_REPOIP=157.1.141.11

heat stack-create --poll -f test_default.yaml -P "password=${HEAT_PASSWD:?}" -P "reposerver=${HEAT_REPOIP:?}" test_console
```

コンソールにログインしてテストの実施準備。パスワードは上記で設定した値。

```
CONSOLE=`heat output-show test_console console | python -c "import json,sys; print json.load(sys.stdin).get('floating_ip')"`; echo $CONSOLE

ssh centos@${CONSOLE}

git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2019-02
git checkout -b ${BRANCH_NAME} remotes/origin/${BRANCH_NAME}
```

`openrc_teacher01` のエンドポイントとパスワードを設定しておく。

```
cd preparation/utils/heat/
source openrc_teacher01
source ../../../hands-on/support.sh
nova list
```

### リソース作成テスト2

全フレーバーで全フレーバーが起動できるかテスト。`CLUSTER` の数はコンピュートノード台数 x 5 にする。ついでに全ノードにNovaのイメージをキャッシュさせる。250台を超えるとNWセグメントが枯渇するので、50より上にしないようにする。

- 全コンピュートに分散するか？
- オーバーコミットが正しく設定されているか？
- 全台起動できているか？(CLUSTER x 5 台起動するはず)

```bash
CLUSTER=30
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.tiny" test_massive1
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.small" test_massive2
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.medium" test_massive3
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.large" test_massive4
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.xlarge" test_massive5

heat stack-list
nova list
nova list | grep test_massive |grep Running | wc -l
nova-manage vm list  # CC で実施する
```

ping を飛ばす。出力が全部0ならOK。

```bash
for i in `nova list |grep massive |awk '{print $12}' | awk -F'=' '{print $2}'`; do ping -c 1 > /dev/null $i; echo -n $?; done
```

```bash
heat stack-delete -y test_massive1
heat stack-delete -y test_massive2
heat stack-delete -y test_massive3
heat stack-delete -y test_massive4
heat stack-delete -y test_massive5
```

### リソース作成テスト3

Heat, LBaaS が正常に稼働しているか確認。

- curl している部分でラウンドロビンされたトップページが表示されればOK
- Cluster Size を変更してもちゃんとオートスケールされることを確認する（前に UPDATE\_IN\_PROGRESS のまま進まないときがあった）

```
repo=`get_reposerver`; echo $repo
heat stack-create --poll -f test_cluster.yaml -P "reposerver=${repo}" test_cluster

URL=`get_heat_output test_cluster lburl`; echo $URL
for i in `seq 1 20`; do curl $URL; sleep 1; done

heat stack-update -f test_cluster.yaml -P "reposerver=${repo}" -P cluster_size=6 test_cluster
heat stack-list
for i in `seq 1 60`; do curl $URL; sleep 2; done

heat stack-delete -y test_cluster
```

### リソース作成テスト4

スタックのアップグレードでフレーバーの変更ができるか確認。`allow_resize_to_same_host` と Migration 設定がうまく行っていないと RESIZE時に UPDATE\_IN\_PROGRESS のまま失敗する。

参考にしたページ：https://qiita.com/kentarosasaki/items/9c0b6c9200bf424311f9

* 6/23 selinux の影響で、/var/lib/nova/.ssh/ の鍵が読み込めずに、resize 等が失敗する現象に遭遇。どのポリシーを適用すればいいのかわからなかったので、とりあえず `setenforce 0` で対処。再起動すると同じ現象になるので、再度 `setenforce` する。

- フレーバーの変更ができればOK。

```
heat stack-create -f test_simple_server.yaml -P "flavor=m1.tiny" test_update_stack
nova list; heat stack-list

heat stack-update -f test_simple_server.yaml -P "flavor=m1.small" test_update_stack
nova list; heat stack-list

heat stack-update -f test_simple_server.yaml -P "flavor=m1.medium" test_update_stack
nova list; heat stack-list

heat stack-update -f test_simple_server.yaml -P "flavor=m1.large" test_update_stack
nova list; heat stack-list

heat stack-update -f test_simple_server.yaml -P "flavor=m1.xlarge" test_update_stack
nova list; heat stack-list

heat stack-delete -y test_update_stack
```

### 環境の削除

ここまでのテストがOKだとほぼ環境は正常に動いているはず。

```
exit
heat stack-delete -y test_console
```


環境環境の整備
------------

コントローラーで作業。演習に必要な環境を作成しておく。

```
unset OS_PROJECT_NAME
unset OS_USERNAME
unset OS_PASSWORD
unset OS_AUTH_URL
unset OS_REGION_NAME
unset OS_VOLUME_API_VERSION
unset OS_IDENTITY_API_VERSION
unset OS_USER_DOMAIN_NAME
unset OS_PROJECT_DOMAIN_NAME

cd ~/topse-tools/preparation/
source ~/keystonerc_admin
nova list --all
```

### テスト用の生徒アカウントを作成

演習が正しく実施できるかは、このユーザーで確かめる。

```
bash ./10_add_test_student.sh

openstack project list
openstack user list
```

### Docker イメージの作成

古いDockerイメージがある場合には削除しておく。

```
openstack image list
openstack image delete Docker
```

起動すると yum update と 基本パッケージのインストールがおこなわれ最後にリブートされる。

```
HEAT_PASSWD=password
HEAT_REPOIP=157.1.141.11

cd ~/topse-tools/preparation/utils/heat
heat stack-create --poll -f build_docker_image.yaml -P "password=${HEAT_PASSWD:?}" -P "reposerver=${HEAT_REPOIP:?}" docker-image-build

nova list
nova console-log docker-image-build

CONSOLE=`heat output-show docker-image-build console | python -c "import json,sys; print json.load(sys.stdin).get('floating_ip')"`; echo $CONSOLE

ssh centos@${CONSOLE}
```

必要なイメージやパッケージがあればインストールする。

```
sudo -i
docker ps -a

docker pull jenkins
docker pull redmine
docker pull centos:6
docker pull centos:7
docker pull enakai00/eplite:ver1.0
docker pull enakai00/epmysql:ver1.0
docker pull minio/minio

docker images

shutdown -h now
```

インスタンスが停止したらイメージ化しておく。

```
nova list
nova image-create docker-image-build Docker

openstack image list
openstack image set --protected --public Docker
```

環境の削除

```
heat stack-delete -y docker-image-build
```

### Etherpad の準備

teacher02 アカウントで作成する。

`openrc_teacher02` のエンドポイントとパスワードを設定しておく。

```
cd ~/topse-tools/preparation/utils/heat
source openrc_teacher02
nova list

heat stack-create --poll -f setup_tools_env.yaml tools-env

HEAT_REPOIP=157.1.141.11
heat stack-create --poll -f etherpad.yaml -P "reposerver=${HEAT_REPOIP:?}" etherpad

nova console-log --length 100 etherpad
heat output-show etherpad floating_ip
```

上記のIPアドレスへ接続してトップページが見えればOK。


### 生徒用アカウントの払い出し

```
unset OS_PROJECT_NAME
unset OS_USERNAME
unset OS_PASSWORD
unset OS_AUTH_URL
unset OS_REGION_NAME
unset OS_VOLUME_API_VERSION
unset OS_IDENTITY_API_VERSION
unset OS_USER_DOMAIN_NAME
unset OS_PROJECT_DOMAIN_NAME

cd ~/topse-tools
source ~/keystonerc_admin
```

元ファイルをコピー

```
cd preparation
cp 10_add_test_student.sh 20_add_students.sh
vi 20_add_students.sh
```

`USERLIST` を編集する。出欠表の学籍番号等。

サンプル

```
USERLIST='11111
22222
33333
44444'
```

実行

```
bash ./20_add_students.sh

openstack project list
openstack user list
```

もし、追加でユーザーの作成が必要になった場合には、このファイルをコピーして追加ユーザーを作成する。

