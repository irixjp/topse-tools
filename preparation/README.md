TOPSE「クラウド基盤構築演習」環境構築方法
=========

研究クラウド側のイメージ
------------

`(deprecated) centos8.2-image_20201022` を使用してベアメタルインスタンス `compute.a` を起動する。接続するネットワークは `TOPSE` を選択。

利用するサーバーの種類と台数

- リポジトリ・演習素材配布サーバー 1台（作業の前半はここで実施）
- コントローラー 1台（作業の後半はここから実施）
- コンピュート N台
  - コンピュートの台数は `受講者 / 5` を切り上げて予備を +1 した台数。

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

NICの関係

```
eno1 使わない
eno2 使う。すべてのトラフィックが流れる
eno3 使わない
その他は使わない
```


準備 - テスト環境の構築(リポジトリサーバーで実施する)
------------

全て `root` で実施

### 必要パッケージのインストール、リポジトリのURLが変更されているので調整する

```
sudo -i

sed -i -e 's/^mirrorlist/#mirrorlist/' -e 's/#baseurl/baseurl/' -e 's/mirror.centos.org/vault.centos.org/' /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-AppStream.repo

dnf clean all
dnf repolist
dnf install -y tmux
dnf install -y podman git

podman pull irixjp/topse-cloud-repo:train-v1.4
podman pull irixjp/topse-cloud-repo:newton-v2.0

cd /mnt
git clone https://github.com/irixjp/topse-tools.git
cd topse-tools/

git branch

podman run -d -p 80:80 --name train-repo \
         -v /mnt/topse-tools/hands-on:/var/www/html/hands-on \
         -v /mnt/topse-tools/preparation:/var/www/html/preparation \
           irixjp/topse-cloud-repo:train-v1.4

dnf install -y centos-release-ansible-29.noarch
dnf install -y ansible
```

### repo サーバーのSELinuxを無効（コンテナからホストディレクトリにアクセスさせるため）

``` bash
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
```


### hosts を更新

例
```
157.1.141.19 reposerver
157.1.141.22 cc
157.1.141.13 com1
157.1.141.20 com2
xxx.x.xxx.xx com3
```

### root@repo -> centos@cc/com へのSSH認証を設定する

``` bash
cd ~/
ssh-keygen -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
↑ この鍵をccとcomの centos ユーザーの authorized_keys に登録する

登録後に動作確認
ansible all -i cc,com1,com2, -b -u centos -m ping -o
```

OpenStackのデプロイ
------------
リポジトリサーバーから `root` で作業する。

### 事前の確認

- nii_hosts を編集してホストを列挙する
- `reposerver_ip` と `openstack_password` を設定する

``` bash
cd /mnt/topse-tools/preparation/
vi nii_hosts
```

### 構築の実行

`-f` で台数分以上にFORKさせる（早く終る

```
FORK=20

cd /mnt/topse-tools/preparation/

ansible-playbook -i nii_hosts <01,02,03,04,05,06> or site.yml
```


構築したOpenStack環境の基礎設定
------------

コントローラノードにログインして以下を実施。

### 状態の確認（エラーがなければOK）

```
cd ~/
source keystonerc_admin

nova service-list
cinder service-list
openstack orchestration service list
neutron agent-list

openstack complete > /etc/bash_completion.d/osc.bash_completion
```

### 基本設定の投入

```
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

mkdir ~/work && cd ~/work
curl -O reposerver/images/CentOS-8-GenericCloud-8.3.2011-20201204.2.x86_64.qcow2
openstack image create \
    --container-format bare --disk-format qcow2 \
    --min-disk 10 --min-ram 1024 --public \
    --file CentOS-8-GenericCloud-8.3.2011-20201204.2.x86_64.qcow2 \
    CentOS8-orig

openstack image list
```

`heat_basic_setting.yaml` で Floating IPのレンジをとパスワードを設定する

```
cd ~/work
curl -O reposerver/preparation/utils/heat/heat_basic_setting.yaml

vi heat_basic_setting.yaml

time openstack stack create --wait -t heat_basic_setting.yaml default
```

ワークアラウンド
------------

