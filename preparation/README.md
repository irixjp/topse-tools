TOPSE「クラウド基盤構築演習」環境構築方法
=========

NII 研究クラウドのベアメタル上に、Rocky Linux 9 + OpenStack Epoxy（2025.1、Packstack）の母艦 OpenStack を Ansible で構築し、演習用のイメージとテナントを準備して、受講者と同じ手順で演習環境を作って確かめる。

このディレクトリ（`preparation/`）は、この README を含めて、正本のリポジトリ（openstack-rocky）から自動で同期される写しである。ここでは直接編集しない。この README の正本は openstack-rocky の `ansible/README.md`。詳しくはリポジトリのルートの [README.md](../README.md) を参照。

研究クラウド側の準備
------------

### 利用するサーバー

すべて Rocky Linux 9 のベアメタルインスタンス。

| 役割 | 台数 | inventory 名 |
|---|---|---|
| repo サーバー（RPM のミラーと演習資材の配布。インターネットに出られる唯一のノード） | 1 | `openstack-repo` |
| controller | 1 | `openstack-cc` |
| compute | N | `openstack-node1`, `openstack-node2`, ... |

compute の台数は受講者数から決める。目安は 1 台あたり 10〜14 名で、受講者 50 名なら 5 台。
そこに repo1台 + controller1台 + 予備1台 を加えた台数を払い出す。

### 名前

名前は構築に影響しないが、慣例的に以下で設定している。

- cloud-repo 1台
- cloud-openstack 残りはこれ。自動的に -1, -2 と採番される

### イメージ

- `Rocky9.8-20260710`

### フレーバー

| フレーバー名  | compute.e   |
|---|---|
| フレーバー ID | 2           |
| メモリー      | 256GB       |
| 仮想 CPU      | 16 仮想 CPU |
| ディスク      | 445GB       |

### ネットワーク

- `cloud-TOPSE-SMARTSE`

Floating IP は受講者 1 名で 3 個使う。外部ネットワークの範囲には、受講者数 × 3 に講師・予備を足した数を確保する。

構築の前提
------------

