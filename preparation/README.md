TOPSE「クラウド基盤構築演習」環境構築方法
=========

NII 研究クラウドのベアメタル上に、Rocky Linux 9 + OpenStack Epoxy（2025.1、Packstack）の母艦 OpenStack を Ansible で構築し、演習用のイメージとテナントを準備する。

このディレクトリの `ansible/`・`docker/`・`pyproject.toml`・`uv.lock` は、正本のリポジトリ（openstack-rocky）から自動で同期される写しである。ここでは直接編集しない（この README を除く）。詳しくはリポジトリのルートの [README.md](../README.md) を参照。

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

### フレーバー

| フレーバー名  | compute.e   |
|---|---|
| フレーバー ID | 2           |
| メモリー      | 256GB       |
| 仮想 CPU      | 16 仮想 CPU |
| ディスク      | 445GB       |

### ネットワーク

（未記入）

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

母艦 OpenStack の構築（約 1 時間 45 分）
------------

```bash
cd ansible
uv run ansible-playbook -K 00_sudo_nopasswd.yml   # 払い出し後に 1 度だけ
uv run ansible all -m ping                        # 全ノードに届くこと
uv run ansible-playbook site.yml                  # 01〜06・11 を順に実行する
```

| Playbook | 内容 |
|---|---|
| `01_repo_server.yml` | repo サーバーに RPM のミラーと演習資材の配信（このリポジトリを clone）を用意する |
| `02_install_prep.yml` | 各ノードの共通設定と Packstack の準備 |
| `03_packstack.yml` | Packstack の実行と再起動 |
| `04_openstack_setup.yml` | br-ex の設定、チューニング |
| `05_reboot.yml` | 全ノードの再起動 |
| `06_verify.yml` | サービスと agent の確認 |
| `11_openstack_resources.yml` | イメージ、ネットワーク、ルーター、セキュリティグループの作成 |

構築が完了した後は、母艦 OpenStack の設定ファイルやサービスを変更しない。

演習用のイメージとテナントの準備
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

受講者のアカウントは、`39_prepare_tenant_setup.yml` の `students` を出欠表の学籍番号などで書き換えて作る（ユーザー `student-<番号>`、テナント `tenant-<番号>`、パスワード `pass-<番号>`）。

`40_prepare_cleanup.yml` は 31〜38 が作ったもの（作業用・試験用の VM、キーペア、イメージ）をすべて削除する。イメージの作り直しのときにだけ使い、演習の前には実行しない。

受講者の演習の資材
------------

受講者は、repo サーバーの `http://<repo サーバー>/hands-on/` から heat テンプレートと playbook を取得する（このリポジトリの [hands-on/](../hands-on/)）。