`Failed to compute_task_build_instances: Host  is not mapped to any cell: nova.exception.HostMappingNotFound: Host  is not mapped to any cell` というエラーが出る場合あるため。参考(https://bugs.launchpad.net/nova/+bug/1693979)

``` bash
nova-manage cell_v2 simple_cell_setup
```


イメージ作成
------------

``` bash
cd ~/work
curl -O reposerver/preparation/utils/heat/build_image_base_env.yaml
time openstack stack create --wait -t build_image_base_env.yaml build-image-env
openstack stack output show build-image-env base_env -f json | jq -r .output_value.private_key > build-image-key.pem
chmod 600 build-image-key.pem


REPOSERVER_IP=157.1.141.14


curl -O reposerver/preparation/utils/heat/build_image_CentOS8-base.yaml
time openstack stack create --wait -t build_image_CentOS8-base.yaml --parameter reposerver=${REPOSERVER_IP:?} build-image-CentOS8-base

>>> 目安の時間
real    7m3.378s
user    0m1.695s
sys     0m0.115s
<<<

watch -n 5 openstack server list
openstack server image create --wait --name CentOS8-base handson-image-CentOS8-base

openstack image list
openstack stack delete -y build-image-CentOS8-base

curl -O reposerver/preparation/utils/heat/build_image_CentOS8-openstack.yaml
time openstack stack create --wait -t build_image_CentOS8-openstack.yaml build-image-CentOS8-openstack
>>>
real    6m22.296s
user    0m1.670s
sys     0m0.083s
<<<

watch -n 5 openstack server list
openstack server image create --wait --name CentOS8-openstack handson-image-CentOS8-openstack

openstack image list
openstack stack delete -y build-image-CentOS8-openstack

curl -O reposerver/preparation/utils/heat/build_image_CentOS8-virt.yaml
time openstack stack create --wait -t build_image_CentOS8-virt.yaml build-image-CentOS8-virt
>>>
real    6m22.296s
user    0m1.670s
sys     0m0.083s
<<<

watch -n 5 openstack server list
openstack server image create --wait --name CentOS8-virt handson-image-CentOS8-virt

openstack image list
+--------------------------------------+-------------------+--------+
| ID                                   | Name              | Status |
+--------------------------------------+-------------------+--------+
| efeb4a4f-178e-4bf6-9aa9-42278a9f33b2 | CentOS8-base      | active |
| 9fb8307a-e554-44d1-a237-dc75399c7b95 | CentOS8-openstack | active |
| c64a265f-4c1e-49e8-ab2c-d4633af33972 | CentOS8-orig      | active |
| c3aca1ba-c71b-459a-87e0-86d392dee9f1 | CentOS8-virt      | active |
+--------------------------------------+-------------------+--------+

openstack stack delete -y build-image-CentOS8-virt

openstack image set --protected --public CentOS8-orig
openstack image set --protected --public CentOS8-base
openstack image set --protected --public CentOS8-virt
openstack image set --protected --public CentOS8-openstack
```

イメージの動作確認

``` bash
openstack server create test-vm-base --network build-net --flavor m1.small --image CentOS8-base --key-name key-for-build --security-group open-all
openstack server create test-vm-openstack --network build-net --flavor m1.small --image CentOS8-openstack --key-name key-for-build --security-group open-all 
openstack server create test-vm-virt --network build-net --flavor m1.large --image CentOS8-virt --key-name key-for-build --security-group open-all 

openstack floating ip create public
openstack floating ip create public
openstack floating ip create public
openstack floating ip list

openstack server add floating ip test-vm-base <fip>
openstack server add floating ip test-vm-openstack <fip>
openstack server add floating ip test-vm-virt <fip>

openstack server list

ssh -i build-image-key.pem centos@xxxx
ssh -i build-image-key.pem centos@xxxx
ssh -i build-image-key.pem centos@xxxx

openstack server delete test-vm-base test-vm-openstack test-vm-virt
openstack floating ip list
openstack floating ip delete

openstack stack delete --wait -y build-image-env
```


環境のテスト
------------

- 作成したコンソールサーバーへログインできればOK。

``` bash
mkdir -p ~/teacher01
cd ~/teacher01
curl -O reposerver/preparation/utils/heat/openrc_teacher01
vim openrc_teacher01
source openrc_teacher01

curl -O reposerver/hands-on/00_default.yaml
time openstack stack create --wait -t 00_default.yaml --parameter password=password console
>>>
real    1m38.499s
user    0m1.224s
sys     0m0.095s
<<<

CONSOLE_IP=`openstack stack output show console info -f json | jq -r .output_value.floating_ip`

scp openrc_teacher01 centos@${CONSOLE_IP:?}:~/openrc
ssh centos@${CONSOLE_IP:?}
```

全フレーバーが起動できるかテスト。`CLUSTER` の数はコンピュートノード台数 x 5 にする。ついでに全ノードにNovaのイメージをキャッシュさせる。250台を超えるとNWセグメントが枯渇するので、50より上にしないようにする。

- 全コンピュートに分散するか？
- オーバーコミットが正しく設定されているか？
- 全台起動できているか？(CLUSTER x 5 台起動するはず)

``` bash
curl -O reposerver/preparation/utils/heat/test_massive_resource.yaml
curl -O reposerver/preparation/utils/heat/test_simple_server.yaml

CLUSTER_SIZE=5
for flavor in "small" "medium" "large" "xlarge"
do
    for image in "CentOS8-base" "CentOS8-openstack" "CentOS8-virt"
    do
        openstack stack create --wait -t test_massive_resource.yaml \
                  --parameter cluster_size=${CLUSTER_SIZE} \
                  --parameter flavor=m1.${flavor} \
                  --parameter image=${image} \
                  massive_${image}_${flavor}
    done
done
```

ping 送信テスト（全部0なら成功）

``` bash
openstack server list --long --all-project -c "Name" -c "Power State" -c "Image Name" -c "Flavor Name" -c "Host"

for i in `nova list |grep ma- |awk '{print $12}' | awk -F'=' '{print $2}'`; do ping -c 1 > /dev/null $i; echo -n $?; done
```

削除

``` bash
for flavor in "small" "medium" "large" "xlarge"
do
    for image in "CentOS8-base" "CentOS8-openstack" "CentOS8-virt"
    do
        openstack stack delete -y massive_${image}_${flavor}
    done
done
```


スタックのアップグレードでフレーバーの変更ができるか確認。`allow_resize_to_same_host` と Migration 設定がうまく行っていないと RESIZE時に UPDATE\_IN\_PROGRESS のまま失敗する。

参考にしたページ：https://qiita.com/kentarosasaki/items/9c0b6c9200bf424311f9

- フレーバーの変更ができればOK。

``` bash
openstack stack create --wait -t test_simple_server.yaml --parameter image=CentOS8-base --parameter flavor=m1.small update_resize

openstack stack update -t test_simple_server.yaml --parameter image=CentOS8-base --parameter flavor=m1.medium update_resize
watch -d -n 5 'openstack stack list && openstack server list'

openstack stack update -t test_simple_server.yaml --parameter image=CentOS8-base --parameter flavor=m1.large update_resize
watch -d -n 5 'openstack stack list && openstack server list'

openstack stack update -t test_simple_server.yaml --parameter image=CentOS8-base --parameter flavor=m1.xlarge update_resize
watch -d -n 5 'openstack stack list && openstack server list'

openstack stack delete -y update_resize
```


### 環境の削除

ここまでのテストがOKだとほぼ環境は正常に動いているはず。

```
exit
openstack stack delete -y console
openstack stack list
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
```

### テスト用の生徒アカウントを作成

演習が正しく実施できるかは、このユーザーで確かめる。

```
cd
source keystonerc_admin
openstack project list
openstack user list

cd ~/work
curl -O reposerver/preparation/90_add_test_student.sh
bash ./90_add_test_student.sh

openstack project list
openstack user list
```

### Etherpad の起動（repoサーバー上で実施）

``` bash
EP_USER=topse
EP_PASS=openstack

podman run -d -p 8443:8443 -p 8080:8080 --name eplite -e EP_USER=${EP_USER:?} -e EP_PASS=${EP_PASS:?} irixjp/eplite:latest
```



以下は削除予定（古い内容）
------------

### Docker イメージの作成

古いDockerイメージがある場合には削除しておく。

```
openstack image list
openstack image delete Docker
```

起動すると yum update と 基本パッケージのインストールがおこなわれ最後にリブートされる。

```
HEAT_PASSWD=password
HEAT_REPOIP=157.1.141.13

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

docker pull jenkins/jenkins
docker pull redmine
docker pull centos:6
docker pull centos:7
docker pull centos:8
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

HEAT_REPOIP=157.1.141.13
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