- 手元の端末（macOS / Linux）に [uv](https://docs.astral.sh/uv/) が入っていること
- 全サーバーに `rocky` ユーザーで直接 SSH できること（ssh config に Host 名を定義する。サーバーの IP は inventory に書かず、ssh config で吸収する）
- 払い出し直後は sudo にパスワードが必要なため、最初に `00_sudo_nopasswd.yml` だけを `-K` 付きで 1 度実行する

```bash
cd preparation
uv sync
```

inventory の作成
------------

`ansible/inventory/example/` を複製し、値を環境に合わせて書き換える。`ansible.cfg` の既定は `inventory/production`。

```bash
cd ansible
cp -r inventory/example inventory/production
vi inventory/production/hosts.yml            # ansible_host（ssh config の Host 名）、compute の台数
vi inventory/production/group_vars/all.yml   # 外部 NIC、外部ネットワーク、Floating IP の範囲、HDD のマウント先
```

母艦 OpenStack の構築（約 2 時間）
------------

```bash
cd ansible
uv run ansible-playbook -K 00_sudo_nopasswd.yml   # 払い出し後に 1 度だけ
uv run ansible all -m ping                        # 全ノードに届くこと
uv run ansible-playbook site.yml                  # 01〜06・11 を順に実行する
```

| Playbook | 内容 |
|---|---|
| `01_repo_server.yml` | repo サーバーに RPM のミラーと演習資材の配信（topse-tools を clone）を用意する |
| `02_install_prep.yml` | 各ノードの共通設定と Packstack の準備 |
| `03_packstack.yml` | Packstack の実行と再起動 |
| `04_openstack_setup.yml` | br-ex の設定、チューニング |
| `05_reboot.yml` | 全ノードの再起動 |
| `06_verify.yml` | サービスと agent の確認 |
| `11_openstack_resources.yml` | イメージ、ネットワーク、ルーター、セキュリティグループの作成 |

構築が完了した後は、母艦 OpenStack の設定ファイルやサービスを変更しない。

演習用のイメージとテナントの準備（約 45 分）
------------

```bash
cd ansible
uv run ansible-playbook site_run_test.yml   # 31〜39 を順に実行する
```

| Playbook | 内容 |
|---|---|
| `31`〜`33` | Rocky 9 のイメージの登録、base イメージ、console イメージの作成 |
| `35`〜`38` | CentOS 7 のイメージの登録、base・openstack・virt イメージの作成（入れ子の OpenStack 用） |
| `39_prepare_tenant_setup.yml` | student ロール、受講者のテナント・ユーザー、クォータの作成 |

受講者のアカウントは、`39_prepare_tenant_setup.yml` の `students` を出欠表の学籍番号などで書き換えて作る（ユーザー `student-<番号>`、テナント `tenant-<番号>`、パスワード `pass-<番号>`）。既定では講師の確認用に `student-00000`（`tenant-00000`）と `student-99999`（`tenant-99999`）を作る。

`40_prepare_cleanup.yml` は 31〜38 が作ったもの（作業用・試験用の VM、キーペア、イメージ）をすべて削除する。イメージの作り直しのときにだけ使い、演習の前には実行しない。

演習環境の構築
------------

受講者と同じ手順で演習環境を作り、母艦の上で演習が動くことを確かめる。講師の確認には `student-00000` を使う。

受講者は、repo サーバーの `http://<repo サーバー>/hands-on/` から heat テンプレートと playbook を取得する（このリポジトリの [hands-on/](../hands-on/)）。

| テンプレート | 作るもの | 所要時間の目安 |
|---|---|---|
| `00_console.yml` | 作業用ネットワーク `work-net`（192.168.199.0/24）、ルーター `Ext-Router`、作業用の console サーバー（Rocky 9、Floating IP 付き） | 1〜2 分 |
| `02_vm_vnet_vstr.yml` | 仮想化の演習用の `handson02-virt`（CentOS 7、KVM）と、ネットワーク・ストレージの演習用の `handson02-vnet`（CentOS 7、Floating IP 付き） | 1〜2 分 |
| `08_openstack_single.yml` | 入れ子の OpenStack（all-in-one）用の `handson08-openstack-single`（CentOS 7） | スタック 1 分、playbook 約 10 分、テスト用 playbook 約 2 分 |
| `10_openstack_multi.yml` | 入れ子の OpenStack（cc 1 台 + compute 2 台）用の `handson10-openstack-{cc,node1,node2}`（CentOS 7） | スタック 1〜2 分、playbook 約 12 分、テスト用 playbook 約 2 分 |

1 名のクォータ（インスタンス 5、RAM 40GB、Floating IP 2）に収まるのは、console と、ほかの演習環境 1 つまで。次の演習環境を作る前に、前のスタックを削除する。

`openstack stack delete --wait` の進み具合の表示は、最後の `Stack DELETE completed` が出る前に途切れることがある。削除の後は `openstack stack list` で、残っているのが console だけであることを確かめる。

### 1. console の作成（Horizon）

1. ブラウザで Horizon（`http://<cc サーバーの外部 IP>/dashboard`）に `student-00000` / `pass-00000` でログインする
2. 「オーケストレーション」→「スタック」→「スタックの起動」で、テンプレートのソースに URL `http://<repo サーバー>/hands-on/00_console.yml` を指定する（または、ファイルの内容を「直接入力」に貼り付ける）
3. スタック名（例: `console`）と、console のパスワード（`password`）を入力して起動する
4. スタックが「作成完了」になったら、「概要」の出力 `console` で Floating IP を確かめる

手元の端末から console に `rocky` ユーザーでログインする（パスワードは 3. で入力したもの）。

```bash
ssh rocky@<console の Floating IP>
```

console の `~/openrc` は仮の値で作られる。自分のアカウントに書き換える。

```bash
vi ~/openrc
#   OS_AUTH_URL=http://<cc サーバーの外部 IP>:5000/v3
#   OS_PROJECT_NAME=tenant-00000
#   OS_USERNAME=student-00000
#   OS_PASSWORD=pass-00000
source ~/openrc
openstack token issue      # 認証が通ること
openstack stack list       # console のスタックが CREATE_COMPLETE
```

ログインしたシェルでは、プロンプトの先頭に `[CONSOLE]` が出て（root では末尾が `#`）、`~/openrc` が読み込まれ、`LC_ALL=en_US.UTF-8` が設定されている。

以降の作業はすべて console で行う。console は演習の期間中は削除しない。

### 2. 演習の資材の取得

console は repo サーバーを `reposerver-centos7` の名前で引ける。

```bash
cd ~
for f in 02_vm_vnet_vstr.yml \
         08_openstack_single.yml 08_openstack_single_inventory.yml \
         08_openstack_single_playbook.yml 08_openstack_single_test_playbook.yml \
         10_openstack_multi.yml 10_openstack_multi_inventory \
         10_openstack_multi_playbook.yml 10_openstack_multi_test_playbook.yml; do
  curl -fsSO http://reposerver-centos7/hands-on/$f
done
ls
```

### 3. 02: 仮想化・仮想ネットワーク・仮想ストレージの演習環境

```bash
openstack stack create -t 02_vm_vnet_vstr.yml --wait handson02
openstack stack output show handson02 --all
openstack server list
```

`handson02-virt`（192.168.199.10）と `handson02-vnet`（192.168.199.11）に、console から `centos` / `password` でログインできることを確かめる。

```bash
ssh centos@192.168.199.10    # プロンプト [VIRT]。libvirtd が動き、/dev/kvm がある
ssh centos@192.168.199.11    # プロンプト [VNET]。target・iscsid・httpd が動いている
```

確かめたら削除する。

```bash
openstack stack delete -y --wait handson02
openstack stack list      # console だけ
```

### 4. 08: 入れ子の OpenStack（all-in-one）

スタックを作り、playbook で入れ子の OpenStack（Newton）を Packstack で構築する。

```bash
openstack stack create -t 08_openstack_single.yml --wait handson08
ansible-playbook -i 08_openstack_single_inventory.yml 08_openstack_single_playbook.yml
```

テスト用 playbook で、入れ子の OpenStack の上に cirros の VM 2 台を作り、VM 間の通信と Floating IP での ping・ssh を確かめる。最後の `PLAY RECAP` で `failed=0` であること。

```bash
ansible-playbook -i 08_openstack_single_inventory.yml 08_openstack_single_test_playbook.yml
```

テスト用のリソース（cirros の VM、ネットワーク等）は入れ子の OpenStack に残る。スタックを残したまま消すときは `-e cleanup=true` を付けて再実行する。

確かめたら削除する。

```bash
openstack stack delete -y --wait handson08
openstack stack list      # console だけ
```

### 5. 10: 入れ子の OpenStack（複数ノード）

08 と同じ流れで、cc 1 台と compute 2 台の入れ子の OpenStack を作る。テスト用 playbook は VM 2 台を別々の compute に置き、compute をまたいだ通信（VXLAN）も確かめる。各 playbook の `PLAY RECAP` で、全ホストが `failed=0` であること。

```bash
openstack stack create -t 10_openstack_multi.yml --wait handson10
ansible-playbook -i 10_openstack_multi_inventory 10_openstack_multi_playbook.yml
ansible-playbook -i 10_openstack_multi_inventory 10_openstack_multi_test_playbook.yml
openstack stack delete -y --wait handson10
openstack stack list      # console だけ
```

### 6. 後片付け

講師の確認が終わったら、Horizon の「スタック」で console のスタックを削除し、スタックが残っていないことを確かめる。
