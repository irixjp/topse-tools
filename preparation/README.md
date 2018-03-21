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

全て `root` で実施

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
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```

上記の公開鍵を全OpenStackノードのログインユーザーの`~/.ssh/authorized_keys`に追記する。

以下はユーザー `centos` の例（一般ユーザーは何でも良い）

```
cd /mnt/topse-tools/preparation/

# 接続確認
ansible openstack-all -f 10 -u centos -b -m ping

# root の authorized_key にコピー
ansible openstack-all -u centos -b -m shell -a 'cat /home/centos/.ssh/authorized_keys >> /root/.ssh/authorized_keys'

# root ログインを有効化
ansible openstack-all -u centos -b -m shell -a "sed -i -e 's/^PermitRootLogin no$/PermitRootLogin yes/g' /etc/ssh/sshd_config; systemctl restart sshd"

# root での接続テスト
ansible openstack-all -f 10 -u root -m ping
```

Gen3でのネットワーク対応。cloud-init が起動のたびにNIC設定を初期化するので無効化しておく。

```
rm -Rf /var/lib/cloud/scripts/per-boot/set_network.sh
```


kipmi が CPU100%になる場合のワークアラウンド
```
# プロセスの確認
ansible openstack-all -u root -m shell -a 'top -b -n 1 | grep kipmi'

# もし100%だったら実行
ansible openstack-all -u root -m shell -a 'echo 100 > /sys/module/ipmi_si/parameters/kipmid_max_busy_us'
```


OpenStackのデプロイ
------------
リポジトリサーバーから `root` で作業する。

### 事前の確認

- リポジトリサーバーのIPアドレス → `group_vars/all`
- OpenStack に設定する admin パスワード → `group_vars/all`
- OpenStackノードのIPアドレス → `production`
- NIC の名前 → `group_vars/production`
- コントローラーのIPアドレス → `utils/ifcfg-br-ex-eno2.cfg.j2`


### 構築の実行

```
cd /mnt/topse-tools/preparation/
ansible-playbook site.yml
```

もし個別のステップを実行する場合には以下のようにする。
```
ansible-playbook 01_pre_connection_test.yml
ansible-playbook 02_requirements_setup.yml
ansible-playbook 03_reboot.yml
ansible-playbook 04_test_requiremetns.yml
ansible-playbook 05_packstack.yml
ansible-playbook 06_reboot.yml
```

yum update 後にリブートすると、起動後に5分程度重い処理が走っているので注意。



構築したOpenStack環境の基礎設定
------------

コントローラノードにログインして以下を実施。

### 状態の確認（エラーがなければOK）

```
sudo -i
cd ~/
git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2018-01
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


環境のテスト
------------

### リソース作成テスト1

- 作成したコンソールサーバーへログインできればOK。

`openrc_teacher01` `openrc_teacher02` のエンドポイント、パスワードを設定しておく。

テストを実行するコンソールサーバーを起動する。

```
cd ~/topse-tools/preparation/utils/heat
source openrc_teacher01
heat stack-create --poll -f test_default.yaml -P "password=password" -P "reposerver=157.1.141.22" test_console
```

コンソールにログインしてテストの実施準備。パスワードは上記で設定した値。

```
CONSOLE=`heat output-show test_console console | python -c "import json,sys; print json.load(sys.stdin).get('floating_ip')"`; echo $CONSOLE

ssh centos@${CONSOLE}

git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

BRANCH_NAME=2018-01
git checkout -b ${BRANCH_NAME} remotes/origin/${BRANCH_NAME}
```

`openrc_teacher01` のエンドポイントとパスワードを設定しておく。

```
cd preparation/utils/heat/
source openrc_teacher01
source ../../../hands-on/support.sh
```

### リソース作成テスト2

全フレーバーで全フレーバーが起動できるかテスト。`CLUSTER` の数はコンピュートノード台数 x 5 にする。ついでに全ノードにNovaのイメージをキャッシュさせる。

- 全コンピュートに分散するか？
- オーバーコミットが正しく設定されているか？
- 全台起動できているか？(CLUSTER x 5 台起動するはず)

```
CLUSTER=5
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.tiny" test_massive1
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.small" test_massive2
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.medium" test_massive3
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.large" test_massive4
heat stack-create --poll -f test_massive_resource.yaml -P "cluster_size=${CLUSTER}" -P "flavor=m1.xlarge" test_massive5

nova list
nova list | grep test_massive | wc -l
nova-manage vm list

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
unset OS_TENANT_NAME
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
bash ./07_add_test_student.sh
```

### Docker イメージの作成

古いDockerイメージがある場合には削除しておく。

```
openstack image list
```

```
cd ~/topse-tools/preparation/utils/heat
heat stack-create --poll -f build_docker_image.yaml -P "password=password" -P "reposerver=157.1.141.22" docker-image-build

nova console-log docker-image-build
```

